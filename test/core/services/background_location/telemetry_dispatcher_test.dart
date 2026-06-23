import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gloria_marketing_flutter/src/core/database/migrations/v7_to_v8.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/outbox/telemetry_dispatcher.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/outbox/telemetry_outbox_data_source.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/outbox/telemetry_outbox_entry.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/outbox/telemetry_outbox_repository.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/features/visits/infra/sync/backoff_scheduler.dart';
import 'package:gloria_marketing_flutter/src/features/visits/infra/sync/connectivity_listener.dart';

/// Drives [TelemetryDispatcher] against a real sqflite (ffi) outbox and a fake
/// Dio adapter so the classification matrix (ack / per-ping reject / retry /
/// terminal / offline / auth-missing) is exercised end-to-end.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late TelemetryOutboxRepository repo;

  Future<void> seed(int n) async {
    final now = DateTime.now();
    for (var i = 0; i < n; i++) {
      await repo.enqueue(TelemetryOutboxEntry(
        pingId: 'p$i',
        payloadJson: '{"latitude":"41.$i","longitude":"69.$i"}',
        clientUuid: 'cu',
        idempotencyKey: 'p$i',
        status: TelemetryOutboxEntry.statusPending,
        attempts: 0,
        maxAttempts: 12,
        nextAttemptAt: now,
        loggedAt: now,
        createdAt: now.add(Duration(milliseconds: i)),
        updatedAt: now,
      ));
    }
  }

  TelemetryDispatcher makeDispatcher(
    _FakeAdapter adapter, {
    bool online = true,
    String? token = 'tok',
  }) {
    final dio = Dio()..httpClientAdapter = adapter;
    return TelemetryDispatcher(
      outbox: repo,
      tokenService: _FakeToken(token),
      connectivity: _FakeConn(online),
      backoff: BackoffScheduler(),
      dio: dio,
      baseUrl: 'https://test.local',
    );
  }

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await V7ToV8Migration.apply(db);
    repo = TelemetryOutboxRepositoryImpl(TelemetryOutboxDataSource(() async => db));
  });

  tearDown(() async => db.close());

  test('200 with all accepted → rows acked (removed)', () async {
    await seed(3);
    final adapter = _FakeAdapter(200, {'accepted_count': 3, 'rejected': []});
    await makeDispatcher(adapter).cycle();

    expect(await repo.count(), 0);
    expect(adapter.callCount, 1);
  });

  test('200 with rejected[index] → that row dead_letter, rest acked', () async {
    await seed(3);
    final adapter = _FakeAdapter(200, {
      'accepted_count': 2,
      'rejected': [
        {'index': 1, 'reason': 'bad_field'}
      ],
    });
    await makeDispatcher(adapter).cycle();

    final counts = await repo.countByStatus();
    expect(counts[TelemetryOutboxEntry.statusDeadLetter], 1);
    // The two accepted rows were removed; only the rejected one remains.
    expect(await repo.count(), 1);
  });

  test('503 → batch retried with backoff (not lost)', () async {
    await seed(2);
    final adapter = _FakeAdapter(503, {'error': 'boom'});
    await makeDispatcher(adapter).cycle();

    // Nothing dropped; rows rescheduled into the future with attempts bumped.
    expect(await repo.count(), 2);
    expect(await repo.peekDueBatch(DateTime.now(), 10), isEmpty);
    final later =
        await repo.peekDueBatch(DateTime.now().add(const Duration(minutes: 10)), 10);
    expect(later, hasLength(2));
    expect(later.first.attempts, 1);
  });

  test('400 (envelope reject) → dead_letter, no poison-pill loop', () async {
    await seed(2);
    final adapter = _FakeAdapter(400, {'error': 'bad'});
    await makeDispatcher(adapter).cycle();

    final counts = await repo.countByStatus();
    expect(counts[TelemetryOutboxEntry.statusDeadLetter], 2);
    expect(await repo.peekDueBatch(DateTime.now(), 10), isEmpty);
  });

  test('offline → nothing sent, rows preserved as pending', () async {
    await seed(2);
    final adapter = _FakeAdapter(200, {'accepted_count': 2, 'rejected': []});
    await makeDispatcher(adapter, online: false).cycle();

    expect(adapter.callCount, 0);
    expect(await repo.peekDueBatch(DateTime.now(), 10), hasLength(2));
  });

  test('missing token → rows preserved (NOT dead-lettered), no send', () async {
    await seed(2);
    final adapter = _FakeAdapter(200, {'accepted_count': 2, 'rejected': []});
    await makeDispatcher(adapter, token: null).cycle();

    expect(adapter.callCount, 0);
    final counts = await repo.countByStatus();
    expect(counts[TelemetryOutboxEntry.statusDeadLetter] ?? 0, 0);
    // Still recoverable on the next cycle (pending/retrying, due now).
    expect(await repo.peekDueBatch(DateTime.now(), 10), hasLength(2));
  });
}

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeToken extends Fake implements TokenService {
  _FakeToken(this._token);
  final String? _token;

  @override
  Future<String?> ensureValidV2Token({String? login, String? password}) async =>
      _token;
}

class _FakeConn extends ConnectivityListener {
  _FakeConn(this._online);
  final bool _online;

  @override
  Future<bool> get isOnline async => _online;

  @override
  Stream<bool> watch() => Stream<bool>.value(_online);
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.status, this.body);
  final int status;
  final Map<String, dynamic> body;
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
