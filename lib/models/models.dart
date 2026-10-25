enum Market { btc, eth, sol }

extension MarketX on Market {
  String get symbol => const {Market.btc: 'BTC', Market.eth: 'ETH', Market.sol: 'SOL'}[this]!;
  int get maxLeverage => const {Market.btc: 50, Market.eth: 50, Market.sol: 20}[this]!;
  int get assetIndex => index;
}

enum Side { long, short }

enum EntryMode { now, trigger }

enum OrderStatus { waiting, filled, closedTp, stoppedOut, closedManual, cancelled }

/// What the user builds on the trade screen. Nothing here needs a wallet.
class TradeDraft {
  const TradeDraft({
    this.market = Market.btc,
    this.side = Side.long,
    this.mode = EntryMode.now,
    this.bet = 250,
    this.leverage = 10,
    this.triggerPrice,
    this.tpslOn = false,
    this.takeProfit,
    this.stopLoss,
  });

  final Market market;
  final Side side;
  final EntryMode mode;
  final double bet;
  final int leverage;
  final double? triggerPrice;
  final bool tpslOn;
  final double? takeProfit;
  final double? stopLoss;

  double get notional => bet * leverage;

  TradeDraft copyWith({
    Market? market,
    Side? side,
    EntryMode? mode,
    double? bet,
    int? leverage,
    double? triggerPrice,
    bool? tpslOn,
    double? takeProfit,
    double? stopLoss,
    bool clearExits = false,
  }) =>
      TradeDraft(
        market: market ?? this.market,
        side: side ?? this.side,
        mode: mode ?? this.mode,
        bet: bet ?? this.bet,
        leverage: leverage ?? this.leverage,
        triggerPrice: triggerPrice ?? this.triggerPrice,
        tpslOn: tpslOn ?? this.tpslOn,
        takeProfit: clearExits ? null : takeProfit ?? this.takeProfit,
        stopLoss: clearExits ? null : stopLoss ?? this.stopLoss,
      );
}

class Order {
  const Order({
    required this.id,
    required this.market,
    required this.side,
    required this.leverage,
    required this.bet,
    required this.status,
    required this.createdAt,
    this.triggerPrice,
    this.takeProfit,
    this.stopLoss,
    this.realizedPnl,
  });

  final String id;
  final Market market;
  final Side side;
  final int leverage;
  final double bet;
  final OrderStatus status;
  final DateTime createdAt;
  final double? triggerPrice;
  final double? takeProfit;
  final double? stopLoss;
  final double? realizedPnl;

  bool get isWaiting => status == OrderStatus.waiting;
  Order withStatus(OrderStatus s, {double? pnl}) => Order(
        id: id,
        market: market,
        side: side,
        leverage: leverage,
        bet: bet,
        status: s,
        createdAt: createdAt,
        triggerPrice: triggerPrice,
        takeProfit: takeProfit,
        stopLoss: stopLoss,
        realizedPnl: pnl ?? realizedPnl,
      );
}

class Position {
  const Position({
    required this.id,
    required this.market,
    required this.side,
    required this.leverage,
    required this.bet,
    required this.entry,
    this.takeProfit,
    this.stopLoss,
  });

  final String id;
  final Market market;
  final Side side;
  final int leverage;
  final double bet;
  final double entry;
  final double? takeProfit;
  final double? stopLoss;

  double get size => bet * leverage;

  double pnl(double mark) {
    final move = (mark - entry) / entry;
    return size * (side == Side.long ? move : -move);
  }

  double pnlPct(double mark) => pnl(mark) / bet * 100;

  /// Isolated-margin estimate with a 2% maintenance buffer.
  double get liquidation {
    final f = 1 / leverage - 0.02;
    return side == Side.long ? entry * (1 - f) : entry * (1 + f);
  }
}

class Wallet {
  const Wallet({required this.app, required this.address});
  final String app;
  final String address;
  String get short => '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
}

/// The delegated trade-only key, as the app sees it. The private half never
/// leaves the signer service.
class SessionPermission {
  const SessionPermission({required this.agentAddress, required this.grantedAt, required this.expiresAt, this.revoked = false});
  final String agentAddress;
  final DateTime grantedAt;
  final DateTime expiresAt;
  final bool revoked;
}

class RewardWeek {
  const RewardWeek({required this.week, required this.amount, required this.sent});
  final int week;
  final double amount;
  final bool sent;
}

class WalletApp {
  const WalletApp(this.name, this.initials, this.color, this.subtitle);
  final String name;
  final String initials;
  final int color;
  final String subtitle;
}
