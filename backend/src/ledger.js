/**
 * Points ledger keyed by wallet: cumulative volume (never resets), current
 * week volume and margin risked (reset weekly). The weekly job shares half of
 * the builder fee pool by score, pays only addresses at or above the $10
 * minimum (no carry-over), and runs only after the platform payout landed.
 */
export const MIN_PAYOUT_USDC = 10;
export const USER_SHARE = 0.5;

export class Ledger {
  constructor() {
    this.rows = new Map();
    this.payouts = [];
  }

  record(address, { notional, margin }) {
    const a = address.toLowerCase();
    const r = this.rows.get(a) ?? { address: a, totalVolume: 0, weekVolume: 0, weekMargin: 0 };
    r.totalVolume += notional;
    r.weekVolume += notional;
    r.weekMargin += margin;
    this.rows.set(a, r);
  }

  static score(r) {
    return r.weekVolume + 10 * r.weekMargin;
  }

  ranking() {
    return [...this.rows.values()].sort((x, y) => Ledger.score(y) - Ledger.score(x)).map((r, i) => ({ rank: i + 1, ...r }));
  }

  /** Returns the transfers to send; the caller sends USDC with the payout wallet (prod key, never in this repo). */
  runWeekly({ week, builderFeePool, platformPayoutReceived }) {
    if (!platformPayoutReceived) return { week, status: 'waiting-for-platform-payout', transfers: [] };
    if (this.payouts.some((p) => p.week === week)) return { week, status: 'already-paid', transfers: [] };
    const rows = [...this.rows.values()];
    const total = rows.reduce((s, r) => s + Ledger.score(r), 0);
    const pool = builderFeePool * USER_SHARE;
    const shares = rows.map((r) => ({ address: r.address, amount: total ? Math.floor((pool * Ledger.score(r)) / total * 100) / 100 : 0 }));
    const transfers = shares.filter((s) => s.amount >= MIN_PAYOUT_USDC);
    this.payouts.push({ week, transfers, skipped: shares.filter((s) => s.amount < MIN_PAYOUT_USDC) });
    for (const r of rows) {
      r.weekVolume = 0;
      r.weekMargin = 0;
    }
    return { week, status: 'paid', transfers };
  }
}
