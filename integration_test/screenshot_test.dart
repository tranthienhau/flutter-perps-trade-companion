import 'package:dispatch_trade/demo/autopilot.dart';
import 'package:dispatch_trade/main.dart';
import 'package:dispatch_trade/nav.dart';
import 'package:dispatch_trade/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Runs the real app on a simulator and walks the same scripted flow as the
/// demo recording, capturing one PNG per screen into screenshots/.
/// Fixed pumps (not pumpAndSettle) so the live price ticker never blocks.
/// `--dart-define=SHOT_PREFIX=android-` keeps per-platform captures apart.
const kPrefix = String.fromEnvironment('SHOT_PREFIX');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture every screen of the trade flow', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DispatchApp()));
    await binding.convertFlutterSurfaceToImage();
    await tester.pump(const Duration(seconds: 2));

    final container = ProviderScope.containerOf(navKey.currentContext!);
    container.read(pricesProvider.notifier).freeze();
    for (final step in demoSteps()) {
      step.action(container);
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await tester.pump(const Duration(milliseconds: 300));
      await binding.takeScreenshot('$kPrefix${step.name}');
    }
  });
}
