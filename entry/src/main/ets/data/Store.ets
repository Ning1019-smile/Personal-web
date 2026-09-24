import { common } from '@kit.AbilityKit';
import { preferences, distributedDataObject } from '@kit.ArkData';
import { DormState, Member, Bill, Note, DutyTask } from '../model/Types';
import { buildDefaultState, DUTY_TASK_NAMES } from './MockData';
import { Theme } from '../utils/Theme';
import { Util } from '../utils/Util';
import { PermissionUtil } from '../utils/PermissionUtil';

// 分布式对象传输信封：rev 用于防止离线消息乱序覆盖
interface SyncEnvelope {
  rev: number;
  state: DormState;
}

const PREFS_NAME: string = 'dorm_board_prefs';
const KEY_STATE: string = 'state_json';
const KEY_SESSION: string = 'session_id';
const KEY_ME: string = 'my_member_id';
const FIELD: string = 'envelope';

// 全宿舍状态中心：
// - 本地 Preferences 持久化（无网/单设备也可用）
// - 分布式数据对象：相同 sessionId 的可信设备之间自动同步，一人更新，全宿舍手机/平板/智慧屏实时刷新
export class Store {
  private static instance: Store | null = null;

  private context: common.UIAbilityContext | null = null;
  // DataObject 的业务字段是动态属性，按官方用法通过 ESObject 动态访问
  private dataObject: ESObject | null = null;
  private prefs: preferences.Preferences | null = null;
  private sessionId: string = '';
  private rev: number = 0;
  private peerIds: Set<string> = new Set();

  static getInstance(): Store {
    if (Store.instance === null) {
      Store.instance = new Store();
    }
    return Store.instance;
  }

  async init(context: common.UIAbilityContext, resumeSession?: string): Promise<void> {
    this.context = context;

    // 先放默认数据，保证 UI 立即可渲染
    AppStorage.setOrCreate<DormState>('dorm', buildDefaultState());
    AppStorage.setOrCreate<boolean>('syncActive', false);
    AppStorage.setOrCreate<number>('peerCount', 0);
    AppStorage.setOrCreate<string[]>('peerLabels', []);
    AppStorage.setOrCreate<string>('myMemberId', '');

    this.prefs = await preferences.getPreferences(context, PREFS_NAME);
    const savedJson: string = this.syncGetString(KEY_STATE);
    if (savedJson.length > 0) {
      try {
        AppStorage.setOrCreate<DormState>('dorm', JSON.parse(savedJson) as DormState);
      } catch (e) {
        // 本地缓存损坏时保持默认数据
      }
    }
    const myId: string = this.syncGetString(KEY_ME);
    if (myId.length > 0) {
      AppStorage.setOrCreate<string>('myMemberId', myId);
    }

    // 创建分布式数据对象（此时未组网，仅本地内存）
    const obj: ESObject = distributedDataObject.create(context, { envelope: '' });
    this.dataObject = obj;
    obj.on('change', () => {
      this.onObjectChange();
    });
    obj.on('status', (_sid: string, networkId: string, status: string) => {
      this.onPeerStatus(networkId, status);
    });
    this.publishLocal();

    // 流转接续或上次未退出的协同会话（权限仍授予时才恢复）
    const wantSession: string = resumeSession ?? '';
    const savedSession: string = this.syncGetString(KEY_SESSION);
    const targetSession: string = wantSession.length > 0 ? wantSession : savedSession;
    if (targetSession.length > 0 && PermissionUtil.isDistributedGranted(context)) {
      this.join(targetSession).then(() => {}).catch(() => {});
    } else if (savedSession.length > 0) {
      this.syncDelete(KEY_SESSION);
    }
  }

  // ---------- 协同会话 ----------

  getSessionId(): string {
    return this.sessionId;
  }

  // 加入宿舍协同：同一 sessionId 的设备自动同步
  async join(sessionId: string): Promise<void> {
    const obj: ESObject | null = this.dataObject;
    if (obj === null) {
      return;
    }
    await obj.setSessionId(sessionId);
    this.sessionId = sessionId;
    this.syncPut(KEY_SESSION, sessionId);
    AppStorage.setOrCreate<boolean>('syncActive', true);
    // 组网后立刻把本端最新数据推给室友
    this.publishLocal();
  }

  leave(): void {
    const obj: ESObject | null = this.dataObject;
    if (obj !== null && this.sessionId.length > 0) {
      obj.setSessionId('', () => {});
    }
    this.sessionId = '';
    this.peerIds.clear();
    this.syncDelete(KEY_SESSION);
    AppStorage.setOrCreate<boolean>('syncActive', false);
    AppStorage.setOrCreate<number>('peerCount', 0);
    AppStorage.setOrCreate<string[]>('peerLabels', []);
  }

  setMyMember(id: string): void {
    AppStorage.setOrCreate<string>('myMemberId', id);
    this.syncPut(KEY_ME, id);
  }

  // ---------- 状态读取 / 变更 ----------

  current(): DormState {
    const s: DormState | undefined = AppStorage.get<DormState>('dorm');
    return s ?? buildDefaultState();
  }

  // 所有修改统一走这里：更新 UI → 本地持久化 → 分布式同步
  mutate(fn: (draft: DormState) => void): void {
    const next: DormState = JSON.parse(JSON.stringify(this.current())) as DormState;
    fn(next);
    this.rev += 1;
    AppStorage.setOrCreate<DormState>('dorm', next);
    this.syncPut(KEY_STATE, JSON.stringify(next));
    this.publishLocal();
  }

  private publishLocal(): void {
    const obj: ESObject | null = this.dataObject;
    if (obj === null) {
      return;
    }
    const envelope: SyncEnvelope = { rev: this.rev, state: this.current() };
    obj.envelope = JSON.stringify(envelope);
  }

  private async onObjectChange(): Promise<void> {
    const obj: ESObject | null = this.dataObject;
    if (obj === null) {
      return;
    }
    try {
      const raw: ESObject = obj.envelope;
      if (typeof raw !== 'string' || (raw as string).length === 0) {
        return;
      }
      const envelope: SyncEnvelope = JSON.parse(raw as string) as SyncEnvelope;
      // 只接受更新版本，防止离线乱序消息把新数据覆盖回旧数据
      if (envelope.rev >= this.rev) {
        this.rev = envelope.rev;
        AppStorage.setOrCreate<DormState>('dorm', envelope.state);
        this.syncPut(KEY_STATE, JSON.stringify(envelope.state));
      }
    } catch (e) {
      // 单条异常消息不影响应用
    }
  }

  private onPeerStatus(networkId: string, status: string): void {
    if (status === 'online') {
      this.peerIds.add(networkId);
    } else if (status === 'offline') {
      this.peerIds.delete(networkId);
    }
    const labels: string[] = [];
    this.peerIds.forEach((id: string) => {
      labels.push(`设备 ${id.substring(0, 4)}`);
    });
    AppStorage.setOrCreate<number>('peerCount', this.peerIds.size);
    AppStorage.setOrCreate<string[]>('peerLabels', labels);
  }

  // ---------- Preferences 容错封装 ----------

  private syncGetString(key: string): string {
    try {
      const value: preferences.ValueType = this.prefs?.getSync(key, '') ?? '';
      return value as string;
    } catch (e) {
      return '';
    }
  }

  private syncPut(key: string, value: string): void {
    try {
      this.prefs?.putSync(key, value);
    } catch (e) {
    }
  }

  private syncDelete(key: string): void {
    try {
      this.prefs?.deleteSync(key);
    } catch (e) {
    }
  }

  // ---------- 宿舍与成员 ----------

  renameDorm(name: string): void {
    this.mutate((d: DormState) => {
      d.dormName = name;
    });
  }

  addMember(name: string): void {
    const trimmed: string = name.trim();
    if (trimmed.length === 0) {
      return;
    }
    const id: string = Util.genId('m');
    const color: string = Theme.palette[this.current().members.length % Theme.palette.length];
    this.mutate((d: DormState) => {
      const m: Member = { id: id, name: trimmed, color: color };
      d.members.push(m);
      d.dutyMemberIds.push(id);
    });
  }

  removeMember(id: string): void {
    this.mutate((d: DormState) => {
      d.members = d.members.filter((m: Member) => m.id !== id);
      d.dutyMemberIds = d.dutyMemberIds.filter((x: string) => x !== id);
      d.dutyTasks = d.dutyTasks.filter((t: DutyTask) => t.assigneeId !== id);
      if (d.dutyOffset >= d.dutyMemberIds.length && d.dutyMemberIds.length > 0) {
        d.dutyOffset = 0;
      }
    });
    const myId: string | undefined = AppStorage.get<string>('myMemberId');
    if (myId === id) {
      this.setMyMember('');
    }
  }

  findMember(id: string): Member | null {
    const found = this.current().members.find((m: Member) => m.id === id);
    return found ?? null;
  }

  // ---------- 白板 ----------

  addNote(text: string, authorId: string): void {
    const trimmed: string = text.trim();
    if (trimmed.length === 0) {
      return;
    }
    this.mutate((d: DormState) => {
      const note: Note = {
        id: Util.genId('n'),
        text: trimmed,
        authorId: authorId,
        updatedAt: Date.now()
      };
      d.notes.unshift(note);
    });
  }

  removeNote(id: string): void {
    this.mutate((d: DormState) => {
      d.notes = d.notes.filter((n: Note) => n.id !== id);
    });
  }

  // ---------- 值日 ----------

  private buildDutyTasks(dateKey: string, assigneeId: string): DutyTask[] {
    const tasks: DutyTask[] = DUTY_TASK_NAMES.map((name: string): DutyTask => {
      const task: DutyTask = {
        id: Util.genId('t'),
        name: name,
        done: false,
        dateKey: dateKey,
        assigneeId: assigneeId
      };
      return task;
    });
    return tasks;
  }

  ensureDutyToday(): void {
    const today: string = Util.todayKey();
    const d: DormState = this.current();
    if (d.dutyDate === today && d.dutyTasks.length > 0) {
      return;
    }
    if (d.dutyMemberIds.length === 0) {
      return;
    }
    const assigneeId: string = d.dutyMemberIds[d.dutyOffset % d.dutyMemberIds.length];
    const tasks: DutyTask[] = this.buildDutyTasks(today, assigneeId);
    this.mutate((state: DormState) => {
      state.dutyDate = today;
      state.dutyTasks = tasks;
    });
  }

  toggleDuty(taskId: string): void {
    this.mutate((d: DormState) => {
      const t = d.dutyTasks.find((x: DutyTask) => x.id === taskId);
      if (t !== undefined) {
        t.done = !t.done;
      }
    });
  }

  // 手动轮到下一位值日生
  rotateDuty(): void {
    const d: DormState = this.current();
    if (d.dutyMemberIds.length === 0) {
      return;
    }
    const nextOffset: number = (d.dutyOffset + 1) % d.dutyMemberIds.length;
    const assigneeId: string = d.dutyMemberIds[nextOffset];
    const today: string = Util.todayKey();
    const tasks: DutyTask[] = this.buildDutyTasks(today, assigneeId);
    this.mutate((state: DormState) => {
      state.dutyOffset = nextOffset;
      state.dutyDate = today;
      state.dutyTasks = tasks;
    });
  }

  currentDutyMember(): Member | null {
    const d: DormState = this.current();
    if (d.dutyMemberIds.length === 0) {
      return null;
    }
    const id: string = d.dutyMemberIds[d.dutyOffset % d.dutyMemberIds.length];
    return this.findMember(id);
  }

  // ---------- 账单 ----------

  upsertBill(bill: Bill): void {
    this.mutate((d: DormState) => {
      const idx: number = d.bills.findIndex((b: Bill) => b.id === bill.id);
      if (idx >= 0) {
        d.bills[idx] = bill;
      } else {
        d.bills.unshift(bill);
      }
    });
  }

  removeBill(id: string): void {
    this.mutate((d: DormState) => {
      d.bills = d.bills.filter((b: Bill) => b.id !== id);
    });
  }

  // 一键分账后：全部标记已结清
  settleAll(): void {
    this.mutate((d: DormState) => {
      d.bills.forEach((b: Bill) => {
        b.settled = true;
      });
    });
  }
}
