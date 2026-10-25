import '../models/models.dart';

/// Fixed demo clock so captures and tests are deterministic.
final kNow = DateTime(2026, 10, 26, 14, 2);

const kUserName = 'Maya Chen';
const kWallet = Wallet(app: 'MetaMask', address: '0x7a3fB2c41e9D05a8c3F1e6b2D9a07c41E5d891c2');
const kAgentAddress = '0x3c91aE5d0B7f24c8e1A96d3F0b52C7e4a81D6f09';
const kBuilderAddress = '0xB1D0e5a7C3f92d84E6a1b0C5d7F3e29a8C4b6D10';

const kStartPrices = {Market.btc: 67412.50, Market.eth: 3284.10, Market.sol: 148.62};
const kDayChange = {Market.btc: 1.24, Market.eth: 1.84, Market.sol: 2.10};

const kWalletApps = [
  WalletApp('MetaMask', 'MM', 0xFFB85C0A, 'Popular Ethereum wallet'),
  WalletApp('Coinbase Wallet', 'CB', 0xFF1652F0, 'Smart wallet and mobile app'),
  WalletApp('Rainbow', 'RB', 0xFFB8502A, 'Optimized for mobile'),
  WalletApp('Trust Wallet', 'TW', 0xFF0072A8, 'Multi-chain self-custody'),
];

List<Order> seedOrders() => [
      Order(
          id: '8821',
          market: Market.eth,
          side: Side.short,
          leverage: 5,
          bet: 100,
          status: OrderStatus.waiting,
          createdAt: kNow.subtract(const Duration(hours: 3)),
          triggerPrice: 3350,
          takeProfit: 3150,
          stopLoss: 3420),
      Order(
          id: '8819',
          market: Market.sol,
          side: Side.long,
          leverage: 3,
          bet: 100,
          status: OrderStatus.waiting,
          createdAt: kNow.subtract(const Duration(hours: 6)),
          triggerPrice: 142,
          takeProfit: 165,
          stopLoss: 134),
      Order(
          id: '8790',
          market: Market.btc,
          side: Side.long,
          leverage: 10,
          bet: 250,
          status: OrderStatus.closedTp,
          createdAt: DateTime(2026, 10, 24, 9, 12),
          realizedPnl: 84.20),
      Order(
          id: '8761',
          market: Market.sol,
          side: Side.short,
          leverage: 4,
          bet: 80,
          status: OrderStatus.stoppedOut,
          createdAt: DateTime(2026, 10, 22, 18, 40),
          realizedPnl: -12.60),
      Order(
          id: '8744',
          market: Market.eth,
          side: Side.long,
          leverage: 2,
          bet: 150,
          status: OrderStatus.closedManual,
          createdAt: DateTime(2026, 10, 21, 11, 5),
          realizedPnl: 6.15),
    ];

const kSeedPositions = [
  Position(id: 'p1', market: Market.btc, side: Side.long, leverage: 10, bet: 250, entry: 67418.20, takeProfit: 72000, stopLoss: 65000),
  Position(id: 'p2', market: Market.sol, side: Side.long, leverage: 3, bet: 100, entry: 139.10, takeProfit: 165, stopLoss: 134),
];

const kRewardHistory = [
  RewardWeek(week: 42, amount: 22.10, sent: true),
  RewardWeek(week: 41, amount: 7.80, sent: false),
  RewardWeek(week: 40, amount: 15.35, sent: true),
];
