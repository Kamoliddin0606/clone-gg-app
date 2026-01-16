import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service responsible for monitoring internet connectivity status
/// 
/// This service provides:
/// - Real-time connectivity status monitoring
/// - Stream of connectivity changes
/// - One-time connectivity checks
/// - Automatic reconnection detection
/// 
/// The service uses connectivity_plus package to detect network changes
/// and provides a clean interface for other services to react to connectivity events.
class ConnectivityMonitoringService {
  final Connectivity _connectivity = Connectivity();
  
  // Stream controller for connectivity status changes
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  
  // Current connectivity status
  bool _isConnected = false;
  
  // Subscription to connectivity changes
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  /// Get the current connectivity status
  bool get isConnected => _isConnected;
  
  /// Stream of connectivity status changes
  /// 
  /// Emits true when connected, false when disconnected
  Stream<bool> get connectivityStream => _connectivityController.stream;
  
  /// Initialize the connectivity monitoring service
  /// 
  /// This should be called once during app initialization
  Future<void> initialize() async {
    try {
      // Check initial connectivity status
      await checkConnectivity();
      
      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          if (kDebugMode) {
            debugPrint('[ConnectivityMonitoringService] Error in connectivity stream: $error');
          }
        },
      );
      
      if (kDebugMode) {
        debugPrint('[ConnectivityMonitoringService] Initialized successfully');
        debugPrint('[ConnectivityMonitoringService] Initial status: ${_isConnected ? "Connected" : "Disconnected"}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConnectivityMonitoringService] Error during initialization: $e');
      }
    }
  }
  
  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = _hasInternetConnectivity(results);
    
    // Only emit if status actually changed
    if (wasConnected != _isConnected) {
      _connectivityController.add(_isConnected);
      
      if (kDebugMode) {
        debugPrint('[ConnectivityMonitoringService] Connectivity changed: ${_isConnected ? "Connected" : "Disconnected"}');
        debugPrint('[ConnectivityMonitoringService] Results: $results');
      }
    }
  }
  
  /// Check if the connectivity results indicate internet connectivity
  bool _hasInternetConnectivity(List<ConnectivityResult> results) {
    // Check if any result indicates connectivity
    return results.any((result) => 
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet ||
      result == ConnectivityResult.vpn
    );
  }
  
  /// Manually check current connectivity status
  /// 
  /// Returns true if connected, false otherwise
  /// This method updates the internal state and emits to the stream if changed
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final wasConnected = _isConnected;
      _isConnected = _hasInternetConnectivity(results);
      
      // Emit if status changed
      if (wasConnected != _isConnected) {
        _connectivityController.add(_isConnected);
      }
      
      if (kDebugMode) {
        debugPrint('[ConnectivityMonitoringService] Manual connectivity check: ${_isConnected ? "Connected" : "Disconnected"}');
        debugPrint('[ConnectivityMonitoringService] Results: $results');
      }
      
      return _isConnected;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConnectivityMonitoringService] Error checking connectivity: $e');
      }
      // Assume no connectivity on error
      _isConnected = false;
      return false;
    }
  }
  
  /// Wait for internet connectivity to be restored
  /// 
  /// [timeout] - Maximum time to wait for connectivity (optional)
  /// Returns true if connectivity was restored, false if timeout occurred
  Future<bool> waitForConnectivity({Duration? timeout}) async {
    if (_isConnected) {
      return true;
    }
    
    try {
      if (timeout != null) {
        final result = await connectivityStream
            .firstWhere((isConnected) => isConnected)
            .timeout(timeout);
        return result;
      } else {
        final result = await connectivityStream
            .firstWhere((isConnected) => isConnected);
        return result;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConnectivityMonitoringService] Error or timeout waiting for connectivity: $e');
      }
      return false;
    }
  }
  
  /// Dispose of resources
  /// 
  /// This should be called when the service is no longer needed
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
    
    if (kDebugMode) {
      debugPrint('[ConnectivityMonitoringService] Disposed');
    }
  }
  
  /// Get a human-readable description of the current connectivity status
  String getConnectivityStatusDescription() {
    return _isConnected 
        ? 'Internet connection available' 
        : 'No internet connection';
  }
  
  /// Check if connectivity is available and throw an exception if not
  /// 
  /// Useful for operations that require internet connectivity
  void ensureConnectivity() {
    if (!_isConnected) {
      throw NoInternetConnectionException();
    }
  }
}

/// Exception thrown when internet connectivity is required but not available
class NoInternetConnectionException implements Exception {
  final String message;
  
  NoInternetConnectionException([
    this.message = 'No internet connection available'
  ]);
  
  @override
  String toString() => 'NoInternetConnectionException: $message';
}
