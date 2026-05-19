import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../domain/entities/device_info.dart';
import '../../domain/entities/local_visit_status.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/visit_location.dart';
import '../../domain/entities/visit_session.dart';

/// sqflite CRUD for `visits_v2` + `visit_tasks_v2`. The repository layer
/// owns the rebuilding of the [VisitSession] aggregate from these two
/// tables, but the SQL itself lives here.
class VisitLocalDataSource {
  VisitLocalDataSource(this._db);

  final Future<Database> Function() _db;

  static const _visits = 'visits_v2';
  static const _tasks = 'visit_tasks_v2';

  Future<void> upsert(VisitSession s) async {
    final db = await _db();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.insert(
        _visits,
        {
          'visit_id': s.visitId,
          'customer_id': s.customerId,
          'planned_flag': s.plannedFlag ? 1 : 0,
          'status': s.status.wire,
          'started_at': s.startedAt.millisecondsSinceEpoch,
          'finished_at': s.finishedAt?.millisecondsSinceEpoch,
          'envelope_id': s.envelopeId,
          'app_version': s.appVersion,
          'start_location_json': jsonEncode(s.startLocation.toJson()),
          'finish_location_json':
              s.finishLocation == null ? null : jsonEncode(s.finishLocation!.toJson()),
          'device_info_json': jsonEncode(s.device.toJson()),
          'network_flags_json': jsonEncode(s.networkFlags),
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Tasks are managed as a snapshot — wipe and reinsert. Volumes are
      // tiny (≤ ~15 tasks/visit), so the simplicity beats diffing.
      await txn.delete(_tasks, where: 'visit_id = ?', whereArgs: [s.visitId]);
      for (final t in s.tasks) {
        await txn.insert(_tasks, {
          'task_id': t.taskId,
          'visit_id': s.visitId,
          'task_code': t.taskCodeRaw,
          'display_order': t.displayOrder,
          'started_at': t.startedAt?.millisecondsSinceEpoch,
          'ended_at': t.endedAt?.millisecondsSinceEpoch,
          'duration_ms': t.durationMs,
          'status': t.status.wire,
          'payload_json': jsonEncode(t.payload),
          'payload_schema_version': t.payloadSchemaVersion,
        });
      }
    });
  }

  Future<VisitSession?> findById(String visitId) async {
    final db = await _db();
    final rows = await db.query(_visits,
        where: 'visit_id = ?', whereArgs: [visitId], limit: 1);
    if (rows.isEmpty) return null;
    final tasks = await _loadTasks(db, visitId);
    return _toSession(rows.first, tasks);
  }

  Future<List<VisitSession>> findByStatus(List<String> statuses) async {
    if (statuses.isEmpty) return const [];
    final db = await _db();
    final placeholders = List.filled(statuses.length, '?').join(',');
    final rows = await db.query(
      _visits,
      where: 'status IN ($placeholders)',
      whereArgs: statuses,
      orderBy: 'started_at DESC',
    );
    final result = <VisitSession>[];
    for (final r in rows) {
      final id = r['visit_id'] as String;
      final tasks = await _loadTasks(db, id);
      result.add(_toSession(r, tasks));
    }
    return result;
  }

  Future<void> updateStatus(String visitId, LocalVisitStatus status) async {
    final db = await _db();
    await db.update(
      _visits,
      {
        'status': status.wire,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'visit_id = ?',
      whereArgs: [visitId],
    );
  }

  Future<int> purgeSyncedOlderThan(Duration age) async {
    final db = await _db();
    final cutoff =
        DateTime.now().subtract(age).millisecondsSinceEpoch;
    return db.delete(
      _visits,
      where: 'status = ? AND updated_at < ?',
      whereArgs: ['synced', cutoff],
    );
  }

  Future<List<VisitTask>> _loadTasks(Database db, String visitId) async {
    final rows = await db.query(
      _tasks,
      where: 'visit_id = ?',
      whereArgs: [visitId],
      orderBy: 'display_order ASC',
    );
    return rows
        .map((m) => VisitTask(
              taskId: m['task_id'] as String,
              taskCodeRaw: m['task_code'] as String,
              displayOrder: m['display_order'] as int,
              required: false, // Required-ness lives in catalog, not local row.
              status: TaskRunStatus.fromWire(m['status'] as String),
              payload: (jsonDecode(m['payload_json'] as String) as Map)
                  .cast<String, dynamic>(),
              payloadSchemaVersion: m['payload_schema_version'] as int,
              startedAt: m['started_at'] == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(m['started_at'] as int),
              endedAt: m['ended_at'] == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(m['ended_at'] as int),
              durationMs: m['duration_ms'] as int?,
            ))
        .toList(growable: false);
  }

  VisitSession _toSession(Map<String, Object?> m, List<VisitTask> tasks) {
    final startedAt =
        DateTime.fromMillisecondsSinceEpoch(m['started_at'] as int);
    final finishedAtMs = m['finished_at'] as int?;
    final startLocJson =
        jsonDecode(m['start_location_json'] as String) as Map<String, dynamic>;
    final finishLocRaw = m['finish_location_json'] as String?;
    final deviceJson =
        jsonDecode(m['device_info_json'] as String) as Map<String, dynamic>;
    final networkRaw = m['network_flags_json'] as String?;

    return VisitSession(
      visitId: m['visit_id'] as String,
      customerId: m['customer_id'] as String,
      plannedFlag: (m['planned_flag'] as int) == 1,
      startedAt: startedAt,
      finishedAt: finishedAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(finishedAtMs),
      tasks: tasks,
      status: LocalVisitStatus.fromWire(m['status'] as String),
      startLocation: VisitLocation.fromJson(startLocJson),
      finishLocation: finishLocRaw == null
          ? null
          : VisitLocation.fromJson(
              jsonDecode(finishLocRaw) as Map<String, dynamic>),
      device: VisitDeviceInfo.fromJson(deviceJson),
      envelopeId: m['envelope_id'] as String?,
      appVersion: m['app_version'] as String?,
      networkFlags: networkRaw == null
          ? const {}
          : (jsonDecode(networkRaw) as Map).cast<String, dynamic>(),
    );
  }
}
