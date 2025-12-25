/// =============================================================================
/// Device Data Collector Helper
/// =============================================================================
/// 
/// Bu helper qurilma ma'lumotlarini to'plash uchun ishlatiladi.
/// Barcha qurilma, batareya, tarmoq, xotira ma'lumotlarini yig'adi.
/// 
/// Qo'llaniladigan paketlar:
/// - device_info_plus: Qurilma ma'lumotlari
/// - connectivity_plus: Tarmoq ma'lumotlari
/// - geolocator: Joylashuv ma'lumotlari
/// =============================================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';

/// Qurilma ma'lumotlarini to'plovchi helper class
/// 
/// Bu class quyidagi ma'lumotlarni to'playdi:
/// - Qurilma identifikatsiyasi (device_id, device_name, manufacturer, model)
/// - Operatsion tizim ma'lumotlari (platform, os_version)
/// - Ekran ma'lumotlari (width, height, density)
/// - Xotira ma'lumotlari (RAM, storage)
/// - Kamera ma'lumotlari
/// - Tarmoq ma'lumotlari (WiFi, cellular, connection type)
/// - Batareya ma'lumotlari (level, charging status)
/// 
/// Foydalanish:
/// ```dart
/// final collector = DeviceDataCollector();
/// final deviceInfo = await collector.collectDeviceInfo();
/// final networkInfo = await collector.collectNetworkInfo();
/// final batteryInfo = await collector.collectBatteryInfo();
/// ```
class DeviceDataCollector {
  // ===========================================================================
  // PRIVATE FIELDS
  // ===========================================================================
  
  /// DeviceInfoPlugin instance - qurilma ma'lumotlarini olish uchun
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  
  /// Connectivity instance - tarmoq holatini tekshirish uchun
  final Connectivity _connectivity = Connectivity();
  
  /// Cached device info - har safar qayta so'ramaslik uchun
  Map<String, dynamic>? _cachedDeviceInfo;
  
  /// Last cache time - cache muddatini tekshirish uchun
  DateTime? _lastCacheTime;
  
  /// Cache duration - 5 daqiqa
  static const Duration _cacheDuration = Duration(minutes: 5);

  // ===========================================================================
  // SINGLETON PATTERN
  // ===========================================================================
  
  static final DeviceDataCollector _instance = DeviceDataCollector._internal();
  
  /// Singleton factory constructor
  factory DeviceDataCollector() => _instance;
  
  /// Private constructor
  DeviceDataCollector._internal();

  // ===========================================================================
  // QURILMA MA'LUMOTLARI (Device Information)
  // ===========================================================================
  
  /// Qurilma ma'lumotlarini to'plash
  /// 
  /// Bu metod qurilmaning asosiy ma'lumotlarini qaytaradi:
  /// - device_id: Qurilma unikal identifikatori
  /// - device_name: Qurilma nomi
  /// - device_manufacturer: Ishlab chiqaruvchi
  /// - device_model: Model nomi
  /// - platform: OS turi (Android/iOS)
  /// - os_version: OS versiyasi
  /// - is_physical_device: Fizik qurilmami yoki emulyatormi
  /// 
  /// Returns: Map<String, dynamic> qurilma ma'lumotlari
  Future<Map<String, dynamic>> collectDeviceInfo() async {
    try {
      // Cache tekshirish
      if (_cachedDeviceInfo != null && _lastCacheTime != null) {
        final elapsed = DateTime.now().difference(_lastCacheTime!);
        if (elapsed < _cacheDuration) {
          if (kDebugMode) {
            print('DeviceDataCollector: Returning cached device info');
          }
          return _cachedDeviceInfo!;
        }
      }

      Map<String, dynamic> deviceInfo = {};

      if (Platform.isAndroid) {
        deviceInfo = await _collectAndroidInfo();
      } else if (Platform.isIOS) {
        deviceInfo = await _collectIosInfo();
      } else {
        deviceInfo = _collectGenericInfo();
      }

      // Cache'ga saqlash
      _cachedDeviceInfo = deviceInfo;
      _lastCacheTime = DateTime.now();

      if (kDebugMode) {
        print('DeviceDataCollector: Collected device info: ${deviceInfo.keys.toList()}');
      }

      return deviceInfo;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('DeviceDataCollector: Error collecting device info: $e');
        print('DeviceDataCollector: Stack trace: $stackTrace');
      }
      return _getDefaultDeviceInfo();
    }
  }

  /// Android qurilma ma'lumotlarini to'plash
  Future<Map<String, dynamic>> _collectAndroidInfo() async {
    try {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      
      return {
        'device_id': androidInfo.id,
        'device_name': androidInfo.device,
        'device_manufacturer': androidInfo.manufacturer,
        'device_model': androidInfo.model,
        'platform': 'Android',
        'os_version': androidInfo.version.release,
        'sdk_version': androidInfo.version.sdkInt,
        'is_physical_device': androidInfo.isPhysicalDevice,
        'device_fingerprint': androidInfo.fingerprint,
        'hardware': androidInfo.hardware,
        'host': androidInfo.host,
        'display': androidInfo.display,
        'board': androidInfo.board,
        'brand': androidInfo.brand,
        'product': androidInfo.product,
        'supported_abis': androidInfo.supportedAbis,
      };
    } catch (e) {
      if (kDebugMode) {
        print('DeviceDataCollector: Error collecting Android info: $e');
      }
      return _getDefaultDeviceInfo();
    }
  }

  /// iOS qurilma ma'lumotlarini to'plash
  Future<Map<String, dynamic>> _collectIosInfo() async {
    try {
      final iosInfo = await _deviceInfoPlugin.iosInfo;
      
      return {
        'device_id': iosInfo.identifierForVendor ?? 'unknown',
        'device_name': iosInfo.name,
        'device_manufacturer': 'Apple',
        'device_model': iosInfo.model,
        'platform': 'iOS',
        'os_version': iosInfo.systemVersion,
        'system_name': iosInfo.systemName,
        'is_physical_device': iosInfo.isPhysicalDevice,
        'utsname_machine': iosInfo.utsname.machine,
        'utsname_release': iosInfo.utsname.release,
        'utsname_version': iosInfo.utsname.version,
        'utsname_sysname': iosInfo.utsname.sysname,
        'utsname_nodename': iosInfo.utsname.nodename,
      };
    } catch (e) {
      if (kDebugMode) {
        print('DeviceDataCollector: Error collecting iOS info: $e');
      }
      return _getDefaultDeviceInfo();
    }
  }

  /// Generic qurilma ma'lumotlari (boshqa platformalar uchun)
  Map<String, dynamic> _collectGenericInfo() {
    return {
      'device_id': 'unknown',
      'device_name': Platform.localHostname,
      'device_manufacturer': 'unknown',
      'device_model': 'unknown',
      'platform': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'is_physical_device': true,
    };
  }

  /// Default qurilma ma'lumotlari (xatolik bo'lganda)
  Map<String, dynamic> _getDefaultDeviceInfo() {
    return {
      'device_id': 'unknown',
      'device_name': 'unknown',
      'device_manufacturer': 'unknown',
      'device_model': 'unknown',
      'platform': Platform.operatingSystem,
      'os_version': 'unknown',
      'is_physical_device': true,
    };
  }

  // ===========================================================================
  // TARMOQ MA'LUMOTLARI (Network Information)
  // ===========================================================================
  
  /// Tarmoq ma'lumotlarini to'plash
  /// 
  /// Bu metod quyidagi ma'lumotlarni qaytaradi:
  /// - network_type: Tarmoq turi (WiFi, Mobile, None)
  /// - connection_type: Ulanish turi
  /// - is_connected: Internetga ulanganmi
  /// 
  /// Returns: Map<String, dynamic> tarmoq ma'lumotlari
  Future<Map<String, dynamic>> collectNetworkInfo() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      
      String networkType = 'None';
      String connectionType = 'none';
      bool isConnected = false;

      // Connectivity result'larni tekshirish
      for (final result in connectivityResults) {
        switch (result) {
          case ConnectivityResult.wifi:
            networkType = 'WiFi';
            connectionType = 'wifi';
            isConnected = true;
            break;
          case ConnectivityResult.mobile:
            networkType = 'Mobile';
            connectionType = 'mobile';
            isConnected = true;
            break;
          case ConnectivityResult.ethernet:
            networkType = 'Ethernet';
            connectionType = 'ethernet';
            isConnected = true;
            break;
          case ConnectivityResult.vpn:
            networkType = 'VPN';
            connectionType = 'vpn';
            isConnected = true;
            break;
          case ConnectivityResult.bluetooth:
            networkType = 'Bluetooth';
            connectionType = 'bluetooth';
            isConnected = true;
            break;
          case ConnectivityResult.other:
            networkType = 'Other';
            connectionType = 'other';
            isConnected = true;
            break;
          case ConnectivityResult.none:
            // Continue checking other results
            break;
        }
        
        // Agar ulanish topilsa, loopdan chiqish
        if (isConnected) break;
      }

      if (kDebugMode) {
        print('DeviceDataCollector: Network info - type: $networkType, connected: $isConnected');
      }

      return {
        'network_type': networkType,
        'connection_type': connectionType,
        'is_connected': isConnected,
        'connectivity_results': connectivityResults.map((r) => r.name).toList(),
      };
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('DeviceDataCollector: Error collecting network info: $e');
        print('DeviceDataCollector: Stack trace: $stackTrace');
      }
      return {
        'network_type': 'Unknown',
        'connection_type': 'unknown',
        'is_connected': false,
      };
    }
  }

  /// Internet ulanishini tekshirish
  Future<bool> isConnectedToInternet() async {
    try {
      final networkInfo = await collectNetworkInfo();
      return networkInfo['is_connected'] as bool? ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('DeviceDataCollector: Error checking internet connection: $e');
      }
      return false;
    }
  }

  // ===========================================================================
  // BATAREYA MA'LUMOTLARI (Battery Information)
  // ===========================================================================
  
  /// Batareya ma'lumotlarini to'plash
  /// 
  /// Bu metod battery_plus paketidan foydalanib batareya ma'lumotlarini oladi:
  /// - battery_level: Batareya darajasi (0-100)
  /// - is_charging: Zaryadlanayaptimi
  /// - battery_state: Batareya holati (charging, discharging, full, etc.)
  /// 
  /// Returns: Map<String, dynamic> batareya ma'lumotlari
  Future<Map<String, dynamic>> collectBatteryInfo() async {
    try {
      final battery = Battery();
      
      // Batareya darajasini olish (0-100)
      final batteryLevel = await battery.batteryLevel;
      
      // Batareya holatini olish
      final batteryState = await battery.batteryState;
      
      // Zaryadlanayaptimi tekshirish
      final isCharging = batteryState == BatteryState.charging || 
                         batteryState == BatteryState.full;
      
      // Battery state ni string ga o'zgartirish
      String batteryStateString;
      switch (batteryState) {
        case BatteryState.charging:
          batteryStateString = 'charging';
          break;
        case BatteryState.discharging:
          batteryStateString = 'discharging';
          break;
        case BatteryState.full:
          batteryStateString = 'full';
          break;
        case BatteryState.connectedNotCharging:
          batteryStateString = 'connected_not_charging';
          break;
        case BatteryState.unknown:
          batteryStateString = 'unknown';
          break;
      }
      
      if (kDebugMode) {
        print('DeviceDataCollector: Battery level: $batteryLevel%, state: $batteryStateString');
      }

      return {
        'battery_level': batteryLevel, // Batareya darajasi (0-100)
        'is_charging': isCharging, // Zaryadlanayaptimi
        'battery_state': batteryStateString, // Batareya holati
        'battery_health': null, // Platform orqali olinmaydi
        'battery_temperature': null, // Platform orqali olinmaydi
        'battery_voltage': null, // Platform orqali olinmaydi
      };
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('DeviceDataCollector: Error collecting battery info: $e');
        print('DeviceDataCollector: Stack trace: $stackTrace');
      }
      return {
        'battery_level': null,
        'is_charging': null,
        'battery_state': null,
        'battery_health': null,
        'battery_temperature': null,
        'battery_voltage': null,
      };
    }
  }

  // ===========================================================================
  // EKRAN MA'LUMOTLARI (Screen Information)
  // ===========================================================================
  
  /// Ekran ma'lumotlarini to'plash
  /// 
  /// Bu metod quyidagi ma'lumotlarni qaytaradi:
  /// - screen_width: Ekran kengligi (pikselda)
  /// - screen_height: Ekran balandligi (pikselda)
  /// - screen_density: Ekran zichligi (DPI)
  /// 
  /// Eslatma: Bu ma'lumotlar BuildContext orqali olinishi kerak,
  /// shuning uchun bu metod Flutter widget'dan chaqirilishi kerak.
  /// 
  /// Returns: Map<String, dynamic> ekran ma'lumotlari
  Map<String, dynamic> collectScreenInfo({
    required double screenWidth,
    required double screenHeight,
    required double screenDensity,
  }) {
    try {
      if (kDebugMode) {
        print('DeviceDataCollector: Screen info - ${screenWidth}x$screenHeight, density: $screenDensity');
      }

      return {
        'screen_width': screenWidth.toInt(),
        'screen_height': screenHeight.toInt(),
        'screen_density': screenDensity.toStringAsFixed(2),
      };
    } catch (e) {
      if (kDebugMode) {
        print('DeviceDataCollector: Error collecting screen info: $e');
      }
      return {
        'screen_width': null,
        'screen_height': null,
        'screen_density': null,
      };
    }
  }

  // ===========================================================================
  // XOTIRA MA'LUMOTLARI (Memory/Storage Information)
  // ===========================================================================
  
  /// Xotira ma'lumotlarini to'plash
  /// 
  /// Eslatma: RAM va storage ma'lumotlari platformaga bog'liq
  /// va qo'shimcha platform channel kerak bo'lishi mumkin.
  /// 
  /// Returns: Map<String, dynamic> xotira ma'lumotlari
  Future<Map<String, dynamic>> collectMemoryInfo() async {
    try {
      // Hozircha placeholder ma'lumotlar
      // TODO: disk_space paketini integratsiya qilish
      
      if (kDebugMode) {
        print('DeviceDataCollector: Memory info collection - placeholder');
      }

      return {
        'ram_total': null, // Jami RAM (baytda)
        'ram_available': null, // Mavjud RAM (baytda)
        'storage_total': null, // Jami xotira (baytda)
        'storage_available': null, // Mavjud xotira (baytda)
      };
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('DeviceDataCollector: Error collecting memory info: $e');
        print('DeviceDataCollector: Stack trace: $stackTrace');
      }
      return {
        'ram_total': null,
        'ram_available': null,
        'storage_total': null,
        'storage_available': null,
      };
    }
  }

  // ===========================================================================
  // KAMERA MA'LUMOTLARI (Camera Information)
  // ===========================================================================
  
  /// Kamera ma'lumotlarini to'plash
  /// 
  /// Returns: Map<String, dynamic> kamera ma'lumotlari
  Future<Map<String, dynamic>> collectCameraInfo() async {
    try {
      // Kamera mavjudligini tekshirish
      // Hozircha default qiymatlar
      
      if (kDebugMode) {
        print('DeviceDataCollector: Camera info collection - placeholder');
      }

      return {
        'camera_front': true, // Ko'p qurilmalarda old kamera bor
        'camera_back': true, // Ko'p qurilmalarda orqa kamera bor
        'camera_resolution': null, // Kamera o'lchami
      };
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('DeviceDataCollector: Error collecting camera info: $e');
        print('DeviceDataCollector: Stack trace: $stackTrace');
      }
      return {
        'camera_front': null,
        'camera_back': null,
        'camera_resolution': null,
      };
    }
  }

  // ===========================================================================
  // SENSOR MA'LUMOTLARI (Sensor Information)
  // ===========================================================================
  
  /// Sensor ma'lumotlarini to'plash
  /// 
  /// Eslatma: Sensor ma'lumotlarini olish uchun sensors_plus paketini
  /// qo'shish kerak. Hozircha placeholder qaytaradi.
  /// 
  /// Returns: Map<String, dynamic> sensor ma'lumotlari
  Future<Map<String, dynamic>> collectSensorInfo() async {
    try {
      // Hozircha placeholder ma'lumotlar
      // TODO: sensors_plus paketini integratsiya qilish
      
      if (kDebugMode) {
        print('DeviceDataCollector: Sensor info collection - placeholder');
      }

      return {
        'accelerometer_x': null,
        'accelerometer_y': null,
        'accelerometer_z': null,
        'gyroscope_x': null,
        'gyroscope_y': null,
        'gyroscope_z': null,
        'magnetometer_x': null,
        'magnetometer_y': null,
        'magnetometer_z': null,
        'proximity_sensor': null,
        'light_sensor': null,
        'temperature': null,
        'humidity': null,
        'pressure': null,
      };
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('DeviceDataCollector: Error collecting sensor info: $e');
        print('DeviceDataCollector: Stack trace: $stackTrace');
      }
      return {
        'accelerometer_x': null,
        'accelerometer_y': null,
        'accelerometer_z': null,
        'gyroscope_x': null,
        'gyroscope_y': null,
        'gyroscope_z': null,
        'magnetometer_x': null,
        'magnetometer_y': null,
        'magnetometer_z': null,
        'proximity_sensor': null,
        'light_sensor': null,
        'temperature': null,
        'humidity': null,
        'pressure': null,
      };
    }
  }

  // ===========================================================================
  // XAVFSIZLIK MA'LUMOTLARI (Security Information)
  // ===========================================================================
  
  /// Xavfsizlik ma'lumotlarini to'plash
  /// 
  /// Bu metod quyidagi ma'lumotlarni qaytaradi:
  /// - is_rooted: Android qurilma root qilinganmi
  /// - is_jailbroken: iOS qurilma jailbreak qilinganmi
  /// - encryption_enabled: Shifrlash yoqilganmi
  /// - screen_lock_type: Ekran qulfi turi
  /// 
  /// Returns: Map<String, dynamic> xavfsizlik ma'lumotlari
  Future<Map<String, dynamic>> collectSecurityInfo() async {
    try {
      // Hozircha placeholder ma'lumotlar
      // TODO: root/jailbreak detection paketini qo'shish
      
      if (kDebugMode) {
        print('DeviceDataCollector: Security info collection - placeholder');
      }

      return {
        'is_rooted': false, // Default: root qilinmagan
        'is_jailbroken': false, // Default: jailbreak qilinmagan
        'encryption_enabled': true, // Default: shifrlash yoqilgan
        'screen_lock_type': 'unknown', // Ekran qulfi turi
      };
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('DeviceDataCollector: Error collecting security info: $e');
        print('DeviceDataCollector: Stack trace: $stackTrace');
      }
      return {
        'is_rooted': null,
        'is_jailbroken': null,
        'encryption_enabled': null,
        'screen_lock_type': null,
      };
    }
  }

  // ===========================================================================
  // ILOVA MA'LUMOTLARI (App Information)
  // ===========================================================================
  
  /// Ilova ma'lumotlarini to'plash
  /// 
  /// Eslatma: Bu ma'lumotlar package_info_plus paketidan olinadi.
  /// Hozircha statik qiymatlar qaytariladi.
  /// 
  /// Returns: Map<String, dynamic> ilova ma'lumotlari
  Future<Map<String, dynamic>> collectAppInfo() async {
    try {
      // Hozircha statik ma'lumotlar
      // TODO: package_info_plus dan olish
      
      if (kDebugMode) {
        print('DeviceDataCollector: App info collection - static values');
      }

      return {
        'app_version': '1.0.0', // Ilova versiyasi
        'app_build_number': '1', // Build raqami
        'app_installation_date': null, // O'rnatilgan sana
        'app_last_update': null, // Oxirgi yangilanish
      };
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('DeviceDataCollector: Error collecting app info: $e');
        print('DeviceDataCollector: Stack trace: $stackTrace');
      }
      return {
        'app_version': 'unknown',
        'app_build_number': 'unknown',
        'app_installation_date': null,
        'app_last_update': null,
      };
    }
  }

  // ===========================================================================
  // VAQT MINTAQASI (Timezone)
  // ===========================================================================
  
  /// Vaqt mintaqasini olish
  /// 
  /// Returns: String vaqt mintaqasi nomi
  String getTimezone() {
    try {
      return DateTime.now().timeZoneName;
    } catch (e) {
      if (kDebugMode) {
        print('DeviceDataCollector: Error getting timezone: $e');
      }
      return 'Unknown';
    }
  }

  // ===========================================================================
  // BARCHA MA'LUMOTLARNI YIG'ISH (Collect All Data)
  // ===========================================================================
  
  /// Barcha qurilma ma'lumotlarini bir vaqtda to'plash
  /// 
  /// Bu metod barcha mavjud ma'lumotlarni parallel ravishda to'playdi
  /// va bitta Map ichida qaytaradi.
  /// 
  /// Returns: Map<String, dynamic> barcha qurilma ma'lumotlari
  Future<Map<String, dynamic>> collectAllData({
    double? screenWidth,
    double? screenHeight,
    double? screenDensity,
  }) async {
    try {
      if (kDebugMode) {
        print('DeviceDataCollector: Starting to collect all device data...');
      }

      // Parallel ravishda barcha ma'lumotlarni to'plash
      final results = await Future.wait([
        collectDeviceInfo(),
        collectNetworkInfo(),
        collectBatteryInfo(),
        collectMemoryInfo(),
        collectCameraInfo(),
        collectSensorInfo(),
        collectSecurityInfo(),
        collectAppInfo(),
      ]);

      // Natijalarni birlashtirish
      final Map<String, dynamic> allData = {};
      
      // Device info
      allData.addAll(results[0]);
      
      // Network info
      allData.addAll(results[1]);
      
      // Battery info
      allData.addAll(results[2]);
      
      // Memory info
      allData.addAll(results[3]);
      
      // Camera info
      allData.addAll(results[4]);
      
      // Sensor info
      allData.addAll(results[5]);
      
      // Security info
      allData.addAll(results[6]);
      
      // App info
      allData.addAll(results[7]);

      // Screen info (agar berilgan bo'lsa)
      if (screenWidth != null && screenHeight != null && screenDensity != null) {
        allData.addAll(collectScreenInfo(
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          screenDensity: screenDensity,
        ));
      }

      // Timezone
      allData['timezone'] = getTimezone();

      if (kDebugMode) {
        print('DeviceDataCollector: Collected all data with ${allData.length} fields');
      }

      return allData;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('DeviceDataCollector: Error collecting all data: $e');
        print('DeviceDataCollector: Stack trace: $stackTrace');
      }
      return _getDefaultDeviceInfo();
    }
  }

  // ===========================================================================
  // CACHE MANAGEMENT
  // ===========================================================================
  
  /// Cache'ni tozalash
  void clearCache() {
    _cachedDeviceInfo = null;
    _lastCacheTime = null;
    if (kDebugMode) {
      print('DeviceDataCollector: Cache cleared');
    }
  }

  /// Cache mavjudligini tekshirish
  bool get hasCachedData => _cachedDeviceInfo != null;
}
