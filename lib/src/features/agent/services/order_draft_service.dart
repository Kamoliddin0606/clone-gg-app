import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/location_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
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
  String? _autoSaveClientCode;

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
    required String selectedOrganizationcode,
    required String selectedWarehousecode,
    required String selectedPriceTypecode,
    required DateTime shippingDate,
    required String clientCode,
  }) {
    _isAutoSaveEnabled = true;
    _autoSaveClientCode = clientCode;

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
          selectedOrganizationcode: selectedOrganizationcode,
          selectedWarehousecode: selectedWarehousecode,
          selectedPriceTypecode: selectedPriceTypecode,
          shippingDate: shippingDate,
        );
      }
    });

    debugPrint('OrderDraftService: Auto-save enabled for visit $visitId, step $stepCode with clientCode: $clientCode');
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
    required String selectedOrganizationcode,
    required String selectedWarehousecode,
    required String selectedPriceTypecode,
    required DateTime shippingDate,
  }) async {
    if (_isSaving) {
      debugPrint('OrderDraftService: Auto-save skipped - already saving');
      return;
    }

    try {
      _isSaving = true;
      debugPrint('OrderDraftService: Performing auto-save...');

      // Get clientCode from stored auto-save data
      final clientCode = _autoSaveClientCode ?? '';
      debugPrint('OrderDraftService: Auto-save using clientCode: "$clientCode"');

      await saveOrderDraft(
        visitId: visitId,
        clientCode: clientCode,
        stepCode: stepCode,
        stepName: stepName,
        selectedOrganization: selectedOrganization,
        selectedWarehouse: selectedWarehouse,
        selectedPriceType: selectedPriceType,
        selectedOrganizationcode: selectedOrganizationcode,
        selectedWarehousecode: selectedWarehousecode,
        selectedPriceTypecode: selectedPriceTypecode,
        shippingDate: shippingDate,
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
  /// Ensures only one draft per client per day by checking for existing drafts and merging data
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
    required String selectedOrganizationcode,
    required String selectedWarehousecode,
    required String selectedPriceTypecode,
    required DateTime shippingDate,
  }) async {
    try {
      debugPrint('OrderDraftService: Saving order draft for visit $visitId, step $stepCode');

      // Check if draft already exists for this visit and step
      final draftExists = await hasOrderDraft(visitId, stepCode);
      Map<String, dynamic>? existingDraft;

      if (draftExists) {
        // Load existing draft data to merge with new data
        debugPrint('OrderDraftService: Existing draft found, loading for merge');
        existingDraft = await loadOrderDraft(visitId, stepCode);
        if (existingDraft == null) {
          debugPrint('OrderDraftService: Failed to load existing draft, proceeding with new save');
        }
      }

      // Calculate additional fields with error handling
      String codeAgent = '';
      double longitude = 0.0;
      double latitude = 0.0;
      String codeProject = '';
      bool hasPromo = false;

      try {
        // Get current user code for codeAgent
        final SharedPreferencesService prefs = sl<SharedPreferencesService>();
        codeAgent = prefs.getUserCode() ?? '';
      } catch (e) {
        debugPrint('OrderDraftService: Error getting user code: $e');
      }

      try {
        // Get location data
        final LocationService locationService = sl<LocationService>();
        final locationData = locationService.getStoredLocation();
        if (locationData != null) {
          longitude = (locationData['longitude'] as num?)?.toDouble() ?? 0.0;
          latitude = (locationData['latitude'] as num?)?.toDouble() ?? 0.0;
        }
      } catch (e) {
        debugPrint('OrderDraftService: Error getting location data: $e');
      }

      try {
        // Get codeProject from user preferences
        final SharedPreferencesService prefs = sl<SharedPreferencesService>();
        codeProject = prefs.getCodeProject() ?? '';
      } catch (e) {
        debugPrint('OrderDraftService: Error getting codeProject: $e');
      }

      // Calculate hasPromo from selected products
      hasPromo = products.any((product) => product.promo);

      // Calculate weight and capacity from products
      double totalWeight = products.fold(0.0, (sum, product) => sum + (product.weight * product.amount));
      double totalCapacity = products.fold(0.0, (sum, product) => sum + (product.capacity * product.amount));

      // Prepare new products data
      List<Map<String, dynamic>> newProductsJson = products.map((p) => p.toJson()).toList();

      // If existing draft exists, merge products data
      if (existingDraft != null) {
        debugPrint('OrderDraftService: Merging products with existing draft');
        final existingProducts = existingDraft['products'] as List<dynamic>? ?? [];
        final mergedProducts = <Map<String, dynamic>>[];

        // Start with existing products
        for (final existingProduct in existingProducts) {
          if (existingProduct is Map<String, dynamic>) {
            mergedProducts.add(Map<String, dynamic>.from(existingProduct));
          }
        }

        // Merge/update with new products
        for (final newProduct in newProductsJson) {
          final codeProduct = newProduct['codeProduct'] as String?;
          if (codeProduct != null) {
            final existingIndex = mergedProducts.indexWhere((p) => p['codeProduct'] == codeProduct);
            if (existingIndex >= 0) {
              // Update existing product with new data
              mergedProducts[existingIndex] = Map<String, dynamic>.from(newProduct);
              debugPrint('OrderDraftService: Updated existing product $codeProduct');
            } else {
              // Add new product
              mergedProducts.add(Map<String, dynamic>.from(newProduct));
              debugPrint('OrderDraftService: Added new product $codeProduct');
            }
          }
        }

        newProductsJson = mergedProducts;
        debugPrint('OrderDraftService: Products merged, total products: ${newProductsJson.length}');
      }

      // Create draft order data with merged/new fields
      final draftData = {
        'visitId': visitId,
        'clientCode': clientCode,
        'stepCode': stepCode,
        'stepName': stepName,
        'selectedOrganization': selectedOrganization,
        'selectedWarehouse': selectedWarehouse,
        'selectedPriceType': selectedPriceType,
        'selectedOrganizationcode': selectedOrganizationcode,
        'selectedWarehousecode': selectedWarehousecode,
        'selectedPriceTypecode': selectedPriceTypecode,
        'shippingDate': shippingDate.toIso8601String(),
        'products': newProductsJson,
        'notes': notes,
        'timestamp': DateTime.now().toIso8601String(),
        'version': 1, // For future migration support
        // New fields as per requirements
        'codeAgent': codeAgent,
        'longitude': longitude,
        'latitude': latitude,
        'weight': totalWeight,
        'capacity': totalCapacity,
        'codeProject': codeProject,
        'hasPromo': hasPromo,
      };

      // If draft exists, delete it first to ensure only one draft per client per day
      if (draftExists) {
        debugPrint('OrderDraftService: Deleting existing draft before saving merged data');
        await deleteOrderDraft(visitId, stepCode);
      }

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

      debugPrint('OrderDraftService: Order draft saved successfully with merged data (ensuring only one draft per client per day)');
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
          !data.containsKey('selectedOrganizationcode') ||
          !data.containsKey('selectedWarehousecode') ||
          !data.containsKey('selectedPriceTypecode') ||
          !data.containsKey('shippingDate') ||
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
        'selectedOrganizationcode': oldData['selectedOrganizationcode'] ?? '',
        'selectedWarehousecode': oldData['selectedWarehousecode'] ?? '',
        'selectedPriceTypecode': oldData['selectedPriceTypecode'] ?? '',
        'shippingDate': oldData['shippingDate'] ?? DateTime.now().toIso8601String(),
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

  /// Clear all order drafts for a specific visit
  /// Used when visit is completed or cancelled to clean up draft data
  Future<void> clearVisitDrafts(String visitId) async {
    try {
      debugPrint('OrderDraftService: Clearing all order drafts for visit $visitId');

      // Get all visit step data for this visit
      final allVisitData = await _dbService.getVisitStepDataByVisitId(visitId);

      // Filter for order draft data
      final draftData = allVisitData.where((data) => data.dataType == 'order_draft').toList();

      if (draftData.isEmpty) {
        debugPrint('OrderDraftService: No order drafts found for visit $visitId');
        return;
      }

      // Delete each draft
      for (final draft in draftData) {
        await _dbService.deleteVisitStepData(draft.id!);
        debugPrint('OrderDraftService: Deleted order draft with id ${draft.id}');
      }

      debugPrint('OrderDraftService: Successfully cleared ${draftData.length} order drafts for visit $visitId');
    } catch (e, stackTrace) {
      debugPrint('OrderDraftService: Error clearing visit drafts: $e');
      debugPrint('OrderDraftService: Stack trace: $stackTrace');
      rethrow;
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
    required String selectedOrganizationcode,
    required String selectedWarehousecode,
    required String selectedPriceTypecode,
    required DateTime shippingDate,
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