import 'dart:async';

import 'package:flutter/foundation.dart';

/// Result of a cached sync operation.
/// 
/// Contains information about whether the operation was executed or skipped,
/// along with any error that occurred.
class SyncCacheResult {
  /// Whether this was the first call that actually executed the function.
  final bool wasExecuted;
  
  /// Whether this call was skipped because the function was already running.
  final bool wasSkipped;
  
  /// Any error that occurred during execution.
  final Object? error;
  
  /// Stack trace if an error occurred.
  final StackTrace? stackTrace;

  const SyncCacheResult({
    required this.wasExecuted,
    required this.wasSkipped,
    this.error,
    this.stackTrace,
  });

  /// Whether the operation completed successfully.
  bool get isSuccess => error == null;

  /// Whether there was an error.
  bool get hasError => error != null;
}

/// Cache service to prevent duplicate sync function calls during a sync session.
/// 
/// This eliminates redundant API calls when multiple tables use the same
/// sync function. For example, product_balances, product_brands, and 
/// product_series all call syncProductBalances - with this cache, 
/// only the first call executes, others wait for its result.
/// 
/// ## Usage
/// ```dart
/// // Instead of calling directly:
/// await ds.syncProductBalances(codeProject, codeSklad);
/// 
/// // Use the cache:
/// await SyncFunctionCache.instance.runOnce(
///   'product_balances_group',
///   () => ds.syncProductBalances(codeProject, codeSklad),
/// );
/// ```
/// 
/// ## Thread Safety
/// Uses Completer pattern to ensure only one execution per key,
/// even when multiple callers request the same key simultaneously.
/// 
/// ## Memory Efficiency
/// - O(n) space where n = number of unique sync function keys
/// - Automatically clears after sync session ends
/// - Typical usage: ~10-15 keys = negligible memory footprint
class SyncFunctionCache {
  SyncFunctionCache._();

  static final SyncFunctionCache _instance = SyncFunctionCache._();
  
  /// Singleton instance for global access.
  static SyncFunctionCache get instance => _instance;

  /// Map of currently running sync functions.
  /// Key: unique identifier for the sync function group
  /// Value: Completer that resolves when the function completes
  final Map<String, Completer<SyncCacheResult>> _runningFunctions = {};

  /// Map of completed results for the current sync session.
  /// Allows subsequent calls to immediately return without waiting.
  final Map<String, SyncCacheResult> _completedResults = {};

  /// Statistics for debugging and monitoring.
  int _executedCount = 0;
  int _skippedCount = 0;
  int _errorCount = 0;

  /// Execute a sync function only once per key during a sync session.
  /// 
  /// If the function is already running for this key, waits for it to complete.
  /// If the function has already completed for this key, returns immediately.
  /// 
  /// [key] - Unique identifier for this sync function group.
  ///         Use the same key for functions that should not run in parallel.
  /// [fn] - The async function to execute.
  /// 
  /// Returns [SyncCacheResult] with execution details.
  /// 
  /// ## Example
  /// ```dart
  /// // First call - executes the function
  /// final result1 = await cache.runOnce('products', () => syncProducts());
  /// print(result1.wasExecuted); // true
  /// 
  /// // Second call with same key - skips execution
  /// final result2 = await cache.runOnce('products', () => syncProducts());
  /// print(result2.wasSkipped); // true
  /// ```
  Future<SyncCacheResult> runOnce(
    String key,
    Future<void> Function() fn,
  ) async {
    // Check if already completed in this session
    if (_completedResults.containsKey(key)) {
      _skippedCount++;
      if (kDebugMode) {
        print('[SyncCache] Skipped (already completed): $key');
      }
      return _completedResults[key]!;
    }

    // Check if already running
    if (_runningFunctions.containsKey(key)) {
      _skippedCount++;
      if (kDebugMode) {
        print('[SyncCache] Waiting for running: $key');
      }
      // Wait for the running function to complete
      return _runningFunctions[key]!.future;
    }

    // First call - execute the function
    final completer = Completer<SyncCacheResult>();
    _runningFunctions[key] = completer;

    if (kDebugMode) {
      print('[SyncCache] Executing: $key');
    }

    try {
      await fn();
      
      _executedCount++;
      final result = const SyncCacheResult(
        wasExecuted: true,
        wasSkipped: false,
      );
      
      _completedResults[key] = result;
      completer.complete(result);
      
      if (kDebugMode) {
        print('[SyncCache] Completed: $key');
      }
      
      return result;
    } catch (e, stackTrace) {
      _errorCount++;
      final result = SyncCacheResult(
        wasExecuted: true,
        wasSkipped: false,
        error: e,
        stackTrace: stackTrace,
      );
      
      // Still cache the error result to prevent retries in same session
      _completedResults[key] = result;
      completer.complete(result);
      
      if (kDebugMode) {
        print('[SyncCache] Error in $key: $e');
      }
      
      return result;
    } finally {
      _runningFunctions.remove(key);
    }
  }

  /// Check if a function with the given key is currently running.
  bool isRunning(String key) => _runningFunctions.containsKey(key);

  /// Check if a function with the given key has completed in this session.
  bool isCompleted(String key) => _completedResults.containsKey(key);

  /// Get the number of unique keys currently being processed.
  int get runningCount => _runningFunctions.length;

  /// Get the number of completed functions in this session.
  int get completedCount => _completedResults.length;

  /// Clear all cached results. Call this after a sync session ends.
  /// 
  /// This resets the cache so that the next sync session starts fresh.
  /// Should be called in finally block after syncAll completes.
  void clear() {
    if (kDebugMode) {
      print('[SyncCache] Clearing cache. Stats: '
          'executed=$_executedCount, skipped=$_skippedCount, errors=$_errorCount');
    }
    
    _runningFunctions.clear();
    _completedResults.clear();
    _executedCount = 0;
    _skippedCount = 0;
    _errorCount = 0;
  }

  /// Get statistics about the current sync session.
  SyncCacheStats getStats() {
    return SyncCacheStats(
      executedCount: _executedCount,
      skippedCount: _skippedCount,
      errorCount: _errorCount,
      runningCount: _runningFunctions.length,
      completedCount: _completedResults.length,
    );
  }

  /// Calculate how many API calls were saved by caching.
  /// 
  /// Returns the number of duplicate calls that were prevented.
  int get savedCallsCount => _skippedCount;

  /// Reset the singleton instance (for testing purposes).
  @visibleForTesting
  static void resetForTesting() {
    _instance.clear();
  }
}

/// Statistics about sync cache usage.
class SyncCacheStats {
  /// Number of functions that were actually executed.
  final int executedCount;
  
  /// Number of function calls that were skipped (duplicates).
  final int skippedCount;
  
  /// Number of functions that resulted in errors.
  final int errorCount;
  
  /// Number of functions currently running.
  final int runningCount;
  
  /// Number of functions that have completed.
  final int completedCount;

  const SyncCacheStats({
    required this.executedCount,
    required this.skippedCount,
    required this.errorCount,
    required this.runningCount,
    required this.completedCount,
  });

  /// Total number of calls made to runOnce.
  int get totalCalls => executedCount + skippedCount;

  /// Percentage of calls that were skipped (0.0 - 1.0).
  double get skipRate => totalCalls == 0 ? 0.0 : skippedCount / totalCalls;

  /// Human-readable summary of cache effectiveness.
  String get summary => 
      'Executed: $executedCount, Skipped: $skippedCount, Errors: $errorCount '
      '(${(skipRate * 100).toStringAsFixed(1)}% saved)';

  @override
  String toString() => 'SyncCacheStats($summary)';
}
