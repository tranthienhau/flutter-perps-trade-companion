import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../models/models.dart';
import '../nav.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class PostedScreen extends ConsumerWidget {
  const PostedScreen({super.key, required this.order});
  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider);
    final mark = ref.watch(pricesProvider)[order.market]!;
    final waiting = order.isWaiting;
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), children: [
          Row(children: [
            const StampMark(size: 34),
            const SizedBox(width: 10),
            Text('DISPATCH', style: T.overline.copyWith(color: C.ink)),
            const Spacer(),
            IconButton(onPressed: Nav.pop, icon: const Icon(Icons.close_rounded, color: C.ink2), tooltip: 'Close'),
          ]),
          const SizedBox(height: 16),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: .7, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, s, child) => Transform.scale(scale: s, child: child),
              child: SizedBox(
                width: 190,
                height: 190,
                child: CustomPaint(
                  painter: _PostmarkRing('POSTED · ${DateFormat('d MMM · HH:mm').format(now).toUpperCase()} · '),
                  child: const Center(child: Icon(Icons.forward_to_inbox_rounded, size: 64, color: C.accentFill)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(waiting ? 'Your order is in the box' : 'Your trade is on its way', textAlign: TextAlign.center, style: T.num(28, w: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(waiting ? 'It waits on the exchange until the price hits.' : 'Sent to the exchange. No wallet pop-up needed.',
              textAlign: TextAlign.center, style: T.body),
          const SizedBox(height: 20),
          AppCard(
            perforated: true,
            child: Column(children: [
              Row(children: [
                Text('RECEIPT', style: T.overline),
                const Spacer(),
                Text('DISPATCH #${order.id}', style: T.mono.copyWith(fontSize: 12)),
              ]),
              const SizedBox(height: 8),
              KV('Position', '${order.side == Side.long ? 'Long' : 'Short'} ${order.market.symbol} · ${order.leverage}x'),
              KV('Bet', usd(order.bet)),
              KV(waiting ? 'Trigger' : 'Filled at', usd(waiting ? order.triggerPrice! : mark)),
              if (order.takeProfit != null) KV('Take profit', usd(order.takeProfit!), vColor: C.up),
              if (order.stopLoss != null) KV('Stop loss', usd(order.stopLoss!), vColor: C.down),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(children: [
                  Expanded(child: Text('Status', style: T.body.copyWith(fontSize: 15))),
                  waiting ? const Tag('Waiting', fg: C.warn, bg: C.warnTint, icon: Icons.schedule_rounded) : const Tag('Open', icon: Icons.circle),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: waiting ? 'View orders' : 'View position',
            icon: Icons.layers_outlined,
            onTap: () {
              ref.read(tabProvider.notifier).state = waiting ? 1 : 2;
              Nav.backToRoot();
            },
          ),
          const SizedBox(height: 10),
          SecondaryButton(label: 'New trade', onTap: () {
            ref.read(tabProvider.notifier).state = 0;
            Nav.backToRoot();
          }),
        ]),
      ),
    );
  }
}

class _PostmarkRing extends CustomPainter {
  _PostmarkRing(this.text);
  final String text;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width / 2;
    canvas.drawCircle(c, r - 2, Paint()..color = C.accentTint);
    canvas.drawCircle(c, r - 2, Paint()
      ..color = C.accentFill
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);
    canvas.drawCircle(c, r - 40, Paint()
      ..color = C.accentFill
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
    final chars = text.split('');
    final step = 2 * pi / chars.length;
    for (var i = 0; i < chars.length; i++) {
      final tp = TextPainter(
          text: TextSpan(text: chars[i], style: T.overline.copyWith(color: C.accentFill, fontSize: 12, letterSpacing: 0)),
          textDirection: TextDirection.ltr)
        ..layout();
      final a = -pi / 2 + i * step;
      canvas.save();
      canvas.translate(c.dx + (r - 21) * cos(a), c.dy + (r - 21) * sin(a));
      canvas.rotate(a + pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PostmarkRing old) => old.text != text;
}
