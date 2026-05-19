import 'package:equatable/equatable.dart';

import 'entity_image_ref.dart';

/// Read-shape of a visit returned by `GET /api/mobile/v2/visits/` and
/// `GET /api/mobile/v2/visits/{id}/`. Mirrors backend `VisitRead`
/// schema (OpenAPI line 20435+).
///
/// Mobile renders this in the visit-history list and detail pages. The
/// envelope mobile sent on finish is a *write* shape — this is the
/// post-persist projection with denormalised IDs and aggregated tasks.
class VisitReadSummary extends Equatable {
  const VisitReadSummary({
    required this.id,
    required this.customerId,
    required this.status,
    required this.startedAt,
    required this.plannedFlag,
    this.finishedAt,
    this.outcome,
    this.totalDurationMs,
  });

  final String id;
  final String customerId;

  /// `draft` | `submitted` | `synced_1c` | `cancelled` | `rejected`.
  final String status;

  final DateTime startedAt;
  final DateTime? finishedAt;
  final bool plannedFlag;
  final String? outcome;
  final int? totalDurationMs;

  bool get isSynced1C => status == 'synced_1c';
  bool get isFinished => finishedAt != null;

  factory VisitReadSummary.fromJson(Map<String, dynamic> json) {
    return VisitReadSummary(
      id: json['id'] as String,
      customerId: json['customer'] as String,
      status: json['status'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      finishedAt: json['finished_at'] == null
          ? null
          : DateTime.parse(json['finished_at'] as String),
      plannedFlag: (json['planned_flag'] as bool?) ?? false,
      outcome: json['outcome'] as String?,
      totalDurationMs: json['total_duration_ms'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        status,
        startedAt,
        finishedAt,
        plannedFlag,
        outcome,
        totalDurationMs,
      ];
}

/// Per-task slice of the detail response. `images` is populated from the
/// server-side `EntityImage` references attached to the task's
/// `photo_asset_ids`. Visit-list rows don't need this — only the detail
/// page expands tasks.
class VisitReadTask extends Equatable {
  const VisitReadTask({
    required this.id,
    required this.taskCode,
    required this.status,
    required this.displayOrder,
    required this.payload,
    this.startedAt,
    this.endedAt,
    this.durationMs,
    this.images = const [],
  });

  final String id;
  final String taskCode;
  final String status;
  final int displayOrder;
  final Map<String, dynamic> payload;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? durationMs;

  /// Resolved photo refs. The backend embeds these alongside `payload.
  /// photo_asset_ids` for the detail endpoint so mobile can render the
  /// retention-aware thumbnail chain without an extra fetch per asset.
  final List<EntityImageRef> images;

  factory VisitReadTask.fromJson(Map<String, dynamic> json) {
    return VisitReadTask(
      id: json['id'] as String,
      taskCode: json['task_code'] as String,
      status: json['status'] as String,
      displayOrder: (json['display_order'] as int?) ?? 0,
      payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] == null
          ? null
          : DateTime.parse(json['ended_at'] as String),
      durationMs: json['duration_ms'] as int?,
      images: ((json['images'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(EntityImageRef.fromJson)
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => [
        id,
        taskCode,
        status,
        displayOrder,
        payload,
        startedAt,
        endedAt,
        durationMs,
        images,
      ];
}

/// Full visit + tasks payload returned by `GET /visits/{id}/`.
class VisitReadDetail extends VisitReadSummary {
  const VisitReadDetail({
    required super.id,
    required super.customerId,
    required super.status,
    required super.startedAt,
    required super.plannedFlag,
    required this.tasks,
    super.finishedAt,
    super.outcome,
    super.totalDurationMs,
    this.startLocation,
    this.finishLocation,
  });

  final List<VisitReadTask> tasks;
  final Map<String, dynamic>? startLocation;
  final Map<String, dynamic>? finishLocation;

  factory VisitReadDetail.fromDetailJson(Map<String, dynamic> json) {
    final summary = VisitReadSummary.fromJson(json);
    return VisitReadDetail(
      id: summary.id,
      customerId: summary.customerId,
      status: summary.status,
      startedAt: summary.startedAt,
      finishedAt: summary.finishedAt,
      plannedFlag: summary.plannedFlag,
      outcome: summary.outcome,
      totalDurationMs: summary.totalDurationMs,
      tasks: ((json['tasks'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(VisitReadTask.fromJson)
          .toList(growable: false),
      startLocation:
          (json['start_location'] as Map?)?.cast<String, dynamic>(),
      finishLocation:
          (json['finish_location'] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  List<Object?> get props => [...super.props, tasks, startLocation, finishLocation];
}

/// One page of the cursor-paginated list endpoint.
class VisitReadPage extends Equatable {
  const VisitReadPage({
    required this.items,
    this.nextCursorUrl,
    this.previousCursorUrl,
  });

  final List<VisitReadSummary> items;

  /// Opaque DRF cursor URL — pass back to [VisitApi.fetchVisits] via
  /// the same query string to fetch the next page. `null` when the
  /// caller reached the end.
  final String? nextCursorUrl;
  final String? previousCursorUrl;

  bool get hasMore => nextCursorUrl != null;

  factory VisitReadPage.fromJson(Map<String, dynamic> json) {
    return VisitReadPage(
      nextCursorUrl: json['next'] as String?,
      previousCursorUrl: json['previous'] as String?,
      items: ((json['results'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(VisitReadSummary.fromJson)
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => [items, nextCursorUrl, previousCursorUrl];
}
