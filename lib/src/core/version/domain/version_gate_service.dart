import 'package:flutter/foundation.dart';

import 'package:gloria_marketing_flutter/src/core/version/data/version_check_cache.dart';
import 'package:gloria_marketing_flutter/src/core/version/data/version_gate_api.dart';
import 'package:gloria_marketing_flutter/src/core/version/data/version_gate_response.dart';

/// Orchestrator for the splash + app-resume version-check flow.
///
/// Three knobs the caller normally needs:
///   - `checkOnStartup` — anonymous probe at cold start. Network wins, cache
///     is a fallback for offline.
///   - `checkOnResume`  — same shape, but skipped if a fresh check already
///     happened in the last hour.
///   - `dismissSoftUpdate` / `isSoftUpdateDismissed` — local-only 24h
///     suppression for the "Keyinroq" path.
///
/// All methods are total: any failure resolves to either a cached payload or
/// `null` (interpreted by the caller as "treat as ok / unknown"). The service
/// never throws.
class VersionGateService {
  final VersionGateApi _api;
  final VersionCheckCache _cache;
  final DateTime Function() _clock;

  VersionGateService({
    required VersionGateApi api,
    required VersionCheckCache cache,
    DateTime Function()? clock,
  })  : _api = api,
        _cache = cache,
        _clock = clock ?? (() => DateTime.now().toUtc());

  /// Splash entry-point. Always tries the network first; on failure (offline,
  /// 4xx, malformed body) falls back to the most recently cached decision.
  Future<VersionGateResponse?> checkOnStartup({String locale = 'uz'}) async {
    try {
      final fresh = await _api.check(locale: locale);
      if (fresh != null) {
        await _cache.save(fresh);
        return fresh;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[VersionGateService] checkOnStartup error: $e');
      }
    }
    return _cache.read();
  }

  /// Foreground-resume entry-point. Skips the network round-trip if a check
  /// landed in the last hour; otherwise behaves like [checkOnStartup].
  Future<VersionGateResponse?> checkOnResume({String locale = 'uz'}) async {
    final last = await _cache.lastCheckAt();
    if (last != null && _clock().difference(last) < const Duration(hours: 1)) {
      return _cache.read();
    }
    return checkOnStartup(locale: locale);
  }

  /// User tapped "Keyinroq" in the soft-update dialog → suppress for 24h.
  Future<void> dismissSoftUpdate() async {
    await _cache.setDismissedSoftUntil(
      _clock().add(const Duration(hours: 24)),
    );
  }

  /// True if a still-active soft-update dismiss stamp is present.
  Future<bool> isSoftUpdateDismissed() async {
    final until = await _cache.dismissedSoftUntil();
    if (until == null) return false;
    return _clock().isBefore(until);
  }

  /// Convenience helper for the splash flow: should we hard-block on this
  /// payload right now?
  static bool shouldBlock(VersionGateResponse? response) {
    if (response == null) return false;
    return response.status.blocksApp;
  }
}
