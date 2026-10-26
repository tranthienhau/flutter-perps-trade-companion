import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../widgets/common.dart';
import 'orders_positions.dart';
import 'trade_screen.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(tabProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: tab, children: const [TradeScreen(), OrdersScreen(), PositionsScreen()]),
      ),
      bottomNavigationBar: AppBottomTabs(index: tab, onTap: (i) => ref.read(tabProvider.notifier).state = i),
    );
  }
}
