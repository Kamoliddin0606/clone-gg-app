import 'dart:convert';

import '../domain/entities/permissions.dart';
import '../domain/entities/visit_envelope.dart';
import '../domain/repositories/outbox_repository.dart';
import 'feature_flags.dart';
import 'sync/outbox_dispatcher.dart';

/// Bridges the BLoC and the outbox/feature-flag plumbing.
///
/// Holds no state of its own; the methods are intentionally single-purpose
/// so the call site reads like prose: "build envelope → enqueue → cycle".
class VisitFinishOrchestrator {
  VisitFinishOrchestrator({
    required OutboxRepository outbox,
    required OutboxDispatcher dispatcher,
    required FeatureFlags flags,
  })  : _outbox = outbox,
        _dispatcher = dispatcher,
        _flags = flags;

  final OutboxRepository _outbox;
  final OutboxDispatcher _dispatcher;
  final FeatureFlags _flags;

  /// `true` when the v2 REST path is active for the current user. The BLoC
  /// branches on this: legacy `VisitFinishService` for SOAP, [submitRestV2]
  /// for v2. Mixing the two is a temporary state during gradual rollout.
  bool get useRestV2 => _flags.useRestV2;

  VisitSubmissionPath get path => _flags.visitSubmissionPath;

  /// Persists the envelope as an outbox row and kicks the dispatcher.
  ///
  /// The dispatcher call is fire-and-forget; the BLoC observes
  /// [OutboxDispatcher.statusStream] for UI feedback.
  Future<void> submitRestV2(VisitEnvelope envelope) async {
    final now = DateTime.now();
    await _outbox.enqueue(OutboxEntry(
      envelopeId: envelope.envelopeId,
      visitId: envelope.visitId,
      endpoint: '/visits/finish/',
      httpMethod: 'POST',
      payloadJson: jsonEncode(envelope.toJson()),
      idempotencyKey: envelope.idempotencyKey,
      clientUuid: envelope.clientUuid,
      status: 'pending',
      attempts: 0,
      maxAttempts: 10,
      nextAttemptAt: now,
      createdAt: now,
      updatedAt: now,
    ));
    // ignore: unawaited_futures
    _dispatcher.cycle();
  }

  /// Manual retry from the dead-letter UI.
  Future<void> retry(String envelopeId) async {
    await _outbox.requeue(envelopeId, DateTime.now());
    // ignore: unawaited_futures
    _dispatcher.cycle();
  }
}
