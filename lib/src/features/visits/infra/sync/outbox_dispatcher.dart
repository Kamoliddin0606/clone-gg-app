import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../data/rest/rest_v2_client.dart';
import '../../domain/failures.dart';
import '../../domain/repositories/outbox_repository.dart';
import '../../domain/repositories/visit_repository.dart';
import 'backoff_scheduler.dart';
import 'connectivity_listener.dart';
import 'outbox_dispatch_result.dart';

/// Drains the local outbox into the v2 backend.
///
/// Triggered from multiple places (app start, app foreground, connectivity
/// flip, periodic timer, Workmanager, manual retry). All triggers funnel
/// into [cycle], which is re-entrant safe via the `_dispatching` latch.
class OutboxDispatcher {
  OutboxDispatcher({
    required OutboxRepository outbox,
    required VisitRepository visits,
    required RestV2Client client,
    required ConnectivityListener connectivity,
    required BackoffScheduler backoff,
    Future<bool> Function()? authRefresh,
  })  : _outbox = outbox,
        _visits = visits,
        _client = client,
        _connectivity = connectivity,
        _backoff = backoff,
        _authRefresh = authRefresh;

  final OutboxRepository _outbox;
  final VisitRepository _visits;
  final RestV2Client _client;
  final ConnectivityListener _connectivity;
  final BackoffScheduler _backoff;

  /// Optional callback the dispatcher invokes on 401. Returning `true` means
  /// the token was refreshed and the entry should be retried immediately.
  final Future<bool> Function()? _authRefresh;

  bool _dispatching = false;

  Stream<OutboxStatus> get statusStream => _statusController.stream;
  final _statusController = StreamController<OutboxStatus>.broadcast();

  Future<void> cycle() async {
    if (_dispatching) return;
    _dispatching = true;
    try {
      if (!await _connectivity.isOnline) return;

      while (true) {
        final entry = await _outbox.peekDue(DateTime.now());
        if (entry == null) break;

        if (entry.attempts >= entry.maxAttempts) {
          await _outbox.markDeadLetter(
              entry.envelopeId, 'max_attempts_exhausted');
          _emit(OutboxStatus.deadLettered(entry.envelopeId));
          continue;
        }

        await _outbox.markInFlight(entry.envelopeId, DateTime.now());
        _emit(OutboxStatus.sending(entry.envelopeId, entry.attempts));

        final outcome = await _send(entry);
        await _apply(entry, outcome);
      }
    } finally {
      _dispatching = false;
    }
  }

  Future<DispatchOutcome> _send(OutboxEntry entry) async {
    try {
      final response = await _client.dio.request<dynamic>(
        entry.endpoint,
        data: jsonDecode(entry.payloadJson),
        options: Options(
          method: entry.httpMethod,
        ),
      );
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        // Backend echoes `Idempotent-Replay: true` (changelog § 6) on a
        // 200 caused by a duplicate POST hitting the dedup cache.
        // Surface it so the cubit's analytics breadcrumb separates
        // "fresh write" from "network retry".
        final replay = response.headers
                .value('idempotent-replay')
                ?.trim()
                .toLowerCase() ==
            'true';
        return DispatchSuccess(httpStatus: status, idempotentReplay: replay);
      }
      if (status == 409) {
        return const DispatchAlreadyAccepted();
      }
      if (status == 401) {
        return const DispatchAuthExpired();
      }
      if (status >= 500 || status == 429) {
        return DispatchTransient(
          error: 'http_$status',
          httpStatus: status,
        );
      }
      return DispatchTerminal(
        error: 'http_$status',
        httpStatus: status,
      );
    } on DioException catch (e) {
      final mapped = e.error;
      if (mapped is NetworkFailure) {
        return DispatchTransient(
          error: mapped.message,
          httpStatus: e.response?.statusCode,
        );
      }
      if (mapped is AuthFailure && e.response?.statusCode == 401) {
        return const DispatchAuthExpired();
      }
      if (mapped is Failure) {
        return DispatchTerminal(
          error: mapped.message,
          httpStatus: e.response?.statusCode,
          code: mapped.code,
        );
      }
      // Should not happen — ErrorMapperInterceptor always attaches a Failure.
      developer.log(
        'Outbox dispatch: unmapped Dio error ${e.type}',
        name: 'outbox',
        error: e,
      );
      return DispatchTransient(
        error: e.message ?? 'unknown_dio_error',
        httpStatus: e.response?.statusCode,
      );
    } catch (e, st) {
      developer.log('Outbox dispatch: unexpected error',
          name: 'outbox', error: e, stackTrace: st);
      return DispatchTransient(error: e.toString());
    }
  }

  Future<void> _apply(OutboxEntry entry, DispatchOutcome outcome) async {
    switch (outcome) {
      case DispatchSuccess s:
        await _outbox.markAck(entry.envelopeId);
        if (entry.visitId != null) {
          await _visits.markSynced(entry.visitId!);
        }
        _emit(OutboxStatus.acked(
          entry.envelopeId,
          s.httpStatus,
          idempotentReplay: s.idempotentReplay,
        ));
        break;
      case DispatchAlreadyAccepted _:
        await _outbox.markAck(entry.envelopeId);
        if (entry.visitId != null) {
          await _visits.markSynced(entry.visitId!);
        }
        _emit(OutboxStatus.acked(entry.envelopeId, 409));
        break;
      case DispatchAuthExpired _:
        // Try once to refresh. We deliberately push `next_attempt_at` a
        // second into the future so the cycle exits — without that delay
        // a stale-token server (always 401) would chew through the entire
        // attempt budget inside a single drain loop.
        final refreshed = (await _authRefresh?.call()) ?? false;
        if (refreshed) {
          final retryAt = DateTime.now().add(const Duration(seconds: 1));
          await _outbox.markRetrying(
            entry.envelopeId,
            retryAt,
            'token_refresh',
            bumpAttempts: false,
          );
          _emit(OutboxStatus.scheduled(entry.envelopeId, entry.attempts));
        } else {
          await _outbox.markDeadLetter(entry.envelopeId, 'auth_refresh_failed');
          _emit(OutboxStatus.deadLettered(entry.envelopeId));
        }
        break;
      case DispatchTransient t:
        final attempts = entry.attempts + 1;
        if (attempts >= entry.maxAttempts) {
          await _outbox.markDeadLetter(entry.envelopeId, t.error);
          _emit(OutboxStatus.deadLettered(entry.envelopeId));
        } else {
          final delay = _backoff.compute(attempts);
          final next = DateTime.now().add(delay);
          await _outbox.markRetrying(entry.envelopeId, next, t.error);
          _emit(OutboxStatus.scheduled(entry.envelopeId, attempts));
        }
        break;
      case DispatchTerminal t:
        await _outbox.markDeadLetter(entry.envelopeId, t.error);
        _emit(OutboxStatus.deadLettered(
          entry.envelopeId,
          httpStatus: t.httpStatus,
          errorCode: t.code,
        ));
        break;
    }
  }

  void _emit(OutboxStatus s) {
    if (!_statusController.isClosed) _statusController.add(s);
  }

  Future<void> dispose() => _statusController.close();
}

/// Public-facing event the cubit binds to for the status badge.
class OutboxStatus {
  const OutboxStatus._(
    this.kind,
    this.envelopeId, {
    this.attempts,
    this.httpStatus,
    this.idempotentReplay = false,
    this.errorCode,
  });
  final String kind;
  final String envelopeId;
  final int? attempts;
  final int? httpStatus;

  /// True when the backend signalled a duplicate POST hit the dedup cache
  /// (changelog § 6). Surfaced so telemetry can count "real" finishes
  /// separately from network-retry replays.
  final bool idempotentReplay;

  /// Server-side error envelope `code` field (e.g. `permission_denied`,
  /// `visits_geofence_violation`). Populated on `deadLettered` events
  /// driven by a 4xx terminal response so the Crashlytics reporter can
  /// split contract-violation breadcrumbs (`permission_denied` + 403
  /// for `visits.add_unplanned_visit`) from ordinary transient failures.
  final String? errorCode;

  factory OutboxStatus.sending(String id, int attempts) =>
      OutboxStatus._('sending', id, attempts: attempts);
  factory OutboxStatus.acked(String id, int status,
          {bool idempotentReplay = false}) =>
      OutboxStatus._('acked', id,
          httpStatus: status, idempotentReplay: idempotentReplay);
  factory OutboxStatus.scheduled(String id, int attempts) =>
      OutboxStatus._('scheduled', id, attempts: attempts);
  factory OutboxStatus.deadLettered(String id,
          {int? httpStatus, String? errorCode}) =>
      OutboxStatus._('dead_lettered', id,
          httpStatus: httpStatus, errorCode: errorCode);
}
