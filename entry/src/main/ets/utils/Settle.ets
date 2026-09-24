import { Bill, Member, Transfer } from '../model/Types';
import { Util } from './Util';

// 单人结算结果
export interface Balance {
  memberId: string;
  paid: number;   // 已垫付
  owed: number;   // 应分摊
  net: number;    // 净额：正=别人欠 TA，负=TA 欠别人
}

export interface SettleResult {
  balances: Balance[];
  transfers: Transfer[];
  total: number;
}

// 根据未结清账单计算 AA 分账（贪心配对，给出最少转账建议）
export function computeSettle(bills: Bill[], members: Member[]): SettleResult {
  const paidMap: Map<string, number> = new Map<string, number>();
  const owedMap: Map<string, number> = new Map<string, number>();
  let total: number = 0;

  bills.forEach((b: Bill) => {
    if (b.settled || b.participantIds.length === 0) {
      return;
    }
    total += b.amount;
    const beforePaid: number = paidMap.get(b.payerId) ?? 0;
    paidMap.set(b.payerId, beforePaid + b.amount);
    const share: number = b.amount / b.participantIds.length;
    b.participantIds.forEach((pid: string) => {
      const beforeOwed: number = owedMap.get(pid) ?? 0;
      owedMap.set(pid, beforeOwed + share);
    });
  });

  const balances: Balance[] = members.map((m: Member): Balance => {
    const paid: number = paidMap.get(m.id) ?? 0;
    const owed: number = owedMap.get(m.id) ?? 0;
    const net: number = Math.round((paid - owed) * 100) / 100;
    const item: Balance = { memberId: m.id, paid: paid, owed: owed, net: net };
    return item;
  });

  // 贪心：最欠钱的人还给最应收钱的人
  const debtors: Balance[] = balances.filter((x: Balance) => x.net < -0.01);
  const creditors: Balance[] = balances.filter((x: Balance) => x.net > 0.01);
  const transfers: Transfer[] = [];

  let i: number = 0;
  let j: number = 0;
  // 副本用于配对时扣减
  const dRemain: number[] = debtors.map((x: Balance) => -x.net);
  const cRemain: number[] = creditors.map((x: Balance) => x.net);

  while (i < debtors.length && j < creditors.length) {
    const pay: number = Math.min(dRemain[i], cRemain[j]);
    if (pay >= 0.01) {
      const transfer: Transfer = {
        fromId: debtors[i].memberId,
        toId: creditors[j].memberId,
        amount: Math.round(pay * 100) / 100
      };
      transfers.push(transfer);
    }
    dRemain[i] -= pay;
    cRemain[j] -= pay;
    if (dRemain[i] < 0.01) {
      i++;
    }
    if (cRemain[j] < 0.01) {
      j++;
    }
  }

  return { balances: balances, transfers: transfers, total: Math.round(total * 100) / 100 };
}

export function money(n: number): string {
  return Util.money(n);
}
