import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';

/// Service for managing user permissions with real-time updates
class PermissionsService {
  final DataSyncService _dataSyncService;
  final SharedPreferencesService _prefs;

  StreamController<SalesReqPermissions?>? _permissionsController;
  Timer? _refreshTimer;

  PermissionsService({
    required DataSyncService dataSyncService,
    required SharedPreferencesService prefs,
  }) : _dataSyncService = dataSyncService,
       _prefs = prefs;

  /// Get current permissions
  Future<SalesReqPermissions?> getPermissions() async {
    try {
      final userCode = _prefs.getUserCode();
      if (userCode == null) {
        if (kDebugMode) {
          print('PermissionsService: No user code found');
        }
        return null;
      }

      final permissions = await _dataSyncService.getCachedSalesReqPermissions(userCode);
      if (kDebugMode) {
        print('PermissionsService: Retrieved permissions for user $userCode: $permissions');
      }
      return permissions;
    } catch (e) {
      if (kDebugMode) {
        print('PermissionsService: Error getting permissions: $e');
      }
      return null;
    }
  }

  /// Stream permissions with periodic updates
  Stream<SalesReqPermissions?> watchPermissions() {
    _permissionsController ??= StreamController<SalesReqPermissions?>.broadcast(
      onListen: _startPeriodicUpdates,
      onCancel: _stopPeriodicUpdates,
    );

    // Emit initial value
    getPermissions().then((permissions) {
      if (_permissionsController?.isClosed == false) {
        _permissionsController?.add(permissions);
      }
    });

    return _permissionsController!.stream;
  }

  void _startPeriodicUpdates() {
    if (kDebugMode) {
      print('PermissionsService: Starting periodic updates');
    }

    // Update every 5 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      try {
        final permissions = await getPermissions();
        if (_permissionsController?.isClosed == false) {
          _permissionsController?.add(permissions);
        }
      } catch (e) {
        if (kDebugMode) {
          print('PermissionsService: Error during periodic update: $e');
        }
      }
    });
  }

  void _stopPeriodicUpdates() {
    if (kDebugMode) {
      print('PermissionsService: Stopping periodic updates');
    }
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Force refresh permissions
  Future<void> refreshPermissions() async {
    try {
      final permissions = await getPermissions();
      if (_permissionsController?.isClosed == false) {
        _permissionsController?.add(permissions);
      }
    } catch (e) {
      if (kDebugMode) {
        print('PermissionsService: Error refreshing permissions: $e');
      }
      rethrow;
    }
  }

  /// Check if user can visit clients
  Future<bool> canVisit() async {
    final permissions = await getPermissions();
    return permissions?.visit ?? true; // Default to true if no permissions
  }

  /// Check if user can create unplanned orders
  Future<bool> canCreateUnplannedOrder() async {
    final permissions = await getPermissions();
    return permissions?.unplannedOrder ?? true; // Default to true if no permissions
  }

  /// Dispose resources
  void dispose() {
    if (kDebugMode) {
      print('PermissionsService: Disposing');
    }
    _refreshTimer?.cancel();
    _permissionsController?.close();
    _permissionsController = null;
  }
}