import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/services/local_uuid_service.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/db/notification_db_dao.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/models/app_notification.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/notification_actions.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/notification_api_service.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/services/notification_tap_router.dart';

/// Smoke integration tests — wire the data layer together end-to-end
/// using fake API + in-memory sqflite. Phase 1 prompt §11 asks for
/// three scenarios that a true on-device run would exercise:
///
///   1. Background push lands → row is recorded → list reflects it
///      after the next bootstrap.
///   2. Terminated-state push tap → tap router maps the payload to
///      the correct named route.
///   3. Inline action ("mark read") tapped while the app is
///      terminated → DAO is mutated AND the queue is filled, so the
///      next foreground sync flushes to /bulk-read/.
///
/// These do NOT spin up Firebase / a navigator / a real device; they
/// exercise the same code paths a true integration test would, but
/// without the platform plugins that aren't available in
/// `flutter test`. Real-device verification belongs in the
/// `integration_test/` folder once we run on staging.

class _InMemoryDbHelper implements DatabaseHelper {
  final Database _db;
  _InMemoryDbHelper(this._db);

  @override
  Future<Database> get database async => _db;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubApi extends Fake implements NotificationApiService {
  AppNotification? nextDetail;
  int detailCalls = 0;

  @override
  Future<AppNotification> detail(String id) async {
    detailCalls++;
    return nextDetail ??
        AppNotification(
          id: id,
          type: 'system_announcement',
          priority: 'normal',
          title: 'Fetched from server',
          body: 'Body',
          createdAt: DateTime.utc(2026, 5, 13, 8, 0),
          lastSyncedAt: DateTime.utc(2026, 5, 13, 8, 0),
        );
  }

  @override
  Future<NotificationListPage> list({
    DateTime? since,
    bool? unreadOnly,
    int limit = 50,
    String? cursor,
  }) async {
    return const NotificationListPage(items: [], nextCursor: null);
  }

  @override
  Future<int> bulkMarkRead({
    required List<String> ids,
    required String clientUuid,
    required String idempotencyKey,
  }) async {
    return ids.length;
  }
}

class _StubUuid extends Fake implements LocalUuidService {
  @override
  Future<String> getOrCreateLocalUuid() async => 'uuid';
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late NotificationDbDao dao;
  late _StubApi api;
  late NotificationRepository repo;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await NotificationDbDao.createTables(db);
    dao = NotificationDbDao(_InMemoryDbHelper(db));
    api = _StubApi();
    repo = NotificationRepository(
      api: api,
      dao: dao,
      uuidService: _StubUuid(),
    );
    await repo.bootstrap();
  });

  tearDown(() async {
    await repo.dispose();
    await db.close();
  });

  group('Scenario 1 — background push → row recorded → visible after bootstrap',
      () {
    test('stub row lands in DAO immediately', () async {
      final message = RemoteMessage(data: {
        'notification_id': 'bg-1',
        'type': 'debt_alert',
        'priority': 'high',
        'title': 'Customer X owes',
        'body': 'Past due 30 days',
        'deep_link': 'selup://customers/X/debts',
      });
      await repo.recordBackgroundPush(message);
      // After the next foreground tick, the list contains the row.
      final cached = await dao.getById('bg-1');
      expect(cached, isNotNull);
      expect(cached!.type, 'debt_alert');
      expect(cached.deepLink, 'selup://customers/X/debts');
    });

    test('duplicate background push does not overwrite richer cached row',
        () async {
      final first = AppNotification(
        id: 'dup',
        type: 'debt_alert',
        priority: 'high',
        title: 'Server-fetched detail',
        body: 'Full body from /notifications/dup/',
        createdAt: DateTime.utc(2026, 5, 13, 8, 0),
        lastSyncedAt: DateTime.utc(2026, 5, 13, 8, 0),
      );
      await dao.upsert(first);

      final push = RemoteMessage(data: {
        'notification_id': 'dup',
        'type': 'debt_alert',
        'title': 'Stub from push',
        'body': 'Short',
      });
      await repo.recordBackgroundPush(push);

      final got = await dao.getById('dup');
      // The richer (server-fetched) title survives.
      expect(got!.title, 'Server-fetched detail');
    });

    test('foreground fetchAndCache after a background stub overwrites it',
        () async {
      // Push lands while the app is in the background.
      await repo.recordBackgroundPush(RemoteMessage(data: {
        'notification_id': 'fg',
        'type': 'order_new',
        'title': 'Stub',
        'body': 'Short',
      }));
      expect((await dao.getById('fg'))!.title, 'Stub');

      // User opens the app — the foreground handler hits the API for
      // the full record.
      api.nextDetail = AppNotification(
        id: 'fg',
        type: 'order_new',
        priority: 'high',
        title: 'Full server title',
        body: 'Full body',
        createdAt: DateTime.utc(2026, 5, 13, 8, 0),
        lastSyncedAt: DateTime.utc(2026, 5, 13, 8, 0),
      );
      await repo.fetchAndCache('fg');

      expect((await dao.getById('fg'))!.title, 'Full server title');
      expect(api.detailCalls, 1);
    });
  });

  group('Scenario 2 — terminated tap → deep-link routing', () {
    test('customer debts link maps to trading-points route + args', () {
      final parsed = NotificationTapRouter.parseForTest(
        'selup://customers/00-00053242/debts',
      );
      expect(parsed, isNotNull);
      expect(parsed!.route, AppRouter.tradingPointsRoute);
      final args = parsed.arguments as Map<String, dynamic>;
      expect(args['customer_id'], '00-00053242');
      expect(args['section'], 'debts');
    });

    test('order link maps to orders route with order_id', () {
      final parsed = NotificationTapRouter.parseForTest(
        'selup://orders/9001',
      );
      expect(parsed, isNotNull);
      expect(parsed!.route, AppRouter.ordersRoute);
      expect((parsed.arguments as Map)['order_id'], '9001');
    });

    test('announcement falls back to the notification detail route', () {
      final parsed = NotificationTapRouter.parseForTest(
        'selup://announcements/uuid-1',
      );
      expect(parsed, isNotNull);
      expect(parsed!.route, AppRouter.notificationDetailRoute);
    });
  });

  group(
      'Scenario 3 — terminated-app inline action → DAO mutated + queue ready',
      () {
    test('mark_read action persists locally AND queues for next sync',
        () async {
      // Pretend the row already arrived via a background push.
      await dao.upsert(AppNotification(
        id: 'inline-mr',
        type: 'debt_alert',
        priority: 'high',
        title: 'T',
        body: 'B',
        createdAt: DateTime.utc(2026, 5, 13, 8, 0),
        lastSyncedAt: DateTime.utc(2026, 5, 13, 8, 0),
      ));
      // Simulate the OS waking the background isolate and invoking
      // the dispatcher with the action id + payload.
      final applied = await dispatchNotificationAction(
        actionId: NotificationActionIds.markRead,
        notificationId: 'inline-mr',
        dbOverride: db,
      );
      expect(applied, isTrue);
      expect((await dao.getById('inline-mr'))!.isUnread, isFalse);
      expect(await dao.pendingReadIds(), ['inline-mr']);

      // App resumes — the next sync drains the queue.
      await repo.flushPendingReads();
      expect(await dao.pendingReadIds(), isEmpty);
    });

    test('snooze_1h action hides the row from the badge + list', () async {
      final now = DateTime.utc(2026, 5, 13, 10, 0);
      await dao.upsert(AppNotification(
        id: 'inline-sn',
        type: 'order_new',
        priority: 'high',
        title: 'T',
        body: 'B',
        createdAt: now,
        lastSyncedAt: now,
      ));
      // Pre-condition — the row is counted before the snooze.
      expect(await dao.unreadCount(now: now), 1);

      await dispatchNotificationAction(
        actionId: NotificationActionIds.snooze1h,
        notificationId: 'inline-sn',
        dbOverride: db,
        now: now,
      );

      // Within the snooze window the badge drops to 0 and the list
      // skips the row…
      expect(await dao.unreadCount(now: now.add(const Duration(minutes: 30))),
          0);
      expect(
        (await dao.getAll(now: now.add(const Duration(minutes: 30))))
            .map((n) => n.id),
        isEmpty,
      );
      // …and reappears once the deadline elapses.
      expect(
        await dao.unreadCount(now: now.add(const Duration(hours: 2))),
        1,
      );
    });
  });

  group('Scenario 4 — wire chain: background push + inline action', () {
    test('push lands → mark_read action → row read after sync', () async {
      // 1. Background push records a stub.
      await repo.recordBackgroundPush(RemoteMessage(data: {
        'notification_id': 'chain',
        'type': 'debt_alert',
        'title': 'New debt',
        'body': '5,000 UZS',
      }));
      expect((await dao.getById('chain'))!.isUnread, isTrue);

      // 2. User taps "Mark as read" right on the OS notification —
      //    fires through the dispatcher without opening the app.
      await dispatchNotificationAction(
        actionId: NotificationActionIds.markRead,
        notificationId: 'chain',
        dbOverride: db,
      );
      expect((await dao.getById('chain'))!.isUnread, isFalse);

      // 3. App opens later — flush queue, no exceptions, queue
      //    drained, server told.
      await repo.flushPendingReads();
      expect(await dao.pendingReadIds(), isEmpty);
    });
  });
}
