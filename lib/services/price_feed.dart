import 'dart:async';
import 'dart:math';

import '../data/mock_data.dart';
import '../models/models.dart';

/// Stand-in for the public reference price API: a seeded random walk that
/// ticks once a second, so demos are lively but repeatable.
class PriceFeed {
  PriceFeed({int seed = 7}) : _rng = Random(seed);
  final Random _rng;
  final Map<Market, double> _px = Map.of(kStartPrices);

  Map<Market, double> get snapshot => Map.unmodifiable(_px);

  Stream<Map<Market, double>> ticks({Duration every = const Duration(seconds: 1)}) async* {
    yield snapshot;
    yield* Stream.periodic(every, (_) {
      for (final m in Market.values) {
        final drift = (_rng.nextDouble() - 0.5) * 0.0006;
        _px[m] = _px[m]! * (1 + drift);
      }
      return snapshot;
    });
  }
}
