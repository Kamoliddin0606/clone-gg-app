import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for monitoring network connectivity changes
/// 
/// Provides:
/// - Real-time connectivity status stream
/// - Current connectivity check
/// - Automatic verification trigger on connectivity restore
class ConnectivityMonitorService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isInitialized = false;
  bool _lastKnownStatus = false;

  /// Stream of connectivity changes (true = connected, false = disconnected)
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Get current connectivity status
  bool get isConnected => _lastKnownStatus;

  /// Initialize connectivity monitoring
  /// 
  /// Sets up listener for connectivity changes and performs initial check
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('[ConnectivityMonitor] Already initialized');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('[ConnectivityMonitor] Initializing...');
      }

      // Perform initial connectivity check
      final initialStatus = await hasConnection();
      _lastKnownStatus = initialStatus;

      if (kDebugMode) {
        print('[ConnectivityMonitor] Initial connectivity status: $initialStatus');
      }

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          if (kDebugMode) {
            print('[ConnectivityMonitor] Error in connectivity stream: $error');
          }
        },
      );

      _isInitialized = true;

      if (kDebugMode) {
        print('[ConnectivityMonitor] Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ConnectivityMonitor] Initialization error: $e');
      }
      rethrow;
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    try {
      // Check if any result indicates connectivity
      final hasConnection = results.any((result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn);

      if (kDebugMode) {
        print('[ConnectivityMonitor] Connectivity changed: $results');
        print('[ConnectivityMonitor] Has connection: $hasConnection');
      }

      // Only emit if status actually changed
      if (hasConnection != _lastKnownStatus) {
        _lastKnownStatus = hasConnection;
        _connectivityController.add(hasConnection);

        if (kDebugMode) {
          print('[ConnectivityMonitor] Status changed to: ${hasConnection ? "CONNECTED" : "DISCONNECTED"}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ConnectivityMonitor] Error handling connectivity change: $e');
      }
    }
  }

  /// Check current connectivity status
  /// 
  /// Returns true if device has active network connection
  Future<bool> hasConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      
      final hasConnection = results.any((result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn);

      if (kDebugMode) {
        print('[ConnectivityMonitor] Current connectivity: $results');
        print('[ConnectivityMonitor] Has connection: $hasConnection');
      }

      return hasConnection;
    } catch (e) {
      if (kDebugMode) {
        print('[ConnectivityMonitor] Error checking connectivity: $e');
      }
      // On error, assume no connection
      return false;
    }
  }

  /// Dispose resources
  /// 
  /// Cancels connectivity subscription and closes stream controller
  Future<void> dispose() async {
    try {
      if (kDebugMode) {
        print('[ConnectivityMonitor] Disposing...');
      }

      await _connectivitySubscription?.cancel();
      _connectivitySubscription = null;

      if (!_connectivityController.isClosed) {
        await _connectivityController.close();
      }

      _isInitialized = false;

      if (kDebugMode) {
        print('[ConnectivityMonitor] Disposed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ConnectivityMonitor] Error during disposal: $e');
      }
    }
  }

  /// Reset service state
  /// 
  /// Useful for testing or reinitializing
  Future<void> reset() async {
    await dispose();
    _lastKnownStatus = false;
  }
}
