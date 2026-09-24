import { DormState, Member, DutyTask } from '../model/Types';
import { Theme } from '../utils/Theme';
import { Store } from '../data/Store';
import { DutyTaskRow } from '../components/DutyTaskRow';
import { MemberAvatar, EmptyView } from '../components/Common';

// 值日表：今日值日生 + 任务打卡 + 顺序轮换，全员实时可见
@Component
export struct DutyPage {
  @StorageProp('dorm') dorm: DormState = {
    dormName: '', members: [], notes: [], bills: [],
    dutyMemberIds: [], dutyOffset: 0, dutyDate: '', dutyTasks: []
  };

  aboutToAppear(): void {
    Store.getInstance().ensureDutyToday();
  }

  private doneCount(): number {
    let count: number = 0;
    this.dorm.dutyTasks.forEach((t: DutyTask) => {
      if (t.done) {
        count++;
      }
    });
    return count;
  }

  private dutyMember(): Member | null {
    return Store.getInstance().currentDutyMember();
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Column() {
          Text('值日表')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.textMain)
          Text(this.dorm.dutyDate.length > 0 ? this.dorm.dutyDate : '今日值日安排')
            .fontSize(12.5)
            .fontColor(Theme.textHint)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button('轮到下一位')
          .height(36)
          .fontSize(13)
          .borderRadius(18)
          .backgroundColor(Color.White)
          .fontColor(Theme.primary)
          .enabled(this.dorm.dutyMemberIds.length > 0)
          .onClick(() => {
            Store.getInstance().rotateDuty();
          })
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 16, bottom: 14 })

      if (this.dorm.members.length === 0) {
        Column() {
          EmptyView({ text: '还没有宿舍成员', hint: '到「宿舍」页把室友都加进来' })
        }
        .layoutWeight(1)
      } else {
        Scroll() {
          Column() {
            // 今日值日生卡片
            Column() {
              Row() {
                Text('今日值日生')
                  .fontSize(13)
                  .fontColor(Color.White)
                  .opacity(0.85)
                Blank()
                Text(`${this.doneCount()}/${this.dorm.dutyTasks.length}`)
                  .fontSize(13)
                  .fontColor(Color.White)
                  .opacity(0.85)
              }
              .width('100%')

              Row() {
                MemberAvatar({
                  name: this.dutyMember()?.name ?? '',
                  color: this.dutyMember()?.color ?? Theme.primary,
                  avatarSize: 58
                })
                Column() {
                  Text(this.dutyMember()?.name ?? '')
                    .fontSize(26)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.White)
                  Text('辛苦啦，保持宿舍整洁')
                    .fontSize(12.5)
                    .fontColor(Color.White)
                    .opacity(0.85)
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .margin({ left: 14 })
                .layoutWeight(1)
              }
              .width('100%')
              .margin({ top: 14 })

              // 进度条
              Stack({ alignContent: Alignment.Start }) {
                Row()
                  .width('100%')
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor('rgba(255,255,255,0.25)')
                Row()
                  .width(`${this.dorm.dutyTasks.length === 0
                    ? 0
                    : (this.doneCount() / this.dorm.dutyTasks.length) * 100}%`)
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor(Color.White)
              }
              .width('100%')
              .height(6)
              .margin({ top: 18 })
            }
            .width('100%')
            .padding(18)
            .borderRadius(20)
            .linearGradient({
              angle: 125,
              colors: [['#3B6EF6', 0.0], ['#7AA2FF', 1.0]]
            })
            .margin({ bottom: 20 })

            // 今日任务
            Row() {
              Text('今日任务')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.textMain)
              Blank()
              Text('点击勾选完成')
                .fontSize(12)
                .fontColor(Theme.textHint)
            }
            .width('100%')
            .margin({ bottom: 12 })

            ForEach(this.dorm.dutyTasks, (t: DutyTask) => {
              DutyTaskRow({
                taskName: t.name,
                done: t.done,
                onToggle: () => {
                  Store.getInstance().toggleDuty(t.id);
                }
              })
            }, (t: DutyTask) => t.id)

            // 轮换顺序
            Row() {
              Text('值日轮换顺序')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.textMain)
            }
            .width('100%')
            .margin({ top: 10, bottom: 12 })

            Row() {
              ForEach(this.dorm.dutyMemberIds, (id: string, index: number) => {
                Row() {
                  MemberAvatar({
                    name: Store.getInstance().findMember(id)?.name ?? '',
                    color: Store.getInstance().findMember(id)?.color ?? Theme.textHint,
                    avatarSize: this.dorm.dutyOffset % this.dorm.dutyMemberIds.length === index ? 46 : 40
                  })
                  if (index < this.dorm.dutyMemberIds.length - 1) {
                    Text('→')
                      .fontSize(14)
                      .fontColor(Theme.textHint)
                      .margin({ left: 6, right: 6 })
                  }
                }
                .margin({ bottom: 8 })
              }, (id: string, index: number) => `${id}_${index}`)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')
          .padding({ left: 18, right: 18, bottom: 28 })
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bg)
  }
}
