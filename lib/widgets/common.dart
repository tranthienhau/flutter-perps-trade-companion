import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

final _usd = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
final _usd0 = NumberFormat.currency(symbol: r'$', decimalDigits: 0);
String usd(double v, {int digits = 2}) => digits == 0 ? _usd0.format(v) : _usd.format(v);
String signedUsd(double v) => '${v >= 0 ? '+' : '-'}${_usd.format(v.abs())}';
String pct(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(v.abs() >= 10 ? 1 : 2)}%';
String px(Market m, double v) => usd(v, digits: m == Market.sol ? 2 : 2);

/// Circular postmark badge: envelope inside a dashed ring, as in the design header.
class StampMark extends StatelessWidget {
  const StampMark({super.key, this.size = 40, this.live = false});
  final double size;
  final bool live;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(clipBehavior: Clip.none, children: [
          CustomPaint(size: Size.square(size), painter: _DashedRing()),
          Center(child: Icon(Icons.mail_outline_rounded, size: size * .48, color: C.accentFill)),
          if (live)
            Positioned(
              right: 0,
              bottom: 1,
              child: Container(
                  width: 10, height: 10, decoration: BoxDecoration(color: C.accent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
            ),
        ]),
      );
}

class _DashedRing extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width / 2 - 1;
    canvas.drawCircle(c, r, Paint()..color = C.accentTint);
    final p = Paint()
      ..color = C.accentFill
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    const n = 18;
    for (var i = 0; i < n; i++) {
      final a = 2 * pi * i / n;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, pi / n, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.title, this.wallet, this.onGear, this.trailing, this.overline});
  final String title;
  final String? overline;
  final Wallet? wallet;
  final VoidCallback? onGear;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
        child: Row(children: [
          StampMark(live: wallet != null),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              if (overline != null) Text(overline!, style: T.overline),
              Text(title, style: T.num(26, w: FontWeight.w600)),
            ]),
          ),
          if (wallet != null) WalletChip(wallet: wallet!),
          if (trailing != null) trailing!,
          if (onGear != null) ...[
            const SizedBox(width: 8),
            Material(
              color: C.surfaceAlt,
              shape: const CircleBorder(side: BorderSide(color: C.border)),
              child: IconButton(
                  key: const Key('gear'), onPressed: onGear, icon: const Icon(Icons.settings_outlined, color: C.ink2), tooltip: 'Settings'),
            ),
          ],
        ]),
      );
}

class WalletChip extends StatelessWidget {
  const WalletChip({super.key, required this.wallet});
  final Wallet wallet;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: C.surfaceAlt, borderRadius: BorderRadius.circular(99), border: Border.all(color: C.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: C.up, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(wallet.short, style: T.caption.copyWith(color: C.ink, fontFamily: 'Courier', fontWeight: FontWeight.w700)),
        ]),
      );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onTap, this.icon, this.dark = false});
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final bg = !enabled ? C.border : (dark ? C.ink : C.accent);
    final fg = !enabled ? C.ink3 : (dark ? Colors.white : C.ink);
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: Material(
        color: bg,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          highlightColor: C.accentPressed,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, style: T.label.copyWith(fontSize: 17, fontWeight: FontWeight.w600, color: fg)),
            if (icon != null) ...[const SizedBox(width: 10), Icon(icon, color: fg, size: 22)],
          ]),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onTap, this.leading});
  final String label;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 56,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: const StadiumBorder(),
            side: const BorderSide(color: C.ink, width: 1.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Text(label, style: T.label.copyWith(fontSize: 17, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

/// Pill track with a raised white selected segment.
class Segmented<V> extends StatelessWidget {
  const Segmented({super.key, required this.values, required this.selected, required this.label, required this.onChanged, this.color});
  final List<V> values;
  final V selected;
  final Widget Function(V v, bool on) label;
  final ValueChanged<V> onChanged;
  final Color? Function(V v)? color;

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: C.surfaceAlt, borderRadius: BorderRadius.circular(99), border: Border.all(color: C.border)),
        child: Row(children: [
          for (final v in values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: v == selected ? (color?.call(v) ?? Colors.white) : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: v == selected ? kSoftShadow : null,
                  ),
                  child: label(v, v == selected),
                ),
              ),
            ),
        ]),
      );
}

const kSoftShadow = [
  BoxShadow(color: Color(0x0A141F0C), blurRadius: 2, offset: Offset(0, 1)),
  BoxShadow(color: Color(0x0F141F0C), blurRadius: 24, offset: Offset(0, 8)),
];

class Pill extends StatelessWidget {
  const Pill({super.key, required this.text, required this.selected, required this.onTap, this.trailing});
  final String text;
  final bool selected;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? C.ink : C.surfaceAlt,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: selected ? C.ink : C.border),
          ),
          child: Text.rich(TextSpan(children: [
            TextSpan(text: text, style: T.label.copyWith(fontSize: 15, color: selected ? Colors.white : C.ink)),
            if (trailing != null)
              TextSpan(text: '  $trailing', style: T.caption.copyWith(color: selected ? const Color(0xFFCFE6C0) : C.ink3)),
          ])),
        ),
      );
}

class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.fg = C.up, this.bg = C.upTint, this.icon});
  final String text;
  final Color fg;
  final Color bg;
  final IconData? icon;

  factory Tag.side(Side s, String text) =>
      s == Side.long ? Tag(text, icon: Icons.arrow_upward_rounded) : Tag(text, fg: C.down, bg: C.downTint, icon: Icons.arrow_downward_rounded);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 4)],
          Text(text, style: T.caption.copyWith(color: fg, fontWeight: FontWeight.w700)),
        ]),
      );
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.perforated = false, this.color = C.surface});
  final Widget child;
  final EdgeInsets padding;
  final bool perforated;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
        foregroundPainter: perforated ? _Perforation() : null,
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(20), border: Border.all(color: C.border), boxShadow: kSoftShadow),
          child: child,
        ),
      );
}

/// Postage-stamp scallops along the top edge of ticket cards.
class _Perforation extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = C.bg;
    for (double x = 24; x < s.width - 20; x += 14) {
      canvas.drawCircle(Offset(x, 0), 4, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class InfoNote extends StatelessWidget {
  const InfoNote({super.key, required this.icon, required this.text, this.bg = C.surfaceAlt, this.fg = C.ink2});
  final IconData icon;
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: T.label.copyWith(color: fg, height: 1.4, fontWeight: FontWeight.w400))),
        ]),
      );
}

class KV extends StatelessWidget {
  const KV(this.k, this.v, {super.key, this.vColor = C.ink, this.divider = true});
  final String k;
  final String v;
  final Color vColor;
  final bool divider;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(border: divider ? const Border(bottom: BorderSide(color: C.border)) : null),
        child: Row(children: [
          Expanded(child: Text(k, style: T.body.copyWith(fontSize: 15))),
          Text(v, style: T.num(16, color: vColor, w: FontWeight.w600)),
        ]),
      );
}

/// White bottom sheet frame with grabber, optional close and step dots.
class SheetFrame extends StatelessWidget {
  const SheetFrame({super.key, required this.child, this.step, this.dismissible = true, this.onClose});
  final Widget child;
  final int? step;
  final bool dismissible;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(color: C.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + MediaQuery.of(context).padding.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (dismissible)
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(9)))),
          const SizedBox(height: 10),
          if (step != null || (dismissible && onClose != null))
            Row(children: [
              if (step != null) StepDots(step: step!),
              if (step != null) Text('  Step $step of 3', style: T.caption),
              const Spacer(),
              if (dismissible && onClose != null)
                IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded, color: C.ink2), tooltip: 'Close'),
            ]),
          child,
        ]),
      );
}

class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.step});
  final int step;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 1; i <= 3; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 4),
            width: i == step ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(color: i <= step ? (i == step ? C.accent : C.accentFill) : C.border, borderRadius: BorderRadius.circular(9)),
          ),
      ]);
}

class AppBottomTabs extends StatelessWidget {
  const AppBottomTabs({super.key, required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  static const _tabs = [
    ('Trade', Icons.send_outlined),
    ('Orders', Icons.mail_outline_rounded),
    ('Positions', Icons.layers_outlined),
  ];

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(color: C.surface, border: Border(top: BorderSide(color: C.border))),
        padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + MediaQuery.of(context).padding.bottom),
        child: Row(children: [
          for (var i = 0; i < _tabs.length; i++)
            Expanded(
              child: GestureDetector(
                key: Key('tab-${_tabs[i].$1}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 64,
                    height: 32,
                    decoration: BoxDecoration(color: i == index ? C.accent : Colors.transparent, borderRadius: BorderRadius.circular(99)),
                    child: Icon(_tabs[i].$2, size: 22, color: i == index ? C.ink : C.ink3),
                  ),
                  const SizedBox(height: 4),
                  Text(_tabs[i].$1,
                      style: T.caption.copyWith(color: i == index ? C.ink : C.ink3, fontWeight: i == index ? FontWeight.w700 : FontWeight.w500)),
                ]),
              ),
            ),
        ]),
      );
}

class RoundedPhoto extends StatelessWidget {
  const RoundedPhoto(this.asset, {super.key, this.height = 200, this.tag});
  final String asset;
  final double height;
  final String? tag;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(children: [
          Image.asset(asset, height: height, width: double.infinity, fit: BoxFit.cover),
          if (tag != null)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                child: Text(tag!, style: T.overline.copyWith(color: C.ink)),
              ),
            ),
        ]),
      );
}

/// Circular "DELIVERED" postmark used on completed orders and payouts.
class Postmark extends StatelessWidget {
  const Postmark({super.key, this.ok = true, this.size = 44});
  final bool ok;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: ok ? C.upTint : C.downTint, border: Border.all(color: ok ? C.up : C.down, width: 1.4)),
        child: Icon(ok ? Icons.done_all_rounded : Icons.close_rounded, size: size * .45, color: ok ? C.up : C.down),
      );
}
