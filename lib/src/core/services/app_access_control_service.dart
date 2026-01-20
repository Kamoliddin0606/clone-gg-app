import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/services/time_verification_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/connectivity_monitoring_service.dart';
import 'package:gloria_marketing_flutter/src/features/time_verification/domain/entities/time_verification_result.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

/// Main orchestrator service for app access control
/// 
/// This service coordinates all access control checks including:
/// - Internet connectivity monitoring
/// - Access validity date checking
/// - Real time verification via Server SOAP API
/// - Automatic checks when internet is restored
/// - Data cleanup on access revocation
/// 
/// The service implements the complete access control flow as specified:
/// 1. Check internet connectivity on app start
/// 2. If no internet: use device time with last access timestamp validation
/// 3. If internet available: verify real time with Server SOAP API
/// 4. Monitor internet restoration and auto-verify
/// 5. Revoke access and cleanup data if expired
class AppAccessControlService {
  final TimeVerificationService _timeVerificationService;
  final ConnectivityMonitoringService _connectivityService;
  final SharedPreferencesService _prefsService;
  
  // Stream subscription for connectivity changes
  StreamSubscription<bool>? _connectivitySubscription;
  
  // Stream controller for access revocation events (notifies UI to navigate to login)
  final StreamController<AccessCheckResult> _accessRevokedController = 
      StreamController<AccessCheckResult>.broadcast();
  
  /// Stream that emits when access is revoked. UI should listen to navigate to login.
  Stream<AccessCheckResult> get accessRevokedStream => _accessRevokedController.stream;
  
  // Flag to track if service is initialized
  bool _isInitialized = false;
  
  AppAccessControlService({
    required TimeVerificationService timeVerificationService,
    required ConnectivityMonitoringService connectivityService,
    required SharedPreferencesService prefsService,
  }) : _timeVerificationService = timeVerificationService,
       _connectivityService = connectivityService,
       _prefsService = prefsService;
  
  /// Initialize the access control service
  /// 
  /// Sets up connectivity monitoring and starts listening for internet restoration
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Already initialized');
      }
      return;
    }
    
    try {
      // Initialize connectivity monitoring
      await _connectivityService.initialize();
      
      // Listen for connectivity restoration
      _connectivitySubscription = _connectivityService.connectivityStream.listen(
        _onConnectivityChanged,
        onError: (error) {
          if (kDebugMode) {
            debugPrint('[AppAccessControlService] Error in connectivity stream: $error');
          }
        },
      );
      
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Error during initialization: $e');
      }
      rethrow;
    }
  }
  
  /// Handle connectivity changes
  /// 
  /// When internet is restored, automatically verify time with server
  /// Also updates the offline mode flag in SharedPreferences
  void _onConnectivityChanged(bool isConnected) async {
    // Update offline mode flag in SharedPreferences
    await _prefsService.setOfflineMode(!isConnected);
    
    if (!isConnected) {
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Internet disconnected - offline mode enabled');
      }
      return;
    }
    
    if (kDebugMode) {
      debugPrint('[AppAccessControlService] Internet restored - online mode enabled, verifying time');
    }
    
    try {
      // Verify time limit with TimeVerificationService
      final result = await _timeVerificationService.verifyTimeLimit();
      
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Time verification result: ${result.status}');
      }
      
      // Check if access should be blocked
      if (result.shouldBlock) {
        if (kDebugMode) {
          debugPrint('[AppAccessControlService] Access expired - revoking access');
        }
        
        // Block user and cleanup data
        await _timeVerificationService.blockUserAndClearData(
          result.message ?? 'Access expired',
        );
        
        // Notify UI to navigate to login
        _accessRevokedController.add(AccessCheckResult(
          isAccessGranted: false,
          reason: AccessDenialReason.expired,
          message: result.message ?? 'Access period has expired',
        ));
      } else {
        if (kDebugMode) {
          debugPrint('[AppAccessControlService] Access still valid');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Error verifying time on connectivity restore: $e');
      }
    }
  }
  
  /// Perform initial access check on app startup
  /// 
  /// Returns AccessCheckResult indicating whether access should be granted
  Future<AccessCheckResult> performInitialAccessCheck() async {
    try {
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Starting initial access check');
      }
      
      // Check if internet is available
      final hasInternet = await _connectivityService.checkConnectivity();
      
      if (hasInternet) {
        // Internet available - verify with server SOAP API
        return await _checkAccessWithInternet();
      } else {
        // No internet - use offline validation
        return await _checkAccessWithoutInternet();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Error during initial access check: $e');
      }
      
      return AccessCheckResult(
        isAccessGranted: false,
        reason: AccessDenialReason.error,
        message: 'Error checking access: ${e.toString()}',
      );
    }
  }
  
  /// Check access when internet is available
  Future<AccessCheckResult> _checkAccessWithInternet() async {
    try {
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Checking access with internet');
      }
      
      // Verify time limit with TimeVerificationService
      final result = await _timeVerificationService.verifyTimeLimit();
      
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Time verification result: ${result.status}');
      }
      
      if (result.status == VerificationStatus.valid) {
        if (kDebugMode) {
          debugPrint('[AppAccessControlService] Access granted');
        }
        
        return AccessCheckResult(
          isAccessGranted: true,
          message: result.message,
        );
      } else if (result.shouldBlock) {
        if (kDebugMode) {
          debugPrint('[AppAccessControlService] Access denied - ${result.status}');
        }
        
        // Block user and cleanup data
        await _timeVerificationService.blockUserAndClearData(
          result.message ?? 'Access expired',
        );
        
        return AccessCheckResult(
          isAccessGranted: false,
          reason: AccessDenialReason.expired,
          message: result.message ?? 'Access period has expired',
        );
      } else {
        // Network error or other issue - allow with warning
        return AccessCheckResult(
          isAccessGranted: true,
          message: result.message ?? 'Verification pending',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Error checking access with internet: $e');
      }
      
      // Fallback to offline check if verification fails
      return await _checkAccessWithoutInternet();
    }
  }
  
  /// Check access when internet is not available
  Future<AccessCheckResult> _checkAccessWithoutInternet() async {
    try {
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Checking access without internet');
      }
      
      // Verify time limit with TimeVerificationService (offline mode)
      final result = await _timeVerificationService.verifyTimeLimit();
      
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Offline verification result: ${result.status}');
      }
      
      if (result.status == VerificationStatus.valid) {
        if (kDebugMode) {
          debugPrint('[AppAccessControlService] Offline access granted');
        }
        
        return AccessCheckResult(
          isAccessGranted: true,
          isOfflineMode: true,
          message: result.message,
        );
      } else if (result.status == VerificationStatus.noTimeLimit) {
        // No time limit stored - first-time user must be online
        if (kDebugMode) {
          debugPrint('[AppAccessControlService] No time limit - internet required');
        }
        
        return AccessCheckResult(
          isAccessGranted: false,
          reason: AccessDenialReason.noInternet,
          message: result.message ?? 'Internet connection required for first-time access',
        );
      } else {
        // Expired or other blocking status
        if (kDebugMode) {
          debugPrint('[AppAccessControlService] Offline access denied - ${result.status}');
        }
        
        return AccessCheckResult(
          isAccessGranted: false,
          reason: AccessDenialReason.expired,
          message: result.message ?? 'Access expired',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Error checking access without internet: $e');
      }
      
      return AccessCheckResult(
        isAccessGranted: false,
        reason: AccessDenialReason.error,
        message: 'Error checking access: ${e.toString()}',
      );
    }
  }
  
  /// Get access status information
  Future<AccessStatusInfo?> getAccessStatusInfo() async {
    try {
      final timeLimit = _prefsService.getTimeLimit();
      if (timeLimit == null) {
        return null;
      }
      
      final now = DateTime.now();
      final daysRemaining = timeLimit.difference(now).inDays;
      final isValid = now.isBefore(timeLimit);
      
      return AccessStatusInfo(
        validityDate: timeLimit,
        daysRemaining: daysRemaining,
        isValid: isValid,
        lastAccessTimestamp: null,
        lastVerifiedTime: null,
        statusDescription: isValid 
            ? 'Access valid until ${timeLimit.toLocal()}'
            : 'Access expired on ${timeLimit.toLocal()}',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Error getting access status: $e');
      }
      return null;
    }
  }
  
  /// Dispose of resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _accessRevokedController.close();
    _connectivityService.dispose();
    
    if (kDebugMode) {
      debugPrint('[AppAccessControlService] Disposed');
    }
  }
}

/// Result of an access check operation
class AccessCheckResult {
  final bool isAccessGranted;
  final AccessDenialReason? reason;
  final String? message;
  final DateTime? verifiedTime;
  final bool isOfflineMode;
  final int? daysRemaining;
  
  AccessCheckResult({
    required this.isAccessGranted,
    this.reason,
    this.message,
    this.verifiedTime,
    this.isOfflineMode = false,
    this.daysRemaining,
  });
  
  @override
  String toString() {
    return 'AccessCheckResult(granted: $isAccessGranted, reason: $reason, offline: $isOfflineMode, days: $daysRemaining)';
  }
}

/// Reasons for access denial
enum AccessDenialReason {
  expired,
  timeManipulation,
  internetRequired,
  noInternet,
  error,
}

/// Information about current access status
class AccessStatusInfo {
  final DateTime validityDate;
  final int daysRemaining;
  final bool isValid;
  final DateTime? lastAccessTimestamp;
  final DateTime? lastVerifiedTime;
  final String statusDescription;
  
  AccessStatusInfo({
    required this.validityDate,
    required this.daysRemaining,
    required this.isValid,
    this.lastAccessTimestamp,
    this.lastVerifiedTime,
    required this.statusDescription,
  });
}
