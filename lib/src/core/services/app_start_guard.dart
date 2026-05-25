// =============================================================================
// AppStartGuard
// =============================================================================
//
// Single-responsibility orchestrator for cold-start access decisions.
//
// Decision tree (consume the cached `gates` first; only re-verify online when
// internet is available; never throw — always emit a typed result):
//
//   1. cachedGates == null
//        → showLogin
//   2. clock.nowUtc() < cachedGates.serverTime
//        → showLoginRevoked (clockTamperingDetected) AND clear gates
//   3. connectivity.online == true
//        → tokenService.refreshV2() →
//             200: persist new gates → showHome
//             4xx: clear gates       → showLoginRevoked(failure)
//             network error          → fall through to step 4
//   4. cachedGates.licenseValidTo != null && now >= licenseValidTo
//        → showLoginExpired(licenseExpired) AND clear gates
//   5. cachedGates.userActiveEnd != null && now >= userActiveEnd
//        → showLoginExpired(userOutsideActiveWindow)
//   6. otherwise: showHome
//
// The guard MUST NOT call any UI code; it returns a value object so the
// caller (main.dart) can route accordingly.
// =============================================================================

import 'package:flutter/foundation.dart';

import 'package:gloria_marketing_flutter/src/core/services/connectivity_monitor_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/core/utils/clock.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/auth_failure.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/login_gates_envelope.dart';

/// One of four boot-time outcomes the UI must handle.
enum StartDecision {
  /// No cached session → show the login screen.
  showLogin,

  /// Cached session is valid (online or offline) → go straight to home.
  showHome,

  /// Online refresh told us the user is now blocked. UI shows login
  /// with a banner / SnackBar carrying the [AuthFailure].
  showLoginRevoked,

  /// Cached gates indicate the session has expired (offline path).
  /// UI shows login with a localized expiry message.
  showLoginExpired,
}

/// Value object returned by [AppStartGuard.decide]. The optional
/// [reason] is populated only for the two failure decisions.
class StartDecisionResult {
  final StartDecision decision;
  final AuthFailure? reason;

  const StartDecisionResult({required this.decision, this.reason});

  @override
  String toString() =>
      'StartDecisionResult(decision: $decision, reason: ${reason?.runtimeType})';
}

/// Boot-time access gate. Wires the cached envelope, the token refresh
/// endpoint, connectivity, and a clock into one decision call.
class AppStartGuard {
  final SharedPreferencesService _prefs;
  final TokenService _tokenService;
  final ConnectivityMonitorService _connectivity;
  final Clock _clock;

  AppStartGuard({
    required SharedPreferencesService prefs,
    required TokenService tokenService,
    required ConnectivityMonitorService connectivity,
    Clock clock = const SystemClock(),
  })  : _prefs = prefs,
        _tokenService = tokenService,
        _connectivity = connectivity,
        _clock = clock;

  /// Read cached gates → decide. NEVER throws — maps any error to
  /// [StartDecision.showLogin] so the user can always recover by
  /// re-authenticating.
  Future<StartDecisionResult> decide() async {
    try {
      // Always strip legacy SharedPreferences keys before reading new ones.
      await _prefs.migrateLegacyKeys();

      // Diagnostic dump — deferred to a microtask so it does not block
      // the decide() critical path. Runs only in debug mode.
      Future<void>.microtask(() => _dumpPrefsForDiagnostics());

      // Step 1: no cache → login.
      final LoginGatesEnvelope? cached = _prefs.getCachedGates();
      if (cached == null) {
        return const StartDecisionResult(decision: StartDecision.showLogin);
      }

      // Step 2: clock-tampering sanity check.
      final now = _clock.nowUtc();
      if (now.isBefore(cached.serverTime)) {
        await _clearAuthCaches();
        return StartDecisionResult(
          decision: StartDecision.showLoginRevoked,
          reason: UserOutsideActiveWindowFailure(
            activeStart: cached.userActiveEnd,
            activeEnd: cached.userActiveEnd,
            serverTime: cached.serverTime,
          ),
        );
      }

      // Step 3: online → re-verify with the backend.
      final online = await _isOnline();
      if (online) {
        final refreshed = await _refreshSafely();
        switch (refreshed) {
          case _RefreshOk(:final envelope):
            await _prefs.setCachedGates(envelope);
            // Backend round-trip succeeded → connectivity is proven.
            // Clear any stale offline flag left over from a previous
            // offline-login session so the UI starts in online mode.
            await _prefs.setOfflineMode(false);
            return const StartDecisionResult(decision: StartDecision.showHome);
          case _RefreshDenied(:final failure):
            await _clearAuthCaches();
            return StartDecisionResult(
              decision: StartDecision.showLoginRevoked,
              reason: failure,
            );
          case _RefreshNetworkError():
            // Fall through to offline checks.
            break;
        }
      }

      // Step 4: offline license check.
      if (!cached.bypass &&
          cached.licenseValidTo != null &&
          !now.isBefore(cached.licenseValidTo!)) {
        await _clearAuthCaches();
        return const StartDecisionResult(
          decision: StartDecision.showLoginExpired,
          reason: LicenseExpiredFailure(),
        );
      }

      // Step 5: offline per-user window check.
      if (cached.userActiveEnd != null &&
          !now.isBefore(cached.userActiveEnd!)) {
        return StartDecisionResult(
          decision: StartDecision.showLoginExpired,
          reason: UserOutsideActiveWindowFailure(
            activeStart: null,
            activeEnd: cached.userActiveEnd,
            serverTime: cached.serverTime,
          ),
        );
      }

      // Step 6: cached session is good enough.
      return const StartDecisionResult(decision: StartDecision.showHome);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AppStartGuard] decide() error: $e\n$st');
      }
      return const StartDecisionResult(decision: StartDecision.showLogin);
    }
  }

  /// Print every SharedPreferences key + value (masked for sensitive
  /// fields) so on-device debugging can confirm what is persisted.
  /// Debug-only: skipped in release to avoid blocking the main isolate
  /// at cold-start (the dump iterates ~90+ keys synchronously).
  void _dumpPrefsForDiagnostics() {
    if (!kDebugMode) return;
    try {
      final raw = _prefs.preferences;
      final keys = raw.getKeys().toList()..sort();
      debugPrint('═══════════════════════════════════════════════════════════════');
      debugPrint('[Prefs] dump (${keys.length} keys)');
      for (final k in keys) {
        final v = raw.get(k);
        final shown = _maskIfSensitive(k, v);
        debugPrint('  $k = $shown');
      }
      debugPrint('═══════════════════════════════════════════════════════════════');
    } catch (e) {
      debugPrint('[Prefs] dump error: $e');
    }
  }

  String _maskIfSensitive(String key, Object? value) {
    if (value == null) return 'null';
    final str = value.toString();
    final low = key.toLowerCase();
    final isSensitive = low.contains('token') ||
        low.contains('password') ||
        low.contains('refresh') ||
        low.contains('access') ||
        low.contains('secret') ||
        low.contains('api_key');
    if (isSensitive) {
      // Always mask — even short values. Reveal only the length.
      if (str.length <= 4) return '***(${str.length} chars)';
      return '${str.substring(0, 4)}…(${str.length} chars)';
    }
    return str;
  }

  /// Atomic cleanup used at every "session is no longer valid" branch.
  /// Cache coherence rule: gates and device binding are always cleared
  /// together — never leave one of the pair lingering past a denial.
  Future<void> _clearAuthCaches() async {
    await _prefs.clearCachedGates();
    await _prefs.clearCachedDeviceBinding();
  }

  Future<bool> _isOnline() async {
    try {
      return await _connectivity.hasConnection();
    } catch (_) {
      return false;
    }
  }

  Future<_RefreshOutcome> _refreshSafely() async {
    try {
      final newAccess = await _tokenService.refreshAccessV2();
      if (newAccess == null) {
        // Refresh returned null — could be invalid refresh token (denial)
        // or transient network error. The token service should have
        // logged context; we treat null as denial here (most likely cause)
        // since the connectivity step already confirmed the device is online.
        final failure = _tokenService.lastV2RefreshFailure ??
            const InvalidCredentialsFailure();
        return _RefreshDenied(failure: failure);
      }
      final fresh = _prefs.getCachedGates();
      if (fresh == null) {
        return const _RefreshDenied(failure: UnknownAuthFailure());
      }
      return _RefreshOk(envelope: fresh);
    } catch (_) {
      return const _RefreshNetworkError();
    }
  }
}

sealed class _RefreshOutcome {
  const _RefreshOutcome();
}

class _RefreshOk extends _RefreshOutcome {
  final LoginGatesEnvelope envelope;
  const _RefreshOk({required this.envelope});
}

class _RefreshDenied extends _RefreshOutcome {
  final AuthFailure failure;
  const _RefreshDenied({required this.failure});
}

class _RefreshNetworkError extends _RefreshOutcome {
  const _RefreshNetworkError();
}
