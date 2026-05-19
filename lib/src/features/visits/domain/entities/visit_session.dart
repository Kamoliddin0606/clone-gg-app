import 'package:equatable/equatable.dart';

import 'device_info.dart';
import 'local_visit_status.dart';
import 'task.dart';
import 'visit_location.dart';

/// In-memory aggregate of an active or recovered visit.
///
/// Lifecycle: created when the user taps "start visit", mutated as tasks
/// complete, drained into a [VisitEnvelope] (built separately) on finish.
/// Persisted to `visits_v2` / `visit_tasks_v2` between mutations so a crash
/// or app restart can resume it without server help — see the resume policy
/// agreed in the plan (server has no in-flight visit concept).
class VisitSession extends Equatable {
  const VisitSession({
    required this.visitId,
    required this.customerId,
    required this.plannedFlag,
    required this.startedAt,
    required this.tasks,
    required this.status,
    required this.startLocation,
    required this.device,
    this.finishedAt,
    this.finishLocation,
    this.totalDurationMs,
    this.envelopeId,
    this.appVersion,
    this.networkFlags = const {},
  });

  /// Mobile-generated UUIDv7. Travels unchanged to the server.
  final String visitId;

  final String customerId;
  final bool plannedFlag;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int? totalDurationMs;

  /// Ordered by `displayOrder`. The runtime currentIndex is BLoC state,
  /// not session state.
  final List<VisitTask> tasks;

  final LocalVisitStatus status;
  final VisitLocation startLocation;
  final VisitLocation? finishLocation;
  final VisitDeviceInfo device;

  /// UUIDv7 of the outbox envelope built from this session on finish. `null`
  /// while the session is still in progress.
  final String? envelopeId;

  final String? appVersion;
  final Map<String, dynamic> networkFlags;

  bool get allRequiredCompleted => tasks
      .where((t) => t.required)
      .every((t) => t.status == TaskRunStatus.completed);

  VisitSession copyWith({
    DateTime? finishedAt,
    int? totalDurationMs,
    List<VisitTask>? tasks,
    LocalVisitStatus? status,
    VisitLocation? finishLocation,
    String? envelopeId,
    Map<String, dynamic>? networkFlags,
  }) {
    return VisitSession(
      visitId: visitId,
      customerId: customerId,
      plannedFlag: plannedFlag,
      startedAt: startedAt,
      startLocation: startLocation,
      device: device,
      appVersion: appVersion,
      finishedAt: finishedAt ?? this.finishedAt,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      tasks: tasks ?? this.tasks,
      status: status ?? this.status,
      finishLocation: finishLocation ?? this.finishLocation,
      envelopeId: envelopeId ?? this.envelopeId,
      networkFlags: networkFlags ?? this.networkFlags,
    );
  }

  @override
  List<Object?> get props => [
        visitId,
        customerId,
        plannedFlag,
        startedAt,
        finishedAt,
        totalDurationMs,
        tasks,
        status,
        startLocation,
        finishLocation,
        device,
        envelopeId,
        appVersion,
        networkFlags,
      ];
}
