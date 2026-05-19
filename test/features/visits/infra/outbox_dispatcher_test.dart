import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/visits/data/rest/interceptors/error_mapper_interceptor.dart';
import 'package:gloria_marketing_flutter/src/features/visits/data/rest/rest_v2_client.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/visit_session.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/repositories/outbox_repository.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/repositories/visit_repository.dart';
import 'package:gloria_marketing_flutter/src/features/visits/infra/sync/backoff_scheduler.dart';
import 'package:gloria_marketing_flutter/src/features/visits/infra/sync/connectivity_listener.dart';
import 'package:gloria_marketing_flutter/src/features/visits/infra/sync/outbox_dispatcher.dart';

/// Drives the dispatcher against in-memory fakes so the classification
/// matrix (ack / retry / dead-letter / auth-refresh / no-network) gets
/// exercised end-to-end without Dio touching a real socket.
void main() {
  group('OutboxDispatcher', () {
    test('acks a 200 response and marks the visit synced', () async {
      final outbox = _FakeOutbox()
        ..enqueueOne(_entry('env-1', visitId: 'visit-1'));
      final visits = _FakeVisits();
      final client = _stubClient(handler: (_) => _ok(200, body: {'ok': true}));

      final dispatcher = OutboxDispatcher(
        outbox: outbox,
        visits: visits,
        client: client,
        connectivity: _AlwaysOnline(),
        backoff: BackoffScheduler(),
      );

      await dispatcher.cycle();

      expect(outbox.statusOf('env-1'), 'ack');
      expect(visits.syncedIds, contains('visit-1'));
      await dispatcher.dispose();
    });

    test('treats 409 as already-accepted and acks without retry', () async {
      final outbox = _FakeOutbox()
        ..enqueueOne(_entry('env-2', visitId: 'visit-2'));
      final visits = _FakeVisits();
      final client = _stubClient(
        handler: (_) => _ok(409, body: {
          'error': {
            'code': 'VISITS_DUPLICATE',
            'message': 'already accepted',
          }
        }),
      );

      final dispatcher = OutboxDispatcher(
        outbox: outbox,
        visits: visits,
        client: client,
        connectivity: _AlwaysOnline(),
        backoff: BackoffScheduler(),
      );

      await dispatcher.cycle();

      expect(outbox.statusOf('env-2'), 'ack');
      expect(outbox.attemptsOf('env-2'), 0);
      expect(visits.syncedIds, contains('visit-2'));
      await dispatcher.dispose();
    });

    test('reschedules a transient 503 with backoff and does not exhaust',
        () async {
      final outbox = _FakeOutbox()..enqueueOne(_entry('env-3'));
      final client = _stubClient(handler: (_) => _ok(503, body: {}));

      final dispatcher = OutboxDispatcher(
        outbox: outbox,
        visits: _FakeVisits(),
        client: client,
        connectivity: _AlwaysOnline(),
        backoff: BackoffScheduler(),
      );

      await dispatcher.cycle();

      expect(outbox.statusOf('env-3'), 'retrying');
      expect(outbox.attemptsOf('env-3'), 1);
      expect(outbox.lastErrorOf('env-3'), contains('503'));
      await dispatcher.dispose();
    });

    test('dead-letters a 422 immediately', () async {
      final outbox = _FakeOutbox()..enqueueOne(_entry('env-4'));
      final client = _stubClient(
        handler: (_) => _ok(422, body: {
          'error': {
            'code': 'VISITS_GEOFENCE_VIOLATION',
            'message': 'out of zone',
          }
        }),
      );

      final dispatcher = OutboxDispatcher(
        outbox: outbox,
        visits: _FakeVisits(),
        client: client,
        connectivity: _AlwaysOnline(),
        backoff: BackoffScheduler(),
      );

      await dispatcher.cycle();

      expect(outbox.statusOf('env-4'), 'dead_letter');
      await dispatcher.dispose();
    });

    test('401 triggers refresh callback and reschedules without attempt bump',
        () async {
      final outbox = _FakeOutbox()..enqueueOne(_entry('env-5'));
      final client = _stubClient(handler: (_) => _ok(401, body: {}));
      var refreshes = 0;

      final dispatcher = OutboxDispatcher(
        outbox: outbox,
        visits: _FakeVisits(),
        client: client,
        connectivity: _AlwaysOnline(),
        backoff: BackoffScheduler(),
        authRefresh: () async {
          refreshes++;
          return true;
        },
      );

      await dispatcher.cycle();

      expect(refreshes, 1);
      expect(outbox.statusOf('env-5'), 'retrying');
      expect(outbox.attemptsOf('env-5'), 0);
      await dispatcher.dispose();
    });

    test('skips when offline and leaves entry pending', () async {
      final outbox = _FakeOutbox()..enqueueOne(_entry('env-6'));
      final client = _stubClient(handler: (_) => _ok(200, body: {}));

      final dispatcher = OutboxDispatcher(
        outbox: outbox,
        visits: _FakeVisits(),
        client: client,
        connectivity: _AlwaysOffline(),
        backoff: BackoffScheduler(),
      );

      await dispatcher.cycle();

      expect(outbox.statusOf('env-6'), 'pending');
      expect(outbox.attemptsOf('env-6'), 0);
      await dispatcher.dispose();
    });

    test('exhausts max attempts → dead_letter', () async {
      final outbox = _FakeOutbox()
        ..enqueueOne(_entry('env-7', attempts: 9, maxAttempts: 10));
      final client = _stubClient(handler: (_) => _ok(503, body: {}));

      final dispatcher = OutboxDispatcher(
        outbox: outbox,
        visits: _FakeVisits(),
        client: client,
        connectivity: _AlwaysOnline(),
        backoff: BackoffScheduler(),
      );

      await dispatcher.cycle();

      expect(outbox.statusOf('env-7'), 'dead_letter');
      await dispatcher.dispose();
    });

    test(
        'idempotent 200 replay (backend changelog § 5) acks as cleanly as 201',
        () async {
      // Backend's "two parallel finish" guarantee: when the network
      // retries an envelope mid-flight, the second POST gets 200
      // (replay) with the same visit id. The dispatcher must treat
      // 200 exactly like 201 — both are success.
      final outbox = _FakeOutbox()
        ..enqueueOne(_entry('env-replay', visitId: 'visit-replay'));
      final visits = _FakeVisits();
      final client = _stubClient(
        handler: (_) => _ok(200, body: {
          'id': 'visit-replay',
          'status': 'submitted',
        }),
      );

      final dispatcher = OutboxDispatcher(
        outbox: outbox,
        visits: visits,
        client: client,
        connectivity: _AlwaysOnline(),
        backoff: BackoffScheduler(),
      );

      await dispatcher.cycle();

      expect(outbox.statusOf('env-replay'), 'ack');
      expect(outbox.attemptsOf('env-replay'), 0);
      expect(visits.syncedIds, contains('visit-replay'));
      await dispatcher.dispose();
    });

    test('two parallel cycles on the same outbox process the row exactly once',
        () async {
      // Workmanager (background) + foreground coordinator can both
      // tick at the same moment. The dispatcher's `_dispatching`
      // re-entrance latch must keep them from racing and double-
      // submitting the same envelope — which would burn a no-op
      // network round-trip and (on legacy backends) risk a duplicate.
      final outbox = _FakeOutbox()
        ..enqueueOne(_entry('env-race', visitId: 'visit-race'));
      var sendCount = 0;
      final client = _stubClient(handler: (_) {
        sendCount++;
        return _ok(201, body: {'id': 'visit-race'});
      });

      final dispatcher = OutboxDispatcher(
        outbox: outbox,
        visits: _FakeVisits(),
        client: client,
        connectivity: _AlwaysOnline(),
        backoff: BackoffScheduler(),
      );

      // Fire both cycles without awaiting individually — the second
      // one observes `_dispatching=true` and bails.
      await Future.wait([dispatcher.cycle(), dispatcher.cycle()]);

      expect(sendCount, 1);
      expect(outbox.statusOf('env-race'), 'ack');
      await dispatcher.dispose();
    });
  });
}

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

OutboxEntry _entry(
  String id, {
  String? visitId,
  int attempts = 0,
  int maxAttempts = 10,
}) {
  final now = DateTime(2026, 5, 16);
  return OutboxEntry(
    envelopeId: id,
    visitId: visitId,
    endpoint: '/visits/finish/',
    httpMethod: 'POST',
    payloadJson: '{}',
    idempotencyKey: 'idem-$id',
    clientUuid: 'cli-$id',
    status: 'pending',
    attempts: attempts,
    maxAttempts: maxAttempts,
    nextAttemptAt: now,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeOutbox implements OutboxRepository {
  final Map<String, OutboxEntry> _rows = {};

  void enqueueOne(OutboxEntry e) => _rows[e.envelopeId] = e;

  String statusOf(String id) => _rows[id]!.status;
  int attemptsOf(String id) => _rows[id]!.attempts;
  String? lastErrorOf(String id) => _rows[id]!.lastError;

  @override
  Future<void> enqueue(OutboxEntry entry) async {
    _rows[entry.envelopeId] = entry;
  }

  @override
  Future<OutboxEntry?> peekDue(DateTime now) async {
    for (final e in _rows.values) {
      if (e.status == 'pending' || e.status == 'retrying') {
        if (!e.nextAttemptAt.isAfter(now)) return e;
      }
    }
    return null;
  }

  @override
  Future<void> markInFlight(String envelopeId, DateTime now) async {
    _rows[envelopeId] = _clone(_rows[envelopeId]!, status: 'in_flight');
  }

  @override
  Future<void> markAck(String envelopeId) async {
    _rows[envelopeId] = _clone(_rows[envelopeId]!, status: 'ack');
  }

  @override
  Future<void> markRetrying(
    String envelopeId,
    DateTime nextAttemptAt,
    String? error, {
    bool bumpAttempts = true,
  }) async {
    final cur = _rows[envelopeId]!;
    _rows[envelopeId] = _clone(
      cur,
      status: 'retrying',
      attempts: bumpAttempts ? cur.attempts + 1 : cur.attempts,
      nextAttemptAt: nextAttemptAt,
      lastError: error,
    );
  }

  @override
  Future<void> markDeadLetter(String envelopeId, String error) async {
    _rows[envelopeId] = _clone(
      _rows[envelopeId]!,
      status: 'dead_letter',
      lastError: error,
    );
  }

  @override
  Future<List<OutboxEntry>> findByStatus(String status) async =>
      _rows.values.where((e) => e.status == status).toList();

  @override
  Future<void> requeue(String envelopeId, DateTime now) async {
    _rows[envelopeId] = _clone(
      _rows[envelopeId]!,
      status: 'pending',
      attempts: 0,
      nextAttemptAt: now,
      lastError: null,
    );
  }

  @override
  Future<void> delete(String envelopeId) async {
    _rows.remove(envelopeId);
  }

  @override
  Future<Map<String, int>> countByStatus() async {
    final result = <String, int>{};
    for (final e in _rows.values) {
      result[e.status] = (result[e.status] ?? 0) + 1;
    }
    return result;
  }

  OutboxEntry _clone(
    OutboxEntry e, {
    String? status,
    int? attempts,
    DateTime? nextAttemptAt,
    String? lastError,
  }) =>
      OutboxEntry(
        envelopeId: e.envelopeId,
        visitId: e.visitId,
        endpoint: e.endpoint,
        httpMethod: e.httpMethod,
        payloadJson: e.payloadJson,
        idempotencyKey: e.idempotencyKey,
        clientUuid: e.clientUuid,
        status: status ?? e.status,
        attempts: attempts ?? e.attempts,
        maxAttempts: e.maxAttempts,
        nextAttemptAt: nextAttemptAt ?? e.nextAttemptAt,
        lastError: lastError ?? e.lastError,
        lastHttpStatus: e.lastHttpStatus,
        createdAt: e.createdAt,
        updatedAt: DateTime.now(),
      );
}

class _FakeVisits implements VisitRepository {
  final List<String> syncedIds = [];
  @override
  Future<void> upsert(VisitSession session) async {}
  @override
  Future<VisitSession?> findById(String visitId) async => null;
  @override
  Future<List<VisitSession>> findByStatus(List<String> statuses) async =>
      const [];
  @override
  Future<void> markSynced(String visitId) async => syncedIds.add(visitId);
  @override
  Future<void> markCancelled(String visitId) async {}
  @override
  Future<int> purgeSyncedOlderThan(Duration age) async => 0;
}

class _AlwaysOnline extends ConnectivityListener {
  _AlwaysOnline() : super();
  @override
  Future<bool> get isOnline async => true;
  @override
  Stream<bool> watch() => const Stream.empty();
}

class _AlwaysOffline extends ConnectivityListener {
  _AlwaysOffline() : super();
  @override
  Future<bool> get isOnline async => false;
  @override
  Stream<bool> watch() => const Stream.empty();
}

// ---------------------------------------------------------------------------
// Dio stub
// ---------------------------------------------------------------------------

typedef _Handler = Response<dynamic> Function(RequestOptions options);

RestV2Client _stubClient({required _Handler handler}) {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://example.test/api/mobile/v2',
    validateStatus: (s) => s != null && s < 600,
  ));
  dio.interceptors.addAll([
    ErrorMapperInterceptor(),
    _CapturingInterceptor(handler),
  ]);
  return RestV2Client.testHook(dio);
}


class _CapturingInterceptor extends Interceptor {
  _CapturingInterceptor(this._handler);
  final _Handler _handler;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final response = _handler(options);
    response.requestOptions = options;
    // Always resolve; Dio's `validateStatus` (set to `< 600` on the test
    // client) lets the dispatcher branch on the real status code rather
    // than the interceptor framework deciding what's an error.
    handler.resolve(response);
  }
}

Response<dynamic> _ok(int code, {required dynamic body}) => Response(
      requestOptions: RequestOptions(path: ''),
      statusCode: code,
      data: body,
    );
