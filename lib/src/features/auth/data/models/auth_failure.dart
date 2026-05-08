/// Domain-level result of a failed login or token refresh.
///
/// Maps the backend's `error.code` strings to typed Dart variants the UI
/// can switch on without comparing raw strings. Each variant exposes
/// [messageKey] (an `AppLocalizations` getter name) and [messageArgs]
/// (placeholder substitutions) so the UI never builds copy itself.
///
/// Adding a new backend error code requires only:
/// 1. A new `final class FooFailure extends AuthFailure { ... }`.
/// 2. A branch in [AuthFailure.fromErrorEnvelope].
/// 3. Matching ARB entries in `app_en/ru/uz.arb`.
sealed class AuthFailure {
  const AuthFailure();

  /// Backend response payload → typed variant.
  ///
  /// Unknown codes fall through to [UnknownAuthFailure] so the UI can
  /// still surface *something*. Network-layer errors (no HTTP response
  /// at all) should be wrapped in [NetworkFailure] by the caller — this
  /// factory only parses well-formed JSON envelopes.
  factory AuthFailure.fromErrorEnvelope(
    Map<String, dynamic> body,
    int httpStatus,
  ) {
    final errorRaw = body[_BodyKeys.error];
    if (errorRaw is! Map<String, dynamic>) {
      return UnknownAuthFailure(rawCode: 'malformed_envelope');
    }
    final code = errorRaw[_BodyKeys.code]?.toString();
    final details = errorRaw[_BodyKeys.details];

    switch (code) {
      case _Codes.authenticationFailed:
      case _Codes.noActiveAccount:
        return const InvalidCredentialsFailure();
      case _Codes.userInactive:
        return const UserInactiveFailure();
      case _Codes.userOutsideActiveWindow:
        return UserOutsideActiveWindowFailure(
          activeStart: _parseUtc(details?[_DetailKeys.activeStart]),
          activeEnd: _parseUtc(details?[_DetailKeys.activeEnd]),
          serverTime: _parseUtc(details?[_DetailKeys.serverTime]) ??
              DateTime.now().toUtc(),
        );
      case _Codes.licenseMissing:
        return const LicenseMissingFailure();
      case _Codes.licenseExpired:
        return const LicenseExpiredFailure();
      case _Codes.licenseSeatExceeded:
        return LicenseSeatExceededFailure(
          seatCount: _parseInt(details?[_DetailKeys.seatCount]),
          activeUserCount: _parseInt(details?[_DetailKeys.activeUserCount]),
          userRank: _parseInt(details?[_DetailKeys.userRank]),
        );
      case _Codes.tokenNotValid:
        return const InvalidCredentialsFailure();
      case _Codes.mobileDeviceBoundToOtherUser:
        return const MobileDeviceBoundToOtherUserFailure();
      case _Codes.mobileUserBoundToOtherDevice:
        return const MobileUserBoundToOtherDeviceFailure();
      case _Codes.deviceBindingInvalid:
        return const DeviceBindingInvalidFailure();
      case _Codes.sessionRevoked:
        return const SessionRevokedFailure();
      default:
        // Some servers omit `code` and only set HTTP 401 — treat as
        // bad credentials so the user sees actionable copy.
        if (code == null && httpStatus == 401) {
          return const InvalidCredentialsFailure();
        }
        return UnknownAuthFailure(rawCode: code);
    }
  }

  /// Localization key (defined in `AppLocalizations`) used to render the
  /// error message to the user.
  String get messageKey;

  /// Placeholder values for the localized template (e.g. `{rank}`).
  /// Empty when the message has no placeholders.
  Map<String, Object> get messageArgs => const <String, Object>{};

  static DateTime? _parseUtc(Object? value) {
    if (value is! String || value.isEmpty) return null;
    try {
      return DateTime.parse(value).toUtc();
    } catch (_) {
      return null;
    }
  }

  static int _parseInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

final class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure();

  @override
  String get messageKey => 'invalidCredentials';
}

final class UserInactiveFailure extends AuthFailure {
  const UserInactiveFailure();

  @override
  String get messageKey => 'userInactive';
}

final class UserOutsideActiveWindowFailure extends AuthFailure {
  final DateTime? activeStart;
  final DateTime? activeEnd;
  final DateTime serverTime;

  const UserOutsideActiveWindowFailure({
    required this.activeStart,
    required this.activeEnd,
    required this.serverTime,
  });

  @override
  String get messageKey => 'userOutsideActiveWindow';

  @override
  Map<String, Object> get messageArgs => <String, Object>{
        'start': activeStart?.toIso8601String() ?? '—',
        'end': activeEnd?.toIso8601String() ?? '—',
      };
}

final class LicenseMissingFailure extends AuthFailure {
  const LicenseMissingFailure();

  @override
  String get messageKey => 'licenseMissing';
}

final class LicenseExpiredFailure extends AuthFailure {
  const LicenseExpiredFailure();

  @override
  String get messageKey => 'licenseExpired';
}

final class LicenseSeatExceededFailure extends AuthFailure {
  final int seatCount;
  final int activeUserCount;
  final int userRank;

  const LicenseSeatExceededFailure({
    required this.seatCount,
    required this.activeUserCount,
    required this.userRank,
  });

  @override
  String get messageKey => 'licenseSeatExceeded';

  @override
  Map<String, Object> get messageArgs => <String, Object>{
        'rank': userRank,
        'seatCount': seatCount,
      };
}

final class NetworkFailure extends AuthFailure {
  const NetworkFailure();

  @override
  String get messageKey => 'networkError';
}

final class UnknownAuthFailure extends AuthFailure {
  /// Raw `error.code` from the backend (or a synthetic marker like
  /// `malformed_envelope`). Useful for logs / error reporting; not
  /// rendered to the user.
  final String? rawCode;

  const UnknownAuthFailure({this.rawCode});

  /// Points at `serverError` rather than `networkError` because this
  /// failure ALWAYS comes from a real HTTP response — the request
  /// reached the backend, the backend returned a body, we just
  /// didn't recognise the `error.code`. Showing a "no internet"
  /// banner here would be misleading.
  @override
  String get messageKey => 'serverError';
}

// ─── Device-binding failures ─────────────────────────────────────────
// Returned by the backend when the per-organization "1 user ↔ 1 mobile
// device" rule is violated, or when an existing binding/session is
// revoked or invalidated. The mobile app cannot resolve any of them on
// its own — they require an admin action in the React panel.

/// HTTP 423 + `MOBILE_DEVICE_BOUND_TO_OTHER_USER` — this physical
/// handset is already bound to a different login under the same
/// organization. Admin must release the old binding before this user
/// can sign in here.
final class MobileDeviceBoundToOtherUserFailure extends AuthFailure {
  const MobileDeviceBoundToOtherUserFailure();

  @override
  String get messageKey => 'mobileDeviceBoundToOtherUser';
}

/// HTTP 423 + `MOBILE_USER_BOUND_TO_OTHER_DEVICE` — this login is
/// already bound to a different mobile device. Admin must release the
/// old binding before the user can switch phones.
final class MobileUserBoundToOtherDeviceFailure extends AuthFailure {
  const MobileUserBoundToOtherDeviceFailure();

  @override
  String get messageKey => 'mobileUserBoundToOtherDevice';
}

/// HTTP 401 + `device_binding_invalid` — a per-request validation flag
/// emitted after Stage 4 of the rollout. The binding referenced by the
/// access token is no longer active (released or blocked); the only
/// recovery is a fresh login on a binding that admin has activated.
final class DeviceBindingInvalidFailure extends AuthFailure {
  const DeviceBindingInvalidFailure();

  @override
  String get messageKey => 'deviceBindingInvalid';
}

/// HTTP 401 + `session_revoked` — admin clicked "Revoke session" or
/// "Revoke all sessions" in the React panel. Mobile must clear caches
/// and route to the login screen.
final class SessionRevokedFailure extends AuthFailure {
  const SessionRevokedFailure();

  @override
  String get messageKey => 'sessionRevoked';
}

/// V2 JWT login succeeded but the same login is unknown to 1C — the
/// SOAP-side session warm-up cannot proceed. Surfaced after V2 success
/// so the user knows their auth credentials are correct but their
/// account has not been provisioned in the operations system.
final class OneCUserNotFoundFailure extends AuthFailure {
  const OneCUserNotFoundFailure();

  @override
  String get messageKey => 'oneCUserNotFound';
}

class _BodyKeys {
  static const String error = 'error';
  static const String code = 'code';
  static const String details = 'details';
}

class _DetailKeys {
  static const String activeStart = 'active_start';
  static const String activeEnd = 'active_end';
  static const String serverTime = 'server_time';
  static const String seatCount = 'seat_count';
  static const String activeUserCount = 'active_user_count';
  static const String userRank = 'user_rank';
}

class _Codes {
  static const String authenticationFailed = 'authentication_failed';
  // SimpleJWT (Django) returns this when the credentials don't match
  // any active user. Treat it as bad credentials so the user sees
  // actionable copy instead of "unknown error".
  static const String noActiveAccount = 'no_active_account';
  static const String userInactive = 'user_inactive';
  static const String userOutsideActiveWindow = 'user_outside_active_window';
  static const String licenseMissing = 'license_missing';
  static const String licenseExpired = 'license_expired';
  static const String licenseSeatExceeded = 'license_seat_exceeded';
  static const String tokenNotValid = 'token_not_valid';

  // Device-binding error codes (rolled out in stages on the backend).
  // Names mirror the backend exactly — do NOT fold case.
  static const String mobileDeviceBoundToOtherUser =
      'MOBILE_DEVICE_BOUND_TO_OTHER_USER';
  static const String mobileUserBoundToOtherDevice =
      'MOBILE_USER_BOUND_TO_OTHER_DEVICE';
  static const String deviceBindingInvalid = 'device_binding_invalid';
  static const String sessionRevoked = 'session_revoked';
}
