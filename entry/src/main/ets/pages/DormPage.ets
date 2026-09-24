import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { DormState, Member } from '../model/Types';
import { Theme } from '../utils/Theme';
import { Util } from '../utils/Util';
import { Store } from '../data/Store';
import { PermissionUtil } from '../utils/PermissionUtil';
import { MemberAvatar, EmptyView } from '../components/Common';

// 宿舍页：成员管理 + 多设备协同开关（分布式数据对象的同 sessionId 自动同步）
@Component
export struct DormPage {
  @StorageProp('dorm') dorm: DormState = {
    dormName: '', members: [], notes: [], bills: [],
    dutyMemberIds: [], dutyOffset: 0, dutyDate: '', dutyTasks: []
  };
  @StorageProp('syncActive') syncActive: boolean = false;
  @StorageProp('peerCount') peerCount: number = 0;
  @StorageProp('peerLabels') peerLabels: string[] = [];
  @StorageProp('myMemberId') myMemberId: string = '';

  @State newMemberName: string = '';
  @State editingName: boolean = false;
  @State nameDraft: string = '';
  @State joining: boolean = false;

  private tips: string[] = [
    '所有设备登录同一华为账号并加入可信组网（超级终端）',
    '每人在自己的设备上点「加入协同」，白板/值日/账单即实时同步',
    '也可从系统任务中心把页面流转到平板、智慧屏接续查看'
  ];

  private sessionIdOfDorm(): string {
    return Util.dormSessionId(this.dorm.dormName);
  }

  private async toggleSync(): Promise<void> {
    const context: common.UIAbilityContext =
      this.getUIContext().getHostContext() as common.UIAbilityContext;
    if (this.syncActive) {
      const res: promptAction.ShowDialogSuccessResponse =
        await this.getUIContext().getPromptAction().showDialog({
          title: '退出多设备协同？',
          message: '退出后本机将不再与室友的设备实时同步，本地数据仍会保留',
          buttons: [
            { text: '取消', color: Theme.textSub },
            { text: '退出', color: Theme.danger }
          ]
        });
      if (res.index === 1) {
        Store.getInstance().leave();
        this.getUIContext().getPromptAction().showToast({ message: '已退出协同' });
      }
      return;
    }

    const granted: boolean = await PermissionUtil.requestDistributed(context);
    if (!granted) {
      this.getUIContext().getPromptAction().showToast({ message: '需要分布式数据权限才能多设备同步' });
      return;
    }
    this.joining = true;
    try {
      await Store.getInstance().join(this.sessionIdOfDorm());
      this.getUIContext().getPromptAction().showToast({ message: '已加入宿舍协同' });
    } catch (e) {
      this.getUIContext().getPromptAction().showToast({ message: '加入协同失败，请确认已登录华为账号' });
    }
    this.joining = false;
  }

  private startEditName(): void {
    this.nameDraft = this.dorm.dormName;
    this.editingName = true;
  }

  private saveName(): void {
    const name: string = this.nameDraft.trim();
    if (name.length > 0) {
      Store.getInstance().renameDorm(name);
    }
    this.editingName = false;
  }

  private addMember(): void {
    if (this.newMemberName.trim().length === 0) {
      return;
    }
    Store.getInstance().addMember(this.newMemberName);
    this.newMemberName = '';
  }

  private async confirmRemove(m: Member): Promise<void> {
    const res: promptAction.ShowDialogSuccessResponse =
      await this.getUIContext().getPromptAction().showDialog({
        title: `移除成员「${m.name}」？`,
        message: 'TA 的值日安排会一并移除，历史账单记录保留',
        buttons: [
          { text: '取消', color: Theme.textSub },
          { text: '移除', color: Theme.danger }
        ]
      });
    if (res.index === 1) {
      Store.getInstance().removeMember(m.id);
    }
  }

  @Builder
  tipRow(text: string) {
    Row() {
      Row()
        .width(6)
        .height(6)
        .borderRadius(3)
        .backgroundColor(Theme.primary)
        .margin({ right: 10, bottom: 8 })
      Text(text)
        .fontSize(12.5)
        .fontColor(Theme.textSub)
        .lineHeight(19)
        .layoutWeight(1)
        .margin({ bottom: 8 })
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  build() {
    Scroll() {
      Column() {
        // 标题
        Row() {
          Text('我的宿舍')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.textMain)
        }
        .width('100%')
        .padding({ left: 18, top: 16, bottom: 14 })

        // 宿舍信息卡
        Column() {
          if (this.editingName) {
            Row() {
              TextInput({ text: $$this.nameDraft })
                .layoutWeight(1)
                .height(40)
                .fontSize(15)
                .backgroundColor('#EEF1F7')
                .borderRadius(20)
                .padding({ left: 16, right: 16 })
              Text('保存')
                .fontSize(14)
                .fontColor(Theme.primary)
                .padding(12)
                .onClick(() => {
                  this.saveName();
                })
            }
            .width('100%')
          } else {
            Row() {
              Text(this.dorm.dormName)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.textMain)
                .layoutWeight(1)
              Text('编辑')
                .fontSize(13)
                .fontColor(Theme.primary)
                .padding({ left: 10, top: 6, bottom: 6 })
                .onClick(() => {
                  this.startEditName();
                })
            }
            .width('100%')
          }

          Row() {
            Column() {
              Text(`${this.dorm.members.length}`)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.primary)
              Text('成员')
                .fontSize(11.5)
                .fontColor(Theme.textHint)
                .margin({ top: 2 })
            }
            .layoutWeight(1)
            Column() {
              Text(`${this.dorm.notes.length}`)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.primary)
              Text('便签')
                .fontSize(11.5)
                .fontColor(Theme.textHint)
                .margin({ top: 2 })
            }
            .layoutWeight(1)
            Column() {
              Text(`${this.dorm.bills.length}`)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.primary)
              Text('账单')
                .fontSize(11.5)
                .fontColor(Theme.textHint)
                .margin({ top: 2 })
            }
            .layoutWeight(1)
          }
          .width('100%')
          .margin({ top: 16 })
        }
        .width('100%')
        .padding(18)
        .backgroundColor(Theme.card)
        .borderRadius(20)
        .margin({ left: 18, right: 18, bottom: 14 })

        // 多设备协同卡
        Column() {
          Row() {
            Column() {
              Text('多设备分布式协同')
                .fontSize(16.5)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.textMain)
              Text('一人更新，手机 / 平板 / 智慧屏自动同步')
                .fontSize(12)
                .fontColor(Theme.textHint)
                .margin({ top: 3 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Row() {
              Row()
                .width(7)
                .height(7)
                .borderRadius(3.5)
                .backgroundColor(this.syncActive ? Theme.success : Theme.textHint)
                .margin({ right: 5 })
              Text(this.syncActive ? '协同中' : '仅本机')
                .fontSize(11.5)
                .fontColor(this.syncActive ? Theme.success : Theme.textHint)
            }
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor(this.syncActive ? '#E8F7EF' : '#F1F2F5')
            .borderRadius(12)
          }
          .width('100%')

          if (this.syncActive) {
            Row() {
              Text(`协同房间：${Store.getInstance().getSessionId()}`)
                .fontSize(12)
                .fontColor(Theme.textSub)
                .layoutWeight(1)
              Text(`${this.peerCount} 台室友设备在线`)
                .fontSize(12)
                .fontColor(this.peerCount > 0 ? Theme.success : Theme.warning)
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F7F9FC')
            .borderRadius(12)
            .margin({ top: 14 })

            if (this.peerCount === 0) {
              Text('等待室友加入同一房间…加入后数据自动互通')
                .fontSize(12)
                .fontColor(Theme.textHint)
                .width('100%')
                .margin({ top: 8 })
            }
          }

          Button(this.syncActive ? '退出协同' : (this.joining ? '加入中…' : '加入宿舍协同'))
            .width('100%')
            .height(46)
            .margin({ top: 16 })
            .borderRadius(23)
            .fontSize(15)
            .backgroundColor(this.syncActive ? Color.White : Theme.primary)
            .fontColor(this.syncActive ? Theme.danger : Color.White)
            .border({
              width: 1,
              color: this.syncActive ? Theme.danger : Color.Transparent
            })
            .enabled(!this.joining)
            .onClick(() => {
              this.toggleSync();
            })

          Column() {
            ForEach(this.tips, (tip: string) => {
              this.tipRow(tip)
            }, (tip: string) => tip)
          }
          .width('100%')
          .margin({ top: 14 })
        }
        .width('100%')
        .padding(18)
        .backgroundColor(Theme.card)
        .borderRadius(20)
        .margin({ left: 18, right: 18, bottom: 14 })
        .alignItems(HorizontalAlign.Start)

        // 我是哪位
        Column() {
          Text('我是哪位成员？')
            .fontSize(16.5)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.textMain)
            .width('100%')
          Text('用于标记便签作者、默认支付人')
            .fontSize(12)
            .fontColor(Theme.textHint)
            .width('100%')
            .margin({ top: 3, bottom: 12 })

          Scroll() {
            Row({ space: 14 }) {
              ForEach(this.dorm.members, (m: Member) => {
                Column() {
                  MemberAvatar({
                    name: m.name,
                    color: m.color,
                    avatarSize: this.myMemberId === m.id ? 52 : 46
                  })
                  Text(m.name)
                    .fontSize(12.5)
                    .fontColor(this.myMemberId === m.id ? Theme.primary : Theme.textSub)
                    .margin({ top: 6 })
                  if (this.myMemberId === m.id) {
                    Text('✓ 是我')
                      .fontSize(10.5)
                      .fontColor(Theme.primary)
                      .margin({ top: 2 })
                  }
                }
                .padding({ top: 8, bottom: 8, left: 10, right: 10 })
                .borderRadius(14)
                .backgroundColor(this.myMemberId === m.id ? '#EDF2FF' : Color.Transparent)
                .border({
                  width: 1.5,
                  color: this.myMemberId === m.id ? Theme.primary : Color.Transparent
                })
                .onClick(() => {
                  Store.getInstance().setMyMember(m.id);
                })
              }, (m: Member) => m.id)
            }
            .padding({ left: 2, right: 2 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
        }
        .width('100%')
        .padding(18)
        .backgroundColor(Theme.card)
        .borderRadius(20)
        .margin({ left: 18, right: 18, bottom: 14 })
        .alignItems(HorizontalAlign.Start)

        // 成员管理
        Column() {
          Text('成员管理')
            .fontSize(16.5)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.textMain)
            .width('100%')
            .margin({ bottom: 12 })

          if (this.dorm.members.length === 0) {
            EmptyView({ text: '还没有成员', hint: '在下方把室友加进来' })
          } else {
            ForEach(this.dorm.members, (m: Member) => {
              Row() {
                MemberAvatar({ name: m.name, color: m.color, avatarSize: 40 })
                Text(m.name)
                  .fontSize(15)
                  .fontColor(Theme.textMain)
                  .margin({ left: 12 })
                  .layoutWeight(1)
                if (this.myMemberId === m.id) {
                  Text('我')
                    .fontSize(11)
                    .fontColor(Theme.primary)
                    .backgroundColor('#EDF2FF')
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                    .borderRadius(8)
                    .margin({ right: 10 })
                }
                Text('移除')
                  .fontSize(13)
                  .fontColor(Theme.danger)
                  .padding({ left: 8, top: 6, bottom: 6 })
                  .onClick(() => {
                    this.confirmRemove(m);
                  })
              }
              .width('100%')
              .padding({ top: 8, bottom: 8 })
            }, (m: Member) => m.id)
          }

          Row() {
            TextInput({ placeholder: '输入新成员昵称', text: $$this.newMemberName })
              .layoutWeight(1)
              .height(40)
              .fontSize(14)
              .backgroundColor('#EEF1F7')
              .borderRadius(20)
              .padding({ left: 16, right: 16 })
              .onSubmit(() => {
                this.addMember();
              })
            Button('添加')
              .height(40)
              .margin({ left: 10 })
              .borderRadius(20)
              .backgroundColor(Theme.primary)
              .fontSize(14)
              .enabled(this.newMemberName.trim().length > 0)
              .onClick(() => {
                this.addMember();
              })
          }
          .width('100%')
          .margin({ top: 10 })
        }
        .width('100%')
        .padding(18)
        .backgroundColor(Theme.card)
        .borderRadius(20)
        .margin({ left: 18, right: 18, bottom: 30 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bg)
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
  }
}
