import 'package:sqflite/sqflite.dart';

import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/models/app_notification.dart';

/// Local sqflite DAO for the notification cache. Two tables:
///
/// * `notifications` — last N rows (200 or 30 days, whichever is
///   larger). Source of truth for the list screen and the unread badge.
/// * `pending_read_marks` — offline queue. Rows land here when
///   `POST /notifications/{id}/read/` fails; the next sync flushes them
///   via the bulk endpoint.
///
/// The DAO is intentionally thin: callers should compose it inside
/// [NotificationRepository], not hit it directly from the UI.
class NotificationDbDao {
  static const String notificationsTable = 'notifications';
  static const String pendingReadTable = 'pending_read_marks';

  final DatabaseHelper _dbHelper;

  NotificationDbDao(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  // ---------------------------------------------------------------------------
  // Schema bootstrap (called both from `onCreate` and `onUpgrade` paths)
  // ---------------------------------------------------------------------------

  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $notificationsTable (
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
        last_synced_at TEXT NOT NULL,
        snooze_until  TEXT
      )
    ''');
    // Sort the list view by created_at without scanning the whole table.
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${notificationsTable}_created_at '
      'ON $notificationsTable(created_at DESC)',
    );
    // Filter unread quickly for the badge count.
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${notificationsTable}_read_at '
      'ON $notificationsTable(read_at)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $pendingReadTable (
        notification_id TEXT PRIMARY KEY,
        marked_at       TEXT NOT NULL
      )
    ''');
  }

  /// Phase 2b migration helper — adds the `snooze_until` column to an
  /// existing v5 schema. Idempotent: silently swallows the "duplicate
  /// column" error so re-running the migration on a partially-upgraded
  /// install does not crash boot.
  static Future<void> addSnoozeColumn(Database db) async {
    try {
      await db.execute(
        'ALTER TABLE $notificationsTable ADD COLUMN snooze_until TEXT',
      );
    } on DatabaseException catch (e) {
      // `duplicate column` is fine — someone already ran this. Anything
      // else means the schema is unexpected; rethrow so we notice.
      if (!e.toString().toLowerCase().contains('duplicate column')) {
        rethrow;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// List ordered by `created_at` DESC. Snoozed rows whose `snooze_until`
  /// is still in the future are hidden — once the timestamp elapses,
  /// the row reappears automatically on the next call.
  Future<List<AppNotification>> getAll({int limit = 200, DateTime? now}) async {
    final db = await _db;
    final cutoff = (now ?? DateTime.now()).toUtc().toIso8601String();
    final rows = await db.query(
      notificationsTable,
      where: 'snooze_until IS NULL OR snooze_until <= ?',
      whereArgs: [cutoff],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(AppNotification.fromDbRow).toList();
  }

  /// Single-row read — does NOT hide snoozed rows, since the detail
  /// screen is typically reached via a deep link or push tap and the
  /// user has an explicit reason to see it.
  Future<AppNotification?> getById(String id) async {
    final db = await _db;
    final rows = await db.query(
      notificationsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppNotification.fromDbRow(rows.first);
  }

  /// Badge counter — unread rows that are NOT currently snoozed.
  /// Snoozed-and-unread rows are intentionally excluded; otherwise the
  /// bell badge would stay lit even when nothing is visible in the list.
  Future<int> unreadCount({DateTime? now}) async {
    final db = await _db;
    final cutoff = (now ?? DateTime.now()).toUtc().toIso8601String();
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM $notificationsTable '
      'WHERE read_at IS NULL '
      'AND (snooze_until IS NULL OR snooze_until <= ?)',
      [cutoff],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Most recent unread rows of a given [type] — feeds the Android
  /// InboxStyle summary notification (Phase 2 stretch — grouping).
  /// Snoozed and read rows are excluded so the summary shows only
  /// what the user would actually see in the list.
  Future<List<AppNotification>> recentUnreadByType(
    String type, {
    int limit = 5,
    DateTime? now,
  }) async {
    final db = await _db;
    final cutoff = (now ?? DateTime.now()).toUtc().toIso8601String();
    final rows = await db.query(
      notificationsTable,
      where: 'type = ? AND read_at IS NULL '
          'AND (snooze_until IS NULL OR snooze_until <= ?)',
      whereArgs: [type, cutoff],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(AppNotification.fromDbRow).toList();
  }

  /// Count of unread + non-snoozed rows of a given [type] — used as the
  /// "N new" prefix on the Android group summary.
  Future<int> unreadCountByType(String type, {DateTime? now}) async {
    final db = await _db;
    final cutoff = (now ?? DateTime.now()).toUtc().toIso8601String();
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM $notificationsTable '
      'WHERE type = ? AND read_at IS NULL '
      'AND (snooze_until IS NULL OR snooze_until <= ?)',
      [type, cutoff],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Most recent `last_synced_at` across all rows — used as the `since`
  /// cursor for the next pull. Returns `null` when the cache is empty.
  Future<DateTime?> lastSyncedAt() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT MAX(last_synced_at) AS max_synced FROM $notificationsTable',
    );
    final raw = rows.first['max_synced'];
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /// Upsert a single row, preserving client-managed state that the
  /// server doesn't know about:
  ///   * `snooze_until` — never reset by a server push.
  ///   * `read_at` — never reset when local has a stamp and the
  ///     server returns null (mark-read may not have propagated yet,
  ///     or the device went offline before the API call). Keeps the
  ///     EARLIER of the two non-null stamps so the immutable read
  ///     history survives.
  ///
  /// Use [unsnooze] / [markUnread] for explicit clears.
  Future<void> upsert(AppNotification notification) async {
    final db = await _db;
    final row = await _mergeLocalState(db, notification);
    await db.insert(
      notificationsTable,
      row.toDbRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAll(Iterable<AppNotification> notifications) async {
    final db = await _db;
    // Batch the lookup so a 50-row sync stays at 2 queries instead of
    // 51 (N+1). We grab BOTH snooze_until and read_at for every id —
    // the same merge rules apply to both columns.
    final ids = notifications.map((n) => n.id).toList(growable: false);
    final existingById = <String, _ExistingState>{};
    if (ids.isNotEmpty) {
      final placeholders = List.filled(ids.length, '?').join(',');
      final rows = await db.query(
        notificationsTable,
        columns: ['id', 'snooze_until', 'read_at'],
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
      for (final r in rows) {
        existingById[r['id'] as String] = _ExistingState(
          snoozeUntil: _parseColumn(r['snooze_until']),
          readAt: _parseColumn(r['read_at']),
        );
      }
    }

    final batch = db.batch();
    for (final n in notifications) {
      final existing = existingById[n.id];
      final merged = existing == null
          ? n
          : n.copyWith(
              snoozeUntil: n.snoozeUntil ?? existing.snoozeUntil,
              readAt: _earlierReadAt(n.readAt, existing.readAt),
            );
      batch.insert(
        notificationsTable,
        merged.toDbRow(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Set `snooze_until` on a single row. Used by the long-press menu.
  Future<void> snooze(String id, DateTime until) async {
    final db = await _db;
    await db.update(
      notificationsTable,
      {'snooze_until': until.toUtc().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clear a previously-set snooze (`snooze_until = NULL`). Used by
  /// fetchAndCache / the long-press menu's "Don't snooze" entry.
  Future<void> unsnooze(String id) async {
    final db = await _db;
    await db.update(
      notificationsTable,
      {'snooze_until': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Reverse of [markRead] — flip a row back to unread. Used by the
  /// long-press menu's "Mark as unread" entry. Local-only; the backend
  /// has no "unread" endpoint (passport §8) and would re-flag it on
  /// the next sync if it ever shipped one — that's the desired outcome.
  Future<void> markUnread(String id) async {
    final db = await _db;
    await db.update(
      notificationsTable,
      {'read_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Helper for the single-row [upsert]: preserve client-managed
  /// columns (`snooze_until`, `read_at`) when the incoming model
  /// would otherwise erase them. Mirrors the batch logic inside
  /// [upsertAll].
  Future<AppNotification> _mergeLocalState(
    Database db,
    AppNotification notification,
  ) async {
    // Skip the round-trip if there's nothing to merge.
    if (notification.snoozeUntil != null && notification.readAt != null) {
      return notification;
    }
    final existing = await db.query(
      notificationsTable,
      columns: ['snooze_until', 'read_at'],
      where: 'id = ?',
      whereArgs: [notification.id],
      limit: 1,
    );
    if (existing.isEmpty) return notification;
    final existingSnooze = _parseColumn(existing.first['snooze_until']);
    final existingReadAt = _parseColumn(existing.first['read_at']);
    return notification.copyWith(
      snoozeUntil: notification.snoozeUntil ?? existingSnooze,
      readAt: _earlierReadAt(notification.readAt, existingReadAt),
    );
  }

  /// Parse an ISO-8601 column into a UTC [DateTime], tolerant of nulls
  /// and malformed values (returns `null` rather than throwing).
  static DateTime? _parseColumn(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// Pick the EARLIER of two `read_at` timestamps. Once a notification
  /// has been read, the read history is immutable — if a sync brings
  /// back a later timestamp (e.g. server-side mark-read happened
  /// after the local optimistic mark), the first time wins. Either
  /// argument may be null; null is treated as "never read".
  static DateTime? _earlierReadAt(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }

  Future<void> markRead(String id, DateTime readAt) async {
    final db = await _db;
    await db.update(
      notificationsTable,
      {'read_at': readAt.toUtc().toIso8601String()},
      where: 'id = ? AND read_at IS NULL',
      whereArgs: [id],
    );
  }

  Future<void> markAllRead(DateTime readAt) async {
    final db = await _db;
    await db.update(
      notificationsTable,
      {'read_at': readAt.toUtc().toIso8601String()},
      where: 'read_at IS NULL',
    );
  }

  Future<void> deleteById(String id) async {
    final db = await _db;
    await db.delete(notificationsTable, where: 'id = ?', whereArgs: [id]);
  }

  /// Cache eviction: keep the newest [keepLast] rows OR everything in
  /// the last [keepWindow], whichever is larger. Matches the rule in
  /// `passport-mobile.md` §4.3.
  Future<int> evictOld({
    int keepLast = 200,
    Duration keepWindow = const Duration(days: 30),
  }) async {
    final db = await _db;
    final cutoff = DateTime.now().toUtc().subtract(keepWindow);
    final cutoffIso = cutoff.toIso8601String();
    // Delete rows that are BOTH older than the window AND outside the
    // newest-N rolling window. Read rows go first; unread are never
    // evicted by this rule.
    final deleted = await db.rawDelete(
      '''
      DELETE FROM $notificationsTable
      WHERE read_at IS NOT NULL
        AND created_at < ?
        AND id NOT IN (
          SELECT id FROM $notificationsTable
          ORDER BY created_at DESC
          LIMIT ?
        )
      ''',
      [cutoffIso, keepLast],
    );
    return deleted;
  }

  // ---------------------------------------------------------------------------
  // Pending read marks (offline queue)
  // ---------------------------------------------------------------------------

  Future<void> enqueueReadMark(String id, DateTime markedAt) async {
    final db = await _db;
    await db.insert(
      pendingReadTable,
      {
        'notification_id': id,
        'marked_at': markedAt.toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<String>> pendingReadIds() async {
    final db = await _db;
    final rows = await db.query(pendingReadTable);
    return rows
        .map((r) => r['notification_id'] as String)
        .toList(growable: false);
  }

  Future<void> dequeueReadMarks(Iterable<String> ids) async {
    if (ids.isEmpty) return;
    final db = await _db;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete(
      pendingReadTable,
      where: 'notification_id IN ($placeholders)',
      whereArgs: ids.toList(),
    );
  }

  Future<void> clearAll() async {
    final db = await _db;
    final batch = db.batch();
    batch.delete(notificationsTable);
    batch.delete(pendingReadTable);
    await batch.commit(noResult: true);
  }
}

/// Internal struct — client-managed columns we need to preserve when
/// the server pushes a fresh row over an existing one. Only used by
/// the batch merge inside [NotificationDbDao.upsertAll].
class _ExistingState {
  final DateTime? snoozeUntil;
  final DateTime? readAt;

  const _ExistingState({required this.snoozeUntil, required this.readAt});
}
