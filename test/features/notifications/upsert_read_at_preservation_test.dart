import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/db/notification_db_dao.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/models/app_notification.dart';

/// Bug regression — when the user opens a notification:
///   1. NotificationDetailCubit.load() calls fetchAndCache(id)
///   2. The server returns `read_at: null` (mark-read hasn't propagated
///      yet, or the API call failed)
///   3. The old upsert() blindly REPLACED the local row, wiping the
///      optimistic `read_at` we set seconds earlier
///   4. The row reverted to unread on the next list refresh
///
/// The fix: upsert and upsertAll preserve `read_at` when the incoming
/// model has none, and keep the EARLIER timestamp when both have a
/// stamp (immutable read history).

class _InMemoryDbHelper implements DatabaseHelper {
  final Database _db;
  _InMemoryDbHelper(this._db);

  @override
  Future<Database> get database async => _db;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AppNotification _row(
  String id, {
  DateTime? readAt,
  DateTime? snoozeUntil,
  String title = 'T',
}) {
  return AppNotification(
    id: id,
    type: 'system_announcement',
    priority: 'normal',
    title: title,
    body: 'B',
    createdAt: DateTime.utc(2026, 5, 13, 8, 0),
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

  tearDown(() => db.close());

  group('upsert — read_at preservation', () {
    test(
        'local "read" survives a server push that has read_at=null '
        '(the user-reported bug)',
        () async {
      final localReadAt = DateTime.utc(2026, 5, 13, 9, 0);
      await dao.upsert(_row('bug', readAt: localReadAt));
      // Server fetch comes back without a read stamp (mark-read API
      // call failed earlier, or hasn't propagated yet).
      await dao.upsert(_row('bug', title: 'Fresh from server'));

      final got = await dao.getById('bug');
      expect(got!.readAt!.toUtc(), localReadAt,
          reason: 'local read stamp must NOT be erased');
      expect(got.title, 'Fresh from server',
          reason: 'non-state fields still take the server value');
    });

    test('explicit server-side read_at wins when local was unread',
        () async {
      // User marked the row read on the web; mobile syncs and learns
      // about it.
      final serverReadAt = DateTime.utc(2026, 5, 13, 11, 0);
      await dao.upsert(_row('web', readAt: null));
      await dao.upsert(_row('web', readAt: serverReadAt));

      expect((await dao.getById('web'))!.readAt!.toUtc(), serverReadAt);
    });

    test('earlier read_at wins when both have a stamp', () async {
      // Mobile optimistically stamps at 09:00; server later replies
      // with its own 11:00 stamp (e.g. processing delay).
      final mobile = DateTime.utc(2026, 5, 13, 9, 0);
      final server = DateTime.utc(2026, 5, 13, 11, 0);
      await dao.upsert(_row('history', readAt: mobile));
      await dao.upsert(_row('history', readAt: server));

      expect((await dao.getById('history'))!.readAt!.toUtc(), mobile,
          reason: 'first read time is the authoritative one');
    });

    test('null + null stays null (still unread)', () async {
      await dao.upsert(_row('u'));
      await dao.upsert(_row('u', title: 'changed'));
      expect((await dao.getById('u'))!.isUnread, isTrue);
    });
  });

  group('upsertAll — batch read_at preservation', () {
    test('mixed rows: local-read survives null-from-server in a batch',
        () async {
      final localReadAt = DateTime.utc(2026, 5, 13, 9, 0);
      // Seed the cache.
      await dao.upsertAll([
        _row('a', readAt: localReadAt),
        _row('b'),
      ]);
      // syncIncremental returns BOTH rows again — neither carries a
      // read_at because the server hasn't processed the read yet.
      await dao.upsertAll([
        _row('a', title: 'Refreshed A'),
        _row('b', title: 'Refreshed B'),
      ]);

      expect((await dao.getById('a'))!.readAt!.toUtc(), localReadAt);
      expect((await dao.getById('b'))!.readAt, isNull);
      expect((await dao.getById('a'))!.title, 'Refreshed A');
    });

    test('server-side mark wins for previously-unread rows', () async {
      final serverReadAt = DateTime.utc(2026, 5, 13, 11, 0);
      await dao.upsertAll([_row('x')]);
      await dao.upsertAll([_row('x', readAt: serverReadAt)]);
      expect((await dao.getById('x'))!.readAt!.toUtc(), serverReadAt);
    });
  });

  group('upsert — snooze preservation still works (regression guard)',
      () {
    test('explicit local snooze survives a server push that has none',
        () async {
      final snoozeUntil = DateTime.utc(2026, 5, 13, 10, 0);
      await dao.upsert(_row('s', snoozeUntil: snoozeUntil));
      await dao.upsert(_row('s', title: 'Refreshed'));
      expect((await dao.getById('s'))!.snoozeUntil!.toUtc(), snoozeUntil);
    });
  });
}
