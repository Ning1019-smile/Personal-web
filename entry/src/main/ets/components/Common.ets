import { Theme } from '../utils/Theme';

// 成员头像：用名字首字 + 成员专属配色，无需任何图片资源
@Component
export struct MemberAvatar {
  @Prop name: string = '';
  @Prop color: string = Theme.textHint;
  @Prop avatarSize: number = 38;

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Text(this.name.length > 0 ? this.name.charAt(0) : '?')
        .fontSize(this.avatarSize * 0.42)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Medium)
    }
    .width(this.avatarSize)
    .height(this.avatarSize)
    .borderRadius(this.avatarSize / 2)
    .backgroundColor(this.color)
  }
}

// 空列表占位
@Component
export struct EmptyView {
  @Prop text: string = '暂无内容';
  @Prop hint: string = '';

  build() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Text('○')
          .fontSize(44)
          .fontColor(Theme.textHint)
      }
      .width(88)
      .height(88)
      .borderRadius(44)
      .backgroundColor('#EAEDF4')
      .margin({ bottom: 12 })

      Text(this.text)
        .fontSize(15)
        .fontColor(Theme.textSub)
      if (this.hint.length > 0) {
        Text(this.hint)
          .fontSize(12.5)
          .fontColor(Theme.textHint)
          .margin({ top: 6 })
      }
    }
    .width('100%')
    .padding({ top: 56, bottom: 56 })
    .justifyContent(FlexAlign.Center)
  }
}

// 筛选/选择用胶囊
@Component
export struct PillChip {
  @Prop label: string = '';
  @Prop selected: boolean = false;
  @Prop color: string = Theme.primary;
  onTap: () => void = () => {};

  build() {
    Text(this.label)
      .fontSize(13.5)
      .fontColor(this.selected ? Color.White : Theme.textSub)
      .backgroundColor(this.selected ? this.color : '#ECF0F7')
      .padding({ left: 16, right: 16, top: 7, bottom: 7 })
      .borderRadius(16)
      .onClick(() => {
        this.onTap();
      })
  }
}

// 通用区块标题
@Component
export struct SectionTitle {
  @Prop title: string = '';

  build() {
    Row() {
      Row()
        .width(4)
        .height(16)
        .borderRadius(2)
        .backgroundColor(Theme.primary)
        .margin({ right: 8 })
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Theme.textMain)
    }
    .width('100%')
    .margin({ bottom: 12 })
  }
}
