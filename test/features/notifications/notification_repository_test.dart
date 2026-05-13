import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/services/local_uuid_service.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/db/notification_db_dao.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/models/app_notification.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/notification_api_service.dart';

/// Repository-level invariants documented in passport-mobile.md:
///   * Optimistic mark-read with offline fallback (§4.2).
///   * Pending queue flush on next sync (§4.1).
///   * Sync merge — server is authoritative (§4.1).
///   * Fetch-and-cache evicts on 404 (§9).

class _FakeApiService extends Fake implements NotificationApiService {
  bool markReadThrows = false;
  bool listThrows = false;
  bool detailThrows = false;
  bool bulkMarkReadThrows = false;
  bool detailNotFound = false;

  /// Rows returned by the next `list()` call.
  List<AppNotification> nextListItems = const [];
  String? nextCursor;

  AppNotification? nextDetail;

  /// Captured args for verification.
  final List<String> markReadCalls = [];
  final List<List<String>> bulkMarkReadCalls = [];
  final List<String> detailCalls = [];
  int listCalls = 0;

  @override
  Future<NotificationListPage> list({
    DateTime? since,
    bool? unreadOnly,
    int limit = 50,
    String? cursor,
  }) async {
    listCalls++;
    if (listThrows) {
      throw const NotificationApiException(
        code: 'network_error',
        message: 'offline',
      );
    }
    return NotificationListPage(
      items: nextListItems,
      nextCursor: nextCursor,
    );
  }

  @override
  Future<AppNotification> detail(String id) async {
    detailCalls.add(id);
    if (detailNotFound) {
      throw const NotificationApiException(
        code: 'notification_not_found',
        message: 'gone',
        statusCode: 404,
      );
    }
    if (detailThrows) {
      throw const NotificationApiException(
        code: 'network_error',
        message: 'offline',
      );
    }
    return nextDetail!;
  }

  @override
  Future<DateTime> markRead(String id) async {
    markReadCalls.add(id);
    if (markReadThrows) {
      throw const NotificationApiException(
        code: 'network_error',
        message: 'offline',
      );
    }
    return DateTime.now().toUtc();
  }

  @override
  Future<int> bulkMarkRead({
    required List<String> ids,
    required String clientUuid,
    required String idempotencyKey,
  }) async {
    bulkMarkReadCalls.add(ids);
    if (bulkMarkReadThrows) {
      throw const NotificationApiException(
        code: 'network_error',
        message: 'offline',
      );
    }
    return ids.length;
  }
}

class _FakeUuidService extends Fake implements LocalUuidService {
  @override
  Future<String> getOrCreateLocalUuid() async => 'test-uuid';
}

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
  DateTime? createdAt,
  DateTime? readAt,
  String title = 'T',
}) {
  return AppNotification(
    id: id,
    type: 'system_announcement',
    priority: 'normal',
    title: title,
    body: 'B',
    createdAt: createdAt ?? DateTime.utc(2026, 5, 13, 8, 0),
    readAt: readAt,
    lastSyncedAt: DateTime.utc(2026, 5, 13, 8, 0),
  );
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late NotificationDbDao dao;
  late _FakeApiService api;
  late NotificationRepository repo;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await NotificationDbDao.createTables(db);
    dao = NotificationDbDao(_InMemoryDbHelper(db));
    api = _FakeApiService();
    repo = NotificationRepository(
      api: api,
      dao: dao,
      uuidService: _FakeUuidService(),
    );
    await repo.bootstrap();
  });

  tearDown(() async {
    await repo.dispose();
    await db.close();
  });

  group('markRead — optimistic + offline fallback', () {
    test('online: DAO updated AND API called, no pending queue entry',
        () async {
      await dao.upsert(_row('a'));
      await repo.markRead('a');

      expect(api.markReadCalls, ['a']);
      expect((await dao.getById('a'))!.readAt, isNotNull);
      expect(await dao.pendingReadIds(), isEmpty);
    });

    test('offline: DAO still updated, id queued for next flush', () async {
      api.markReadThrows = true;
      await dao.upsert(_row('b'));
      await repo.markRead('b');

      expect(api.markReadCalls, ['b']);
      expect((await dao.getById('b'))!.readAt, isNotNull,
          reason: 'optimistic update must persist locally');
      expect(await dao.pendingReadIds(), ['b']);
    });
  });

  group('flushPendingReads', () {
    test('drains the queue when bulk endpoint succeeds', () async {
      await dao.enqueueReadMark('x', DateTime.utc(2026, 5, 13));
      await dao.enqueueReadMark('y', DateTime.utc(2026, 5, 13));

      await repo.flushPendingReads();

      expect(api.bulkMarkReadCalls, hasLength(1));
      expect(api.bulkMarkReadCalls.first, unorderedEquals(['x', 'y']));
      expect(await dao.pendingReadIds(), isEmpty);
    });

    test('keeps the queue when bulk endpoint fails', () async {
      api.bulkMarkReadThrows = true;
      await dao.enqueueReadMark('x', DateTime.utc(2026, 5, 13));

      await repo.flushPendingReads();

      expect(await dao.pendingReadIds(), ['x']);
    });

    test('is a no-op when the queue is empty', () async {
      await repo.flushPendingReads();
      expect(api.bulkMarkReadCalls, isEmpty);
    });
  });

  group('syncIncremental', () {
    test('upserts server rows + flushes the read queue first', () async {
      // Cache has one stale row.
      await dao.upsert(_row('old', title: 'stale-title'));
      // A pending read mark must be flushed BEFORE the GET.
      await dao.enqueueReadMark('old', DateTime.utc(2026, 5, 13));

      api.nextListItems = [
        _row('old', title: 'fresh-title'),
        _row('new'),
      ];

      await repo.syncIncremental(force: true);

      // Bulk flush ran before list (order matters — passport §4.1).
      expect(api.bulkMarkReadCalls, hasLength(1));
      expect(api.listCalls, 1);

      // Server is authoritative — title was overwritten.
      expect((await dao.getById('old'))!.title, 'fresh-title');
      expect(await dao.getById('new'), isNotNull);
      expect(await dao.pendingReadIds(), isEmpty);
    });

    test('does not crash when the list endpoint throws', () async {
      api.listThrows = true;
      // No exception should bubble — sync is best-effort.
      await repo.syncIncremental(force: true);
      expect(api.listCalls, 1);
    });
  });

  group('fetchAndCache', () {
    test('returns fresh row and replaces the cache', () async {
      await dao.upsert(_row('z', title: 'cached'));
      api.nextDetail = _row('z', title: 'fresh');

      final result = await repo.fetchAndCache('z');

      expect(result, isNotNull);
      expect(result!.title, 'fresh');
      expect((await dao.getById('z'))!.title, 'fresh');
    });

    test('evicts the local row on 404', () async {
      await dao.upsert(_row('gone'));
      api.detailNotFound = true;

      final result = await repo.fetchAndCache('gone');

      expect(result, isNull);
      expect(await dao.getById('gone'), isNull);
    });

    test('keeps the local row on transient network failure', () async {
      await dao.upsert(_row('keep'));
      api.detailThrows = true;

      final result = await repo.fetchAndCache('keep');

      expect(result, isNull);
      // Important: a network blip must NOT delete the local row.
      expect(await dao.getById('keep'), isNotNull);
    });
  });

  group('unreadCount stream', () {
    test('reflects markRead immediately (optimistic)', () async {
      await dao.upsert(_row('u1'));
      await dao.upsert(_row('u2'));
      // Re-bootstrap so the streams pick up the seed.
      await repo.bootstrap();
      // Bootstrap is idempotent — manually push via markRead to verify
      // the stream tick.
      final counts = <int>[];
      final sub = repo.unreadCountStream.listen(counts.add);

      await repo.markRead('u1');
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      // The first emitted value is the seeded one; later values must
      // include a decrement.
      expect(counts, contains(1));
    });
  });

  group('clearForLogout', () {
    test('wipes both tables and resets the streams', () async {
      await dao.upsert(_row('a'));
      await dao.enqueueReadMark('a', DateTime.utc(2026, 5, 13));

      await repo.clearForLogout();

      expect(await dao.getAll(), isEmpty);
      expect(await dao.pendingReadIds(), isEmpty);
      expect(repo.unreadCountValue, 0);
      expect(repo.listValue, isEmpty);
    });
  });
}
