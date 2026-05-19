import 'package:uuid/uuid.dart';

import '../../domain/entities/task.dart';
import '../../domain/entities/visit_envelope.dart';
import '../../domain/entities/visit_session.dart';
import '../../domain/entities/visit_location.dart';

/// Translates a finished [VisitSession] + the finish-time fix into the
/// [VisitEnvelope] that the outbox serialises and POSTs.
///
/// Pulled into its own class so the BLoC stays declarative ("build the
/// envelope, hand it to the outbox") and unit tests can exercise the
/// serialisation contract without spinning up Dio.
class VisitEnvelopeBuilder {
  VisitEnvelopeBuilder({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  VisitEnvelope build({
    required VisitSession session,
    required String clientUuid,
    required VisitLocation finishLocation,
    required DateTime finishedAt,
    required int clientClockDriftMs,
    required Map<String, dynamic> networkFlags,
    String outcome = 'completed',
  }) {
    final total = finishedAt.difference(session.startedAt).inMilliseconds;
    final envelopeId = session.envelopeId ?? _uuid.v7();
    final idempotencyKey = _uuid.v7();

    final tasks = session.tasks
        .where((t) =>
            t.status == TaskRunStatus.completed ||
            t.status == TaskRunStatus.skipped)
        .map<EnvelopeTask>((t) => EnvelopeTask(
              taskId: t.taskId,
              taskCode: t.taskCodeRaw,
              startedAt: t.startedAt ?? session.startedAt,
              endedAt: t.endedAt ?? finishedAt,
              durationMs: t.durationMs ??
                  ((t.endedAt ?? finishedAt)
                      .difference(t.startedAt ?? session.startedAt)
                      .inMilliseconds),
              status: t.status,
              payload: t.payload,
              payloadSchemaVersion: t.payloadSchemaVersion,
            ))
        .toList(growable: false);

    return VisitEnvelope(
      envelopeId: envelopeId,
      visitId: session.visitId,
      customerId: session.customerId,
      clientUuid: clientUuid,
      idempotencyKey: idempotencyKey,
      plannedFlag: session.plannedFlag,
      startedAt: session.startedAt,
      finishedAt: finishedAt,
      totalDurationMs: total,
      outcome: outcome,
      startLocation: session.startLocation,
      finishLocation: finishLocation,
      device: session.device,
      clientClockDriftMs: clientClockDriftMs,
      networkFlags: networkFlags,
      tasks: tasks,
    );
  }
}
