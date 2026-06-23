import 'package:sqflite/sqflite.dart';

import 'telemetry_outbox_entry.dart';

/// Thin sqflite wrapper for the `telemetry_outbox` table. Keeps SQL in one
/// place so the repository layer can stay focused on status-transition policy.
///
/// Modeled on `OutboxDataSource`
/// (`lib/src/features/visits/data/local/outbox_data_source.dart`) but adds
/// **batch** read/write helpers because the telemetry endpoint accepts many
/// pings per POST.
class TelemetryOutboxDataSource {
  TelemetryOutboxDataSource(this._db);

  final Future<Database> Function() _db;

  static const _table = 'telemetry_outbox';

  /// Insert a freshly-collected ping. `ConflictAlgorithm.ignore` makes enqueue
  /// idempotent on `ping_id` / `idempotency_key` so a double-enqueue (e.g. a
  /// retried collection tick) never throws or duplicates.
  Future<void> insert(TelemetryOutboxEntry entry) async {
    final db = await _db();
    await db.insert(
      _table,
      _toMap(entry),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Oldest [limit] entries that are due (`pending`/`retrying` and
  /// `next_attempt_at <= now`), ordered for FIFO drain.
  Future<List<TelemetryOutboxEntry>> peekDueBatch(DateTime now, int limit) async {
    final db = await _db();
    final rows = await db.query(
      _table,
      where: 'status IN (?, ?) AND next_attempt_at <= ?',
      whereArgs: [
        TelemetryOutboxEntry.statusPending,
        TelemetryOutboxEntry.statusRetrying,
        now.millisecondsSinceEpoch,
      ],
      orderBy: 'next_attempt_at ASC, created_at ASC',
      limit: limit,
    );
    return rows.map(_fromMap).toList(growable: false);
  }

  Future<TelemetryOutboxEntry?> findById(String pingId) async {
    final db = await _db();
    final rows = await db.query(
      _table,
      where: 'ping_id = ?',
      whereArgs: [pingId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  /// Flip a set of rows to `in_flight` in one transaction so a parallel cycle
  /// cannot grab the same rows.
  Future<void> markInFlightMany(List<String> pingIds, DateTime now) async {
    if (pingIds.isEmpty) return;
    final db = await _db();
    final batch = db.batch();
    for (final id in pingIds) {
      batch.update(
        _table,
        {
          'status': TelemetryOutboxEntry.statusInFlight,
          'updated_at': now.millisecondsSinceEpoch,
        },
        where: 'ping_id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Delete a set of rows (used to drop `ack`ed pings — no point keeping them).
  Future<void> deleteMany(List<String> pingIds) async {
    if (pingIds.isEmpty) return;
    final db = await _db();
    final batch = db.batch();
    for (final id in pingIds) {
      batch.delete(_table, where: 'ping_id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateStatus(
    String pingId, {
    required String status,
    DateTime? nextAttemptAt,
    int? attempts,
    String? lastError,
    int? lastHttpStatus,
    required DateTime now,
  }) async {
    final db = await _db();
    final updates = <String, Object?>{
      'status': status,
      'updated_at': now.millisecondsSinceEpoch,
    };
    if (nextAttemptAt != null) {
      updates['next_attempt_at'] = nextAttemptAt.millisecondsSinceEpoch;
    }
    if (attempts != null) updates['attempts'] = attempts;
    if (lastError != null) updates['last_error'] = lastError;
    if (lastHttpStatus != null) updates['last_http_status'] = lastHttpStatus;

    await db.update(
      _table,
      updates,
      where: 'ping_id = ?',
      whereArgs: [pingId],
    );
  }

  Future<Map<String, int>> countByStatus() async {
    final db = await _db();
    final rows = await db
        .rawQuery('SELECT status, COUNT(*) AS c FROM $_table GROUP BY status');
    return {
      for (final r in rows) r['status'] as String: (r['c'] as int? ?? 0),
    };
  }

  Future<int> count() async {
    final db = await _db();
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
    return (rows.first['c'] as int?) ?? 0;
  }

  /// Retention sweep: delete the oldest `ack`/`dead_letter` rows first, then —
  /// only if still over [maxRows] — the oldest unsent rows. Returns the number
  /// of UNSENT rows dropped (for the loss metric). Unlike the old
  /// SharedPreferences cap this is explicit and auditable, and terminal rows
  /// are always reclaimed before live data.
  Future<int> pruneToCap(int maxRows) async {
    final db = await _db();
    final total = await count();
    if (total <= maxRows) return 0;

    var toDrop = total - maxRows;

    // 1) Reclaim terminal rows first (acked rows are normally deleted on ack,
    //    but dead_letter rows linger for the diagnostics surface).
    final terminal = await db.query(
      _table,
      columns: ['ping_id'],
      where: 'status IN (?, ?)',
      whereArgs: [
        TelemetryOutboxEntry.statusAck,
        TelemetryOutboxEntry.statusDeadLetter,
      ],
      orderBy: 'created_at ASC',
      limit: toDrop,
    );
    if (terminal.isNotEmpty) {
      await deleteMany(
          terminal.map((r) => r['ping_id'] as String).toList(growable: false));
      toDrop -= terminal.length;
    }
    if (toDrop <= 0) return 0;

    // 2) Last resort: drop the oldest UNSENT rows. This is real data loss, so
    //    the caller logs the returned count.
    final unsent = await db.query(
      _table,
      columns: ['ping_id'],
      orderBy: 'created_at ASC',
      limit: toDrop,
    );
    final ids = unsent.map((r) => r['ping_id'] as String).toList(growable: false);
    await deleteMany(ids);
    return ids.length;
  }

  /// Recover rows left `in_flight` by a cycle that died mid-send (app killed,
  /// isolate torn down). Flips them back to `pending` (due now) so the next
  /// cycle retries them. Re-sending is safe because each ping carries an
  /// `idempotency_key` the server dedups on.
  Future<void> requeueInFlight(DateTime now) async {
    final db = await _db();
    await db.update(
      _table,
      {
        'status': TelemetryOutboxEntry.statusPending,
        'next_attempt_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      },
      where: 'status = ?',
      whereArgs: [TelemetryOutboxEntry.statusInFlight],
    );
  }

  /// Wipe everything — called on logout so one user's backlog can never be
  /// uploaded under another user's token.
  Future<void> purgeAll() async {
    final db = await _db();
    await db.delete(_table);
  }

  Map<String, Object?> _toMap(TelemetryOutboxEntry e) => {
        'ping_id': e.pingId,
        'payload_json': e.payloadJson,
        'client_uuid': e.clientUuid,
        'idempotency_key': e.idempotencyKey,
        'status': e.status,
        'attempts': e.attempts,
        'max_attempts': e.maxAttempts,
        'next_attempt_at': e.nextAttemptAt.millisecondsSinceEpoch,
        'last_error': e.lastError,
        'last_http_status': e.lastHttpStatus,
        'logged_at': e.loggedAt.millisecondsSinceEpoch,
        'created_at': e.createdAt.millisecondsSinceEpoch,
        'updated_at': e.updatedAt.millisecondsSinceEpoch,
      };

  TelemetryOutboxEntry _fromMap(Map<String, Object?> m) => TelemetryOutboxEntry(
        pingId: m['ping_id'] as String,
        payloadJson: m['payload_json'] as String,
        clientUuid: m['client_uuid'] as String,
        idempotencyKey: m['idempotency_key'] as String,
        status: m['status'] as String,
        attempts: m['attempts'] as int,
        maxAttempts: m['max_attempts'] as int,
        nextAttemptAt:
            DateTime.fromMillisecondsSinceEpoch(m['next_attempt_at'] as int),
        lastError: m['last_error'] as String?,
        lastHttpStatus: m['last_http_status'] as int?,
        loggedAt: DateTime.fromMillisecondsSinceEpoch(m['logged_at'] as int),
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
      );
}
