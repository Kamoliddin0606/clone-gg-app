/// One of five qaror values returned by the backend version-gate endpoint.
///
/// See `docs/integration-prompts/mobile-app-version-passport.md` §3.4 for the
/// full table. Mapping is intentionally fail-open: unknown / malformed values
/// resolve to [VersionGateStatus.ok] so a server-side typo can never lock the
/// user out.
enum VersionGateStatus {
  ok,
  softUpdate,
  forceUpdate,
  blocked,
  maintenance;

  static VersionGateStatus fromString(String? raw) {
    switch (raw) {
      case 'ok':
        return VersionGateStatus.ok;
      case 'soft_update':
        return VersionGateStatus.softUpdate;
      case 'force_update':
        return VersionGateStatus.forceUpdate;
      case 'blocked':
        return VersionGateStatus.blocked;
      case 'maintenance':
        return VersionGateStatus.maintenance;
      default:
        return VersionGateStatus.ok;
    }
  }

  String get wireValue {
    switch (this) {
      case VersionGateStatus.ok:
        return 'ok';
      case VersionGateStatus.softUpdate:
        return 'soft_update';
      case VersionGateStatus.forceUpdate:
        return 'force_update';
      case VersionGateStatus.blocked:
        return 'blocked';
      case VersionGateStatus.maintenance:
        return 'maintenance';
    }
  }

  /// True when the UI must replace the current navigation stack with the
  /// full-screen [VersionGateScreen]. Used by both the splash flow and the
  /// per-request 426 interceptor.
  bool get blocksApp =>
      this == VersionGateStatus.forceUpdate ||
      this == VersionGateStatus.blocked ||
      this == VersionGateStatus.maintenance;
}
