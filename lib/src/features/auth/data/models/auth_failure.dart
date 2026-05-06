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

  @override
  String get messageKey => 'networkError';
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
  static const String userInactive = 'user_inactive';
  static const String userOutsideActiveWindow = 'user_outside_active_window';
  static const String licenseMissing = 'license_missing';
  static const String licenseExpired = 'license_expired';
  static const String licenseSeatExceeded = 'license_seat_exceeded';
  static const String tokenNotValid = 'token_not_valid';
}
