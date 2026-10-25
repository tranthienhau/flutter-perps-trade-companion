import '../models/models.dart';

enum PermissionState { none, active, expiringSoon, expired }

/// Expiry rules for the 30-day trade-only key:
/// - warn when 5 days or fewer are left
/// - block posting, closing and editing once it has expired
/// - block a new trade whose take profit / stop loss could still be resting
///   on the exchange after the key expires (the exits would outlive the key
///   that is allowed to manage them)
class PermissionPolicy {
  static const lifetime = Duration(days: 30);
  static const warnWindow = Duration(days: 5);

  /// How long a resting exit is assumed to need management (edit / cancel).
  static const exitHorizon = Duration(days: 7);

  static PermissionState stateOf(SessionPermission? p, DateTime now) {
    if (p == null || p.revoked) return PermissionState.none;
    if (!now.isBefore(p.expiresAt)) return PermissionState.expired;
    if (p.expiresAt.difference(now) <= warnWindow) return PermissionState.expiringSoon;
    return PermissionState.active;
  }

  static int daysLeft(SessionPermission p, DateTime now) {
    final d = p.expiresAt.difference(now);
    return d.isNegative ? 0 : (d.inHours / 24).ceil();
  }

  static bool exitsCrossExpiry(SessionPermission p, TradeDraft draft, DateTime now) {
    if (!draft.tpslOn) return false;
    return now.add(exitHorizon).isAfter(p.expiresAt);
  }

  /// Null when the trade can be posted, otherwise the reason to show the
  /// blocking re-sign sheet.
  static String? blockReason(SessionPermission? p, TradeDraft draft, DateTime now) {
    final s = stateOf(p, now);
    if (s == PermissionState.none) return 'connect';
    if (s == PermissionState.expired) return 'expired';
    if (exitsCrossExpiry(p!, draft, now)) return 'exits-cross-expiry';
    return null;
  }
}
