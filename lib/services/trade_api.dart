import 'dart:convert';

import '../data/mock_data.dart';
import '../models/models.dart';
import 'eip712.dart';

class AuditEntry {
  const AuditEntry(this.at, this.action, this.digest, this.prevHash, this.hash);
  final DateTime at;
  final String action;
  final String digest;
  final String prevHash;
  final String hash;
}

/// Client for the Dispatch backend. In this POC the backend is in-process:
/// it builds the EIP-712 intent, "signs" with the custodied agent key and
/// appends to a hash-chained audit log. The real signer lives in backend/
/// (Node) with envelope encryption; the app only ever sends a draft.
class TradeApi {
  final List<AuditEntry> audit = [];
  int _nonce = 1761487000000;
  int _orderSeq = 8830;

  Eip712Message approveAgentMessage(Wallet w, DateTime now) => Eip712Message(exchangeDomain, approveAgentType, {
        'agent': kAgentAddress,
        'agentName': 'dispatch-session',
        'builder': kBuilderAddress,
        'validUntil': now.add(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000,
        'nonce': ++_nonce,
      });

  Eip712Message tradeIntent(Wallet w, TradeDraft d, double mark, {bool reduceOnly = false}) {
    final px = d.mode == EntryMode.trigger ? d.triggerPrice ?? mark : mark;
    final size = d.notional / px;
    return Eip712Message(exchangeDomain, tradeIntentType, {
      'account': w.address,
      'asset': d.market.assetIndex,
      'isBuy': (d.side == Side.long) != reduceOnly,
      'size': size.toStringAsFixed(5),
      'limitPx': px.toStringAsFixed(2),
      'triggerPx': d.mode == EntryMode.trigger ? px.toStringAsFixed(2) : '0',
      'reduceOnly': reduceOnly,
      'nonce': ++_nonce,
    });
  }

  String _sign(String action, Eip712Message m) {
    final digest = toHex(m.digest);
    final prev = audit.isEmpty ? '0x${'0' * 64}' : audit.last.hash;
    final hash = toHex(keccak256(utf8.encode('$prev|$action|$digest')));
    audit.add(AuditEntry(DateTime.now(), action, digest, prev, hash));
    return hash;
  }

  Future<Order> post(Wallet w, TradeDraft d, double mark) async {
    _sign('open', tradeIntent(w, d, mark));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return Order(
      id: '${_orderSeq++}',
      market: d.market,
      side: d.side,
      leverage: d.leverage,
      bet: d.bet,
      status: d.mode == EntryMode.trigger ? OrderStatus.waiting : OrderStatus.filled,
      createdAt: kNow,
      triggerPrice: d.mode == EntryMode.trigger ? d.triggerPrice : null,
      takeProfit: d.tpslOn ? d.takeProfit : null,
      stopLoss: d.tpslOn ? d.stopLoss : null,
    );
  }

  Future<void> close(Wallet w, Position p, double mark) async {
    final d = TradeDraft(market: p.market, side: p.side, bet: p.bet, leverage: p.leverage);
    _sign('close', tradeIntent(w, d, mark, reduceOnly: true));
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
}
