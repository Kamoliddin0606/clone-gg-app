import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show TimeOfDay;

/// Known notification types — drives the per-type toggle list in
/// Settings and the Android channel registry in [PushHandlerService].
///
/// Unknown server-side types fall back to [SystemAnnouncement] / a
/// default channel; the toggle list is open-ended on the server but
/// the UI only renders the values it knows. Add a new constant here
/// when the backend ships a new `type`.
class NotificationTypes {
  NotificationTypes._();

  static const String debtAlert = 'debt_alert';
  static const String orderNew = 'order_new';
  static const String systemAnnouncement = 'system_announcement';
  static const String stockLotExpiring = 'stock_lot_expiring';

  /// All known types, in display order.
  static const List<String> all = [
    debtAlert,
    orderNew,
    stockLotExpiring,
    systemAnnouncement,
  ];
}

/// Output of a per-priority sound setting. Maps onto the Android
/// channel's importance + sound URI, and onto the iOS local-notification
/// `presentSound` flag.
enum NotificationSoundLevel {
  /// No sound, no vibration. Notification still appears.
  silent,

  /// Vibrate only — sound suppressed. Android: `IMPORTANCE_DEFAULT`
  /// with `setSound(null)` + vibration pattern.
  vibrate,

  /// Default channel sound + vibration. Android: `IMPORTANCE_HIGH`.
  sound,
}

/// User-tunable client-side notification preferences. Lives in
/// SharedPreferences as a single JSON blob; loaded once at app boot
/// and exposed as a stream by [NotificationPreferencesService].
///
/// Phase 2 scope per passport-mobile.md §12:
///   * per-`type` enable/disable
///   * Do-not-disturb window (client-side filter; Phase 3 moves it
///     server-side so backend can skip sending entirely)
///   * sound/vibration per priority — fed into Android channel setup
class NotificationPreferences extends Equatable {
  /// `type` → enabled. Missing keys default to `true` (opt-out, not opt-in).
  final Map<String, bool> typeEnabled;

  /// DND window start (local time). `null` when DND is disabled.
  final TimeOfDay? dndStart;

  /// DND window end (local time). `null` when DND is disabled. Allowed
  /// to wrap past midnight, e.g. 22:00 → 06:00.
  final TimeOfDay? dndEnd;

  /// Priority → sound level. Missing keys fall back to [defaultSound].
  final Map<String, NotificationSoundLevel> soundByPriority;

  const NotificationPreferences({
    this.typeEnabled = const {},
    this.dndStart,
    this.dndEnd,
    this.soundByPriority = const {},
  });

  static const NotificationPreferences defaults = NotificationPreferences();

  /// Default sound level when a priority is not customised. Mirrors
  /// passport §12 Q1: high/urgent vibrate; normal/low silent. Sound is
  /// opt-in to keep the noise floor low on a sales-agent device.
  static NotificationSoundLevel defaultSound(String priority) {
    switch (priority) {
      case 'urgent':
      case 'high':
        return NotificationSoundLevel.vibrate;
      case 'low':
        return NotificationSoundLevel.silent;
      case 'normal':
      default:
        return NotificationSoundLevel.silent;
    }
  }

  bool isTypeEnabled(String type) => typeEnabled[type] ?? true;

  NotificationSoundLevel soundFor(String priority) =>
      soundByPriority[priority] ?? defaultSound(priority);

  bool get isDndEnabled => dndStart != null && dndEnd != null;

  /// Returns true when [now] (defaults to wall clock) falls inside the
  /// DND window. Handles overnight wrap, e.g. start=22:00, end=06:00
  /// matches 23:00 AND 04:00 but not 12:00.
  bool isInDnd([DateTime? now]) {
    if (!isDndEnabled) return false;
    final t = now ?? DateTime.now();
    final current = TimeOfDay(hour: t.hour, minute: t.minute);
    return _withinWindow(current, dndStart!, dndEnd!);
  }

  static bool _withinWindow(
    TimeOfDay current,
    TimeOfDay start,
    TimeOfDay end,
  ) {
    final cur = current.hour * 60 + current.minute;
    final s = start.hour * 60 + start.minute;
    final e = end.hour * 60 + end.minute;
    if (s == e) return false; // empty window
    if (s < e) {
      // Normal window: start <= current < end.
      return cur >= s && cur < e;
    }
    // Wrap-around (e.g. 22:00 → 06:00). True if current is at or after
    // start OR strictly before end.
    return cur >= s || cur < e;
  }

  NotificationPreferences copyWith({
    Map<String, bool>? typeEnabled,
    TimeOfDay? dndStart,
    TimeOfDay? dndEnd,
    bool clearDnd = false,
    Map<String, NotificationSoundLevel>? soundByPriority,
  }) {
    return NotificationPreferences(
      typeEnabled: typeEnabled ?? this.typeEnabled,
      dndStart: clearDnd ? null : (dndStart ?? this.dndStart),
      dndEnd: clearDnd ? null : (dndEnd ?? this.dndEnd),
      soundByPriority: soundByPriority ?? this.soundByPriority,
    );
  }

  /// Returns a copy with a single type flipped.
  NotificationPreferences withTypeEnabled(String type, bool enabled) {
    final next = Map<String, bool>.from(typeEnabled);
    next[type] = enabled;
    return copyWith(typeEnabled: next);
  }

  NotificationPreferences withSoundForPriority(
    String priority,
    NotificationSoundLevel level,
  ) {
    final next = Map<String, NotificationSoundLevel>.from(soundByPriority);
    next[priority] = level;
    return copyWith(soundByPriority: next);
  }

  // --- Serialization ---------------------------------------------------------

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'typeEnabled': typeEnabled,
      'dndStart': _timeToString(dndStart),
      'dndEnd': _timeToString(dndEnd),
      'soundByPriority': soundByPriority.map(
        (k, v) => MapEntry(k, v.name),
      ),
    };
  }

  static NotificationPreferences fromJson(Map<String, dynamic> json) {
    final rawTypes = json['typeEnabled'];
    final types = <String, bool>{};
    if (rawTypes is Map) {
      rawTypes.forEach((k, v) {
        if (k is String && v is bool) types[k] = v;
      });
    }
    final rawSound = json['soundByPriority'];
    final sounds = <String, NotificationSoundLevel>{};
    if (rawSound is Map) {
      rawSound.forEach((k, v) {
        if (k is! String) return;
        final level = _parseSound(v);
        if (level != null) sounds[k] = level;
      });
    }
    return NotificationPreferences(
      typeEnabled: types,
      dndStart: _timeFromString(json['dndStart']),
      dndEnd: _timeFromString(json['dndEnd']),
      soundByPriority: sounds,
    );
  }

  String encode() => jsonEncode(toJson());

  static NotificationPreferences decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return fromJson(decoded);
    } catch (_) {/* fall through */}
    return defaults;
  }

  static String? _timeToString(TimeOfDay? t) {
    if (t == null) return null;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static TimeOfDay? _timeFromString(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  static NotificationSoundLevel? _parseSound(Object? raw) {
    if (raw is! String) return null;
    for (final level in NotificationSoundLevel.values) {
      if (level.name == raw) return level;
    }
    return null;
  }

  @override
  List<Object?> get props => [
        typeEnabled,
        dndStart?.hour,
        dndStart?.minute,
        dndEnd?.hour,
        dndEnd?.minute,
        soundByPriority,
      ];
}
