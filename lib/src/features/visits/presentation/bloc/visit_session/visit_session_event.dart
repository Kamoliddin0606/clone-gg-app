import 'package:equatable/equatable.dart';

import '../../../domain/entities/device_info.dart';
import '../../../domain/entities/visit_location.dart';

sealed class VisitSessionEvent extends Equatable {
  const VisitSessionEvent();

  @override
  List<Object?> get props => [];
}

/// Start a fresh visit. The BLoC validates geofence / clock drift before
/// transitioning to `VisitSessionActive`.
class StartVisit extends VisitSessionEvent {
  const StartVisit({
    required this.customerId,
    required this.plannedFlag,
    required this.startLocation,
    required this.device,
    required this.appVersion,
  });

  final String customerId;
  final bool plannedFlag;
  final VisitLocation startLocation;
  final VisitDeviceInfo device;
  final String appVersion;

  @override
  List<Object?> get props =>
      [customerId, plannedFlag, startLocation, device, appVersion];
}

/// Resume an `in_progress` visit from the local DB after a crash or
/// app-kill recovery.
class ResumeVisit extends VisitSessionEvent {
  const ResumeVisit(this.visitId);
  final String visitId;

  @override
  List<Object?> get props => [visitId];
}

class StartTask extends VisitSessionEvent {
  const StartTask(this.taskId);
  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

class CompleteTask extends VisitSessionEvent {
  const CompleteTask({
    required this.taskId,
    required this.payload,
  });

  final String taskId;
  final Map<String, dynamic> payload;

  @override
  List<Object?> get props => [taskId, payload];
}

class SkipTask extends VisitSessionEvent {
  const SkipTask({required this.taskId, required this.reason});
  final String taskId;
  final String reason;

  @override
  List<Object?> get props => [taskId, reason];
}

class FinishVisit extends VisitSessionEvent {
  const FinishVisit({
    required this.finishLocation,
  });

  final VisitLocation finishLocation;

  @override
  List<Object?> get props => [finishLocation];
}

class CancelVisit extends VisitSessionEvent {
  const CancelVisit({required this.reason});
  final String reason;

  @override
  List<Object?> get props => [reason];
}
