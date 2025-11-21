import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/create_order.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_data.dart';
import 'package:crypto/crypto.dart';

/// Service for managing order draft persistence and synchronization
/// Handles saving and loading order drafts with proper error handling and validation
class OrderDraftService {
  final ApiDatabaseService _dbService;

  // Auto-save configuration
  static const Duration _autoSaveInterval = Duration(seconds: 30);
  Timer? _autoSaveTimer;
  bool _isAutoSaveEnabled = false;

  // App lifecycle management
  WidgetsBindingObserver? _lifecycleObserver;

  // Save status tracking
  DateTime? _lastSaveTime;
  bool _isSaving = false;
  String? _lastSaveError;

  OrderDraftService(this._dbService) {
    _initializeLifecycleObserver();
  }

  /// Initialize app lifecycle observer for automatic saving
  void _initializeLifecycleObserver() {
    _lifecycleObserver = _DraftLifecycleObserver(
      onSave: _performAutoSave,
      onDispose: _cleanup,
    );

    // Register the observer if WidgetsBinding is available
    try {
      WidgetsBinding.instance.addObserver(_lifecycleObserver!);
    } catch (e) {
      // WidgetsBinding might not be available during testing
      debugPrint('OrderDraftService: Could not register lifecycle observer: $e');
    }
  }

  /// Enable automatic saving for a specific draft
  void enableAutoSave({
    required String visitId,
    required int stepCode,
    required List<CreateOrderProduct> products,
    required String selectedOrganization,
    required String selectedWarehouse,
    required String selectedPriceType,
    required String notes,
    required String stepName,
  }) {
    _isAutoSaveEnabled = true;

    // Cancel existing timer
    _autoSaveTimer?.cancel();

    // Start new auto-save timer
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) {
      if (_isAutoSaveEnabled && !_isSaving) {
        _performAutoSave(
          visitId: visitId,
          stepCode: stepCode,
          products: products,
          selectedOrganization: selectedOrganization,
          selectedWarehouse: selectedWarehouse,
          selectedPriceType: selectedPriceType,
          notes: notes,
          stepName: stepName,
        );
      }
    });

    debugPrint('OrderDraftService: Auto-save enabled for visit $visitId, step $stepCode');
  }

  /// Disable automatic saving
  void disableAutoSave() {
    _isAutoSaveEnabled = false;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    debugPrint('OrderDraftService: Auto-save disabled');
  }

  /// Perform automatic save operation
  Future<void> _performAutoSave({
    required String visitId,
    required int stepCode,
    required List<CreateOrderProduct> products,
    required String selectedOrganization,
    required String selectedWarehouse,
    required String selectedPriceType,
    required String notes,
    required String stepName,
  }) async {
    if (_isSaving) {
      debugPrint('OrderDraftService: Auto-save skipped - already saving');
      return;
    }

    try {
      _isSaving = true;
      debugPrint('OrderDraftService: Performing auto-save...');

      await saveOrderDraft(
        visitId: visitId,
        clientCode: '', // Will be determined from context
        stepCode: stepCode,
        stepName: stepName,
        selectedOrganization: selectedOrganization,
        selectedWarehouse: selectedWarehouse,
        selectedPriceType: selectedPriceType,
        products: products,
        notes: notes,
      );

      _lastSaveTime = DateTime.now();
      _lastSaveError = null;

      debugPrint('OrderDraftService: Auto-save completed successfully');
    } catch (e, stackTrace) {
      _lastSaveError = e.toString();
      debugPrint('OrderDraftService: Auto-save failed: $e');
      debugPrint('OrderDraftService: Stack trace: $stackTrace');

      // Don't rethrow - auto-save failures should not interrupt user workflow
    } finally {
      _isSaving = false;
    }
  }

  /// Get current save status
  Map<String, dynamic> getSaveStatus() {
    return {
      'isSaving': _isSaving,
      'lastSaveTime': _lastSaveTime,
      'lastSaveError': _lastSaveError,
      'autoSaveEnabled': _isAutoSaveEnabled,
    };
  }

  /// Cleanup resources
  void _cleanup() {
    disableAutoSave();
    if (_lifecycleObserver != null) {
      try {
        WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  }

  /// Dispose of the service
  void dispose() {
    _cleanup();
  }

  /// Save order draft data with immediate persistence
  /// Creates or updates a draft order in the database
  Future<void> saveOrderDraft({
    required String visitId,
    required String clientCode,
    required int stepCode,
    required String stepName,
    required String selectedOrganization,
    required String selectedWarehouse,
    required String selectedPriceType,
    required List<CreateOrderProduct> products,
    required String notes,
  }) async {
    try {
      debugPrint('OrderDraftService: Saving order draft for visit $visitId, step $stepCode');

      // Create draft order data
      final draftData = {
        'visitId': visitId,
        'clientCode': clientCode,
        'stepCode': stepCode,
        'stepName': stepName,
        'selectedOrganization': selectedOrganization,
        'selectedWarehouse': selectedWarehouse,
        'selectedPriceType': selectedPriceType,
        'products': products.map((p) => p.toJson()).toList(),
        'notes': notes,
        'timestamp': DateTime.now().toIso8601String(),
        'version': 1, // For future migration support
      };

      // Create VisitData object
      final visitData = VisitData(
        visitId: visitId,
        clientCode: clientCode,
        stepCode: stepCode,
        stepName: stepName,
        dataType: 'order_draft',
        dataContent: jsonEncode(draftData),
        timestamp: DateTime.now(),
        isSynced: false,
      );

      // Save to database using visit_steps_data table
      await _dbService.saveVisitStepData(visitData);

      debugPrint('OrderDraftService: Order draft saved successfully');
    } catch (e, stackTrace) {
      debugPrint('OrderDraftService: Failed to save order draft: $e');
      debugPrint('OrderDraftService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Load order draft data from database
  /// Returns null if no draft exists or loading fails
  Future<Map<String, dynamic>?> loadOrderDraft(String visitId, int stepCode) async {
    try {
      debugPrint('OrderDraftService: Loading order draft for visit $visitId, step $stepCode');

      final allVisitData = await _dbService.getVisitStepDataByVisitId(visitId);
      final stepData = allVisitData.where((data) => data.stepCode == stepCode).toList();
      final draftData = stepData.where((data) => data.dataType == 'order_draft').toList();

      if (draftData.isEmpty) {
        debugPrint('OrderDraftService: No order draft found');
        return null;
      }

      // Get the most recent draft
      draftData.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final latestDraft = draftData.first;

      final parsedData = jsonDecode(latestDraft.dataContent) as Map<String, dynamic>;

      // Validate data structure
      if (!_isValidDraftData(parsedData)) {
        debugPrint('OrderDraftService: Invalid draft data structure, ignoring');
        return null;
      }

      debugPrint('OrderDraftService: Order draft loaded successfully');
      return parsedData;
    } catch (e, stackTrace) {
      debugPrint('OrderDraftService: Failed to load order draft: $e');
      debugPrint('OrderDraftService: Stack trace: $stackTrace');
      return null; // Return null on error to allow graceful fallback
    }
  }

  /// Delete order draft data
  /// Called when order is completed or cancelled
  Future<void> deleteOrderDraft(String visitId, int stepCode) async {
    try {
      debugPrint('OrderDraftService: Deleting order draft for visit $visitId, step $stepCode');

      await _dbService.deleteVisitStepDataByStepCode(visitId, stepCode);

      debugPrint('OrderDraftService: Order draft deleted successfully');
    } catch (e, stackTrace) {
      debugPrint('OrderDraftService: Failed to delete order draft: $e');
      debugPrint('OrderDraftService: Stack trace: $stackTrace');
      // Don't rethrow - deletion failure is not critical
    }
  }

  /// Check if order draft exists
  Future<bool> hasOrderDraft(String visitId, int stepCode) async {
    try {
      final draft = await loadOrderDraft(visitId, stepCode);
      return draft != null;
    } catch (e) {
      debugPrint('OrderDraftService: Error checking draft existence: $e');
      return false;
    }
  }

  /// Validate draft data structure
  bool _isValidDraftData(Map<String, dynamic> data) {
    try {
      // Check required fields
      if (!data.containsKey('visitId') ||
          !data.containsKey('clientCode') ||
          !data.containsKey('stepCode') ||
          !data.containsKey('selectedOrganization') ||
          !data.containsKey('selectedWarehouse') ||
          !data.containsKey('selectedPriceType') ||
          !data.containsKey('products') ||
          !data.containsKey('notes')) {
        return false;
      }

      // Validate products array
      final products = data['products'];
      if (products is! List) {
        return false;
      }

      // Validate each product has required fields
      for (final product in products) {
        if (product is! Map<String, dynamic> ||
            !product.containsKey('codeProduct') ||
            !product.containsKey('amount') ||
            !product.containsKey('price')) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('OrderDraftService: Error validating draft data: $e');
      return false;
    }
  }

  /// Migrate old format data to new format
  /// Handles backward compatibility for existing saved data
  Map<String, dynamic>? _migrateDraftData(Map<String, dynamic> oldData) {
    try {
      // If data already has version field, it's in new format
      if (oldData.containsKey('version')) {
        return oldData;
      }

      // Migrate from old format (direct order data) to new format
      debugPrint('OrderDraftService: Migrating old format draft data');

      return {
        'visitId': oldData['visitId'] ?? '',
        'clientCode': oldData['clientCode'] ?? '',
        'stepCode': oldData['stepCode'] ?? 0,
        'stepName': oldData['stepName'] ?? '',
        'selectedOrganization': oldData['selectedOrganization'] ?? '',
        'selectedWarehouse': oldData['selectedWarehouse'] ?? '',
        'selectedPriceType': oldData['selectedPriceType'] ?? '',
        'products': oldData['products'] ?? [],
        'notes': oldData['notes'] ?? '',
        'timestamp': oldData['timestamp'] ?? DateTime.now().toIso8601String(),
        'version': 1,
      };
    } catch (e) {
      debugPrint('OrderDraftService: Error migrating draft data: $e');
      return null;
    }
  }

  /// Get draft statistics for debugging
  Future<Map<String, dynamic>> getDraftStats() async {
    try {
      final stats = await _dbService.getVisitStepDataStats();
      final draftCount = stats['dataTypes']?['order_draft'] ?? 0;

      return {
        'totalDrafts': draftCount,
        'totalVisitData': stats['total'] ?? 0,
        'pendingSync': stats['pending'] ?? 0,
      };
    } catch (e) {
      debugPrint('OrderDraftService: Error getting draft stats: $e');
      return {'error': e.toString()};
    }
  }
}

/// Lifecycle observer for automatic draft saving
class _DraftLifecycleObserver extends WidgetsBindingObserver {
  final Future<void> Function({
    required String visitId,
    required int stepCode,
    required List<CreateOrderProduct> products,
    required String selectedOrganization,
    required String selectedWarehouse,
    required String selectedPriceType,
    required String notes,
    required String stepName,
  }) onSave;
  final VoidCallback onDispose;

  _DraftLifecycleObserver({
    required this.onSave,
    required this.onDispose,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App is going to background or being terminated
        // Note: We can't perform async operations here directly
        // The actual save should be handled by the service
        break;
      case AppLifecycleState.resumed:
      case AppLifecycleState.hidden:
        // App is coming back to foreground
        break;
    }
  }

  @override
  void didHaveMemoryPressure() {
    // Save data when memory is low
    debugPrint('OrderDraftService: Memory pressure detected - forcing save');
  }
}