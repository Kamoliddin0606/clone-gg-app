import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/db/notification_db_dao.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/notification_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/push_handler_service.dart';

/// Phase 2 §1 — push handler must respect the per-type / DND filter.
/// Full handler init binds to FirebaseMessaging plugin channels (not
/// available in unit tests), so we exercise the public
/// `shouldShowForeground` predicate directly. The other Phase 1 push
/// flows (fetchAndCache, deep-link tap) are covered in the existing
/// repository and tap-router tests.

void main() {
  late SharedPreferencesService prefs;
  late NotificationPreferencesService prefsService;
  late PushHandlerService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferencesService.getInstance();
    await prefs.preferences.clear();
    prefsService = NotificationPreferencesService(prefs: prefs);
    await prefsService.bootstrap();
    service = PushHandlerService(
      // Filter logic never calls into the repo or DAO — pass throwing
      // stubs so any accidental use surfaces as a test failure.
      repo: _UnusedRepo(),
      dao: _UnusedDao(),
      preferences: prefsService,
      // Bypass the real Firebase / system tray plugins — both crash in
      // unit tests because their platform channels are absent.
      messaging: _FakeMessaging(),
      localNotifications: _FakeLocalNotifications(),
    );
  });

  test('default prefs allow every type', () {
    expect(service.shouldShowForeground(type: 'debt_alert'), isTrue);
    expect(service.shouldShowForeground(type: 'order_new'), isTrue);
    expect(service.shouldShowForeground(type: null), isTrue);
  });

  test('type-off suppresses only that type', () async {
    await prefsService.update(
      prefsService.value.withTypeEnabled('debt_alert', false),
    );
    expect(service.shouldShowForeground(type: 'debt_alert'), isFalse);
    expect(service.shouldShowForeground(type: 'order_new'), isTrue);
    expect(service.shouldShowForeground(type: null), isTrue,
        reason: 'missing type → never gated on type');
  });

  test('DND window suppresses everything', () async {
    await prefsService.update(
      prefsService.value.copyWith(
        dndStart: const TimeOfDay(hour: 22, minute: 0),
        dndEnd: const TimeOfDay(hour: 6, minute: 0),
      ),
    );
    final inside = DateTime(2026, 5, 13, 23, 30);
    final outside = DateTime(2026, 5, 13, 12, 0);

    expect(service.shouldShowForeground(type: 'debt_alert', now: inside),
        isFalse);
    expect(service.shouldShowForeground(type: null, now: inside), isFalse);
    expect(service.shouldShowForeground(type: 'debt_alert', now: outside),
        isTrue);
  });

  test('type-off + DND outside window → still suppressed by type', () async {
    await prefsService.update(
      prefsService.value
          .withTypeEnabled('order_new', false)
          .copyWith(
            dndStart: const TimeOfDay(hour: 22, minute: 0),
            dndEnd: const TimeOfDay(hour: 6, minute: 0),
          ),
    );
    final daytime = DateTime(2026, 5, 13, 12, 0);
    expect(service.shouldShowForeground(type: 'order_new', now: daytime),
        isFalse);
    expect(service.shouldShowForeground(type: 'debt_alert', now: daytime),
        isTrue);
  });
}

/// Failure surface — if the filter ever calls into the repo, the test
/// errors out instead of silently passing. `Fake implements` satisfies
/// the static type without forcing us to implement every method.
class _UnusedRepo extends Fake implements NotificationRepository {
  @override
  noSuchMethod(Invocation invocation) {
    fail('PushHandlerService filter must not touch the repo — '
        'attempted: ${invocation.memberName}');
  }
}

/// Same idea for the DAO — the foreground filter path (these tests)
/// never queries the database; the grouping summary path does, but
/// that's covered by separate tests under notification_grouping_test.
class _UnusedDao extends Fake implements NotificationDbDao {
  @override
  noSuchMethod(Invocation invocation) {
    fail('PushHandlerService filter must not touch the DAO — '
        'attempted: ${invocation.memberName}');
  }
}

/// Fake FirebaseMessaging — the constructor needs SOMETHING but the
/// filter-only tests never call into it. The lazy-init in the service
/// (`messaging ?? FirebaseMessaging.instance`) makes this just enough.
class _FakeMessaging extends Fake implements FirebaseMessaging {
  @override
  Stream<String> get onTokenRefresh => const Stream.empty();
}

/// Same idea for `flutter_local_notifications` — we don't trigger the
/// system tray code path in these tests; just satisfy the type.
class _FakeLocalNotifications extends Fake
    implements FlutterLocalNotificationsPlugin {}
