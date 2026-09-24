import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';

// 分布式数据同步权限申请（user_grant，需运行时弹窗）
const PERMISSION_DISTRIBUTED: Permissions = 'ohos.permission.DISTRIBUTED_DATASYNC';

export class PermissionUtil {
  static isDistributedGranted(context: common.UIAbilityContext): boolean {
    try {
      const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
      const status: abilityAccessCtrl.GrantStatus =
        atManager.verifyAccessTokenSync(context.applicationInfo.accessTokenId, PERMISSION_DISTRIBUTED);
      return status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (e) {
      return false;
    }
  }

  static async requestDistributed(context: common.UIAbilityContext): Promise<boolean> {
    if (PermissionUtil.isDistributedGranted(context)) {
      return true;
    }
    try {
      const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(context, [PERMISSION_DISTRIBUTED]);
      return result.authResults.length > 0 && result.authResults[0] === 0;
    } catch (e) {
      return false;
    }
  }
}
