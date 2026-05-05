/// `POST /api/mobile/v1/telemetry/pings/` payload (flat).
///
/// Server bitta payload'ni Device + LocationPing ga ajratadi. Faqat `latitude`
/// va `longitude` majburiy; qolgan field'lar policy `collect_*` bayroqlariga
/// va mavjud ma'lumotlarga bog'liq holda yuboriladi.
class TelemetryPingRequest {
  // Required
  final String latitude;
  final String longitude;

  // Agent identifikatsiyasi (server JWT'dan ham oladi, lekin metadata uchun)
  final String? agentCode;
  final String? agentName;
  final String? agentPhone;

  // Joylashuv aniqligi va metadata
  final String? accuracy;
  final String? altitude;
  final String? speed;
  final String? heading;
  final String? locationProvider;

  // Manzil (reverse-geocode kelajakda)
  final String? address;
  final String? city;
  final String? country;
  final String? postalCode;
  final String? timezone;

  // Qurilma (collect_device_info=true bo'lganda)
  final String? deviceId;
  final String? deviceName;
  final String? deviceManufacturer;
  final String? deviceModel;
  final String? deviceFingerprint;
  final String? platform;
  final String? osVersion;
  final int? screenWidth;
  final int? screenHeight;
  final String? screenDensity;
  final int? ramTotal;
  final int? ramAvailable;
  final int? storageTotal;
  final int? storageAvailable;
  final bool? cameraFront;
  final bool? cameraBack;
  final String? cameraResolution;
  final String? appVersion;
  final String? appBuildNumber;

  // Batareya (collect_battery=true bo'lganda)
  final String? batteryLevel;
  final bool? isCharging;
  final String? batteryHealth;
  final String? batteryTemperature;
  final String? batteryVoltage;

  // Tarmoq (collect_network=true bo'lganda)
  final String? signalStrength;
  final String? networkType;
  final String? wifiSsid;
  final String? wifiBssid;
  final String? cellularOperator;
  final String? cellularNetworkType;
  final String? ipAddress;
  final String? connectionType;

  // Sensorlar (collect_sensors=true bo'lganda)
  final String? accelerometerX;
  final String? accelerometerY;
  final String? accelerometerZ;
  final String? gyroscopeX;
  final String? gyroscopeY;
  final String? gyroscopeZ;

  // Xavfsizlik
  final bool? isRooted;
  final bool? isJailbroken;
  final bool? encryptionEnabled;
  final String? screenLockType;

  // Vaqt belgisi
  final DateTime? loggedAt;

  const TelemetryPingRequest({
    required this.latitude,
    required this.longitude,
    this.agentCode,
    this.agentName,
    this.agentPhone,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    this.locationProvider,
    this.address,
    this.city,
    this.country,
    this.postalCode,
    this.timezone,
    this.deviceId,
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
    this.ramAvailable,
    this.storageTotal,
    this.storageAvailable,
    this.cameraFront,
    this.cameraBack,
    this.cameraResolution,
    this.appVersion,
    this.appBuildNumber,
    this.batteryLevel,
    this.isCharging,
    this.batteryHealth,
    this.batteryTemperature,
    this.batteryVoltage,
    this.signalStrength,
    this.networkType,
    this.wifiSsid,
    this.wifiBssid,
    this.cellularOperator,
    this.cellularNetworkType,
    this.ipAddress,
    this.connectionType,
    this.accelerometerX,
    this.accelerometerY,
    this.accelerometerZ,
    this.gyroscopeX,
    this.gyroscopeY,
    this.gyroscopeZ,
    this.isRooted,
    this.isJailbroken,
    this.encryptionEnabled,
    this.screenLockType,
    this.loggedAt,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
    };
    void put(String key, Object? value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      map[key] = value;
    }

    put('agent_code', agentCode);
    put('agent_name', agentName);
    put('agent_phone', agentPhone);
    put('accuracy', accuracy);
    put('altitude', altitude);
    put('speed', speed);
    put('heading', heading);
    put('location_provider', locationProvider);
    put('address', address);
    put('city', city);
    put('country', country);
    put('postal_code', postalCode);
    put('timezone', timezone);
    put('device_id', deviceId);
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
    put('ram_available', ramAvailable);
    put('storage_total', storageTotal);
    put('storage_available', storageAvailable);
    put('camera_front', cameraFront);
    put('camera_back', cameraBack);
    put('camera_resolution', cameraResolution);
    put('app_version', appVersion);
    put('app_build_number', appBuildNumber);
    put('battery_level', batteryLevel);
    put('is_charging', isCharging);
    put('battery_health', batteryHealth);
    put('battery_temperature', batteryTemperature);
    put('battery_voltage', batteryVoltage);
    put('signal_strength', signalStrength);
    put('network_type', networkType);
    put('wifi_ssid', wifiSsid);
    put('wifi_bssid', wifiBssid);
    put('cellular_operator', cellularOperator);
    put('cellular_network_type', cellularNetworkType);
    put('ip_address', ipAddress);
    put('connection_type', connectionType);
    put('accelerometer_x', accelerometerX);
    put('accelerometer_y', accelerometerY);
    put('accelerometer_z', accelerometerZ);
    put('gyroscope_x', gyroscopeX);
    put('gyroscope_y', gyroscopeY);
    put('gyroscope_z', gyroscopeZ);
    put('is_rooted', isRooted);
    put('is_jailbroken', isJailbroken);
    put('encryption_enabled', encryptionEnabled);
    put('screen_lock_type', screenLockType);
    if (loggedAt != null) {
      map['logged_at'] = loggedAt!.toUtc().toIso8601String();
    }
    return map;
  }

  factory TelemetryPingRequest.fromJson(Map<String, dynamic> json) {
    DateTime? parsedLoggedAt;
    final loggedAtStr = json['logged_at'] as String?;
    if (loggedAtStr != null) {
      try {
        parsedLoggedAt = DateTime.parse(loggedAtStr);
      } catch (_) {
        parsedLoggedAt = null;
      }
    }
    return TelemetryPingRequest(
      latitude: (json['latitude'] ?? '').toString(),
      longitude: (json['longitude'] ?? '').toString(),
      agentCode: json['agent_code'] as String?,
      agentName: json['agent_name'] as String?,
      agentPhone: json['agent_phone'] as String?,
      accuracy: json['accuracy'] as String?,
      altitude: json['altitude'] as String?,
      speed: json['speed'] as String?,
      heading: json['heading'] as String?,
      locationProvider: json['location_provider'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      postalCode: json['postal_code'] as String?,
      timezone: json['timezone'] as String?,
      deviceId: json['device_id'] as String?,
      deviceName: json['device_name'] as String?,
      deviceManufacturer: json['device_manufacturer'] as String?,
      deviceModel: json['device_model'] as String?,
      deviceFingerprint: json['device_fingerprint'] as String?,
      platform: json['platform'] as String?,
      osVersion: json['os_version'] as String?,
      screenWidth: json['screen_width'] as int?,
      screenHeight: json['screen_height'] as int?,
      screenDensity: json['screen_density'] as String?,
      ramTotal: json['ram_total'] as int?,
      ramAvailable: json['ram_available'] as int?,
      storageTotal: json['storage_total'] as int?,
      storageAvailable: json['storage_available'] as int?,
      cameraFront: json['camera_front'] as bool?,
      cameraBack: json['camera_back'] as bool?,
      cameraResolution: json['camera_resolution'] as String?,
      appVersion: json['app_version'] as String?,
      appBuildNumber: json['app_build_number'] as String?,
      batteryLevel: json['battery_level'] as String?,
      isCharging: json['is_charging'] as bool?,
      batteryHealth: json['battery_health'] as String?,
      batteryTemperature: json['battery_temperature'] as String?,
      batteryVoltage: json['battery_voltage'] as String?,
      signalStrength: json['signal_strength'] as String?,
      networkType: json['network_type'] as String?,
      wifiSsid: json['wifi_ssid'] as String?,
      wifiBssid: json['wifi_bssid'] as String?,
      cellularOperator: json['cellular_operator'] as String?,
      cellularNetworkType: json['cellular_network_type'] as String?,
      ipAddress: json['ip_address'] as String?,
      connectionType: json['connection_type'] as String?,
      accelerometerX: json['accelerometer_x'] as String?,
      accelerometerY: json['accelerometer_y'] as String?,
      accelerometerZ: json['accelerometer_z'] as String?,
      gyroscopeX: json['gyroscope_x'] as String?,
      gyroscopeY: json['gyroscope_y'] as String?,
      gyroscopeZ: json['gyroscope_z'] as String?,
      isRooted: json['is_rooted'] as bool?,
      isJailbroken: json['is_jailbroken'] as bool?,
      encryptionEnabled: json['encryption_enabled'] as bool?,
      screenLockType: json['screen_lock_type'] as String?,
      loggedAt: parsedLoggedAt,
    );
  }
}
