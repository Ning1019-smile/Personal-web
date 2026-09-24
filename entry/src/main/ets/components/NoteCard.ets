import { Theme } from '../utils/Theme';

// 白板便签卡片
@Component
export struct NoteCard {
  @Prop text: string = '';
  @Prop authorName: string = '';
  @Prop authorColor: string = Theme.textHint;
  @Prop timeText: string = '';
  @Prop widthPercent: string = '48%';
  onDelete: () => void = () => {};

  build() {
    Column() {
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          Text(this.authorName.length > 0 ? this.authorName.charAt(0) : '?')
            .fontSize(12)
            .fontColor(Color.White)
        }
        .width(24)
        .height(24)
        .borderRadius(12)
        .backgroundColor(this.authorColor)

        Text(this.authorName.length > 0 ? this.authorName : '已退宿成员')
          .fontSize(12.5)
          .fontColor(Theme.textSub)
          .margin({ left: 6 })
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('✕')
          .fontSize(13)
          .fontColor(Theme.textHint)
          .padding(6)
          .onClick(() => {
            this.onDelete();
          })
      }
      .width('100%')
      .margin({ bottom: 8 })

      Text(this.text)
        .fontSize(14.5)
        .fontColor(Theme.textMain)
        .lineHeight(22)
        .width('100%')

      Row() {
        Blank()
        Text(this.timeText)
          .fontSize(11)
          .fontColor(Theme.textHint)
      }
      .width('100%')
      .margin({ top: 10 })
    }
    .width(this.widthPercent)
    .padding(14)
    .margin({ bottom: 12 })
    .backgroundColor(Theme.card)
    .borderRadius(16)
  }
}
