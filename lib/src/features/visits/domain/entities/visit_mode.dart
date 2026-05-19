import 'permissions.dart';

/// Visit-creation mode the user is in, derived from the two new
/// scope-cascade flags on [PermissionFlags].
///
/// The four-mode UX rule (passport § 3.1):
///
/// | `unplannedOnlyMode` | `allowUnplannedVisit` | Mode            |
/// |---------------------|-----------------------|-----------------|
/// | true                | false                 | [blocked]       |
/// | false               | false                 | [plannedOnly]   |
/// | true                | true                  | [unplannedOnly] |
/// | false               | true                  | [both]          |
///
/// Mobile never re-computes the cascade itself — backend is the single
/// authoritative source. We only branch on the resolved flags.
enum VisitMode {
  /// No tasks configured AND user lacks `visits.add_unplanned_visit`.
  /// UI shows a "configuration missing" screen; no start button.
  blocked,

  /// Tasks are configured but user cannot create unplanned visits.
  /// Standard flow — start button leads to the planned-route trading
  /// points list, geofence enforced.
  plannedOnly,

  /// No tasks configured, but user can still create unplanned visits.
  /// UI shows a single "create unplanned" entry point, no radius circle.
  unplannedOnly,

  /// Tasks are configured AND user can create unplanned visits.
  /// UI shows both entry points (planned route + ad-hoc unplanned).
  both;

  /// True when the user can start at least one kind of visit.
  bool get canStartAnyVisit => this != VisitMode.blocked;

  /// True when planned visits are available in this mode.
  bool get canStartPlanned =>
      this == VisitMode.plannedOnly || this == VisitMode.both;

  /// True when unplanned visits are available in this mode.
  bool get canStartUnplanned =>
      this == VisitMode.unplannedOnly || this == VisitMode.both;

  /// Resolve the mode from the two flag fields the server delivers.
  ///
  /// Defaults to [plannedOnly] when called against an older backend
  /// that omits both flags (i.e. both default to false): that is the
  /// safest reading — the user can keep visiting planned trading points
  /// the same way they did before the cascade rollout.
  static VisitMode fromFlags({
    required bool unplannedOnlyMode,
    required bool allowUnplannedVisit,
  }) {
    if (unplannedOnlyMode && !allowUnplannedVisit) return VisitMode.blocked;
    if (unplannedOnlyMode && allowUnplannedVisit) {
      return VisitMode.unplannedOnly;
    }
    if (!unplannedOnlyMode && allowUnplannedVisit) return VisitMode.both;
    return VisitMode.plannedOnly;
  }

  /// Convenience reader off a fully-parsed permissions snapshot.
  static VisitMode fromPermissions(VisitsPermissions perms) => fromFlags(
        unplannedOnlyMode: perms.flags.unplannedOnlyMode,
        allowUnplannedVisit: perms.flags.allowUnplannedVisit,
      );
}
