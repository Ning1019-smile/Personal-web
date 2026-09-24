import { router, promptAction } from '@kit.ArkUI';
import { DormState, Bill, Member } from '../model/Types';
import { Theme, BILL_CATEGORIES } from '../utils/Theme';
import { Util } from '../utils/Util';
import { Store } from '../data/Store';
import { PillChip } from '../components/Common';

interface EditParams {
  id: string;
}

// 记一笔 / 编辑账单
@Entry
@Component
struct BillEditPage {
  @StorageProp('dorm') dorm: DormState = {
    dormName: '', members: [], notes: [], bills: [],
    dutyMemberIds: [], dutyOffset: 0, dutyDate: '', dutyTasks: []
  };
  @StorageProp('myMemberId') myMemberId: string = '';

  @State title: string = '';
  @State amountText: string = '';
  @State category: string = '餐饮';
  @State payerId: string = '';
  @State participantIds: string[] = [];
  @State dateText: string = Util.todayKey();
  private isEdit: boolean = false;
  private billId: string = '';
  private createdAt: number = 0;
  private settled: boolean = false;

  aboutToAppear(): void {
    const raw: Object | undefined = router.getParams() as Object | undefined;
    if (raw !== undefined && raw !== null) {
      const params: EditParams = raw as EditParams;
      const exist: Bill | undefined = Store.getInstance().current().bills
        .find((b: Bill) => b.id === params.id);
      if (exist !== undefined) {
        this.isEdit = true;
        this.billId = exist.id;
        this.title = exist.title;
        this.amountText = `${exist.amount}`;
        this.category = exist.category;
        this.payerId = exist.payerId;
        this.participantIds = exist.participantIds;
        this.dateText = exist.dateText;
        this.createdAt = exist.createdAt;
        this.settled = exist.settled;
        return;
      }
    }
    // 新建：默认支付人为「我」，参与人为全员
    const defaultPayer: string = this.myMemberId.length > 0
      ? this.myMemberId
      : (this.dorm.members.length > 0 ? this.dorm.members[0].id : '');
    this.payerId = defaultPayer;
    this.participantIds = this.dorm.members.map((m: Member) => m.id);
  }

  private toggleParticipant(id: string): void {
    if (this.participantIds.includes(id)) {
      this.participantIds = this.participantIds.filter((x: string) => x !== id);
    } else {
      const next: string[] = this.participantIds.slice();
      next.push(id);
      this.participantIds = next;
    }
  }

  private save(): void {
    const name: string = this.title.trim();
    if (name.length === 0) {
      this.getUIContext().getPromptAction().showToast({ message: '请填写账单名称' });
      return;
    }
    const amount: number = Math.round(parseFloat(this.amountText) * 100) / 100;
    if (isNaN(amount) || amount <= 0) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入正确的金额' });
      return;
    }
    if (this.payerId.length === 0) {
      this.getUIContext().getPromptAction().showToast({ message: '请选择支付人' });
      return;
    }
    if (this.participantIds.length === 0) {
      this.getUIContext().getPromptAction().showToast({ message: '请至少选择一位参与 AA 的成员' });
      return;
    }

    const bill: Bill = {
      id: this.isEdit ? this.billId : Util.genId('b'),
      title: name,
      category: this.category,
      amount: amount,
      payerId: this.payerId,
      participantIds: this.participantIds,
      dateText: this.dateText,
      settled: this.settled,
      createdAt: this.isEdit ? this.createdAt : Date.now()
    };
    Store.getInstance().upsertBill(bill);
    this.getUIContext().getPromptAction()
      .showToast({ message: this.isEdit ? '已保存修改' : '已记账，AA 自动更新' });
    router.back();
  }

  private async confirmDelete(): Promise<void> {
    const res: promptAction.ShowDialogSuccessResponse =
      await this.getUIContext().getPromptAction().showDialog({
        title: '删除这笔账单？',
        message: '删除后所有协同设备都会同步移除',
        buttons: [
          { text: '取消', color: Theme.textSub },
          { text: '删除', color: Theme.danger }
        ]
      });
    if (res.index === 1) {
      Store.getInstance().removeBill(this.billId);
      router.back();
    }
  }

  @Builder
  fieldLabel(text: string) {
    Text(text)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor(Theme.textMain)
      .width('100%')
      .margin({ bottom: 10 })
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Text('‹')
          .fontSize(30)
          .fontColor(Theme.textMain)
          .padding({ right: 10, top: 4, bottom: 4 })
          .onClick(() => {
            router.back();
          })
        Text(this.isEdit ? '编辑账单' : '记一笔')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.textMain)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 14, right: 18, top: 12, bottom: 10 })

      Scroll() {
        Column() {
          // 名称 / 金额
          Column() {
            this.fieldLabel('账单名称')
            TextInput({ placeholder: '例如：9 月宿舍电费', text: $$this.title })
              .width('100%')
              .height(46)
              .fontSize(15)
              .backgroundColor('#F3F5F9')
              .borderRadius(12)
              .padding({ left: 14, right: 14 })
              .margin({ bottom: 18 })

            this.fieldLabel('金额（元）')
            Row() {
              Text('¥')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.textMain)
                .margin({ right: 6 })
              TextInput({ placeholder: '0.00', text: $$this.amountText })
                .layoutWeight(1)
                .height(46)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .type(InputType.Number)
                .backgroundColor(Color.Transparent)
                .padding(0)
            }
            .width('100%')
            .padding({ left: 14, right: 14 })
            .backgroundColor('#F3F5F9')
            .borderRadius(12)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Theme.card)
          .borderRadius(18)
          .margin({ bottom: 14 })
          .alignItems(HorizontalAlign.Start)

          // 分类
          Column() {
            this.fieldLabel('分类')
            Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
              ForEach(BILL_CATEGORIES, (c: string, index: number) => {
                PillChip({
                  label: c,
                  selected: this.category === c,
                  color: Theme.categoryColor(c),
                  onTap: () => {
                    this.category = c;
                  }
                })
                  .margin({ right: 10, bottom: 10 })
              }, (c: string) => c)
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Theme.card)
          .borderRadius(18)
          .margin({ bottom: 14 })
          .alignItems(HorizontalAlign.Start)

          // 支付人
          Column() {
            this.fieldLabel('谁垫付的？')
            Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
              ForEach(this.dorm.members, (m: Member) => {
                PillChip({
                  label: m.name,
                  selected: this.payerId === m.id,
                  color: m.color,
                  onTap: () => {
                    this.payerId = m.id;
                  }
                })
                  .margin({ right: 10, bottom: 10 })
              }, (m: Member) => m.id)
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Theme.card)
          .borderRadius(18)
          .margin({ bottom: 14 })
          .alignItems(HorizontalAlign.Start)

          // 参与 AA
          Column() {
            this.fieldLabel('哪些成员参与 AA？')
            Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
              ForEach(this.dorm.members, (m: Member) => {
                PillChip({
                  label: m.name,
                  selected: this.participantIds.includes(m.id),
                  color: m.color,
                  onTap: () => {
                    this.toggleParticipant(m.id);
                  }
                })
                  .margin({ right: 10, bottom: 10 })
              }, (m: Member) => m.id)
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Theme.card)
          .borderRadius(18)
          .margin({ bottom: 14 })
          .alignItems(HorizontalAlign.Start)

          // 日期
          Row() {
            Text('记账日期')
              .fontSize(14)
              .fontColor(Theme.textSub)
            Blank()
            Text(this.dateText)
              .fontSize(14)
              .fontColor(Theme.textMain)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Theme.card)
          .borderRadius(18)
          .margin({ bottom: 24 })

          Button(this.isEdit ? '保存修改' : '保存并同步给室友')
            .width('100%')
            .height(50)
            .borderRadius(25)
            .backgroundColor(Theme.primary)
            .fontSize(16)
            .onClick(() => {
              this.save();
            })

          if (this.isEdit) {
            Button('删除这笔账单')
              .width('100%')
              .height(46)
              .margin({ top: 14 })
              .borderRadius(23)
              .backgroundColor(Color.White)
              .fontColor(Theme.danger)
              .fontSize(15)
              .border({ width: 1, color: Theme.danger })
              .onClick(() => {
                this.confirmDelete();
              })
          }
        }
        .width('100%')
        .padding({ left: 18, right: 18, bottom: 30 })
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bg)
  }
}
