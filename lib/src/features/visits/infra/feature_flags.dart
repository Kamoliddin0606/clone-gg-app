import '../domain/entities/permissions.dart';
import '../domain/repositories/permissions_repository.dart';

/// Single source of truth for the SOAP↔REST v2 toggle.
///
/// Reads only the synchronous cached snapshot — the BLoC that decides the
/// path must have refreshed permissions already (handled at app start by
/// `PermissionsRepository.getCurrent()`). Defaults to SOAP when the cache
/// is empty so a fresh install can never accidentally hit a half-wired
/// REST flow.
class FeatureFlags {
  FeatureFlags(this._permissions);

  final PermissionsRepository _permissions;

  VisitSubmissionPath get visitSubmissionPath {
    return _permissions.cached?.flags.visitSubmissionPath ??
        VisitSubmissionPath.soap;
  }

  bool get useRestV2 => visitSubmissionPath == VisitSubmissionPath.restV2;
}
