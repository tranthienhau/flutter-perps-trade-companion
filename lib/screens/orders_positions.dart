import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../nav.dart';
import '../state/providers.dart';
import '../state/trade_flow.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

String _sideLabel(Side s, Market m, int lev) => '${s == Side.long ? 'Long' : 'Short'} ${m.symbol} · ${lev}x';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider).where((o) => o.status != OrderStatus.cancelled && o.status != OrderStatus.filled).toList();
    final waiting = orders.where((o) => o.isWaiting).toList();
    final done = orders.where((o) => !o.isWaiting).toList();
    final seg = ref.watch(ordersSegmentProvider);
    final prices = ref.watch(pricesProvider);
    return Column(children: [
      AppHeader(title: 'Orders', overline: 'POSTAL DESK', wallet: ref.watch(walletProvider)),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        child: Segmented<int>(
          values: const [0, 1],
          selected: seg,
          onChanged: (v) => ref.read(ordersSegmentProvider.notifier).state = v,
          label: (v, on) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(v == 0 ? 'Waiting' : 'Completed', style: T.label.copyWith(fontSize: 15, color: on ? C.ink : C.ink2)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(color: on ? C.accent : C.border, borderRadius: BorderRadius.circular(99)),
              child: Text('${v == 0 ? waiting.length : done.length}', style: T.caption.copyWith(color: C.ink, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
      Expanded(
        child: orders.isEmpty
            ? const _Empty(
                photo: 'assets/images/empty-mailbox.jpg',
                title: 'No letters in the box yet',
                body: 'Trades waiting for a price and finished trades show up here.')
            : ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
                if (seg == 0) ...[
                  Row(children: [
                    const Icon(Icons.schedule_rounded, size: 18, color: C.ink3),
                    const SizedBox(width: 6),
                    Text('WAITING FOR PRICE (${waiting.length})', style: T.overline),
                    const Spacer(),
                    Text('Live', style: T.caption),
                  ]),
                  const SizedBox(height: 10),
                  for (final o in waiting) ...[_WaitingCard(order: o, mark: prices[o.market]!), const SizedBox(height: 12)],
                  if (waiting.isEmpty) Text('Nothing waiting. Pick "When hits" on the trade screen to queue an order.', style: T.body),
                ],
                if (seg == 1) ...[
                  Text('COMPLETED (${done.length})', style: T.overline),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(children: [for (final o in done) _DoneRow(order: o, last: o == done.last)]),
                  ),
                ],
                const SizedBox(height: 18),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.mark_email_read_outlined, size: 16, color: C.ink3),
                  const SizedBox(width: 6),
                  Text('Trigger orders wait on the exchange until price hits', style: T.caption.copyWith(color: C.ink2)),
                ]),
              ]),
      ),
    ]);
  }
}

class _WaitingCard extends ConsumerWidget {
  const _WaitingCard({required this.order, required this.mark});
  final Order order;
  final double mark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = order.triggerPrice!;
    final away = ((t - mark) / mark * 100).abs();
    return AppCard(
      perforated: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Tag.side(order.side, _sideLabel(order.side, order.market, order.leverage)),
          const SizedBox(width: 10),
          Text('#${order.id}', style: T.mono),
          const Spacer(),
          TextButton(
            onPressed: () => ref.read(ordersProvider.notifier).cancel(order.id),
            child: Text('Cancel', style: T.label.copyWith(color: C.ink2, decoration: TextDecoration.underline)),
          ),
        ]),
        const SizedBox(height: 6),
        Text('WHEN PRICE HITS', style: T.overline),
        const SizedBox(height: 2),
        Text(usd(t), style: T.num(34)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: C.surfaceAlt, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
          child: Column(children: [
            Row(children: [
              Text('Now ', style: T.label.copyWith(color: C.ink2)),
              Text(usd(mark), style: T.num(15, w: FontWeight.w700)),
              const Spacer(),
              Text('${away.toStringAsFixed(1)}% away', style: T.label.copyWith(color: C.accentFill, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: LinearProgressIndicator(
                value: (1 - away / 10).clamp(0.05, 1),
                minHeight: 6,
                backgroundColor: C.border,
                valueColor: const AlwaysStoppedAnimation(C.accentFill),
              ),
            ),
          ]),
        ),
        if (order.takeProfit != null) ...[
          const SizedBox(height: 12),
          Row(children: [
            Tag('TP ${usd(order.takeProfit!)}', icon: Icons.verified_outlined),
            const SizedBox(width: 8),
            Tag('SL ${usd(order.stopLoss!)}', fg: C.down, bg: C.downTint, icon: Icons.shield_outlined),
            const Spacer(),
            Text('Bet ${usd(order.bet, digits: 0)}', style: T.caption.copyWith(color: C.ink2)),
          ]),
        ],
      ]),
    );
  }
}

class _DoneRow extends StatelessWidget {
  const _DoneRow({required this.order, required this.last});
  final Order order;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final pnl = order.realizedPnl ?? 0;
    final why = switch (order.status) {
      OrderStatus.closedTp => 'Closed by take profit',
      OrderStatus.stoppedOut => 'Stopped out',
      _ => 'Closed manually',
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: C.border))),
      child: Row(children: [
        Postmark(ok: pnl >= 0),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: _sideLabel(order.side, order.market, order.leverage), style: T.label.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
              TextSpan(text: '  ${DateFormat('d MMM').format(order.createdAt)}', style: T.caption),
            ])),
            Text(why, style: T.caption.copyWith(color: C.ink2)),
          ]),
        ),
        Tag(signedUsd(pnl), fg: pnl >= 0 ? C.up : C.down, bg: pnl >= 0 ? C.upTint : C.downTint),
      ]),
    );
  }
}

class _Empty extends ConsumerWidget {
  const _Empty({required this.photo, required this.title, required this.body});
  final String photo;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(padding: const EdgeInsets.fromLTRB(28, 24, 28, 24), children: [
        RoundedPhoto(photo, height: 230),
        const SizedBox(height: 24),
        Text(title, textAlign: TextAlign.center, style: T.num(26, w: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center, style: T.body),
        const SizedBox(height: 22),
        PrimaryButton(label: 'Build a trade', icon: Icons.send_outlined, onTap: () => ref.read(tabProvider.notifier).state = 0),
      ]);
}

class PositionsScreen extends ConsumerWidget {
  const PositionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positions = ref.watch(positionsProvider);
    final prices = ref.watch(pricesProvider);
    final total = ref.watch(openPnlProvider);
    final invested = positions.fold<double>(0, (s, p) => s + p.bet);
    return Column(children: [
      AppHeader(
        title: 'Positions',
        overline: 'LIVE DESK',
        wallet: ref.watch(walletProvider),
      ),
      Expanded(
        child: positions.isEmpty
            ? const _Empty(
                photo: 'assets/images/envelope-stack.jpg',
                title: 'Nothing open right now',
                body: 'Open trades appear here with live profit and loss.')
            : ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
                AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('OPEN P&L · ${positions.length} POSITIONS', style: T.overline),
                      const Spacer(),
                      const Tag('Live', icon: Icons.circle),
                    ]),
                    const SizedBox(height: 6),
                    Text(signedUsd(total), key: const Key('openPnl'), style: T.num(44, color: total >= 0 ? C.up : C.down)),
                    const SizedBox(height: 4),
                    Text('${pct(invested == 0 ? 0 : total / invested * 100)} on ${usd(invested, digits: 0)} margin', style: T.caption.copyWith(color: C.ink2)),
                  ]),
                ),
                const SizedBox(height: 12),
                for (final p in positions) ...[_PositionCard(p: p, mark: prices[p.market]!), const SizedBox(height: 12)],
              ]),
      ),
    ]);
  }
}

class _PositionCard extends StatelessWidget {
  const _PositionCard({required this.p, required this.mark});
  final Position p;
  final double mark;

  @override
  Widget build(BuildContext context) {
    final pnl = p.pnl(mark);
    final c = pnl >= 0 ? C.up : C.down;
    return AppCard(
      perforated: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Tag.side(p.side, _sideLabel(p.side, p.market, p.leverage)),
          const Spacer(),
          Text(pct(p.pnlPct(mark)), style: T.label.copyWith(color: c, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        Text('UNREALIZED P&L', style: T.overline),
        Text(signedUsd(pnl), style: T.num(32, color: c)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _Mini('Entry', usd(p.entry))),
          Expanded(child: _Mini('Mark', usd(mark))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _Mini('Size', usd(p.size, digits: 0))),
          Expanded(child: _Mini('Liq. price', usd(p.liquidation), color: C.down)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          if (p.takeProfit != null) Tag('TP ${usd(p.takeProfit!, digits: 0)}'),
          if (p.stopLoss != null) ...[const SizedBox(width: 8), Tag('SL ${usd(p.stopLoss!, digits: 0)}', fg: C.down, bg: C.downTint)],
          const Spacer(),
          SizedBox(
            height: 44,
            child: OutlinedButton(
              key: Key('close-${p.id}'),
              onPressed: () => Nav.closePosition(p),
              style: OutlinedButton.styleFrom(shape: const StadiumBorder(), side: const BorderSide(color: C.ink, width: 1.5)),
              child: Text('Close', style: T.label.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.k, this.v, {this.color = C.ink});
  final String k;
  final String v;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k, style: T.caption),
        Text(v, style: T.num(16, color: color, w: FontWeight.w600)),
      ]);
}

class ClosePositionSheet extends ConsumerWidget {
  const ClosePositionSheet({super.key, required this.position});
  final Position position;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mark = ref.watch(pricesProvider)[position.market]!;
    final pnl = position.pnl(mark);
    final c = pnl >= 0 ? C.up : C.down;
    return SheetFrame(
      onClose: Nav.pop,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Close ${_sideLabel(position.side, position.market, position.leverage)}?', style: T.num(26, w: FontWeight.w600)),
        const SizedBox(height: 14),
        AppCard(
          color: pnl >= 0 ? C.upTint : C.downTint,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ESTIMATED RETURN', style: T.overline),
            const SizedBox(height: 4),
            Row(children: [
              Text(signedUsd(pnl), style: T.num(44, color: c)),
              const Spacer(),
              Tag(pct(position.pnlPct(mark)), fg: c, bg: Colors.white),
            ]),
          ]),
        ),
        const SizedBox(height: 8),
        KV('Entry price', usd(position.entry)),
        KV('Mark price', usd(mark)),
        KV('Position size', usd(position.size)),
        KV('You keep (bet + P&L)', usd(position.bet + pnl), vColor: c),
        KV('Dispatch fee', r'$0.00', vColor: C.up, divider: false),
        const SizedBox(height: 10),
        const InfoNote(icon: Icons.key_rounded, text: 'Signed by your 30-day permission. No wallet pop-up.'),
        const SizedBox(height: 14),
        PrimaryButton(
            key: const Key('confirm-close'),
            label: 'Close position',
            icon: Icons.arrow_forward_rounded,
            onTap: () => closePosition(WidgetRefAdapter(ref), position)),
        const SizedBox(height: 10),
        SecondaryButton(label: 'Keep open', onTap: Nav.pop),
      ]),
    );
  }
}
