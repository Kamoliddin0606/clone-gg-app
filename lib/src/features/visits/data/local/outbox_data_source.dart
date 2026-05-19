import 'package:sqflite/sqflite.dart';

import '../../domain/repositories/outbox_repository.dart';

/// Thin sqflite wrapper for the `outbox` table. Keeps SQL in one place so
/// the repository layer can stay focused on policy (backoff classification,
/// status transitions).
class OutboxDataSource {
  OutboxDataSource(this._db);

  final Future<Database> Function() _db;

  static const _table = 'outbox';

  Future<void> insert(OutboxEntry entry) async {
    final db = await _db();
    await db.insert(
      _table,
      _toMap(entry),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<OutboxEntry?> peekDue(DateTime now) async {
    final db = await _db();
    final rows = await db.query(
      _table,
      where: 'status IN (?, ?) AND next_attempt_at <= ?',
      whereArgs: ['pending', 'retrying', now.millisecondsSinceEpoch],
      orderBy: 'next_attempt_at ASC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  Future<void> updateStatus(
    String envelopeId, {
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
      where: 'envelope_id = ?',
      whereArgs: [envelopeId],
    );
  }

  Future<OutboxEntry?> findById(String envelopeId) async {
    final db = await _db();
    final rows = await db.query(
      _table,
      where: 'envelope_id = ?',
      whereArgs: [envelopeId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  Future<List<OutboxEntry>> findByStatus(String status) async {
    final db = await _db();
    final rows = await db.query(
      _table,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'updated_at DESC',
    );
    return rows.map(_fromMap).toList(growable: false);
  }

  Future<void> delete(String envelopeId) async {
    final db = await _db();
    await db.delete(_table, where: 'envelope_id = ?', whereArgs: [envelopeId]);
  }

  Future<Map<String, int>> countByStatus() async {
    final db = await _db();
    final rows = await db
        .rawQuery('SELECT status, COUNT(*) AS c FROM $_table GROUP BY status');
    return {
      for (final r in rows) r['status'] as String: (r['c'] as int? ?? 0),
    };
  }

  Map<String, Object?> _toMap(OutboxEntry e) => {
        'envelope_id': e.envelopeId,
        'visit_id': e.visitId,
        'endpoint': e.endpoint,
        'http_method': e.httpMethod,
        'payload_json': e.payloadJson,
        'idempotency_key': e.idempotencyKey,
        'client_uuid': e.clientUuid,
        'status': e.status,
        'attempts': e.attempts,
        'max_attempts': e.maxAttempts,
        'next_attempt_at': e.nextAttemptAt.millisecondsSinceEpoch,
        'last_error': e.lastError,
        'last_http_status': e.lastHttpStatus,
        'created_at': e.createdAt.millisecondsSinceEpoch,
        'updated_at': e.updatedAt.millisecondsSinceEpoch,
      };

  OutboxEntry _fromMap(Map<String, Object?> m) => OutboxEntry(
        envelopeId: m['envelope_id'] as String,
        visitId: m['visit_id'] as String?,
        endpoint: m['endpoint'] as String,
        httpMethod: m['http_method'] as String,
        payloadJson: m['payload_json'] as String,
        idempotencyKey: m['idempotency_key'] as String,
        clientUuid: m['client_uuid'] as String,
        status: m['status'] as String,
        attempts: m['attempts'] as int,
        maxAttempts: m['max_attempts'] as int,
        nextAttemptAt:
            DateTime.fromMillisecondsSinceEpoch(m['next_attempt_at'] as int),
        lastError: m['last_error'] as String?,
        lastHttpStatus: m['last_http_status'] as int?,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
      );
}
