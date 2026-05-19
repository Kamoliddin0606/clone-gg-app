import 'package:equatable/equatable.dart';

import '../../../domain/entities/visit_session.dart';
import '../../../domain/failures.dart';

sealed class VisitSessionState extends Equatable {
  const VisitSessionState();

  @override
  List<Object?> get props => [];
}

class VisitSessionInitial extends VisitSessionState {
  const VisitSessionInitial();
}

class VisitSessionLoading extends VisitSessionState {
  const VisitSessionLoading();
}

/// User is actively working on the visit. [activeTaskId] is `null` between
/// tasks (UI on the picker screen).
class VisitSessionActive extends VisitSessionState {
  const VisitSessionActive({
    required this.session,
    this.activeTaskId,
  });

  final VisitSession session;
  final String? activeTaskId;

  VisitSessionActive copyWith({VisitSession? session, String? activeTaskId}) =>
      VisitSessionActive(
        session: session ?? this.session,
        activeTaskId: activeTaskId ?? this.activeTaskId,
      );

  @override
  List<Object?> get props => [session, activeTaskId];
}

/// User tapped finish; envelope is being built / enqueued.
class VisitSessionFinishing extends VisitSessionState {
  const VisitSessionFinishing(this.session);
  final VisitSession session;

  @override
  List<Object?> get props => [session];
}

/// Envelope landed in the outbox (may still be `pending`/`retrying`). UI
/// can return the user to the list; the dispatcher cubit owns the badge.
class VisitSessionEnqueued extends VisitSessionState {
  const VisitSessionEnqueued(this.session);
  final VisitSession session;

  @override
  List<Object?> get props => [session];
}

/// Visit was cancelled by the user before finish.
class VisitSessionCancelled extends VisitSessionState {
  const VisitSessionCancelled(this.visitId);
  final String visitId;

  @override
  List<Object?> get props => [visitId];
}

class VisitSessionError extends VisitSessionState {
  const VisitSessionError(this.failure, {this.session});
  final Failure failure;
  final VisitSession? session;

  @override
  List<Object?> get props => [failure, session];
}
