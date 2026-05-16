import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Cold-start snapshot of the four `X-App-*` header values plus the optional
/// OS/device telemetry pair. Built once in `main()` (or lazily on first
/// access) and re-used by both the request interceptor and the splash
/// version-check call — `package_info_plus.fromPlatform()` reads from a
/// platform channel and we do not want to pay that cost on every request.
class VersionAppInfo {
  final String packageName;
  final String platform;
  final String appVersion;
  final String buildNumber;
  final String osVersion;
  final String deviceModel;

  const VersionAppInfo({
    required this.packageName,
    required this.platform,
    required this.appVersion,
    required this.buildNumber,
    required this.osVersion,
    required this.deviceModel,
  });

  static const VersionAppInfo empty = VersionAppInfo(
    packageName: '',
    platform: '',
    appVersion: '',
    buildNumber: '',
    osVersion: '',
    deviceModel: '',
  );

  static Future<VersionAppInfo> load() async {
    String packageName = '';
    String appVersion = '';
    String buildNumber = '';
    try {
      final info = await PackageInfo.fromPlatform();
      packageName = info.packageName;
      appVersion = info.version;
      buildNumber = info.buildNumber;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[VersionAppInfo] PackageInfo failed: $e');
      }
    }

    String platform = 'unknown';
    String osVersion = '';
    String deviceModel = '';
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        platform = 'android';
        final android = await deviceInfo.androidInfo;
        osVersion = android.version.release;
        deviceModel = '${android.manufacturer} ${android.model}'.trim();
      } else if (Platform.isIOS) {
        platform = 'ios';
        final ios = await deviceInfo.iosInfo;
        osVersion = ios.systemVersion;
        deviceModel = ios.utsname.machine;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[VersionAppInfo] DeviceInfo failed: $e');
      }
    }

    return VersionAppInfo(
      packageName: packageName,
      platform: platform,
      appVersion: appVersion,
      buildNumber: buildNumber,
      osVersion: osVersion,
      deviceModel: deviceModel,
    );
  }
}
