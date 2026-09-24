import { router } from '@kit.ArkUI';
import { DormState, Bill, Member, Transfer } from '../model/Types';
import { Theme, BILL_CATEGORIES } from '../utils/Theme';
import { Util } from '../utils/Util';
import { Store } from '../data/Store';
import { computeSettle, SettleResult, Balance } from '../utils/Settle';
import { BillCard } from '../components/BillCard';
import { MemberAvatar, EmptyView, PillChip } from '../components/Common';

// 宿舍账单：垫付/AA 记录 + 一键分账，结算方案全员同步
@Component
export struct BillPage {
  @StorageProp('dorm') dorm: DormState = {
    dormName: '', members: [], notes: [], bills: [],
    dutyMemberIds: [], dutyOffset: 0, dutyDate: '', dutyTasks: []
  };
  @State filter: string = '全部';
  @State showSettle: boolean = false;

  private unsettledBills(): Bill[] {
    return this.dorm.bills.filter((b: Bill) => !b.settled);
  }

  private visibleBills(): Bill[] {
    if (this.filter === '全部') {
      return this.dorm.bills;
    }
    return this.dorm.bills.filter((b: Bill) => b.category === this.filter);
  }

  private memberOf(id: string): Member {
    const m: Member | null = Store.getInstance().findMember(id);
    return m ?? { id: '', name: '未知', color: Theme.textHint };
  }

  private settleResult(): SettleResult {
    return computeSettle(this.dorm.bills, this.dorm.members);
  }

  // AA 分账半模态面板
  @Builder
  settleSheet() {
    Column() {
      Text('AA 一键分账')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor(Theme.textMain)
        .margin({ top: 8, bottom: 4 })

      Text(`未结总支出 ¥${Util.money(this.settleResult().total)}`)
        .fontSize(13)
        .fontColor(Theme.textSub)
        .margin({ bottom: 16 })

      // 每人收支
      Column() {
        ForEach(this.settleResult().balances, (b: Balance) => {
          Row() {
            MemberAvatar({
              name: this.memberOf(b.memberId).name,
              color: this.memberOf(b.memberId).color,
              avatarSize: 34
            })
            Text(this.memberOf(b.memberId).name)
              .fontSize(14.5)
              .fontColor(Theme.textMain)
              .margin({ left: 10 })
              .layoutWeight(1)

            Column() {
              Text(`垫付 ¥${Util.money(b.paid)}`)
                .fontSize(12.5)
                .fontColor(Theme.textSub)
              Text(`应付 ¥${Util.money(b.owed)}`)
                .fontSize(12.5)
                .fontColor(Theme.textSub)
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.End)

            Text(b.net > 0.01 ? `应收 ¥${Util.money(b.net)}`
              : (b.net < -0.01 ? `应补 ¥${Util.money(-b.net)}` : '两清'))
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(b.net > 0.01 ? Theme.success : (b.net < -0.01 ? Theme.danger : Theme.textHint))
              .width(96)
              .textAlign(TextAlign.End)
              .margin({ left: 10 })
          }
          .width('100%')
          .padding({ top: 10, bottom: 10 })
        }, (b: Balance) => b.memberId)
      }
      .padding({ left: 14, right: 14 })
      .backgroundColor('#F7F9FC')
      .borderRadius(14)

      // 转账建议
      Text('建议这样转账')
        .fontSize(14.5)
        .fontWeight(FontWeight.Bold)
        .fontColor(Theme.textMain)
        .width('100%')
        .margin({ top: 18, bottom: 10 })

      if (this.settleResult().transfers.length === 0) {
        Text('大家已经两清啦')
          .fontSize(13.5)
          .fontColor(Theme.success)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 8, bottom: 8 })
      } else {
        Column() {
          ForEach(this.settleResult().transfers, (t: Transfer, index: number) => {
            Row() {
              MemberAvatar({
                name: this.memberOf(t.fromId).name,
                color: this.memberOf(t.fromId).color,
                avatarSize: 32
              })
              Text(this.memberOf(t.fromId).name)
                .fontSize(14)
                .fontColor(Theme.textMain)
                .margin({ left: 8 })
              Text('→')
                .fontSize(14)
                .fontColor(Theme.textHint)
                .margin({ left: 10, right: 10 })
              MemberAvatar({
                name: this.memberOf(t.toId).name,
                color: this.memberOf(t.toId).color,
                avatarSize: 32
              })
              Text(this.memberOf(t.toId).name)
                .fontSize(14)
                .fontColor(Theme.textMain)
                .margin({ left: 8 })
                .layoutWeight(1)
              Text(`¥${Util.money(t.amount)}`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.primary)
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
          }, (t: Transfer, index: number) => `${t.fromId}_${t.toId}_${index}`)
        }
        .padding({ left: 14, right: 14 })
        .backgroundColor('#F7F9FC')
        .borderRadius(14)
      }

      Button('全部标记已结清')
        .width('100%')
        .height(48)
        .margin({ top: 22, bottom: 6 })
        .borderRadius(24)
        .backgroundColor(Theme.primary)
        .fontSize(15.5)
        .enabled(this.settleResult().transfers.length > 0)
        .onClick(() => {
          Store.getInstance().settleAll();
          this.showSettle = false;
          this.getUIContext().getPromptAction().showToast({ message: '已结清，账单已同步给室友' });
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, bottom: 24 })
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // 标题栏
        Row() {
          Column() {
            Text('宿舍账单')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.textMain)
            Text('水电、外卖、日用，垫付一笔自动算 AA')
              .fontSize(12.5)
              .fontColor(Theme.textHint)
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          if (this.unsettledBills().length > 0) {
            Row() {
              Text('¥')
                .fontSize(12)
                .fontColor(Color.White)
                .margin({ right: 2 })
              Text('一键分账')
                .fontSize(13)
                .fontColor(Color.White)
            }
            .padding({ left: 14, right: 14, top: 8, bottom: 8 })
            .borderRadius(18)
            .backgroundColor(Theme.primary)
            .onClick(() => {
              this.showSettle = true;
            })
          }
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 16, bottom: 12 })

        Scroll() {
          Column() {
            // 汇总卡
            Row() {
              Column() {
                Text('未结总支出')
                  .fontSize(12)
                  .fontColor(Color.White)
                  .opacity(0.85)
                Text(`¥${Util.money(this.settleResult().total)}`)
                  .fontSize(26)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                  .margin({ top: 6 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Column() {
                Text(`${this.unsettledBills().length} 笔待结清`)
                  .fontSize(12.5)
                  .fontColor(Color.White)
                  .opacity(0.9)
                Text(`${this.dorm.members.length} 位成员`)
                  .fontSize(12.5)
                  .fontColor(Color.White)
                  .opacity(0.9)
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.End)
            }
            .width('100%')
            .padding(18)
            .borderRadius(20)
            .linearGradient({
              angle: 125,
              colors: [['#24B36B', 0.0], ['#65D39C', 1.0]]
            })
            .margin({ bottom: 16 })

            // 分类筛选
            Scroll() {
              Row({ space: 10 }) {
                PillChip({
                  label: '全部',
                  selected: this.filter === '全部',
                  onTap: () => {
                    this.filter = '全部';
                  }
                })
                ForEach(BILL_CATEGORIES, (c: string) => {
                  PillChip({
                    label: c,
                    selected: this.filter === c,
                    color: Theme.categoryColor(c),
                    onTap: () => {
                      this.filter = c;
                    }
                  })
                }, (c: string) => c)
              }
              .padding({ left: 2, right: 2 })
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .width('100%')
            .height(40)
            .margin({ bottom: 8 })

            if (this.visibleBills().length === 0) {
              EmptyView({ text: '这个分类还没有账单', hint: '点右下角记一笔，垫付后自动算 AA' })
            } else {
              ForEach(this.visibleBills(), (b: Bill) => {
                BillCard({
                  bill: b,
                  payerName: this.memberOf(b.payerId).name,
                  payerColor: this.memberOf(b.payerId).color,
                  onTap: () => {
                    router.pushUrl({ url: 'pages/BillEditPage', params: { id: b.id } });
                  }
                })
              }, (b: Bill) => b.id)
            }
          }
          .width('100%')
          .padding({ left: 18, right: 18, bottom: 90 })
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
      .width('100%')
      .height('100%')

      // 记一笔浮动按钮
      Row() {
        Text('+')
          .fontSize(20)
          .fontColor(Color.White)
          .margin({ right: 4 })
        Text('记一笔')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
      }
      .padding({ left: 16, right: 20, top: 12, bottom: 12 })
      .borderRadius(26)
      .backgroundColor(Theme.primary)
      .margin({ right: 18, bottom: 18 })
      .shadow({ radius: 12, color: 'rgba(59,110,246,0.35)', offsetY: 4 })
      .onClick(() => {
        router.pushUrl({ url: 'pages/BillEditPage' });
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bg)
    .bindSheet($$this.showSettle, this.settleSheet(), {
      height: SheetSize.FIT_CONTENT,
      dragBar: true
    })
  }
}
