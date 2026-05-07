import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:gloria_marketing_flutter/src/core/services/local_uuid_service.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/login_device_payload.dart';

/// Builds the [LoginDevicePayload] sent in every JWT login body.
///
/// Combines three sources:
///   * [LocalUuidService] for the stable per-install `app_instance_id`.
///   * `device_info_plus` for the human-readable `device_name` and
///     `os_version` (Android `Build` + iOS `utsname` fallbacks).
///   * `package_info_plus` for the `app_version` from `pubspec.yaml`.
///
/// The payload is memoised in memory after the first successful build —
/// every login attempt within the same app session reuses the same
/// instance, so a single read of the secure keychain + plugin channels
/// is amortised across the whole session.
///
/// Failure-tolerant: if any of the underlying plugins throw, the
/// builder substitutes empty strings for the offending fields so the
/// login can still proceed (Stage 1 is record-only). The caller can
/// inspect [LoginDevicePayload.appInstanceId] to know whether the UUID
/// part was populated.
class LoginDevicePayloadBuilder {
  final LocalUuidService _uuidService;
  final DeviceInfoPlugin _deviceInfo;

  /// Memoised payload — null until the first build.
  LoginDevicePayload? _cached;

  LoginDevicePayloadBuilder({
    required LocalUuidService uuidService,
    DeviceInfoPlugin? deviceInfo,
  })  : _uuidService = uuidService,
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  /// Returns the cached payload, building it on the first call.
  ///
  /// Pass [forceRebuild] when something has changed mid-session that
  /// invalidates the cache (e.g. the OS version after an update — rare
  /// but cheap to support).
  Future<LoginDevicePayload> build({bool forceRebuild = false}) async {
    if (!forceRebuild && _cached != null) return _cached!;

    final results = await Future.wait<Object?>([
      _safeUuid(),
      _safeDeviceMetadata(),
      _safePackageInfo(),
    ]);

    final uuid = results[0] as String;
    final metadata = results[1] as _DeviceMetadata;
    final pkg = results[2] as PackageInfo?;

    _cached = LoginDevicePayload(
      clientType: LoginDeviceClientTypes.mobile,
      appInstanceId: uuid,
      platform: metadata.platform,
      deviceName: metadata.deviceName,
      osVersion: metadata.osVersion,
      appVersion: pkg?.version ?? '',
    );
    return _cached!;
  }

  /// Drops the in-memory cache. Used by tests and by logout flows that
  /// want the next login to re-read every source of truth.
  void clearCache() => _cached = null;

  Future<String> _safeUuid() async {
    try {
      return await _uuidService.getOrCreateLocalUuid();
    } catch (e) {
      if (kDebugMode) {
        // Never log the raw UUID; only the failure context.
        debugPrint('[LoginDevicePayloadBuilder] UUID read failed: $e');
      }
      return '';
    }
  }

  Future<_DeviceMetadata> _safeDeviceMetadata() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return _DeviceMetadata(
          platform: LoginDevicePlatforms.android,
          deviceName: '${info.manufacturer} ${info.model}'.trim(),
          osVersion: 'Android ${info.version.release}',
        );
      }
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        // `utsname.machine` is the canonical hardware identifier
        // (e.g. iPhone15,2). The user-facing `name` can be empty on
        // freshly provisioned devices.
        final name = info.name.isNotEmpty ? info.name : info.utsname.machine;
        return _DeviceMetadata(
          platform: LoginDevicePlatforms.ios,
          deviceName: name,
          osVersion: '${info.systemName} ${info.systemVersion}'.trim(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LoginDevicePayloadBuilder] device_info read failed: $e');
      }
    }
    return const _DeviceMetadata(
      platform: '',
      deviceName: '',
      osVersion: '',
    );
  }

  Future<PackageInfo?> _safePackageInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LoginDevicePayloadBuilder] package_info read failed: $e');
      }
      return null;
    }
  }
}

/// Internal grouping for the device-info bits — reduces the surface
/// area of [LoginDevicePayloadBuilder._safeDeviceMetadata] and keeps
/// the platform-specific branches readable.
class _DeviceMetadata {
  final String platform;
  final String deviceName;
  final String osVersion;

  const _DeviceMetadata({
    required this.platform,
    required this.deviceName,
    required this.osVersion,
  });
}
