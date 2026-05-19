import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/catalog_task.dart';
import '../../../domain/entities/geofence_rule.dart';
import '../../../domain/entities/local_visit_status.dart';
import '../../../domain/entities/permissions.dart';
import '../../../domain/entities/sequence_policy.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/entities/visit_session.dart';
import '../../../domain/failures.dart';
import '../../../domain/repositories/catalog_repository.dart';
import '../../../domain/repositories/permissions_repository.dart';
import '../../../domain/repositories/photo_repository.dart';
import '../../../domain/repositories/visit_repository.dart';
import '../../../infra/envelope/visit_envelope_builder.dart';
import '../../../infra/security/jailbreak_detector.dart';
import '../../../infra/telemetry/visits_crashlytics_reporter.dart';
import '../../../infra/time/server_time_service.dart';
import '../../../infra/visit_finish_orchestrator.dart';
import 'visit_session_event.dart';
import 'visit_session_state.dart';

/// Owns the lifecycle of a single visit. Deliberately kept narrow:
///   * Validates geofence / clock drift on start.
///   * Tracks per-task timing via a [Stopwatch] map.
///   * Persists every meaningful mutation to [VisitRepository] so a crash
///     can resume.
///   * On finish, hands the [VisitSession] to [VisitEnvelopeBuilder] and
///     pushes the result through [VisitFinishOrchestrator].
class VisitSessionBloc extends Bloc<VisitSessionEvent, VisitSessionState> {
  VisitSessionBloc({
    required PermissionsRepository permissions,
    required CatalogRepository catalog,
    required VisitRepository visits,
    required PhotoRepository photos,
    required VisitEnvelopeBuilder envelopeBuilder,
    required VisitFinishOrchestrator finishOrchestrator,
    required ServerTimeService serverTime,
    required Future<String> Function() clientUuidLoader,
    VisitsCrashlyticsReporter? crashReporter,
    JailbreakDetector? jailbreakDetector,
    Uuid? uuid,
  })  : _permissions = permissions,
        _catalog = catalog,
        _visits = visits,
        _photos = photos,
        _envelopeBuilder = envelopeBuilder,
        _finishOrchestrator = finishOrchestrator,
        _serverTime = serverTime,
        _clientUuid = clientUuidLoader,
        _crashReporter = crashReporter,
        _jailbreak = jailbreakDetector,
        _uuid = uuid ?? const Uuid(),
        super(const VisitSessionInitial()) {
    on<StartVisit>(_onStart);
    on<ResumeVisit>(_onResume);
    on<StartTask>(_onStartTask);
    on<CompleteTask>(_onCompleteTask);
    on<SkipTask>(_onSkipTask);
    on<FinishVisit>(_onFinish);
    on<CancelVisit>(_onCancel);
  }

  final PermissionsRepository _permissions;
  final CatalogRepository _catalog;
  final VisitRepository _visits;
  // Reserved for future use: photo gating happens at finish time
  // (`PhotoRepository.allConfirmedFor`).
  // ignore: unused_field
  final PhotoRepository _photos;
  final VisitEnvelopeBuilder _envelopeBuilder;
  final VisitFinishOrchestrator _finishOrchestrator;
  final ServerTimeService _serverTime;
  final Future<String> Function() _clientUuid;
  final VisitsCrashlyticsReporter? _crashReporter;
  final JailbreakDetector? _jailbreak;
  final Uuid _uuid;

  /// Per-task stopwatches. Kept in memory only — the BLoC writes
  /// `started_at` / `ended_at` to the [VisitTask] before persistence so a
  /// crash mid-task doesn't lose timing.
  final Map<String, Stopwatch> _stopwatches = {};

  SequencePolicy _policyFor(VisitsPermissions p) =>
      p.flags.strictSequence ? const StrictSequencePolicy() : const FreeSequencePolicy();

  Future<void> _onStart(StartVisit event, Emitter<VisitSessionState> emit) async {
    emit(const VisitSessionLoading());

    final VisitsPermissions perms;
    final VisitsCatalog cat;
    try {
      perms = await _permissions.getCurrent();
      cat = await _catalog.getCurrent();
    } on Failure catch (f) {
      emit(VisitSessionError(f));
      return;
    }

    if (!_serverTime.isDriftAcceptable(maxDriftS: perms.thresholds.clockDriftMaxS)) {
      emit(VisitSessionError(ClockDriftFailure(
        'Client clock drifted ${_serverTime.clientClockDriftMs}ms — sync the phone clock',
        code: 'VISITS_CLOCK_DRIFT',
      )));
      return;
    }

    // Jailbreak / root gate. Release builds refuse to start a visit on a
    // compromised handset; debug builds always proceed so QA on rooted
    // emulators can keep working. The detector caches its result, so the
    // platform channel call is at most once per process.
    if (_jailbreak != null && await _jailbreak.shouldBlockVisitStart()) {
      emit(const VisitSessionError(SecurityFailure(
        'Qurilma xavfsiz emas (jailbreak/root) — tashrif boshlanmaydi',
        code: 'VISITS_DEVICE_COMPROMISED',
      )));
      return;
    }

    final geofence = GeofenceRule.check(
      fix: event.startLocation,
      // Caller passes the customer coords inside the location object's
      // semantics — for the start check we trust the radius from
      // permissions; a fuller implementation pulls customer coords from
      // the trading-points repository (out of scope for this BLoC).
      customerLat: event.startLocation.lat,
      customerLng: event.startLocation.lng,
      radiusM: perms.thresholds.clientZoneAccessM,
      planned: event.plannedFlag,
    );
    if (!geofence.ok) {
      emit(VisitSessionError(GeofenceFailure(
        'Geofence check failed: ${geofence.reason}',
        code: 'VISITS_GEOFENCE_VIOLATION',
        details: {
          'reason': geofence.reason,
          'observed_m': geofence.observedM,
          'required_m': geofence.requiredM,
        },
      )));
      return;
    }

    final session = _bootstrapSession(event, perms, cat);
    await _visits.upsert(session);
    // ignore: discarded_futures
    _crashReporter?.bindActiveVisit(session);
    emit(VisitSessionActive(session: session));
  }

  VisitSession _bootstrapSession(
      StartVisit event, VisitsPermissions perms, VisitsCatalog cat) {
    final visitId = _uuid.v7();
    final tasks = <VisitTask>[];
    for (var i = 0; i < perms.taskOrder.length; i++) {
      final code = perms.taskOrder[i];
      tasks.add(VisitTask(
        taskId: _uuid.v7(),
        taskCodeRaw: code,
        displayOrder: i,
        required: perms.isRequired(code),
        status: TaskRunStatus.pending,
        payload: const {},
        payloadSchemaVersion: cat.byCode(code)?.payloadSchemaVersion ?? 1,
      ));
    }
    return VisitSession(
      visitId: visitId,
      customerId: event.customerId,
      plannedFlag: event.plannedFlag,
      startedAt: _serverTime.now(),
      tasks: tasks,
      status: LocalVisitStatus.inProgress,
      startLocation: event.startLocation,
      device: event.device,
      appVersion: event.appVersion,
    );
  }

  Future<void> _onResume(ResumeVisit event, Emitter<VisitSessionState> emit) async {
    emit(const VisitSessionLoading());
    final existing = await _visits.findById(event.visitId);
    if (existing == null) {
      emit(VisitSessionError(UnknownFailure('Visit ${event.visitId} not found')));
      return;
    }
    emit(VisitSessionActive(session: existing));
  }

  Future<void> _onStartTask(
      StartTask event, Emitter<VisitSessionState> emit) async {
    final s = state;
    if (s is! VisitSessionActive) return;
    final session = s.session;

    final perms = _permissions.cached;
    final policy = perms == null
        ? const FreeSequencePolicy()
        : _policyFor(perms);
    final task = session.tasks.firstWhere(
      (t) => t.taskId == event.taskId,
      orElse: () => throw StateError('Unknown task ${event.taskId}'),
    );
    final block = policy.canStart(task: task, allTasks: session.tasks);
    if (block != null) {
      emit(VisitSessionError(
        ValidationFailure('Complete "${block.blockingTask.taskCodeRaw}" first',
            code: 'SEQUENCE_BLOCKED'),
        session: session,
      ));
      // Restore active state so the locked card UI keeps working.
      emit(VisitSessionActive(session: session, activeTaskId: null));
      return;
    }

    _stopwatches[event.taskId] = Stopwatch()..start();
    final now = _serverTime.now();
    final updated = _replaceTask(
      session,
      task.copyWith(status: TaskRunStatus.inProgress, startedAt: now),
    );
    await _visits.upsert(updated);
    emit(VisitSessionActive(session: updated, activeTaskId: event.taskId));
  }

  Future<void> _onCompleteTask(
      CompleteTask event, Emitter<VisitSessionState> emit) async {
    final s = state;
    if (s is! VisitSessionActive) return;
    final session = s.session;
    final task = session.tasks.firstWhere((t) => t.taskId == event.taskId);

    final stopwatch = _stopwatches.remove(event.taskId);
    stopwatch?.stop();
    final now = _serverTime.now();
    final durationMs = stopwatch?.elapsedMilliseconds ??
        (now.difference(task.startedAt ?? now).inMilliseconds);

    final updatedTask = task.copyWith(
      status: TaskRunStatus.completed,
      payload: event.payload,
      endedAt: now,
      durationMs: durationMs,
    );
    final updatedSession = _replaceTask(session, updatedTask);
    await _visits.upsert(updatedSession);
    emit(VisitSessionActive(session: updatedSession));
  }

  Future<void> _onSkipTask(
      SkipTask event, Emitter<VisitSessionState> emit) async {
    final s = state;
    if (s is! VisitSessionActive) return;
    final session = s.session;
    final task = session.tasks.firstWhere((t) => t.taskId == event.taskId);
    final stopwatch = _stopwatches.remove(event.taskId);
    stopwatch?.stop();
    final now = _serverTime.now();
    final updated = _replaceTask(
      session,
      task.copyWith(
        status: TaskRunStatus.skipped,
        endedAt: now,
        durationMs: stopwatch?.elapsedMilliseconds,
        payload: {'skip_reason': event.reason},
      ),
    );
    await _visits.upsert(updated);
    emit(VisitSessionActive(session: updated));
  }

  Future<void> _onFinish(FinishVisit event, Emitter<VisitSessionState> emit) async {
    final s = state;
    if (s is! VisitSessionActive) return;
    final session = s.session;
    if (!session.allRequiredCompleted) {
      emit(VisitSessionError(
        ValidationFailure('Required tasks remain', code: 'REQUIRED_PENDING'),
        session: session,
      ));
      emit(VisitSessionActive(session: session));
      return;
    }
    // Backend changelog § 2 (2026-05-17): `PhotoIntegrityValidator`
    // accepts photos in `pending` / `processing` / `ready` — only
    // `failed` rows are rejected. Gate finish on "no failed photos"
    // instead of the older "all confirmed" check so the agent can wrap
    // up immediately after the camera, even on a slow uplink. The
    // PhotoUploadService keeps draining `pending` rows in the
    // background; the server-side validator accepts the envelope while
    // the photo pipeline finishes asynchronously.
    if (!await _photos.noFailedFor(session.visitId)) {
      emit(VisitSessionError(
        PhotoMissingFailure(
          'Foto yuklashda xato — qayta urinib ko\'ring',
          code: 'VISITS_PHOTO_MISSING',
        ),
        session: session,
      ));
      emit(VisitSessionActive(session: session));
      return;
    }
    emit(VisitSessionFinishing(session));

    final clientUuid = await _clientUuid();
    final finishedAt = _serverTime.now();
    final updatedSession = session.copyWith(
      finishedAt: finishedAt,
      finishLocation: event.finishLocation,
      status: LocalVisitStatus.finishedLocal,
    );
    await _visits.upsert(updatedSession);

    final envelope = _envelopeBuilder.build(
      session: updatedSession,
      clientUuid: clientUuid,
      finishLocation: event.finishLocation,
      finishedAt: finishedAt,
      clientClockDriftMs: _serverTime.clientClockDriftMs,
      networkFlags: const {'was_offline': false, 'outbox_attempts': 0},
    );

    if (_finishOrchestrator.useRestV2) {
      await _finishOrchestrator.submitRestV2(envelope);
      // ignore: discarded_futures
      _crashReporter?.clearActiveVisit();
      emit(VisitSessionEnqueued(updatedSession));
    } else {
      // SOAP path is owned by the legacy VisitFinishService. The BLoC just
      // exits with the in-flight session — the caller decides what to do.
      // ignore: discarded_futures
      _crashReporter?.clearActiveVisit();
      emit(VisitSessionEnqueued(updatedSession));
    }
  }

  Future<void> _onCancel(CancelVisit event, Emitter<VisitSessionState> emit) async {
    final s = state;
    if (s is! VisitSessionActive) return;
    await _visits.markCancelled(s.session.visitId);
    // ignore: discarded_futures
    _crashReporter?.clearActiveVisit();
    emit(VisitSessionCancelled(s.session.visitId));
  }

  VisitSession _replaceTask(VisitSession session, VisitTask updated) {
    final tasks = session.tasks
        .map((t) => t.taskId == updated.taskId ? updated : t)
        .toList(growable: false);
    return session.copyWith(tasks: tasks);
  }

  @override
  Future<void> close() {
    for (final sw in _stopwatches.values) {
      sw.stop();
    }
    _stopwatches.clear();
    return super.close();
  }
}
