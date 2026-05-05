import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../background_location/helpers/device_data_collector.dart';
import '../shared_preferences_service.dart';
import '../token_service.dart';
import 'models/device_register_request.dart';
import 'rest_logging.dart';

/// `POST /api/mobile/v1/devices/register/` ga bir martalik chaqiruv qiluvchi
/// servis. App startup'da (login muvaffaqiyatli bo'lgandan keyin) chaqiriladi.
/// Idempotent — server `(user, device_id)` unique indexi orqali upsert qiladi.
class DeviceRegistrationService {
  static const String _endpoint = '/api/mobile/v1/devices/register/';

  /// SharedPreferences kalit — oxirgi muvaffaqiyatli registratsiya vaqti
  /// saqlanadi (24 soatdan keyin qayta yuboriladi).
  static const String _lastRegisteredAtKey = 'device_v2_last_registered_at';

  static const Duration _resendCooldown = Duration(hours: 24);

  final Dio _dio;
  final TokenService _tokenService;
  final SharedPreferencesService _prefs;
  final DeviceDataCollector _collector;

  DeviceRegistrationService({
    required TokenService tokenService,
    required SharedPreferencesService prefs,
    DeviceDataCollector? collector,
    Dio? dio,
  })  : _tokenService = tokenService,
        _prefs = prefs,
        _collector = collector ?? DeviceDataCollector(),
        _dio = dio ?? Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    attachRestLogger(_dio, 'DEVICE');
  }

  /// Qurilmani ro'yxatdan o'tkazish.
  ///
  /// `force=true` bo'lsa cooldown e'tiborga olinmaydi va majburiy yuboriladi
  /// (masalan, app version yangilanganda).
  ///
  /// Qaytaradi: server qabul qilgan bo'lsa true, aks holda false.
  Future<bool> register({bool force = false}) async {
    try {
      if (!force && _isWithinCooldown()) {
        if (kDebugMode) {
          print('DeviceRegistrationService: within cooldown, skipping');
        }
        return true; // oxirgi muvaffaqiyatli registratsiya hali yangi
      }

      final token = await _tokenService.ensureValidV2Token();
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('DeviceRegistrationService: No V2 token, skipping');
        }
        return false;
      }

      final payload = await _buildPayload();
      final url = '${TokenService.v2BaseUrl}$_endpoint';

      if (kDebugMode) {
        print('DeviceRegistrationService: POST $url device_id=${payload.deviceId}');
      }

      final response = await _dio.post(
        url,
        data: payload.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _prefs.preferences.setString(
          _lastRegisteredAtKey,
          DateTime.now().toIso8601String(),
        );
        if (kDebugMode) {
          print('DeviceRegistrationService: success status=${response.statusCode}');
        }
        return true;
      }

      if (kDebugMode) {
        print('DeviceRegistrationService: unexpected status=${response.statusCode} data=${response.data}');
      }
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('DeviceRegistrationService: DioException ${e.type} status=${e.response?.statusCode}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('DeviceRegistrationService: unexpected error: $e');
      }
      return false;
    }
  }

  bool _isWithinCooldown() {
    final raw = _prefs.preferences.getString(_lastRegisteredAtKey);
    if (raw == null || raw.isEmpty) return false;
    try {
      final last = DateTime.parse(raw);
      return DateTime.now().difference(last) < _resendCooldown;
    } catch (_) {
      return false;
    }
  }

  Future<DeviceRegisterRequest> _buildPayload() async {
    final data = await _collector.collectAllData();
    final pkg = await _safePackageInfo();

    return DeviceRegisterRequest(
      deviceId: (data['device_id'] as String?) ?? 'unknown',
      deviceName: data['device_name'] as String?,
      deviceManufacturer: data['device_manufacturer'] as String?,
      deviceModel: data['device_model'] as String?,
      deviceFingerprint: data['device_fingerprint'] as String?,
      platform: _normalizePlatform(data['platform'] as String?),
      osVersion: data['os_version'] as String?,
      screenWidth: data['screen_width'] as int?,
      screenHeight: data['screen_height'] as int?,
      screenDensity: data['screen_density'] as String?,
      cameraFront: data['camera_front'] as bool?,
      cameraBack: data['camera_back'] as bool?,
      cameraResolution: data['camera_resolution'] as String?,
      appVersion: pkg?.version,
      appBuildNumber: pkg?.buildNumber,
      isRooted: data['is_rooted'] as bool?,
      isJailbroken: data['is_jailbroken'] as bool?,
      encryptionEnabled: data['encryption_enabled'] as bool?,
      screenLockType: data['screen_lock_type'] as String?,
    );
  }

  /// DeviceDataCollector "Android"/"iOS" qaytaradi, server PlatformEnum lowercase.
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
      return await PackageInfo.fromPlatform();
    } catch (e) {
      if (kDebugMode) {
        print('DeviceRegistrationService: PackageInfo error: $e');
      }
      return null;
    }
  }
}
