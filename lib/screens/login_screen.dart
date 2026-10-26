import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../nav.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Google or Apple only. No email form, password or phone number.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  void _signIn(WidgetRef ref) {
    ref.read(signedInProvider.notifier).state = true;
    Nav.home();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const StampMark(),
                const SizedBox(width: 12),
                Text('Dispatch', style: T.num(24, w: FontWeight.w600)),
                const Spacer(),
                const Tag('v1.0', icon: Icons.circle, fg: C.accentFill, bg: C.accentTint),
              ]),
              const SizedBox(height: 20),
              const RoundedPhoto('assets/images/login-hero-envelope.jpg', height: 240, tag: 'AIRMAIL'),
              const SizedBox(height: 28),
              Text('Trade like sending a letter.', style: T.num(36, w: FontWeight.w700).copyWith(height: 1.12)),
              const SizedBox(height: 12),
              const Text('Open and close BTC, ETH and SOL positions in seconds.', style: T.body),
              const SizedBox(height: 18),
              const Wrap(spacing: 8, children: [
                Tag('Trade only', icon: Icons.bolt_rounded, fg: C.ink2, bg: C.surfaceAlt),
                Tag('No funds held', icon: Icons.lock_outline_rounded, fg: C.ink2, bg: C.surfaceAlt),
              ]),
              const SizedBox(height: 28),
              PrimaryButton(key: const Key('apple'), label: 'Continue with Apple', icon: Icons.apple, dark: true, onTap: () => _signIn(ref)),
              const SizedBox(height: 12),
              SecondaryButton(
                key: const Key('google'),
                label: 'Continue with Google',
                leading: Text('G', style: T.num(20, color: const Color(0xFF1A73E8))),
                onTap: () => _signIn(ref),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text('No email, no password. Dispatch never holds your funds.',
                    textAlign: TextAlign.center, style: T.label.copyWith(color: C.ink2, fontWeight: FontWeight.w400)),
              ),
              const SizedBox(height: 10),
              Center(child: Text('Terms of Service   ·   Privacy Policy', style: T.caption.copyWith(color: C.ink2))),
            ]),
          ),
        ),
      );
}
