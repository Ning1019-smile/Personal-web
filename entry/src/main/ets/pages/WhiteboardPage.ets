import { DormState, Note, Member } from '../model/Types';
import { Theme } from '../utils/Theme';
import { Util } from '../utils/Util';
import { Store } from '../data/Store';
import { NoteCard } from '../components/NoteCard';
import { EmptyView } from '../components/Common';

// 共享白板：任意成员贴便签，所有协同设备实时刷新
@Component
export struct WhiteboardPage {
  @StorageProp('dorm') dorm: DormState = {
    dormName: '', members: [], notes: [], bills: [],
    dutyMemberIds: [], dutyOffset: 0, dutyDate: '', dutyTasks: []
  };
  @StorageProp('myMemberId') myMemberId: string = '';
  @State draft: string = '';

  private authorOf(note: Note): Member {
    const m: Member | null = Store.getInstance().findMember(note.authorId);
    if (m === null) {
      return { id: '', name: '', color: Theme.textHint };
    }
    return m;
  }

  private publish(): void {
    if (this.draft.trim().length === 0) {
      return;
    }
    let authorId: string = this.myMemberId;
    if (authorId.length === 0) {
      authorId = this.dorm.members.length > 0 ? this.dorm.members[0].id : '';
    }
    if (authorId.length === 0) {
      this.getUIContext().getPromptAction().showToast({ message: '先在「宿舍」页添加成员' });
      return;
    }
    Store.getInstance().addNote(this.draft, authorId);
    this.draft = '';
    this.getUIContext().getPromptAction().showToast({ message: '已贴到白板' });
  }

  private async confirmDelete(id: string): Promise<void> {
    const result = await this.getUIContext().getPromptAction().showDialog({
      title: '删除这条便签？',
      message: '删除后所有协同设备都会同步移除',
      buttons: [
        { text: '取消', color: Theme.textSub },
        { text: '删除', color: Theme.danger }
      ]
    });
    if (result.index === 1) {
      Store.getInstance().removeNote(id);
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Column() {
          Text('宿舍白板')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.textMain)
          Text(`${this.dorm.dormName} · ${this.dorm.notes.length} 条便签`)
            .fontSize(12.5)
            .fontColor(Theme.textHint)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Row() {
          Row()
            .width(7)
            .height(7)
            .borderRadius(4)
            .backgroundColor(Theme.success)
            .margin({ right: 5 })
          Text('实时同步')
            .fontSize(11.5)
            .fontColor(Theme.success)
        }
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .backgroundColor('#E8F7EF')
        .borderRadius(12)
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 16, bottom: 12 })

      // 发布便签
      Row() {
        TextInput({ placeholder: '给室友留句话…', text: $$this.draft })
          .layoutWeight(1)
          .height(42)
          .fontSize(14.5)
          .backgroundColor('#EEF1F7')
          .borderRadius(21)
          .padding({ left: 16, right: 16 })

        Button('贴出')
          .height(42)
          .margin({ left: 10 })
          .borderRadius(21)
          .backgroundColor(Theme.primary)
          .fontSize(14.5)
          .enabled(this.draft.trim().length > 0)
          .onClick(() => {
            this.publish();
          })
      }
      .width('100%')
      .padding({ left: 18, right: 18, bottom: 12 })

      // 便签墙
      Scroll() {
        if (this.dorm.notes.length === 0) {
          EmptyView({ text: '白板还是空的', hint: '贴第一条便签，室友马上能看到' })
        } else {
          Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
            ForEach(this.dorm.notes, (n: Note, index: number) => {
              NoteCard({
                text: n.text,
                authorName: this.authorOf(n).name,
                authorColor: this.authorOf(n).color,
                timeText: Util.fmtTime(n.updatedAt),
                onDelete: () => {
                  this.confirmDelete(n.id);
                }
              })
                .margin({ right: index % 2 === 0 ? '4%' : '0%' })
            }, (n: Note) => n.id)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 4, bottom: 24 })
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .width('100%')
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bg)
  }
}
