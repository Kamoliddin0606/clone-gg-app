import 'package:sqflite/sqflite.dart';

import '../../domain/repositories/photo_repository.dart';

/// sqflite CRUD for `photo_uploads`.
class PhotoUploadsDataSource {
  PhotoUploadsDataSource(this._db);

  final Future<Database> Function() _db;

  static const _table = 'photo_uploads';

  Future<void> insert(PhotoUpload p) async {
    final db = await _db();
    await db.insert(_table, _toMap(p),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<List<PhotoUpload>> findUploadable({int maxAttempts = 5}) async {
    final db = await _db();
    final rows = await db.query(
      _table,
      where: '(status = ? OR (status = ? AND attempts < ?))',
      whereArgs: ['pending', 'failed', maxAttempts],
      orderBy: 'created_at ASC',
    );
    return rows.map(_fromMap).toList(growable: false);
  }

  Future<List<PhotoUpload>> findByTask(String visitId, String taskId) async {
    final db = await _db();
    final rows = await db.query(
      _table,
      where: 'visit_id = ? AND task_id = ?',
      whereArgs: [visitId, taskId],
      orderBy: 'created_at ASC',
    );
    return rows.map(_fromMap).toList(growable: false);
  }

  Future<void> updateStatus(
    String assetId, {
    required String status,
    String? remoteAssetId,
    String? lastError,
    bool incrementAttempts = false,
  }) async {
    final db = await _db();
    final updates = <String, Object?>{
      'status': status,
    };
    if (remoteAssetId != null) updates['remote_asset_id'] = remoteAssetId;
    if (lastError != null) updates['last_error'] = lastError;
    if (incrementAttempts) {
      // SQLite-safe atomic increment.
      await db.rawUpdate(
        'UPDATE $_table SET attempts = attempts + 1 WHERE asset_id = ?',
        [assetId],
      );
    }
    if (updates.isNotEmpty) {
      await db.update(_table, updates,
          where: 'asset_id = ?', whereArgs: [assetId]);
    }
  }

  Future<void> delete(String assetId) async {
    final db = await _db();
    await db.delete(_table, where: 'asset_id = ?', whereArgs: [assetId]);
  }

  Future<bool> allConfirmedFor(String visitId) async {
    final db = await _db();
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM $_table WHERE visit_id = ? AND status <> ?',
      [visitId, 'confirmed'],
    );
    final unconfirmed = (rows.first['c'] as int?) ?? 0;
    return unconfirmed == 0;
  }

  Future<bool> noFailedFor(String visitId) async {
    final db = await _db();
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM $_table WHERE visit_id = ? AND status = ?',
      [visitId, 'failed'],
    );
    final failed = (rows.first['c'] as int?) ?? 0;
    return failed == 0;
  }

  Map<String, Object?> _toMap(PhotoUpload p) => {
        'asset_id': p.assetId,
        'visit_id': p.visitId,
        'task_id': p.taskId,
        'task_code': p.taskCode,
        'local_path': p.localPath,
        'thumbnail_path': p.thumbnailPath,
        'sha256': p.sha256,
        'size_bytes': p.sizeBytes,
        'width': p.width,
        'height': p.height,
        'captured_at': p.capturedAt.millisecondsSinceEpoch,
        'lat': p.lat,
        'lng': p.lng,
        'accuracy_m': p.accuracyM,
        'status': p.status,
        'remote_asset_id': p.remoteAssetId,
        'attempts': p.attempts,
        'last_error': p.lastError,
        'idempotency_key': p.idempotencyKey,
        'created_at': p.createdAt.millisecondsSinceEpoch,
      };

  PhotoUpload _fromMap(Map<String, Object?> m) => PhotoUpload(
        assetId: m['asset_id'] as String,
        visitId: m['visit_id'] as String,
        taskId: m['task_id'] as String?,
        taskCode: m['task_code'] as String,
        localPath: m['local_path'] as String,
        thumbnailPath: m['thumbnail_path'] as String?,
        sha256: m['sha256'] as String,
        sizeBytes: m['size_bytes'] as int,
        width: m['width'] as int?,
        height: m['height'] as int?,
        capturedAt:
            DateTime.fromMillisecondsSinceEpoch(m['captured_at'] as int),
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        accuracyM: (m['accuracy_m'] as num?)?.toDouble(),
        status: m['status'] as String,
        remoteAssetId: m['remote_asset_id'] as String?,
        attempts: m['attempts'] as int? ?? 0,
        lastError: m['last_error'] as String?,
        idempotencyKey: m['idempotency_key'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );
}
