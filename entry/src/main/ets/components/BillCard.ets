import { Bill } from '../model/Types';
import { Theme } from '../utils/Theme';
import { Util } from '../utils/Util';
import { MemberAvatar } from './Common';

// 账单卡片
@Component
export struct BillCard {
  @Prop bill: Bill = {
    id: '', title: '', category: '其他', amount: 0, payerId: '',
    participantIds: [], dateText: '', settled: false, createdAt: 0
  };
  @Prop payerName: string = '';
  @Prop payerColor: string = Theme.textHint;
  onTap: () => void = () => {};

  build() {
    Row() {
      // 左侧分类色条
      Column()
        .width(5)
        .height(46)
        .borderRadius(3)
        .backgroundColor(Theme.categoryColor(this.bill.category))
        .margin({ right: 12 })

      Column() {
        Text(this.bill.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.bill.settled ? Theme.textHint : Theme.textMain)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Row() {
          Text(this.bill.category)
            .fontSize(11)
            .fontColor(Theme.categoryColor(this.bill.category))
            .backgroundColor(this.bill.settled ? '#F1F2F5' : '#F0F4FF')
            .padding({ left: 7, right: 7, top: 2, bottom: 2 })
            .borderRadius(6)
            .margin({ right: 8 })

          MemberAvatar({ name: this.payerName, color: this.payerColor, avatarSize: 18 })
            .margin({ right: 4 })
          Text(`${this.payerName} 垫付`)
            .fontSize(12)
            .fontColor(Theme.textSub)
            .margin({ right: 8 })
          Text(`${this.bill.participantIds.length} 人 AA`)
            .fontSize(12)
            .fontColor(Theme.textHint)
          Blank()
          Text(this.bill.dateText)
            .fontSize(11.5)
            .fontColor(Theme.textHint)
        }
        .width('100%')
        .margin({ top: 7 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column() {
        Text(`¥${Util.money(this.bill.amount)}`)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.bill.settled ? Theme.textHint : Theme.textMain)
        if (this.bill.settled) {
          Text('已结清')
            .fontSize(10.5)
            .fontColor(Theme.success)
            .margin({ top: 2 })
        }
      }
      .margin({ left: 10 })
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Theme.card)
    .borderRadius(16)
    .margin({ bottom: 10 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onTap();
    })
  }
}
