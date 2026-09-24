import { DormState, Member, Note, Bill } from '../model/Types';
import { Theme } from '../utils/Theme';
import { Util } from '../utils/Util';

// 首次进入时的演示数据：上海杉达学院 3 号楼 302 宿舍
export function buildDefaultState(): DormState {
  const m1: Member = { id: 'm_linyi', name: '林一', color: Theme.palette[0] };
  const m2: Member = { id: 'm_chenze', name: '陈泽', color: Theme.palette[1] };
  const m3: Member = { id: 'm_miya', name: '米娅', color: Theme.palette[2] };
  const m4: Member = { id: 'm_zhoutong', name: '周潼', color: Theme.palette[3] };

  const now: number = Date.now();
  const notes: Note[] = [
    {
      id: 'n_demo_1',
      text: '周三宿舍卫生检查，大家记得把桌面收拾干净，垃圾桶提前倒掉～',
      authorId: m3.id,
      updatedAt: now - 1000 * 60 * 60 * 3
    },
    {
      id: 'n_demo_2',
      text: '空调统一开 26 度，出门记得拔插头！',
      authorId: m1.id,
      updatedAt: now - 1000 * 60 * 60 * 8
    },
    {
      id: 'n_demo_3',
      text: '桶装水快没了，周末一起拼个单？',
      authorId: m4.id,
      updatedAt: now - 1000 * 60 * 60 * 20
    }
  ];

  const bills: Bill[] = [
    {
      id: 'b_demo_1',
      title: '9 月宿舍电费',
      category: '水电',
      amount: 128.6,
      payerId: m1.id,
      participantIds: [m1.id, m2.id, m3.id, m4.id],
      dateText: Util.todayKey(),
      settled: false,
      createdAt: now - 1000 * 60 * 60 * 26
    },
    {
      id: 'b_demo_2',
      title: '周五晚火锅 AA',
      category: '餐饮',
      amount: 186,
      payerId: m2.id,
      participantIds: [m1.id, m2.id, m3.id, m4.id],
      dateText: Util.todayKey(),
      settled: false,
      createdAt: now - 1000 * 60 * 60 * 30
    },
    {
      id: 'b_demo_3',
      title: '洗衣液 + 纸巾',
      category: '日用',
      amount: 45.9,
      payerId: m3.id,
      participantIds: [m1.id, m2.id, m3.id, m4.id],
      dateText: Util.todayKey(),
      settled: false,
      createdAt: now - 1000 * 60 * 60 * 50
    }
  ];

  return {
    dormName: '杉达 3号楼 302',
    members: [m1, m2, m3, m4],
    notes: notes,
    bills: bills,
    dutyMemberIds: [m1.id, m2.id, m3.id, m4.id],
    dutyOffset: 0,
    dutyDate: '',
    dutyTasks: []
  };
}

// 值日任务模板
export const DUTY_TASK_NAMES: string[] = ['扫地拖地', '倒垃圾', '卫生间清洁', '整理公共区域'];
