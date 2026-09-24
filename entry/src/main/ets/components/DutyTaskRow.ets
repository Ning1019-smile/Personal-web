import { Theme } from '../utils/Theme';

// 值日任务行（可勾选）
@Component
export struct DutyTaskRow {
  @Prop taskName: string = '';
  @Prop done: boolean = false;
  onToggle: () => void = () => {};

  build() {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        if (this.done) {
          Text('✓')
            .fontSize(15)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
        }
      }
      .width(26)
      .height(26)
      .borderRadius(13)
      .backgroundColor(this.done ? Theme.success : Color.Transparent)
      .border({ width: 1.5, color: this.done ? Color.Transparent : Theme.textHint })
      .margin({ right: 14 })

      Text(this.taskName)
        .fontSize(15.5)
        .fontColor(this.done ? Theme.textHint : Theme.textMain)
        .decoration({ type: this.done ? TextDecorationType.LineThrough : TextDecorationType.None })
        .layoutWeight(1)

      Text(this.done ? '已完成' : '待完成')
        .fontSize(12)
        .fontColor(this.done ? Theme.success : Theme.warning)
    }
    .width('100%')
    .padding({ top: 16, bottom: 16, left: 16, right: 16 })
    .backgroundColor(Theme.card)
    .borderRadius(14)
    .margin({ bottom: 10 })
    .onClick(() => {
      this.onToggle();
    })
  }
}
