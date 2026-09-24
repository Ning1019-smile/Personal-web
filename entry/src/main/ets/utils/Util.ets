// 通用小工具
export class Util {
  static genId(prefix: string): string {
    return `${prefix}_${Date.now()}_${Math.floor(Math.random() * 100000)}`;
  }

  // 今天日期键 YYYY-MM-DD
  static todayKey(): string {
    return Util.dateKey(new Date());
  }

  static dateKey(d: Date): string {
    const m: string = d.getMonth() + 1 < 10 ? `0${d.getMonth() + 1}` : `${d.getMonth() + 1}`;
    const day: string = d.getDate() < 10 ? `0${d.getDate()}` : `${d.getDate()}`;
    return `${d.getFullYear()}-${m}-${day}`;
  }

  // 时间戳格式化为 MM-dd HH:mm
  static fmtTime(ts: number): string {
    const d: Date = new Date(ts);
    const m: string = d.getMonth() + 1 < 10 ? `0${d.getMonth() + 1}` : `${d.getMonth() + 1}`;
    const day: string = d.getDate() < 10 ? `0${d.getDate()}` : `${d.getDate()}`;
    const hh: string = d.getHours() < 10 ? `0${d.getHours()}` : `${d.getHours()}`;
    const mm: string = d.getMinutes() < 10 ? `0${d.getMinutes()}` : `${d.getMinutes()}`;
    return `${m}-${day} ${hh}:${mm}`;
  }

  // 金额保留两位（消除浮点误差）
  static money(n: number): string {
    return (Math.round(n * 100) / 100).toFixed(2);
  }

  // 由宿舍名生成分布式会话号：
  // 分布式 sessionId 只允许字母/数字/下划线/中划线，中文宿舍名需先哈希；
  // 同名宿舍哈希结果相同，室友输入相同宿舍名即可自动进入同一协同房间
  static dormSessionId(dormName: string): string {
    let h: number = 0x811c9dc5;
    for (let i = 0; i < dormName.length; i++) {
      h ^= dormName.charCodeAt(i);
      h = Math.imul(h, 0x01000193);
    }
    return `dormboard_${(h >>> 0).toString(16)}`;
  }
}
