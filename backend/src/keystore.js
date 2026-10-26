import crypto from 'node:crypto';
import { Wallet } from 'ethers';

/**
 * One agent keypair per user, stored encrypted at rest with envelope
 * encryption: each key gets its own random data key (AES-256-GCM), and the
 * data key is wrapped by a master key. In production the master key lives in
 * the cloud KMS and wrap/unwrap are KMS calls; here it comes from
 * MASTER_KEY_HEX so the flow is testable offline.
 */
export class KeyStore {
  constructor({ masterKey, store = new Map() }) {
    if (!masterKey || masterKey.length !== 32) throw new Error('master key must be 32 bytes');
    this.masterKey = masterKey;
    this.store = store;
  }

  static fromEnv(env = process.env) {
    return new KeyStore({ masterKey: Buffer.from(env.MASTER_KEY_HEX ?? '', 'hex') });
  }

  #seal(key, plaintext, aad) {
    const iv = crypto.randomBytes(12);
    const c = crypto.createCipheriv('aes-256-gcm', key, iv);
    c.setAAD(Buffer.from(aad));
    const ct = Buffer.concat([c.update(plaintext), c.final()]);
    return { iv: iv.toString('base64'), ct: ct.toString('base64'), tag: c.getAuthTag().toString('base64') };
  }

  #open(key, box, aad) {
    const d = crypto.createDecipheriv('aes-256-gcm', key, Buffer.from(box.iv, 'base64'));
    d.setAAD(Buffer.from(aad));
    d.setAuthTag(Buffer.from(box.tag, 'base64'));
    return Buffer.concat([d.update(Buffer.from(box.ct, 'base64')), d.final()]);
  }

  /** Creates the agent key for a user wallet. Returns only the public address. */
  create(userAddress) {
    const user = userAddress.toLowerCase();
    const agent = Wallet.createRandom();
    const dataKey = crypto.randomBytes(32);
    const record = {
      agentAddress: agent.address,
      // AAD binds the ciphertext to this user: a row copied to another user fails to decrypt.
      key: this.#seal(dataKey, Buffer.from(agent.privateKey.slice(2), 'hex'), user),
      wrappedDataKey: this.#seal(this.masterKey, dataKey, `dk:${user}`),
      createdAt: new Date().toISOString(),
    };
    dataKey.fill(0);
    this.store.set(user, record);
    return agent.address;
  }

  agentAddress(userAddress) {
    return this.store.get(userAddress.toLowerCase())?.agentAddress;
  }

  /** Decrypts in memory only for the duration of fn, then zeroes the buffers. */
  async withSigner(userAddress, fn) {
    const user = userAddress.toLowerCase();
    const rec = this.store.get(user);
    if (!rec) throw new Error('no agent key for user');
    const dataKey = this.#open(this.masterKey, rec.wrappedDataKey, `dk:${user}`);
    const pk = this.#open(dataKey, rec.key, user);
    try {
      return await fn(new Wallet(`0x${pk.toString('hex')}`));
    } finally {
      pk.fill(0);
      dataKey.fill(0);
    }
  }
}
