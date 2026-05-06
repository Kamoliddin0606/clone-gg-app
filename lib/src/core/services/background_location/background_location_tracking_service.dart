// =============================================================================
// Background Location Tracking Service (V2 — yangi server)
// =============================================================================
//
// Bu service fonda joylashuv ma'lumotlarini yig'ib, yangi serverga
// (telemetry endpointlariga) yuboradi.
//
// Asosiy xususiyatlar:
// - Tracking policy server tomondan boshqariladi (TrackingPolicyService)
// - Mobile lokal pre-filtering qiladi (active hours/days, distance, accuracy)
// - Offline rejimda yozuvlar SharedPreferences'ga saqlanadi va internet
//   qaytarilganda batch sifatida yuboriladi
// - V2 JWT tokenlar ishlatiladi (TokenService.ensureValidV2Token)
//
// Endpoint: POST {V2}/api/mobile/v1/telemetry/pings/
// =============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/helpers/device_data_collector.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/telemetry_v2/device_registration_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/telemetry_v2/rest_logging.dart';
import 'package:gloria_marketing_flutter/src/core/services/telemetry_v2/models/telemetry_accepted_response.dart';
import 'package:gloria_marketing_flutter/src/core/services/telemetry_v2/models/telemetry_ping_request.dart';
import 'package:gloria_marketing_flutter/src/core/services/telemetry_v2/models/tracking_policy.dart';
import 'package:gloria_marketing_flutter/src/core/services/telemetry_v2/models/tracking_policy_envelope.dart';
import 'package:gloria_marketing_flutter/src/core/services/telemetry_v2/tracking_policy_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';

class BackgroundLocationTrackingService {
  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  /// Telemetry pings endpoint (yangi server).
  static const String _telemetryEndpoint = '/api/mobile/v1/telemetry/pings/';

  /// Default interval — server policy yo'q bo'lganda yoki keluvchi qiymat 0 bo'lsa.
  static const int _defaultIntervalSeconds = 60;

  /// Minimum interval — juda tez-tez so'rov yuborilmasligi uchun.
  static const int _minIntervalSeconds = 10;

  /// Policyni qayta yuklash chastotasi (foreground yoki resume da).
  static const Duration _policyRefreshInterval = Duration(minutes: 15);

  /// V2 offline queue keyi (yangi format — TelemetryPingRequest JSON).
  static const String _offlineQueueKey = 'background_location_v2_offline_queue';

  /// Maksimal queue hajmi — undan oshsa eng eski yozuvlar tushib qoladi.
  static const int _offlineQueueMaxSize = 1000;

  /// Bir batch'da yuboriladigan maksimum yozuv.
  static const int _batchUploadMaxSize = 100;

  static const String _lastLocationUpdateKey = 'background_location_v2_last_update';
  static const String _trackingEnabledKey = 'background_location_tracking_enabled';

  // ===========================================================================
  // DEPENDENCIES
  // ===========================================================================

  final SharedPreferencesService _prefs;
  final TokenService _tokenService;
  // dbService eski sales_req_permissions fallback uchun saqlanadi.
  // Yangi serverdan policy kelmasa, eski jadvaldan interval o'qiladi.
  // ignore: unused_field
  final ApiDatabaseService _dbService;
  final TrackingPolicyService _policyService;
  final DeviceRegistrationService _deviceRegistrationService;
  final DeviceDataCollector _deviceDataCollector = DeviceDataCollector();
  final Connectivity _connectivity = Connectivity();
  final Dio _dio;

  // ===========================================================================
  // STATE
  // ===========================================================================

  Timer? _locationTimer;
  Timer? _policyTimer;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isInitialized = false;
  bool _isTrackingActive = false;

  int _currentIntervalSeconds = _defaultIntervalSeconds;
  Position? _lastPosition;
  Position? _lastSentPosition;

  /// Cached app info — payload yasashda ishlatiladi.
  PackageInfo? _packageInfo;

  /// Offline queue (RAM) — SharedPreferences bilan sinxronlanadi.
  List<TelemetryPingRequest> _offlineQueue = [];

  /// Parallel uploadlarni oldini olish uchun mutex bayrog'i.
  bool _isSending = false;

  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================

  BackgroundLocationTrackingService({
    required SharedPreferencesService prefs,
    required TokenService tokenService,
    required ApiDatabaseService dbService,
    required TrackingPolicyService policyService,
    required DeviceRegistrationService deviceRegistrationService,
    Dio? dio,
  })  : _prefs = prefs,
        _tokenService = tokenService,
        _dbService = dbService,
        _policyService = policyService,
        _deviceRegistrationService = deviceRegistrationService,
        _dio = dio ?? Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    attachRestLogger(_dio, 'TELEMETRY');
  }

  // ===========================================================================
  // PUBLIC GETTERS (backward-compatible)
  // ===========================================================================

  bool get isTrackingActive => _isTrackingActive;
  int get currentIntervalSeconds => _currentIntervalSeconds;
  int get offlineQueueSize => _offlineQueue.length;

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;

      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════════════');
        print('BackgroundLocationTrackingService: Initializing (V2)...');
        print('═══════════════════════════════════════════════════════════════');
      }

      await _loadOfflineQueue();
      _setupConnectivityListener();

      // Cached policyni yuklash (offline-first). Tarmoq bor bo'lsa
      // startTracking() ichida yangi policy fetch qilinadi.
      final cachedEnvelope = await _policyService.loadFromCache();
      if (cachedEnvelope != null) {
        _applyPolicyInterval(cachedEnvelope.policy);
      }

      try {
        _packageInfo = await PackageInfo.fromPlatform();
      } catch (_) {
        _packageInfo = null;
      }

      _isInitialized = true;

      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Initialized. interval=$_currentIntervalSeconds s, queue=${_offlineQueue.length}');
      }
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: init error: $e\n$st');
      }
      return false;
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isConnected = results.any((r) => r != ConnectivityResult.none);
    if (kDebugMode) {
      print('BackgroundLocationTrackingService: Connectivity changed connected=$isConnected');
    }
    if (isConnected && _offlineQueue.isNotEmpty) {
      _sendOfflineQueue();
    }
  }

  // ===========================================================================
  // TRACKING CONTROL
  // ===========================================================================

  Future<bool> startTracking() async {
    try {
      if (!_isInitialized) {
        final ok = await initialize();
        if (!ok) return false;
      }
      if (_isTrackingActive) return true;

      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: permission not granted');
        }
        return false;
      }

      // Policy va device registration'ni parallel chaqirish.
      // Failure-tolerant — yangi server hali tayyor bo'lmasligi mumkin.
      // ignore: unawaited_futures
      _refreshPolicy();
      // ignore: unawaited_futures
      _deviceRegistrationService.register();

      // Birinchi ping (policy va token mavjud bo'lsa darhol yuboradi).
      await _updateAndSendLocation();

      _startLocationTimer();
      _startPositionStream();
      _startPolicyTimer();

      await _prefs.preferences.setBool(_trackingEnabledKey, true);
      _isTrackingActive = true;

      if (kDebugMode) {
        print('BackgroundLocationTrackingService: tracking started');
      }
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: startTracking error: $e\n$st');
      }
      return false;
    }
  }

  Future<void> stopTracking() async {
    try {
      _locationTimer?.cancel();
      _locationTimer = null;
      _policyTimer?.cancel();
      _policyTimer = null;
      await _positionStream?.cancel();
      _positionStream = null;
      await _prefs.preferences.setBool(_trackingEnabledKey, false);
      _isTrackingActive = false;

      if (kDebugMode) {
        print('BackgroundLocationTrackingService: tracking stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: stopTracking error: $e');
      }
    }
  }

  Future<void> dispose() async {
    try {
      _locationTimer?.cancel();
      _policyTimer?.cancel();
      await _positionStream?.cancel();
      await _connectivitySubscription?.cancel();
      _locationTimer = null;
      _policyTimer = null;
      _positionStream = null;
      _connectivitySubscription = null;
      _isInitialized = false;
      _isTrackingActive = false;
    } catch (e) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: dispose error: $e');
      }
    }
  }

  // ===========================================================================
  // PERMISSION
  // ===========================================================================

  Future<bool> _checkLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return false;
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  // ===========================================================================
  // TIMERS
  // ===========================================================================

  void _startLocationTimer() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      Duration(seconds: _currentIntervalSeconds),
      (_) => _updateAndSendLocation(),
    );
    if (kDebugMode) {
      print('BackgroundLocationTrackingService: location timer started ${_currentIntervalSeconds}s');
    }
  }

  void _startPolicyTimer() {
    _policyTimer?.cancel();
    _policyTimer = Timer.periodic(_policyRefreshInterval, (_) => _refreshPolicy());
  }

  void _startPositionStream() {
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    ).listen(
      (Position position) {
        _lastPosition = position;
      },
      onError: (e) {
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: position stream error: $e');
        }
      },
    );
  }

  Future<void> _refreshPolicy() async {
    try {
      final envelope = await _policyService.fetchPolicy();
      if (envelope != null) {
        _applyPolicyInterval(envelope.policy);
      }
    } catch (e) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: refreshPolicy error: $e');
      }
    }
  }

  void _applyPolicyInterval(TrackingPolicy policy) {
    final raw = policy.gpsIntervalSeconds;
    if (raw <= 0) return; // policy kelgan, lekin interval belgilanmagan
    final clamped = raw < _minIntervalSeconds ? _minIntervalSeconds : raw;
    if (clamped == _currentIntervalSeconds) return;
    _currentIntervalSeconds = clamped;
    if (_isTrackingActive) {
      _startLocationTimer();
    }
    if (kDebugMode) {
      print('BackgroundLocationTrackingService: applied interval $_currentIntervalSeconds s');
    }
  }

  // ===========================================================================
  // LOCATION UPDATE & SEND
  // ===========================================================================

  Future<void> _updateAndSendLocation() async {
    if (_isSending) return;
    _isSending = true;
    try {
      // Step 0: read policy from RAM cache (no network).
      final envelope = _policyService.cached ?? TrackingPolicyEnvelope.defaultOff();
      final policy = envelope.policy;
      final cacheStatus = _policyService.cached == null ? 'DEFAULT_OFF (no cache)' : 'CACHED';
      restLog('GPS', '┌─ tick @ ${DateTime.now().toIso8601String()}');
      restLog('GPS', '│ policy source=$cacheStatus → ${envelope.source.toServerValue()} rev=${envelope.revision}');
      restLog('GPS', '│ rules: is_active=${policy.isActive} gps_enabled=${policy.gpsEnabled} '
          'interval=${policy.gpsIntervalSeconds}s '
          'min_distance=${policy.gpsMinDistanceMeters}m '
          'min_accuracy=${policy.gpsMinAccuracyMeters}m');
      restLog('GPS', '│ window: hours=${policy.activeHoursStart ?? "*"}..${policy.activeHoursEnd ?? "*"} '
          'days=${policy.activeDays.isEmpty ? "[every]" : policy.activeDays}');

      // FILTER 1: gps_enabled + is_active
      final shouldCollect = _policyService.shouldCollectGps(policy);
      restLog('GPS', '│ filter[1/5] shouldCollectGps → ${shouldCollect ? "PASS" : "FAIL"}');
      if (!shouldCollect) {
        restLog('GPS', '└─ SKIP: policy disabled (is_active=${policy.isActive}, gps_enabled=${policy.gpsEnabled})');
        return;
      }

      // FILTER 2: active_hours
      final now = DateTime.now();
      final hoursOk = _policyService.isWithinActiveHours(policy, now);
      final nowHm = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      restLog('GPS', '│ filter[2/5] isWithinActiveHours (now=$nowHm) → ${hoursOk ? "PASS" : "FAIL"}');
      if (!hoursOk) {
        restLog('GPS', '└─ SKIP: outside active hours ${policy.activeHoursStart}..${policy.activeHoursEnd}');
        return;
      }

      // FILTER 3: active_days
      final daysOk = _policyService.isWithinActiveDays(policy, now);
      const dayCodes = ['mon','tue','wed','thu','fri','sat','sun'];
      final todayCode = dayCodes[(now.weekday - 1).clamp(0, 6)];
      restLog('GPS', '│ filter[3/5] isWithinActiveDays (today=$todayCode) → ${daysOk ? "PASS" : "FAIL"}');
      if (!daysOk) {
        restLog('GPS', '└─ SKIP: today=$todayCode not in ${policy.activeDays}');
        return;
      }

      // GPS request
      restLog('GPS', '│ requesting fresh position (high-accuracy, 15s timeout)');
      final position = await _getCurrentPosition();
      if (position == null) {
        restLog('GPS', '└─ no position obtained (Geolocator returned null and no cached fallback)');
        return;
      }
      restLog('GPS', '│ got position lat=${position.latitude.toStringAsFixed(6)} '
          'lng=${position.longitude.toStringAsFixed(6)} '
          'acc=${position.accuracy.toStringAsFixed(1)}m '
          'alt=${position.altitude.toStringAsFixed(1)}m '
          'speed=${position.speed.toStringAsFixed(2)}m/s '
          'heading=${position.heading.toStringAsFixed(1)}°');
      _lastPosition = position;

      // FILTER 4: gps_min_accuracy_meters
      final accOk = _policyService.isAccuracyAcceptable(policy, position.accuracy);
      restLog('GPS', '│ filter[4/5] isAccuracyAcceptable '
          '(${position.accuracy.toStringAsFixed(1)}m vs limit ${policy.gpsMinAccuracyMeters}m) → ${accOk ? "PASS" : "FAIL"}');
      if (!accOk) {
        restLog('GPS', '└─ DROP: accuracy ${position.accuracy.toStringAsFixed(1)}m > ${policy.gpsMinAccuracyMeters}m');
        return;
      }

      // FILTER 5: gps_min_distance_meters
      final distOk = _policyService.isDistanceAcceptable(policy, _lastSentPosition, position);
      final delta = _lastSentPosition == null
          ? 'n/a (first fix)'
          : '${Geolocator.distanceBetween(_lastSentPosition!.latitude, _lastSentPosition!.longitude, position.latitude, position.longitude).toStringAsFixed(1)}m';
      restLog('GPS', '│ filter[5/5] isDistanceAcceptable '
          '(moved=$delta vs min ${policy.gpsMinDistanceMeters}m) → ${distOk ? "PASS" : "FAIL"}');
      if (!distOk) {
        restLog('GPS', '└─ DROP: moved $delta < ${policy.gpsMinDistanceMeters}m');
        return;
      }
      restLog('GPS', '│ ALL FILTERS PASSED → building telemetry payload');

      // Build payload
      restLog('GPS', '│ collect flags: device=${policy.collectDeviceInfo} '
          'battery=${policy.collectBattery} network=${policy.collectNetwork} sensors=${policy.collectSensors}');
      final ping = await _buildTelemetryPing(position, policy);
      restLog('GPS', '│ payload fields=${ping.toJson().length} → POST telemetry');

      final ok = await _sendSinglePing(ping);
      if (ok) {
        _lastSentPosition = position;
        restLog('GPS', '└─ SENT ✅ server accepted ping');
      } else {
        await _addToOfflineQueue(ping);
        restLog('GPS', '└─ FAIL ⚠️ queued offline (size=${_offlineQueue.length})');
      }

      await _prefs.preferences.setString(
        _lastLocationUpdateKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e, st) {
      restLog('GPS', 'ERROR _updateAndSendLocation: $e\n$st');
    } finally {
      _isSending = false;
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      restLog('GPS', 'getCurrentPosition error: $e (falling back to last cached)');
      return _lastPosition;
    }
  }

  Future<TelemetryPingRequest> _buildTelemetryPing(
    Position position,
    TrackingPolicy policy,
  ) async {
    final agentCode = _prefs.getUserCode() ?? '';
    final agentName = _prefs.getUserName();
    final agentPhone = _prefs.getTelegramID();    // best-effort: stored phone-like ID
    final region = _prefs.getServerName();         // server/region name (best-effort)
    final deviceData = await _deviceDataCollector.collectAllData();
    final pkg = _packageInfo ?? await _safePackageInfo();

    final lat = position.latitude.toStringAsFixed(6);
    final lng = position.longitude.toStringAsFixed(6);

    String? toFixedString(double? v, int n) => v?.toStringAsFixed(n);

    String? batteryLevel;
    bool? isCharging;
    String? batteryHealth;
    String? batteryTemperature;
    String? batteryVoltage;
    if (policy.collectBattery) {
      batteryLevel = deviceData['battery_level']?.toString();
      isCharging = deviceData['is_charging'] as bool?;
      batteryHealth = deviceData['battery_health'] as String?;
      batteryTemperature = deviceData['battery_temperature']?.toString();
      batteryVoltage = deviceData['battery_voltage']?.toString();
    }

    String? networkType;
    String? wifiSsid;
    String? wifiBssid;
    String? cellularOperator;
    String? cellularNetworkType;
    String? ipAddress;
    String? connectionType;
    String? signalStrength;
    if (policy.collectNetwork) {
      networkType = deviceData['network_type'] as String?;
      wifiSsid = deviceData['wifi_ssid'] as String?;
      wifiBssid = deviceData['wifi_bssid'] as String?;
      cellularOperator = deviceData['cellular_operator'] as String?;
      cellularNetworkType = deviceData['cellular_network_type'] as String?;
      ipAddress = deviceData['ip_address'] as String?;
      connectionType = deviceData['connection_type'] as String?;
      signalStrength = deviceData['signal_strength']?.toString();
    }

    String? deviceId;
    String? deviceName;
    String? deviceManufacturer;
    String? deviceModel;
    String? deviceFingerprint;
    String? platform;
    String? osVersion;
    int? screenWidth;
    int? screenHeight;
    String? screenDensity;
    String? appVersion;
    String? appBuildNumber;
    bool? isRooted;
    bool? isJailbroken;
    bool? encryptionEnabled;
    String? screenLockType;
    if (policy.collectDeviceInfo) {
      deviceId = deviceData['device_id'] as String?;
      deviceName = deviceData['device_name'] as String?;
      deviceManufacturer = deviceData['device_manufacturer'] as String?;
      deviceModel = deviceData['device_model'] as String?;
      deviceFingerprint = deviceData['device_fingerprint'] as String?;
      platform = _normalizePlatform(deviceData['platform'] as String?);
      osVersion = deviceData['os_version'] as String?;
      screenWidth = deviceData['screen_width'] as int?;
      screenHeight = deviceData['screen_height'] as int?;
      screenDensity = deviceData['screen_density'] as String?;
      appVersion = pkg?.version;
      appBuildNumber = pkg?.buildNumber;
      isRooted = deviceData['is_rooted'] as bool?;
      isJailbroken = deviceData['is_jailbroken'] as bool?;
      encryptionEnabled = deviceData['encryption_enabled'] as bool?;
      screenLockType = deviceData['screen_lock_type'] as String?;
    } else {
      // Hatto collect_device_info=false bo'lsa ham device_id va platform ni
      // jo'natamiz — server LocationPing'ni Device bilan bog'laydi.
      deviceId = deviceData['device_id'] as String?;
      platform = _normalizePlatform(deviceData['platform'] as String?);
    }

    String? accelerometerX;
    String? accelerometerY;
    String? accelerometerZ;
    String? gyroscopeX;
    String? gyroscopeY;
    String? gyroscopeZ;
    if (policy.collectSensors) {
      accelerometerX = deviceData['accelerometer_x']?.toString();
      accelerometerY = deviceData['accelerometer_y']?.toString();
      accelerometerZ = deviceData['accelerometer_z']?.toString();
      gyroscopeX = deviceData['gyroscope_x']?.toString();
      gyroscopeY = deviceData['gyroscope_y']?.toString();
      gyroscopeZ = deviceData['gyroscope_z']?.toString();
    }

    String? magnetometerX;
    String? magnetometerY;
    String? magnetometerZ;
    String? proximitySensor;
    String? lightSensor;
    String? temperature;
    String? humidity;
    String? pressure;
    if (policy.collectSensors) {
      magnetometerX = deviceData['magnetometer_x']?.toString();
      magnetometerY = deviceData['magnetometer_y']?.toString();
      magnetometerZ = deviceData['magnetometer_z']?.toString();
      proximitySensor = deviceData['proximity_sensor']?.toString();
      lightSensor = deviceData['light_sensor']?.toString();
      temperature = deviceData['temperature']?.toString();
      humidity = deviceData['humidity']?.toString();
      pressure = deviceData['pressure']?.toString();
    }

    int? ramTotal;
    int? ramAvailable;
    int? storageTotal;
    int? storageAvailable;
    bool? cameraFront;
    bool? cameraBack;
    String? cameraResolution;
    if (policy.collectDeviceInfo) {
      ramTotal = deviceData['ram_total'] as int?;
      ramAvailable = deviceData['ram_available'] as int?;
      storageTotal = deviceData['storage_total'] as int?;
      storageAvailable = deviceData['storage_available'] as int?;
      cameraFront = deviceData['camera_front'] as bool?;
      cameraBack = deviceData['camera_back'] as bool?;
      cameraResolution = deviceData['camera_resolution'] as String?;
    }

    return TelemetryPingRequest(
      latitude: lat,
      longitude: lng,
      agentCode: agentCode.isEmpty ? null : agentCode,
      agentName: agentName,
      agentPhone: agentPhone,
      region: region,
      isActive: true,
      isDeleted: false,
      accuracy: toFixedString(position.accuracy, 2),
      altitude: toFixedString(position.altitude, 2),
      speed: toFixedString(position.speed, 2),
      heading: toFixedString(position.heading, 2),
      locationProvider: 'geolocator',
      timezone: deviceData['timezone'] as String?,
      deviceId: deviceId,
      deviceName: deviceName,
      deviceManufacturer: deviceManufacturer,
      deviceModel: deviceModel,
      deviceFingerprint: deviceFingerprint,
      platform: platform,
      osVersion: osVersion,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      screenDensity: screenDensity,
      ramTotal: ramTotal,
      ramAvailable: ramAvailable,
      storageTotal: storageTotal,
      storageAvailable: storageAvailable,
      cameraFront: cameraFront,
      cameraBack: cameraBack,
      cameraResolution: cameraResolution,
      appVersion: appVersion,
      appBuildNumber: appBuildNumber,
      batteryLevel: batteryLevel,
      isCharging: isCharging,
      batteryHealth: batteryHealth,
      batteryTemperature: batteryTemperature,
      batteryVoltage: batteryVoltage,
      signalStrength: signalStrength,
      networkType: networkType,
      wifiSsid: wifiSsid,
      wifiBssid: wifiBssid,
      cellularOperator: cellularOperator,
      cellularNetworkType: cellularNetworkType,
      ipAddress: ipAddress,
      connectionType: connectionType,
      accelerometerX: accelerometerX,
      accelerometerY: accelerometerY,
      accelerometerZ: accelerometerZ,
      gyroscopeX: gyroscopeX,
      gyroscopeY: gyroscopeY,
      gyroscopeZ: gyroscopeZ,
      magnetometerX: magnetometerX,
      magnetometerY: magnetometerY,
      magnetometerZ: magnetometerZ,
      proximitySensor: proximitySensor,
      lightSensor: lightSensor,
      temperature: temperature,
      humidity: humidity,
      pressure: pressure,
      isRooted: isRooted,
      isJailbroken: isJailbroken,
      encryptionEnabled: encryptionEnabled,
      screenLockType: screenLockType,
      loggedAt: DateTime.now().toUtc(),
    );
  }

  String? _normalizePlatform(String? raw) {
    if (raw == null) return null;
    final lower = raw.toLowerCase();
    if (lower.contains('android')) return 'android';
    if (lower.contains('ios')) return 'ios';
    if (lower.contains('web')) return 'web';
    return 'other';
  }

  Future<PackageInfo?> _safePackageInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      return _packageInfo;
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // API COMMUNICATION
  // ===========================================================================

  /// Bitta pingni yuborish (single payload).
  Future<bool> _sendSinglePing(TelemetryPingRequest ping) async {
    return _postPings([ping], asBatch: false);
  }

  /// Bir nechta pingni batch sifatida yuborish (`{"pings": [...]}`).
  Future<bool> _postPings(
    List<TelemetryPingRequest> pings, {
    required bool asBatch,
  }) async {
    if (pings.isEmpty) return true;
    try {
      final token = await _tokenService.ensureValidV2Token();
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: no V2 token, queueing');
        }
        return false;
      }

      final isConnected = await _deviceDataCollector.isConnectedToInternet();
      if (!isConnected) return false;

      final url = '${TokenService.v2BaseUrl}$_telemetryEndpoint';
      final body = asBatch
          ? <String, dynamic>{'pings': pings.map((p) => p.toJson()).toList()}
          : pings.first.toJson();

      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map) {
          final parsed = TelemetryAcceptedResponse.fromJson(
            Map<String, dynamic>.from(response.data as Map),
          );
          if (kDebugMode) {
            print('BackgroundLocationTrackingService: accepted=${parsed.acceptedCount} rejected=${parsed.rejectedCount}');
            if (parsed.rejected.isNotEmpty) {
              for (final r in parsed.rejected) {
                print('  rejected[${r.index}] ${r.reason}');
              }
            }
          }
        }
        return true;
      }

      if (kDebugMode) {
        print('BackgroundLocationTrackingService: postPings status=${response.statusCode} data=${response.data}');
      }
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: postPings DioException ${e.type} status=${e.response?.statusCode}');
      }
      return false;
    } catch (e, st) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: postPings error: $e\n$st');
      }
      return false;
    }
  }

  // ===========================================================================
  // OFFLINE QUEUE
  // ===========================================================================

  Future<void> _addToOfflineQueue(TelemetryPingRequest ping) async {
    try {
      _offlineQueue.add(ping);
      if (_offlineQueue.length > _offlineQueueMaxSize) {
        _offlineQueue.removeRange(0, _offlineQueue.length - _offlineQueueMaxSize);
      }
      await _saveOfflineQueue();
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: queued ping. size=${_offlineQueue.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: addToOfflineQueue error: $e');
      }
    }
  }

  Future<void> _saveOfflineQueue() async {
    try {
      final list = _offlineQueue.map((p) => p.toJson()).toList();
      await _prefs.preferences.setString(_offlineQueueKey, jsonEncode(list));
    } catch (e) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: saveOfflineQueue error: $e');
      }
    }
  }

  Future<void> _loadOfflineQueue() async {
    try {
      final raw = _prefs.preferences.getString(_offlineQueueKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _offlineQueue = decoded
            .whereType<Map>()
            .map((e) => TelemetryPingRequest.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: loadOfflineQueue error: $e');
      }
      _offlineQueue = [];
    }
  }

  Future<void> _sendOfflineQueue() async {
    if (_offlineQueue.isEmpty || _isSending) return;
    _isSending = true;
    try {
      while (_offlineQueue.isNotEmpty) {
        final batch = _offlineQueue.take(_batchUploadMaxSize).toList();
        final ok = await _postPings(batch, asBatch: true);
        if (!ok) break;
        _offlineQueue.removeRange(0, batch.length);
      }
      await _saveOfflineQueue();
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: offline queue flushed. remaining=${_offlineQueue.length}');
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: sendOfflineQueue error: $e\n$st');
      }
    } finally {
      _isSending = false;
    }
  }

  Future<void> clearOfflineQueue() async {
    _offlineQueue.clear();
    await _prefs.preferences.remove(_offlineQueueKey);
  }

  // ===========================================================================
  // PUBLIC API (backward-compatible signatures)
  // ===========================================================================

  /// Tashqi kod (masalan, server policy update kelgan SOAP push) chaqiradigan
  /// metod — interval yangilanadi va timer qayta tushiriladi. Endi asosiy
  /// manba TrackingPolicyService bo'lsa-da, bu metod saqlanadi (backward compat).
  Future<void> updateInterval(int intervalSeconds) async {
    if (intervalSeconds <= 0) return;
    final clamped =
        intervalSeconds < _minIntervalSeconds ? _minIntervalSeconds : intervalSeconds;
    if (clamped == _currentIntervalSeconds) return;
    _currentIntervalSeconds = clamped;
    if (_isTrackingActive) {
      _startLocationTimer();
    }
  }

  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'isTrackingActive': _isTrackingActive,
      'currentIntervalSeconds': _currentIntervalSeconds,
      'offlineQueueSize': _offlineQueue.length,
      'lastPosition': _lastPosition != null
          ? '${_lastPosition!.latitude}, ${_lastPosition!.longitude}'
          : null,
      'lastUpdate': _prefs.preferences.getString(_lastLocationUpdateKey),
      'cachedPolicySource': _policyService.cached?.source.toServerValue(),
    };
  }
}
