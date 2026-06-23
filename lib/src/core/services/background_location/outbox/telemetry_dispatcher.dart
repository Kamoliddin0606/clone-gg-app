import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:gloria_marketing_flutter/src/core/services/background_location/outbox/telemetry_outbox_entry.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/outbox/telemetry_outbox_repository.dart';
import 'package:gloria_marketing_flutter/src/core/services/telemetry_v2/models/telemetry_accepted_response.dart';
import 'package:gloria_marketing_flutter/src/core/services/telemetry_v2/rest_logging.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/features/visits/infra/sync/backoff_scheduler.dart';
import 'package:gloria_marketing_flutter/src/features/visits/infra/sync/connectivity_listener.dart';

/// Drains the durable [TelemetryOutboxRepository] into the v2 telemetry batch
/// endpoint. Re-entrant safe within an isolate via the `_dispatching` latch;
/// safe across isolates (UI vs Workmanager) because each ping carries an
/// `idempotency_key` the server dedups on.
///
/// Modeled on the visits `OutboxDispatcher`
/// (`lib/src/features/visits/infra/sync/outbox_dispatcher.dart`) but:
///   * sends a **batch** (`{"pings": [...]}`) instead of one row per request;
///   * maps the server's per-ping `rejected[]` indices to `dead_letter`;
///   * NEVER dead-letters on auth failure — telemetry rows are preserved until
///     a valid token returns (a logged-out window must not lose the agent's
///     track). This is a deliberate divergence from the visits dispatcher,
///     which dead-letters on `auth_refresh_failed`.
class TelemetryDispatcher {
  TelemetryDispatcher({
    required TelemetryOutboxRepository outbox,
    required TokenService tokenService,
    required ConnectivityListener connectivity,
    required BackoffScheduler backoff,
    Dio? dio,
    String? baseUrl,
    String endpoint = '/api/mobile/v1/telemetry/pings/',
    int batchSize = 100,
    int retentionMaxRows = 20000,
  })  : _outbox = outbox,
        _tokenService = tokenService,
        _connectivity = connectivity,
        _backoff = backoff,
        _endpoint = endpoint,
        _baseUrl = baseUrl ?? TokenService.v2BaseUrl,
        _batchSize = batchSize,
        _retentionMaxRows = retentionMaxRows,
        _dio = dio ?? Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 12);
    _dio.options.sendTimeout = const Duration(seconds: 12);
    _dio.options.receiveTimeout = const Duration(seconds: 12);
    // Accept <500 so we can branch on the status code ourselves (200/201/409/
    // 401/4xx). Only 5xx / transport errors throw and fall to the catch block.
    _dio.options.validateStatus = (s) => s != null && s < 500;
    attachRestLogger(_dio, 'TELEMETRY-OUT');
  }

  final TelemetryOutboxRepository _outbox;
  final TokenService _tokenService;
  final ConnectivityListener _connectivity;
  final BackoffScheduler _backoff;
  final Dio _dio;
  final String _baseUrl;
  final String _endpoint;
  final int _batchSize;
  final int _retentionMaxRows;

  bool _dispatching = false;

  /// Drain the outbox until it is empty, offline, or blocked (auth/bad network).
  /// Fire-and-forget safe; concurrent calls in the same isolate no-op.
  Future<void> cycle() async {
    if (_dispatching) return;
    _dispatching = true;
    try {
      // Recover anything a previous killed cycle left reserved.
      await _outbox.requeueInFlight();

      if (!await _connectivity.isOnline) return;

      while (true) {
        final batch = await _outbox.peekDueBatch(DateTime.now(), _batchSize);
        if (batch.isEmpty) break;

        await _outbox.markInFlight(
          batch.map((e) => e.pingId).toList(growable: false),
          DateTime.now(),
        );

        final outcome = await _send(batch);
        final keepDraining = await _apply(batch, outcome);
        if (!keepDraining) break;
      }
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('TelemetryDispatcher: cycle error: $e\n$st');
      }
    } finally {
      _dispatching = false;
      // Best-effort retention sweep (terminal rows first, oldest unsent last).
      try {
        final dropped = await _outbox.pruneToCap(_retentionMaxRows);
        if (dropped > 0) {
          // Real data loss — make it auditable instead of silent.
          restLog('TELEMETRY-OUT',
              'retention: dropped $dropped UNSENT pings over cap $_retentionMaxRows');
        }
      } catch (_) {}
    }
  }

  Future<_BatchOutcome> _send(List<TelemetryOutboxEntry> batch) async {
    final token = await _tokenService.ensureValidV2Token();
    if (token == null || token.isEmpty) {
      return const _BatchOutcome(_OutcomeKind.authMissing);
    }

    final List<Map<String, dynamic>> pings;
    try {
      pings = batch
          .map((e) => jsonDecode(e.payloadJson) as Map<String, dynamic>)
          .toList(growable: false);
    } catch (e) {
      // A corrupt frozen payload can never be sent — terminal for this batch.
      return _BatchOutcome(_OutcomeKind.terminal, error: 'corrupt_payload: $e');
    }

    try {
      final response = await _dio.post(
        '$_baseUrl$_endpoint',
        data: <String, dynamic>{'pings': pings},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final status = response.statusCode ?? 0;
      if (status == 200 || status == 201) {
        final rejected = <int>{};
        if (response.data is Map) {
          final parsed = TelemetryAcceptedResponse.fromJson(
            Map<String, dynamic>.from(response.data as Map),
          );
          for (final r in parsed.rejected) {
            if (r.index >= 0 && r.index < batch.length) rejected.add(r.index);
          }
        }
        return _BatchOutcome(_OutcomeKind.accepted,
            httpStatus: status, rejectedIndices: rejected);
      }
      if (status == 409) {
        // Whole batch already accepted (dedup cache) — treat as success.
        return _BatchOutcome(_OutcomeKind.accepted,
            httpStatus: status, rejectedIndices: const <int>{});
      }
      if (status == 401) {
        return _BatchOutcome(_OutcomeKind.authExpired, httpStatus: status);
      }
      if (status == 429 || status >= 500) {
        return _BatchOutcome(_OutcomeKind.transient,
            httpStatus: status, error: 'http_$status');
      }
      // Other 4xx: a systemic/envelope reject. Terminal to avoid a poison-pill
      // that blocks the whole queue forever.
      return _BatchOutcome(_OutcomeKind.terminal,
          httpStatus: status, error: 'http_$status');
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401) {
        return _BatchOutcome(_OutcomeKind.authExpired, httpStatus: code);
      }
      if (code != null && code >= 400 && code < 500 && code != 429) {
        return _BatchOutcome(_OutcomeKind.terminal,
            httpStatus: code, error: 'http_$code');
      }
      // Timeout / connection error / 5xx / 429 → retry.
      return _BatchOutcome(_OutcomeKind.transient,
          httpStatus: code, error: 'dio_${e.type.name}');
    } catch (e) {
      return _BatchOutcome(_OutcomeKind.transient, error: e.toString());
    }
  }

  /// Returns `true` to keep draining, `false` to stop this cycle.
  Future<bool> _apply(
      List<TelemetryOutboxEntry> batch, _BatchOutcome outcome) async {
    switch (outcome.kind) {
      case _OutcomeKind.accepted:
        final acked = <String>[];
        final rejectedEntries = <TelemetryOutboxEntry>[];
        for (var i = 0; i < batch.length; i++) {
          if (outcome.rejectedIndices.contains(i)) {
            rejectedEntries.add(batch[i]);
          } else {
            acked.add(batch[i].pingId);
          }
        }
        await _outbox.ackAndRemove(acked);
        if (rejectedEntries.isNotEmpty) {
          await _outbox.markDeadLetter(
              rejectedEntries, 'server_rejected', httpStatus: outcome.httpStatus);
        }
        return true; // keep draining the rest of the queue

      case _OutcomeKind.transient:
        // Reschedule with backoff; dead-letter rows that exhausted attempts.
        final exhausted = <TelemetryOutboxEntry>[];
        final retry = <TelemetryOutboxEntry>[];
        for (final e in batch) {
          if (e.attempts + 1 >= e.maxAttempts) {
            exhausted.add(e);
          } else {
            retry.add(e);
          }
        }
        if (retry.isNotEmpty) {
          final maxAttempts =
              retry.map((e) => e.attempts).fold<int>(0, (a, b) => a > b ? a : b);
          final delay = _backoff.compute(maxAttempts + 1);
          await _outbox.markRetrying(
              retry, DateTime.now().add(delay), outcome.error);
        }
        if (exhausted.isNotEmpty) {
          await _outbox.markDeadLetter(exhausted, outcome.error ?? 'exhausted',
              httpStatus: outcome.httpStatus);
        }
        return false; // network is bad — stop until next trigger

      case _OutcomeKind.terminal:
        // Systemic reject for this batch — dead-letter it (auditable) and stop
        // so we don't mass-dead-letter the whole queue in one cycle.
        await _outbox.markDeadLetter(batch, outcome.error ?? 'terminal',
            httpStatus: outcome.httpStatus);
        return false;

      case _OutcomeKind.authMissing:
      case _OutcomeKind.authExpired:
        // Preserve data: release the reservation, do NOT bump attempts, do NOT
        // dead-letter. Rows wait for a valid token (re-login / refresh).
        await _outbox.markRetrying(batch, DateTime.now(), 'auth_unavailable',
            bumpAttempts: false);
        return false;
    }
  }

  Future<Map<String, int>> statusCounts() => _outbox.countByStatus();
}

enum _OutcomeKind { accepted, transient, terminal, authMissing, authExpired }

class _BatchOutcome {
  const _BatchOutcome(
    this.kind, {
    this.httpStatus,
    this.error,
    this.rejectedIndices = const <int>{},
  });

  final _OutcomeKind kind;
  final int? httpStatus;
  final String? error;
  final Set<int> rejectedIndices;
}
