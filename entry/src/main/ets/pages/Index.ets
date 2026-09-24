import { Theme } from '../utils/Theme';
import { WhiteboardPage } from './WhiteboardPage';
import { DutyPage } from './DutyPage';
import { BillPage } from './BillPage';
import { DormPage } from './DormPage';

// 宿舍分布式协作板：白板 / 值日 / 账单 / 宿舍（多设备协同）
@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  private tabsController: TabsController = new TabsController();

  @Builder
  tabBarItem(label: string, index: number) {
    Column() {
      Row()
        .width(6)
        .height(6)
        .borderRadius(3)
        .backgroundColor(this.currentIndex === index ? Theme.primary : Color.Transparent)
        .margin({ bottom: 5 })
      Text(label)
        .fontSize(12.5)
        .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentIndex === index ? Theme.primary : Theme.textHint)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
      TabContent() {
        WhiteboardPage()
      }
      .tabBar(this.tabBarItem('白板', 0))

      TabContent() {
        DutyPage()
      }
      .tabBar(this.tabBarItem('值日', 1))

      TabContent() {
        BillPage()
      }
      .tabBar(this.tabBarItem('账单', 2))

      TabContent() {
        DormPage()
      }
      .tabBar(this.tabBarItem('宿舍', 3))
    }
    .barPosition(BarPosition.End)
    .barMode(BarMode.Fixed)
    .barHeight(64)
    .scrollable(false)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }
}
