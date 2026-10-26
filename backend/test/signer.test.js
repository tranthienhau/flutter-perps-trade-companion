import assert from 'node:assert/strict';
import test from 'node:test';

import { Wallet, verifyTypedData } from 'ethers';

import { AuditLog } from '../src/audit.js';
import { domain, tradeIntentTypes } from '../src/eip712.js';
import { KeyStore } from '../src/keystore.js';
import { Ledger } from '../src/ledger.js';
import { LIFETIME_S } from '../src/policy.js';
import { Signer } from '../src/signer.js';

const builder = '0xb1d0e5a7c3f92d84e6a1b0c5d7f3e29a8c4b6d10';

async function setup() {
  let now = 1_800_000_000;
  const keystore = new KeyStore({ masterKey: Buffer.alloc(32, 9) });
  const signer = new Signer({ keystore, builder, clock: () => now });
  const user = Wallet.createRandom();
  const req = signer.registerStart(user.address);
  const sig = await user.signTypedData(req.domain, req.types, req.message);
  signer.registerFinish(user.address, req.message, sig);
  return { signer, keystore, user, advance: (s) => (now += s) };
}

test('registration requires the main wallet signature', async () => {
  const { signer } = await setup();
  const victim = Wallet.createRandom();
  const attacker = Wallet.createRandom();
  const req = signer.registerStart(victim.address);
  const forged = await attacker.signTypedData(req.domain, req.types, req.message);
  assert.throws(() => signer.registerFinish(victim.address, req.message, forged), /not from the user wallet/);
});

test('signs an open with the agent key, verifiable on the EIP-712 domain', async () => {
  const { signer, keystore, user } = await setup();
  const out = await signer.signTrade(user.address, { action: 'open', market: 'BTC', side: 'long', bet: 250, leverage: 10, markPx: 67412.5 });
  const { type, ...message } = out.action;
  assert.equal(verifyTypedData(domain, tradeIntentTypes, message, out.signature), keystore.agentAddress(user.address));
});

test('rejects anything that is not open or close', async () => {
  const { signer, user } = await setup();
  await assert.rejects(signer.signTrade(user.address, { action: 'withdraw', market: 'BTC', amount: 1000 }), /action-not-allowed/);
});

test('expired permission blocks signing; exits that cross expiry are blocked', async () => {
  const { signer, user, advance } = await setup();
  advance(LIFETIME_S - 3 * 24 * 3600);
  await assert.rejects(
    signer.signTrade(user.address, { action: 'open', market: 'ETH', side: 'short', bet: 100, leverage: 5, markPx: 3284.1, takeProfit: 3150 }),
    /exits-cross-expiry/,
  );
  assert.equal(signer.status(user.address).state, 'expiring-soon');
  advance(4 * 24 * 3600);
  await assert.rejects(signer.signTrade(user.address, { action: 'close', market: 'ETH', side: 'short', size: 0.1, markPx: 3284.1 }), /expired/);
});

test('keys are encrypted at rest and bound to their user', async () => {
  const { keystore, user } = await setup();
  const rec = keystore.store.get(user.address.toLowerCase());
  assert.ok(!JSON.stringify(rec).includes('privateKey'));
  const other = Wallet.createRandom().address.toLowerCase();
  keystore.store.set(other, rec);
  await assert.rejects(keystore.withSigner(other, async () => {}));
});

test('audit log is hash-chained and detects tampering', async () => {
  const { signer, user } = await setup();
  await signer.signTrade(user.address, { action: 'open', market: 'SOL', side: 'long', bet: 100, leverage: 3, markPx: 148.62 });
  assert.equal(signer.audit.verify().ok, true);
  signer.audit.entries[0].agent = '0xdead';
  assert.equal(signer.audit.verify().ok, false);
});

test('weekly payout: waits for platform, $10 minimum, no carry-over', () => {
  const l = new Ledger();
  l.record('0xA', { notional: 90000, margin: 2000 });
  l.record('0xB', { notional: 2000, margin: 50 });
  assert.equal(l.runWeekly({ week: 43, builderFeePool: 400, platformPayoutReceived: false }).status, 'waiting-for-platform-payout');
  const out = l.runWeekly({ week: 43, builderFeePool: 400, platformPayoutReceived: true });
  assert.deepEqual(out.transfers.map((t) => t.address), ['0xa']);
  assert.equal(l.rows.get('0xb').weekVolume, 0);
  assert.equal(l.rows.get('0xb').totalVolume, 2000);
  assert.equal(l.runWeekly({ week: 43, builderFeePool: 400, platformPayoutReceived: true }).status, 'already-paid');
});

test('AuditLog starts from a zero head', () => {
  assert.equal(new AuditLog().head, '0'.repeat(64));
});
