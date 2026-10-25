import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../nav.dart';
import '../services/permission_policy.dart';
import '../state/providers.dart';
import '../state/trade_flow.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class TradeScreen extends ConsumerWidget {
  const TradeScreen({super.key});

  /// Lets the demo scroll down to the TP/SL rows and price scale.
  static final scroll = ScrollController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(draftProvider);
    final prices = ref.watch(pricesProvider);
    final mark = prices[d.market]!;
    final wallet = ref.watch(walletProvider);
    final perm = ref.watch(permissionProvider);
    final pState = ref.watch(permissionStateProvider);
    final now = ref.watch(clockProvider);
    final n = ref.read(draftProvider.notifier);
    final entry = d.mode == EntryMode.trigger ? (d.triggerPrice ?? mark) : mark;
    final probe = Position(id: '-', market: d.market, side: d.side, leverage: d.leverage, bet: d.bet, entry: entry);

    return Column(children: [
      AppHeader(
        title: 'Trade',
        wallet: wallet,
        trailing: wallet == null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: C.surfaceAlt, borderRadius: BorderRadius.circular(99), border: Border.all(color: C.border)),
                child: Text('PERPS', style: T.overline.copyWith(color: C.ink2)),
              )
            : null,
        onGear: Nav.settings,
      ),
      Expanded(
        child: ListView(controller: TradeScreen.scroll, padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
          if (pState == PermissionState.expiringSoon && perm != null) ...[
            _ExpiryBanner(days: PermissionPolicy.daysLeft(perm, now), until: perm.expiresAt),
            const SizedBox(height: 12),
          ],
          Row(children: [
            for (final m in Market.values) ...[
              Expanded(child: Pill(text: m.symbol, trailing: '${m.maxLeverage}x', selected: d.market == m, onTap: () => n.market(m))),
              if (m != Market.sol) const SizedBox(width: 8),
            ],
          ]),
          const SizedBox(height: 10),
          _LivePrice(market: d.market, price: mark),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: Segmented<Side>(
                values: Side.values,
                selected: d.side,
                onChanged: n.side,
                label: (v, on) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(v == Side.long ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 18, color: on ? (v == Side.long ? C.up : C.down) : C.ink3),
                  const SizedBox(width: 4),
                  Text(v == Side.long ? 'Long' : 'Short',
                      style: T.label.copyWith(fontSize: 15, color: on ? (v == Side.long ? C.up : C.down) : C.ink2)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Segmented<EntryMode>(
                values: EntryMode.values,
                selected: d.mode,
                onChanged: (m) => n.mode(m, mark),
                label: (v, on) => Text(v == EntryMode.now ? 'Now' : 'When hits',
                    style: T.label.copyWith(fontSize: 15, color: on ? C.ink : C.ink2, fontWeight: on ? FontWeight.w700 : FontWeight.w500)),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (d.mode == EntryMode.trigger) ...[
                _TriggerEditor(market: d.market, value: entry, mark: mark, onChanged: n.trigger),
                const SizedBox(height: 14),
                const Divider(color: C.border, height: 1),
                const SizedBox(height: 14),
              ],
              Text('BET SIZE', textAlign: TextAlign.center, style: T.overline),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: usd(d.bet, digits: 0), style: T.num(d.mode == EntryMode.trigger ? 40 : 56)),
                  TextSpan(text: ' USD', style: T.label.copyWith(color: C.ink2)),
                ]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Row(children: [
                for (final b in const [50.0, 100.0, 250.0, 1000.0]) ...[
                  Expanded(child: Pill(text: b == 1000 ? 'Max' : usd(b, digits: 0), selected: d.bet == b, onTap: () => n.bet(b))),
                  if (b != 1000) const SizedBox(width: 8),
                ],
              ]),
              const SizedBox(height: 14),
              _LeverageBox(value: d.leverage, max: d.market.maxLeverage, onChanged: n.leverage),
              const SizedBox(height: 8),
              if (d.mode == EntryMode.now) KV('Est. fill · max slippage 0.5%', usd(mark)),
              KV('Position size', usd(d.notional, digits: 0)),
              KV('Est. liquidation', usd(probe.liquidation, digits: 0)),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.border))),
                child: Row(children: [
                  Expanded(child: Text('Fee', style: T.body.copyWith(fontSize: 15))),
                  Text(r'$0', style: T.num(16, color: C.up, w: FontWeight.w600)),
                  Text(' from Dispatch', style: T.caption.copyWith(color: C.ink2)),
                ]),
              ),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.tune_rounded, size: 20, color: C.ink2),
                const SizedBox(width: 10),
                Expanded(child: Text('Take profit / Stop loss', style: T.label.copyWith(fontSize: 15))),
                Switch(key: const Key('tpsl'), value: d.tpslOn, onChanged: (v) => n.tpsl(v, entry)),
              ]),
              if (d.tpslOn) ...[
                const SizedBox(height: 6),
                _ExitRow(
                    label: 'Take profit',
                    price: d.takeProfit!,
                    entry: entry,
                    pnl: probe.pnl(d.takeProfit!),
                    color: C.up,
                    onTap: () => Nav.tpslEditor(takeProfit: true)),
                const SizedBox(height: 8),
                _ExitRow(
                    label: 'Stop loss',
                    price: d.stopLoss!,
                    entry: entry,
                    pnl: probe.pnl(d.stopLoss!),
                    color: C.down,
                    onTap: () => Nav.tpslEditor(takeProfit: false)),
                const SizedBox(height: 16),
                PriceScale(
                  marks: [
                    ScaleMark('Liq.', probe.liquidation, C.down),
                    ScaleMark('SL', d.stopLoss!, C.down),
                    ScaleMark(d.mode == EntryMode.trigger ? 'Trigger' : 'Entry', entry, C.ink),
                    if (d.mode == EntryMode.trigger) ScaleMark('Now', mark, C.accentFill),
                    ScaleMark('TP', d.takeProfit!, C.up),
                  ],
                ),
              ],
            ]),
          ),
        ]),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
        decoration: const BoxDecoration(color: C.bg, border: Border(top: BorderSide(color: C.border))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          PrimaryButton(key: const Key('post'), label: 'Post trade', icon: Icons.send_outlined, onTap: () => postTrade(WidgetRefAdapter(ref))),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.warning_amber_rounded, size: 15, color: C.warn),
            const SizedBox(width: 4),
            Flexible(
              child: Text('Leverage can lose your whole bet · Liq. ${usd(probe.liquidation, digits: 0)}',
                  textAlign: TextAlign.center, style: T.caption.copyWith(color: C.ink2)),
            ),
          ]),
        ]),
      ),
    ]);
  }
}

class _ExpiryBanner extends StatelessWidget {
  const _ExpiryBanner({required this.days, required this.until});
  final int days;
  final DateTime until;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(color: C.warnTint, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFF0D9BC))),
        child: Row(children: [
          const Icon(Icons.schedule_rounded, color: C.warn, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Trading permission ends in $days days (${DateFormat('d MMM').format(until)}). Renew so your exits stay covered.',
                style: T.label.copyWith(color: C.warn, fontWeight: FontWeight.w500, height: 1.35)),
          ),
          TextButton(
            onPressed: Nav.grantPermission,
            child: Text('Renew', style: T.label.copyWith(color: C.warn, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
          ),
        ]),
      );
}

class _LivePrice extends StatelessWidget {
  const _LivePrice({required this.market, required this.price});
  final Market market;
  final double price;

  @override
  Widget build(BuildContext context) {
    final ch = kDayChange[market]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
      child: Row(children: [
        Container(width: 9, height: 9, decoration: const BoxDecoration(color: C.up, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Text(market.symbol, style: T.label.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(width: 10),
        Text(usd(price), key: const Key('mark'), style: T.num(18, w: FontWeight.w700)),
        const Spacer(),
        Tag(pct(ch), icon: Icons.trending_up_rounded),
      ]),
    );
  }
}

class _TriggerEditor extends StatelessWidget {
  const _TriggerEditor({required this.market, required this.value, required this.mark, required this.onChanged});
  final Market market;
  final double value;
  final double mark;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final step = mark * 0.005;
    final away = (value - mark) / mark * 100;
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text('TRIGGER PRICE', style: T.overline), const SizedBox(width: 6), const Icon(Icons.sell_outlined, size: 15, color: C.ink3)]),
          const SizedBox(height: 4),
          Text(usd(value), key: const Key('trigger'), style: T.displayL),
          const SizedBox(height: 2),
          Text('Now ${usd(mark)} · ${away.abs().toStringAsFixed(1)}% ${away >= 0 ? 'above' : 'below'}', style: T.caption.copyWith(color: C.ink2)),
        ]),
      ),
      _RoundIcon(Icons.remove_rounded, () => onChanged(value - step)),
      const SizedBox(width: 8),
      _RoundIcon(Icons.add_rounded, () => onChanged(value + step)),
    ]);
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: C.surfaceAlt,
        shape: const CircleBorder(side: BorderSide(color: C.border)),
        child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox(width: 44, height: 44, child: Icon(icon, color: C.ink))),
      );
}

class _LeverageBox extends StatelessWidget {
  const _LeverageBox({required this.value, required this.max, required this.onChanged});
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        decoration: BoxDecoration(color: C.surfaceAlt, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.border)),
        child: Column(children: [
          Row(children: [
            Text('Leverage', style: T.label.copyWith(fontSize: 15, color: C.ink2)),
            const SizedBox(width: 6),
            const Icon(Icons.info_outline_rounded, size: 17, color: C.ink3),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: C.accent, borderRadius: BorderRadius.circular(99)),
              child: Text('${value}x', style: T.num(18)),
            ),
          ]),
          Slider(value: value.toDouble(), min: 1, max: max.toDouble(), divisions: max - 1, onChanged: (v) => onChanged(v.round())),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (final t in [1, (max * .2).round(), (max * .5).round(), max])
              Text('${t}x', style: T.caption.copyWith(color: t == value ? C.ink : C.ink3, fontWeight: t == value ? FontWeight.w700 : FontWeight.w500)),
          ]),
        ]),
      );
}

class _ExitRow extends StatelessWidget {
  const _ExitRow({required this.label, required this.price, required this.entry, required this.pnl, required this.color, required this.onTap});
  final String label;
  final double price;
  final double entry;
  final double pnl;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: C.surfaceAlt, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: T.label.copyWith(color: C.ink2))),
            Text(usd(price), style: T.num(16, w: FontWeight.w600)),
            const SizedBox(width: 8),
            Text(pct((price - entry) / entry * 100), style: T.caption),
            const SizedBox(width: 8),
            Text(signedUsd(pnl), style: T.num(15, color: color, w: FontWeight.w700)),
          ]),
        ),
      );
}

class ScaleMark {
  const ScaleMark(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

/// Visual price scale: every level laid out proportionally on one ruler.
class PriceScale extends StatelessWidget {
  const PriceScale({super.key, required this.marks});
  final List<ScaleMark> marks;

  @override
  Widget build(BuildContext context) {
    final lo = marks.map((m) => m.value).reduce((a, b) => a < b ? a : b);
    final hi = marks.map((m) => m.value).reduce((a, b) => a > b ? a : b);
    final sorted = [...marks]..sort((a, b) => a.value.compareTo(b.value));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('PRICE SCALE', style: T.overline),
      const SizedBox(height: 10),
      LayoutBuilder(builder: (_, c) {
        final w = c.maxWidth;
        double x(double v) => hi == lo ? w / 2 : (v - lo) / (hi - lo) * (w - 12) + 6;
        return SizedBox(
          height: 64,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(
                left: 0,
                right: 0,
                top: 14,
                child: Container(height: 6, decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(9)))),
            for (var i = 0; i < sorted.length; i++) ...[
              Positioned(
                left: x(sorted[i].value) - 6,
                top: 11,
                child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: sorted[i].color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
              ),
              Positioned(
                left: (x(sorted[i].value) - 32).clamp(0, w - 64),
                top: i.isEven ? 30 : -6,
                width: 64,
                child: Text(sorted[i].label,
                    textAlign: TextAlign.center, style: T.caption.copyWith(color: sorted[i].color, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              if (i.isEven)
                Positioned(
                  left: (x(sorted[i].value) - 40).clamp(0, w - 80),
                  top: 46,
                  width: 80,
                  child: Text(usd(sorted[i].value, digits: sorted[i].value > 1000 ? 0 : 2),
                      textAlign: TextAlign.center, style: T.caption.copyWith(fontSize: 12)),
                ),
            ],
          ]),
        );
      }),
    ]);
  }
}
