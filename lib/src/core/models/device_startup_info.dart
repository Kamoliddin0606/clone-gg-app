/// =============================================================================
/// Device Startup Info Model
/// =============================================================================
/// 
/// Bu model startup tekshiruvida serverga yuboriladigan qurilma ma'lumotlarini
/// o'z ichiga oladi.
/// =============================================================================

class DeviceStartupInfo {
  /// Foydalanuvchi identifikatori (userCode)
  final String userId;
  
  /// Local UUID (flutter_secure_storage dan)
  final String localUuid;
  
  /// Qurilma identifikatori (androidId yoki identifierForVendor)
  final String? appDeviceId;
  
  /// Platforma (Android/iOS)
  final String platform;
  
  /// Brend (Samsung, Xiaomi, Apple, etc.)
  final String brand;
  
  /// Model (Galaxy S21, iPhone 13, etc.)
  final String model;
  
  /// OS versiyasi
  final String osVersion;
  
  /// SDK versiyasi (faqat Android)
  final String? sdk;
  
  /// Ilova versiyasi
  final String appVersion;
  
  /// Device fingerprint (Android)
  final String? deviceFingerprint;

  const DeviceStartupInfo({
    required this.userId,
    required this.localUuid,
    this.appDeviceId,
    required this.platform,
    required this.brand,
    required this.model,
    required this.osVersion,
    this.sdk,
    required this.appVersion,
    this.deviceFingerprint,
  });

  /// DeviceDataCollector natijasidan yaratish
  factory DeviceStartupInfo.fromDeviceData({
    required String userId,
    required String localUuid,
    required Map<String, dynamic> deviceData,
    required String appVersion,
  }) {
    return DeviceStartupInfo(
      userId: userId,
      localUuid: localUuid,
      appDeviceId: deviceData['device_id'] as String?,
      platform: deviceData['platform'] as String? ?? 'Unknown',
      brand: deviceData['brand'] as String? ?? deviceData['device_manufacturer'] as String? ?? 'Unknown',
      model: deviceData['device_model'] as String? ?? deviceData['model'] as String? ?? 'Unknown',
      osVersion: deviceData['os_version'] as String? ?? 'Unknown',
      sdk: deviceData['sdk_version']?.toString(),
      appVersion: appVersion,
      deviceFingerprint: deviceData['device_fingerprint'] as String?,
    );
  }

  /// SOAP request uchun XML elementlar
  Map<String, String> toSoapParams() {
    return {
      'UserId': userId,
      'LocalUUID': localUuid,
      'AppDeviceId': appDeviceId ?? '',
      'Platform': platform,
      'Brand': brand,
      'Model': model,
      'OSVersion': osVersion,
      'SDK': sdk ?? '',
      'AppVersion': appVersion,
      'DeviceFingerprint': deviceFingerprint ?? '',
    };
  }

  /// JSON formatga o'girish (debug/logging uchun)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'localUuid': localUuid,
      'appDeviceId': appDeviceId,
      'platform': platform,
      'brand': brand,
      'model': model,
      'osVersion': osVersion,
      'sdk': sdk,
      'appVersion': appVersion,
      'deviceFingerprint': deviceFingerprint,
    };
  }

  @override
  String toString() {
    return 'DeviceStartupInfo(userId: $userId, platform: $platform, brand: $brand, model: $model)';
  }
}
