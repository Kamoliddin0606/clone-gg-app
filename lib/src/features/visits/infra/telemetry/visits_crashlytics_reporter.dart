import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../../domain/entities/visit_session.dart';
import '../sync/outbox_dispatcher.dart';

/// Funnels visit lifecycle events into Crashlytics so a post-mortem on a
/// crash report has the visit/envelope context already attached. Mirrors
/// the Sentry tags requested in the mobile passport § 13.1, mapped to
/// the project's actual telemetry backend (Crashlytics).
///
/// Custom keys are bound *globally* on the Crashlytics instance — they
/// survive subsequent log lines until the next call overwrites them.
/// That's exactly what we want for the "current visit" context.
class VisitsCrashlyticsReporter {
  VisitsCrashlyticsReporter({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;
  StreamSubscription<OutboxStatus>? _outboxSub;

  /// Stamps custom keys for the active visit so any crash that happens
  /// while the agent is mid-flow lands with the visit context.
  Future<void> bindActiveVisit(VisitSession session) async {
    await Future.wait([
      _crashlytics.setCustomKey('visits.visit_id', session.visitId),
      _crashlytics.setCustomKey('visits.customer_id', session.customerId),
      _crashlytics.setCustomKey('visits.planned', session.plannedFlag),
      _crashlytics.setCustomKey('visits.task_count', session.tasks.length),
      _crashlytics.setCustomKey('visits.status', session.status.wire),
      if (session.envelopeId != null)
        _crashlytics.setCustomKey('visits.envelope_id', session.envelopeId!),
    ]);
    await _crashlytics.log('visit.bound visit_id=${session.visitId}');
  }

  /// Drops the visit-scoped keys so a later crash isn't blamed on a visit
  /// the user already finished or cancelled. Leaves user-level keys
  /// (deviceId etc.) alone — those are owned by the auth layer.
  Future<void> clearActiveVisit() async {
    await Future.wait([
      _crashlytics.setCustomKey('visits.visit_id', ''),
      _crashlytics.setCustomKey('visits.envelope_id', ''),
      _crashlytics.setCustomKey('visits.status', ''),
    ]);
    await _crashlytics.log('visit.cleared');
  }

  /// Forwards an outbox event as a breadcrumb. The dispatcher fires these
  /// for every send / retry / dead-letter so a crash inside the network
  /// path arrives with the last 64 events already in the report.
  void attachOutbox(Stream<OutboxStatus> stream) {
    _outboxSub?.cancel();
    _outboxSub = stream.listen(_logOutbox);
  }

  void _logOutbox(OutboxStatus event) {
    final kv = <String>[
      'kind=${event.kind}',
      'envelope_id=${event.envelopeId}',
      if (event.attempts != null) 'attempts=${event.attempts}',
      if (event.httpStatus != null) 'http=${event.httpStatus}',
      if (event.errorCode != null) 'code=${event.errorCode}',
      // Backend changelog § 6 — surface replay attribution so
      // network-quality dashboards can split "real" finishes from
      // dedup-cache hits on a flaky uplink.
      if (event.idempotentReplay) 'replay=true',
    ].join(' ');
    // ignore: discarded_futures
    _crashlytics.log('outbox $kv');

    // Scope-cascade rollout (2026-05-17): a 403 `permission_denied`
    // dead-letter means mobile sent an envelope the backend rejected
    // for a missing codename (typically `visits.add_unplanned_visit`).
    // Per passport § 6 this is treated as a mobile contract-violation
    // bug — surface a non-fatal so the issue lands as a distinct
    // Crashlytics class instead of disappearing into the generic
    // outbox-dead-letter breadcrumbs.
    if (event.kind == 'dead_lettered' &&
        event.httpStatus == 403 &&
        event.errorCode == 'permission_denied') {
      // ignore: discarded_futures
      _crashlytics.recordError(
        StateError('visits.contract_violation.unplanned_403'),
        StackTrace.current,
        reason:
            'Mobile submitted planned_flag=false without '
            'visits.add_unplanned_visit codename '
            '(envelope_id=${event.envelopeId})',
        fatal: false,
      );
    }
  }

  /// Records a non-fatal explicitly. Used by the BLoC when a Failure
  /// would otherwise be swallowed by the UI banner — Crashlytics keeps
  /// the trail so we can correlate user reports with logs.
  Future<void> recordFailure(
    Object failure,
    StackTrace stack, {
    String? reason,
  }) {
    return _crashlytics.recordError(
      failure,
      stack,
      reason: reason,
      fatal: false,
    );
  }

  Future<void> dispose() async {
    await _outboxSub?.cancel();
    _outboxSub = null;
  }
}
