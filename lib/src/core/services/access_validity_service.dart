import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

/// Service responsible for managing app access validity based on expiration date
/// 
/// This service handles:
/// - Checking if the app access has expired based on a hardcoded validity date
/// - Storing and retrieving the last successful access timestamp
/// - Comparing device time with stored timestamps to detect time manipulation
/// 
/// The validity date is currently hardcoded but can be easily modified to be
/// fetched from a remote server or configuration file in the future.
class AccessValidityService {
  final SharedPreferencesService _prefsService;
  
  // Hardcoded access validity date - can be modified or fetched from server
  // Format: YYYY-MM-DD
  static const String _validityDateString = '2026-01-20';
  
  // SharedPreferences keys
  static const String _lastAccessTimestampKey = 'last_successful_access_timestamp';
  static const String _lastVerifiedRealTimeKey = 'last_verified_real_time';
  
  AccessValidityService({
    required SharedPreferencesService prefsService,
  }) : _prefsService = prefsService;
  
  /// Get the hardcoded validity date
  DateTime get validityDate {
    try {
      return DateTime.parse(_validityDateString);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AccessValidityService] Error parsing validity date: $e');
      }
      // Return a default date far in the future if parsing fails
      return DateTime(2099, 12, 31);
    }
  }
  
  /// Check if access is still valid based on the provided current time
  /// 
  /// [currentTime] - The time to check against (can be device time or verified real time)
  /// Returns true if access is valid, false if expired
  bool isAccessValid(DateTime currentTime) {
    final isValid = currentTime.isBefore(validityDate);
    
    if (kDebugMode) {
      debugPrint('[AccessValidityService] Checking access validity');
      debugPrint('[AccessValidityService] Current time: $currentTime');
      debugPrint('[AccessValidityService] Validity date: $validityDate');
      debugPrint('[AccessValidityService] Is valid: $isValid');
    }
    
    return isValid;
  }
  
  /// Get the last successful access timestamp from local storage
  /// 
  /// Returns null if no timestamp is stored
  DateTime? getLastAccessTimestamp() {
    try {
      final timestamp = _prefsService.preferences.getInt(_lastAccessTimestampKey);
      if (timestamp == null) {
        return null;
      }
      
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      
      if (kDebugMode) {
        debugPrint('[AccessValidityService] Retrieved last access timestamp: $dateTime');
      }
      
      return dateTime;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AccessValidityService] Error retrieving last access timestamp: $e');
      }
      return null;
    }
  }
  
  /// Save the current access timestamp to local storage
  /// 
  /// [timestamp] - The timestamp to save (defaults to current time)
  Future<void> saveLastAccessTimestamp([DateTime? timestamp]) async {
    try {
      final timeToSave = timestamp ?? DateTime.now();
      final milliseconds = timeToSave.millisecondsSinceEpoch;
      
      await _prefsService.preferences.setInt(_lastAccessTimestampKey, milliseconds);
      
      if (kDebugMode) {
        debugPrint('[AccessValidityService] Saved last access timestamp: $timeToSave');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AccessValidityService] Error saving last access timestamp: $e');
      }
    }
  }
  
  /// Get the last verified real time from Gemini/AI service
  /// 
  /// Returns null if no verified time is stored
  DateTime? getLastVerifiedRealTime() {
    try {
      final timestamp = _prefsService.preferences.getInt(_lastVerifiedRealTimeKey);
      if (timestamp == null) {
        return null;
      }
      
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      
      if (kDebugMode) {
        debugPrint('[AccessValidityService] Retrieved last verified real time: $dateTime');
      }
      
      return dateTime;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AccessValidityService] Error retrieving last verified real time: $e');
      }
      return null;
    }
  }
  
  /// Save the verified real time from Gemini/AI service
  /// 
  /// [verifiedTime] - The verified real time to save
  Future<void> saveLastVerifiedRealTime(DateTime verifiedTime) async {
    try {
      final milliseconds = verifiedTime.millisecondsSinceEpoch;
      
      await _prefsService.preferences.setInt(_lastVerifiedRealTimeKey, milliseconds);
      
      if (kDebugMode) {
        debugPrint('[AccessValidityService] Saved last verified real time: $verifiedTime');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AccessValidityService] Error saving last verified real time: $e');
      }
    }
  }
  
  /// Check if device time has been manipulated (moved backwards)
  /// 
  /// Compares current device time with the last stored access timestamp
  /// Returns true if time manipulation is detected
  bool isTimeManipulated() {
    final lastAccess = getLastAccessTimestamp();
    if (lastAccess == null) {
      // No previous access recorded, cannot detect manipulation
      return false;
    }
    
    final currentTime = DateTime.now();
    final isManipulated = currentTime.isBefore(lastAccess);
    
    if (kDebugMode) {
      debugPrint('[AccessValidityService] Checking time manipulation');
      debugPrint('[AccessValidityService] Last access: $lastAccess');
      debugPrint('[AccessValidityService] Current time: $currentTime');
      debugPrint('[AccessValidityService] Time manipulated: $isManipulated');
    }
    
    return isManipulated;
  }
  
  /// Clear all stored access data
  /// 
  /// This should be called when access is revoked or app data needs to be reset
  Future<void> clearAccessData() async {
    try {
      await _prefsService.preferences.remove(_lastAccessTimestampKey);
      await _prefsService.preferences.remove(_lastVerifiedRealTimeKey);
      
      if (kDebugMode) {
        debugPrint('[AccessValidityService] Cleared all access data');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AccessValidityService] Error clearing access data: $e');
      }
    }
  }
  
  /// Get days remaining until access expires
  /// 
  /// [currentTime] - The time to check against (defaults to device time)
  /// Returns negative number if already expired
  int getDaysRemaining([DateTime? currentTime]) {
    final checkTime = currentTime ?? DateTime.now();
    final difference = validityDate.difference(checkTime);
    return difference.inDays;
  }
  
  /// Get a human-readable string describing the access status
  /// 
  /// [currentTime] - The time to check against (defaults to device time)
  String getAccessStatusDescription([DateTime? currentTime]) {
    final checkTime = currentTime ?? DateTime.now();
    final daysRemaining = getDaysRemaining(checkTime);
    
    if (daysRemaining < 0) {
      return 'Access expired ${daysRemaining.abs()} days ago';
    } else if (daysRemaining == 0) {
      return 'Access expires today';
    } else if (daysRemaining == 1) {
      return 'Access expires tomorrow';
    } else if (daysRemaining <= 7) {
      return 'Access expires in $daysRemaining days (Warning)';
    } else {
      return 'Access valid for $daysRemaining days';
    }
  }
}
