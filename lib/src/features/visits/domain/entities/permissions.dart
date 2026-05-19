import 'package:equatable/equatable.dart';

/// Which transport the mobile app should use for visit finish.
///
/// Server flips this flag via `/permissions/` so rollback to SOAP is a
/// flags-only change — no app release required.
enum VisitSubmissionPath {
  soap('soap'),
  restV2('rest_v2');

  const VisitSubmissionPath(this.wire);
  final String wire;

  static VisitSubmissionPath fromWire(String? wire) {
    if (wire == null) return VisitSubmissionPath.soap; // safe default
    for (final v in values) {
      if (v.wire == wire) return v;
    }
    return VisitSubmissionPath.soap;
  }
}

/// Boolean toggles delivered by `/api/mobile/v2/visits/permissions/`.
class PermissionFlags extends Equatable {
  const PermissionFlags({
    required this.visit,
    required this.strictSequence,
    required this.unplannedOrder,
    required this.plannedRoute,
    required this.editClientCoordinates,
    required this.skipTinDuplicateCheck,
    required this.allowCreationWithoutTin,
    required this.visitSubmissionPath,
    this.allowUnplannedVisit = false,
    this.unplannedOnlyMode = false,
  });

  final bool visit;
  final bool strictSequence;
  final bool unplannedOrder;
  final bool plannedRoute;
  final bool editClientCoordinates;
  final bool skipTinDuplicateCheck;
  final bool allowCreationWithoutTin;
  final VisitSubmissionPath visitSubmissionPath;

  /// Scope-cascade addition (2026-05-17): true when the user holds the
  /// `visits.add_unplanned_visit` RBAC codename. When false, the mobile
  /// must never submit an envelope with `planned_flag=false` — backend
  /// would respond 403 `permission_denied` with detail
  /// `required_codename=visits.add_unplanned_visit`.
  final bool allowUnplannedVisit;

  /// Scope-cascade addition (2026-05-17): true when no level
  /// (user/project/org) has any task configured. The user can still
  /// create *unplanned* visits if [allowUnplannedVisit] is true;
  /// otherwise visit creation is fully blocked.
  final bool unplannedOnlyMode;

  factory PermissionFlags.fromJson(Map<String, dynamic> json) =>
      PermissionFlags(
        visit: json['visit'] as bool? ?? false,
        strictSequence: json['strict_sequence'] as bool? ?? false,
        unplannedOrder: json['unplanned_order'] as bool? ?? false,
        plannedRoute: json['planned_route'] as bool? ?? false,
        editClientCoordinates:
            json['edit_client_coordinates'] as bool? ?? false,
        skipTinDuplicateCheck:
            json['skip_tin_duplicate_check'] as bool? ?? false,
        allowCreationWithoutTin:
            json['allow_creation_without_tin'] as bool? ?? false,
        visitSubmissionPath:
            VisitSubmissionPath.fromWire(json['visit_submission_path'] as String?),
        allowUnplannedVisit: json['allow_unplanned_visit'] as bool? ?? false,
        unplannedOnlyMode: json['unplanned_only_mode'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        visit,
        strictSequence,
        unplannedOrder,
        plannedRoute,
        editClientCoordinates,
        skipTinDuplicateCheck,
        allowCreationWithoutTin,
        visitSubmissionPath,
        allowUnplannedVisit,
        unplannedOnlyMode,
      ];
}

/// Numeric and structured limits applied to a visit. Anything the user
/// experience must enforce up-front comes from here — we never hard-code
/// thresholds in the mobile build.
class PermissionThresholds extends Equatable {
  const PermissionThresholds({
    required this.clientZoneAccessM,
    required this.locationUpdateIntervalS,
    required this.gpsAccuracyMaxM,
    required this.clockDriftMaxS,
    required this.maxPhotosPerTask,
    required this.minPhotosPerTask,
  });

  /// Allowed planned-visit radius in metres. `0` disables the radius check.
  final int clientZoneAccessM;

  final int locationUpdateIntervalS;

  /// Reject GPS fixes wider than this (in metres). Also used as the upper
  /// bound when computing the per-visit accuracy gate (`radius / 3`).
  final int gpsAccuracyMaxM;

  /// `|client_now - server_time|` may not exceed this many seconds.
  final int clockDriftMaxS;

  final int maxPhotosPerTask;

  /// Per-taskCode lower bound on attached photos (e.g. PHOTO_BEFORE → 1).
  final Map<String, int> minPhotosPerTask;

  factory PermissionThresholds.fromJson(Map<String, dynamic> json) =>
      PermissionThresholds(
        clientZoneAccessM: json['client_zone_access_m'] as int? ?? 0,
        locationUpdateIntervalS:
            json['location_update_interval_s'] as int? ?? 30,
        gpsAccuracyMaxM: json['gps_accuracy_max_m'] as int? ?? 30,
        clockDriftMaxS: json['clock_drift_max_s'] as int? ?? 300,
        maxPhotosPerTask: json['max_photos_per_task'] as int? ?? 10,
        minPhotosPerTask: ((json['min_photos_per_task'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k as String, v as int)),
      );

  @override
  List<Object?> get props => [
        clientZoneAccessM,
        locationUpdateIntervalS,
        gpsAccuracyMaxM,
        clockDriftMaxS,
        maxPhotosPerTask,
        minPhotosPerTask,
      ];
}

/// Aggregate of `/permissions/` response. ETag is stored alongside so the
/// next request can send `If-None-Match`.
///
/// The backend contract uses opaque UUIDs (`user_id` / `project_id`) for
/// these handles — the early Phase 1 mobile build expected human-readable
/// codes (`user_code`), but Phase 2 of the rollout flipped to UUIDs to
/// stay in sync with `apps.tenants.Organization.id` / `apps.accounts.User.id`.
/// The mobile field names keep the legacy `Code` suffix to spare the BLoCs
/// and routers a rename; the wire keys (`user_id`, `project_id`) are what
/// the JSON parser actually reads.
class VisitsPermissions extends Equatable {
  const VisitsPermissions({
    required this.etag,
    required this.userCode,
    required this.projectCode,
    required this.flags,
    required this.thresholds,
    required this.enabledTasks,
    required this.taskOrder,
    required this.taskRequired,
    this.resolvedScope,
  });

  final String etag;

  /// Scope-cascade addition (2026-05-17): debug-only field naming which
  /// level the backend resolved tasks/thresholds from. One of
  /// `"user"` / `"project"` / `"organization"` / `"none"`, or null when
  /// the field is absent (older backend). UI must NOT branch on this —
  /// only telemetry / Crashlytics tags consume it.
  final String? resolvedScope;

  /// Backend `user_id` (UUID). Name kept as `userCode` to avoid touching
  /// every caller — it's the same value, just relabelled.
  final String userCode;

  /// Backend `project_id` (UUID, or empty string when `customer_scope=
  /// organization`).
  final String projectCode;
  final PermissionFlags flags;
  final PermissionThresholds thresholds;

  /// Wire `task_code`s the user is allowed to see. Unknown codes are kept
  /// verbatim — they may render via `GenericFormRenderer`.
  final List<String> enabledTasks;

  /// Display order. Same length and elements as [enabledTasks] (server
  /// guarantees this).
  final List<String> taskOrder;

  /// `task_code` → required flag. Missing entries default to optional.
  final Map<String, bool> taskRequired;

  bool isRequired(String taskCode) => taskRequired[taskCode] ?? false;

  factory VisitsPermissions.fromJson(Map<String, dynamic> json,
      {required String etag}) {
    // Backend's canonical keys are `user_id` / `project_id`. Accept the
    // legacy `_code` variants too so a downgraded backend during rollout
    // doesn't break the parser; the field name preference order is
    // `_id` ➜ `_code` ➜ empty string.
    final userId = (json['user_id'] ?? json['user_code']) as String? ?? '';
    final projectId =
        (json['project_id'] ?? json['project_code']) as String? ?? '';
    // The body sometimes echoes the etag (Phase 2 backend does); fall back
    // to the header value the caller already extracted.
    final bodyEtag = json['etag'] as String?;
    return VisitsPermissions(
      etag: bodyEtag != null && bodyEtag.isNotEmpty ? bodyEtag : etag,
      userCode: userId,
      projectCode: projectId,
      flags: PermissionFlags.fromJson(
          (json['flags'] as Map?)?.cast<String, dynamic>() ?? const {}),
      thresholds: PermissionThresholds.fromJson(
          (json['thresholds'] as Map?)?.cast<String, dynamic>() ?? const {}),
      enabledTasks:
          (json['enabled_tasks'] as List<dynamic>?)?.cast<String>() ??
              const [],
      taskOrder:
          (json['task_order'] as List<dynamic>?)?.cast<String>() ?? const [],
      taskRequired: ((json['task_required'] as Map?) ?? const {})
          .map((k, v) => MapEntry(k as String, v as bool)),
      resolvedScope: json['resolved_scope'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        etag,
        userCode,
        projectCode,
        flags,
        thresholds,
        enabledTasks,
        taskOrder,
        taskRequired,
        resolvedScope,
      ];
}
