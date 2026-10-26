import http from 'node:http';

import { Ledger } from './ledger.js';
import { Signer } from './signer.js';

/**
 * Minimal JSON API the Flutter app talks to. Auth (Firebase ID token) and the
 * exchange POST are stubbed: the response returns the signed action the
 * backend would forward to the exchange endpoint.
 */
const signer = Signer.dev();
const ledger = new Ledger();

const routes = {
  'POST /session/start': ({ user }) => signer.registerStart(user),
  'POST /session/finish': ({ user, message, signature }) => signer.registerFinish(user, message, signature),
  'GET /session/status': ({ user }) => signer.status(user),
  'POST /trade': async ({ user, draft }) => {
    const signed = await signer.signTrade(user, draft);
    if (draft.action === 'open') ledger.record(user, { notional: draft.bet * draft.leverage, margin: draft.bet });
    return signed;
  },
  'GET /audit/verify': () => signer.audit.verify(),
};

http
  .createServer(async (req, res) => {
    const url = new URL(req.url, 'http://x');
    const key = `${req.method} ${url.pathname}`;
    let body = '';
    for await (const chunk of req) body += chunk;
    const input = req.method === 'GET' ? Object.fromEntries(url.searchParams) : JSON.parse(body || '{}');
    try {
      const out = await routes[key]?.(input);
      res.writeHead(out ? 200 : 404, { 'content-type': 'application/json' });
      res.end(JSON.stringify(out ?? { error: 'not found' }));
    } catch (e) {
      res.writeHead(400, { 'content-type': 'application/json' });
      res.end(JSON.stringify({ error: e.code ?? e.message }));
    }
  })
  .listen(process.env.PORT ?? 8787, () => console.log(`dispatch-signer on :${process.env.PORT ?? 8787}`));
