import 'dart:async';

import '../../data/rest/visit_api.dart';

/// Polls a visit's backend status until it lands on `synced_1c`,
/// `rejected`, or the timeout elapses (whichever comes first).
///
/// Backend changelog § 7 (2026-05-17) says `POST /finish/` returns 201
/// immediately but the 1C SOAP forward is async — Celery worker takes
/// up to ~30 seconds in the happy path. This helper lets the
/// post-finish UI show a "buyurtma 1C ga yetkazildi" confirmation
/// without leaking polling state into the BLoC.
///
/// The poller is intentionally narrow:
///   * fire-and-forget (`Future<VisitStatusPollResult>` returns the
///     terminal state).
///   * doesn't mutate any local store — the outbox dispatcher already
///     handles the local `visits_v2.status='synced'` flip.
///   * cancellable via the returned [VisitStatusPollHandle].
class VisitStatusPoller {
  VisitStatusPoller(this._api);

  final VisitApi _api;

  /// Defaults match the changelog's recommended UX window. Override
  /// when running under a different SLA (e.g. retry tests).
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration defaultInterval = Duration(seconds: 5);

  static const _terminalStates = {
    'synced_1c',
    'rejected',
    'cancelled',
  };

  /// Polls in the background. The handle resolves the terminal status
  /// when the visit reaches one of [_terminalStates] or `timeout`
  /// elapses. Either way the caller gets a single result it can render.
  VisitStatusPollHandle pollUntilTerminal(
    String visitId, {
    Duration timeout = defaultTimeout,
    Duration interval = defaultInterval,
  }) {
    final completer = Completer<VisitStatusPollResult>();
    final deadline = DateTime.now().add(timeout);
    var cancelled = false;
    String? lastStatus;

    Future<void> tick() async {
      while (!cancelled) {
        final status = await _api.fetchVisitStatus(visitId);
        if (status != null) lastStatus = status;
        if (status != null && _terminalStates.contains(status)) {
          if (!completer.isCompleted) {
            completer.complete(VisitStatusPollResult(
              status: status,
              timedOut: false,
            ));
          }
          return;
        }
        if (DateTime.now().isAfter(deadline)) {
          if (!completer.isCompleted) {
            completer.complete(VisitStatusPollResult(
              status: lastStatus,
              timedOut: true,
            ));
          }
          return;
        }
        await Future<void>.delayed(interval);
      }
      if (!completer.isCompleted) {
        completer.complete(const VisitStatusPollResult(
          status: null,
          timedOut: false,
          cancelled: true,
        ));
      }
    }

    // Fire-and-forget — the handle owns lifecycle.
    // ignore: discarded_futures
    tick();

    return VisitStatusPollHandle._(
      future: completer.future,
      cancel: () => cancelled = true,
    );
  }
}

class VisitStatusPollHandle {
  VisitStatusPollHandle._({
    required this.future,
    required void Function() cancel,
  }) : _cancel = cancel;

  final Future<VisitStatusPollResult> future;
  final void Function() _cancel;

  void cancel() => _cancel();
}

class VisitStatusPollResult {
  const VisitStatusPollResult({
    required this.status,
    required this.timedOut,
    this.cancelled = false,
  });

  /// Last observed status (`null` if the visit never resolved within
  /// the timeout AND the backend was unreachable every tick).
  final String? status;
  final bool timedOut;
  final bool cancelled;

  bool get reached1C => status == 'synced_1c';
  bool get rejected => status == 'rejected';
}
