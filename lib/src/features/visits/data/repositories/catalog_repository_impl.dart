import 'dart:convert';

import '../../domain/entities/catalog_task.dart';
import '../../domain/failures.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../local/etag_cache_data_source.dart';
import '../rest/visit_api.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl({
    required VisitApi api,
    required EtagCacheDataSource cache,
    required Future<String> Function() projectCodeLoader,
  })  : _api = api,
        _cache = cache,
        _projectCode = projectCodeLoader;

  final VisitApi _api;
  final EtagCacheDataSource _cache;
  final Future<String> Function() _projectCode;

  VisitsCatalog? _hot;

  @override
  VisitsCatalog? get cached => _hot;

  @override
  Future<VisitsCatalog> getCurrent({
    bool forceRefresh = false,
    Duration maxAge = const Duration(hours: 1),
  }) async {
    final projectCode = await _projectCode();
    if (_hot == null) {
      final row = await _cache.readCatalog(projectCode);
      if (row != null) {
        _hot = VisitsCatalog.fromJson(
          (jsonDecode(row['json'] as String) as Map).cast<String, dynamic>(),
          etag: row['etag'] as String,
        );
      }
    }

    final isFresh =
        _hot != null && !forceRefresh && await _withinMaxAge(projectCode, maxAge);
    if (isFresh) return _hot!;

    try {
      final fresh = await _api.fetchCatalog(etag: _hot?.etag);
      _hot = fresh;
      await _cache.upsertCatalog(
        projectCode: projectCode,
        etag: fresh.etag,
        json: jsonEncode(_toJson(fresh)),
      );
      return fresh;
    } on NotModifiedException {
      // 304 — cached catalog is authoritative. Backend changelog § 9.
      return _hot!;
    } on NetworkFailure {
      if (_hot != null) return _hot!;
      rethrow;
    }
  }

  Future<bool> _withinMaxAge(String projectCode, Duration maxAge) async {
    final row = await _cache.readCatalog(projectCode);
    if (row == null) return false;
    final fetchedAt =
        DateTime.fromMillisecondsSinceEpoch(row['fetched_at'] as int);
    return DateTime.now().difference(fetchedAt) < maxAge;
  }

  Map<String, dynamic> _toJson(VisitsCatalog c) => {
        // Cache under the canonical backend key so a disk round-trip
        // exercises the same parse path as a fresh REST response.
        'results': c.tasks
            .map((t) => {
                  'task_code': t.taskCode,
                  'name_i18n': t.nameI18n,
                  'required': t.required,
                  'display_order': t.displayOrder,
                  'payload_schema': t.payloadSchema,
                  'payload_schema_version': t.payloadSchemaVersion,
                  'config': t.config,
                  'renderer_hint': t.rendererHint,
                })
            .toList(),
      };
}
