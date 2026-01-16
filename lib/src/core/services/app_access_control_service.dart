import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/services/access_validity_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/connectivity_monitoring_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
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
  final AccessValidityService _validityService;
  final ConnectivityMonitoringService _connectivityService;
  final SoapApiService _soapApiService;
  final SharedPreferencesService _prefsService;
  final DatabaseHelper _databaseHelper;
  
  // Stream subscription for connectivity changes
  StreamSubscription<bool>? _connectivitySubscription;
  
  // Flag to track if service is initialized
  bool _isInitialized = false;
  
  AppAccessControlService({
    required AccessValidityService validityService,
    required ConnectivityMonitoringService connectivityService,
    required SoapApiService soapApiService,
    required SharedPreferencesService prefsService,
    required DatabaseHelper databaseHelper,
  }) : _validityService = validityService,
       _connectivityService = connectivityService,
       _soapApiService = soapApiService,
       _prefsService = prefsService,
       _databaseHelper = databaseHelper;
  
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
      // Verify real time with server SOAP API
      final verifiedTime = await _soapApiService.getServerTime();
      
      // Save verified time
      await _validityService.saveLastVerifiedRealTime(verifiedTime);
      
      // Check if access is still valid
      if (!_validityService.isAccessValid(verifiedTime)) {
        if (kDebugMode) {
          debugPrint('[AppAccessControlService] Access expired - revoking access');
        }
        
        // Revoke access and cleanup
        await revokeAccessAndCleanup();
      } else {
        if (kDebugMode) {
          debugPrint('[AppAccessControlService] Access still valid');
        }
        
        // Update last access timestamp
        await _validityService.saveLastAccessTimestamp(verifiedTime);
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
      
      // Get verified real time from server SOAP API
      final verifiedTime = await _soapApiService.getServerTime();
      
      // Save verified time
      await _validityService.saveLastVerifiedRealTime(verifiedTime);
      
      // Check if access is valid
      final isValid = _validityService.isAccessValid(verifiedTime);
      
      if (isValid) {
        // Save last access timestamp
        await _validityService.saveLastAccessTimestamp(verifiedTime);
        
        if (kDebugMode) {
          debugPrint('[AppAccessControlService] Access granted - valid until ${_validityService.validityDate}');
        }
        
        return AccessCheckResult(
          isAccessGranted: true,
          verifiedTime: verifiedTime,
          daysRemaining: _validityService.getDaysRemaining(verifiedTime),
        );
      } else {
        if (kDebugMode) {
          debugPrint('[AppAccessControlService] Access denied - expired');
        }
        
        // Revoke access and cleanup
        await revokeAccessAndCleanup();
        
        return AccessCheckResult(
          isAccessGranted: false,
          reason: AccessDenialReason.expired,
          message: 'Access period has expired',
          verifiedTime: verifiedTime,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Error checking access with internet: $e');
      }
      
      // Fallback to offline check if server time fails
      return await _checkAccessWithoutInternet();
    }
  }
  
  /// Check access when internet is not available
  Future<AccessCheckResult> _checkAccessWithoutInternet() async {
    try {
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Checking access without internet');
      }
      
      // Get device time
      final deviceTime = DateTime.now();
      
      // Check for time manipulation
      if (_validityService.isTimeManipulated()) {
        if (kDebugMode) {
          debugPrint('[AppAccessControlService] Time manipulation detected');
        }
        
        return AccessCheckResult(
          isAccessGranted: false,
          reason: AccessDenialReason.timeManipulation,
          message: 'Device time has been manipulated',
        );
      }
      
      // Get last access timestamp
      final lastAccess = _validityService.getLastAccessTimestamp();
      
      if (lastAccess == null) {
        // No previous access recorded - require internet for first time setup
        if (kDebugMode) {
          debugPrint('[AppAccessControlService] No previous access - internet required');
        }
        
        return AccessCheckResult(
          isAccessGranted: false,
          reason: AccessDenialReason.internetRequired,
          message: 'Internet connection required for first time setup',
        );
      }
      
      // Verify device time is after last access
      if (deviceTime.isBefore(lastAccess)) {
        if (kDebugMode) {
          debugPrint('[AppAccessControlService] Device time is before last access');
        }
        
        return AccessCheckResult(
          isAccessGranted: false,
          reason: AccessDenialReason.timeManipulation,
          message: 'Device time inconsistency detected',
        );
      }
      
      // Check if access is still valid based on device time
      final isValid = _validityService.isAccessValid(deviceTime);
      
      if (isValid) {
        // Update last access timestamp
        await _validityService.saveLastAccessTimestamp(deviceTime);
        
        if (kDebugMode) {
          debugPrint('[AppAccessControlService] Access granted (offline mode)');
        }
        
        return AccessCheckResult(
          isAccessGranted: true,
          isOfflineMode: true,
          daysRemaining: _validityService.getDaysRemaining(deviceTime),
        );
      } else {
        if (kDebugMode) {
          debugPrint('[AppAccessControlService] Access denied - expired (offline mode)');
        }
        
        // Revoke access and cleanup
        await revokeAccessAndCleanup();
        
        return AccessCheckResult(
          isAccessGranted: false,
          reason: AccessDenialReason.expired,
          message: 'Access period has expired',
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
  
  /// Revoke access and cleanup all data
  /// 
  /// This method:
  /// - Clears all local database data
  /// - Clears all cached data
  /// - Clears all SharedPreferences data
  /// - Clears access timestamps
  Future<void> revokeAccessAndCleanup() async {
    try {
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Revoking access and cleaning up data');
      }
      
      // Clear database
      await _clearDatabase();
      
      // Clear SharedPreferences (except critical system data)
      await _clearSharedPreferences();
      
      // Clear access data
      await _validityService.clearAccessData();
      
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Data cleanup completed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Error during data cleanup: $e');
      }
      rethrow;
    }
  }
  
  /// Clear all database data
  Future<void> _clearDatabase() async {
    try {
      final db = await _databaseHelper.database;
      
      // Get all table names
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );
      
      // Delete all data from each table
      for (final table in tables) {
        final tableName = table['name'] as String;
        await db.delete(tableName);
        if (kDebugMode) {
          debugPrint('[AppAccessControlService] Cleared table: $tableName');
        }
      }
      
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Database cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Error clearing database: $e');
      }
    }
  }
  
  /// Clear SharedPreferences data
  /// 
  /// Preserves critical system settings like language preference
  Future<void> _clearSharedPreferences() async {
    try {
      // Get current language setting to preserve it
      final currentLanguage = _prefsService.preferences.getString('language');
      
      // Clear all preferences
      await _prefsService.preferences.clear();
      
      // Restore language setting
      if (currentLanguage != null) {
        await _prefsService.preferences.setString('language', currentLanguage);
      }
      
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] SharedPreferences cleared (language preserved)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppAccessControlService] Error clearing SharedPreferences: $e');
      }
    }
  }
  
  /// Get access status information
  AccessStatusInfo getAccessStatusInfo() {
    final deviceTime = DateTime.now();
    final lastAccess = _validityService.getLastAccessTimestamp();
    final lastVerified = _validityService.getLastVerifiedRealTime();
    final daysRemaining = _validityService.getDaysRemaining(deviceTime);
    final isValid = _validityService.isAccessValid(deviceTime);
    
    return AccessStatusInfo(
      validityDate: _validityService.validityDate,
      daysRemaining: daysRemaining,
      isValid: isValid,
      lastAccessTimestamp: lastAccess,
      lastVerifiedTime: lastVerified,
      statusDescription: _validityService.getAccessStatusDescription(deviceTime),
    );
  }
  
  /// Dispose of resources
  void dispose() {
    _connectivitySubscription?.cancel();
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
