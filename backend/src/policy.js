import { ASSETS } from './eip712.js';

export const LIFETIME_S = 30 * 24 * 3600;
export const WARN_S = 5 * 24 * 3600;
export const EXIT_HORIZON_S = 7 * 24 * 3600;
const MAX_LEVERAGE = { BTC: 50, ETH: 50, SOL: 20 };

/**
 * Server-side allowlist. The signer refuses anything that is not an open or
 * close the user built in the app, even though the exchange would also
 * reject a transfer signed by an agent key (defense in depth).
 */
export function checkIntent(draft, permission, nowS) {
  if (!permission || permission.revoked) return 'no-permission';
  if (nowS >= permission.validUntil) return 'expired';
  if (!['open', 'close'].includes(draft.action)) return 'action-not-allowed';
  if (!(draft.market in ASSETS)) return 'unknown-market';
  if (draft.action === 'open') {
    if (!(draft.leverage >= 1 && draft.leverage <= MAX_LEVERAGE[draft.market])) return 'leverage-out-of-range';
    if (!(draft.bet > 0 && draft.bet <= 100000)) return 'bet-out-of-range';
    if (draft.takeProfit && nowS + EXIT_HORIZON_S > permission.validUntil) return 'exits-cross-expiry';
  }
  return null;
}

export function permissionState(permission, nowS) {
  if (!permission || permission.revoked) return 'none';
  if (nowS >= permission.validUntil) return 'expired';
  if (permission.validUntil - nowS <= WARN_S) return 'expiring-soon';
  return 'active';
}
