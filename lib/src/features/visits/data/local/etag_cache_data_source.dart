import 'package:sqflite/sqflite.dart';

/// Persists ETag + JSON snapshot for `/permissions/` and `/catalog/` so the
/// next refresh can send `If-None-Match` and keep working offline.
class EtagCacheDataSource {
  EtagCacheDataSource(this._db);

  final Future<Database> Function() _db;

  Future<void> upsertPermissions({
    required String userCode,
    required String projectCode,
    required String etag,
    required String json,
  }) async {
    final db = await _db();
    await db.insert(
      'permissions_cache',
      {
        'user_code': userCode,
        'project_code': projectCode,
        'etag': etag,
        'json': json,
        'fetched_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, Object?>?> readPermissions({
    required String userCode,
    required String projectCode,
  }) async {
    final db = await _db();
    final rows = await db.query(
      'permissions_cache',
      where: 'user_code = ? AND project_code = ?',
      whereArgs: [userCode, projectCode],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> upsertCatalog({
    required String projectCode,
    required String etag,
    required String json,
  }) async {
    final db = await _db();
    await db.insert(
      'catalog_cache',
      {
        'project_code': projectCode,
        'etag': etag,
        'json': json,
        'fetched_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, Object?>?> readCatalog(String projectCode) async {
    final db = await _db();
    final rows = await db.query(
      'catalog_cache',
      where: 'project_code = ?',
      whereArgs: [projectCode],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }
}
