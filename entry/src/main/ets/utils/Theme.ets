// 主题色板（不依赖任何图片资源，避免资源缺失导致编译失败）
export class Theme {
  static readonly primary: string = '#3B6EF6';
  static readonly primaryDark: string = '#2B55C7';
  static readonly bg: string = '#F3F5FA';
  static readonly card: string = '#FFFFFF';
  static readonly textMain: string = '#1C2333';
  static readonly textSub: string = '#6B7488';
  static readonly textHint: string = '#9AA2B5';
  static readonly divider: string = '#ECEEF3';
  static readonly danger: string = '#E8503D';
  static readonly success: string = '#24B36B';
  static readonly warning: string = '#F5A623';

  // 成员头像自动配色
  static readonly palette: string[] =
    ['#3B6EF6', '#24B36B', '#F5A623', '#E8503D', '#8E5BFF', '#12B5C9'];

  // 账单分类配色
  static categoryColor(category: string): string {
    if (category === '水电') {
      return '#3B6EF6';
    }
    if (category === '餐饮') {
      return '#E8503D';
    }
    if (category === '日用') {
      return '#24B36B';
    }
    if (category === '外卖') {
      return '#F5A623';
    }
    return '#8E5BFF';
  }
}

export const BILL_CATEGORIES: string[] = ['水电', '餐饮', '日用', '外卖', '其他'];
