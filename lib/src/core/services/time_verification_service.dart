import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/network/api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/features/time_verification/domain/entities/time_verification_result.dart';
import 'package:gloria_marketing_flutter/src/features/time_verification/domain/repositories/time_verification_repository.dart';

/// Service for managing server time verification and user access control
/// 
/// Implements the core business logic for:
/// - Fetching server time and time limit
/// - Verifying user access (online and offline)
/// - Managing time limit in preferences
/// - Blocking users and clearing data when expired
class TimeVerificationService {
  final TimeVerificationRepository _repository;
  final SharedPreferencesService _prefs;
  final DataSyncService _dataSyncService;

  TimeVerificationService({
    required TimeVerificationRepository repository,
    required SharedPreferencesService prefs,
    required DataSyncService dataSyncService,
  })  : _repository = repository,
        _prefs = prefs,
        _dataSyncService = dataSyncService;

  /// Main verification method - determines online/offline verification
  /// 
  /// Flow:
  /// 1. Try online verification (fetch from server)
  /// 2. If network error and has stored limit -> offline verification
  /// 3. If network error and no stored limit -> block access
  /// 
  /// Returns [TimeVerificationResult] with status and action to take
  Future<TimeVerificationResult> verifyTimeLimit() async {
    try {
      if (kDebugMode) {
        print('[TimeVerificationService] Starting time limit verification...');
      }

      // Try online verification first
      return await _verifyOnline();
    } on ConnectivityException {
      if (kDebugMode) {
        print('[TimeVerificationService] Network error, attempting offline verification...');
      }
      
      // Network error - try offline verification
      return await _verifyOffline();
    } on AllServersUnavailableException {
      if (kDebugMode) {
        print('[TimeVerificationService] All servers unavailable, attempting offline verification...');
      }
      
      // All servers down - try offline verification
      return await _verifyOffline();
    } catch (e) {
      if (kDebugMode) {
        print('[TimeVerificationService] Unexpected error during verification: $e');
      }
      
      // Unexpected error - return network error result
      return TimeVerificationResult.networkError(
        message: 'Verification failed: $e',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Online verification - fetch from server and verify
  /// 
  /// Steps:
  /// 1. Fetch server time and time limit from API
  /// 2. Update time limit in preferences
  /// 3. Check if server time exceeds limit
  /// 4. Return result
  Future<TimeVerificationResult> _verifyOnline() async {
    try {
      if (kDebugMode) {
        print('[TimeVerificationService] Performing online verification...');
      }

      // Fetch server time and limit
      final serverTime = await _repository.getServerTime();

      if (kDebugMode) {
        print('[TimeVerificationService] Server time: ${serverTime.serverTime}');
        print('[TimeVerificationService] Time limit: ${serverTime.timeLimit}');
      }

      // Update time limit in preferences
      await updateTimeLimit(serverTime.timeLimit);

      // Check if expired
      if (serverTime.isExpired()) {
        if (kDebugMode) {
          print('[TimeVerificationService] Time limit EXPIRED');
        }
        
        return TimeVerificationResult.expired(
          message: 'Your access period has expired. Please contact support.',
        );
      }

      if (kDebugMode) {
        print('[TimeVerificationService] Time limit VALID');
        print('[TimeVerificationService] Remaining time: ${serverTime.getRemainingTime()}');
      }

      return TimeVerificationResult.valid(
        message: 'Access verified successfully',
      );
    } catch (e) {
      if (kDebugMode) {
        print('[TimeVerificationService] Online verification failed: $e');
      }
      rethrow;
    }
  }

  /// Offline verification - use local time and stored limit
  /// 
  /// Steps:
  /// 1. Check if time limit exists in preferences
  /// 2. If no limit -> block (first-time user must be online)
  /// 3. If has limit -> compare with local device time
  /// 4. Return result
  Future<TimeVerificationResult> _verifyOffline() async {
    try {
      if (kDebugMode) {
        print('[TimeVerificationService] Performing offline verification...');
      }

      // Check if time limit exists
      if (!_prefs.hasTimeLimit()) {
        if (kDebugMode) {
          print('[TimeVerificationService] No time limit found - first-time user must be online');
        }
        
        return TimeVerificationResult.noTimeLimit(
          message: 'Internet connection required for first-time access',
        );
      }

      final storedLimit = _prefs.getTimeLimit();
      if (storedLimit == null) {
        if (kDebugMode) {
          print('[TimeVerificationService] Failed to retrieve stored time limit');
        }
        
        return TimeVerificationResult.noTimeLimit(
          message: 'Unable to verify access offline',
        );
      }

      // Get local device time
      final localTime = DateTime.now();

      if (kDebugMode) {
        print('[TimeVerificationService] Local time: $localTime');
        print('[TimeVerificationService] Stored limit: $storedLimit');
      }

      // Check if expired
      if (localTime.isAfter(storedLimit)) {
        if (kDebugMode) {
          print('[TimeVerificationService] Time limit EXPIRED (offline check)');
        }
        
        return TimeVerificationResult.expired(
          message: 'Your access period has expired. Please connect to internet.',
        );
      }

      if (kDebugMode) {
        final remaining = storedLimit.difference(localTime);
        print('[TimeVerificationService] Time limit VALID (offline check)');
        print('[TimeVerificationService] Remaining time: $remaining');
      }

      return TimeVerificationResult.valid(
        message: 'Access verified (offline mode)',
      );
    } catch (e) {
      if (kDebugMode) {
        print('[TimeVerificationService] Offline verification failed: $e');
      }
      
      return TimeVerificationResult.networkError(
        message: 'Offline verification error: $e',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Update time limit in preferences
  /// 
  /// Called after successful online verification
  Future<void> updateTimeLimit(DateTime limit) async {
    try {
      await _prefs.setTimeLimit(limit);
      
      if (kDebugMode) {
        print('[TimeVerificationService] Time limit updated: ${limit.toIso8601String()}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[TimeVerificationService] Failed to update time limit: $e');
      }
      rethrow;
    }
  }

  /// Get stored time limit from preferences
  DateTime? getStoredTimeLimit() {
    return _prefs.getTimeLimit();
  }

  /// Check if valid time limit exists
  bool hasValidTimeLimit() {
    return _prefs.hasTimeLimit();
  }

  /// Block user and clear all data
  /// 
  /// Called when time limit is expired
  /// Clears:
  /// - All database tables
  /// - User data from preferences (keeps time limit for audit)
  /// - Offline mode flag
  Future<void> blockUserAndClearData(String reason) async {
    try {
      if (kDebugMode) {
        print('[TimeVerificationService] Blocking user and clearing data...');
        print('[TimeVerificationService] Reason: $reason');
      }

      // Clear database using DataSyncService
      await _dataSyncService.clearAllCachedData();
      if (kDebugMode) {
        print('[TimeVerificationService] Database cleared');
      }

      // Clear user data from preferences (keep time limit for audit)
      await _prefs.clearUserData();
      if (kDebugMode) {
        print('[TimeVerificationService] User data cleared from preferences');
      }

      // Clear offline mode
      await _prefs.clearOfflineMode();
      if (kDebugMode) {
        print('[TimeVerificationService] Offline mode cleared');
      }

      // Log the block event
      await _logBlockEvent(reason);

      if (kDebugMode) {
        print('[TimeVerificationService] User blocked successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[TimeVerificationService] Error blocking user: $e');
      }
      rethrow;
    }
  }

  /// Log block event for audit purposes
  Future<void> _logBlockEvent(String reason) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final userCode = _prefs.getUserCode() ?? 'unknown';
      
      if (kDebugMode) {
        print('[TimeVerificationService] AUDIT LOG: User blocked');
        print('[TimeVerificationService] Timestamp: $timestamp');
        print('[TimeVerificationService] User code: $userCode');
        print('[TimeVerificationService] Reason: $reason');
      }

      // TODO: Send to analytics/logging service if needed
    } catch (e) {
      if (kDebugMode) {
        print('[TimeVerificationService] Failed to log block event: $e');
      }
      // Don't throw - logging failure shouldn't prevent blocking
    }
  }

  /// Force refresh time limit from server
  /// 
  /// Useful when user manually triggers refresh or connectivity is restored
  Future<TimeVerificationResult> refreshTimeLimit() async {
    try {
      if (kDebugMode) {
        print('[TimeVerificationService] Force refreshing time limit from server...');
      }

      return await _verifyOnline();
    } catch (e) {
      if (kDebugMode) {
        print('[TimeVerificationService] Failed to refresh time limit: $e');
      }
      
      if (e is ConnectivityException || e is AllServersUnavailableException) {
        return TimeVerificationResult.networkError(
          message: 'Unable to connect to server. Please check your internet connection.',
          exception: e is Exception ? e : Exception(e.toString()),
        );
      }
      
      rethrow;
    }
  }

  /// Clear time limit from preferences
  /// 
  /// Use with caution - only for logout or data reset
  Future<void> clearTimeLimit() async {
    try {
      await _prefs.clearTimeLimit();
      
      if (kDebugMode) {
        print('[TimeVerificationService] Time limit cleared from preferences');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[TimeVerificationService] Failed to clear time limit: $e');
      }
      rethrow;
    }
  }
}
