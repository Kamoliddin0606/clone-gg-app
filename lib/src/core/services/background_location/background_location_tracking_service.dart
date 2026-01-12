/// =============================================================================
/// Background Location Tracking Service
/// =============================================================================
/// 
/// Bu service fonda (background) joylashuv ma'lumotlarini kuzatib,
/// serverga yuborish uchun javobgardir.
/// 
/// Asosiy xususiyatlar:
/// - Ilova aktiv bo'lmasa ham ishlaydi (background mode)
/// - Serverdan olingan LocationUpdateInterval vaqti bo'yicha ishlaydi
/// - Offline rejimda ma'lumotlarni saqlaydi va keyinroq yuboradi
/// - Qurilma, tarmoq, batareya ma'lumotlarini ham to'playdi
/// 
/// API Endpoint: http://178.218.200.120:1596/api/v1/agent-location/
/// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/models/agent_location_record.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/helpers/device_data_collector.dart';

/// Background Location Tracking Service
/// 
/// Bu service quyidagi vazifalarni bajaradi:
/// 1. Joylashuv ma'lumotlarini belgilangan vaqt oralig'ida olish
/// 2. Qurilma, tarmoq, batareya ma'lumotlarini to'plash
/// 3. Ma'lumotlarni serverga yuborish (REST API)
/// 4. Offline rejimda ma'lumotlarni saqlash (queue)
/// 5. Internet qayta ulanganda saqlangan ma'lumotlarni yuborish
/// 
/// Foydalanish:
/// ```dart
/// final service = BackgroundLocationTrackingService(
///   prefs: prefsService,
///   tokenService: tokenService,
///   dbService: dbService,
///   dio: dio,
/// );
/// await service.initialize();
/// await service.startTracking();
/// ```
class BackgroundLocationTrackingService {
  // ===========================================================================
  // CONSTANTS
  // ===========================================================================
  
  /// API base URL - location ma'lumotlarini yuborish uchun
  static const String _apiBaseUrl = 'http://178.218.200.120:1596';
  
  /// API endpoint - agent joylashuvini yuborish
  static const String _locationEndpoint = '/api/v1/agent-location/';
  
  /// Default interval (sekundlarda) - agar serverdan kelgan qiymat 0 bo'lsa
  static const int _defaultIntervalSeconds = 60;
  
  /// Minimum interval (sekundlarda) - juda tez-tez so'rov yuborilmasligi uchun
  static const int _minIntervalSeconds = 10;
  
  /// Offline queue key - SharedPreferences uchun
  static const String _offlineQueueKey = 'background_location_offline_queue';
  
  /// Last location update key
  static const String _lastLocationUpdateKey = 'background_location_last_update';
  
  /// Tracking enabled key
  static const String _trackingEnabledKey = 'background_location_tracking_enabled';

  // ===========================================================================
  // DEPENDENCIES
  // ===========================================================================
  
  /// SharedPreferences service - ma'lumotlarni saqlash uchun
  final SharedPreferencesService _prefs;
  
  /// Token service - API autentifikatsiya uchun
  final TokenService _tokenService;
  
  /// Database service - sales_req_permissions dan interval olish uchun
  final ApiDatabaseService _dbService;
  
  /// Dio instance - HTTP so'rovlar uchun
  final Dio _dio;
  
  /// Device data collector - qurilma ma'lumotlarini to'plash uchun
  final DeviceDataCollector _deviceDataCollector = DeviceDataCollector();
  
  /// Connectivity - tarmoq holatini kuzatish uchun
  final Connectivity _connectivity = Connectivity();

  // ===========================================================================
  // STATE VARIABLES
  // ===========================================================================
  
  /// Location tracking timer - belgilangan vaqt oralig'ida ishlaydi
  Timer? _locationTimer;
  
  /// Position stream subscription - joylashuv o'zgarishlarini kuzatish
  StreamSubscription<Position>? _positionStream;
  
  /// Connectivity subscription - tarmoq holatini kuzatish
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  /// Service initialized flag
  bool _isInitialized = false;
  
  /// Tracking active flag
  bool _isTrackingActive = false;
  
  /// Current interval (sekundlarda)
  int _currentIntervalSeconds = _defaultIntervalSeconds;
  
  /// Last known position - oxirgi joylashuv
  Position? _lastPosition;
  
  /// Offline queue - internet yo'q paytida saqlanadigan ma'lumotlar
  List<AgentLocationRecord> _offlineQueue = [];
  
  /// Is currently sending - parallel so'rovlar oldini olish
  bool _isSending = false;

  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================
  
  /// BackgroundLocationTrackingService konstruktori
  /// 
  /// Parametrlar:
  /// - [prefs] - SharedPreferencesService instance
  /// - [tokenService] - TokenService instance (API autentifikatsiya)
  /// - [dbService] - ApiDatabaseService instance (interval olish)
  BackgroundLocationTrackingService({
    required SharedPreferencesService prefs,
    required TokenService tokenService,
    required ApiDatabaseService dbService,
    Dio? dio,
  })  : _prefs = prefs,
        _tokenService = tokenService,
        _dbService = dbService,
        _dio = dio ?? Dio() {
    // Alohida Dio instance - boshqa service'lar interceptorlaridan ta'sirlanmaydi
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================
  
  /// Service'ni ishga tushirish
  /// 
  /// Bu metod quyidagi ishlarni bajaradi:
  /// 1. Offline queue'ni yuklash
  /// 2. Connectivity listener'ni sozlash
  /// 3. Interval'ni database'dan olish
  /// 
  /// Qaytaradi: Future<bool> - muvaffaqiyatli ishga tushirilganmi
  Future<bool> initialize() async {
    try {
      if (_isInitialized) {
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: Already initialized');
        }
        return true;
      }

      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════════════');
        print('BackgroundLocationTrackingService: Initializing...');
        print('═══════════════════════════════════════════════════════════════');
      }

      // 1. Offline queue'ni yuklash
      await _loadOfflineQueue();

      // 2. Connectivity listener'ni sozlash
      _setupConnectivityListener();

      // 3. Interval'ni database'dan olish
      await _loadIntervalFromDatabase();

      _isInitialized = true;

      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Initialized successfully');
        print('BackgroundLocationTrackingService: Current interval: $_currentIntervalSeconds seconds');
        print('BackgroundLocationTrackingService: Offline queue size: ${_offlineQueue.length}');
      }

      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Initialization error: $e');
        print('BackgroundLocationTrackingService: Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Database'dan interval'ni yuklash
  Future<void> _loadIntervalFromDatabase() async {
    try {
      final userCode = _prefs.getUserCode();
      if (userCode == null || userCode.isEmpty) {
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: No user code, using default interval');
        }
        return;
      }

      // sales_req_permissions jadvalidan interval'ni olish
      final permissions = await _dbService.getSalesReqPermissions(userCode);
      if (permissions != null) {
        // SalesReqPermissions obyektidan locationUpdateInterval ni olish
        final interval = permissions.locationUpdateInterval;
        if (interval > 0) {
          // Minimum interval'ni tekshirish
          _currentIntervalSeconds = interval < _minIntervalSeconds 
              ? _minIntervalSeconds 
              : interval;
          
          if (kDebugMode) {
            print('BackgroundLocationTrackingService: Loaded interval from DB: $_currentIntervalSeconds seconds');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Error loading interval: $e');
      }
      // Default interval ishlatiladi
    }
  }

  /// Connectivity listener'ni sozlash
  void _setupConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  /// Connectivity o'zgarganda chaqiriladi
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isConnected = results.any((r) => r != ConnectivityResult.none);
    
    if (kDebugMode) {
      print('BackgroundLocationTrackingService: Connectivity changed - connected: $isConnected');
    }

    if (isConnected && _offlineQueue.isNotEmpty) {
      // Internet qayta ulandi, offline queue'ni yuborish
      _sendOfflineQueue();
    }
  }

  // ===========================================================================
  // TRACKING CONTROL
  // ===========================================================================
  
  /// Joylashuv kuzatishni boshlash
  /// 
  /// Bu metod quyidagi ishlarni bajaradi:
  /// 1. Location permission'ni tekshirish
  /// 2. Timer'ni sozlash
  /// 3. Position stream'ni boshlash
  /// 
  /// Qaytaradi: Future<bool> - muvaffaqiyatli boshlandi mi
  Future<bool> startTracking() async {
    try {
      if (!_isInitialized) {
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: Not initialized, initializing first...');
        }
        final initialized = await initialize();
        if (!initialized) {
          return false;
        }
      }

      if (_isTrackingActive) {
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: Tracking already active');
        }
        return true;
      }

      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════════════');
        print('BackgroundLocationTrackingService: Starting tracking...');
        print('BackgroundLocationTrackingService: Interval: $_currentIntervalSeconds seconds');
        print('═══════════════════════════════════════════════════════════════');
      }

      // 1. Location permission'ni tekshirish
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: Location permission not granted');
        }
        return false;
      }

      // 2. Dastlabki joylashuvni olish va yuborish
      await _updateAndSendLocation();

      // 3. Timer'ni sozlash
      _startLocationTimer();

      // 4. Position stream'ni boshlash (masofaga asoslangan yangilanishlar uchun)
      _startPositionStream();

      // 5. Tracking enabled flag'ni saqlash
      await _prefs.preferences.setBool(_trackingEnabledKey, true);

      _isTrackingActive = true;

      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Tracking started successfully');
      }

      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Error starting tracking: $e');
        print('BackgroundLocationTrackingService: Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Joylashuv kuzatishni to'xtatish
  /// 
  /// Bu metod timer va stream'larni bekor qiladi.
  Future<void> stopTracking() async {
    try {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Stopping tracking...');
      }

      // Timer'ni bekor qilish
      _locationTimer?.cancel();
      _locationTimer = null;

      // Position stream'ni bekor qilish
      await _positionStream?.cancel();
      _positionStream = null;

      // Tracking enabled flag'ni o'chirish
      await _prefs.preferences.setBool(_trackingEnabledKey, false);

      _isTrackingActive = false;

      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Tracking stopped');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Error stopping tracking: $e');
        print('BackgroundLocationTrackingService: Stack trace: $stackTrace');
      }
    }
  }

  /// Tracking holatini tekshirish
  bool get isTrackingActive => _isTrackingActive;

  /// Current interval (sekundlarda)
  int get currentIntervalSeconds => _currentIntervalSeconds;

  // ===========================================================================
  // LOCATION TIMER
  // ===========================================================================
  
  /// Location timer'ni boshlash
  void _startLocationTimer() {
    _locationTimer?.cancel();
    
    _locationTimer = Timer.periodic(
      Duration(seconds: _currentIntervalSeconds),
      (_) async {
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: Timer triggered at ${DateTime.now()}');
        }
        await _updateAndSendLocation();
      },
    );

    if (kDebugMode) {
      print('BackgroundLocationTrackingService: Timer started with ${_currentIntervalSeconds}s interval');
    }
  }

  /// Position stream'ni boshlash
  void _startPositionStream() {
    _positionStream?.cancel();
    
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // 50 metr harakat qilganda yangilash
      ),
    ).listen(
      (Position position) {
        _lastPosition = position;
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: Position stream update: ${position.latitude}, ${position.longitude}');
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: Position stream error: $error');
        }
      },
    );
  }

  // ===========================================================================
  // LOCATION UPDATE & SEND
  // ===========================================================================
  
  /// Joylashuvni yangilash va serverga yuborish
  Future<void> _updateAndSendLocation() async {
    try {
      if (_isSending) {
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: Already sending, skipping...');
        }
        return;
      }

      _isSending = true;

      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Updating and sending location...');
      }

      // 1. Joylashuvni olish
      final position = await _getCurrentPosition();
      if (position == null) {
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: Could not get position');
        }
        _isSending = false;
        return;
      }

      _lastPosition = position;

      // 2. AgentLocationRecord yaratish
      final record = await _buildLocationRecord(position);

      // 3. Serverga yuborish
      final success = await _sendLocationToServer(record);

      if (!success) {
        // Offline queue'ga qo'shish
        await _addToOfflineQueue(record);
      }

      // 4. Last update vaqtini saqlash
      await _prefs.preferences.setString(
        _lastLocationUpdateKey,
        DateTime.now().toIso8601String(),
      );

      _isSending = false;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Error in _updateAndSendLocation: $e');
        print('BackgroundLocationTrackingService: Stack trace: $stackTrace');
      }
      _isSending = false;
    }
  }

  /// Joriy joylashuvni olish
  Future<Position?> _getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Error getting position: $e');
      }
      // Oxirgi ma'lum joylashuvni qaytarish
      return _lastPosition;
    }
  }

  /// AgentLocationRecord yaratish
  Future<AgentLocationRecord> _buildLocationRecord(Position position) async {
    try {
      // Agent ma'lumotlarini olish
      final agentCode = _prefs.getUserCode() ?? '';
      final agentName = _prefs.getUserName();

      // Qurilma ma'lumotlarini to'plash
      final deviceData = await _deviceDataCollector.collectAllData();

      // AgentLocationRecord yaratish
      return AgentLocationRecord(
        // Majburiy maydonlar
        agentCode: agentCode,
        latitude: position.latitude.toStringAsFixed(6),
        longitude: position.longitude.toStringAsFixed(6),
        
        // Agent ma'lumotlari
        agentName: agentName,
        
        // Qurilma ma'lumotlari
        deviceId: deviceData['device_id'] as String?,
        deviceName: deviceData['device_name'] as String?,
        deviceManufacturer: deviceData['device_manufacturer'] as String?,
        deviceModel: deviceData['device_model'] as String?,
        platform: deviceData['platform'] as String?,
        osVersion: deviceData['os_version'] as String?,
        
        // Ekran ma'lumotlari
        screenWidth: deviceData['screen_width'] as int?,
        screenHeight: deviceData['screen_height'] as int?,
        screenDensity: deviceData['screen_density'] as String?,
        
        // Joylashuv aniqligi
        accuracy: position.accuracy.toStringAsFixed(2),
        altitude: position.altitude.toStringAsFixed(2),
        speed: position.speed.toStringAsFixed(2),
        heading: position.heading.toStringAsFixed(2),
        
        // Tarmoq ma'lumotlari
        networkType: deviceData['network_type'] as String?,
        connectionType: deviceData['connection_type'] as String?,
        
        // Vaqt mintaqasi
        timezone: deviceData['timezone'] as String?,
        
        // Lokatsiya manbasi
        locationProvider: 'geolocator',
        
        // Qurilma fingerprint
        deviceFingerprint: deviceData['device_fingerprint'] as String?,
        
        // Xavfsizlik
        isRooted: deviceData['is_rooted'] as bool?,
        isJailbroken: deviceData['is_jailbroken'] as bool?,
        
        // Batareya ma'lumotlari
        batteryLevel: deviceData['battery_level']?.toString(),
        isCharging: deviceData['is_charging'] as bool?,
        batteryHealth: deviceData['battery_health'] as String?,
        batteryTemperature: deviceData['battery_temperature']?.toString(),
        batteryVoltage: deviceData['battery_voltage']?.toString(),
        
        // Log vaqti
        loggedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Error building location record: $e');
        print('BackgroundLocationTrackingService: Stack trace: $stackTrace');
      }
      
      // Minimal record qaytarish
      return AgentLocationRecord(
        agentCode: _prefs.getUserCode() ?? '',
        latitude: position.latitude.toStringAsFixed(6),
        longitude: position.longitude.toStringAsFixed(6),
        loggedAt: DateTime.now(),
      );
    }
  }

  // ===========================================================================
  // API COMMUNICATION
  // ===========================================================================
  
  /// Joylashuvni serverga yuborish
  /// 
  /// Parametrlar:
  /// - [record] - Yuborilishi kerak bo'lgan AgentLocationRecord
  /// 
  /// Qaytaradi: Future<bool> - muvaffaqiyatli yuborildi mi
  Future<bool> _sendLocationToServer(AgentLocationRecord record) async {
    try {
      // Token olish (avtomatik qayta autentifikatsiya bilan)
      final token = await _tokenService.ensureValidToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: No valid token after re-authentication attempt, adding to offline queue');
        }
        return false;
      }

      // Internet ulanishini tekshirish
      final isConnected = await _deviceDataCollector.isConnectedToInternet();
      if (!isConnected) {
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: No internet, adding to offline queue');
        }
        return false;
      }

      final url = '$_apiBaseUrl$_locationEndpoint';
      
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Sending location to $url');
        print('BackgroundLocationTrackingService: Data: ${record.toJson()}');
      }

      // API so'rovi
      final response = await _dio.post(
        url,
        data: record.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: Location sent successfully');
          print('BackgroundLocationTrackingService: Response: ${response.data}');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: Failed with status ${response.statusCode}');
          print('BackgroundLocationTrackingService: Response: ${response.data}');
        }
        return false;
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: DioException: ${e.type}');
        print('BackgroundLocationTrackingService: Message: ${e.message}');
        print('BackgroundLocationTrackingService: Response: ${e.response?.data}');
      }
      return false;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Error sending location: $e');
        print('BackgroundLocationTrackingService: Stack trace: $stackTrace');
      }
      return false;
    }
  }

  // ===========================================================================
  // OFFLINE QUEUE
  // ===========================================================================
  
  /// Offline queue'ga qo'shish
  Future<void> _addToOfflineQueue(AgentLocationRecord record) async {
    try {
      _offlineQueue.add(record);
      await _saveOfflineQueue();
      
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Added to offline queue. Queue size: ${_offlineQueue.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Error adding to offline queue: $e');
      }
    }
  }

  /// Offline queue'ni saqlash
  Future<void> _saveOfflineQueue() async {
    try {
      final jsonList = _offlineQueue.map((r) => r.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs.preferences.setString(_offlineQueueKey, jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Error saving offline queue: $e');
      }
    }
  }

  /// Offline queue'ni yuklash
  Future<void> _loadOfflineQueue() async {
    try {
      final jsonString = _prefs.preferences.getString(_offlineQueueKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonList = jsonDecode(jsonString) as List;
        _offlineQueue = jsonList
            .map((json) => AgentLocationRecord.fromJson(json as Map<String, dynamic>))
            .toList();
        
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: Loaded ${_offlineQueue.length} items from offline queue');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Error loading offline queue: $e');
      }
      _offlineQueue = [];
    }
  }

  /// Offline queue'ni yuborish
  Future<void> _sendOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;
    if (_isSending) return;

    try {
      _isSending = true;
      
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Sending ${_offlineQueue.length} items from offline queue');
      }

      final itemsToRemove = <AgentLocationRecord>[];

      for (final record in _offlineQueue) {
        final success = await _sendLocationToServer(record);
        if (success) {
          itemsToRemove.add(record);
        } else {
          // Bitta xato bo'lsa, qolganlarini keyinroq yuborish
          break;
        }
      }

      // Muvaffaqiyatli yuborilganlarni o'chirish
      for (final item in itemsToRemove) {
        _offlineQueue.remove(item);
      }

      await _saveOfflineQueue();

      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Sent ${itemsToRemove.length} items. Remaining: ${_offlineQueue.length}');
      }

      _isSending = false;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Error sending offline queue: $e');
        print('BackgroundLocationTrackingService: Stack trace: $stackTrace');
      }
      _isSending = false;
    }
  }

  /// Offline queue'ni tozalash
  Future<void> clearOfflineQueue() async {
    _offlineQueue.clear();
    await _prefs.preferences.remove(_offlineQueueKey);
    
    if (kDebugMode) {
      print('BackgroundLocationTrackingService: Offline queue cleared');
    }
  }

  /// Offline queue size
  int get offlineQueueSize => _offlineQueue.length;

  // ===========================================================================
  // PERMISSION CHECK
  // ===========================================================================
  
  /// Location permission'ni tekshirish
  Future<bool> _checkLocationPermission() async {
    try {
      // Location service yoqilganmi
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: Location service disabled');
        }
        return false;
      }

      // Permission tekshirish
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: Location permission denied forever');
        }
        return false;
      }

      final hasPermission = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Location permission: $permission, hasPermission: $hasPermission');
      }

      return hasPermission;
    } catch (e) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Error checking permission: $e');
      }
      return false;
    }
  }

  // ===========================================================================
  // INTERVAL UPDATE
  // ===========================================================================
  
  /// Interval'ni yangilash
  /// 
  /// Bu metod server'dan yangi interval kelganda chaqiriladi.
  /// 
  /// Parametrlar:
  /// - [intervalSeconds] - Yangi interval (sekundlarda)
  Future<void> updateInterval(int intervalSeconds) async {
    try {
      if (intervalSeconds <= 0) {
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: Invalid interval: $intervalSeconds');
        }
        return;
      }

      final newInterval = intervalSeconds < _minIntervalSeconds 
          ? _minIntervalSeconds 
          : intervalSeconds;

      if (newInterval == _currentIntervalSeconds) {
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: Interval unchanged');
        }
        return;
      }

      _currentIntervalSeconds = newInterval;

      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Interval updated to $_currentIntervalSeconds seconds');
      }

      // Agar tracking active bo'lsa, timer'ni qayta boshlash
      if (_isTrackingActive) {
        _startLocationTimer();
      }
    } catch (e) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Error updating interval: $e');
      }
    }
  }

  // ===========================================================================
  // CLEANUP
  // ===========================================================================
  
  /// Service'ni tozalash
  Future<void> dispose() async {
    try {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Disposing...');
      }

      _locationTimer?.cancel();
      _locationTimer = null;

      await _positionStream?.cancel();
      _positionStream = null;

      await _connectivitySubscription?.cancel();
      _connectivitySubscription = null;

      _isInitialized = false;
      _isTrackingActive = false;

      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Disposed');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Error disposing: $e');
        print('BackgroundLocationTrackingService: Stack trace: $stackTrace');
      }
    }
  }

  // ===========================================================================
  // DEBUG INFO
  // ===========================================================================
  
  /// Debug ma'lumotlarini olish
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
    };
  }
}
