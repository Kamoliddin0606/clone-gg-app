import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

/// Localized "time ago" formatter used by balance-related widgets
/// ([BalanceStatusDetailsSheet], [DebtBlockedDialog]).
///
/// Buckets:
///   * `< 1 min`    → "just now" / "только что" / "hozir"
///   * `< 60 min`   → "Nm ago" / "N мин назад" / "N daqiqa oldin"
///   * `< 24 hours` → hours
///   * `>= 1 day`   → days
///
/// Pass [now] in tests to keep the result deterministic.
String formatTimeAgo(
  DateTime fetchedAt,
  AppLocalizations l10n, {
  DateTime? now,
}) {
  final delta = (now ?? DateTime.now()).difference(fetchedAt);
  if (delta.inMinutes < 1) return l10n.timeAgoJustNow;
  if (delta.inMinutes < 60) return l10n.timeAgoMinutes(delta.inMinutes);
  if (delta.inHours < 24) return l10n.timeAgoHours(delta.inHours);
  return l10n.timeAgoDays(delta.inDays);
}
