import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/db/notification_db_dao.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/models/app_notification.dart';

/// In-memory sqflite DAO tests. The production [DatabaseHelper] copies
/// a zipped asset DB at first launch which we cannot exercise in unit
/// tests — but the DAO only depends on `_dbHelper.database`, so a thin
/// stub returning an FFI-backed in-memory DB is enough.
class _InMemoryDbHelper implements DatabaseHelper {
  final Database _db;
  _InMemoryDbHelper(this._db);

  @override
  Future<Database> get database async => _db;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late NotificationDbDao dao;

  AppNotification sample({
    required String id,
    String type = 'system_announcement',
    String priority = 'normal',
    String title = 'T',
    String body = 'B',
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? expiresAt,
  }) {
    return AppNotification(
      id: id,
      type: type,
      priority: priority,
      title: title,
      body: body,
      createdAt: createdAt ?? DateTime.utc(2026, 5, 13, 8, 0),
      readAt: readAt,
      expiresAt: expiresAt,
      lastSyncedAt: DateTime.utc(2026, 5, 13, 8, 0),
    );
  }

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await NotificationDbDao.createTables(db);
    dao = NotificationDbDao(_InMemoryDbHelper(db));
  });

  tearDown(() async {
    await db.close();
  });

  group('upsert + reads', () {
    test('round-trip a single row', () async {
      await dao.upsert(sample(id: 'a'));
      final got = await dao.getById('a');
      expect(got, isNotNull);
      expect(got!.id, 'a');
    });

    test('upsert replaces existing row', () async {
      await dao.upsert(sample(id: 'dup', title: 'first'));
      await dao.upsert(sample(id: 'dup', title: 'second'));
      final all = await dao.getAll();
      expect(all, hasLength(1));
      expect(all.single.title, 'second');
    });

    test('getAll orders by created_at DESC', () async {
      await dao.upsertAll([
        sample(id: 'old', createdAt: DateTime.utc(2026, 5, 10)),
        sample(id: 'new', createdAt: DateTime.utc(2026, 5, 13)),
        sample(id: 'mid', createdAt: DateTime.utc(2026, 5, 12)),
      ]);
      final all = await dao.getAll();
      expect(all.map((n) => n.id).toList(), ['new', 'mid', 'old']);
    });
  });

  group('unreadCount', () {
    test('counts only rows with read_at NULL', () async {
      await dao.upsertAll([
        sample(id: '1'),
        sample(id: '2'),
        sample(
          id: '3-read',
          readAt: DateTime.utc(2026, 5, 13, 9, 0),
        ),
      ]);
      expect(await dao.unreadCount(), 2);
    });

    test('markRead drops the count', () async {
      await dao.upsert(sample(id: '1'));
      expect(await dao.unreadCount(), 1);
      await dao.markRead('1', DateTime.utc(2026, 5, 13, 9, 0));
      expect(await dao.unreadCount(), 0);
    });

    test('markRead is a no-op for an already-read row', () async {
      final firstRead = DateTime.utc(2026, 5, 13, 9, 0);
      await dao.upsert(sample(id: '1', readAt: firstRead));
      await dao.markRead('1', DateTime.utc(2026, 5, 13, 10, 0));
      final got = await dao.getById('1');
      // The DAO guards against overwriting an existing read_at.
      expect(got!.readAt!.toUtc(), firstRead);
    });
  });

  group('markAllRead', () {
    test('marks every unread row', () async {
      await dao.upsertAll([
        sample(id: '1'),
        sample(id: '2'),
        sample(id: '3', readAt: DateTime.utc(2026, 5, 13, 9, 0)),
      ]);
      await dao.markAllRead(DateTime.utc(2026, 5, 13, 9, 30));
      expect(await dao.unreadCount(), 0);
    });
  });

  group('pending_read_marks', () {
    test('enqueue + drain', () async {
      await dao.enqueueReadMark('a', DateTime.utc(2026, 5, 13));
      await dao.enqueueReadMark('b', DateTime.utc(2026, 5, 13));
      expect(await dao.pendingReadIds(), unorderedEquals(['a', 'b']));
      await dao.dequeueReadMarks(['a']);
      expect(await dao.pendingReadIds(), ['b']);
    });

    test('enqueue twice for the same id is a no-op (PRIMARY KEY)', () async {
      await dao.enqueueReadMark('a', DateTime.utc(2026, 5, 13));
      await dao.enqueueReadMark('a', DateTime.utc(2026, 5, 14));
      expect(await dao.pendingReadIds(), ['a']);
    });
  });

  group('evictOld', () {
    test('keeps unread rows even if old', () async {
      final old = DateTime.utc(2025, 1, 1);
      await dao.upsertAll([
        sample(id: 'unread-old', createdAt: old),
        sample(id: 'read-old', createdAt: old, readAt: old),
      ]);
      await dao.evictOld(keepLast: 0, keepWindow: const Duration(days: 1));
      final ids = (await dao.getAll()).map((n) => n.id).toList();
      expect(ids, contains('unread-old'));
      expect(ids, isNot(contains('read-old')));
    });

    test('keeps newest N regardless of age', () async {
      final old = DateTime.utc(2025, 1, 1);
      await dao.upsertAll(List.generate(
        5,
        (i) => sample(
          id: 'r$i',
          createdAt: old.add(Duration(days: i)),
          readAt: old.add(Duration(days: i, hours: 1)),
        ),
      ));
      await dao.evictOld(keepLast: 2, keepWindow: const Duration(days: 1));
      final ids = (await dao.getAll()).map((n) => n.id).toList();
      // Newest 2 should still be there even though all are old+read.
      expect(ids, containsAll(['r4', 'r3']));
      expect(ids.length, 2);
    });
  });

  group('clearAll', () {
    test('wipes both tables', () async {
      await dao.upsert(sample(id: '1'));
      await dao.enqueueReadMark('x', DateTime.utc(2026, 5, 13));
      await dao.clearAll();
      expect(await dao.getAll(), isEmpty);
      expect(await dao.pendingReadIds(), isEmpty);
    });
  });

  group('lastSyncedAt', () {
    test('returns the MAX(last_synced_at) across rows', () async {
      await dao.upsert(AppNotification(
        id: '1',
        type: 'system_announcement',
        priority: 'normal',
        title: '',
        body: '',
        createdAt: DateTime.utc(2026, 5, 13),
        lastSyncedAt: DateTime.utc(2026, 5, 13, 7, 0),
      ));
      await dao.upsert(AppNotification(
        id: '2',
        type: 'system_announcement',
        priority: 'normal',
        title: '',
        body: '',
        createdAt: DateTime.utc(2026, 5, 13),
        lastSyncedAt: DateTime.utc(2026, 5, 13, 9, 0),
      ));
      expect(
        (await dao.lastSyncedAt())!.toUtc(),
        DateTime.utc(2026, 5, 13, 9, 0),
      );
    });

    test('returns null on an empty cache', () async {
      expect(await dao.lastSyncedAt(), isNull);
    });
  });
}
