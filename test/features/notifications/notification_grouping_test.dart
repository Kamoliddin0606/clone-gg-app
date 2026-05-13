import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/db/notification_db_dao.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/models/app_notification.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/push_handler_service.dart';

/// Phase 2 stretch — notification grouping.
///
/// Coverage:
///   * Group key wire format is stable across versions (Android
///     `groupKey` + iOS `threadIdentifier` share the value).
///   * Summary id is deterministic per type so successive pushes
///     replace the same summary card.
///   * DAO query feeding InboxStyle returns ONLY unread + non-snoozed
///     rows, newest first, capped at `limit`.
///   * Summary title localisation handles every known type.

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
  String type = 'debt_alert',
  DateTime? createdAt,
  DateTime? readAt,
  DateTime? snoozeUntil,
  String title = 'T',
  String body = 'B',
}) {
  return AppNotification(
    id: id,
    type: type,
    priority: 'high',
    title: title,
    body: body,
    createdAt: createdAt ?? DateTime.utc(2026, 5, 13, 8, 0),
    readAt: readAt,
    snoozeUntil: snoozeUntil,
    lastSyncedAt: DateTime.utc(2026, 5, 13, 8, 0),
  );
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('groupKeyFor — wire format', () {
    test('known type', () {
      expect(PushHandlerService.groupKeyFor('debt_alert'),
          'selup_debt_alert');
    });

    test('null or empty falls back to a default bucket', () {
      expect(PushHandlerService.groupKeyFor(null), 'selup_default');
      expect(PushHandlerService.groupKeyFor(''), 'selup_default');
    });

    test('unknown server-side type still keys deterministically', () {
      // Phase 3 may ship new types — they should still group, just
      // under their own bucket. No allow-list at this layer.
      expect(PushHandlerService.groupKeyFor('some_future_type'),
          'selup_some_future_type');
    });
  });

  group('summaryIdFor — Android replacement key', () {
    test('stable across calls', () {
      final a = PushHandlerService.summaryIdFor('debt_alert');
      final b = PushHandlerService.summaryIdFor('debt_alert');
      expect(a, b);
    });

    test('differs across types', () {
      expect(
        PushHandlerService.summaryIdFor('debt_alert'),
        isNot(PushHandlerService.summaryIdFor('order_new')),
      );
    });

    test('does not collide with row-id hash space (high bit set)', () {
      // Row notifications use `id.hashCode & 0x7fffffff` — i.e. the
      // top bit is 0. Summary ids must NOT mask that pattern or
      // Android would treat them as the same notification.
      final id = PushHandlerService.summaryIdFor('debt_alert');
      expect(id & 0x40000000, isNot(0),
          reason: 'summary id keeps the 0x40000000 bit set');
    });
  });

  group('summaryTitleFor — localised label', () {
    test('every known type maps to a non-empty Uzbek label', () {
      const known = [
        'debt_alert',
        'order_new',
        'stock_lot_expiring',
        'system_announcement',
      ];
      for (final type in known) {
        final title = PushHandlerService.summaryTitleFor(type, 3);
        expect(title.startsWith('3 ta yangi '), isTrue,
            reason: 'title for $type was "$title"');
        expect(title.length > '3 ta yangi '.length, isTrue);
      }
    });

    test('unknown type falls back to the generic label', () {
      expect(PushHandlerService.summaryTitleFor('something_new', 2),
          contains('bildirishnoma'));
    });
  });

  group('DAO — recentUnreadByType + unreadCountByType', () {
    late Database db;
    late NotificationDbDao dao;

    setUp(() async {
      db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await NotificationDbDao.createTables(db);
      dao = NotificationDbDao(_InMemoryDbHelper(db));
    });

    tearDown(() => db.close());

    test('newest-first ordering capped at limit', () async {
      final base = DateTime.utc(2026, 5, 13, 8, 0);
      await dao.upsertAll(List.generate(
        10,
        (i) => _row('row-$i',
            createdAt: base.add(Duration(minutes: i))),
      ));
      final lines = await dao.recentUnreadByType('debt_alert', limit: 5);
      expect(lines.map((n) => n.id),
          ['row-9', 'row-8', 'row-7', 'row-6', 'row-5']);
    });

    test('excludes read rows', () async {
      await dao.upsertAll([
        _row('unread'),
        _row('read', readAt: DateTime.utc(2026, 5, 13, 9, 0)),
      ]);
      final lines = await dao.recentUnreadByType('debt_alert');
      expect(lines.map((n) => n.id), ['unread']);
    });

    test('excludes snoozed rows', () async {
      final now = DateTime.utc(2026, 5, 13, 12, 0);
      await dao.upsertAll([
        _row('visible'),
        _row('snoozed',
            snoozeUntil: now.add(const Duration(hours: 1))),
      ]);
      final lines = await dao.recentUnreadByType('debt_alert', now: now);
      expect(lines.map((n) => n.id), ['visible']);
    });

    test('filters by type', () async {
      await dao.upsertAll([
        _row('debt-1', type: 'debt_alert'),
        _row('order-1', type: 'order_new'),
      ]);
      final lines = await dao.recentUnreadByType('debt_alert');
      expect(lines.map((n) => n.id), ['debt-1']);
    });

    test('unreadCountByType mirrors the row filter', () async {
      final now = DateTime.utc(2026, 5, 13, 12, 0);
      await dao.upsertAll([
        _row('a'),
        _row('b'),
        _row('c-read', readAt: DateTime.utc(2026, 5, 13, 9, 0)),
        _row('d-snoozed',
            snoozeUntil: now.add(const Duration(hours: 1))),
        _row('e-other-type', type: 'order_new'),
      ]);
      expect(
        await dao.unreadCountByType('debt_alert', now: now),
        2,
      );
    });
  });
}
