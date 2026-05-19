import 'package:equatable/equatable.dart';

import 'task_code.dart';

/// Per-task lifecycle as tracked locally and reported in the envelope.
enum TaskRunStatus {
  pending('pending'),
  inProgress('in_progress'),
  completed('completed'),
  skipped('skipped'),
  failed('failed');

  const TaskRunStatus(this.wire);
  final String wire;

  static TaskRunStatus fromWire(String wire) {
    for (final value in values) {
      if (value.wire == wire) return value;
    }
    throw ArgumentError('Unknown TaskRunStatus: $wire');
  }
}

/// One task within a [VisitSession]. The class is intentionally generic:
/// per-task payload shape lives in [payload] (a free-form map validated
/// against the catalog's JSON Schema) so adding a new task type doesn't
/// require new model code — see `TaskRendererRegistry` for the UI side.
class VisitTask extends Equatable {
  const VisitTask({
    required this.taskId,
    required this.taskCodeRaw,
    required this.displayOrder,
    required this.required,
    required this.status,
    required this.payload,
    required this.payloadSchemaVersion,
    this.startedAt,
    this.endedAt,
    this.durationMs,
  });

  /// UUIDv7 generated when the task slot is first materialised in the session.
  final String taskId;

  /// Wire string. Use [taskCode] to get the enum, [taskCodeRaw] preserves
  /// unknown codes so generic renderer can still handle them.
  final String taskCodeRaw;

  /// Resolved enum, or `null` for codes the mobile build doesn't know about
  /// (server-driven catalog may introduce new ones).
  TaskCode? get taskCode => TaskCode.fromCode(taskCodeRaw);

  final int displayOrder;
  final bool required;
  final TaskRunStatus status;

  /// Polymorphic payload. Shape is dictated by the catalog's
  /// `payload_schema`; the renderer is responsible for building it and the
  /// envelope just passes it through.
  final Map<String, dynamic> payload;

  final int payloadSchemaVersion;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? durationMs;

  VisitTask copyWith({
    TaskRunStatus? status,
    Map<String, dynamic>? payload,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationMs,
  }) {
    return VisitTask(
      taskId: taskId,
      taskCodeRaw: taskCodeRaw,
      displayOrder: displayOrder,
      required: required,
      payloadSchemaVersion: payloadSchemaVersion,
      status: status ?? this.status,
      payload: payload ?? this.payload,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  @override
  List<Object?> get props => [
        taskId,
        taskCodeRaw,
        displayOrder,
        required,
        status,
        payload,
        payloadSchemaVersion,
        startedAt,
        endedAt,
        durationMs,
      ];
}
