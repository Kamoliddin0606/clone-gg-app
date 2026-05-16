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

      _setStatus(hasConnection);
    } catch (e) {
      if (kDebugMode) {
        print('[ConnectivityMonitor] Error handling connectivity change: $e');
      }
    }
  }

  /// Check current connectivity status
  ///
  /// Returns true if device has active network connection.
  /// Also synchronises `_lastKnownStatus` with the freshly probed value so
  /// any UI listeners (StreamBuilder on [connectivityStream]) see the
  /// up-to-date state — without this, `hasConnection()` callers would
  /// silently diverge from the cached value the stream emits.
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

      _setStatus(hasConnection);
      return hasConnection;
    } catch (e) {
      if (kDebugMode) {
        print('[ConnectivityMonitor] Error checking connectivity: $e');
      }
      // On error, assume no connection
      _setStatus(false);
      return false;
    }
  }

  /// Force the cached status to "connected" and emit on the stream when
  /// the value actually changes. Used after a successful server probe
  /// (see [NetworkModeGate.probeOnline]) so the UI can hide the offline
  /// badge immediately instead of waiting for the next platform
  /// connectivity event.
  void markConnected() => _setStatus(true);

  /// Symmetric counterpart to [markConnected]. Currently unused by UI
  /// code, but exposed so callers that detect a transport failure can
  /// invalidate the cached status proactively.
  void markDisconnected() => _setStatus(false);

  void _setStatus(bool value) {
    if (value == _lastKnownStatus) return;
    _lastKnownStatus = value;
    if (!_connectivityController.isClosed) {
      _connectivityController.add(value);
    }
    if (kDebugMode) {
      print('[ConnectivityMonitor] Status set to: ${value ? "CONNECTED" : "DISCONNECTED"}');
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
