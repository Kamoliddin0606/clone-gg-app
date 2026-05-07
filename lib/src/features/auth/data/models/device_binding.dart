import 'dart:convert';

/// Echo of the backend's `device` block returned alongside `gates` on
/// every successful JWT login or refresh.
///
/// The mobile app does not act on these values directly — they are simply
/// cached so the React admin and backend audit trail can correlate the
/// session with a specific binding row.
///
/// All three fields come from the server. The mobile app must never
/// fabricate any of them; if the server omits the block (Stage 1 grace
/// period), this object is `null`.
final class DeviceBinding {
  /// Server-side primary key of the `UserDeviceBinding` row.
  final String bindingId;

  /// Always `'mobile'` on this app, but kept as a string so the same
  /// model can be reused if a `'web'` client is ever added.
  final String clientType;

  /// Server-side primary key of the active `UserDeviceSession` row.
  /// Rotates on every refresh that issues a new lineage.
  final String sessionId;

  const DeviceBinding({
    required this.bindingId,
    required this.clientType,
    required this.sessionId,
  });

  /// Parses the inner `device` block. Tolerates missing fields by
  /// treating them as empty strings — callers that need to know whether
  /// a binding is present should check the parent envelope's nullable
  /// `device` field instead of inspecting these strings.
  factory DeviceBinding.fromJson(Map<String, dynamic> json) {
    return DeviceBinding(
      bindingId: (json[_Keys.bindingId] ?? '').toString(),
      clientType: (json[_Keys.clientType] ?? '').toString(),
      sessionId: (json[_Keys.sessionId] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        _Keys.bindingId: bindingId,
        _Keys.clientType: clientType,
        _Keys.sessionId: sessionId,
      };

  /// Compact JSON representation for SharedPreferences storage.
  String encode() => jsonEncode(toJson());

  /// Inverse of [encode]. Returns `null` for empty / corrupt input so
  /// callers can treat "no cache" and "bad cache" identically.
  static DeviceBinding? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return DeviceBinding.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  DeviceBinding copyWith({
    String? bindingId,
    String? clientType,
    String? sessionId,
  }) {
    return DeviceBinding(
      bindingId: bindingId ?? this.bindingId,
      clientType: clientType ?? this.clientType,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceBinding &&
        other.bindingId == bindingId &&
        other.clientType == clientType &&
        other.sessionId == sessionId;
  }

  @override
  int get hashCode => Object.hash(bindingId, clientType, sessionId);

  /// Intentionally truncates the IDs — they are sensitive enough that
  /// dumping them into terminal logs would leak server-side primary keys.
  @override
  String toString() {
    String trim(String value) =>
        value.isEmpty ? '∅' : '${value.substring(0, value.length > 8 ? 8 : value.length)}…';
    return 'DeviceBinding(binding=${trim(bindingId)}, '
        'client=$clientType, session=${trim(sessionId)})';
  }
}

/// Centralised JSON keys — the contract is shared with the backend and
/// also appears in `LoginGatesEnvelope`'s `toJson` so the same constants
/// live in one place per model.
class _Keys {
  static const String bindingId = 'binding_id';
  static const String clientType = 'client_type';
  static const String sessionId = 'session_id';
}
