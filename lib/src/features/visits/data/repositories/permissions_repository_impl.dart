import 'dart:convert';

import '../../domain/entities/permissions.dart';
import '../../domain/failures.dart';
import '../../domain/repositories/permissions_repository.dart';
import '../local/etag_cache_data_source.dart';
import '../rest/visit_api.dart';

class PermissionsRepositoryImpl implements PermissionsRepository {
  PermissionsRepositoryImpl({
    required VisitApi api,
    required EtagCacheDataSource cache,
    required Future<String> Function() userCodeLoader,
    required Future<String> Function() projectCodeLoader,
  })  : _api = api,
        _cache = cache,
        _userCode = userCodeLoader,
        _projectCode = projectCodeLoader;

  final VisitApi _api;
  final EtagCacheDataSource _cache;
  final Future<String> Function() _userCode;
  final Future<String> Function() _projectCode;

  VisitsPermissions? _hot;

  @override
  VisitsPermissions? get cached => _hot;

  @override
  Future<VisitsPermissions> getCurrent({
    bool forceRefresh = false,
    Duration maxAge = const Duration(hours: 1),
  }) async {
    final userCode = await _userCode();
    final projectCode = await _projectCode();

    // Warm the in-memory copy from disk on first call.
    if (_hot == null) {
      final row = await _cache.readPermissions(
          userCode: userCode, projectCode: projectCode);
      if (row != null) {
        _hot = VisitsPermissions.fromJson(
          (jsonDecode(row['json'] as String) as Map).cast<String, dynamic>(),
          etag: row['etag'] as String,
        );
      }
    }

    final isFresh = _hot != null && !forceRefresh && await _withinMaxAge(
      userCode: userCode,
      projectCode: projectCode,
      maxAge: maxAge,
    );
    if (isFresh) return _hot!;

    try {
      final fresh = await _api.fetchPermissions(etag: _hot?.etag);
      _hot = fresh;
      await _cache.upsertPermissions(
        userCode: userCode,
        projectCode: projectCode,
        etag: fresh.etag,
        json: jsonEncode(_toJson(fresh)),
      );
      return fresh;
    } on NotModifiedException {
      // 304 — our cached snapshot is still authoritative. The fetched_at
      // timestamp stays put on disk because nothing changed; the next
      // staleness check will re-issue the conditional GET. Backend
      // changelog § 9: ETag is the only thing that flips here.
      return _hot!;
    } on NetworkFailure {
      if (_hot != null) return _hot!;
      rethrow;
    }
  }

  Future<bool> _withinMaxAge({
    required String userCode,
    required String projectCode,
    required Duration maxAge,
  }) async {
    final row = await _cache.readPermissions(
        userCode: userCode, projectCode: projectCode);
    if (row == null) return false;
    final fetchedAt =
        DateTime.fromMillisecondsSinceEpoch(row['fetched_at'] as int);
    return DateTime.now().difference(fetchedAt) < maxAge;
  }

  Map<String, dynamic> _toJson(VisitsPermissions p) => {
        // Cache the canonical backend keys so a re-parse from disk
        // round-trips through the same code path as a fresh HTTP response.
        'user_id': p.userCode,
        'project_id': p.projectCode,
        'flags': {
          'visit': p.flags.visit,
          'strict_sequence': p.flags.strictSequence,
          'unplanned_order': p.flags.unplannedOrder,
          'planned_route': p.flags.plannedRoute,
          'edit_client_coordinates': p.flags.editClientCoordinates,
          'skip_tin_duplicate_check': p.flags.skipTinDuplicateCheck,
          'allow_creation_without_tin': p.flags.allowCreationWithoutTin,
          'visit_submission_path': p.flags.visitSubmissionPath.wire,
        },
        'thresholds': {
          'client_zone_access_m': p.thresholds.clientZoneAccessM,
          'location_update_interval_s': p.thresholds.locationUpdateIntervalS,
          'gps_accuracy_max_m': p.thresholds.gpsAccuracyMaxM,
          'clock_drift_max_s': p.thresholds.clockDriftMaxS,
          'max_photos_per_task': p.thresholds.maxPhotosPerTask,
          'min_photos_per_task': p.thresholds.minPhotosPerTask,
        },
        'enabled_tasks': p.enabledTasks,
        'task_order': p.taskOrder,
        'task_required': p.taskRequired,
      };
}
