import 'package:equatable/equatable.dart';

import 'device_info.dart';
import 'task.dart';
import 'visit_location.dart';

/// Wire-shape of the atomic `POST /api/mobile/v2/visits/finish/` body.
///
/// Built once, on finish, by `VisitEnvelopeBuilder` from a [VisitSession].
/// The exact same instance is serialised into the outbox row and replayed on
/// retry — never rebuilt. That's what makes the [idempotencyKey] meaningful:
/// the same bytes always carry the same key.
class VisitEnvelope extends Equatable {
  const VisitEnvelope({
    required this.envelopeId,
    required this.visitId,
    required this.customerId,
    required this.clientUuid,
    required this.idempotencyKey,
    required this.plannedFlag,
    required this.startedAt,
    required this.finishedAt,
    required this.totalDurationMs,
    required this.outcome,
    required this.startLocation,
    required this.finishLocation,
    required this.device,
    required this.clientClockDriftMs,
    required this.networkFlags,
    required this.tasks,
  });

  /// UUIDv7 of the outbox row. Logged to telemetry on every retry.
  final String envelopeId;

  final String visitId;
  final String customerId;

  /// Stable per-install device UUID. The backend pairs it with
  /// [idempotencyKey] to deduplicate.
  final String clientUuid;

  /// UUIDv7 used as the backend idempotency key. Generated once per outbox
  /// row; constant across retries.
  final String idempotencyKey;

  final bool plannedFlag;
  final DateTime startedAt;
  final DateTime finishedAt;
  final int totalDurationMs;

  /// `'completed'` or `'aborted'`.
  final String outcome;

  final VisitLocation startLocation;
  final VisitLocation finishLocation;
  final VisitDeviceInfo device;
  final int clientClockDriftMs;
  final Map<String, dynamic> networkFlags;
  final List<EnvelopeTask> tasks;

  Map<String, dynamic> toJson() => {
        'client_uuid': clientUuid,
        'idempotency_key': idempotencyKey,
        'visit_id': visitId,
        'customer_id': customerId,
        'planned_flag': plannedFlag,
        'started_at': startedAt.toUtc().toIso8601String(),
        'finished_at': finishedAt.toUtc().toIso8601String(),
        'total_duration_ms': totalDurationMs,
        'outcome': outcome,
        'start_location': startLocation.toJson(),
        'finish_location': finishLocation.toJson(),
        'device': device.toJson(),
        'client_clock_drift_ms': clientClockDriftMs,
        'network_flags': networkFlags,
        'tasks': tasks.map((t) => t.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        envelopeId,
        visitId,
        customerId,
        clientUuid,
        idempotencyKey,
        plannedFlag,
        startedAt,
        finishedAt,
        totalDurationMs,
        outcome,
        startLocation,
        finishLocation,
        device,
        clientClockDriftMs,
        networkFlags,
        tasks,
      ];
}

/// Per-task slice of the envelope. Built from a [VisitTask] but trimmed to
/// the fields the backend needs (no UI helpers, no runtime fields).
class EnvelopeTask extends Equatable {
  const EnvelopeTask({
    required this.taskId,
    required this.taskCode,
    required this.startedAt,
    required this.endedAt,
    required this.durationMs,
    required this.status,
    required this.payload,
    required this.payloadSchemaVersion,
  });

  final String taskId;
  final String taskCode;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationMs;
  final TaskRunStatus status;
  final Map<String, dynamic> payload;
  final int payloadSchemaVersion;

  Map<String, dynamic> toJson() => {
        'task_id': taskId,
        'task_code': taskCode,
        'started_at': startedAt.toUtc().toIso8601String(),
        'ended_at': endedAt.toUtc().toIso8601String(),
        'duration_ms': durationMs,
        'status': status.wire,
        'payload': payload,
        'payload_schema_version': payloadSchemaVersion,
      };

  @override
  List<Object?> get props => [
        taskId,
        taskCode,
        startedAt,
        endedAt,
        durationMs,
        status,
        payload,
        payloadSchemaVersion,
      ];
}
