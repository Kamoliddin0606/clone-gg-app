/// =============================================================================
/// Agent Location Record Model
/// =============================================================================
/// 
/// Bu model serverga yuboriladigan location ma'lumotlarini o'z ichiga oladi.
/// API endpointi: agent-location telemetry endpoint (V2 backend).
///
/// Barcha maydonlar API dokumentatsiyasiga mos keladi.
/// Majburiy maydonlar: agent_code, latitude, longitude
/// =============================================================================

/// Agent joylashuv ma'lumotlarini serverga yuborish uchun model
/// 
/// Bu model quyidagi ma'lumotlarni o'z ichiga oladi:
/// - Agent identifikatsiyasi (agent_code, agent_name, agent_phone)
/// - Joylashuv ma'lumotlari (latitude, longitude, accuracy, altitude, speed, heading)
/// - Qurilma ma'lumotlari (device_id, device_name, device_manufacturer, device_model, platform, os_version)
/// - Ekran ma'lumotlari (screen_width, screen_height, screen_density)
/// - Xotira ma'lumotlari (ram_total, ram_available, storage_total, storage_available)
/// - Kamera ma'lumotlari (camera_front, camera_back, camera_resolution)
/// - Ilova ma'lumotlari (app_version, app_build_number, app_installation_date, app_last_update)
/// - Batareya ma'lumotlari (battery_level, is_charging, battery_health, battery_temperature, battery_voltage)
/// - Tarmoq ma'lumotlari (signal_strength, network_type, wifi_ssid, wifi_bssid, cellular_operator, etc.)
/// - Sensor ma'lumotlari (accelerometer, gyroscope, magnetometer, proximity, light, temperature, humidity, pressure)
/// - Xavfsizlik ma'lumotlari (device_fingerprint, is_rooted, is_jailbroken, encryption_enabled, screen_lock_type)
/// - Qo'shimcha ma'lumotlar (logged_at, address, note, metadata)
class AgentLocationRecord {
  // ===========================================================================
  // MAJBURIY MAYDONLAR (Required Fields)
  // ===========================================================================
  
  /// Agent kodi - serverda agentni identifikatsiya qilish uchun
  /// API: agent_code (required, string, non-empty)
  final String agentCode;
  
  /// Geografik kenglik (Latitude)
  /// API: latitude (required, string, decimal, pattern: ^-?\d{0,3}(?:\.\d{0,6})?$)
  final String latitude;
  
  /// Geografik uzunlik (Longitude)
  /// API: longitude (required, string, decimal, pattern: ^-?\d{0,3}(?:\.\d{0,6})?$)
  final String longitude;
  
  // ===========================================================================
  // AGENT MA'LUMOTLARI (Agent Information)
  // ===========================================================================
  
  /// Agent ismi
  /// API: agent_name (string)
  final String? agentName;
  
  /// Agent telefon raqami
  /// API: agent_phone (string)
  final String? agentPhone;
  
  /// Hudud nomi
  /// API: region (string)
  final String? region;
  
  // ===========================================================================
  // QURILMA MA'LUMOTLARI (Device Information)
  // ===========================================================================
  
  /// Qurilma unikal identifikatori
  /// API: device_id (string)
  final String? deviceId;
  
  /// Qurilma nomi
  /// API: device_name (string)
  final String? deviceName;
  
  /// Ishlab chiqaruvchi nomi (Samsung, Xiaomi, Apple, etc.)
  /// API: device_manufacturer (string)
  final String? deviceManufacturer;
  
  /// Qurilma modeli (Galaxy S21, iPhone 13, etc.)
  /// API: device_model (string)
  final String? deviceModel;
  
  /// Operatsion tizim (Android/iOS)
  /// API: platform (string)
  final String? platform;
  
  /// OS versiyasi (12, 15.0, etc.)
  /// API: os_version (string)
  final String? osVersion;
  
  // ===========================================================================
  // EKRAN MA'LUMOTLARI (Screen Information)
  // ===========================================================================
  
  /// Ekran kengligi (pikselda)
  /// API: screen_width (integer or null)
  final int? screenWidth;
  
  /// Ekran balandligi (pikselda)
  /// API: screen_height (integer or null)
  final int? screenHeight;
  
  /// Ekran zichligi (DPI)
  /// API: screen_density (string or null, decimal, pattern: ^-?\d{0,3}(?:\.\d{0,2})?$)
  final String? screenDensity;
  
  // ===========================================================================
  // XOTIRA MA'LUMOTLARI (Memory Information)
  // ===========================================================================
  
  /// Jami RAM (baytda)
  /// API: ram_total (integer or null)
  final int? ramTotal;
  
  /// Mavjud RAM (baytda)
  /// API: ram_available (integer or null)
  final int? ramAvailable;
  
  /// Jami xotira (baytda)
  /// API: storage_total (integer or null)
  final int? storageTotal;
  
  /// Mavjud xotira (baytda)
  /// API: storage_available (integer or null)
  final int? storageAvailable;
  
  // ===========================================================================
  // KAMERA MA'LUMOTLARI (Camera Information)
  // ===========================================================================
  
  /// Old kamera mavjudligi
  /// API: camera_front (boolean)
  final bool? cameraFront;
  
  /// Orqa kamera mavjudligi
  /// API: camera_back (boolean)
  final bool? cameraBack;
  
  /// Kamera o'lchami/resolution
  /// API: camera_resolution (string)
  final String? cameraResolution;
  
  // ===========================================================================
  // ILOVA MA'LUMOTLARI (App Information)
  // ===========================================================================
  
  /// Ilova versiyasi
  /// API: app_version (string)
  final String? appVersion;
  
  /// Build raqami
  /// API: app_build_number (string)
  final String? appBuildNumber;
  
  /// O'rnatilgan sana
  /// API: app_installation_date (string or null, date-time)
  final DateTime? appInstallationDate;
  
  /// Oxirgi yangilanish sanasi
  /// API: app_last_update (string or null, date-time)
  final DateTime? appLastUpdate;
  
  // ===========================================================================
  // JOYLASHUV ANIQLIGI (Location Accuracy)
  // ===========================================================================
  
  /// Aniqlik (metrda)
  /// API: accuracy (string or null, decimal, pattern: ^-?\d{0,5}(?:\.\d{0,2})?$)
  final String? accuracy;
  
  /// Balandlik (metrda)
  /// API: altitude (string or null, decimal, pattern: ^-?\d{0,6}(?:\.\d{0,2})?$)
  final String? altitude;
  
  /// Tezlik (m/s)
  /// API: speed (string or null, decimal, pattern: ^-?\d{0,4}(?:\.\d{0,2})?$)
  final String? speed;
  
  /// Yo'nalish (gradusda, 0-360)
  /// API: heading (string or null, decimal, pattern: ^-?\d{0,4}(?:\.\d{0,2})?$)
  final String? heading;
  
  // ===========================================================================
  // MANZIL MA'LUMOTLARI (Address Information)
  // ===========================================================================
  
  /// Shahar nomi
  /// API: city (string)
  final String? city;
  
  /// Davlat nomi
  /// API: country (string)
  final String? country;
  
  /// Pochta indeksi
  /// API: postal_code (string)
  final String? postalCode;
  
  /// Vaqt mintaqasi (e.g., "Asia/Tashkent")
  /// API: timezone (string)
  final String? timezone;
  
  /// Lokatsiya manbasi (GPS, Network, Fused, etc.)
  /// API: location_provider (string)
  final String? locationProvider;
  
  // ===========================================================================
  // BATAREYA MA'LUMOTLARI (Battery Information)
  // ===========================================================================
  
  /// Batareya darajasi (foizda, 0-100)
  /// API: battery_level (string or null, decimal, pattern: ^-?\d{0,3}(?:\.\d{0,1})?$)
  final String? batteryLevel;
  
  /// Batareya zaryadlanayaptimi
  /// API: is_charging (boolean)
  final bool? isCharging;
  
  /// Batareya holati (Good, Overheat, Dead, etc.)
  /// API: battery_health (string)
  final String? batteryHealth;
  
  /// Batareya harorati (Celsius)
  /// API: battery_temperature (string or null, decimal, pattern: ^-?\d{0,3}(?:\.\d{0,2})?$)
  final String? batteryTemperature;
  
  /// Batareya kuchlanishi (Volt)
  /// API: battery_voltage (string or null, decimal, pattern: ^-?\d{0,3}(?:\.\d{0,3})?$)
  final String? batteryVoltage;
  
  // ===========================================================================
  // TARMOQ MA'LUMOTLARI (Network Information)
  // ===========================================================================
  
  /// Signal kuchi
  /// API: signal_strength (string)
  final String? signalStrength;
  
  /// Tarmoq turi (WiFi, Mobile, None)
  /// API: network_type (string)
  final String? networkType;
  
  /// WiFi SSID (tarmoq nomi)
  /// API: wifi_ssid (string)
  final String? wifiSsid;
  
  /// WiFi BSSID (MAC address)
  /// API: wifi_bssid (string)
  final String? wifiBssid;
  
  /// Mobil operator nomi
  /// API: cellular_operator (string)
  final String? cellularOperator;
  
  /// Mobil tarmoq turi (4G, 5G, LTE, etc.)
  /// API: cellular_network_type (string)
  final String? cellularNetworkType;
  
  /// IP manzil
  /// API: ip_address (string or null, non-empty)
  final String? ipAddress;
  
  /// Ulanish turi
  /// API: connection_type (string)
  final String? connectionType;
  
  // ===========================================================================
  // SENSOR MA'LUMOTLARI (Sensor Information)
  // ===========================================================================
  
  /// Accelerometer X o'qi
  /// API: accelerometer_x (string or null, decimal, pattern: ^-?\d{0,4}(?:\.\d{0,4})?$)
  final String? accelerometerX;
  
  /// Accelerometer Y o'qi
  /// API: accelerometer_y (string or null, decimal, pattern: ^-?\d{0,4}(?:\.\d{0,4})?$)
  final String? accelerometerY;
  
  /// Accelerometer Z o'qi
  /// API: accelerometer_z (string or null, decimal, pattern: ^-?\d{0,4}(?:\.\d{0,4})?$)
  final String? accelerometerZ;
  
  /// Gyroscope X o'qi
  /// API: gyroscope_x (string or null, decimal, pattern: ^-?\d{0,4}(?:\.\d{0,4})?$)
  final String? gyroscopeX;
  
  /// Gyroscope Y o'qi
  /// API: gyroscope_y (string or null, decimal, pattern: ^-?\d{0,4}(?:\.\d{0,4})?$)
  final String? gyroscopeY;
  
  /// Gyroscope Z o'qi
  /// API: gyroscope_z (string or null, decimal, pattern: ^-?\d{0,4}(?:\.\d{0,4})?$)
  final String? gyroscopeZ;
  
  /// Magnetometer X o'qi
  /// API: magnetometer_x (string or null, decimal, pattern: ^-?\d{0,4}(?:\.\d{0,4})?$)
  final String? magnetometerX;
  
  /// Magnetometer Y o'qi
  /// API: magnetometer_y (string or null, decimal, pattern: ^-?\d{0,4}(?:\.\d{0,4})?$)
  final String? magnetometerY;
  
  /// Magnetometer Z o'qi
  /// API: magnetometer_z (string or null, decimal, pattern: ^-?\d{0,4}(?:\.\d{0,4})?$)
  final String? magnetometerZ;
  
  /// Yaqinlik sensori qiymati
  /// API: proximity_sensor (string or null, decimal, pattern: ^-?\d{0,4}(?:\.\d{0,4})?$)
  final String? proximitySensor;
  
  /// Yorug'lik sensori qiymati (lux)
  /// API: light_sensor (string or null, decimal, pattern: ^-?\d{0,6}(?:\.\d{0,2})?$)
  final String? lightSensor;
  
  /// Harorat (Celsius)
  /// API: temperature (string or null, decimal, pattern: ^-?\d{0,3}(?:\.\d{0,2})?$)
  final String? temperature;
  
  /// Namlik (foizda)
  /// API: humidity (string or null, decimal, pattern: ^-?\d{0,3}(?:\.\d{0,2})?$)
  final String? humidity;
  
  /// Bosim (hPa)
  /// API: pressure (string or null, decimal, pattern: ^-?\d{0,5}(?:\.\d{0,2})?$)
  final String? pressure;
  
  // ===========================================================================
  // XAVFSIZLIK MA'LUMOTLARI (Security Information)
  // ===========================================================================
  
  /// Qurilma fingerprint (unikal identifikator)
  /// API: device_fingerprint (string)
  final String? deviceFingerprint;
  
  /// Qurilma root qilinganmi (Android)
  /// API: is_rooted (boolean)
  final bool? isRooted;
  
  /// Qurilma jailbreak qilinganmi (iOS)
  /// API: is_jailbroken (boolean)
  final bool? isJailbroken;
  
  /// Shifrlash yoqilganmi
  /// API: encryption_enabled (boolean)
  final bool? encryptionEnabled;
  
  /// Ekran qulfi turi (PIN, Pattern, Fingerprint, Face, None)
  /// API: screen_lock_type (string)
  final String? screenLockType;
  
  // ===========================================================================
  // QO'SHIMCHA MA'LUMOTLAR (Additional Information)
  // ===========================================================================
  
  /// Qurilmada yozilgan vaqt (local time when location was recorded)
  /// API: logged_at (string or null, date-time)
  final DateTime? loggedAt;
  
  /// Manzil (to'liq manzil string)
  /// API: address (string)
  final String? address;
  
  /// Izoh (qo'shimcha ma'lumot)
  /// API: note (string)
  final String? note;
  
  /// Qo'shimcha JSON ma'lumotlar
  /// API: metadata (any or null)
  final Map<String, dynamic>? metadata;

  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================
  
  /// AgentLocationRecord konstruktori
  /// 
  /// Majburiy parametrlar:
  /// - [agentCode] - Agent identifikatori
  /// - [latitude] - Geografik kenglik
  /// - [longitude] - Geografik uzunlik
  AgentLocationRecord({
    required this.agentCode,
    required this.latitude,
    required this.longitude,
    this.agentName,
    this.agentPhone,
    this.region,
    this.deviceId,
    this.deviceName,
    this.deviceManufacturer,
    this.deviceModel,
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
    this.appInstallationDate,
    this.appLastUpdate,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    this.city,
    this.country,
    this.postalCode,
    this.timezone,
    this.locationProvider,
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
    this.magnetometerX,
    this.magnetometerY,
    this.magnetometerZ,
    this.proximitySensor,
    this.lightSensor,
    this.temperature,
    this.humidity,
    this.pressure,
    this.deviceFingerprint,
    this.isRooted,
    this.isJailbroken,
    this.encryptionEnabled,
    this.screenLockType,
    this.loggedAt,
    this.address,
    this.note,
    this.metadata,
  });

  // ===========================================================================
  // TO JSON - API uchun ma'lumotlarni JSON formatga o'girish
  // ===========================================================================
  
  /// Ma'lumotlarni API uchun JSON formatga o'girish
  /// 
  /// Bu metod faqat null bo'lmagan qiymatlarni qaytaradi,
  /// API ga keraksiz null maydonlar yuborilmaydi.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      // Majburiy maydonlar
      'agent_code': agentCode,
      'latitude': latitude,
      'longitude': longitude,
    };

    // Agent ma'lumotlari
    if (agentName != null) json['agent_name'] = agentName;
    if (agentPhone != null) json['agent_phone'] = agentPhone;
    if (region != null) json['region'] = region;

    // Qurilma ma'lumotlari
    if (deviceId != null) json['device_id'] = deviceId;
    if (deviceName != null) json['device_name'] = deviceName;
    if (deviceManufacturer != null) json['device_manufacturer'] = deviceManufacturer;
    if (deviceModel != null) json['device_model'] = deviceModel;
    if (platform != null) json['platform'] = platform;
    if (osVersion != null) json['os_version'] = osVersion;

    // Ekran ma'lumotlari
    if (screenWidth != null) json['screen_width'] = screenWidth;
    if (screenHeight != null) json['screen_height'] = screenHeight;
    if (screenDensity != null) json['screen_density'] = screenDensity;

    // Xotira ma'lumotlari
    if (ramTotal != null) json['ram_total'] = ramTotal;
    if (ramAvailable != null) json['ram_available'] = ramAvailable;
    if (storageTotal != null) json['storage_total'] = storageTotal;
    if (storageAvailable != null) json['storage_available'] = storageAvailable;

    // Kamera ma'lumotlari
    if (cameraFront != null) json['camera_front'] = cameraFront;
    if (cameraBack != null) json['camera_back'] = cameraBack;
    if (cameraResolution != null) json['camera_resolution'] = cameraResolution;

    // Ilova ma'lumotlari
    if (appVersion != null) json['app_version'] = appVersion;
    if (appBuildNumber != null) json['app_build_number'] = appBuildNumber;
    if (appInstallationDate != null) json['app_installation_date'] = appInstallationDate!.toIso8601String();
    if (appLastUpdate != null) json['app_last_update'] = appLastUpdate!.toIso8601String();

    // Joylashuv aniqligi
    if (accuracy != null) json['accuracy'] = accuracy;
    if (altitude != null) json['altitude'] = altitude;
    if (speed != null) json['speed'] = speed;
    if (heading != null) json['heading'] = heading;

    // Manzil ma'lumotlari
    if (city != null) json['city'] = city;
    if (country != null) json['country'] = country;
    if (postalCode != null) json['postal_code'] = postalCode;
    if (timezone != null) json['timezone'] = timezone;
    if (locationProvider != null) json['location_provider'] = locationProvider;

    // Batareya ma'lumotlari
    if (batteryLevel != null) json['battery_level'] = batteryLevel;
    if (isCharging != null) json['is_charging'] = isCharging;
    if (batteryHealth != null) json['battery_health'] = batteryHealth;
    if (batteryTemperature != null) json['battery_temperature'] = batteryTemperature;
    if (batteryVoltage != null) json['battery_voltage'] = batteryVoltage;

    // Tarmoq ma'lumotlari
    if (signalStrength != null) json['signal_strength'] = signalStrength;
    if (networkType != null) json['network_type'] = networkType;
    if (wifiSsid != null) json['wifi_ssid'] = wifiSsid;
    if (wifiBssid != null) json['wifi_bssid'] = wifiBssid;
    if (cellularOperator != null) json['cellular_operator'] = cellularOperator;
    if (cellularNetworkType != null) json['cellular_network_type'] = cellularNetworkType;
    if (ipAddress != null) json['ip_address'] = ipAddress;
    if (connectionType != null) json['connection_type'] = connectionType;

    // Sensor ma'lumotlari
    if (accelerometerX != null) json['accelerometer_x'] = accelerometerX;
    if (accelerometerY != null) json['accelerometer_y'] = accelerometerY;
    if (accelerometerZ != null) json['accelerometer_z'] = accelerometerZ;
    if (gyroscopeX != null) json['gyroscope_x'] = gyroscopeX;
    if (gyroscopeY != null) json['gyroscope_y'] = gyroscopeY;
    if (gyroscopeZ != null) json['gyroscope_z'] = gyroscopeZ;
    if (magnetometerX != null) json['magnetometer_x'] = magnetometerX;
    if (magnetometerY != null) json['magnetometer_y'] = magnetometerY;
    if (magnetometerZ != null) json['magnetometer_z'] = magnetometerZ;
    if (proximitySensor != null) json['proximity_sensor'] = proximitySensor;
    if (lightSensor != null) json['light_sensor'] = lightSensor;
    if (temperature != null) json['temperature'] = temperature;
    if (humidity != null) json['humidity'] = humidity;
    if (pressure != null) json['pressure'] = pressure;

    // Xavfsizlik ma'lumotlari
    if (deviceFingerprint != null) json['device_fingerprint'] = deviceFingerprint;
    if (isRooted != null) json['is_rooted'] = isRooted;
    if (isJailbroken != null) json['is_jailbroken'] = isJailbroken;
    if (encryptionEnabled != null) json['encryption_enabled'] = encryptionEnabled;
    if (screenLockType != null) json['screen_lock_type'] = screenLockType;

    // Qo'shimcha ma'lumotlar
    if (loggedAt != null) json['logged_at'] = loggedAt!.toIso8601String();
    if (address != null) json['address'] = address;
    if (note != null) json['note'] = note;
    if (metadata != null) json['metadata'] = metadata;

    return json;
  }

  // ===========================================================================
  // FROM JSON - API javobidan model yaratish
  // ===========================================================================
  
  /// API javobidan AgentLocationRecord yaratish
  factory AgentLocationRecord.fromJson(Map<String, dynamic> json) {
    return AgentLocationRecord(
      agentCode: json['agent_code'] as String,
      latitude: json['latitude'] as String,
      longitude: json['longitude'] as String,
      agentName: json['agent_name'] as String?,
      agentPhone: json['agent_phone'] as String?,
      region: json['region'] as String?,
      deviceId: json['device_id'] as String?,
      deviceName: json['device_name'] as String?,
      deviceManufacturer: json['device_manufacturer'] as String?,
      deviceModel: json['device_model'] as String?,
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
      appInstallationDate: json['app_installation_date'] != null 
          ? DateTime.parse(json['app_installation_date'] as String) 
          : null,
      appLastUpdate: json['app_last_update'] != null 
          ? DateTime.parse(json['app_last_update'] as String) 
          : null,
      accuracy: json['accuracy'] as String?,
      altitude: json['altitude'] as String?,
      speed: json['speed'] as String?,
      heading: json['heading'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      postalCode: json['postal_code'] as String?,
      timezone: json['timezone'] as String?,
      locationProvider: json['location_provider'] as String?,
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
      magnetometerX: json['magnetometer_x'] as String?,
      magnetometerY: json['magnetometer_y'] as String?,
      magnetometerZ: json['magnetometer_z'] as String?,
      proximitySensor: json['proximity_sensor'] as String?,
      lightSensor: json['light_sensor'] as String?,
      temperature: json['temperature'] as String?,
      humidity: json['humidity'] as String?,
      pressure: json['pressure'] as String?,
      deviceFingerprint: json['device_fingerprint'] as String?,
      isRooted: json['is_rooted'] as bool?,
      isJailbroken: json['is_jailbroken'] as bool?,
      encryptionEnabled: json['encryption_enabled'] as bool?,
      screenLockType: json['screen_lock_type'] as String?,
      loggedAt: json['logged_at'] != null 
          ? DateTime.parse(json['logged_at'] as String) 
          : null,
      address: json['address'] as String?,
      note: json['note'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // ===========================================================================
  // TO STRING - Debug uchun
  // ===========================================================================
  
  @override
  String toString() {
    return 'AgentLocationRecord(agentCode: $agentCode, lat: $latitude, lng: $longitude, loggedAt: $loggedAt)';
  }

  // ===========================================================================
  // COPY WITH - Ma'lumotlarni yangilash uchun
  // ===========================================================================
  
  /// Ma'lumotlarni yangilash uchun copyWith metodi
  AgentLocationRecord copyWith({
    String? agentCode,
    String? latitude,
    String? longitude,
    String? agentName,
    String? agentPhone,
    String? region,
    String? deviceId,
    String? deviceName,
    String? deviceManufacturer,
    String? deviceModel,
    String? platform,
    String? osVersion,
    int? screenWidth,
    int? screenHeight,
    String? screenDensity,
    int? ramTotal,
    int? ramAvailable,
    int? storageTotal,
    int? storageAvailable,
    bool? cameraFront,
    bool? cameraBack,
    String? cameraResolution,
    String? appVersion,
    String? appBuildNumber,
    DateTime? appInstallationDate,
    DateTime? appLastUpdate,
    String? accuracy,
    String? altitude,
    String? speed,
    String? heading,
    String? city,
    String? country,
    String? postalCode,
    String? timezone,
    String? locationProvider,
    String? batteryLevel,
    bool? isCharging,
    String? batteryHealth,
    String? batteryTemperature,
    String? batteryVoltage,
    String? signalStrength,
    String? networkType,
    String? wifiSsid,
    String? wifiBssid,
    String? cellularOperator,
    String? cellularNetworkType,
    String? ipAddress,
    String? connectionType,
    String? accelerometerX,
    String? accelerometerY,
    String? accelerometerZ,
    String? gyroscopeX,
    String? gyroscopeY,
    String? gyroscopeZ,
    String? magnetometerX,
    String? magnetometerY,
    String? magnetometerZ,
    String? proximitySensor,
    String? lightSensor,
    String? temperature,
    String? humidity,
    String? pressure,
    String? deviceFingerprint,
    bool? isRooted,
    bool? isJailbroken,
    bool? encryptionEnabled,
    String? screenLockType,
    DateTime? loggedAt,
    String? address,
    String? note,
    Map<String, dynamic>? metadata,
  }) {
    return AgentLocationRecord(
      agentCode: agentCode ?? this.agentCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      agentName: agentName ?? this.agentName,
      agentPhone: agentPhone ?? this.agentPhone,
      region: region ?? this.region,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceManufacturer: deviceManufacturer ?? this.deviceManufacturer,
      deviceModel: deviceModel ?? this.deviceModel,
      platform: platform ?? this.platform,
      osVersion: osVersion ?? this.osVersion,
      screenWidth: screenWidth ?? this.screenWidth,
      screenHeight: screenHeight ?? this.screenHeight,
      screenDensity: screenDensity ?? this.screenDensity,
      ramTotal: ramTotal ?? this.ramTotal,
      ramAvailable: ramAvailable ?? this.ramAvailable,
      storageTotal: storageTotal ?? this.storageTotal,
      storageAvailable: storageAvailable ?? this.storageAvailable,
      cameraFront: cameraFront ?? this.cameraFront,
      cameraBack: cameraBack ?? this.cameraBack,
      cameraResolution: cameraResolution ?? this.cameraResolution,
      appVersion: appVersion ?? this.appVersion,
      appBuildNumber: appBuildNumber ?? this.appBuildNumber,
      appInstallationDate: appInstallationDate ?? this.appInstallationDate,
      appLastUpdate: appLastUpdate ?? this.appLastUpdate,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      city: city ?? this.city,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      timezone: timezone ?? this.timezone,
      locationProvider: locationProvider ?? this.locationProvider,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      batteryHealth: batteryHealth ?? this.batteryHealth,
      batteryTemperature: batteryTemperature ?? this.batteryTemperature,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      signalStrength: signalStrength ?? this.signalStrength,
      networkType: networkType ?? this.networkType,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      wifiBssid: wifiBssid ?? this.wifiBssid,
      cellularOperator: cellularOperator ?? this.cellularOperator,
      cellularNetworkType: cellularNetworkType ?? this.cellularNetworkType,
      ipAddress: ipAddress ?? this.ipAddress,
      connectionType: connectionType ?? this.connectionType,
      accelerometerX: accelerometerX ?? this.accelerometerX,
      accelerometerY: accelerometerY ?? this.accelerometerY,
      accelerometerZ: accelerometerZ ?? this.accelerometerZ,
      gyroscopeX: gyroscopeX ?? this.gyroscopeX,
      gyroscopeY: gyroscopeY ?? this.gyroscopeY,
      gyroscopeZ: gyroscopeZ ?? this.gyroscopeZ,
      magnetometerX: magnetometerX ?? this.magnetometerX,
      magnetometerY: magnetometerY ?? this.magnetometerY,
      magnetometerZ: magnetometerZ ?? this.magnetometerZ,
      proximitySensor: proximitySensor ?? this.proximitySensor,
      lightSensor: lightSensor ?? this.lightSensor,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      pressure: pressure ?? this.pressure,
      deviceFingerprint: deviceFingerprint ?? this.deviceFingerprint,
      isRooted: isRooted ?? this.isRooted,
      isJailbroken: isJailbroken ?? this.isJailbroken,
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      screenLockType: screenLockType ?? this.screenLockType,
      loggedAt: loggedAt ?? this.loggedAt,
      address: address ?? this.address,
      note: note ?? this.note,
      metadata: metadata ?? this.metadata,
    );
  }
}
