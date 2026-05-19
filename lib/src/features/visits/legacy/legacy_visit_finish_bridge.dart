/// Bridge between the legacy SOAP `VisitFinishService` and the new
/// Visits v2 pipeline.
///
/// The legacy code path is owned by `lib/src/features/agent/services/
/// visit_finish_service.dart` and is still the production path until the
/// rollout finishes. This bridge gives the calling UI a single API
/// (`LegacyVisitFinishBridge.finish`) that consults [FeatureFlags] and
/// either:
///   * delegates to the legacy SOAP service (the historical behaviour), or
///   * builds a v2 envelope and hands it to the [VisitFinishOrchestrator].
///
/// The bridge **does not** duplicate the SOAP body. It assumes the legacy
/// service is already registered in GetIt and resolves it dynamically so
/// this file doesn't reach into the agent feature's internals (avoids
/// circular imports).
library;

import 'package:get_it/get_it.dart';

import '../domain/entities/permissions.dart';
import '../domain/entities/visit_envelope.dart';
import '../infra/feature_flags.dart';
import '../infra/visit_finish_orchestrator.dart';

/// Outcome the calling UI can branch on without knowing which path ran.
enum LegacyBridgeOutcome {
  /// Envelope is in the v2 outbox; UI may dismiss the visit screen.
  enqueued,

  /// Legacy SOAP path was used; UI should defer to the legacy service's
  /// existing callbacks for progress / errors.
  legacyHandled,

  /// Neither path was wired (DI gap). UI should surface a banner asking
  /// the user to update / re-login.
  unavailable,
}

class LegacyVisitFinishBridge {
  LegacyVisitFinishBridge({GetIt? locator})
      : _sl = locator ?? GetIt.instance;

  final GetIt _sl;

  /// Routes the finish call based on the cached feature flag.
  ///
  /// Pass [envelope] when the caller has already built one (REST v2
  /// session). The legacy callback runs `legacyHandler` and may take
  /// arbitrarily long — the bridge does not await UI side effects.
  Future<LegacyBridgeOutcome> finish({
    required VisitEnvelope envelope,
    required Future<void> Function() legacyHandler,
  }) async {
    if (!_sl.isRegistered<FeatureFlags>() ||
        !_sl.isRegistered<VisitFinishOrchestrator>()) {
      return LegacyBridgeOutcome.unavailable;
    }

    final flags = _sl<FeatureFlags>();
    if (flags.visitSubmissionPath == VisitSubmissionPath.restV2) {
      await _sl<VisitFinishOrchestrator>().submitRestV2(envelope);
      return LegacyBridgeOutcome.enqueued;
    }

    await legacyHandler();
    return LegacyBridgeOutcome.legacyHandled;
  }

  /// Snapshot of the active path. Useful for the visit screen to label the
  /// finish button or hide the legacy progress UI when v2 is in charge.
  VisitSubmissionPath get currentPath {
    if (!_sl.isRegistered<FeatureFlags>()) {
      return VisitSubmissionPath.soap;
    }
    return _sl<FeatureFlags>().visitSubmissionPath;
  }
}
