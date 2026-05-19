import 'package:equatable/equatable.dart';

/// Snapshot of the handset attached to every envelope so the backend has
/// the audit trail (model, OS, app version, jailbreak/root flag, battery,
/// network). Captured once per session — not refreshed mid-visit.
class VisitDeviceInfo extends Equatable {
  const VisitDeviceInfo({
    required this.deviceId,
    required this.platform,
    required this.osVersion,
    required this.appVersion,
    required this.model,
    required this.batteryLevel,
    required this.networkType,
    required this.isJailbroken,
    required this.timezone,
    required this.locale,
  });

  /// Stable per-install UUID (`LocalUuidService.deviceUuid`). Not the real
  /// device serial — that would leak PII.
  final String deviceId;

  /// `'android'` or `'ios'`. Lowercase so the backend can compare directly.
  final String platform;

  final String osVersion;
  final String appVersion;
  final String model;

  /// 0.0–1.0. `-1.0` if the platform refused to report (e.g. emulator).
  final double batteryLevel;

  /// `'wifi'`, `'mobile'`, `'ethernet'`, `'vpn'`, `'none'`.
  final String networkType;

  /// `true` if `JailbreakDetector.isCompromised()` returned positive. Release
  /// builds block the visit; debug builds only warn.
  final bool isJailbroken;

  /// IANA timezone name (e.g. `'Asia/Tashkent'`).
  final String timezone;

  /// BCP 47 (e.g. `'uz_UZ'`).
  final String locale;

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'platform': platform,
        'os_version': osVersion,
        'app_version': appVersion,
        'model': model,
        'battery_level': batteryLevel,
        'network_type': networkType,
        'is_jailbroken': isJailbroken,
        'timezone': timezone,
        'locale': locale,
      };

  factory VisitDeviceInfo.fromJson(Map<String, dynamic> json) =>
      VisitDeviceInfo(
        deviceId: json['device_id'] as String,
        platform: json['platform'] as String,
        osVersion: json['os_version'] as String,
        appVersion: json['app_version'] as String,
        model: json['model'] as String,
        batteryLevel: (json['battery_level'] as num).toDouble(),
        networkType: json['network_type'] as String,
        isJailbroken: json['is_jailbroken'] as bool,
        timezone: json['timezone'] as String,
        locale: json['locale'] as String,
      );

  @override
  List<Object?> get props => [
        deviceId,
        platform,
        osVersion,
        appVersion,
        model,
        batteryLevel,
        networkType,
        isJailbroken,
        timezone,
        locale,
      ];
}
