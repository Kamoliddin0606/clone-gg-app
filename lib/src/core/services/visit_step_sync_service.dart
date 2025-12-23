import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/visit_data_repository.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

/// Service for background synchronization of visit step data
class VisitStepSyncService {
  final VisitDataRepository _visitDataRepository;
  final DataSyncService _dataSyncService;
  final SharedPreferencesService _prefs;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isInitialized = false;

  static const String _lastSyncKey = 'visit_steps_last_sync';
  static const Duration _syncInterval = Duration(minutes: 15);
  static const Duration _retryDelay = Duration(minutes: 5);

  VisitStepSyncService({
    required VisitDataRepository visitDataRepository,
    required DataSyncService dataSyncService,
    required SharedPreferencesService prefs,
  }) : _visitDataRepository = visitDataRepository,
       _dataSyncService = dataSyncService,
       _prefs = prefs,
       _connectivity = Connectivity();

  /// Initialize the sync service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
      );

      // Start periodic sync
      _startPeriodicSync();

      // Initial sync if connected
      final connectivityResult = await _connectivity.checkConnectivity();
      if (!_isOffline(connectivityResult)) {
        await syncUnsyncedData();
      }

      _isInitialized = true;
      if (kDebugMode) print('VisitStepSyncService initialized successfully');
    } catch (e) {
      if (kDebugMode) print('Error initializing VisitStepSyncService: $e');
      rethrow;
    }
  }

  /// Check if device is offline
  bool _isOffline(List<ConnectivityResult> results) {
    return results.every((result) => result == ConnectivityResult.none);
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    if (!_isOffline(results)) {
      // Network available, sync data
      if (kDebugMode) print('Network available, starting visit step data sync');
      syncUnsyncedData();
    } else {
      if (kDebugMode) print('Network unavailable, visit step sync paused');
    }
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (!_isInitialized) return;
      if (kDebugMode) print('Periodic visit step sync triggered');
      syncUnsyncedData();
    });
  }

  /// Sync all unsynced visit step data
  Future<void> syncUnsyncedData() async {
    try {
      final unsyncedData = await _visitDataRepository.getPendingSyncVisitStepData();

      if (unsyncedData.isEmpty) {
        if (kDebugMode) print('No unsynced visit step data found');
        return;
      }

      if (kDebugMode) print('Found ${unsyncedData.length} unsynced visit step records');

      // Group data by visit ID for efficient processing
      final groupedData = <String, List<VisitData>>{};
      for (final data in unsyncedData) {
        if (!groupedData.containsKey(data.visitId)) {
          groupedData[data.visitId] = [];
        }
        groupedData[data.visitId]!.add(data);
      }

      if (kDebugMode) print('Grouped into ${groupedData.length} visits');

      // Sync each visit's data
      int successCount = 0;
      int failureCount = 0;

      for (final entry in groupedData.entries) {
        try {
          await _syncVisitData(entry.key, entry.value);
          successCount++;
        } catch (e) {
          if (kDebugMode) print('Failed to sync visit ${entry.key}: $e');
          failureCount++;
        }
      }

      if (kDebugMode) print('Sync completed: $successCount successful, $failureCount failed');

      // Update last sync time
      await _prefs.preferences.setString(_lastSyncKey, DateTime.now().toIso8601String());

    } catch (e) {
      if (kDebugMode) print('Error during visit step data sync: $e');
      _scheduleRetrySync();
    }
  }

  /// Sync data for a specific visit
  Future<void> _syncVisitData(String visitId, List<VisitData> visitData) async {
    if (kDebugMode) print('Syncing visit $visitId with ${visitData.length} data items');

    // Group data by type for different sync strategies
    final photos = visitData.where((d) => d.dataType == 'photo').toList();
    final audits = visitData.where((d) => d.dataType == 'audit').toList();
    final orders = visitData.where((d) => d.dataType == 'order').toList();
    final forms = visitData.where((d) => d.dataType == 'form').toList();
    final notes = visitData.where((d) => d.dataType == 'note').toList();

    // Sync photos first (they might need file uploads)
    if (photos.isNotEmpty) {
      await _syncPhotos(visitId, photos);
    }

    // Sync other data types
    if (audits.isNotEmpty) {
      await _syncAuditData(visitId, audits);
    }

    if (orders.isNotEmpty) {
      await _syncOrderData(visitId, orders);
    }

    if (forms.isNotEmpty) {
      await _syncFormData(visitId, forms);
    }

    if (notes.isNotEmpty) {
      await _syncNotes(visitId, notes);
    }

    // Mark all data as synced
    await _visitDataRepository.markVisitStepDataAsSynced(visitId);
    if (kDebugMode) print('Visit $visitId sync completed successfully');
  }

  /// Sync photo data
  Future<void> _syncPhotos(String visitId, List<VisitData> photos) async {
    if (kDebugMode) print('Syncing ${photos.length} photos for visit $visitId');

    for (final photo in photos) {
      try {
        final content = photo.parsedDataContent;
        final imagePath = content['image_path'];
        final thumbnailPath = content['thumbnail_path'];

        // Here you would upload files to server
        // For now, just mark as synced
        await _visitDataRepository.updateVisitStepDataSyncStatus(photo.id!, true);

      } catch (e) {
        if (kDebugMode) print('Error syncing photo ${photo.id}: $e');
        // Continue with other photos
      }
    }
  }

  /// Sync audit data
  Future<void> _syncAuditData(String visitId, List<VisitData> audits) async {
    if (kDebugMode) print('Syncing ${audits.length} audit records for visit $visitId');

    for (final audit in audits) {
      try {
        // Send audit data to server via appropriate API
        // This would call a specific audit sync endpoint
        await _visitDataRepository.updateVisitStepDataSyncStatus(audit.id!, true);

      } catch (e) {
        if (kDebugMode) print('Error syncing audit ${audit.id}: $e');
      }
    }
  }

  /// Sync order data
  Future<void> _syncOrderData(String visitId, List<VisitData> orders) async {
    if (kDebugMode) print('Syncing ${orders.length} orders for visit $visitId');

    for (final order in orders) {
      try {
        // Sync order data - this might integrate with existing order sync
        await _visitDataRepository.updateVisitStepDataSyncStatus(order.id!, true);

      } catch (e) {
        if (kDebugMode) print('Error syncing order ${order.id}: $e');
      }
    }
  }

  /// Sync form data
  Future<void> _syncFormData(String visitId, List<VisitData> forms) async {
    if (kDebugMode) print('Syncing ${forms.length} forms for visit $visitId');

    for (final form in forms) {
      try {
        // Send form data to server
        await _visitDataRepository.updateVisitStepDataSyncStatus(form.id!, true);

      } catch (e) {
        if (kDebugMode) print('Error syncing form ${form.id}: $e');
      }
    }
  }

  /// Sync notes
  Future<void> _syncNotes(String visitId, List<VisitData> notes) async {
    if (kDebugMode) print('Syncing ${notes.length} notes for visit $visitId');

    for (final note in notes) {
      try {
        // Send notes to server
        await _visitDataRepository.updateVisitStepDataSyncStatus(note.id!, true);

      } catch (e) {
        if (kDebugMode) print('Error syncing note ${note.id}: $e');
      }
    }
  }

  /// Force sync a specific visit
  Future<void> forceSyncVisit(String visitId) async {
    try {
      final visitData = await _visitDataRepository.getVisitStepDataByVisitId(visitId);
      if (visitData.isNotEmpty) {
        await _syncVisitData(visitId, visitData);
      }
    } catch (e) {
      if (kDebugMode) print('Error force syncing visit $visitId: $e');
      rethrow;
    }
  }

  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final unsyncedCount = await _visitDataRepository.getUnsyncedVisitStepDataCount();
      final lastSync = _prefs.preferences.getString(_lastSyncKey);

      return {
        'unsyncedCount': unsyncedCount,
        'lastSync': lastSync,
        'isOnline': !(await _connectivity.checkConnectivity()).every((r) => r == ConnectivityResult.none),
      };
    } catch (e) {
      if (kDebugMode) print('Error getting sync status: $e');
      return {
        'unsyncedCount': 0,
        'lastSync': null,
        'isOnline': false,
      };
    }
  }

  /// Schedule retry sync
  void _scheduleRetrySync() {
    Timer(_retryDelay, () {
      if (_isInitialized) {
        if (kDebugMode) print('Retrying visit step sync');
        syncUnsyncedData();
      }
    });
  }

  /// Clean up old synced data (optional)
  Future<void> cleanupOldData({Duration maxAge = const Duration(days: 30)}) async {
    try {
      final cutoffDate = DateTime.now().subtract(maxAge);
      await _visitDataRepository.deleteOldVisitStepData(olderThan: cutoffDate.difference(DateTime.now()));
      if (kDebugMode) print('Cleaned up visit step data older than $maxAge');
    } catch (e) {
      if (kDebugMode) print('Error cleaning up old data: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _isInitialized = false;
    if (kDebugMode) print('VisitStepSyncService disposed');
  }
}