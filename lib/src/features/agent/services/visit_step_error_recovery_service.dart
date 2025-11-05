import 'dart:async';
import 'dart:convert';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/visit_data_repository.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

/// Error recovery strategies
enum RecoveryStrategy {
  retry,
  fallback,
  manualIntervention,
  skip,
}

/// Error types for visit steps
enum VisitStepError {
  networkError,
  validationError,
  storageError,
  syncError,
  permissionError,
  timeoutError,
}

/// Error recovery configuration
class ErrorRecoveryConfig {
  final int maxRetries;
  final Duration retryDelay;
  final Duration timeout;
  final RecoveryStrategy strategy;
  final bool enableFallback;

  const ErrorRecoveryConfig({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 5),
    this.timeout = const Duration(seconds: 30),
    this.strategy = RecoveryStrategy.retry,
    this.enableFallback = true,
  });
}

/// Error recovery service for visit steps
class VisitStepErrorRecoveryService {
  final VisitDataRepository _visitDataRepository;
  final SharedPreferencesService _prefs;

  static const String _failedOperationsKey = 'visit_step_failed_operations';
  static const String _recoveryAttemptsKey = 'visit_step_recovery_attempts';

  final Map<String, Timer> _retryTimers = {};
  final Map<String, int> _retryCounts = {};

  VisitStepErrorRecoveryService({
    required VisitDataRepository visitDataRepository,
    required SharedPreferencesService prefs,
  }) : _visitDataRepository = visitDataRepository,
       _prefs = prefs;

  /// Handle error and attempt recovery
  Future<bool> handleError({
    required String operationId,
    required VisitStepError error,
    required dynamic errorData,
    required ErrorRecoveryConfig config,
    required Future<bool> Function() retryOperation,
  }) async {
    print('Handling error for operation $operationId: $error');

    // Log the error
    await _logError(operationId, error, errorData);

    // Determine recovery strategy
    final strategy = _determineRecoveryStrategy(error, config);

    switch (strategy) {
      case RecoveryStrategy.retry:
        return await _attemptRetry(operationId, config, retryOperation);

      case RecoveryStrategy.fallback:
        return await _attemptFallback(operationId, error, errorData);

      case RecoveryStrategy.manualIntervention:
        await _scheduleManualIntervention(operationId, error, errorData);
        return false;

      case RecoveryStrategy.skip:
        await _skipOperation(operationId);
        return false;
    }
  }

  /// Attempt retry with exponential backoff
  Future<bool> _attemptRetry(
    String operationId,
    ErrorRecoveryConfig config,
    Future<bool> Function() retryOperation,
  ) async {
    final currentAttempts = _retryCounts[operationId] ?? 0;

    if (currentAttempts >= config.maxRetries) {
      print('Max retries exceeded for operation $operationId');
      await _scheduleManualIntervention(operationId, VisitStepError.timeoutError, null);
      return false;
    }

    _retryCounts[operationId] = currentAttempts + 1;

    // Calculate delay with exponential backoff
    final delay = config.retryDelay * (1 << currentAttempts); // 2^attempts

    print('Scheduling retry for operation $operationId in ${delay.inSeconds}s (attempt ${currentAttempts + 1})');

    _retryTimers[operationId]?.cancel();
    _retryTimers[operationId] = Timer(delay, () async {
      try {
        final success = await retryOperation.timeout(config.timeout);
        if (success) {
          print('Retry successful for operation $operationId');
          await _clearError(operationId);
          _retryCounts.remove(operationId);
        } else {
          // Try again if still failing
          await _attemptRetry(operationId, config, retryOperation);
        }
      } catch (e) {
        print('Retry failed for operation $operationId: $e');
        await _attemptRetry(operationId, config, retryOperation);
      }
    });

    return false; // Not successful yet
  }

  /// Attempt fallback operation
  Future<bool> _attemptFallback(String operationId, VisitStepError error, dynamic errorData) async {
    print('Attempting fallback for operation $operationId');

    try {
      switch (error) {
        case VisitStepError.networkError:
          // Try offline storage as fallback
          return await _storeOffline(operationId, errorData);

        case VisitStepError.storageError:
          // Try alternative storage method
          return await _storeAlternative(operationId, errorData);

        case VisitStepError.validationError:
          // Try to fix validation issues automatically
          return await _fixValidationIssues(operationId, errorData);

        default:
          return false;
      }
    } catch (e) {
      print('Fallback failed for operation $operationId: $e');
      return false;
    }
  }

  /// Store data offline as fallback
  Future<bool> _storeOffline(String operationId, dynamic errorData) async {
    try {
      // Mark data as requiring sync later
      await _visitDataRepository.markDataForOfflineSync(operationId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Store using alternative method
  Future<bool> _storeAlternative(String operationId, dynamic errorData) async {
    try {
      // Try different storage approach
      await _visitDataRepository.saveWithAlternativeMethod(operationId, errorData);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fix validation issues automatically
  Future<bool> _fixValidationIssues(String operationId, dynamic errorData) async {
    try {
      // Attempt to fix common validation issues
      final fixedData = await _autoFixValidationErrors(errorData);
      await _visitDataRepository.saveFixedData(operationId, fixedData);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Schedule manual intervention
  Future<void> _scheduleManualIntervention(String operationId, VisitStepError error, dynamic errorData) async {
    print('Scheduling manual intervention for operation $operationId');

    final failedOperation = {
      'operationId': operationId,
      'error': error.toString(),
      'errorData': errorData,
      'timestamp': DateTime.now().toIso8601String(),
      'requiresManualIntervention': true,
    };

    await _storeFailedOperation(failedOperation);
  }

  /// Skip operation
  Future<void> _skipOperation(String operationId) async {
    print('Skipping operation $operationId');

    await _visitDataRepository.markOperationAsSkipped(operationId);
    await _clearError(operationId);
  }

  /// Determine recovery strategy based on error type
  RecoveryStrategy _determineRecoveryStrategy(VisitStepError error, ErrorRecoveryConfig config) {
    switch (error) {
      case VisitStepError.networkError:
        return config.enableFallback ? RecoveryStrategy.fallback : RecoveryStrategy.retry;

      case VisitStepError.validationError:
        return config.enableFallback ? RecoveryStrategy.fallback : RecoveryStrategy.manualIntervention;

      case VisitStepError.storageError:
        return RecoveryStrategy.retry;

      case VisitStepError.syncError:
        return RecoveryStrategy.retry;

      case VisitStepError.permissionError:
        return RecoveryStrategy.manualIntervention;

      case VisitStepError.timeoutError:
        return RecoveryStrategy.skip;
    }
  }

  /// Auto-fix common validation errors
  Future<Map<String, dynamic>> _autoFixValidationErrors(dynamic errorData) async {
    if (errorData is! Map<String, dynamic>) return errorData;

    final fixedData = Map<String, dynamic>.from(errorData);

    // Fix common issues
    if (fixedData['notes'] == null) {
      fixedData['notes'] = '';
    }

    if (fixedData['timestamp'] == null) {
      fixedData['timestamp'] = DateTime.now().toIso8601String();
    }

    if (fixedData['stepCode'] is String) {
      fixedData['stepCode'] = int.tryParse(fixedData['stepCode']) ?? 0;
    }

    return fixedData;
  }

  /// Log error for debugging
  Future<void> _logError(String operationId, VisitStepError error, dynamic errorData) async {
    final errorLog = {
      'operationId': operationId,
      'error': error.toString(),
      'errorData': errorData?.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    final existingLogs = await _getErrorLogs();
    existingLogs.add(errorLog);

    // Keep only last 100 error logs
    if (existingLogs.length > 100) {
      existingLogs.removeRange(0, existingLogs.length - 100);
    }

    await _prefs.setString('visit_step_error_logs', jsonEncode(existingLogs));
  }

  /// Clear error from logs
  Future<void> _clearError(String operationId) async {
    final logs = await _getErrorLogs();
    logs.removeWhere((log) => log['operationId'] == operationId);
    await _prefs.setString('visit_step_error_logs', jsonEncode(logs));
  }

  /// Get error logs
  Future<List<Map<String, dynamic>>> _getErrorLogs() async {
    final logsJson = await _prefs.getString('visit_step_error_logs') ?? '[]';
    final logs = jsonDecode(logsJson) as List;
    return logs.map((log) => log as Map<String, dynamic>).toList();
  }

  /// Store failed operation
  Future<void> _storeFailedOperation(Map<String, dynamic> operation) async {
    final failedOps = await _getFailedOperations();
    failedOps.add(operation);
    await _prefs.setString(_failedOperationsKey, jsonEncode(failedOps));
  }

  /// Get failed operations
  Future<List<Map<String, dynamic>>> _getFailedOperations() async {
    final opsJson = await _prefs.getString(_failedOperationsKey) ?? '[]';
    final ops = jsonDecode(opsJson) as List;
    return ops.map((op) => op as Map<String, dynamic>).toList();
  }

  /// Process failed operations (called during app startup)
  Future<void> processFailedOperations() async {
    final failedOps = await _getFailedOperations();

    for (final op in failedOps) {
      // Try to recover failed operations
      print('Processing failed operation: ${op['operationId']}');
      // Implementation would depend on specific operation type
    }
  }

  /// Get recovery status
  Future<Map<String, dynamic>> getRecoveryStatus() async {
    final failedOps = await _getFailedOperations();
    final errorLogs = await _getErrorLogs();

    return {
      'failedOperationsCount': failedOps.length,
      'errorLogsCount': errorLogs.length,
      'activeRetries': _retryTimers.length,
      'retryCounts': Map.from(_retryCounts),
    };
  }

  /// Clear all recovery data (for testing or reset)
  Future<void> clearRecoveryData() async {
    await _prefs.setString(_failedOperationsKey, '[]');
    await _prefs.setString('visit_step_error_logs', '[]');

    for (final timer in _retryTimers.values) {
      timer.cancel();
    }
    _retryTimers.clear();
    _retryCounts.clear();
  }

  /// Dispose resources
  void dispose() {
    for (final timer in _retryTimers.values) {
      timer.cancel();
    }
    _retryTimers.clear();
    _retryCounts.clear();
  }
}