/// `POST /api/mobile/v1/devices/register/` payload.
///
/// App startup'da bir marta yuboriladi. Server `(user, device_id)` unique
/// indeksiga asoslanib upsert qiladi va joriy tracking policyni qaytaradi.
class DeviceRegisterRequest {
  // Required
  final String deviceId;

  // Hardware/OS
  final String? deviceName;
  final String? deviceManufacturer;
  final String? deviceModel;
  final String? deviceFingerprint;
  final String? platform; // 'android' | 'ios'
  final String? osVersion;
  final int? screenWidth;
  final int? screenHeight;
  final String? screenDensity;
  final int? ramTotal;
  final int? storageTotal;
  final bool? cameraFront;
  final bool? cameraBack;
  final String? cameraResolution;

  // App
  final String? appVersion;
  final String? appBuildNumber;
  final DateTime? appInstallationDate;
  final DateTime? appLastUpdate;

  // Xavfsizlik
  final bool? isRooted;
  final bool? isJailbroken;
  final bool? encryptionEnabled;
  final String? screenLockType;

  const DeviceRegisterRequest({
    required this.deviceId,
    this.deviceName,
    this.deviceManufacturer,
    this.deviceModel,
    this.deviceFingerprint,
    this.platform,
    this.osVersion,
    this.screenWidth,
    this.screenHeight,
    this.screenDensity,
    this.ramTotal,
    this.storageTotal,
    this.cameraFront,
    this.cameraBack,
    this.cameraResolution,
    this.appVersion,
    this.appBuildNumber,
    this.appInstallationDate,
    this.appLastUpdate,
    this.isRooted,
    this.isJailbroken,
    this.encryptionEnabled,
    this.screenLockType,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'device_id': deviceId};
    void put(String key, Object? value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      map[key] = value;
    }

    put('device_name', deviceName);
    put('device_manufacturer', deviceManufacturer);
    put('device_model', deviceModel);
    put('device_fingerprint', deviceFingerprint);
    put('platform', platform);
    put('os_version', osVersion);
    put('screen_width', screenWidth);
    put('screen_height', screenHeight);
    put('screen_density', screenDensity);
    put('ram_total', ramTotal);
    put('storage_total', storageTotal);
    put('camera_front', cameraFront);
    put('camera_back', cameraBack);
    put('camera_resolution', cameraResolution);
    put('app_version', appVersion);
    put('app_build_number', appBuildNumber);
    if (appInstallationDate != null) {
      map['app_installation_date'] = appInstallationDate!.toUtc().toIso8601String();
    }
    if (appLastUpdate != null) {
      map['app_last_update'] = appLastUpdate!.toUtc().toIso8601String();
    }
    put('is_rooted', isRooted);
    put('is_jailbroken', isJailbroken);
    put('encryption_enabled', encryptionEnabled);
    put('screen_lock_type', screenLockType);
    return map;
  }
}
