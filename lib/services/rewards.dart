/// Weekly builder fee share: half of the week's builder fee pool goes to
/// traders, split by a score of volume and margin risked. Shares under the
/// minimum are not paid and do not carry over.
class RewardInput {
  const RewardInput(this.address, this.weekVolume, this.marginRisked);
  final String address;
  final double weekVolume;
  final double marginRisked;

  double get score => weekVolume + 10 * marginRisked;
}

class Payout {
  const Payout(this.address, this.amount, this.sent);
  final String address;
  final double amount;
  final bool sent;
}

class RewardsCalculator {
  static const minimumUsdc = 10.0;
  static const userShare = 0.5;

  static List<Payout> weekly({required double builderFeePool, required List<RewardInput> traders, required bool platformPaid}) {
    if (!platformPaid) return const [];
    final total = traders.fold<double>(0, (s, t) => s + t.score);
    if (total == 0) return const [];
    final pool = builderFeePool * userShare;
    return [
      for (final t in traders)
        () {
          final amount = (pool * t.score / total * 100).floorToDouble() / 100;
          return Payout(t.address, amount, amount >= minimumUsdc);
        }(),
    ];
  }

  static List<RewardInput> ranked(List<RewardInput> t) => [...t]..sort((a, b) => b.score.compareTo(a.score));
}
