import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../nav.dart';
import '../services/permission_policy.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class _Back extends StatelessWidget {
  const _Back(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 20, 8),
        child: Row(children: [
          IconButton(onPressed: Nav.pop, icon: const Icon(Icons.arrow_back_rounded, color: C.ink), tooltip: 'Back'),
          Text(title, style: T.num(26, w: FontWeight.w600)),
        ]),
      );
}

final _notifProvider = StateProvider<Map<String, bool>>((_) => {'filled': true, 'tpsl': true, 'expiring': true});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final perm = ref.watch(permissionProvider);
    final now = ref.watch(clockProvider);
    final pState = ref.watch(permissionStateProvider);
    final days = perm == null ? 0 : PermissionPolicy.daysLeft(perm, now);
    final notif = ref.watch(_notifProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const _Back('Settings'),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  ClipOval(child: Image.asset('assets/images/avatar-maya-chen.jpg', width: 52, height: 52, fit: BoxFit.cover)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(kUserName, style: T.title),
                      Row(children: [
                        const Icon(Icons.apple, size: 16, color: C.ink2),
                        const SizedBox(width: 4),
                        Text('Signed in with Apple', style: T.caption.copyWith(color: C.ink2)),
                      ]),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: const Color(0xFFB85C0A), borderRadius: BorderRadius.circular(12)),
                      child: Text('MM', style: T.label.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(wallet?.app ?? 'No wallet yet', style: T.label.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
                        Text(wallet?.short ?? 'Connects when you post your first trade', style: wallet == null ? T.caption : T.mono),
                      ]),
                    ),
                    if (perm != null)
                      Tag(
                        switch (pState) {
                          PermissionState.expired => 'Expired',
                          PermissionState.expiringSoon => '$days days left',
                          _ => 'Active · $days days left',
                        },
                        fg: pState == PermissionState.active ? C.up : (pState == PermissionState.expired ? C.down : C.warn),
                        bg: pState == PermissionState.active ? C.upTint : (pState == PermissionState.expired ? C.downTint : C.warnTint),
                      ),
                  ]),
                  if (perm != null) ...[
                    const SizedBox(height: 14),
                    Row(children: [
                      Text('Trade-only permission', style: T.caption.copyWith(color: C.ink2)),
                      const Spacer(),
                      Text('$days / 30 days', style: T.caption.copyWith(color: C.ink, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: LinearProgressIndicator(
                          value: days / 30, minHeight: 6, backgroundColor: C.border, valueColor: const AlwaysStoppedAnimation(C.accentFill)),
                    ),
                    const SizedBox(height: 8),
                    Text('Opens, closes and sets exits only. Cannot deposit, withdraw or transfer.', style: T.caption),
                    const SizedBox(height: 12),
                    Row(children: [
                      SizedBox(
                        height: 44,
                        child: FilledButton.icon(
                          onPressed: Nav.grantPermission,
                          style: FilledButton.styleFrom(backgroundColor: C.accent, foregroundColor: C.ink, shape: const StadiumBorder()),
                          icon: const Icon(Icons.autorenew_rounded, size: 18),
                          label: Text('Renew permission', style: T.label.copyWith(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          ref.read(permissionProvider.notifier).state = null;
                          ref.read(walletProvider.notifier).state = null;
                        },
                        child: Text('Disconnect', style: T.label.copyWith(color: C.down)),
                      ),
                    ]),
                  ],
                ]),
              ),
              const SizedBox(height: 12),
              _Group(children: [
                _Row(
                  icon: Icons.redeem_outlined,
                  label: 'Weekly rewards',
                  value: r'$18.40 this week',
                  valueColor: C.up,
                  onTap: Nav.rewards,
                ),
                const _Row(icon: Icons.tune_rounded, label: 'Default leverage', value: '10x'),
              ]),
              const SizedBox(height: 16),
              Text('NOTIFICATIONS', style: T.overline),
              const SizedBox(height: 8),
              _Group(children: [
                for (final e in const [
                  ('filled', 'Order filled', 'When a waiting order executes'),
                  ('tpsl', 'Take profit / stop loss hit', 'Exit alerts on open positions'),
                  ('expiring', 'Permission expiring', '5 days before your key ends'),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.$2, style: T.label.copyWith(fontSize: 15)),
                          Text(e.$3, style: T.caption),
                        ]),
                      ),
                      Switch(
                          value: notif[e.$1]!,
                          onChanged: (v) => ref.read(_notifProvider.notifier).state = {...notif, e.$1: v}),
                    ]),
                  ),
              ]),
              const SizedBox(height: 16),
              Text('SUPPORT', style: T.overline),
              const SizedBox(height: 8),
              const _Group(children: [
                _Row(icon: Icons.key_outlined, label: 'How permission works'),
                _Row(icon: Icons.help_outline_rounded, label: 'Help and support'),
                _Row(icon: Icons.description_outlined, label: 'Terms'),
                _Row(icon: Icons.privacy_tip_outlined, label: 'Privacy'),
              ]),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text('Sign out', style: T.label.copyWith(color: C.down, fontSize: 15)),
                ),
              ),
              Center(child: Text('Version 1.0.0 (42)', style: T.caption)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: C.border)),
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const Divider(height: 1, color: C.border, indent: 16, endIndent: 16),
          ],
        ]),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, this.value, this.valueColor = C.ink2, this.onTap});
  final IconData icon;
  final String label;
  final String? value;
  final Color valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap ?? () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Icon(icon, size: 22, color: C.ink2),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: T.label.copyWith(fontSize: 15))),
            if (value != null) Text(value!, style: T.label.copyWith(color: valueColor, fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: C.ink3),
          ]),
        ),
      );
}

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider) ?? kWallet;
    const est = 18.40;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const _Back('Weekly rewards'),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('ESTIMATED THIS WEEK', style: T.overline),
                  const SizedBox(height: 6),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(usd(est), style: T.num(48)),
                    const SizedBox(width: 8),
                    Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('USDC', style: T.label.copyWith(color: C.accentFill))),
                  ]),
                  const SizedBox(height: 6),
                  Text('Sent to ${wallet.short} every Monday. No claim needed.', style: T.caption.copyWith(color: C.ink2)),
                  const SizedBox(height: 16),
                  Row(children: [
                    Text(r'$10 minimum', style: T.caption.copyWith(color: C.ink2)),
                    const Spacer(),
                    const Tag(r'$10.00 met', icon: Icons.check_circle_outline_rounded),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: const LinearProgressIndicator(value: 1, minHeight: 6, backgroundColor: C.border, valueColor: AlwaysStoppedAnimation(C.accentFill)),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: const [
                  _Stat('This week volume', r'$48,250', '+12% vs last week'),
                  _Stat('All-time volume', r'$312,900', 'Never resets'),
                  _Stat('Margin risked', r'$1,840', 'This week'),
                  _Stat('Your rank', '#214', 'of 3,920 traders'),
                ],
              ),
              const SizedBox(height: 16),
              Text('PAYOUT HISTORY', style: T.overline),
              const SizedBox(height: 8),
              _Group(children: [
                for (final w in kRewardHistory)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: [
                      Postmark(ok: w.sent, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Week ${w.week}', style: T.label.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
                          Text(w.sent ? 'Delivered to your wallet' : r'Below $10 minimum, not sent', style: T.caption.copyWith(color: w.sent ? C.ink2 : C.warn)),
                        ]),
                      ),
                      Text('${usd(w.amount)} USDC', style: T.num(15, color: w.sent ? C.ink : C.ink3, w: FontWeight.w600)),
                    ]),
                  ),
              ]),
              const SizedBox(height: 14),
              const InfoNote(
                icon: Icons.redeem_outlined,
                text: 'Half of the builder fee is shared with traders by volume and margin risked, paid after the platform payout arrives.',
                bg: C.accentTint,
                fg: C.accentFill,
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.k, this.v, this.sub);
  final String k;
  final String v;
  final String sub;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(k, style: T.caption.copyWith(color: C.ink2)),
          Text(v, style: T.num(24)),
          Text(sub, style: T.caption),
        ]),
      );
}
