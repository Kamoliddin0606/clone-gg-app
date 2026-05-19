import 'package:flutter/foundation.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

/// Probes the host OS for jailbreak (iOS) / root (Android) state.
///
/// We don't refuse to launch a compromised device — the user may need
/// the app for legitimate offline work. Instead the BLoC consults
/// [isCompromised] at visit start and refuses *that* visit's start when
/// the device looks tampered. The behaviour mirrors what
/// `GeofenceRule.check` does for mock-location fixes: a release build
/// blocks; a debug build only warns so QA can keep testing on rooted
/// emulators.
///
/// Failure of the underlying platform channel is treated as "not
/// compromised" so a missing iOS check never blocks the agent.
class JailbreakDetector {
  const JailbreakDetector();

  /// Cached negative result is fine for the duration of a process —
  /// jailbreak state doesn't flip mid-session.
  static bool? _cached;

  Future<bool> isCompromised() async {
    final cached = _cached;
    if (cached != null) return cached;
    try {
      final jailbroken = await FlutterJailbreakDetection.jailbroken;
      _cached = jailbroken;
      return jailbroken;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JailbreakDetector] probe failed, assuming clean: $e');
      }
      _cached = false;
      return false;
    }
  }

  /// True when release builds should refuse to start a visit. Debug
  /// builds always return false so QA on a rooted emulator can proceed.
  Future<bool> shouldBlockVisitStart() async {
    if (kDebugMode) return false;
    return isCompromised();
  }

  /// Test seam.
  @visibleForTesting
  static void resetCache() {
    _cached = null;
  }
}
