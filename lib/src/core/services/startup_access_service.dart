import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/models/access_check_result.dart';
import 'package:gloria_marketing_flutter/src/core/models/device_startup_info.dart';
import 'package:gloria_marketing_flutter/src/core/services/local_uuid_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/helpers/device_data_collector.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_exceptions.dart';

/// =============================================================================
/// Startup Access Service
/// =============================================================================
/// 
/// Bu servis ilova ishga tushganda qurilma va account bog'liqligini tekshiradi.
/// 
/// VAZIFALAR:
/// - LocalUUID ni olish/yaratish
/// - Device ma'lumotlarini yig'ish
/// - SOAP CheckAccessOnStartup chaqirish
/// - Natijani qaytarish
/// =============================================================================

/// Ilova holati
enum AppAccessState {
  /// Tekshiruv jarayonida
  loading,
  
  /// Ruxsat berildi
  allowed,
  
  /// Bloklangan
  blocked,
  
  /// Xatolik yuz berdi
  error,
  
  /// Login qilinmagan
  notLoggedIn,
  
  /// Offline rejim (server bilan bog'lanib bo'lmadi)
  offline,
}

class StartupAccessService {
  final LocalUuidService _localUuidService;
  final SharedPreferencesService _prefsService;
  final SoapApiService _soapApiService;
  final DeviceDataCollector _deviceDataCollector;

  /// App versiyasi (pubspec.yaml dan)
  static const String _appVersion = '1.0.0';

  StartupAccessService({
    required LocalUuidService localUuidService,
    required SharedPreferencesService prefsService,
    required SoapApiService soapApiService,
    DeviceDataCollector? deviceDataCollector,
  })  : _localUuidService = localUuidService,
        _prefsService = prefsService,
        _soapApiService = soapApiService,
        _deviceDataCollector = deviceDataCollector ?? DeviceDataCollector();

  /// Foydalanuvchi login qilganmi tekshirish
  bool isUserLoggedIn() {
    final userCode = _prefsService.getUserCode();
    return userCode != null && userCode.isNotEmpty;
  }

  /// Foydalanuvchi ma'lumotlarini olish
  String? getUserId() {
    return _prefsService.getUserCode();
  }

  /// Device va account access tekshiruvi
  /// 
  /// Returns [AccessCheckResult] with status and details
  Future<AccessCheckResult> checkAccess() async {
    try {
      // 1. Foydalanuvchi login qilganmi tekshirish
      final userId = getUserId();
      if (userId == null || userId.isEmpty) {
        if (kDebugMode) {
          print('StartupAccessService: User not logged in');
        }
        return AccessCheckResult.allowed(); // Login qilinmagan - tekshirish shart emas
      }

      // 2. Local UUID ni olish yoki yaratish
      final localUuid = await _localUuidService.getOrCreateLocalUuid();
      if (kDebugMode) {
        print('StartupAccessService: LocalUUID: $localUuid');
      }

      // 3. Device ma'lumotlarini yig'ish
      final deviceData = await _deviceDataCollector.collectDeviceInfo();
      if (kDebugMode) {
        print('StartupAccessService: Device data collected: ${deviceData.keys}');
      }

      // 4. DeviceStartupInfo yaratish
      final startupInfo = DeviceStartupInfo.fromDeviceData(
        userId: userId,
        localUuid: localUuid,
        deviceData: deviceData,
        appVersion: _appVersion,
      );

      if (kDebugMode) {
        print('StartupAccessService: Checking access for: $startupInfo');
      }

      // 5. SOAP CheckAccessOnStartup chaqirish
      final response = await _soapApiService.checkAccessOnStartup(
        userId: startupInfo.userId,
        localUuid: startupInfo.localUuid,
        appDeviceId: startupInfo.appDeviceId,
        platform: startupInfo.platform,
        brand: startupInfo.brand,
        model: startupInfo.model,
        osVersion: startupInfo.osVersion,
        sdk: startupInfo.sdk,
        appVersion: startupInfo.appVersion,
        deviceFingerprint: startupInfo.deviceFingerprint,
      );

      // 6. Response ni parse qilish
      final status = response['status'] as String? ?? 'ALLOW';
      final riskScore = response['riskScore'] as int?;
      final reason = response['reason'] as String?;
      final message = response['message'] as String?;

      if (kDebugMode) {
        print('StartupAccessService: Access check result - Status: $status, Reason: $reason');
      }

      // 7. AccessCheckResult yaratish va qaytarish
      if (status.toUpperCase() == 'ALLOW' || status.toUpperCase() == 'ALLOWED') {
        return AccessCheckResult(
          status: AccessStatus.allow,
          riskScore: riskScore,
          message: message,
        );
      } else {
        return AccessCheckResult(
          status: AccessStatus.block,
          riskScore: riskScore,
          reason: _parseReason(reason),
          message: message,
          rawReason: reason,
        );
      }
    } on ConnectivityException catch (e) {
      if (kDebugMode) {
        print('StartupAccessService: Connectivity error: $e');
      }
      // Offline rejimda - ruxsat berish (keyingi safar tekshiriladi)
      return AccessCheckResult.allowed();
    } catch (e) {
      if (kDebugMode) {
        print('StartupAccessService: Error checking access: $e');
      }
      // Xatolik bo'lsa ham, foydalanuvchini bloklash emas
      // Keyingi safar tekshiriladi
      return AccessCheckResult.allowed();
    }
  }

  /// Reason string ni enum ga o'girish
  AccessBlockReason _parseReason(String? reason) {
    if (reason == null || reason.isEmpty) {
      return AccessBlockReason.unknown;
    }

    switch (reason.toUpperCase().trim()) {
      case 'ACCOUNT_ALREADY_BOUND_TO_ANOTHER_DEVICE':
      case 'ACCOUNT_BOUND':
        return AccessBlockReason.accountAlreadyBoundToAnotherDevice;
      case 'DEVICE_ALREADY_HAS_ANOTHER_ACCOUNT':
      case 'DEVICE_BOUND':
        return AccessBlockReason.deviceAlreadyHasAnotherAccount;
      case 'HIGH_RISK_DEVICE':
      case 'HIGH_RISK':
        return AccessBlockReason.highRiskDevice;
      case 'SECURITY_POLICY_VIOLATION':
      case 'POLICY_VIOLATION':
        return AccessBlockReason.securityPolicyViolation;
      default:
        return AccessBlockReason.unknown;
    }
  }

  /// Device info ni olish (debug/logging uchun)
  Future<Map<String, dynamic>> getDeviceInfo() async {
    return await _deviceDataCollector.collectDeviceInfo();
  }

  /// Local UUID ni olish
  Future<String> getLocalUuid() async {
    return await _localUuidService.getOrCreateLocalUuid();
  }

  /// Local UUID ni tozalash (logout vaqtida)
  Future<void> clearLocalUuid() async {
    await _localUuidService.clearLocalUuid();
  }
}
