// Pure-function tests for the shared time-ago formatter used by the
// balance details sheet + debt-blocked dialog. Stubs AppLocalizations
// with a minimal fake so we don't depend on real generated l10n files.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/util/format_time_ago.dart';

class _FakeL10n extends AppLocalizations {
  _FakeL10n() : super('en');

  @override
  String get timeAgoJustNow => 'just now';
  @override
  String timeAgoMinutes(int m) => '${m}m';
  @override
  String timeAgoHours(int h) => '${h}h';
  @override
  String timeAgoDays(int d) => '${d}d';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final l10n = _FakeL10n();

  test('< 1 minute → just now', () {
    final now = DateTime(2026, 5, 14, 12, 0, 0);
    final fetched = now.subtract(const Duration(seconds: 30));
    expect(formatTimeAgo(fetched, l10n, now: now), 'just now');
  });

  test('1–59 minutes → minutes', () {
    final now = DateTime(2026, 5, 14, 12, 0, 0);
    expect(
      formatTimeAgo(now.subtract(const Duration(minutes: 5)), l10n, now: now),
      '5m',
    );
    expect(
      formatTimeAgo(now.subtract(const Duration(minutes: 59)), l10n, now: now),
      '59m',
    );
  });

  test('1–23 hours → hours', () {
    final now = DateTime(2026, 5, 14, 12, 0, 0);
    expect(
      formatTimeAgo(now.subtract(const Duration(hours: 3)), l10n, now: now),
      '3h',
    );
    expect(
      formatTimeAgo(now.subtract(const Duration(hours: 23)), l10n, now: now),
      '23h',
    );
  });

  test('>= 24 hours → days', () {
    final now = DateTime(2026, 5, 14, 12, 0, 0);
    expect(
      formatTimeAgo(now.subtract(const Duration(days: 1)), l10n, now: now),
      '1d',
    );
    expect(
      formatTimeAgo(now.subtract(const Duration(days: 7)), l10n, now: now),
      '7d',
    );
  });

  test('60-minute boundary rolls into hours bucket', () {
    final now = DateTime(2026, 5, 14, 12, 0, 0);
    expect(
      formatTimeAgo(now.subtract(const Duration(minutes: 60)), l10n, now: now),
      '1h',
    );
  });
}
