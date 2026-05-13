import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/db/notification_db_dao.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/models/app_notification.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/notification_actions.dart';

/// Phase 2 stretch — inline notification action dispatcher.
///
/// The dispatcher runs in two contexts:
///   * Foreground — PushHandlerService calls into it from the local
///     notification tap callback.
///   * Background isolate — `notificationBackgroundActionEntryPoint`
///     is registered with `flutter_local_notifications` so the OS
///     can invoke it while the app is terminated.
///
/// Both paths must produce the same on-disk effect, so we exercise
/// the dispatcher against an in-memory sqflite instance.

AppNotification _row(String id, {DateTime? readAt}) {
  return AppNotification(
    id: id,
    type: 'system_announcement',
    priority: 'normal',
    title: 'T',
    body: 'B',
    createdAt: DateTime.utc(2026, 5, 13, 8, 0),
    readAt: readAt,
    lastSyncedAt: DateTime.utc(2026, 5, 13, 8, 0),
  );
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late NotificationDbDao dao;
  final reference = DateTime.utc(2026, 5, 13, 10, 0);

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await NotificationDbDao.createTables(db);
    dao = NotificationDbDao(db.toDbHelper());
  });

  tearDown(() => db.close());

  group('NotificationActionIds.isKnown', () {
    test('returns true for every advertised id', () {
      for (final id in NotificationActionIds.all) {
        expect(NotificationActionIds.isKnown(id), isTrue,
            reason: 'id $id should be known');
      }
    });

    test('rejects null, empty, and unknown ids', () {
      expect(NotificationActionIds.isKnown(null), isFalse);
      expect(NotificationActionIds.isKnown(''), isFalse);
      expect(NotificationActionIds.isKnown('definitely_not_a_real_id'),
          isFalse);
    });
  });

  group('dispatchNotificationAction — mark_read', () {
    test('updates read_at AND enqueues the pending read mark', () async {
      await dao.upsert(_row('a'));
      final applied = await dispatchNotificationAction(
        actionId: NotificationActionIds.markRead,
        notificationId: 'a',
        dbOverride: db,
        now: reference,
      );
      expect(applied, isTrue);
      expect((await dao.getById('a'))!.readAt!.toUtc(), reference);
      expect(await dao.pendingReadIds(), ['a'],
          reason: 'next sync flushes via /bulk-read/');
    });

    test('already-read row stays read; queue still contains the id',
        () async {
      final initial = DateTime.utc(2026, 5, 13, 9, 0);
      await dao.upsert(_row('a', readAt: initial));
      final applied = await dispatchNotificationAction(
        actionId: NotificationActionIds.markRead,
        notificationId: 'a',
        dbOverride: db,
        now: reference,
      );
      expect(applied, isTrue);
      // DAO.markRead guards against overwriting an existing read
      // stamp, so the original is preserved.
      expect((await dao.getById('a'))!.readAt!.toUtc(), initial);
      // The bulk-read queue still records the intent — the server
      // tolerates a re-mark.
      expect(await dao.pendingReadIds(), ['a']);
    });
  });

  group('dispatchNotificationAction — snooze_1h', () {
    test('writes snooze_until = now + 1h', () async {
      await dao.upsert(_row('s'));
      final applied = await dispatchNotificationAction(
        actionId: NotificationActionIds.snooze1h,
        notificationId: 's',
        dbOverride: db,
        now: reference,
      );
      expect(applied, isTrue);
      expect(
        (await dao.getById('s'))!.snoozeUntil!.toUtc(),
        reference.add(const Duration(hours: 1)),
      );
    });
  });

  group('dispatchNotificationAction — invalid input', () {
    test('returns false on unknown action id', () async {
      final applied = await dispatchNotificationAction(
        actionId: 'never_registered',
        notificationId: 'a',
        dbOverride: db,
      );
      expect(applied, isFalse);
    });

    test('returns false on missing notification id', () async {
      final applied = await dispatchNotificationAction(
        actionId: NotificationActionIds.markRead,
        notificationId: null,
        dbOverride: db,
      );
      expect(applied, isFalse);
    });
  });
}

/// Tiny shim — the dispatcher's `dbOverride` parameter sidesteps
/// `DatabaseHelper().database`, but the DAO we use directly in the
/// test setup still wants a [DatabaseHelper]. Same pattern as the
/// other DAO-heavy tests in this folder.
extension on Database {
  DatabaseHelper toDbHelper() => _InMemoryDbHelper(this);
}

class _InMemoryDbHelper implements DatabaseHelper {
  final Database _db;
  _InMemoryDbHelper(this._db);

  @override
  Future<Database> get database async => _db;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
