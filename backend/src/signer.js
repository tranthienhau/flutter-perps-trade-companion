import { verifyTypedData } from 'ethers';

import { AuditLog } from './audit.js';
import { ASSETS, approveAgentTypes, domain, tradeIntentTypes } from './eip712.js';
import { KeyStore } from './keystore.js';
import { LIFETIME_S, checkIntent, permissionState } from './policy.js';

/**
 * The only component that touches agent private keys. Flow:
 *  1. registerStart(user)  -> creates the agent key, returns the ApproveAgent
 *                             typed data for the user's main wallet to sign.
 *  2. registerFinish(...)  -> verifies the main-wallet signature, stores the
 *                             permission (agent, validUntil, builder).
 *  3. signTrade(user, d)   -> policy check, build TradeIntent, sign with the
 *                             agent key, audit, return the signed payload for
 *                             the exchange POST.
 */
export class Signer {
  constructor({ keystore, audit = new AuditLog(), builder, clock = () => Math.floor(Date.now() / 1000) }) {
    this.keys = keystore;
    this.audit = audit;
    this.builder = builder;
    this.clock = clock;
    this.permissions = new Map();
    this.nonce = Date.now();
  }

  static dev() {
    return new Signer({
      keystore: new KeyStore({ masterKey: Buffer.alloc(32, 7) }),
      builder: '0xb1d0e5a7c3f92d84e6a1b0c5d7f3e29a8c4b6d10',
    });
  }

  registerStart(user) {
    const agent = this.keys.agentAddress(user) ?? this.keys.create(user);
    const message = { agent, agentName: 'dispatch-session', builder: this.builder, validUntil: this.clock() + LIFETIME_S, nonce: ++this.nonce };
    return { domain, types: approveAgentTypes, primaryType: 'ApproveAgent', message };
  }

  registerFinish(user, message, signature) {
    const recovered = verifyTypedData(domain, approveAgentTypes, message, signature);
    if (recovered.toLowerCase() !== user.toLowerCase()) throw new Error('signature is not from the user wallet');
    if (message.agent !== this.keys.agentAddress(user)) throw new Error('agent mismatch');
    if (message.builder !== this.builder) throw new Error('builder mismatch');
    const p = { agent: message.agent, validUntil: Number(message.validUntil), builder: message.builder, revoked: false };
    this.permissions.set(user.toLowerCase(), p);
    this.audit.append({ user: user.toLowerCase(), action: 'register', agent: p.agent, validUntil: p.validUntil, sig: signature.slice(0, 18) });
    return p;
  }

  revoke(user) {
    const p = this.permissions.get(user.toLowerCase());
    if (p) p.revoked = true;
    this.audit.append({ user: user.toLowerCase(), action: 'revoke' });
  }

  status(user) {
    const p = this.permissions.get(user.toLowerCase());
    return { state: permissionState(p, this.clock()), validUntil: p?.validUntil ?? null };
  }

  async signTrade(user, draft) {
    const u = user.toLowerCase();
    const reason = checkIntent(draft, this.permissions.get(u), this.clock());
    if (reason) {
      this.audit.append({ user: u, action: `reject:${draft.action}`, reason });
      const err = new Error(reason);
      err.code = reason;
      throw err;
    }
    const px = draft.triggerPx ?? draft.markPx;
    const reduceOnly = draft.action === 'close';
    const message = {
      account: user,
      asset: ASSETS[draft.market],
      isBuy: (draft.side === 'long') !== reduceOnly,
      size: (draft.action === 'open' ? (draft.bet * draft.leverage) / px : draft.size).toFixed(5),
      limitPx: px.toFixed(2),
      triggerPx: draft.triggerPx ? draft.triggerPx.toFixed(2) : '0',
      reduceOnly,
      nonce: ++this.nonce,
    };
    const signature = await this.keys.withSigner(u, (w) => w.signTypedData(domain, tradeIntentTypes, message));
    const entry = this.audit.append({ user: u, action: draft.action, market: draft.market, nonce: message.nonce, sig: signature.slice(0, 18) });
    return { action: { type: 'order', ...message }, signature, auditSeq: entry.seq };
  }
}
