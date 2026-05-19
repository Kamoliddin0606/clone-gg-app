import 'package:equatable/equatable.dart';

/// One entry from `GET /api/mobile/v2/visits/catalog/`. Drives both
/// validation (JSON Schema) and UI selection (renderer hint).
class CatalogTask extends Equatable {
  const CatalogTask({
    required this.taskCode,
    required this.nameI18n,
    required this.required,
    required this.displayOrder,
    required this.payloadSchema,
    required this.payloadSchemaVersion,
    required this.config,
    required this.rendererHint,
  });

  final String taskCode;

  /// Locale → display name. Mobile picks current locale; falls back to `en`
  /// then to the `task_code` itself.
  final Map<String, String> nameI18n;

  final bool required;
  final int displayOrder;

  /// JSON Schema draft-07 the [payload] map of a task must satisfy before
  /// the envelope is allowed to leave the device.
  final Map<String, dynamic> payloadSchema;

  final int payloadSchemaVersion;

  /// Free-form per-task config (e.g. survey questions, photo limits). Lives
  /// here so admin can add new task types without a mobile release.
  final Map<String, dynamic> config;

  /// `'custom'` → look up `TaskRendererRegistry`; `'generic'` → use
  /// `GenericFormRenderer`. Hint only — the registry is the source of truth.
  final String rendererHint;

  String displayName(String localeCode) =>
      nameI18n[localeCode] ?? nameI18n['en'] ?? taskCode;

  factory CatalogTask.fromJson(Map<String, dynamic> json) => CatalogTask(
        taskCode: json['task_code'] as String,
        nameI18n: ((json['name_i18n'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k as String, v as String)),
        required: json['required'] as bool? ?? false,
        displayOrder: json['display_order'] as int? ?? 0,
        payloadSchema:
            (json['payload_schema'] as Map?)?.cast<String, dynamic>() ??
                const {},
        payloadSchemaVersion: json['payload_schema_version'] as int? ?? 1,
        config:
            (json['config'] as Map?)?.cast<String, dynamic>() ?? const {},
        rendererHint: json['renderer_hint'] as String? ?? 'generic',
      );

  @override
  List<Object?> get props => [
        taskCode,
        nameI18n,
        required,
        displayOrder,
        payloadSchema,
        payloadSchemaVersion,
        config,
        rendererHint,
      ];
}

class VisitsCatalog extends Equatable {
  const VisitsCatalog({
    required this.etag,
    required this.tasks,
  });

  final String etag;
  final List<CatalogTask> tasks;

  CatalogTask? byCode(String taskCode) {
    for (final t in tasks) {
      if (t.taskCode == taskCode) return t;
    }
    return null;
  }

  factory VisitsCatalog.fromJson(Map<String, dynamic> json,
      {required String etag}) {
    // Backend wraps the catalog rows in `{"results": [...]}` (DRF-style
    // pagination envelope); older builds may have used `{"tasks": [...]}`
    // — accept either so a mixed-version rollout doesn't break parse.
    final raw = (json['results'] ?? json['tasks']) as List<dynamic>? ??
        const [];
    return VisitsCatalog(
      etag: etag,
      tasks: raw
          .map((e) => CatalogTask.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [etag, tasks];
}
