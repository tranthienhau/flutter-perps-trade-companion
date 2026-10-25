import '../models/models.dart';
import '../nav.dart';
import '../services/permission_policy.dart';
import 'providers.dart';

/// Post button: the wallet is only requested here, never at sign-in.
Future<void> postTrade(WidgetRefLike ref) async {
  if (ref.read(walletProvider) == null) {
    await Nav.walletConnect();
    return;
  }
  final reason = PermissionPolicy.blockReason(ref.read(permissionProvider), ref.read(draftProvider), ref.read(clockProvider));
  if (reason == 'connect') {
    await Nav.walletProve();
    return;
  }
  if (reason != null) {
    await Nav.permissionBlocked(reason);
    return;
  }
  await submitTrade(ref);
}

Future<void> submitTrade(WidgetRefLike ref) async {
  final d = ref.read(draftProvider);
  final mark = ref.read(pricesProvider)[d.market]!;
  final order = await ref.read(tradeApiProvider).post(ref.read(walletProvider)!, d, mark);
  ref.read(ordersProvider.notifier).add(order);
  if (order.status == OrderStatus.filled) {
    ref.read(positionsProvider.notifier).add(Position(
          id: 'p${order.id}',
          market: d.market,
          side: d.side,
          leverage: d.leverage,
          bet: d.bet,
          entry: mark,
          takeProfit: order.takeProfit,
          stopLoss: order.stopLoss,
        ));
  }
  Nav.posted(order);
}

Future<void> closePosition(WidgetRefLike ref, Position p) async {
  final reason = PermissionPolicy.stateOf(ref.read(permissionProvider), ref.read(clockProvider));
  if (reason == PermissionState.expired) {
    Nav.pop();
    await Nav.permissionBlocked('expired');
    return;
  }
  final mark = ref.read(pricesProvider)[p.market]!;
  await ref.read(tradeApiProvider).close(ref.read(walletProvider)!, p, mark);
  ref.read(positionsProvider.notifier).remove(p.id);
  Nav.pop();
}
