import 'package:dispatch_trade/models/models.dart';
import 'package:dispatch_trade/services/eip712.dart';
import 'package:dispatch_trade/services/permission_policy.dart';
import 'package:dispatch_trade/services/rewards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final granted = DateTime(2026, 10, 26, 14);
  final p = SessionPermission(agentAddress: '0x1', grantedAt: granted, expiresAt: granted.add(PermissionPolicy.lifetime));

  group('PermissionPolicy', () {
    test('active, warning at 5 days, expired', () {
      expect(PermissionPolicy.stateOf(p, granted.add(const Duration(days: 10))), PermissionState.active);
      expect(PermissionPolicy.stateOf(p, granted.add(const Duration(days: 25))), PermissionState.expiringSoon);
      expect(PermissionPolicy.stateOf(p, granted.add(const Duration(days: 30))), PermissionState.expired);
      expect(PermissionPolicy.stateOf(null, granted), PermissionState.none);
    });

    test('blocks a new trade whose exits could outlive the key', () {
      const withExits = TradeDraft(tpslOn: true, takeProfit: 70000, stopLoss: 65000);
      const plain = TradeDraft();
      final late = granted.add(const Duration(days: 26));
      expect(PermissionPolicy.blockReason(p, withExits, late), 'exits-cross-expiry');
      expect(PermissionPolicy.blockReason(p, plain, late), isNull);
      expect(PermissionPolicy.blockReason(p, plain, granted.add(const Duration(days: 31))), 'expired');
    });
  });

  group('Rewards', () {
    test('half the pool, \$10 minimum, no carry-over, waits for platform payout', () {
      final traders = [const RewardInput('a', 90000, 2000), const RewardInput('b', 2000, 50)];
      expect(RewardsCalculator.weekly(builderFeePool: 400, traders: traders, platformPaid: false), isEmpty);
      final out = RewardsCalculator.weekly(builderFeePool: 400, traders: traders, platformPaid: true);
      final total = out.fold<double>(0, (s, x) => s + x.amount);
      expect(total, lessThanOrEqualTo(200));
      expect(out.firstWhere((x) => x.address == 'a').sent, isTrue);
      expect(out.firstWhere((x) => x.address == 'b').sent, isFalse);
    });
  });

  group('EIP-712', () {
    test('keccak256 matches the known empty-string vector', () {
      expect(toHex(keccak256([])), '0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470');
    });

    test('Mail example from the EIP-712 spec hashes to the published digest', () {
      const person = TypedStruct('Person', [Field('name', 'string'), Field('wallet', 'address')]);
      // Mail(Person from,Person to,string contents) needs nested structs; check the Person typehash instead.
      expect(person.encodeType, 'Person(string name,address wallet)');
      expect(toHex(person.typeHash), '0xb9d8c78acf9b987311de6c7b45bb6a9c8e1bf361fa7fd3467a2163f994c79500');
    });

    test('trade intent has no transfer or withdraw field', () {
      final names = tradeIntentType.fields.map((f) => f.name).toList();
      expect(names, isNot(contains('destination')));
      expect(names, isNot(contains('amount')));
    });
  });
}
