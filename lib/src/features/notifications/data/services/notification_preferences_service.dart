import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/models/notification_preferences.dart';

/// Reactive storage for [NotificationPreferences]. Lives as a single
/// JSON blob in [SharedPreferences] keyed by [_prefsKey].
///
/// The service is a long-lived singleton — UI listens on [stream] for
/// live updates after Settings flips a toggle, while the push handler
/// reads [value] for the latest snapshot (no need for an async fetch
/// on every push).
class NotificationPreferencesService {
  static const String _prefsKey = 'notif_preferences_v1';

  final SharedPreferencesService _prefs;
  final BehaviorSubject<NotificationPreferences> _subject;
  bool _hydrated = false;

  NotificationPreferencesService({
    required SharedPreferencesService prefs,
  })  : _prefs = prefs,
        _subject =
            BehaviorSubject<NotificationPreferences>.seeded(
                NotificationPreferences.defaults);

  /// Latest preferences. Safe to read synchronously after [bootstrap].
  NotificationPreferences get value => _subject.value;

  /// Distinct stream of updates. UI rebuilds only when something
  /// actually changed (Equatable on the model).
  Stream<NotificationPreferences> get stream => _subject.stream.distinct();

  /// Hydrate the in-memory value from SharedPreferences. Idempotent —
  /// safe to call from `main()` and again later.
  Future<void> bootstrap() async {
    if (_hydrated) return;
    _hydrated = true;
    try {
      final raw = _prefs.preferences.getString(_prefsKey);
      if (raw == null || raw.isEmpty) {
        _subject.add(NotificationPreferences.defaults);
        return;
      }
      _subject.add(NotificationPreferences.decode(raw));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NOTIF-PREFS] bootstrap failed, using defaults: $e');
      }
      _subject.add(NotificationPreferences.defaults);
    }
  }

  /// Replace the entire preferences blob. Used by the Settings screen
  /// after a multi-field edit.
  Future<void> update(NotificationPreferences next) async {
    _subject.add(next);
    try {
      await _prefs.preferences.setString(_prefsKey, next.encode());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NOTIF-PREFS] persist failed: $e');
      }
    }
  }

  Future<void> dispose() => _subject.close();
}
