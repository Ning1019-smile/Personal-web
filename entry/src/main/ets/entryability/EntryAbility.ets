import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { Store } from '../data/Store';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'DormBoard', '%{public}s', 'Ability onCreate');

    // 流转接续：从室友设备/本设备其他端拉起时，带上协同房间 sessionId
    let resumeSession: string | undefined = undefined;
    if (want.parameters !== undefined && want.parameters !== null) {
      const value: Object | undefined = want.parameters['sessionId'];
      if (typeof value === 'string' && (value as string).length > 0) {
        resumeSession = value as string;
      }
    }
    Store.getInstance().init(this.context, resumeSession);
  }

  // 跨设备流转：本端迁移到手机/平板/智慧屏时，把协同房间号带过去，目标端自动入会同步
  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    const sessionId: string = Store.getInstance().getSessionId();
    if (sessionId.length > 0) {
      wantParam['sessionId'] = sessionId;
    }
    hilog.info(DOMAIN, 'DormBoard', 'onContinue with session: %{public}s', sessionId);
    return AbilityConstant.OnContinueResult.AGREE;
  }

  // 应用已在目标设备运行时的流转（热启动）
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    if (want.parameters !== undefined && want.parameters !== null) {
      const value: Object | undefined = want.parameters['sessionId'];
      if (typeof value === 'string' && (value as string).length > 0) {
        Store.getInstance().join(value as string).then(() => {}).catch(() => {});
      }
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'DormBoard', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'DormBoard', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'DormBoard', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'DormBoard', '%{public}s', 'Succeeded in loading the content.');
    });

    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'DormBoard', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'DormBoard', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'DormBoard', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'DormBoard', '%{public}s', 'Ability onBackground');
  }
}
