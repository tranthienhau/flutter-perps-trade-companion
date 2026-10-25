import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../services/permission_policy.dart';
import '../services/price_feed.dart';
import '../services/trade_api.dart';

final clockProvider = StateProvider<DateTime>((_) => kNow);
final signedInProvider = StateProvider<bool>((_) => false);
final tabProvider = StateProvider<int>((_) => 0);
final ordersSegmentProvider = StateProvider<int>((_) => 0);
final walletProvider = StateProvider<Wallet?>((_) => null);
final permissionProvider = StateProvider<SessionPermission?>((_) => null);
final tradeApiProvider = Provider<TradeApi>((_) => TradeApi());

class PricesNotifier extends StateNotifier<Map<Market, double>> {
  PricesNotifier() : super(kStartPrices) {
    _sub = PriceFeed().ticks().listen((p) {
      if (!_frozen) state = p;
    });
  }
  late final StreamSubscription<Map<Market, double>> _sub;
  bool _frozen = false;

  /// Pins prices to the design values (screenshots, demo recording).
  void freeze() {
    _frozen = true;
    state = kStartPrices;
  }

  /// Scripted move for the demo while frozen.
  void set(Map<Market, double> p) => state = {...state, ...p};

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final pricesProvider = StateNotifierProvider<PricesNotifier, Map<Market, double>>((_) => PricesNotifier());

class DraftNotifier extends StateNotifier<TradeDraft> {
  DraftNotifier() : super(const TradeDraft());
  void set(TradeDraft d) => state = d;
  void market(Market m) => state = state.copyWith(market: m, leverage: state.leverage.clamp(1, m.maxLeverage), clearExits: true);
  void side(Side s) => state = state.copyWith(side: s, clearExits: true);
  void mode(EntryMode m, double mark) =>
      state = state.copyWith(mode: m, triggerPrice: m == EntryMode.trigger ? state.triggerPrice ?? mark : null);
  void bet(double b) => state = state.copyWith(bet: b);
  void leverage(int l) => state = state.copyWith(leverage: l);
  void trigger(double p) => state = state.copyWith(triggerPrice: p);

  void tpsl(bool on, double ref) {
    if (!on) {
      state = state.copyWith(tpslOn: false);
      return;
    }
    final long = state.side == Side.long;
    state = state.copyWith(
      tpslOn: true,
      takeProfit: state.takeProfit ?? ref * (long ? 1.06 : 0.94),
      stopLoss: state.stopLoss ?? ref * (long ? 0.97 : 1.02),
    );
  }

  void takeProfit(double p) => state = state.copyWith(takeProfit: p);
  void stopLoss(double p) => state = state.copyWith(stopLoss: p);
}

final draftProvider = StateNotifierProvider<DraftNotifier, TradeDraft>((_) => DraftNotifier());

class OrdersNotifier extends StateNotifier<List<Order>> {
  OrdersNotifier() : super(seedOrders());
  void add(Order o) => state = [o, ...state];
  void cancel(String id) => state = [for (final o in state) o.id == id ? o.withStatus(OrderStatus.cancelled) : o];
  void clear() => state = const [];
  void reset() => state = seedOrders();
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<Order>>((_) => OrdersNotifier());

class PositionsNotifier extends StateNotifier<List<Position>> {
  PositionsNotifier() : super(kSeedPositions);
  void add(Position p) => state = [p, ...state];
  void remove(String id) => state = state.where((p) => p.id != id).toList();
  void clear() => state = const [];
  void reset() => state = kSeedPositions;
}

final positionsProvider = StateNotifierProvider<PositionsNotifier, List<Position>>((_) => PositionsNotifier());

final permissionStateProvider = Provider<PermissionState>(
    (ref) => PermissionPolicy.stateOf(ref.watch(permissionProvider), ref.watch(clockProvider)));

final openPnlProvider = Provider<double>((ref) {
  final px = ref.watch(pricesProvider);
  return ref.watch(positionsProvider).fold(0.0, (s, p) => s + p.pnl(px[p.market]!));
});

/// Grants the 30-day trade-only key starting at the current clock.
void grantPermission(WidgetRefLike ref) {
  final now = ref.read(clockProvider);
  ref.read(permissionProvider.notifier).state =
      SessionPermission(agentAddress: kAgentAddress, grantedAt: now, expiresAt: now.add(PermissionPolicy.lifetime));
}

/// Shared by widgets (WidgetRef) and the demo (ProviderContainer).
abstract class WidgetRefLike {
  T read<T>(ProviderListenable<T> p);
}

class ContainerRef implements WidgetRefLike {
  ContainerRef(this.c);
  final ProviderContainer c;
  @override
  T read<T>(ProviderListenable<T> p) => c.read(p);
}

class WidgetRefAdapter implements WidgetRefLike {
  WidgetRefAdapter(this.r);
  final WidgetRef r;
  @override
  T read<T>(ProviderListenable<T> p) => r.read(p);
}
