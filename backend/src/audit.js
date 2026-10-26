import crypto from 'node:crypto';
import fs from 'node:fs';

/**
 * Append-only, hash-chained signing log. Each entry commits to the previous
 * entry's hash, so deleting or editing any line breaks verify(). In
 * production this is a write-once table (or object-lock bucket); the file
 * keeps the POC dependency-free.
 */
export class AuditLog {
  constructor(path = null) {
    this.path = path;
    this.entries = [];
    if (path && fs.existsSync(path)) {
      this.entries = fs.readFileSync(path, 'utf8').split('\n').filter(Boolean).map((l) => JSON.parse(l));
    }
  }

  get head() {
    return this.entries.at(-1)?.hash ?? '0'.repeat(64);
  }

  static hashOf(e) {
    const { hash, ...body } = e;
    return crypto.createHash('sha256').update(JSON.stringify(body)).digest('hex');
  }

  append(event) {
    const e = { seq: this.entries.length, at: new Date().toISOString(), prev: this.head, ...event };
    e.hash = AuditLog.hashOf(e);
    this.entries.push(e);
    if (this.path) fs.appendFileSync(this.path, `${JSON.stringify(e)}\n`);
    return e;
  }

  verify() {
    let prev = '0'.repeat(64);
    for (const e of this.entries) {
      if (e.prev !== prev || AuditLog.hashOf(e) !== e.hash) return { ok: false, brokenAt: e.seq };
      prev = e.hash;
    }
    return { ok: true, count: this.entries.length };
  }
}
