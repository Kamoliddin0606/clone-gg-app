import '../entities/catalog_task.dart';

/// ETag-cached task catalog (renderer hints + JSON Schema). Refreshed
/// lazily alongside permissions because the two often change together
/// (admin enables a new task and grants the permission in the same edit).
abstract class CatalogRepository {
  Future<VisitsCatalog> getCurrent({
    bool forceRefresh = false,
    Duration maxAge = const Duration(hours: 1),
  });

  VisitsCatalog? get cached;
}
