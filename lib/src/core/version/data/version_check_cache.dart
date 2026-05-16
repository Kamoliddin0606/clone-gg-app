import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gloria_marketing_flutter/src/core/version/data/version_gate_response.dart';

/// SharedPreferences-backed persistence for the version-gate decision.
///
/// Three keys (passport §13):
///   - `version_gate.last_response`        : serialized [VersionGateResponse]
///   - `version_gate.last_check_at`        : `millisecondsSinceEpoch` of the
///                                           last successful network call
///   - `version_gate.dismissed_soft_until` : soft-update "Keyinroq" stamp
///
/// The cache is fail-soft: every getter swallows parse errors and returns
/// `null`. A corrupted entry is logged in debug and erased on the next write
/// — the live network response always wins.
class VersionCheckCache {
  static const _kLastResponse = 'version_gate.last_response';
  static const _kLastCheckAt = 'version_gate.last_check_at';
  static const _kDismissedSoftUntil = 'version_gate.dismissed_soft_until';

  final Future<SharedPreferences> Function() _prefsFactory;

  VersionCheckCache({Future<SharedPreferences> Function()? prefsFactory})
      : _prefsFactory = prefsFactory ?? SharedPreferences.getInstance;

  Future<VersionGateResponse?> read() async {
    try {
      final prefs = await _prefsFactory();
      final raw = prefs.getString(_kLastResponse);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        return VersionGateResponse.fromJson(json);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[VersionCheckCache] read error: $e');
      }
      return null;
    }
  }

  Future<void> save(VersionGateResponse response) async {
    try {
      final prefs = await _prefsFactory();
      await prefs.setString(_kLastResponse, jsonEncode(response.toJson()));
      await prefs.setInt(
        _kLastCheckAt,
        DateTime.now().toUtc().millisecondsSinceEpoch,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[VersionCheckCache] save error: $e');
      }
    }
  }

  Future<DateTime?> lastCheckAt() async {
    try {
      final prefs = await _prefsFactory();
      final stamp = prefs.getInt(_kLastCheckAt);
      if (stamp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(stamp, isUtc: true);
    } catch (_) {
      return null;
    }
  }

  Future<DateTime?> dismissedSoftUntil() async {
    try {
      final prefs = await _prefsFactory();
      final stamp = prefs.getInt(_kDismissedSoftUntil);
      if (stamp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(stamp, isUtc: true);
    } catch (_) {
      return null;
    }
  }

  Future<void> setDismissedSoftUntil(DateTime until) async {
    try {
      final prefs = await _prefsFactory();
      await prefs.setInt(
        _kDismissedSoftUntil,
        until.toUtc().millisecondsSinceEpoch,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[VersionCheckCache] setDismissedSoftUntil error: $e');
      }
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await _prefsFactory();
      await prefs.remove(_kLastResponse);
      await prefs.remove(_kLastCheckAt);
      await prefs.remove(_kDismissedSoftUntil);
    } catch (_) {}
  }
}
