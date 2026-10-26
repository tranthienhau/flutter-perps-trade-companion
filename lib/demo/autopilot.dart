import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../nav.dart';
import '../screens/trade_screen.dart';
import '../state/providers.dart';
import '../state/trade_flow.dart';

class DemoStep {
  const DemoStep(this.name, this.action, {this.dwell = const Duration(milliseconds: 1700), this.inVideo = true});
  final String name;
  final void Function(ProviderContainer c) action;
  final Duration dwell;
  final bool inVideo;
}

/// Guided walkthrough shared by the demo recording and the integration
/// screenshot test: sign in, build a trade with no wallet, connect + two
/// signatures on Post, live positions, trigger order with TP/SL, orders,
/// settings, rewards, the 5-day warning and the blocking re-sign.
List<DemoStep> demoSteps() => [
      DemoStep('01-login', (_) {}, dwell: const Duration(milliseconds: 1500)),
      DemoStep('02-trade', (c) {
        c.read(signedInProvider.notifier).state = true;
        Nav.home();
      }),
      DemoStep('03-wallet-connect', (_) => Nav.walletConnect()),
      DemoStep('04-wallet-prove', (c) {
        c.read(walletProvider.notifier).state = kWallet;
        Nav.pop();
        Nav.walletProve();
      }),
      DemoStep('05-grant-permission', (_) {
        Nav.pop();
        Nav.grantPermission();
      }, dwell: const Duration(milliseconds: 2000)),
      DemoStep('06-trade-posted', (c) {
        final r = ContainerRef(c);
        grantPermission(r);
        Nav.pop();
        submitTrade(r);
      }, dwell: const Duration(milliseconds: 1900)),
      DemoStep('07-positions', (c) {
        c.read(pricesProvider.notifier).set({Market.btc: 68002.40});
        c.read(tabProvider.notifier).state = 2;
        Nav.backToRoot();
      }),
      DemoStep('08-close-position', (c) => Nav.closePosition(c.read(positionsProvider)[1])),
      DemoStep('09-trade-trigger-tpsl', (c) {
        Nav.pop();
        c.read(tabProvider.notifier).state = 0;
        c.read(draftProvider.notifier).set(const TradeDraft(
            market: Market.eth,
            side: Side.short,
            mode: EntryMode.trigger,
            bet: 100,
            leverage: 5,
            triggerPrice: 3350,
            tpslOn: true,
            takeProfit: 3150,
            stopLoss: 3420));
        Future<void>.delayed(const Duration(milliseconds: 350), () {
          final sc = TradeScreen.scroll;
          if (sc.hasClients) sc.animateTo(sc.position.maxScrollExtent, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
        });
      }, dwell: const Duration(milliseconds: 2000)),
      DemoStep('10-tpsl-editor', (_) => Nav.tpslEditor(takeProfit: true)),
      DemoStep('11-orders', (c) {
        Nav.pop();
        c.read(tabProvider.notifier).state = 1;
      }),
      DemoStep('12-orders-completed', (c) => c.read(ordersSegmentProvider.notifier).state = 1),
      DemoStep('13-settings', (_) => Nav.settings()),
      DemoStep('14-weekly-rewards', (_) => Nav.rewards()),
      DemoStep('15-trade-expiry-warning', (c) {
        Nav.backToRoot();
        c.read(ordersSegmentProvider.notifier).state = 0;
        c.read(tabProvider.notifier).state = 0;
        final p = c.read(permissionProvider)!;
        c.read(clockProvider.notifier).state = p.expiresAt.subtract(const Duration(days: 5));
        c.read(draftProvider.notifier).set(const TradeDraft(market: Market.sol, bet: 100, leverage: 3));
        for (final ms in [0, 300]) {
          Future<void>.delayed(Duration(milliseconds: ms), () {
            if (TradeScreen.scroll.hasClients) TradeScreen.scroll.jumpTo(0);
          });
        }
      }),
      DemoStep('16-permission-expired', (c) {
        final p = c.read(permissionProvider)!;
        c.read(clockProvider.notifier).state = p.expiresAt.add(const Duration(minutes: 1));
        Nav.permissionBlocked('expired');
      }, dwell: const Duration(milliseconds: 2200)),
      DemoStep('17-orders-empty', (c) {
        Nav.pop();
        c.read(ordersProvider.notifier).clear();
        c.read(tabProvider.notifier).state = 1;
      }, inVideo: false),
      DemoStep('18-positions-empty', (c) {
        c.read(positionsProvider.notifier).clear();
        c.read(tabProvider.notifier).state = 2;
      }, inVideo: false),
    ];

class Autopilot {
  Future<void> run() async {
    final c = ProviderScope.containerOf(navKey.currentContext!);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    for (final s in demoSteps().where((s) => s.inVideo)) {
      s.action(c);
      await Future<void>.delayed(s.dwell);
    }
    // Keep the live price ticking so screen recorders flush the final frames.
    for (var i = 0; i < 12; i++) {
      c.read(pricesProvider.notifier).set({Market.sol: 148.62 + (i.isEven ? 0.01 : 0)});
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    debugPrint('AUTOPILOT_DONE');
  }
}
