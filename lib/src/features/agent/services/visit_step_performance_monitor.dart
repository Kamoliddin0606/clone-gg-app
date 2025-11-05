import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/visit_step_data_service.dart';

/// Performance monitoring for visit steps
class VisitStepPerformanceMonitor {
  static final VisitStepPerformanceMonitor _instance = VisitStepPerformanceMonitor._internal();
  factory VisitStepPerformanceMonitor() => _instance;
  VisitStepPerformanceMonitor._internal();

  final Map<String, PerformanceMetrics> _metrics = {};
  final StreamController<PerformanceEvent> _eventController = StreamController.broadcast();
  final Queue<PerformanceMetrics> _completedOperations = Queue();

  static const int _maxCompletedOperations = 1000;

  Stream<PerformanceEvent> get events => _eventController.stream;

  /// Start timing an operation
  String startOperation(String operationName, {Map<String, dynamic>? metadata}) {
    final operationId = '${operationName}_${DateTime.now().millisecondsSinceEpoch}_${_metrics.length}';
    _metrics[operationId] = PerformanceMetrics(
      operationName: operationName,
      startTime: DateTime.now(),
      metadata: metadata,
    );
    return operationId;
  }

  /// End timing an operation
  void endOperation(String operationId, {bool success = true, String? error}) {
    final metrics = _metrics[operationId];
    if (metrics != null) {
      metrics.endTime = DateTime.now();
      metrics.success = success;
      metrics.error = error;
      metrics.duration = metrics.endTime!.difference(metrics.startTime).inMilliseconds;

      // Add to completed operations queue
      _completedOperations.add(metrics);
      if (_completedOperations.length > _maxCompletedOperations) {
        _completedOperations.removeFirst();
      }

      _eventController.add(PerformanceEvent(
        operationId: operationId,
        metrics: metrics,
      ));

      // Log performance issues
      _logPerformanceIssues(metrics);

      _metrics.remove(operationId);
    }
  }

  /// Log performance issues
  void _logPerformanceIssues(PerformanceMetrics metrics) {
    const slowThreshold = 5000; // 5 seconds
    const verySlowThreshold = 15000; // 15 seconds

    if (metrics.duration > verySlowThreshold) {
      print('🚨 CRITICAL PERFORMANCE ISSUE: ${metrics.operationName} took ${metrics.duration}ms');
      _reportCriticalPerformance(metrics);
    } else if (metrics.duration > slowThreshold) {
      print('⚠️ SLOW OPERATION: ${metrics.operationName} took ${metrics.duration}ms');
    }

    if (!metrics.success) {
      print('❌ FAILED OPERATION: ${metrics.operationName} (${metrics.error})');
    }
  }

  /// Report critical performance issues
  void _reportCriticalPerformance(PerformanceMetrics metrics) {
    // In a real app, this would send to monitoring service
    // For now, just log detailed information
    print('''
🚨 CRITICAL PERFORMANCE REPORT 🚨
Operation: ${metrics.operationName}
Duration: ${metrics.duration}ms
Start Time: ${metrics.startTime}
End Time: ${metrics.endTime}
Success: ${metrics.success}
Error: ${metrics.error}
Metadata: ${metrics.metadata}
''');
  }

  /// Get performance statistics
  Map<String, dynamic> getStatistics() {
    final completedOps = _completedOperations.toList();
    if (completedOps.isEmpty) return {};

    final totalDuration = completedOps.fold<int>(0, (sum, m) => sum + m.duration);
    final avgDuration = totalDuration / completedOps.length;
    final successRate = completedOps.where((m) => m.success).length / completedOps.length;
    final slowOperations = completedOps.where((m) => m.duration > 5000).length;

    // Group by operation type
    final operationStats = <String, Map<String, dynamic>>{};
    for (final op in completedOps) {
      if (!operationStats.containsKey(op.operationName)) {
        operationStats[op.operationName] = {
          'count': 0,
          'totalDuration': 0,
          'successCount': 0,
          'slowCount': 0,
        };
      }

      final stats = operationStats[op.operationName]!;
      stats['count'] = stats['count'] + 1;
      stats['totalDuration'] = stats['totalDuration'] + op.duration;
      if (op.success) stats['successCount'] = stats['successCount'] + 1;
      if (op.duration > 5000) stats['slowCount'] = stats['slowCount'] + 1;
    }

    return {
      'totalOperations': completedOps.length,
      'averageDuration': avgDuration,
      'successRate': successRate,
      'slowOperations': slowOperations,
      'activeOperations': _metrics.length,
      'operationBreakdown': operationStats,
    };
  }

  /// Get slow operations
  List<PerformanceMetrics> getSlowOperations({int thresholdMs = 5000}) {
    return _completedOperations.where((m) => m.duration > thresholdMs).toList();
  }

  /// Get failed operations
  List<PerformanceMetrics> getFailedOperations() {
    return _completedOperations.where((m) => !m.success).toList();
  }

  /// Clear old data
  void clearOldData({Duration maxAge = const Duration(hours: 1)}) {
    final cutoffTime = DateTime.now().subtract(maxAge);
    _completedOperations.removeWhere((m) => m.endTime!.isBefore(cutoffTime));
  }

  void dispose() {
    _eventController.close();
    _metrics.clear();
    _completedOperations.clear();
  }
}

/// Performance metrics
class PerformanceMetrics {
  final String operationName;
  final DateTime startTime;
  DateTime? endTime;
  int duration = 0;
  bool success = false;
  String? error;
  final Map<String, dynamic>? metadata;

  PerformanceMetrics({
    required this.operationName,
    required this.startTime,
    this.metadata,
  });

  @override
  String toString() {
    return 'PerformanceMetrics(operation: $operationName, duration: ${duration}ms, success: $success)';
  }
}

/// Performance event
class PerformanceEvent {
  final String operationId;
  final PerformanceMetrics metrics;

  PerformanceEvent({
    required this.operationId,
    required this.metrics,
  });
}

/// Optimized data batching for better performance
class DataBatchProcessor {
  static const int _batchSize = 50;
  static const Duration _batchDelay = Duration(seconds: 2);

  final List<VisitData> _batch = [];
  Timer? _batchTimer;
  final Future<void> Function(List<VisitData>) _processBatch;

  DataBatchProcessor(this._processBatch);

  /// Add data to batch
  void addToBatch(VisitData data) {
    _batch.add(data);

    if (_batch.length >= _batchSize) {
      _flushBatch();
    } else {
      _scheduleBatchFlush();
    }
  }

  /// Schedule batch flush
  void _scheduleBatchFlush() {
    _batchTimer?.cancel();
    _batchTimer = Timer(_batchDelay, _flushBatch);
  }

  /// Flush current batch
  Future<void> _flushBatch() async {
    if (_batch.isEmpty) return;

    final batchToProcess = List<VisitData>.from(_batch);
    _batch.clear();
    _batchTimer?.cancel();

    final operationId = VisitStepPerformanceMonitor().startOperation(
      'batch_processing',
      metadata: {'batchSize': batchToProcess.length},
    );

    try {
      await _processBatch(batchToProcess);
      VisitStepPerformanceMonitor().endOperation(operationId, success: true);
    } catch (e) {
      VisitStepPerformanceMonitor().endOperation(operationId, success: false, error: e.toString());
      rethrow;
    }
  }

  /// Force flush remaining data
  Future<void> flush() async {
    await _flushBatch();
  }

  /// Get batch statistics
  Map<String, dynamic> getStats() {
    return {
      'currentBatchSize': _batch.length,
      'hasPendingBatch': _batchTimer != null,
      'timeUntilFlush': _batchTimer?.tick,
    };
  }

  void dispose() {
    _batchTimer?.cancel();
    flush();
  }
}

/// Memory optimization utilities
class MemoryOptimizer {
  static const int _maxCacheSize = 100;
  static const Duration _defaultCacheTTL = Duration(minutes: 30);

  final Map<String, CachedData> _cache = {};
  final Map<String, int> _accessCount = {};

  /// Cache data with automatic cleanup
  void cacheData(String key, dynamic data, {Duration? ttl}) {
    if (_cache.length >= _maxCacheSize) {
      _cleanupOldCache();
    }

    _cache[key] = CachedData(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl ?? _defaultCacheTTL,
      accessCount: 0,
    );
  }

  /// Get cached data with LRU tracking
  T? getCachedData<T>(String key) {
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) {
      cached.accessCount++;
      _accessCount[key] = (_accessCount[key] ?? 0) + 1;
      return cached.data as T;
    }
    _cache.remove(key);
    _accessCount.remove(key);
    return null;
  }

  /// Clean up expired and LRU cache entries
  void _cleanupOldCache() {
    // Remove expired entries
    _cache.removeWhere((key, cached) => cached.isExpired);

    // If still over limit, remove least recently used
    if (_cache.length >= _maxCacheSize) {
      final sortedKeys = _cache.keys.toList()
        ..sort((a, b) => (_accessCount[a] ?? 0).compareTo(_accessCount[b] ?? 0));

      final keysToRemove = sortedKeys.take(_cache.length - _maxCacheSize + 10);
      for (final key in keysToRemove) {
        _cache.remove(key);
        _accessCount.remove(key);
      }
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _cache.length,
      'maxCacheSize': _maxCacheSize,
      'totalAccessCount': _accessCount.values.fold(0, (a, b) => a + b),
      'hitRate': _calculateHitRate(),
    };
  }

  /// Calculate cache hit rate (simplified)
  double _calculateHitRate() {
    if (_accessCount.isEmpty) return 0.0;
    final totalAccesses = _accessCount.values.fold(0, (a, b) => a + b);
    final hits = _accessCount.values.where((count) => count > 1).fold(0, (a, b) => a + (b - 1));
    return hits / totalAccesses;
  }

  /// Clear all cache
  void clearCache() {
    _cache.clear();
    _accessCount.clear();
  }

  /// Preload frequently used data
  Future<void> preloadData(Map<String, Future<dynamic> Function()> dataLoaders) async {
    for (final entry in dataLoaders.entries) {
      try {
        final data = await entry.value();
        cacheData(entry.key, data);
      } catch (e) {
        print('Failed to preload ${entry.key}: $e');
      }
    }
  }
}

/// Cached data wrapper
class CachedData {
  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;
  int accessCount;

  CachedData({
    required this.data,
    required this.timestamp,
    required this.ttl,
    required this.accessCount,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

/// Performance-optimized image processing
class OptimizedImageProcessor {
  static const int _maxDimension = 2048;
  static const int _jpegQuality = 85;
  static const Duration _processingTimeout = Duration(seconds: 30);

  static final MemoryOptimizer _memoryOptimizer = MemoryOptimizer();

  /// Process image with performance optimizations
  static Future<Uint8List> processImage(
    Uint8List imageBytes, {
    int maxWidth = _maxDimension,
    int maxHeight = _maxDimension,
    int quality = _jpegQuality,
    bool enableCaching = true,
  }) async {
    final cacheKey = 'image_${imageBytes.length}_${maxWidth}_${maxHeight}_$quality';

    // Check cache first
    if (enableCaching) {
      final cached = _memoryOptimizer.getCachedData<Uint8List>(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

    final operationId = VisitStepPerformanceMonitor().startOperation(
      'image_processing',
      metadata: {
        'inputSize': imageBytes.length,
        'maxWidth': maxWidth,
        'maxHeight': maxHeight,
        'quality': quality,
      },
    );

    try {
      final result = await _processImageInternal(imageBytes, maxWidth, maxHeight, quality)
          .timeout(_processingTimeout);

      VisitStepPerformanceMonitor().endOperation(operationId, success: true);

      // Cache result
      if (enableCaching) {
        _memoryOptimizer.cacheData(cacheKey, result);
      }

      return result;

    } catch (e) {
      VisitStepPerformanceMonitor().endOperation(operationId, success: false, error: e.toString());
      rethrow;
    }
  }

  /// Internal image processing
  static Future<Uint8List> _processImageInternal(
    Uint8List imageBytes,
    int maxWidth,
    int maxHeight,
    int quality,
  ) async {
    // Decode image
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Failed to decode image');

    // Calculate new dimensions
    var newWidth = image.width;
    var newHeight = image.height;

    if (newWidth > maxWidth || newHeight > maxHeight) {
      final aspectRatio = newWidth / newHeight;

      if (newWidth > newHeight) {
        newWidth = maxWidth;
        newHeight = (maxWidth / aspectRatio).round();
      } else {
        newHeight = maxHeight;
        newWidth = (maxHeight * aspectRatio).round();
      }
    }

    // Resize if needed
    img.Image processedImage;
    if (newWidth != image.width || newHeight != image.height) {
      processedImage = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );
    } else {
      processedImage = image;
    }

    // Encode with optimized quality
    final optimizedBytes = img.encodeJpg(processedImage, quality: quality);
    return Uint8List.fromList(optimizedBytes);
  }

  /// Batch process multiple images
  static Future<List<Uint8List>> batchProcessImages(
    List<Uint8List> images, {
    int maxWidth = _maxDimension,
    int maxHeight = _maxDimension,
    int quality = _jpegQuality,
    int concurrency = 3, // Process 3 images concurrently
  }) async {
    final results = <Uint8List>[];
    final semaphore = _Semaphore(concurrency);

    final futures = images.map((imageBytes) async {
      await semaphore.acquire();
      try {
        final result = await processImage(
          imageBytes,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          quality: quality,
        );
        results.add(result);
      } finally {
        semaphore.release();
      }
    });

    await Future.wait(futures);
    return results;
  }
}

/// Simple semaphore for concurrency control
class _Semaphore {
  final int _maxCount;
  int _currentCount = 0;
  final List<Completer<void>> _waitQueue = [];

  _Semaphore(this._maxCount);

  Future<void> acquire() async {
    if (_currentCount < _maxCount) {
      _currentCount++;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    await completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeAt(0);
      completer.complete();
    } else {
      _currentCount--;
    }
  }
}

/// Database connection pooling for better performance
class DatabaseConnectionPool {
  static const int _maxConnections = 5;
  final List<_DatabaseConnection> _connections = [];
  final Queue<_DatabaseConnection> _availableConnections = Queue();

  /// Get a database connection
  Future<_DatabaseConnection> getConnection() async {
    if (_availableConnections.isNotEmpty) {
      return _availableConnections.removeFirst();
    }

    if (_connections.length < _maxConnections) {
      final connection = _DatabaseConnection();
      await connection.open();
      _connections.add(connection);
      return connection;
    }

    // Wait for an available connection
    while (_availableConnections.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 10));
    }

    return _availableConnections.removeFirst();
  }

  /// Return a connection to the pool
  void returnConnection(_DatabaseConnection connection) {
    if (_connections.contains(connection)) {
      _availableConnections.add(connection);
    }
  }

  /// Close all connections
  Future<void> closeAll() async {
    for (final connection in _connections) {
      await connection.close();
    }
    _connections.clear();
    _availableConnections.clear();
  }
}

/// Mock database connection for demonstration
class _DatabaseConnection {
  bool _isOpen = false;

  Future<void> open() async {
    // Simulate connection opening
    await Future.delayed(const Duration(milliseconds: 50));
    _isOpen = true;
  }

  Future<void> close() async {
    _isOpen = false;
  }

  bool get isOpen => _isOpen;
}