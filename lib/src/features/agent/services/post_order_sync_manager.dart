// =============================================================================
// POST ORDER SYNC MANAGER SERVICE
// =============================================================================
// This service is responsible for updating product & catalog related tables
// (products, product_balances, product_brands) and orders table in background
// after an order is successfully submitted to the server.
//
// Main responsibilities:
// - Update product data after successful order submission
// - Reload orders table from server
// - Notify UI about sync progress (via callbacks)
// - Handle errors and retries
//
// Usage:
// final manager = PostOrderSyncManager(dataSyncService: sl<DataSyncService>());
// await manager.syncAfterOrderSubmission(onProgress: (status) => print(status));
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';

/// =============================================================================
/// SYNC STATUS ENUM
/// =============================================================================
/// Synchronization process states.
/// UI uses these states to display appropriate messages to the user.
/// =============================================================================
enum PostOrderSyncStatus {
  /// Sync not started or waiting
  idle,
  
  /// Products data is being updated
  syncingProducts,
  
  /// Product balances and brands are being updated
  syncingProductBalances,
  
  /// Orders list is being updated
  syncingOrders,
  
  /// All synchronization completed successfully
  completed,
  
  /// Error occurred during synchronization
  error,
}

/// =============================================================================
/// SYNC PROGRESS MODEL
/// =============================================================================
/// Model for storing sync process progress information.
/// UI uses this model to display detailed information to the user.
/// =============================================================================
class PostOrderSyncProgress {
  /// Current synchronization status
  final PostOrderSyncStatus status;
  
  /// Message to display to the user (localization key)
  final String message;
  
  /// Total number of steps
  final int totalSteps;
  
  /// Current step number (starts from 1)
  final int currentStep;
  
  /// Error message (if any)
  final String? errorMessage;
  
  /// Constructor
  const PostOrderSyncProgress({
    required this.status,
    required this.message,
    this.totalSteps = 3,
    this.currentStep = 0,
    this.errorMessage,
  });
  
  /// Progress percentage (0.0 to 1.0)
  double get progressPercent => totalSteps > 0 ? currentStep / totalSteps : 0.0;
  
  /// Check if synchronization is in progress
  bool get isInProgress => status != PostOrderSyncStatus.idle && 
                           status != PostOrderSyncStatus.completed && 
                           status != PostOrderSyncStatus.error;
  
  /// CopyWith method
  PostOrderSyncProgress copyWith({
    PostOrderSyncStatus? status,
    String? message,
    int? totalSteps,
    int? currentStep,
    String? errorMessage,
  }) {
    return PostOrderSyncProgress(
      status: status ?? this.status,
      message: message ?? this.message,
      totalSteps: totalSteps ?? this.totalSteps,
      currentStep: currentStep ?? this.currentStep,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  @override
  String toString() {
    return 'PostOrderSyncProgress(status: $status, message: $message, '
           'progress: $currentStep/$totalSteps, error: $errorMessage)';
  }
}

/// =============================================================================
/// POST ORDER SYNC MANAGER
/// =============================================================================
/// Manager class for background data synchronization after successful
/// order submission.
///
/// This manager updates the following tables:
/// 1. Products - Products table
/// 2. Product Balances - Product balances (stock)
/// 3. Product Brands - Product brands
/// 4. Orders - Orders list
///
/// Usage example:
/// ```dart
/// final manager = PostOrderSyncManager(dataSyncService: sl<DataSyncService>());
/// 
/// // With callback
/// await manager.syncAfterOrderSubmission(
///   onProgress: (progress) {
///     print('Status: ${progress.status}, Message: ${progress.message}');
///   },
/// );
///
/// // With stream
/// manager.syncAfterOrderSubmissionStream().listen((progress) {
///   print('Progress: ${progress.currentStep}/${progress.totalSteps}');
/// });
/// ```
/// =============================================================================
class PostOrderSyncManager {
  /// DataSyncService - main synchronization service
  final DataSyncService _dataSyncService;
  
  /// SharedPreferencesService - for getting user data
  final SharedPreferencesService _prefs;
  
  /// Current synchronization state
  PostOrderSyncProgress _currentProgress = const PostOrderSyncProgress(
    status: PostOrderSyncStatus.idle,
    message: '',
  );
  
  /// StreamController for tracking progress changes
  final StreamController<PostOrderSyncProgress> _progressController = 
      StreamController<PostOrderSyncProgress>.broadcast();
  
  /// Check if synchronization is in progress
  bool _isSyncing = false;
  
  /// =============================================================================
  /// CONSTRUCTOR
  /// =============================================================================
  /// [dataSyncService] - Main synchronization service
  /// [prefs] - Preferences service for user data
  /// =============================================================================
  PostOrderSyncManager({
    required DataSyncService dataSyncService,
    SharedPreferencesService? prefs,
  }) : _dataSyncService = dataSyncService,
       _prefs = prefs ?? sl<SharedPreferencesService>();
  
  /// =============================================================================
  /// GETTERS
  /// =============================================================================
  
  /// Get current progress information
  PostOrderSyncProgress get currentProgress => _currentProgress;
  
  /// Check if synchronization is in progress
  bool get isSyncing => _isSyncing;
  
  /// Progress stream - UI can subscribe to this stream
  Stream<PostOrderSyncProgress> get progressStream => _progressController.stream;
  
  /// =============================================================================
  /// MAIN SYNC METHOD (With callback)
  /// =============================================================================
  /// Main method called after successful order submission.
  /// 
  /// [onProgress] - Callback function for each step
  /// [forceRefresh] - Ignore cache and force refresh
  /// 
  /// Returns: true - success, false - error
  /// =============================================================================
  Future<bool> syncAfterOrderSubmission({
    void Function(PostOrderSyncProgress)? onProgress,
    bool forceRefresh = true,
  }) async {
    // If sync is already in progress, return
    if (_isSyncing) {
      debugPrint('PostOrderSyncManager: Sync already in progress');
      return false;
    }
    
    _isSyncing = true;
    
    try {
      debugPrint('PostOrderSyncManager: Starting sync after order submission');
      
      // Get user data
      final userCode = _prefs.getUserCode();
      final codeProject = _prefs.getCodeProject();
      final codeSklad = _prefs.getWarehouseCode();
      
      // Check if data is available
      if (userCode == null || userCode.isEmpty) {
        _emitProgress(PostOrderSyncProgress(
          status: PostOrderSyncStatus.error,
          message: 'syncErrorUserNotFound',
          errorMessage: 'userCode is null or empty',
        ), onProgress);
        return false;
      }
      
      // =========================================================================
      // STEP 1: PRODUCTS SYNC
      // =========================================================================
      _emitProgress(PostOrderSyncProgress(
        status: PostOrderSyncStatus.syncingProducts,
        message: 'syncingProducts',
        totalSteps: 3,
        currentStep: 1,
      ), onProgress);
      
      try {
        await _dataSyncService.syncProducts(
          codeProject: codeProject ?? '',
          codeSklad: codeSklad ?? '',
          forceRefresh: forceRefresh,
        );
        debugPrint('PostOrderSyncManager: Products synced successfully');
      } catch (e) {
        debugPrint('PostOrderSyncManager: Error syncing products: $e');
        // Continue even if error - not critical
      }
      
      // =========================================================================
      // STEP 2: PRODUCT BALANCES AND BRANDS SYNC
      // =========================================================================
      _emitProgress(PostOrderSyncProgress(
        status: PostOrderSyncStatus.syncingProductBalances,
        message: 'syncingProductBalances',
        totalSteps: 3,
        currentStep: 2,
      ), onProgress);
      
      try {
        // syncProductBalances method updates balances, brands and series together
        await _dataSyncService.syncProductBalances(
          codeProject: codeProject ?? '',
          codeSklad: codeSklad ?? '',
          forceRefresh: forceRefresh,
        );
        debugPrint('PostOrderSyncManager: Product balances and brands synced successfully');
      } catch (e) {
        debugPrint('PostOrderSyncManager: Error syncing product balances: $e');
        // Continue even if error - not critical
      }
      
      // =========================================================================
      // STEP 3: ORDERS LIST SYNC
      // =========================================================================
      _emitProgress(PostOrderSyncProgress(
        status: PostOrderSyncStatus.syncingOrders,
        message: 'syncingOrders',
        totalSteps: 3,
        currentStep: 3,
      ), onProgress);
      
      try {
        await _dataSyncService.syncOrders(
          userCode: userCode,
          forceRefresh: forceRefresh,
        );
        debugPrint('PostOrderSyncManager: Orders synced successfully');
      } catch (e) {
        debugPrint('PostOrderSyncManager: Error syncing orders: $e');
        // Continue even if error - not critical
      }
      
      // =========================================================================
      // COMPLETION
      // =========================================================================
      _emitProgress(PostOrderSyncProgress(
        status: PostOrderSyncStatus.completed,
        message: 'syncCompleted',
        totalSteps: 3,
        currentStep: 3,
      ), onProgress);
      
      debugPrint('PostOrderSyncManager: All sync completed successfully');
      return true;
      
    } catch (e, stackTrace) {
      debugPrint('PostOrderSyncManager: General error: $e');
      debugPrint('PostOrderSyncManager: Stack trace: $stackTrace');
      
      _emitProgress(PostOrderSyncProgress(
        status: PostOrderSyncStatus.error,
        message: 'syncError',
        errorMessage: e.toString(),
      ), onProgress);
      
      return false;
    } finally {
      _isSyncing = false;
    }
  }
  
  /// =============================================================================
  /// STREAM-BASED SYNC METHOD
  /// =============================================================================
  /// Post-order sync - delivers progress data via Stream.
  /// UI can subscribe to this stream.
  ///
  /// [forceRefresh] - Ignore cache and force refresh
  ///
  /// Returns: Progress stream
  /// =============================================================================
  Stream<PostOrderSyncProgress> syncAfterOrderSubmissionStream({
    bool forceRefresh = true,
  }) async* {
    // If sync is already in progress, emit error
    if (_isSyncing) {
      yield PostOrderSyncProgress(
        status: PostOrderSyncStatus.error,
        message: 'syncAlreadyInProgress',
        errorMessage: 'Sync already in progress',
      );
      return;
    }
    
    _isSyncing = true;
    
    try {
      debugPrint('PostOrderSyncManager: Starting stream-based sync');
      
      // Get user data
      final userCode = _prefs.getUserCode();
      final codeProject = _prefs.getCodeProject();
      final codeSklad = _prefs.getWarehouseCode();
      
      if (userCode == null || userCode.isEmpty) {
        yield PostOrderSyncProgress(
          status: PostOrderSyncStatus.error,
          message: 'syncErrorUserNotFound',
          errorMessage: 'userCode is null or empty',
        );
        return;
      }
      
      // STEP 1: Products
      yield PostOrderSyncProgress(
        status: PostOrderSyncStatus.syncingProducts,
        message: 'syncingProducts',
        totalSteps: 3,
        currentStep: 1,
      );
      
      try {
        await _dataSyncService.syncProducts(
          codeProject: codeProject ?? '',
          codeSklad: codeSklad ?? '',
          forceRefresh: forceRefresh,
        );
      } catch (e) {
        debugPrint('PostOrderSyncManager: Products error: $e');
      }
      
      // STEP 2: Product balances
      yield PostOrderSyncProgress(
        status: PostOrderSyncStatus.syncingProductBalances,
        message: 'syncingProductBalances',
        totalSteps: 3,
        currentStep: 2,
      );
      
      try {
        await _dataSyncService.syncProductBalances(
          codeProject: codeProject ?? '',
          codeSklad: codeSklad ?? '',
          forceRefresh: forceRefresh,
        );
      } catch (e) {
        debugPrint('PostOrderSyncManager: Balances error: $e');
      }
      
      // STEP 3: Orders
      yield PostOrderSyncProgress(
        status: PostOrderSyncStatus.syncingOrders,
        message: 'syncingOrders',
        totalSteps: 3,
        currentStep: 3,
      );
      
      try {
        await _dataSyncService.syncOrders(
          userCode: userCode,
          forceRefresh: forceRefresh,
        );
      } catch (e) {
        debugPrint('PostOrderSyncManager: Orders error: $e');
      }
      
      // Completion
      yield PostOrderSyncProgress(
        status: PostOrderSyncStatus.completed,
        message: 'syncCompleted',
        totalSteps: 3,
        currentStep: 3,
      );
      
      debugPrint('PostOrderSyncManager: Stream sync completed');
      
    } catch (e, stackTrace) {
      debugPrint('PostOrderSyncManager: Stream error: $e');
      debugPrint('PostOrderSyncManager: Stack trace: $stackTrace');
      
      yield PostOrderSyncProgress(
        status: PostOrderSyncStatus.error,
        message: 'syncError',
        errorMessage: e.toString(),
      );
    } finally {
      _isSyncing = false;
    }
  }
  
  /// =============================================================================
  /// HELPER METHODS
  /// =============================================================================
  
  /// Emit progress data
  void _emitProgress(PostOrderSyncProgress progress, void Function(PostOrderSyncProgress)? callback) {
    _currentProgress = progress;
    _progressController.add(progress);
    callback?.call(progress);
  }
  
  /// Dispose resources
  void dispose() {
    _progressController.close();
  }
}
