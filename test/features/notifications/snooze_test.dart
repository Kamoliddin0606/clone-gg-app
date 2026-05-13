import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/services/local_uuid_service.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/db/notification_db_dao.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/models/app_notification.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/notification_api_service.dart';

/// Phase 2b — snooze + mark-unread invariants.
///
/// Coverage:
///   * Snoozed row hides from getAll / unreadCount until the deadline
///     elapses; reappears automatically afterwards.
///   * markUnread flips read_at back to NULL and re-counts the row.
///   * upsert preserves an existing snooze when the server push lands
///     without one (passport §2b: server has no snooze concept).
///   * Detail-screen reads (getById) bypass the snooze filter — the
///     user explicitly asked for it.

class _InMemoryDbHelper implements DatabaseHelper {
  final Database _db;
  _InMemoryDbHelper(this._db);

  @override
  Future<Database> get database async => _db;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubApi extends Fake implements NotificationApiService {
  @override
  Future<DateTime> markRead(String id) async => DateTime.now().toUtc();
}

class _StubUuid extends Fake implements LocalUuidService {
  @override
  Future<String> getOrCreateLocalUuid() async => 'uuid';
}

AppNotification _row(
  String id, {
  DateTime? readAt,
  DateTime? snoozeUntil,
  DateTime? createdAt,
}) {
  return AppNotification(
    id: id,
    type: 'system_announcement',
    priority: 'normal',
    title: 'T',
    body: 'B',
    createdAt: createdAt ?? DateTime.utc(2026, 5, 13, 8, 0),
    readAt: readAt,
    snoozeUntil: snoozeUntil,
    lastSyncedAt: DateTime.utc(2026, 5, 13, 8, 0),
  );
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late NotificationDbDao dao;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await NotificationDbDao.createTables(db);
    dao = NotificationDbDao(_InMemoryDbHelper(db));
  });

  tearDown(() async {
    await db.close();
  });

  group('AppNotification.isSnoozed', () {
    test('null snoozeUntil → false', () {
      expect(_row('x').isSnoozed(), isFalse);
    });

    test('future snoozeUntil → true', () {
      final n = _row('x',
          snoozeUntil: DateTime.utc(2026, 5, 13, 9, 0));
      expect(n.isSnoozed(DateTime.utc(2026, 5, 13, 8, 0)), isTrue);
    });

    test('past snoozeUntil → false (snooze expired)', () {
      final n = _row('x',
          snoozeUntil: DateTime.utc(2026, 5, 13, 7, 0));
      expect(n.isSnoozed(DateTime.utc(2026, 5, 13, 8, 0)), isFalse);
    });
  });

  group('DAO — snooze filter', () {
    test('getAll hides rows snoozed past now', () async {
      final now = DateTime.utc(2026, 5, 13, 12, 0);
      await dao.upsertAll([
        _row('visible'),
        _row('snoozed',
            snoozeUntil: now.add(const Duration(hours: 1))),
      ]);
      final list = await dao.getAll(now: now);
      expect(list.map((n) => n.id), ['visible']);
    });

    test('getAll re-exposes rows once snooze elapses', () async {
      final snoozeUntil = DateTime.utc(2026, 5, 13, 10, 0);
      await dao.upsert(_row('x', snoozeUntil: snoozeUntil));
      // Before deadline.
      var list = await dao.getAll(now: snoozeUntil.subtract(
        const Duration(minutes: 1),
      ));
      expect(list, isEmpty);
      // After deadline — automatic re-appearance.
      list = await dao.getAll(now: snoozeUntil.add(const Duration(seconds: 1)));
      expect(list, hasLength(1));
    });

    test('unreadCount excludes snoozed unread rows', () async {
      final now = DateTime.utc(2026, 5, 13, 12, 0);
      await dao.upsertAll([
        _row('u1'),
        _row('u2',
            snoozeUntil: now.add(const Duration(hours: 1))),
      ]);
      expect(await dao.unreadCount(now: now), 1);
    });

    test('getById bypasses the snooze filter (detail view)', () async {
      final now = DateTime.utc(2026, 5, 13, 12, 0);
      await dao.upsert(_row('x',
          snoozeUntil: now.add(const Duration(hours: 1))));
      final got = await dao.getById('x');
      expect(got, isNotNull);
      expect(got!.snoozeUntil, isNotNull);
    });
  });

  group('DAO — snooze + unsnooze + markUnread', () {
    test('snooze sets the column', () async {
      await dao.upsert(_row('x'));
      final until = DateTime.utc(2026, 5, 13, 10, 0);
      await dao.snooze('x', until);
      final got = await dao.getById('x');
      expect(got!.snoozeUntil!.toUtc(), until);
    });

    test('unsnooze clears the column', () async {
      await dao.upsert(
          _row('x', snoozeUntil: DateTime.utc(2026, 5, 13, 10, 0)));
      await dao.unsnooze('x');
      expect((await dao.getById('x'))!.snoozeUntil, isNull);
    });

    test('markUnread sets read_at to NULL', () async {
      await dao.upsert(_row('x',
          readAt: DateTime.utc(2026, 5, 13, 9, 0)));
      expect((await dao.getById('x'))!.isUnread, isFalse);
      await dao.markUnread('x');
      expect((await dao.getById('x'))!.isUnread, isTrue);
    });
  });

  group('DAO — upsert preserves snooze on server overwrite', () {
    test('single upsert keeps existing snooze when model has none',
        () async {
      final snoozeUntil = DateTime.utc(2026, 5, 13, 10, 0);
      await dao.upsert(_row('x', snoozeUntil: snoozeUntil));
      // Server push lands without a snoozeUntil — must not clear it.
      await dao.upsert(_row('x'));
      expect(
        (await dao.getById('x'))!.snoozeUntil!.toUtc(),
        snoozeUntil,
      );
    });

    test('explicit snoozeUntil in the model overrides the existing one',
        () async {
      final first = DateTime.utc(2026, 5, 13, 10, 0);
      final second = DateTime.utc(2026, 5, 13, 14, 0);
      await dao.upsert(_row('x', snoozeUntil: first));
      await dao.upsert(_row('x', snoozeUntil: second));
      expect((await dao.getById('x'))!.snoozeUntil!.toUtc(), second);
    });

    test('upsertAll batches preserve snooze for unspecified rows',
        () async {
      final snooze = DateTime.utc(2026, 5, 13, 10, 0);
      await dao.upsertAll([
        _row('a', snoozeUntil: snooze),
        _row('b'),
      ]);
      // Server resync — neither row carries a snooze field.
      await dao.upsertAll([_row('a'), _row('b')]);
      expect((await dao.getById('a'))!.snoozeUntil!.toUtc(), snooze);
      expect((await dao.getById('b'))!.snoozeUntil, isNull);
    });
  });

  group('Repository — snooze + markUnread', () {
    late NotificationRepository repo;

    setUp(() async {
      repo = NotificationRepository(
        api: _StubApi(),
        dao: dao,
        uuidService: _StubUuid(),
      );
      await repo.bootstrap();
    });

    tearDown(() => repo.dispose());

    test('snooze hides row from list/unread; unsnooze restores', () async {
      await dao.upsert(_row('x'));
      await repo.bootstrap();
      // Sanity — visible before snooze.
      // (Bootstrap was called once before upsert via setUp; refresh.)
      await repo.snooze('x', const Duration(hours: 1));
      expect(repo.listValue, isEmpty,
          reason: 'snoozed row hidden in publish');
      expect(repo.unreadCountValue, 0);

      await repo.unsnooze('x');
      expect(repo.listValue, hasLength(1));
      expect(repo.unreadCountValue, 1);
    });

    test('markUnread flips the badge back up', () async {
      await dao.upsert(_row('x', readAt: DateTime.utc(2026, 5, 13, 9, 0)));
      await repo.bootstrap();
      // Force a publish so the seeded state reflects the row.
      await repo.markRead('x'); // re-publish after a known op
      expect(repo.unreadCountValue, 0);

      await repo.markUnread('x');
      expect(repo.unreadCountValue, 1);
    });
  });

  group('Migration helper', () {
    test('addSnoozeColumn is idempotent', () async {
      // Drop the table, recreate with old schema (no snooze_until), then
      // run the migration twice.
      await db.execute('DROP TABLE ${NotificationDbDao.notificationsTable}');
      await db.execute('''
        CREATE TABLE ${NotificationDbDao.notificationsTable} (
          id            TEXT PRIMARY KEY,
          type          TEXT NOT NULL,
          priority      TEXT NOT NULL,
          title         TEXT NOT NULL,
          body          TEXT NOT NULL,
          deep_link     TEXT,
          payload       TEXT,
          created_at    TEXT NOT NULL,
          read_at       TEXT,
          expires_at    TEXT,
          last_synced_at TEXT NOT NULL
        )
      ''');
      await NotificationDbDao.addSnoozeColumn(db);
      // Running it again must not throw.
      await NotificationDbDao.addSnoozeColumn(db);
      // Column exists.
      await dao.upsert(_row('x',
          snoozeUntil: DateTime.utc(2026, 5, 13, 10, 0)));
      expect(
        (await dao.getById('x'))!.snoozeUntil,
        isNotNull,
      );
    });
  });
}
