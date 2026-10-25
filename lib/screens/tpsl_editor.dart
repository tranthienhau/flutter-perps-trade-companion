import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../nav.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'trade_screen.dart';

/// Edit take profit or stop loss as an absolute price or a % move from entry.
class TpSlEditorSheet extends ConsumerStatefulWidget {
  const TpSlEditorSheet({super.key, required this.takeProfit});
  final bool takeProfit;

  @override
  ConsumerState<TpSlEditorSheet> createState() => _TpSlEditorSheetState();
}

class _TpSlEditorSheetState extends ConsumerState<TpSlEditorSheet> {
  bool percent = true;
  String input = '';

  double get _entry {
    final d = ref.read(draftProvider);
    return d.mode == EntryMode.trigger ? d.triggerPrice! : ref.read(pricesProvider)[d.market]!;
  }

  int get _dir {
    final long = ref.read(draftProvider).side == Side.long;
    return (widget.takeProfit == long) ? 1 : -1;
  }

  @override
  void initState() {
    super.initState();
    final d = ref.read(draftProvider);
    final cur = widget.takeProfit ? d.takeProfit : d.stopLoss;
    if (cur != null) input = (((cur - _entry) / _entry * 100).abs()).toStringAsFixed(0);
  }

  double get _value {
    final v = double.tryParse(input) ?? 0;
    return percent ? _entry * (1 + _dir * v / 100) : (v == 0 ? _entry : v);
  }

  void _key(String k) => setState(() {
        if (k == '<') {
          if (input.isNotEmpty) input = input.substring(0, input.length - 1);
        } else if (!(k == '.' && input.contains('.')) && input.length < 9) {
          input += k;
        }
      });

  void _save() {
    final n = ref.read(draftProvider.notifier);
    widget.takeProfit ? n.takeProfit(_value) : n.stopLoss(_value);
    Nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(draftProvider);
    final probe = Position(id: '-', market: d.market, side: d.side, leverage: d.leverage, bet: d.bet, entry: _entry);
    final color = widget.takeProfit ? C.up : C.down;
    final title = widget.takeProfit ? 'Take profit' : 'Stop loss';
    return SheetFrame(
      onClose: Nav.pop,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: T.num(26, w: FontWeight.w600)),
        Text('${d.side == Side.long ? 'Long' : 'Short'} ${d.market.symbol} · ${d.leverage}x · entry ${usd(_entry)}', style: T.caption),
        const SizedBox(height: 14),
        Segmented<bool>(
          values: const [false, true],
          selected: percent,
          onChanged: (v) => setState(() {
            percent = v;
            input = '';
          }),
          label: (v, on) => Text(v ? 'Percent' : 'Price', style: T.label.copyWith(color: on ? C.ink : C.ink2)),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: C.border)),
          child: Column(children: [
            Text(percent ? '${_dir > 0 ? '+' : '-'}${input.isEmpty ? '0' : input}%' : usd(_value), style: T.displayL),
            const SizedBox(height: 8),
            Tag('= ${usd(_value)} · est. ${signedUsd(probe.pnl(_value))}', fg: color, bg: widget.takeProfit ? C.upTint : C.downTint),
          ]),
        ),
        const SizedBox(height: 12),
        if (percent)
          Row(children: [
            for (final p in const ['5', '10', '12', '25']) ...[
              Expanded(child: Pill(text: '${_dir > 0 ? '+' : '-'}$p%', selected: input == p, onTap: () => setState(() => input = p))),
              if (p != '25') const SizedBox(width: 8),
            ],
          ]),
        const SizedBox(height: 12),
        PriceScale(marks: [
          ScaleMark('Liq.', probe.liquidation, C.down),
          ScaleMark('Entry', _entry, C.ink),
          ScaleMark(widget.takeProfit ? 'TP' : 'SL', _value, color),
        ]),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.9,
          children: [
            for (final k in const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '<'])
              Material(
                color: C.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _key(k),
                  child: Center(
                      child: k == '<' ? const Icon(Icons.backspace_outlined, color: C.ink2) : Text(k, style: T.num(22, w: FontWeight.w600))),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        PrimaryButton(label: 'Set ${title.toLowerCase()}', icon: Icons.check_rounded, onTap: _save),
        TextButton(
          onPressed: () {
            ref.read(draftProvider.notifier).tpsl(false, _entry);
            Nav.pop();
          },
          child: Text('Remove ${title.toLowerCase()}', style: T.label.copyWith(color: C.ink2)),
        ),
      ]),
    );
  }
}
