import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../nav.dart';
import '../services/eip712.dart';
import '../services/permission_policy.dart';
import '../state/providers.dart';
import '../state/trade_flow.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Step 1 of 3: shown only after the user taps Post trade.
class WalletConnectSheet extends ConsumerWidget {
  const WalletConnectSheet({super.key});

  void _pick(WidgetRef ref) {
    ref.read(walletProvider.notifier).state = kWallet;
    Nav.pop();
    Nav.walletProve();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(draftProvider);
    return SheetFrame(
      step: 1,
      onClose: Nav.pop,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Connect a wallet to post', style: T.num(26, w: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text('Your trade is ready. Connect once, sign twice, then trade for 30 days.', style: T.body),
        const SizedBox(height: 14),
        AppCard(
          perforated: true,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: d.side == Side.long ? C.up : C.down, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
                child: Text('${d.side == Side.long ? 'Long' : 'Short'} ${d.market.symbol} · ${d.leverage}x · ${usd(d.bet, digits: 0)}',
                    style: T.label.copyWith(fontSize: 15, fontWeight: FontWeight.w700))),
            const Tag('TICKET', icon: Icons.confirmation_number_outlined, fg: C.accentFill, bg: C.accentTint),
          ]),
        ),
        const SizedBox(height: 16),
        Text('CHOOSE WALLET', style: T.overline),
        const SizedBox(height: 8),
        for (final w in kWalletApps) _WalletRow(app: w, onTap: () => _pick(ref)),
        _WalletRow(
            app: const WalletApp('Other wallets via WalletConnect', 'WC', 0xFF3B6FD8, 'Scan QR code or deep link'),
            icon: Icons.qr_code_2_rounded,
            onTap: () => _pick(ref)),
        const SizedBox(height: 6),
        const InfoNote(icon: Icons.verified_user_outlined, text: 'Dispatch can never deposit, withdraw or move your money.'),
      ]),
    );
  }
}

class _WalletRow extends StatelessWidget {
  const _WalletRow({required this.app, required this.onTap, this.icon});
  final WalletApp app;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: C.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: C.border)),
          child: InkWell(
            key: Key('wallet-${app.initials}'),
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Color(app.color), borderRadius: BorderRadius.circular(12)),
                  child: icon != null
                      ? Icon(icon, color: Colors.white)
                      : Text(app.initials, style: T.label.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(app.name, style: T.label.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(app.subtitle, style: T.caption),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded, color: C.ink3),
              ]),
            ),
          ),
        ),
      );
}

/// Step 2 of 3: a free personal_sign login message proves wallet ownership.
class ProveOwnershipSheet extends ConsumerStatefulWidget {
  const ProveOwnershipSheet({super.key});

  @override
  ConsumerState<ProveOwnershipSheet> createState() => _ProveOwnershipSheetState();
}

class _ProveOwnershipSheetState extends ConsumerState<ProveOwnershipSheet> {
  bool waiting = false;

  Future<void> _sign() async {
    setState(() => waiting = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Nav.pop();
    Nav.grantPermission();
  }

  @override
  Widget build(BuildContext context) {
    final w = ref.watch(walletProvider) ?? kWallet;
    final date = DateFormat('d MMM yyyy').format(ref.watch(clockProvider));
    return SheetFrame(
      step: 2,
      onClose: Nav.pop,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const RoundedPhoto('assets/images/wax-seal.jpg', height: 150, tag: 'IDENTITY SEAL'),
        const SizedBox(height: 16),
        Text('Sign to prove it is you', style: T.num(26, w: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('A free signature. No gas, no transaction.', style: T.body),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xFFB85C0A), borderRadius: BorderRadius.circular(10)),
                child: Text('MM', style: T.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(w.app, style: T.label.copyWith(fontWeight: FontWeight.w700)),
                  Text(w.short, style: T.mono),
                ]),
              ),
              const Tag('Free · no gas'),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: C.surfaceAlt, borderRadius: BorderRadius.circular(12)),
              child: Text('Dispatch login\nnonce 8F2K-41QD\n$date', style: T.mono.copyWith(height: 1.5)),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        PrimaryButton(key: const Key('prove'), label: 'Open MetaMask to sign', icon: Icons.arrow_forward_rounded, onTap: waiting ? null : _sign),
        const SizedBox(height: 10),
        if (waiting)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: C.accentFill)),
            const SizedBox(width: 8),
            Text('Waiting for signature...', style: T.caption),
          ]),
      ]),
    );
  }
}

/// Step 3 of 3: one EIP-712 signature registers the 30-day trade-only key.
class GrantPermissionSheet extends ConsumerWidget {
  const GrantPermissionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider);
    final msg = ref.read(tradeApiProvider).approveAgentMessage(ref.read(walletProvider) ?? kWallet, now);
    final until = now.add(PermissionPolicy.lifetime);
    final digest = toHex(msg.digest);
    return SheetFrame(
      step: 3,
      onClose: Nav.pop,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Allow trading for 30 days', style: T.num(26, w: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('A session key lets Dispatch post your trades without a wallet pop-up each time.', style: T.body),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.accent, width: 3), color: C.accentTint),
              child: const Icon(Icons.key_rounded, color: C.accentFill, size: 28),
            ),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('30 days', style: T.displayL),
              Text('until ${DateFormat('d MMM yyyy · HH:mm').format(until)}', style: T.caption.copyWith(color: C.ink2)),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Expanded(child: _Scope(title: 'Dispatch can', ok: true, items: ['Open positions', 'Close positions', 'Set TP and SL'])),
          const SizedBox(width: 10),
          const Expanded(child: _Scope(title: 'Dispatch can never', ok: false, items: ['Deposit', 'Withdraw', 'Transfer', 'Stake or claim'])),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: C.surfaceAlt, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('EIP-712 · ${msg.type.name}', style: T.overline),
            const SizedBox(height: 6),
            Text('agent    ${_short(msg.message['agent'] as String)}\nbuilder  ${_short(msg.message['builder'] as String)}\nuntil    ${msg.message['validUntil']}\ndigest   ${digest.substring(0, 18)}...',
                style: T.mono.copyWith(fontSize: 12, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 10),
        const InfoNote(icon: Icons.key_off_outlined, text: 'Revoke any time from your wallet. You will not sign each trade.'),
        const SizedBox(height: 14),
        PrimaryButton(
          key: const Key('grant'),
          label: 'Sign permission',
          icon: Icons.draw_outlined,
          onTap: () async {
            final r = WidgetRefAdapter(ref);
            grantPermission(r);
            Nav.pop();
            await submitTrade(r);
          },
        ),
      ]),
    );
  }

  static String _short(String a) => '${a.substring(0, 6)}...${a.substring(a.length - 4)}';
}

class _Scope extends StatelessWidget {
  const _Scope({required this.title, required this.ok, required this.items});
  final String title;
  final bool ok;
  final List<String> items;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: T.caption.copyWith(color: ok ? C.up : C.down, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          for (final i in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Icon(ok ? Icons.check_circle_outline_rounded : Icons.cancel_outlined, size: 17, color: ok ? C.up : C.down),
                const SizedBox(width: 6),
                Expanded(child: Text(i, style: T.label.copyWith(fontSize: 13, fontWeight: FontWeight.w500))),
              ]),
            ),
        ]),
      );
}

/// Blocking re-sign: permission expired, or a new trade's exits would
/// outlive the key that manages them. Cannot be swiped away.
class PermissionBlockedSheet extends ConsumerWidget {
  const PermissionBlockedSheet({super.key, required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perm = ref.watch(permissionProvider);
    final open = ref.watch(positionsProvider).length;
    final expired = reason == 'expired';
    final when = perm == null ? '' : DateFormat('d MMM yyyy').format(perm.expiresAt);
    return SheetFrame(
      dismissible: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const RoundedPhoto('assets/images/return-to-sender.jpg', height: 160),
        const SizedBox(height: 16),
        Text(expired ? 'Your trading permission has ended' : 'This trade would outlive your permission',
            style: T.num(26, w: FontWeight.w600).copyWith(height: 1.15)),
        const SizedBox(height: 8),
        Text(
          expired
              ? 'Your open positions and their take profit and stop loss stay on the exchange. To post, close or edit trades, sign a new 30-day permission.'
              : 'Its take profit and stop loss could still be waiting after your permission ends on $when. Renew now so Dispatch can keep managing them.',
          style: T.body,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: C.surfaceAlt, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.border)),
          child: Row(children: [
            const Icon(Icons.schedule_rounded, color: C.warn),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(expired ? 'Expired $when' : 'Ends $when', style: T.label.copyWith(fontWeight: FontWeight.w700)),
                Text('$open positions open', style: T.caption.copyWith(color: C.ink2)),
              ]),
            ),
            Tag(expired ? 'INACTIVE' : 'ENDING', fg: expired ? C.down : C.warn, bg: expired ? C.downTint : C.warnTint),
          ]),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          key: const Key('resign'),
          label: 'Sign new permission',
          icon: Icons.draw_outlined,
          onTap: () {
            ref.read(clockProvider.notifier).state = ref.read(clockProvider);
            grantPermission(WidgetRefAdapter(ref));
            Nav.pop();
          },
        ),
        const SizedBox(height: 10),
        SecondaryButton(
          label: 'View positions',
          onTap: () {
            Nav.pop();
            ref.read(tabProvider.notifier).state = 2;
          },
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.lock_outline_rounded, size: 16, color: C.accentFill),
          const SizedBox(width: 6),
          Text('Dispatch never holds or moves your funds', style: T.caption.copyWith(color: C.ink2)),
        ]),
      ]),
    );
  }
}
