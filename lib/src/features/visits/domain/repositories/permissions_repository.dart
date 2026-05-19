import '../entities/permissions.dart';

/// ETag-cached permissions store. The repository is allowed to return a
/// cached snapshot when offline; callers must accept that the
/// `visitSubmissionPath` flag may lag the server by up to the configured
/// TTL (default 1 hour).
abstract class PermissionsRepository {
  /// Returns the last known permissions, or fetches fresh ones if [forceRefresh]
  /// is set or the cache is older than [maxAge].
  Future<VisitsPermissions> getCurrent({
    bool forceRefresh = false,
    Duration maxAge = const Duration(hours: 1),
  });

  /// Sync helper used by `FeatureFlags`/UI badges. Returns `null` if the cache
  /// has never been warmed in this install.
  VisitsPermissions? get cached;
}
