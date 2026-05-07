/// The device-binding metadata the backend uses to enforce the
/// "1 user ↔ 1 mobile device per organization" rule.
///
/// Sent inside the JWT login body under the `device` key. The contract
/// is described in `docs/runbooks/device-binding/mobile.md` of the
/// backend repo. Stage 1 of the rollout treats this block as optional;
/// Stage 2 onwards rejects mobile login that omits `app_instance_id`
/// with HTTP 400 `DEVICE_PAYLOAD_REQUIRED`.
///
/// All fields are immutable. The payload is built once per app launch
/// by [LoginDevicePayloadBuilder] (see `lib/src/core/services/`); each
/// login attempt reuses the same instance.
final class LoginDevicePayload {
  /// Always `'mobile'` on this app. Backend uses this to pick the right
  /// row in `UserDeviceBinding` (mobile vs web).
  final String clientType;

  /// Stable UUID v4 produced by `LocalUuidService`. Survives app
  /// re-installs because it lives in the platform keychain.
  final String appInstanceId;

  /// `'android'` or `'ios'` — the same lowercase enum the backend
  /// schema uses (`PlatformEnum`).
  final String platform;

  /// User-readable hardware name (e.g. `iPhone15,2` or `Pixel 7 Pro`).
  /// Surfaced in the React admin's bindings list.
  final String deviceName;

  /// OS marketing version (e.g. `iOS 26.3.1`, `Android 15`).
  final String osVersion;

  /// `pubspec.yaml` version string (e.g. `1.4.7`). Helpful when triaging
  /// device-specific bugs — the admin can see which build the binding
  /// was created from.
  final String appVersion;

  const LoginDevicePayload({
    required this.clientType,
    required this.appInstanceId,
    required this.platform,
    required this.deviceName,
    required this.osVersion,
    required this.appVersion,
  });

  /// Backend contract — keys are snake_case.
  Map<String, dynamic> toJson() => <String, dynamic>{
        _Keys.clientType: clientType,
        _Keys.appInstanceId: appInstanceId,
        _Keys.platform: platform,
        _Keys.deviceName: deviceName,
        _Keys.osVersion: osVersion,
        _Keys.appVersion: appVersion,
      };

  LoginDevicePayload copyWith({
    String? clientType,
    String? appInstanceId,
    String? platform,
    String? deviceName,
    String? osVersion,
    String? appVersion,
  }) {
    return LoginDevicePayload(
      clientType: clientType ?? this.clientType,
      appInstanceId: appInstanceId ?? this.appInstanceId,
      platform: platform ?? this.platform,
      deviceName: deviceName ?? this.deviceName,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginDevicePayload &&
        other.clientType == clientType &&
        other.appInstanceId == appInstanceId &&
        other.platform == platform &&
        other.deviceName == deviceName &&
        other.osVersion == osVersion &&
        other.appVersion == appVersion;
  }

  @override
  int get hashCode => Object.hash(
        clientType,
        appInstanceId,
        platform,
        deviceName,
        osVersion,
        appVersion,
      );

  /// Intentionally omits `appInstanceId` — the UUID is sensitive and
  /// must not appear in terminal logs even in debug builds.
  @override
  String toString() => 'LoginDevicePayload('
      'clientType=$clientType, platform=$platform, '
      'deviceName=$deviceName, osVersion=$osVersion, '
      'appVersion=$appVersion, appInstanceId=<redacted>)';
}

/// Centralised JSON keys — kept private so the file owns its contract.
class _Keys {
  static const String clientType = 'client_type';
  static const String appInstanceId = 'app_instance_id';
  static const String platform = 'platform';
  static const String deviceName = 'device_name';
  static const String osVersion = 'os_version';
  static const String appVersion = 'app_version';
}

/// Stable string constants for the only currently supported client type.
/// Keeps the magic string out of business code.
class LoginDeviceClientTypes {
  LoginDeviceClientTypes._();
  static const String mobile = 'mobile';
  static const String web = 'web';
}

/// Stable string constants for the platform enum. Mirrors the backend's
/// `PlatformEnum` so the values stay in sync without consulting the
/// runbook every time.
class LoginDevicePlatforms {
  LoginDevicePlatforms._();
  static const String android = 'android';
  static const String ios = 'ios';
}
