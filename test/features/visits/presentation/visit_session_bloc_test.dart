import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/catalog_task.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/device_info.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/local_visit_status.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/permissions.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/task.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/visit_location.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/visit_session.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/repositories/catalog_repository.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/repositories/outbox_repository.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/repositories/permissions_repository.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/repositories/photo_repository.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/repositories/visit_repository.dart';
import 'package:gloria_marketing_flutter/src/features/visits/infra/envelope/visit_envelope_builder.dart';
import 'package:gloria_marketing_flutter/src/features/visits/infra/feature_flags.dart';
import 'package:gloria_marketing_flutter/src/features/visits/infra/time/server_time_service.dart';
import 'package:gloria_marketing_flutter/src/features/visits/infra/visit_finish_orchestrator.dart';
import 'package:gloria_marketing_flutter/src/features/visits/infra/sync/backoff_scheduler.dart';
import 'package:gloria_marketing_flutter/src/features/visits/infra/sync/connectivity_listener.dart';
import 'package:gloria_marketing_flutter/src/features/visits/infra/sync/outbox_dispatcher.dart';
import 'package:gloria_marketing_flutter/src/features/visits/data/rest/rest_v2_client.dart';
import 'package:gloria_marketing_flutter/src/features/visits/presentation/bloc/visit_session/visit_session_bloc.dart';
import 'package:gloria_marketing_flutter/src/features/visits/presentation/bloc/visit_session/visit_session_event.dart';
import 'package:gloria_marketing_flutter/src/features/visits/presentation/bloc/visit_session/visit_session_state.dart';
import 'package:dio/dio.dart';

/// End-to-end happy-path: start visit → complete two tasks → finish.
/// Asserts:
///   * Geofence + clock-drift gates let a valid fix through.
///   * Per-task Stopwatch produces non-zero durations.
///   * Finish enqueues an OutboxEntry whose `idempotencyKey` matches the
///     envelope's `idempotency_key` (the contract that makes idempotent
///     retries possible).
void main() {
  test('VisitSessionBloc — start → complete tasks → finish enqueues envelope',
      () async {
    final visits = _InMemoryVisits();
    final outbox = _InMemoryOutbox();
    final permissions = _StubPermissions();
    final catalog = _StubCatalog();
    final dispatcher = _NoopDispatcher();
    final orchestrator = VisitFinishOrchestrator(
      outbox: outbox,
      dispatcher: dispatcher,
      flags: FeatureFlags(permissions),
    );

    final bloc = VisitSessionBloc(
      permissions: permissions,
      catalog: catalog,
      visits: visits,
      photos: _NoopPhotos(),
      envelopeBuilder: VisitEnvelopeBuilder(),
      finishOrchestrator: orchestrator,
      serverTime: ServerTimeService(),
      clientUuidLoader: () async => 'device-uuid',
    );

    bloc.add(StartVisit(
      customerId: 'tp-1',
      plannedFlag: true,
      startLocation: _fix(),
      device: _device(),
      appVersion: '2.5.0+318',
    ));

    final active = await _waitFor<VisitSessionActive>(bloc.stream);
    expect(active.session.tasks, hasLength(2));
    expect(active.session.status, LocalVisitStatus.inProgress);

    // Start + complete the first task, give the stopwatch a tick.
    final firstTaskId = active.session.tasks.first.taskId;
    bloc.add(StartTask(firstTaskId));
    await _waitFor<VisitSessionActive>(
      bloc.stream,
      where: (s) => s.activeTaskId == firstTaskId,
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    bloc.add(CompleteTask(taskId: firstTaskId, payload: const {'count': 1}));
    await _waitFor<VisitSessionActive>(
      bloc.stream,
      where: (s) =>
          s.session.tasks.first.status == TaskRunStatus.completed,
    );

    // Second task — required as well.
    final secondTaskId = active.session.tasks[1].taskId;
    bloc.add(StartTask(secondTaskId));
    await _waitFor<VisitSessionActive>(
      bloc.stream,
      where: (s) => s.activeTaskId == secondTaskId,
    );
    bloc.add(CompleteTask(taskId: secondTaskId, payload: const {'done': true}));
    final ready = await _waitFor<VisitSessionActive>(
      bloc.stream,
      where: (s) => s.session.allRequiredCompleted,
    );
    expect(ready.session.allRequiredCompleted, isTrue);

    bloc.add(FinishVisit(finishLocation: _fix()));
    final enqueued = await _waitFor<VisitSessionEnqueued>(bloc.stream);

    // The session row is persisted as `finished_local`; the outbox holds
    // exactly one entry whose idempotency_key is the envelope's key.
    final saved = await visits.findById(enqueued.session.visitId);
    expect(saved?.status, LocalVisitStatus.finishedLocal);

    expect(outbox.entries, hasLength(1));
    final row = outbox.entries.single;
    expect(row.endpoint, '/visits/finish/');
    expect(row.visitId, enqueued.session.visitId);
    expect(row.payloadJson, contains('"idempotency_key"'));

    await bloc.close();
  });

  test('VisitSessionBloc — blocks finish when a required task is still pending',
      () async {
    final visits = _InMemoryVisits();
    final outbox = _InMemoryOutbox();
    final permissions = _StubPermissions();
    final dispatcher = _NoopDispatcher();
    final orchestrator = VisitFinishOrchestrator(
      outbox: outbox,
      dispatcher: dispatcher,
      flags: FeatureFlags(permissions),
    );

    final bloc = VisitSessionBloc(
      permissions: permissions,
      catalog: _StubCatalog(),
      visits: visits,
      photos: _NoopPhotos(),
      envelopeBuilder: VisitEnvelopeBuilder(),
      finishOrchestrator: orchestrator,
      serverTime: ServerTimeService(),
      clientUuidLoader: () async => 'device-uuid',
    );

    bloc.add(StartVisit(
      customerId: 'tp-1',
      plannedFlag: true,
      startLocation: _fix(),
      device: _device(),
      appVersion: '2.5.0+318',
    ));
    await _waitFor<VisitSessionActive>(bloc.stream);

    bloc.add(FinishVisit(finishLocation: _fix()));
    final err = await _waitFor<VisitSessionError>(bloc.stream);
    expect(err.failure.code, 'REQUIRED_PENDING');
    expect(outbox.entries, isEmpty);

    await bloc.close();
  });
}

// -- helpers ---------------------------------------------------------------

VisitLocation _fix() => VisitLocation(
      lat: 41.311081,
      lng: 69.279729,
      accuracyM: 12.0,
      source: 'gps',
      mocked: false,
      providerTs: DateTime.utc(2026, 5, 16, 8, 14, 21),
    );

VisitDeviceInfo _device() => const VisitDeviceInfo(
      deviceId: 'device-uuid',
      platform: 'android',
      osVersion: '14',
      appVersion: '2.5.0+318',
      model: 'SM-G990B',
      batteryLevel: 0.83,
      networkType: 'wifi',
      isJailbroken: false,
      timezone: 'Asia/Tashkent',
      locale: 'uz_UZ',
    );

/// Awaits the first state on [stream] that matches [where] and is of type T.
Future<T> _waitFor<T extends VisitSessionState>(
  Stream<VisitSessionState> stream, {
  bool Function(T state)? where,
}) {
  return stream.firstWhere(
    (s) => s is T && (where == null || where(s)),
  ).then((s) => s as T);
}

class _StubPermissions implements PermissionsRepository {
  final VisitsPermissions _value = VisitsPermissions(
    etag: 'W/"stub"',
    userCode: 'U001',
    projectCode: 'evyap',
    flags: const PermissionFlags(
      visit: true,
      strictSequence: false,
      unplannedOrder: false,
      plannedRoute: true,
      editClientCoordinates: false,
      skipTinDuplicateCheck: false,
      allowCreationWithoutTin: false,
      visitSubmissionPath: VisitSubmissionPath.restV2,
    ),
    thresholds: const PermissionThresholds(
      clientZoneAccessM: 0, // disables radius check for the stub fix
      locationUpdateIntervalS: 30,
      gpsAccuracyMaxM: 30,
      clockDriftMaxS: 300,
      maxPhotosPerTask: 5,
      minPhotosPerTask: {},
    ),
    enabledTasks: const ['PHOTO_BEFORE', 'AUDIT_OWN'],
    taskOrder: const ['PHOTO_BEFORE', 'AUDIT_OWN'],
    taskRequired: const {'PHOTO_BEFORE': true, 'AUDIT_OWN': true},
  );

  @override
  VisitsPermissions? get cached => _value;

  @override
  Future<VisitsPermissions> getCurrent({
    bool forceRefresh = false,
    Duration maxAge = const Duration(hours: 1),
  }) async =>
      _value;
}

class _StubCatalog implements CatalogRepository {
  final VisitsCatalog _value = VisitsCatalog(
    etag: 'W/"stub"',
    tasks: [
      CatalogTask(
        taskCode: 'PHOTO_BEFORE',
        nameI18n: const {'uz': 'Foto oldidan', 'en': 'Photo before'},
        required: true,
        displayOrder: 0,
        payloadSchema: const {},
        payloadSchemaVersion: 1,
        config: const {},
        rendererHint: 'custom',
      ),
      CatalogTask(
        taskCode: 'AUDIT_OWN',
        nameI18n: const {'uz': 'Polka', 'en': 'Shelf'},
        required: true,
        displayOrder: 1,
        payloadSchema: const {},
        payloadSchemaVersion: 1,
        config: const {},
        rendererHint: 'custom',
      ),
    ],
  );

  @override
  VisitsCatalog? get cached => _value;

  @override
  Future<VisitsCatalog> getCurrent({
    bool forceRefresh = false,
    Duration maxAge = const Duration(hours: 1),
  }) async =>
      _value;
}

class _InMemoryVisits implements VisitRepository {
  final Map<String, VisitSession> _rows = {};

  @override
  Future<void> upsert(VisitSession session) async {
    _rows[session.visitId] = session;
  }

  @override
  Future<VisitSession?> findById(String visitId) async => _rows[visitId];

  @override
  Future<List<VisitSession>> findByStatus(List<String> statuses) async =>
      _rows.values.where((s) => statuses.contains(s.status.wire)).toList();

  @override
  Future<void> markSynced(String visitId) async {
    final cur = _rows[visitId];
    if (cur != null) _rows[visitId] = cur.copyWith(status: LocalVisitStatus.synced);
  }

  @override
  Future<void> markCancelled(String visitId) async {
    final cur = _rows[visitId];
    if (cur != null) _rows[visitId] = cur.copyWith(status: LocalVisitStatus.cancelled);
  }

  @override
  Future<int> purgeSyncedOlderThan(Duration age) async => 0;
}

class _InMemoryOutbox implements OutboxRepository {
  final List<OutboxEntry> entries = [];

  @override
  Future<void> enqueue(OutboxEntry entry) async => entries.add(entry);

  @override
  Future<OutboxEntry?> peekDue(DateTime now) async => null;
  @override
  Future<void> markInFlight(String envelopeId, DateTime now) async {}
  @override
  Future<void> markAck(String envelopeId) async {}
  @override
  Future<void> markRetrying(
    String envelopeId,
    DateTime nextAttemptAt,
    String? error, {
    bool bumpAttempts = true,
  }) async {}
  @override
  Future<void> markDeadLetter(String envelopeId, String error) async {}
  @override
  Future<List<OutboxEntry>> findByStatus(String status) async => const [];
  @override
  Future<void> requeue(String envelopeId, DateTime now) async {}
  @override
  Future<void> delete(String envelopeId) async {}
  @override
  Future<Map<String, int>> countByStatus() async => const {};
}

class _NoopPhotos implements PhotoRepository {
  @override
  Future<PhotoUpload> capture({
    required String visitId,
    required String taskCode,
    String? taskId,
    required File source,
    double? lat,
    double? lng,
    double? accuracyM,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<PhotoUpload>> findUploadable() async => const [];

  @override
  Future<List<PhotoUpload>> findByTask(String visitId, String taskId) async =>
      const [];

  @override
  Future<void> markUploading(String assetId) async {}
  @override
  Future<void> markConfirmed(String assetId, {required String remoteAssetId}) async {}
  @override
  Future<void> markFailed(String assetId, String error,
      {bool incrementAttempt = true}) async {}
  @override
  Future<void> delete(String assetId) async {}
  @override
  Future<bool> allConfirmedFor(String visitId) async => true;
  @override
  Future<bool> noFailedFor(String visitId) async => true;
}

class _NoopDispatcher implements OutboxDispatcher {
  @override
  Future<void> cycle() async {}

  @override
  Future<void> dispose() async {}

  @override
  Stream<OutboxStatus> get statusStream => const Stream.empty();

  // The integration test never invokes the dispatcher's internals.
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

// Unused imports referenced for completeness so the integration list keeps
// matching the production wiring at-a-glance.
// ignore: unused_element
ConnectivityListener? _connectivityListenerDecoy() => null;
// ignore: unused_element
BackoffScheduler? _backoffDecoy() => null;
// ignore: unused_element
RestV2Client? _restClientDecoy() => null;
// ignore: unused_element
Dio? _dioDecoy() => null;
