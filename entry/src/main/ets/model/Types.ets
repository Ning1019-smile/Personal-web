// 宿舍分布式协作板 - 核心数据模型

// 宿舍成员
export interface Member {
  id: string;
  name: string;
  color: string;
}

// 白板便签
export interface Note {
  id: string;
  text: string;
  authorId: string;
  updatedAt: number;
}

// 值日任务（按天生成）
export interface DutyTask {
  id: string;
  name: string;
  done: boolean;
  dateKey: string;
  assigneeId: string;
}

// 账单
export interface Bill {
  id: string;
  title: string;
  category: string;
  amount: number;
  payerId: string;
  participantIds: string[];
  dateText: string;
  settled: boolean;
  createdAt: number;
}

// 全宿舍共享状态（分布式数据对象中以此结构同步）
export interface DormState {
  dormName: string;
  members: Member[];
  notes: Note[];
  bills: Bill[];
  // 值日轮换顺序
  dutyMemberIds: string[];
  // 当前值日在轮换顺序中的偏移
  dutyOffset: number;
  // 当前任务所属日期（YYYY-MM-DD）
  dutyDate: string;
  dutyTasks: DutyTask[];
}

// 一笔转账建议
export interface Transfer {
  fromId: string;
  toId: string;
  amount: number;
}
