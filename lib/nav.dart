import 'package:flutter/material.dart';

import 'models/models.dart';
import 'screens/home_shell.dart';
import 'screens/orders_positions.dart';
import 'screens/posted_screen.dart';
import 'screens/settings_rewards.dart';
import 'screens/tpsl_editor.dart';
import 'screens/wallet_sheets.dart';
import 'theme/app_theme.dart';

/// Single navigator so taps and the demo autopilot share one route stack.
final navKey = GlobalKey<NavigatorState>();

NavigatorState get _nav => navKey.currentState!;
BuildContext get _ctx => navKey.currentContext!;

Future<R?> _push<R>(Widget w) => _nav.push<R>(PageRouteBuilder<R>(
      pageBuilder: (_, __, ___) => w,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, a, __, child) {
        final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: c,
          child: SlideTransition(position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(c), child: child),
        );
      },
    ));

Future<R?> _sheet<R>(Widget w, {bool dismissible = true}) => showModalBottomSheet<R>(
      context: _ctx,
      isScrollControlled: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      backgroundColor: Colors.transparent,
      barrierColor: C.scrim,
      builder: (_) => PopScope(canPop: dismissible, child: w),
    );

class Nav {
  static void home() => _nav.pushAndRemoveUntil(
      PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) => const HomeShell(),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 350)),
      (_) => false);

  // wallet flow, bottom sheets on top of the trade screen
  static Future<void> walletConnect() => _sheet(const WalletConnectSheet());
  static Future<void> walletProve() => _sheet(const ProveOwnershipSheet());
  static Future<void> grantPermission() => _sheet(const GrantPermissionSheet());
  static Future<void> permissionBlocked(String reason) => _sheet(PermissionBlockedSheet(reason: reason), dismissible: false);

  static Future<void> tpslEditor({required bool takeProfit}) => _sheet(TpSlEditorSheet(takeProfit: takeProfit));
  static void posted(Order o) => _push(PostedScreen(order: o));
  static Future<void> closePosition(Position p) => _sheet(ClosePositionSheet(position: p));

  static void settings() => _push(const SettingsScreen());
  static void rewards() => _push(const RewardsScreen());

  static void backToRoot() => _nav.popUntil((r) => r.isFirst);
  static void pop() {
    if (_nav.canPop()) _nav.pop();
  }
}
