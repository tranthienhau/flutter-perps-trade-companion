import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'demo/autopilot.dart';
import 'nav.dart';
import 'screens/login_screen.dart';
import 'state/providers.dart';
import 'theme/app_theme.dart';

/// `--dart-define=DEMO=true` walks the app hands-free (used for demo recordings).
const kDemo = bool.fromEnvironment('DEMO');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  runApp(const ProviderScope(child: DispatchApp()));
}

class DispatchApp extends ConsumerStatefulWidget {
  const DispatchApp({super.key});

  @override
  ConsumerState<DispatchApp> createState() => _DispatchAppState();
}

class _DispatchAppState extends ConsumerState<DispatchApp> {
  @override
  void initState() {
    super.initState();
    if (kDemo) {
      ref.read(pricesProvider.notifier).freeze();
      WidgetsBinding.instance.addPostFrameCallback((_) => Autopilot().run());
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Dispatch',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        navigatorKey: navKey,
        home: const LoginScreen(),
      );
}
