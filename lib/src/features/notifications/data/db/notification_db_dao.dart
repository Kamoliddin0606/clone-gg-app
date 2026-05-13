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
        last_synced_at TEXT NOT NULL
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

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  Future<List<AppNotification>> getAll({int limit = 200}) async {
    final db = await _db;
    final rows = await db.query(
      notificationsTable,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(AppNotification.fromDbRow).toList();
  }

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

  Future<int> unreadCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM $notificationsTable WHERE read_at IS NULL',
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

  Future<void> upsert(AppNotification notification) async {
    final db = await _db;
    await db.insert(
      notificationsTable,
      notification.toDbRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAll(Iterable<AppNotification> notifications) async {
    final db = await _db;
    final batch = db.batch();
    for (final n in notifications) {
      batch.insert(
        notificationsTable,
        n.toDbRow(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
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
