import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_orchestrator.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/background_location_tracking_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/kpi_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/price_type.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_price.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/business_region.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/district_contracting.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/contract_type.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_warehouse.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_balance.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_brand.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_series.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_with_price.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_contract.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/main_report.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/business_region_report.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/akb_by_category.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_plan.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_plan_list.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order_status.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order_detail.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/planned_route.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_organization.dart';
import 'package:gloria_marketing_flutter/src/features/marketing/data/models/promotion_model.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/entities/user_entity.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/data_sync_progress_widget.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_image.dart';
import 'package:gloria_marketing_flutter/src/core/services/rest_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';

/// Centralized service for data synchronization and user validation
class DataSyncService {
  final SharedPreferencesService _prefs;
  final SoapApiService _apiService;
  final ApiDatabaseService _dbService;
  final DatabaseHelper _dbHelper;
  // NOTE: Media-server client images are synced on-demand per client
  // (e.g. ClientImagesPage / TradingPointsPage). Global sync does not
  // pull images to keep the sync lightweight.

  DataSyncService({
    required SharedPreferencesService prefs,
    required SoapApiService apiService,
    required ApiDatabaseService dbService,
    required DatabaseHelper dbHelper,
  }) : _prefs = prefs,
        _apiService = apiService,
        _dbService = dbService,
        _dbHelper = dbHelper {
    _initializeWorkManager();
  }

  static const String _backgroundSyncTask = 'backgroundDataSync';
  static const String _retrySyncTask = 'retryDataSync';

  void _initializeWorkManager() {
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  /// Register background sync task
  Future<void> registerBackgroundSync({
    Duration frequency = const Duration(hours: 6),
  }) async {
    // Get credentials from prefs since background task needs them
    final userCode = _prefs.getUserCode();
    final password = _prefs.getPassword();
    final codeProject = _prefs.getCodeProject();
    final codeSklad = _prefs.getWarehouseCode();

    if (userCode == null || password == null) {
      if (kDebugMode) print('Background sync: Missing credentials, cannot register.');
      return;
    }

    await Workmanager().registerPeriodicTask(
      _backgroundSyncTask,
      _backgroundSyncTask,
      frequency: frequency,
      inputData: {
        'userCode': userCode,
        'password': password,
        'codeProject': codeProject,
        'codeSklad': codeSklad,
      },
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
    if (kDebugMode) print('Background sync registered with frequency: $frequency');
  }

  /// Toggle background sync based on settings
  Future<void> toggleBackgroundSync(bool enabled) async {
    if (enabled) {
      final intervalHours = _prefs.getBgSyncInterval();
      final customMinutes = _prefs.getBgSyncCustomMinutes();
      
      Duration frequency;
      if (customMinutes != null && customMinutes >= 15) {
        // Use custom minutes (minimum 15 minutes - Android WorkManager limit)
        frequency = Duration(minutes: customMinutes);
      } else if (intervalHours > 0) {
        frequency = Duration(hours: intervalHours);
      } else {
        // Default to 6 hours
        frequency = Duration(hours: 6);
      }
      
      if (kDebugMode) {
        print('Background sync: Registering with frequency: ${frequency.inMinutes} minutes');
      }
      
      await registerBackgroundSync(frequency: frequency);
    } else {
      await cancelBackgroundSync();
    }
  }

  /// Cancel background sync
  Future<void> cancelBackgroundSync() async {
    await Workmanager().cancelByUniqueName(_backgroundSyncTask);
  }

  /// Register retry sync task for failed operations
  Future<void> registerRetrySync({
    required Map<String, dynamic> failedOperation,
    Duration delay = const Duration(minutes: 15),
  }) async {
    await Workmanager().registerOneOffTask(
      '${_retrySyncTask}_${DateTime.now().millisecondsSinceEpoch}',
      _retrySyncTask,
      inputData: failedOperation,
      initialDelay: delay,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// Check if preferences user matches database user table
  Future<bool> validateUserWithDatabase() async {
    if (kDebugMode) {
      print('Validating user with database...');
      print('User code: ${_prefs.getUserCode()}');
      print('User name: ${_prefs.getUserName()}');
    }

    try {
      final prefsUserCode = _prefs.getUserCode();
      final prefsUserName = _prefs.getUserName();
      final prefsWarehouseCode = _prefs.getWarehouseCode();
      final prefsCodeProject = _prefs.getCodeProject();

      // If no stored preferences, consider it valid
      if (prefsUserCode == null || prefsUserName == null) {
        if (kDebugMode) print('No stored preferences found');
        return true;
      }

      // Get user from database
      final dbUser = await _dbHelper.getUserByCode(prefsUserCode);
      if (kDebugMode) print('Database user: $dbUser');
      // If user not in database, consider it invalid (needs sync)
      if (dbUser == null) {
        if (kDebugMode) {
          print('User not found in database: $prefsUserCode');
        }
        return false;
      }

      // Check if user data matches
      final userMatches = dbUser['code'] == prefsUserCode &&
          dbUser['name'] == prefsUserName &&
          dbUser['warehouse_code'] == prefsWarehouseCode &&
          dbUser['code_project'] == prefsCodeProject;

      if (kDebugMode) {
        print('User validation: prefs=($prefsUserCode, $prefsUserName, $prefsWarehouseCode, $prefsCodeProject) vs db=(${dbUser['code']}, ${dbUser['name']}, ${dbUser['warehouse_code']}, ${dbUser['code_project']}) - matches: $userMatches');
      }

      return userMatches;
    } catch (e) {
      if (kDebugMode) {
        print('Error validating user with database: $e');
      }
      return false;
    }
  }

  /// Sync user data when preferences and database don't match
  Future<void> syncUserDataWithDatabase() async {
    try {
      final prefsUserCode = _prefs.getUserCode();
      final prefsUserName = _prefs.getUserName();
      final prefsWarehouseCode = _prefs.getWarehouseCode();
      final prefsCodeProject = _prefs.getCodeProject();

      if (prefsUserCode == null || prefsUserName == null) {
        return;
      }

      // Update database user table with preferences data
      await _dbHelper.saveUser({
        'code': prefsUserCode,
        'username': '', // We don't store username in prefs
        'password': '', // Don't store password
        'name': prefsUserName,
        'role': 'Agent', // Default role
        'warehouse_code': prefsWarehouseCode,
        'code_project': prefsCodeProject,
        'base_url': _prefs.getBaseUrl() ?? '',
        'telegram_id': _prefs.getTelegramID() ?? '',
        'chat_id': _prefs.getChatID() ?? '',
        'topic_id': _prefs.getTopicID() ?? '',
      });

      // Clear all other tables except users
      await clearAllCachedData();

      if (kDebugMode) {
        print('User data synced with database and other tables cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing user data with database: $e');
      }
      rethrow;
    }
  }

  /// Clear all cached data when user changes
  Future<void> clearAllCachedData() async {
    try {
      if (kDebugMode) {
        print('Clearing all cached data...');
      }
      await _dbService.clearAllData();
      if (kDebugMode) {
        print('All cached data cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing cached data: $e');
      }
      // Don't rethrow - continue with sync even if clearing fails
      // This prevents the sync from failing due to missing tables
    }
  }

  /// Clear main report data
  Future<void> clearMainReportData() async {
    try {
      if (kDebugMode) {
        print('Clearing main report data...');
      }
      await _dbService.clearMainReport();
      if (kDebugMode) {
        print('Main report data cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing main report data: $e');
      }
      rethrow;
    }
  }

  /// Sync all data for a user (force refresh)
  Future<void> syncAllUserData({
    required String userCode,
    required String password,
    required String codeProject,
    required String codeSklad,
  })
  async {
    try {
      if (kDebugMode) {
        print('Starting full data sync for user: $userCode');
      }

      // Sync KPI data
      await _syncKpiData(userCode, password);

      // Sync clients
      await _syncClients(userCode, password);

      // Sync products
      await _syncProducts(codeProject, codeSklad);

      // Sync price types
      await _syncPriceTypes(userCode);

      // Sync business regions
      await _syncBusinessRegions(userCode);

      // Sync user warehouses
      await _syncUserWarehouses(userCode);

      // Sync product prices
      await _syncProductPrices(userCode);

      // Sync product balances
      await _syncProductBalances(codeProject, codeSklad);

      // Sync client contracts
      await _syncClientContracts(userCode);

      // Sync order statuses
      await _syncOrderStatuses(userCode);

      // Sync orders
      await _syncOrders(userCode);

      // Sync sales req permissions
      await _syncSalesReqPermissions(userCode);

      // Sync planned routes
      await _syncPlannedRoutes(userCode);

      // Sync user organizations
      await _syncUserOrganizations(userCode);

      // Sync promotions
      if ( isAvonServerSelected() || isEvyapServerSelected() ) {
        await _syncPromotions(null); // No auth token needed for now
      }

      // Sync map tokens
      try {
        await syncMapTokens();
      } catch (e) {
        if (kDebugMode) {
        }
      }

      if( isEvyapServerSelected() ) {
        // Sync reports (current month by default)
        try {
          final now = DateTime.now();
          final startOfMonth = DateTime(now.year, now.month, 1);
          final endOfMonth = DateTime(now.year, now.month + 1, 0);

          final dateStart = startOfMonth.toIso8601String().split('T')[0];
          final dateEnd = endOfMonth.toIso8601String().split('T')[0];

          await _syncReportByPeriod(userCode, dateStart, dateEnd);
        } catch (e) {
          // Log error but don't fail the entire sync
          if (kDebugMode) {
            print('Error syncing reports: $e');
          }
          // Continue with other steps
        }
      }

      if (kDebugMode) {
        print('Full data sync completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during full data sync: $e');
      }
      rethrow;
    }
  }

  /// Sync all data for a user with progress updates
  Stream<SyncStep> syncAllUserDataWithProgress({
    required String userCode,
    required String password,
    required String codeProject,
    required String codeSklad,
  }) async* {
    final controller = StreamController<SyncStep>();

    try {
      if (kDebugMode) {
        print('Starting full data sync with progress for user: $userCode');
      }

      // Step 1: Check user validation
      yield SyncStep.checkingUser;
      final user = UserEntity(
        id: userCode,
        username: '',
        fullName: _prefs.getUserName() ?? '',
        role: '',
        code: userCode,
        name: _prefs.getUserName() ?? '',
        warehouseCode: codeSklad,
        codeProject: codeProject,
        baseUrl: _prefs.getBaseUrl() ?? '',
        telegramID: _prefs.getTelegramID() ?? '',
        chatID: _prefs.getChatID() ?? '',
        topicID: _prefs.getTopicID() ?? '',
      );

      final isValid = await validateUserWithDatabase();
      if (!isValid) {
        // Step 2: Sync user data with database
        yield SyncStep.clearingData;
        await syncUserDataWithDatabase();
      }

      // Step 3: Sync KPI data
      yield SyncStep.syncingKpi;
      await _syncKpiData(userCode, password);

      // Step 4: Sync clients
      yield SyncStep.syncingClients;
      await _syncClients(userCode, password);

      // Step 5: Sync products
      yield SyncStep.syncingProducts;
      await _syncProducts(codeProject, codeSklad);

      // Step 6: Sync price types
      yield SyncStep.syncingPriceTypes;
      await _syncPriceTypes(userCode);

      // Step 7: Sync business regions
      yield SyncStep.syncingBusinessRegions;
      await _syncBusinessRegions(userCode);

      // Step 8: Sync user warehouses
      yield SyncStep.syncingUserWarehouses;
      await _syncUserWarehouses(userCode);

      // Step 9: Sync product prices
      yield SyncStep.syncingProductPrices;
      await _syncProductPrices(userCode);

      // Step 10: Sync product balances
      yield SyncStep.syncingProductBalances;
      await _syncProductBalances(codeProject, codeSklad);

      // Step 11: Sync client contracts
      yield SyncStep.syncingClientContracts;
      await _syncClientContracts(userCode);

      // Step 12: Update clients has_contract field
      yield SyncStep.updatingClientContractStatus;
      await updateClientsHasContractField();

      // Step 13: Sync contract types (for contract creation)
      yield SyncStep.syncingContractTypes;
      await _syncContractTypes();

      // Step 14: Sync district contracting (for contract creation)
      yield SyncStep.syncingDistrictContracting;
      await _syncDistrictContracting(userCode, codeProject);

      // Step 15: Sync order statuses
      yield SyncStep.syncingOrderStatuses;
      await _syncOrderStatuses(userCode);

      // Step 13: Sync orders
      yield SyncStep.syncingOrders;
      await _syncOrders(userCode);

      // Step 14: Sync sales req permissions
      yield SyncStep.syncingSalesReqPermissions;
      await _syncSalesReqPermissions(userCode);

      // Step 15: Sync planned routes
      yield SyncStep.syncingPlannedRoutes;
      await _syncPlannedRoutes(userCode);

      // Step 16: Sync user organizations
      yield SyncStep.syncingUserOrganizations;
      await _syncUserOrganizations(userCode);

      if( isAvonServerSelected() || isEvyapServerSelected() ) {
        // Step 16: Sync promotions
        yield SyncStep.syncingPromotions;
        try {
          await _syncPromotions(null); // No auth token needed for now
        } catch (e) {
          // Log error but don't fail the entire sync
          if (kDebugMode) {
            print('Error syncing promotions: $e');
          }
          // Continue with other steps
        }
      }

      if( isEvyapServerSelected() ) {
        // Step 13: Sync reports (current month by default)
        yield SyncStep.syncingReports;
        try {
          final now = DateTime.now();
          final startOfMonth = DateTime(now.year, now.month, 1);
          final endOfMonth = DateTime(now.year, now.month + 1, 0);

          final dateStart = startOfMonth.toIso8601String().split('T')[0];
          final dateEnd = endOfMonth.toIso8601String().split('T')[0];

          await _syncReportByPeriod(userCode, dateStart, dateEnd);
        } catch (e) {
          // Log error but don't fail the entire sync
          if (kDebugMode) {
            print('Error syncing reports: $e');
          }
          // Continue with other steps
        }
      }

      // Step 19: Completed
      yield SyncStep.completed;

      if (kDebugMode) {
        print('Full data sync with progress completed successfully');
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error during full data sync with progress: $e');
      }
      controller.addError(e);
    } finally {
      await controller.close();
    }

    yield* controller.stream;
  }

  /// Sync KPI data
  Future<KpiData> syncKpiData({
    required String userCode,
    required String password,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _dbService.getKpiData(userCode);
      if (cached != null) {
        final updateTime = DateTime.parse(cached.updateDate);
        final now = DateTime.now();
        if (now.difference(updateTime).inHours < 1) {
          return cached;
        }
      }
    }

    return await _syncKpiData(userCode, password);
  }

  Future<KpiData> _syncKpiData(String userCode, String password) async {
    if (kDebugMode) {
      print('DataSyncService: Fetching KPI data from API for user: $userCode');
    }
    
    final kpiData = await _apiService.getKpiData(
      userCode: userCode,
      password: password,
    );
    
    if (kDebugMode) {
      print('DataSyncService: KPI data received from API: $kpiData');
      print('DataSyncService: KPI plan=${kpiData.plan}, fact=${kpiData.fact}');
    }
    
    // Save to database
    try {
      await _dbService.saveKpiData(userCode, kpiData);
      if (kDebugMode) {
        print('DataSyncService: KPI data saved to database successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DataSyncService: Error saving KPI data to database: $e');
      }
      rethrow;
    }
    
    return kpiData;
  }

  /// Sync clients data
  Future<List<TradingPoint>> syncClients({
    required String userCode,
    required String password,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _dbService.getClients();
      if (kDebugMode) print(cached);
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    return await _syncClients(userCode, password);
  }

  Future<List<TradingPoint>> _syncClients(String userCode, String password) async {
    final clients = await _apiService.getClients(
      userCode: userCode,
      password: password,
    );
    if (kDebugMode) {
      print('Mijozlar ma\'lumotlari yuklandi: ${clients.length} ta mijoz');
    }
    
    // Use incremental sync for better performance
    final stats = await _dbService.saveClientsIncremental(clients);
    if (kDebugMode) {
      print('[DeltaSync] Clients: +${stats['inserted']}, ~${stats['updated']}, -${stats['deleted']} (${stats['duration_ms']}ms)');
    }
    
    return clients;
  }

  /// Sync products data
  Future<List<ProductData>> syncProducts({
    required String codeProject,
    required String codeSklad,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _dbService.getProducts();
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    return await _syncProducts(codeProject, codeSklad);
  }

  Future<List<ProductData>> _syncProducts(String codeProject, String codeSklad) async {
    final products = await _apiService.getProducts(
      codeProject: codeProject,
      codeSklad: codeSklad,
    );
    if (kDebugMode) {
      print('Mahsulotlar ma\'lumotlari yuklandi: ${products.length} ta mahsulot');
    }
    
    // Use incremental sync for better performance
    final stats = await _dbService.saveProductsIncremental(products);
    if (kDebugMode) {
      print('[DeltaSync] Products: +${stats['inserted']}, ~${stats['updated']}, -${stats['deleted']} (${stats['duration_ms']}ms)');
    }
    
    return products;
  }

  /// Sync price types data
  Future<List<PriceType>> syncPriceTypes({
    required String userCode,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _dbService.getPriceTypes();
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    return await _syncPriceTypes(userCode);
  }

  Future<List<PriceType>> _syncPriceTypes(String userCode) async {
    final priceTypes = await _apiService.getPriceTypes(userCode: userCode);
    if (kDebugMode) {
      print('Narx turlari ma\'lumotlari yuklandi: ${priceTypes.length} ta narx turi');
    }
    await _dbService.savePriceTypes(priceTypes);
    return priceTypes;
  }

  /// Sync product prices data
  Future<List<ProductPrice>> syncProductPrices({
    required String userCode,
    bool forceRefresh = false,
    String? priceTypeCode,
  }) async {
    if (!forceRefresh) {
      final cached = await _dbService.getProductPrices(priceTypeCode: priceTypeCode);
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    return await _syncProductPrices(userCode);
  }

  Future<List<ProductPrice>> _syncProductPrices(String userCode) async {
    final productPrices = await _apiService.getProductPrices(userCode: userCode);
    if (kDebugMode) {
      print('Mahsulot narxlari ma\'lumotlari yuklandi: ${productPrices.length} ta narx');
    }
    
    // Use incremental sync for better performance
    final stats = await _dbService.saveProductPricesIncremental(productPrices);
    if (kDebugMode) {
      print('[DeltaSync] ProductPrices: +${stats['inserted']}, ~${stats['updated']}, -${stats['deleted']} (${stats['duration_ms']}ms)');
    }
    
    return productPrices;
  }

  /// Sync business regions data
  Future<List<BusinessRegion>> syncBusinessRegions({
    required String userCode,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _dbService.getBusinessRegions();
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    return await _syncBusinessRegions(userCode);
  }

  Future<List<BusinessRegion>> _syncBusinessRegions(String userCode) async {
    final regions = await _apiService.getBusinessRegions(userCode: userCode);
    if (kDebugMode) {
      print('Biznes rayonlari ma\'lumotlari yuklandi: ${regions.length} ta rayon');
    }
    await _dbService.saveBusinessRegions(regions);
    return regions;
  }

  /// Sync district contracting data
  Future<List<DistrictContracting>> syncDistrictContracting({
    required String userCode,
    required String codeProject,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _dbService.getDistrictContracting();
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    return await _syncDistrictContracting(userCode, codeProject);
  }

  Future<List<DistrictContracting>> _syncDistrictContracting(String userCode, String codeProject) async {
    final districts = await _apiService.getCitiesDistrictContracting(
      codeUser: userCode,
      codeProject: codeProject,
    );
    if (kDebugMode) {
      print('Shartnoma uchun shahar/tuman ma\'lumotlari yuklandi: ${districts.length} ta');
    }
    await _dbService.saveDistrictContracting(districts);
    return districts;
  }

  /// Get cached district contracting data
  Future<List<DistrictContracting>> getCachedDistrictContracting() async {
    return await _dbService.getDistrictContracting();
  }

  /// Sync user warehouses data
  Future<List<UserWarehouse>> syncUserWarehouses({
    required String userCode,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _dbService.getUserWarehouses();
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    return await _syncUserWarehouses(userCode);
  }

  Future<List<UserWarehouse>> _syncUserWarehouses(String userCode) async {
    final warehouses = await _apiService.getWarehousesUser(userCode: userCode);
    if (kDebugMode) {
      print('Foydalanuvchi omborlari ma\'lumotlari yuklandi: ${warehouses.length} ta ombor');
    }
    await _dbService.saveUserWarehouses(warehouses);
    return warehouses;
  }

  /// Sync product balances data
  Future<Map<String, dynamic>> syncProductBalances({
    required String codeProject,
    required String codeSklad,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _dbService.getProductBalances();
      if (cached.isNotEmpty) {
        return {
          'balances': cached,
          'brands': await _dbService.getProductBrands(),
          'series': await _dbService.getProductSeries(),
        };
      }
    }

    return await _syncProductBalances(codeProject, codeSklad);
  }

  Future<Map<String, dynamic>> _syncProductBalances(String codeProject, String codeSklad) async {
    final data = await _apiService.getProductBalances(
      codeProject: codeProject,
      codeSklad: codeSklad,
    );

    final balances = data['balances'] as List<ProductBalance>;
    final brands = data['brands'] as List<ProductBrand>;
    final series = data['series'] as List<ProductSeries>;

    if (kDebugMode) {
      print('Mahsulot balanslari ma\'lumotlari yuklandi: ${balances.length} ta balans, ${brands.length} ta brand, ${series.length} ta seriya');
    }

    // Use incremental sync for better performance
    final stats = await _dbService.saveProductBalancesIncremental(balances);
    if (kDebugMode) {
      print('[DeltaSync] ProductBalances: +${stats['inserted']}, ~${stats['updated']}, -${stats['deleted']} (${stats['duration_ms']}ms)');
    }
    
    await _dbService.saveProductBrands(brands);
    await _dbService.saveProductSeries(series);

    return data;
  }

  /// Create new business region
  Future<BusinessRegion> createBusinessRegion({
    required String userCode,
    required String code,
    required String name,
  }) async {
    // Validate input
    if (code.isEmpty || name.isEmpty) {
      throw Exception('Kod va nom bo\'sh bo\'lishi mumkin emas');
    }

    // Check if region already exists
    final existing = await _dbService.getBusinessRegionByCode(code);
    if (existing != null) {
      throw Exception('Bu kod bilan biznes rayoni allaqachon mavjud');
    }

    try {
      // Call API
      await _apiService.createBusinessRegion(
        userCode: userCode,
        code: code,
        name: name,
      );

      // Create local region object
      final region = BusinessRegion(
        code: code,
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to local database
      await _dbService.saveBusinessRegion(region);

      return region;
    } catch (e) {
      throw Exception('Biznes rayoni yaratishda xatolik: $e');
    }
  }

  /// Update business region
  Future<BusinessRegion> updateBusinessRegion({
    required String userCode,
    required String code,
    required String name,
  }) async {
    // Validate input
    if (code.isEmpty || name.isEmpty) {
      throw Exception('Kod va nom bo\'sh bo\'lishi mumkin emas');
    }

    // Check if region exists
    final existing = await _dbService.getBusinessRegionByCode(code);
    if (existing == null) {
      throw Exception('Bu kod bilan biznes rayoni topilmadi');
    }

    try {
      // Call API
      await _apiService.updateBusinessRegion(
        userCode: userCode,
        code: code,
        name: name,
      );

      // Update local region
      final updatedRegion = existing.copyWith(
        name: name,
        updatedAt: DateTime.now(),
      );

      // Save to local database
      await _dbService.updateBusinessRegion(code, updatedRegion);

      return updatedRegion;
    } catch (e) {
      throw Exception('Biznes rayoni yangilashda xatolik: $e');
    }
  }

  /// Delete business region by code
  Future<void> deleteBusinessRegion({
    required String userCode,
    required String code,
  }) async {
    // Check if region exists
    final existing = await _dbService.getBusinessRegionByCode(code);
    if (existing == null) {
      throw Exception('Bu kod bilan biznes rayoni topilmadi');
    }

    // Check for dependencies in clients table
    final db = await _dbService.database;
    final clientsWithRegion = await db.rawQuery(
      'SELECT COUNT(*) as count FROM clients WHERE code_region = ?',
      [code],
    );
    final count = Sqflite.firstIntValue(clientsWithRegion) ?? 0;

    if (count > 0) {
      throw Exception('Bu biznes rayoni $count ta mijozda ishlatilgan. Avval mijozlardan olib tashlang.');
    }

    try {
      // Call API
      await _apiService.deleteBusinessRegion(
        userCode: userCode,
        code: code,
      );

      // Delete from local database
      await _dbService.deleteBusinessRegion(code);
    } catch (e) {
      throw Exception('Biznes rayoni o\'chirishda xatolik: $e');
    }
  }

  /// Delete all business regions
  Future<void> deleteAllBusinessRegions({
    required String userCode,
  }) async {
    // Check for dependencies in clients table
    final db = await _dbService.database;
    final clientsWithRegions = await db.rawQuery(
      'SELECT COUNT(*) as count FROM clients WHERE code_region IS NOT NULL AND code_region != ""',
      [],
    );
    final count = Sqflite.firstIntValue(clientsWithRegions) ?? 0;

    if (count > 0) {
      throw Exception('Biznes rayonlari $count ta mijozda ishlatilgan. Avval mijozlardan olib tashlang.');
    }

    try {
      // Call API
      await _apiService.deleteAllBusinessRegions(userCode: userCode);

      // Clear local database
      await db.rawDelete('DELETE FROM business_regions');
    } catch (e) {
      throw Exception('Barcha biznes rayonlarini o\'chirishda xatolik: $e');
    }
  }

  /// Sync promotions data
  Future<List<PromotionModel>> syncPromotions({
    String? authToken,
    bool forceRefresh = false,
  }) async {

    final timestamp = DateTime.now().toIso8601String();
    if (kDebugMode) {
      print('[$timestamp] DEBUG SYNC: syncPromotions called, forceRefresh: $forceRefresh');
      print('[$timestamp] DEBUG SYNC: Checking cached promotions');
    }
    final cached = await _dbService.getPromotions();
    if (kDebugMode) print('[$timestamp] DEBUG SYNC: Cached promotions count: ${cached.length}');

    if (cached.isNotEmpty) {
      // Check if data is recent (less than 24 hours old)
      final mostRecentSync = cached
          .where((p) => p.lastSynced != null)
          .map((p) => p.lastSynced!)
          .fold<DateTime?>(null, (prev, curr) => prev == null || curr.isAfter(prev) ? curr : prev);

      if (kDebugMode) print('[$timestamp] DEBUG SYNC: Most recent sync: $mostRecentSync');

      if (mostRecentSync != null) {
        final now = DateTime.now();
        final diff = now.difference(mostRecentSync).inHours;
        if (kDebugMode) print('[$timestamp] DEBUG SYNC: Time difference: ${diff} hours');

        if (diff < 24) {
          if (kDebugMode) print('[$timestamp] DEBUG SYNC: Returning cached data (recent)');
          return cached;
        }
      }
    }

    if( isAvonServerSelected() || isEvyapServerSelected() ) {
      if (kDebugMode) print('[$timestamp] DEBUG SYNC: Proceeding with fresh sync');
      return await _syncPromotions(authToken);
    }
    return <PromotionModel>[];
  }

  /// Sync client contracts data
  Future<List<ClientContract>> syncClientContracts({
    required String userCode,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _dbService.getClientContracts();
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    return await _syncClientContracts(userCode);
  }

  Future<List<ClientContract>> _syncClientContracts(String userCode) async {
    final contracts = await _apiService.getAllContracts(userCode: userCode);
    if (kDebugMode) {
      print('Mijoz shartnomalari ma\'lumotlari yuklandi: ${contracts.length} ta shartnoma');
    }
    await _dbService.saveClientContracts(contracts);
    return contracts;
  }

  /// Syncs contract types from server to local database.
  /// 
  /// Contract types are required for creating new contracts.
  /// This data is relatively static and changes infrequently.
  /// 
  /// Returns: List of contract types synced
  Future<List<ContractType>> _syncContractTypes() async {
    try {
      final contractTypes = await _apiService.getTypeOfContract();
      if (kDebugMode) {
        print('DataSyncService: Contract types loaded: ${contractTypes.length} types');
      }
      
      if (contractTypes.isNotEmpty) {
        await _dbService.saveContractTypes(contractTypes);
      }
      
      return contractTypes;
    } catch (e) {
      if (kDebugMode) {
        print('DataSyncService: Error syncing contract types: $e');
      }
      // Return empty list on error - non-critical data
      return [];
    }
  }

  /// Update clients has_contract field based on active contracts
  /// This method should be called after client contracts sync to ensure data consistency
  Future<void> updateClientsHasContractField() async {
    try {
      if (kDebugMode) {
        print('Starting update of clients has_contract field...');
      }

      final db = await _dbService.database;

      // 1. Get all active contract client codes using HashSet for O(1) lookup
      final contractClientsResult = await db.rawQuery('''
        SELECT DISTINCT code_client
        FROM client_contracts
        WHERE active = 1 OR active = 0
      ''');
      // contractClientsResult  ni saralashga 919-qatorga joylashtirilishi kerak: WHERE active = 1
      final contractClientCodes = <String>{};
      for (final row in contractClientsResult) {
        final code = row['code_client'] as String?;
        if (code != null && code.isNotEmpty) {
          contractClientCodes.add(code);
        }
      }

      if (kDebugMode) {
        print('Found ${contractClientCodes.length} clients with active contracts');
      }

      // 2. Get all clients and update has_contract field
      final clients = await db.query('clients');
      final batch = db.batch();
      int updatedCount = 0;

      for (final client in clients) {
        final clientCode = client['code'] as String;
        final hasContract = contractClientCodes.contains(clientCode) ? 1 : 0;
        final currentHasContract = client['has_contract'] as int? ?? 0;

        // Only update if there's a change to minimize database operations
        if (hasContract != currentHasContract) {
          batch.update(
            'clients',
            {
              'has_contract': hasContract,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'code = ?',
            whereArgs: [clientCode],
          );
          updatedCount++;
        }
      }

      // Execute batch update if there are changes
      if (updatedCount > 0) {
        await batch.commit(noResult: true);
        if (kDebugMode) {
          print('Successfully updated has_contract field for $updatedCount clients');
        }
      } else {
        if (kDebugMode) {
          print('No client has_contract fields needed updating');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating clients has_contract field: $e');
      }
      // Don't rethrow to prevent sync failure - this is a non-critical operation
      // Log the error for debugging but allow sync to continue
    }
  }

  Future<List<PromotionModel>> _syncPromotions(String? authToken) async {
    if(isEvyapServerSelected()|| isAvonServerSelected()){
      final timestamp = DateTime.now().toIso8601String();
      if (kDebugMode) print('[$timestamp] DEBUG SYNC: _syncPromotions called');

      try {
        if (kDebugMode) print('[$timestamp] DEBUG SYNC: Calling _apiService.getPromotions');
        final promotions = await _apiService.getPromotions(authToken: authToken);
        if (kDebugMode) print('[$timestamp] DEBUG SYNC: API returned ${promotions.length} promotions');

        if (kDebugMode) {
          print('Aksiyalar ma\'lumotlari yuklandi: ${promotions.length} ta aksiya');
        }

        if (kDebugMode) print('[$timestamp] DEBUG SYNC: Saving promotions to database');
        await _dbService.savePromotions(promotions);
        if (kDebugMode) print('[$timestamp] DEBUG SYNC: Promotions saved to database');

        return promotions;
      } catch (e) {
        if (kDebugMode) print('[$timestamp] DEBUG SYNC: Error syncing promotions: $e');

        // If promotion API fails, return cached data instead of failing the entire sync
        try {
          final cachedPromotions = await _dbService.getPromotions();
          if (kDebugMode) print('[$timestamp] DEBUG SYNC: Returning ${cachedPromotions.length} cached promotions');
          return cachedPromotions;
        } catch (cacheError) {
          if (kDebugMode) print('[$timestamp] DEBUG SYNC: Error getting cached promotions: $cacheError');
          // Return empty list if both API and cache fail
          return [];
        }
      }
    }
    return <PromotionModel>[];
  }

  /// Sync report data
  Future<Map<String, dynamic>> syncReportByPeriod({
    required String userCode,
    required String dateStart,
    required String dateEnd,
    bool forceRefresh = false,
  }) async {
    if(isEvyapServerSelected()){
      if (!forceRefresh) {
        final cached = await _dbService.getMainReports(userCode: userCode);
        final existingReport = cached.firstWhere(
              (report) => report.dateStart.toIso8601String().split('T')[0] == dateStart &&
              report.dateEnd.toIso8601String().split('T')[0] == dateEnd,
          orElse: () => MainReport(
            userCode: '',
            dateStart: DateTime.parse(dateStart),
            dateEnd: DateTime.parse(dateEnd),
            countAKB: 0,
            countOKB: 0,
            cash: 0,
            transfer: 0,
            sum: 0,
            countVisited: 0,
          ),
        );

        if (existingReport.userCode.isNotEmpty) {
          // Return cached data with related tables
          final businessRegionReports = await _dbService.getBusinessRegionReports(mainReportId: existingReport.id);
          final akbByCategories = await _dbService.getAKBByCategories(mainReportId: existingReport.id);

          return {
            'mainReport': existingReport,
            'businessRegionReports': businessRegionReports,
            'akbByCategories': akbByCategories,
          };
        }
      }

      return await _syncReportByPeriod(userCode, dateStart, dateEnd);
    }
    return {};
  }

  Future<Map<String, dynamic>> _syncReportByPeriod(String userCode, String dateStart, String dateEnd) async {
    if(isEvyapServerSelected()){
      final reportData = await _apiService.getReportByPeriod(
        userCode: userCode,
        dateStart: dateStart,
        dateEnd: dateEnd,
      );

      final mainReport = reportData['mainReport'] as MainReport;
      final businessRegionReports = reportData['businessRegionReports'] as List<BusinessRegionReport>;
      final akbByCategories = reportData['akbByCategories'] as List<AKBByCategory>;

      if (kDebugMode) {
        print('Hisobot ma\'lumotlari yuklandi: ${businessRegionReports.length} ta biznes rayon, ${akbByCategories.length} ta kategoriya');
      }

      // Save main report first to get ID
      await _dbService.saveMainReports([mainReport]);
      await _dbService.saveBusinessRegionReports(businessRegionReports);
      debugPrint('all report data saved successfully');
      await _dbService.saveAKBByCategories(akbByCategories);
      debugPrint('all report data saved successfully');
      final savedReports = await _dbService.getMainReports(userCode: userCode);
      if (kDebugMode) print("___________saved report${savedReports.first.id}");
      final savedReport = savedReports.firstWhere(
            (r) => r.dateStart.toIso8601String().split('T')[0] == dateStart &&
            r.dateEnd.toIso8601String().split('T')[0] == dateEnd,
      );
      if (kDebugMode) print("___________saved report${savedReport}");
      // Update related tables with correct main_report_id
      final updatedBusinessRegionReports = businessRegionReports.map((report) =>
          report.copyWith(mainReportId: savedReport.id)
      ).toList();

      final updatedAKBByCategories = akbByCategories.map((category) =>
          category.copyWith(mainReportId: savedReport.id)
      ).toList();
      if (kDebugMode) print('yangilangan kategoriyalar: ${updatedAKBByCategories.length}');
      // Save related data
      await _dbService.saveBusinessRegionReports(updatedBusinessRegionReports);
      await _dbService.saveAKBByCategories(updatedAKBByCategories);

      // Display the saved reports data for debugging/UI integration
      if (kDebugMode) {
        print('Saved reports data: $savedReports');
        print('Main report: $savedReport');
        print('Business region reports: ${updatedBusinessRegionReports.length} items');
        print('AKB by categories: ${updatedAKBByCategories.length} items');
      }

      return {
        'mainReport': savedReport,
        'businessRegionReports': updatedBusinessRegionReports,
        'akbByCategories': updatedAKBByCategories,
      };
    }
    return {};
  }

  /// Get cached data (for offline scenarios)
  Future<KpiData?> getCachedKpiData(String userCode) => _dbService.getKpiData(userCode);
  Future<List<TradingPoint>> getCachedClients() => _dbService.getClients();
  Future<List<ProductData>> getCachedProducts() => _dbService.getProducts();
  Future<List<PriceType>> getCachedPriceTypes() => _dbService.getPriceTypes();
  Future<List<ProductPrice>> getCachedProductPrices({String? priceTypeCode}) =>
      _dbService.getProductPrices(priceTypeCode: priceTypeCode);
  Future<List<BusinessRegion>> getCachedBusinessRegions() => _dbService.getBusinessRegions();
  Future<List<UserWarehouse>> getCachedUserWarehouses() => _dbService.getUserWarehouses();
  Future<List<ProductBalance>> getCachedProductBalances({
    String? warehouseCode,
    String? productBrand,
    String? productSeries,
  }) => _dbService.getProductBalances(
    warehouseCode: warehouseCode,
    productBrand: productBrand,
    productSeries: productSeries,
  );
  Future<List<ProductBrand>> getCachedProductBrands() => _dbService.getProductBrands();
  Future<List<ProductSeries>> getCachedProductSeries({String? brandName}) =>
      _dbService.getProductSeries(brandName: brandName);
  Future<List<ClientContract>> getCachedClientContracts({
    String? clientCode,
    bool? active,
  }) => _dbService.getClientContracts(
    clientCode: clientCode,
    active: active,
  );

  /// Get cached client contracts with client names using efficient JOIN query
  Future<List<ClientContractWithName>> getCachedClientContractsWithNames({
    String? clientCode,
    bool? active,
  }) => _dbService.getClientContractsWithNames(
    clientCode: clientCode,
    active: active,
  );

  Future<List<PromotionModel>> getCachedPromotions({
    bool onlyActive = true,
    String? searchQuery,
    DateTime? dateFilter,
  }) => _dbService.getPromotions(
    onlyActive: onlyActive,
    searchQuery: searchQuery,
    dateFilter: dateFilter,
  );

  Future<List<MainReport>> getCachedMainReports({String? userCode}) =>
      _dbService.getMainReports(userCode: userCode);

  Future<List<BusinessRegionReport>> getCachedBusinessRegionReports({int? mainReportId}) =>
      _dbService.getBusinessRegionReports(mainReportId: mainReportId);

  Future<List<AKBByCategory>> getCachedAKBByCategories({int? mainReportId}) =>
      _dbService.getAKBByCategories(mainReportId: mainReportId);

  Future<List<VisitPlan>> getCachedVisitPlans({int? mainReportId, String? clientCode}) =>
      _dbService.getVisitPlans(mainReportId: mainReportId, clientCode: clientCode);

  Future<List<VisitPlanList>> getCachedVisitPlanLists({int? visitPlanId}) =>
      _dbService.getVisitPlanLists(visitPlanId: visitPlanId);

  /// Get cached products with prices using optimized JOIN query
  Future<List<ProductWithPrice>> getCachedProductsWithPrices({
    required String priceTypeCode,
    List<String>? warehouseCodes,
    String? searchQuery,
    String? codeProject,
  }) => _dbService.getProductsWithPrices(
    priceTypeCode: priceTypeCode,
    warehouseCodes: warehouseCodes,
    searchQuery: searchQuery,
    codeProject: codeProject,
  );

  /// Update cached clients (for local updates like visit status)
  Future<void> updateCachedClients(List<TradingPoint> clients) async {
    await _dbService.saveClients(clients);
  }

  /// Conflict resolution strategies
  Future<void> resolveConflicts({
    required String dataType,
    required List<Map<String, dynamic>> localData,
    required List<Map<String, dynamic>> remoteData,
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.lastWriteWins,
  }) async {
    switch (strategy) {
      case ConflictResolutionStrategy.lastWriteWins:
        await _resolveLastWriteWins(dataType, localData, remoteData);
        break;
      case ConflictResolutionStrategy.userPrompt:
      // For now, default to last write wins
      // In a real app, this would show a dialog to the user
        await _resolveLastWriteWins(dataType, localData, remoteData);
        break;
      case ConflictResolutionStrategy.merge:
        await _resolveMerge(dataType, localData, remoteData);
        break;
    }
  }

  Future<void> _resolveLastWriteWins(
      String dataType,
      List<Map<String, dynamic>> localData,
      List<Map<String, dynamic>> remoteData,
      ) async {
    // Compare timestamps and keep the most recent
    final merged = <Map<String, dynamic>>[];

    for (final remote in remoteData) {
      final local = localData.firstWhere(
            (l) => l['id'] == remote['id'] || l['code'] == remote['code'],
        orElse: () => <String, dynamic>{},
      );

      if (local.isEmpty) {
        merged.add(remote);
      } else {
        final localTime = DateTime.parse(local['updated_at'] ?? local['last_synced'] ?? '1970-01-01');
        final remoteTime = DateTime.parse(remote['updated_at'] ?? remote['last_synced'] ?? '1970-01-01');

        merged.add(remoteTime.isAfter(localTime) ? remote : local);
      }
    }

    // Save merged data based on type
    switch (dataType) {
      case 'promotions':
        final promotions = merged.map((m) => PromotionModel.fromMap(m)).toList();
        await _dbService.savePromotions(promotions);
        break;
    // Add other data types as needed
    }
  }

  Future<void> _resolveMerge(
      String dataType,
      List<Map<String, dynamic>> localData,
      List<Map<String, dynamic>> remoteData,
      ) async {
    // For promotions, merge by keeping all unique items
    final merged = <Map<String, dynamic>>[...localData];

    for (final remote in remoteData) {
      final exists = merged.any((m) => m['code'] == remote['code']);
      if (!exists) {
        merged.add(remote);
      }
    }

    switch (dataType) {
      case 'promotions':
        final promotions = merged.map((m) => PromotionModel.fromMap(m)).toList();
        await _dbService.savePromotions(promotions);
        break;
    }
  }

  /// Retry failed sync operations
  Future<void> retryFailedOperations() async {
    try {
      // Get failed operations from storage (you might want to implement this)
      final failedOps = await _getFailedOperations();

      for (final op in failedOps) {
        try {
          await _executeSyncOperation(op);
          await _removeFailedOperation(op['id']);
        } catch (e) {
          // If still failing, schedule another retry with exponential backoff
          final retryCount = op['retry_count'] ?? 0;
          if (retryCount < 3) {
            await registerRetrySync(
              failedOperation: {...op, 'retry_count': retryCount + 1},
              delay: Duration(minutes: (15 * (retryCount + 1)).toInt()),
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error retrying failed operations: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getFailedOperations() async {
    // This would typically read from a persistent storage
    // For now, return empty list
    return [];
  }

  Future<void> _executeSyncOperation(Map<String, dynamic> operation) async {
    final type = operation['type'];
    final data = operation['data'];

    switch (type) {
      case 'sync_promotions':
        await _syncPromotions(data['authToken']);
        break;
    // Add other operation types
    }
  }

  Future<void> _removeFailedOperation(String id) async {
    // Remove from persistent storage
  }

  /// Check if user has selected Evyap server in preferences
  /// Returns true if Evyap server is selected, false otherwise
  bool isEvyapServerSelected() {
    try {
      final serverName = _prefs.getServerName();
      return serverName == 'Evyap';
    } catch (e) {
      if (kDebugMode) {
        print('Error checking Evyap server selection: $e');
      }
      return false;
    }
  }

  /// Check if user has Avon server
  /// Returns true if current server is Avon, false otherwise
  bool isAvonServerSelected() {
    try {
      final serverName = _prefs.getServerName();
      return serverName == 'Avon';
    } catch (e) {
      if (kDebugMode) {
        print('Error checking Avon server: $e');
      }
      return false;
    }
  }

  /// Sync order statuses data
  Future<List<OrderStatus>> syncOrderStatuses({
    required String userCode,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _dbService.getOrderStatuses();
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    return await _syncOrderStatuses(userCode);
  }

  Future<List<OrderStatus>> _syncOrderStatuses(String userCode) async {
    final statuses = await _apiService.getOrderStatusList(userCode: userCode);
    if (kDebugMode) {
      print('Buyurtma statuslari ma\'lumotlari yuklandi: ${statuses.length} ta status');
    }
    await _dbService.saveOrderStatuses(statuses);
    // Return saved statuses with auto-generated IDs from database
    return await _dbService.getOrderStatuses();
  }

  /// Sync orders data
  Future<List<Order>> syncOrders({
    required String userCode,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _dbService.getOrders();
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    return await _syncOrders(userCode);
  }

  Future<List<Order>> _syncOrders(String userCode) async {
    final orders = await _apiService.getOrderList(userCode: userCode);
    if (kDebugMode) {
      print('Buyurtmalar ma\'lumotlari yuklandi: ${orders.length} ta buyurtma');
    }

    // Extract and cache unique courier data
    final uniqueCouriers = <String>{};
    final uniqueCourierCars = <String>{};

    for (final order in orders) {
      if (order.courierName != null && order.courierName!.isNotEmpty) {
        uniqueCouriers.add(order.courierName!);
      }
      if (order.courierCar != null && order.courierCar!.isNotEmpty) {
        uniqueCourierCars.add(order.courierCar!);
      }
    }
    if (kDebugMode) {
      print('uniqueCouriers: $uniqueCouriers');
      print('uniqueCourierCars: $uniqueCourierCars');
    }

    // Save unique courier data to cache
    for (final courierName in uniqueCouriers) {
      final car = orders.firstWhere((order) => order.courierName == courierName).courierCar;
      await _dbService.saveCourier(courierName, car);
    }

    for (final car in uniqueCourierCars) {
      await _dbService.saveCourierCar(car);
    }

    await _dbService.saveOrders(orders);

    return orders;
  }

  /// Get cached order statuses
  Future<List<OrderStatus>> getCachedOrderStatuses() => _dbService.getOrderStatuses();

  /// Get cached orders
  Future<List<Order>> getCachedOrders({
    String? clientCode,
    String? mainStatus,
    String? typePriceCode,
  }) => _dbService.getOrders(
    clientCode: clientCode,
    mainStatus: mainStatus,
    typePriceCode: typePriceCode,
  );

  /// Get cached order by num order
  Future<Order?> getCachedOrderByNumOrder(String numOrder) => _dbService.getOrderByNumOrder(numOrder);

  /// Update cached order status
  Future<void> updateCachedOrderStatus(String numOrder, String mainStatus) =>
      _dbService.updateOrderStatus(numOrder, mainStatus);

  /// Delete cached order
  Future<void> deleteCachedOrder(String numOrder) => _dbService.deleteOrder(numOrder);

  /// Get cached unique courier names
  Future<List<String>> getCachedCourierNames() => _dbService.getUniqueCourierNames();

  /// Get cached unique courier cars
  Future<List<String>> getCachedCourierCars() => _dbService.getUniqueCourierCars();

  /// Sync order details data
  Future<OrderDetail> syncOrderDetails({
    required String numberOrder,
    required String orderDate1,
    required String orderDate2,
    bool forceRefresh = false,
  }) async {
    if (kDebugMode) print('syncOrderDetails called with numberOrder: $numberOrder, orderDate1: $orderDate1, orderDate2: $orderDate2');
    if (!forceRefresh) {
      final cached = await _dbService.getOrderDetailByNumOrder(numberOrder);
      if (cached != null) {
        return cached;
      }
    }

    return await _syncOrderDetails(numberOrder, orderDate1, orderDate2);
  }

  Future<OrderDetail> _syncOrderDetails(String numberOrder, String orderDate1, String orderDate2) async {
    final orderDetail = await _apiService.getOrderDetails(
      numberOrder: numberOrder,
      orderDate1: orderDate1,
      orderDate2: orderDate2,
    );
    if (kDebugMode) {
      print('Buyurtma tafsilotlari yuklandi: ${orderDetail.numOrder}');
    }

    await _dbService.saveOrderDetail(orderDetail);
    return orderDetail;
  }

  /// Get cached order details
  Future<List<OrderDetail>> getCachedOrderDetails({String? numOrder}) =>
      _dbService.getOrderDetails(numOrder: numOrder);

  /// Get cached order detail by num order
  Future<OrderDetail?> getCachedOrderDetailByNumOrder(String numOrder) =>
      _dbService.getOrderDetailByNumOrder(numOrder);

  /// Save cached order detail
  Future<void> saveCachedOrderDetail(OrderDetail orderDetail) =>
      _dbService.saveOrderDetail(orderDetail);

  /// Update cached order detail
  Future<void> updateCachedOrderDetail(String numOrder, OrderDetail orderDetail) =>
      _dbService.updateOrderDetail(numOrder, orderDetail);

  /// Delete cached order detail
  Future<void> deleteCachedOrderDetail(String numOrder) =>
      _dbService.deleteOrderDetail(numOrder);

  /// Sync sales req permissions data
  Future<SalesReqPermissions?> syncSalesReqPermissions({
    required String userCode,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _dbService.getSalesReqPermissions(userCode);
      if (cached != null) {
        return cached;
      }
    }

    return await _syncSalesReqPermissions(userCode);
  }

  Future<SalesReqPermissions?> _syncSalesReqPermissions(String userCode) async {
    try {
      // Ensure tables exist before attempting sync
      await _dbService.ensureSalesReqPermissionsTableExists();

      final permissions = await _apiService.getSalesReqPermissions(userCode: userCode);

      // Debug: Log the full API response to identify null fields
      if (kDebugMode) {
        print('DEBUG: Full API response for getSalesReqPermissions:');
        print('permissions: ${permissions['permissions']}');
        if (permissions != null) {
          permissions.forEach((key, value) {
            if (kDebugMode) print('  $key: $value (type: ${value?.runtimeType})');
          });
        }
        print('Agent ruxsatlari ma\'lumotlari yuklandi: ${permissions?['userCode']}');
      }

      // Validate required fields before type casting
      if (permissions == null) {
        if (kDebugMode) {
          print('WARNING: API returned null response for getSalesReqPermissions');
        }
        return null;
      }

      // Check for null values in critical fields
      permissions['userCode']= userCode;

      final userCodeValue = permissions['userCode'];
      if (userCodeValue == null) {
        if (kDebugMode) print('WARNING: userCode is null in API response: ${permissions['visitSteps']}');
        if (kDebugMode) {
          print('WARNING: userCode is null in API response');
        }
        return null;
      }

      // Convert API response to SalesReqPermissions object with safe casting
      final salesReqPermissions = SalesReqPermissions(
        userCode: userCodeValue as String,
        skipTINduplicateCheck: permissions['permissions']['skipTINduplicateCheck'] as bool? ?? false,
        allowCreationWithoutTIN: permissions['permissions']['allowCreationWithoutTIN'] as bool? ?? false,
        allowCreatingPointOfSale: permissions['permissions']['allowCreatingPointOfSale'] as bool? ?? false,
        visit: permissions['permissions']['visit'] as bool? ?? false,
        strictSequence: permissions['permissions']['strictSequence'] as bool? ?? false,
        unplannedOrder: permissions['permissions']['unplannedOrder'] as bool? ?? false,
        plannedRoute: permissions['permissions']['plannedRoute'] as bool? ?? false,
        editClientCoordinates: permissions['permissions']['editClientCoordinates'] as bool? ?? false,
        clientZoneAccess: permissions['permissions']['clientZoneAccess'] as int? ?? 0,
        locationUpdateInterval: permissions['permissions']['locationUpdateInterval'] as int? ?? 0,
        visitSteps: (permissions['visitSteps'] as List<dynamic>? ?? []).map((step) => VisitStep(
          stepCode: step['stepCode'] as int,
          stepName: step['stepName'] as String,
          stepRequired: step['stepRequired'] as bool? ?? false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )).toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      if (kDebugMode) print(salesReqPermissions.visitSteps);

      // Save sales req permissions first to get the ID
      await _dbService.clearSalesReqPermissions();
      await _dbService.saveSalesReqPermissions([salesReqPermissions]);
      final savedPermission = await _dbService.getSalesReqPermissions(userCode);

      if (savedPermission == null) {
        if (kDebugMode) {
          print('WARNING: Could not retrieve saved sales req permissions for user: $userCode');
        }
        return null;
      }

      // Save visit steps with the correct sales_req_permissions_id
      // print('salesReqPermissions.visitSteps.isNotEmpty: ${salesReqPermissions[0].visitSteps.isNotEmpty}');
      if (salesReqPermissions.visitSteps.isNotEmpty) {
        try {

          await _dbService.saveVisitSteps(salesReqPermissions.visitSteps, savedPermission.id!);

          if (kDebugMode) {
            print('Successfully saved ${salesReqPermissions.visitSteps.length} visit steps for user: $userCode');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error saving visit steps for user $userCode: $e');
          }
          // Don't fail the entire sync if visit steps save fails
          // Log the error but continue
        }
      }

      return savedPermission;
    } catch (e) {
      // Handle different types of API errors gracefully
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data?.toString() ?? '';

        if (kDebugMode) {
          print('DioException in _syncSalesReqPermissions: Status $statusCode');
          print('Response data: $responseData');
          print('Error message: ${e.message}');
        }

        // Handle specific HTTP status codes
        if (statusCode == 500) {
          // Server error - API might not exist or be temporarily unavailable
          if (kDebugMode) {
            print('WARNING: getSalesReqPermissions API returned 500 error. This API may not be available on the current server.');
            print('The application will continue without sales request permissions data.');
          }
          // Return null instead of throwing - this allows the sync to continue
          return null;
        } else if (statusCode == 404) {
          // API endpoint not found
          if (kDebugMode) {
            print('WARNING: getSalesReqPermissions API endpoint not found (404). This API may not exist on the current server.');
            print('The application will continue without sales request permissions data.');
          }
          return null;
        } else if (statusCode == 403) {
          // Forbidden - user doesn't have permission
          if (kDebugMode) {
            print('WARNING: Access forbidden for getSalesReqPermissions API (403). User may not have permission.');
            print('The application will continue without sales request permissions data.');
          }
          return null;
        } else if (statusCode == 401) {
          // Unauthorized
          if (kDebugMode) {
            print('WARNING: Unauthorized access to getSalesReqPermissions API (401). Authentication may be required.');
            print('The application will continue without sales request permissions data.');
          }
          return null;
        }
      }

      // For any other errors, log and continue
      if (kDebugMode) {
        print('Error syncing sales req permissions: $e');
        print('The application will continue without sales request permissions data.');
      }

      // Return null instead of rethrowing to prevent sync failure
      return null;
    }
  }

  /// Get cached sales req permissions
  Future<SalesReqPermissions?> getCachedSalesReqPermissions(String userCode) =>
      _dbService.getSalesReqPermissions(userCode);

  /// Sync planned routes data
  Future<List<PlannedRoute>> syncPlannedRoutes({
    required String userCode,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _dbService.getPlannedRoutes(userCode);
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    return await _syncPlannedRoutes(userCode);
  }

  Future<List<PlannedRoute>> _syncPlannedRoutes(String userCode) async {
    final routeData = await _apiService.getPlannedRouteList(userCode: userCode);
    if (kDebugMode) {
      print('Rejalashtirilgan marshrutlar ma\'lumotlari yuklandi: ${routeData.length} ta marshrut');
    }

    // Convert API response to PlannedRoute objects
    final routes = routeData.map((routeMap) => PlannedRoute(
      id: 0, // Will be set by database
      userCode: userCode,
      codeWeekday: routeMap['codeWeekday'] as int,
      weekDay: routeMap['weekDay'] as String,
      codeClient: routeMap['codeClient'] as String,
      clientName: routeMap['clientName'] as String,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    )).toList();

    await _dbService.savePlannedRoutes(routes);
    return routes;
  }

  /// Get cached planned routes
  Future<List<PlannedRoute>> getCachedPlannedRoutes(String userCode) =>
      _dbService.getPlannedRoutes(userCode);

  /// Get cached planned routes by weekday
  Future<List<PlannedRoute>> getCachedPlannedRoutesByWeekday(String userCode, int codeWeekday) =>
      _dbService.getPlannedRoutesByWeekday(userCode, codeWeekday);

  /// Get cached planned routes by client
  Future<List<PlannedRoute>> getCachedPlannedRoutesByClient(String userCode, String codeClient) =>
      _dbService.getPlannedRoutesByClient(userCode, codeClient);

  /// Update client coordinates via API and database
  /// This method updates client coordinates on the server and local database
  /// Validates input parameters and handles errors gracefully
  Future<void> updateClientCoordinates({
    required String userCode,
    required String clientCode,
    required double latitude,
    required double longitude,
  }) async {
    // Validate input parameters
    if (userCode.isEmpty) {
      throw ArgumentError('UserCode cannot be empty');
    }
    if (clientCode.isEmpty) {
      throw ArgumentError('ClientCode cannot be empty');
    }
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError('Latitude must be between -90 and 90 degrees');
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError('Longitude must be between -180 and 180 degrees');
    }

    try {
      if (kDebugMode) {
        print('DataSyncService: Updating client coordinates for client: $clientCode, lat: $latitude, lng: $longitude');
      }

      // Call API to update coordinates on server
      await _apiService.updateClientCoordinates(
        userCode: userCode,
        clientCode: clientCode,
        latitude: latitude,
        longitude: longitude,
      );

      // Update local database
      await _dbService.updateClientCoordinates(clientCode, latitude, longitude);

      if (kDebugMode) {
        print('DataSyncService: Client coordinates updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DataSyncService: Error updating client coordinates: $e');
      }
      rethrow;
    }
  }

  /// Sync map tokens from server and save to shared preferences
  /// This method fetches Yandex and Google map tokens from the server
  /// and stores them in shared preferences for map services to use
  Future<Map<String, String>> syncMapTokens() async {
    try {
      if (kDebugMode) {
       // print('DataSyncService: Starting map tokens sync for user: $userCode');
      }

      // Fetch tokens from server using SOAP API
      final tokens = await _apiService.getMapTokens();

      if (kDebugMode) {
        print('DataSyncService: Retrieved tokens from server - Yandex: ${tokens['yandexToken']?.isNotEmpty == true ? 'Present' : 'Empty'}, Google: ${tokens['googleToken']?.isNotEmpty == true ? 'Present' : 'Empty'}');
      }

      // Save tokens to shared preferences
      final saved = await _prefs.saveMapTokens(
        yandexToken: tokens['yandexToken'] ?? '',
        googleToken: tokens['googleToken'] ?? '',
      );

      if (!saved) {
        if (kDebugMode) {
          print('DataSyncService: Failed to save map tokens to preferences');
        }
        throw Exception('Failed to save map tokens to shared preferences');
      }

      if (kDebugMode) {
        print('DataSyncService: Map tokens sync completed successfully');
      }

      return tokens;
    } catch (e) {
      if (kDebugMode) {
        print('DataSyncService: Error syncing map tokens: $e');
      }
      // Re-throw to allow caller to handle the error appropriately
      rethrow;
    }
  }

  /// Get cached map tokens from shared preferences
  Map<String, String> getCachedMapTokens() {
    return _prefs.getMapTokens();
  }

  /// Check if valid map tokens are available
  bool hasValidMapTokens() {
    return _prefs.hasValidMapTokens();
  }

  /// Get last time map tokens were updated
  DateTime? getMapTokensLastUpdated() {
    return _prefs.getMapTokensLastUpdated();
  }

  /// Sync user organizations data
  Future<List<UserOrganization>> syncUserOrganizations({
    required String userCode,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _dbService.getUserOrganizations(userCode);
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    return await _syncUserOrganizations(userCode);
  }

  Future<List<UserOrganization>> _syncUserOrganizations(String userCode) async {
    final organizations = await _apiService.getOrganizationsByUserCode(userCode: userCode);
    if (kDebugMode) {
      print('Foydalanuvchi tashkilotlari ma\'lumotlari yuklandi: ${organizations.length} ta tashkilot');
    }
    await _dbService.saveUserOrganizations(userCode, organizations);
    return organizations;
  }

  /// Sync visit steps data
  Future<List<VisitStep>> syncVisitSteps({
    required String userCode,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _dbService.getSalesReqPermissions(userCode);
      if (cached != null && cached.visitSteps.isNotEmpty) {
        return cached.visitSteps;
      }
    }

    return await _syncVisitSteps(userCode);
  }

  Future<List<VisitStep>> _syncVisitSteps(String userCode) async {
    try {
      // First sync sales req permissions to ensure we have the permissions data
      final permissions = await syncSalesReqPermissions(userCode: userCode, forceRefresh: true);

      if (permissions == null) {
        if (kDebugMode) {
          print('WARNING: No sales req permissions found for user: $userCode');
        }
        return [];
      }

      // Visit steps are already included in the permissions object
      // No additional API call needed as visit steps come with permissions
      if (kDebugMode) {
        print('Visit steps synced for user: $userCode, count: ${permissions.visitSteps.length}');
      }

      return permissions.visitSteps;
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing visit steps for user $userCode: $e');
      }
      // Return cached data if sync fails
      final cached = await _dbService.getSalesReqPermissions(userCode);
      return cached?.visitSteps ?? [];
    }
  }

  /// Get cached visit steps for a user
  Future<List<VisitStep>> getCachedVisitSteps(String userCode) async {
    final permissions = await _dbService.getSalesReqPermissions(userCode);
    return permissions?.visitSteps ?? [];
  }

  /// Save visit steps for a user (local update)
  Future<void> saveVisitSteps(String userCode, List<VisitStep> visitSteps) async {
    final permissions = await _dbService.getSalesReqPermissions(userCode);
    if (permissions == null) {
      throw Exception('Sales req permissions not found for user: $userCode');
    }

    await _dbService.saveVisitStepsLegacy(visitSteps);
  }

  /// Update visit step for a user
  Future<void> updateVisitStep(String userCode, int visitStepId, VisitStep visitStep) async {
    await _dbService.updateVisitStep(visitStepId, visitStep);
  }

  /// Delete visit step for a user
  Future<void> deleteVisitStep(String userCode, int visitStepId) async {
    await _dbService.deleteVisitStep(visitStepId);
  }

  /// Get visit steps count for a user
  Future<int> getVisitStepsCount(String userCode) async {
    final permissions = await _dbService.getSalesReqPermissions(userCode);
    if (permissions == null) return 0;
    return await _dbService.getVisitStepsCount(permissions.id!);
  }

  /// Sync create orders to server
  /// This method sends unsynced create orders to the server via SetOrder API
  Future<List<Map<String, dynamic>>> syncCreateOrders() async {
    try {
      if (kDebugMode) {
        print('DataSyncService: Starting create orders sync');
      }

      // Get all unsynced create orders
      final unsyncedOrders = await _dbService.getUnsyncedCreateOrders();

      if (unsyncedOrders.isEmpty) {
        if (kDebugMode) {
          print('DataSyncService: No unsynced create orders found');
        }
        return [];
      }

      final syncResults = <Map<String, dynamic>>[];

      for (final order in unsyncedOrders) {
        try {
          if (kDebugMode) {
            print('DataSyncService: Syncing create order ${order.id}');
          }

          // Send order to server
          final result = await _apiService.setOrder(order: order);

          // Update sync status
          await _dbService.updateCreateOrderSyncStatus(order.id!, true);

          syncResults.add({
            'orderId': order.id,
            'success': true,
            'result': result,
          });

          if (kDebugMode) {
            print('DataSyncService: Successfully synced create order ${order.id}');
          }
        } catch (e) {
          // Update sync status with error
          await _dbService.updateCreateOrderSyncStatus(order.id!, false, syncError: e.toString());

          syncResults.add({
            'orderId': order.id,
            'success': false,
            'error': e.toString(),
          });

          if (kDebugMode) {
            print('DataSyncService: Failed to sync create order ${order.id}: $e');
          }
        }
      }

      if (kDebugMode) {
        print('DataSyncService: Create orders sync completed. Results: $syncResults');
      }

      return syncResults;
    } catch (e) {
      if (kDebugMode) {
        print('DataSyncService: Error during create orders sync: $e');
      }
      rethrow;
    }
  }

  // =========================================================================
  // Product Images Sync (REST API)
  // =========================================================================

  /// Sync product images from REST API media server
  /// 
  /// Fetches all product images from the nomenklatura-image endpoint
  /// and saves them to local database for offline access.
  Future<List<ProductImage>> syncProductImages({
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final hasImages = await _dbService.hasProductImages();
        if (hasImages) {
          return await _dbService.getAllProductImages();
        }
      }

      return await _syncProductImagesFromServer();
    } catch (e) {
      if (kDebugMode) {
        print('DataSyncService: Error syncing product images: $e');
      }
      // Return cached images on error
      return await _dbService.getAllProductImages();
    }
  }

  /// Sync product images from server with proper code_1c matching
  /// 
  /// This method fetches images from the nomenklatura-image API endpoint
  /// and only saves images where the API's code_1c matches an existing
  /// product's code in the local database.
  /// 
  /// Algorithm:
  /// 1. Fetch all local product codes (efficient single query)
  /// 2. Fetch all images from server API
  /// 3. Extract code_1c from API response (nomenklatura_code field)
  /// 4. Filter images - only keep those matching local product codes
  /// 5. Upsert matched images (update existing, insert new)
  Future<List<ProductImage>> _syncProductImagesFromServer() async {
    try {
      // Get REST API service and token
      final restApiService = sl<RestApiService>();
      final tokenService = sl<TokenService>();
      
      final token = await tokenService.getValidAccessToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('DataSyncService: No auth token for product images sync');
        }
        return [];
      }

      // Step 1: Get all local product codes for O(1) matching
      final localProductCodes = await _dbService.getAllProductCodes();
      final productCodeSet = localProductCodes.toSet();

      if (productCodeSet.isEmpty) {
        if (kDebugMode) {
          print('DataSyncService: No local products found, skipping image sync');
        }
        return [];
      }

      if (kDebugMode) {
        print('DataSyncService: Found ${productCodeSet.length} local product codes for matching');
      }

      // Step 1.5: Fetch nomenklatura ID to code_1c mapping
      // This is needed because API returns nomenklatura as integer ID, not code_1c
      final nomenklaturaIdToCode = await restApiService.getNomenklaturaIdToCodeMapping(
        authToken: token,
      );
      
      if (kDebugMode) {
        print('DataSyncService: Got ${nomenklaturaIdToCode.length} nomenklatura ID->code mappings');
      }

      // Step 2: Fetch all product images from server
      final rawImages = await restApiService.getAllProductImages(
        authToken: token,
        onProgress: (fetched, total) {
          if (kDebugMode) {
            print('DataSyncService: Product images progress: $fetched / ${total ?? "?"}');
          }
        },
      );

      if (rawImages.isEmpty) {
        if (kDebugMode) {
          print('DataSyncService: No product images received from server');
        }
        return [];
      }

      if (kDebugMode) {
        print('DataSyncService: Received ${rawImages.length} images from server');
      }

      // Step 3 & 4: Extract code_1c and filter by matching local products
      final matchedImages = <ProductImage>[];
      int skippedCount = 0;
      final unmatchedCodes = <String>{};

      // Debug: print first 3 raw image responses to see structure
      if (kDebugMode && rawImages.isNotEmpty) {
        print('DataSyncService: Sample raw image response keys: ${rawImages.first.keys.toList()}');
        print('DataSyncService: Sample raw image response: ${rawImages.first}');
        print('DataSyncService: Sample local product codes: ${productCodeSet.take(5).toList()}');
      }

      for (final raw in rawImages) {
        // Extract product code from API response
        // Priority: 
        // 1. nomenklatura_code (direct code_1c field)
        // 2. code_1c (alternative field name)
        // 3. nomenklatura as integer ID -> lookup in mapping
        // 4. nomenklatura as string (fallback)
        String? code1c;
        
        if (raw['nomenklatura_code'] != null) {
          // Direct code_1c field from API
          code1c = raw['nomenklatura_code'].toString().trim();
        } else if (raw['code_1c'] != null) {
          // Alternative field name
          code1c = raw['code_1c'].toString().trim();
        } else if (raw['nomenklatura'] != null) {
          final nomenklatura = raw['nomenklatura'];
          if (nomenklatura is int) {
            // Numeric ID - lookup code_1c from mapping
            code1c = nomenklaturaIdToCode[nomenklatura];
            if (kDebugMode && code1c != null) {
              print('DataSyncService: Mapped nomenklatura ID $nomenklatura -> code_1c: $code1c');
            }
          } else if (nomenklatura is String) {
            // Try to parse as int first for ID lookup
            final parsedId = int.tryParse(nomenklatura);
            if (parsedId != null && nomenklaturaIdToCode.containsKey(parsedId)) {
              code1c = nomenklaturaIdToCode[parsedId];
            } else {
              // Use as-is if it's already a code
              code1c = nomenklatura.trim();
            }
          }
        }

        // Skip if no valid code found
        if (code1c == null || code1c.isEmpty) {
          skippedCount++;
          continue;
        }

        // Only save if product exists in local database
        if (productCodeSet.contains(code1c)) {
          matchedImages.add(ProductImage.fromApiResponse(raw, code1c));
        } else {
          skippedCount++;
          if (unmatchedCodes.length < 5) {
            unmatchedCodes.add(code1c);
          }
        }
      }
      
      if (kDebugMode && unmatchedCodes.isNotEmpty) {
        print('DataSyncService: Sample unmatched codes from API: $unmatchedCodes');
      }

      if (kDebugMode) {
        print('DataSyncService: Matched ${matchedImages.length} images, skipped $skippedCount (no matching product)');
      }

      if (matchedImages.isEmpty) {
        if (kDebugMode) {
          print('DataSyncService: No matching product images to save');
        }
        return [];
      }

      // Step 5: Upsert matched images (smart update/insert)
      final upsertedCount = await _dbService.upsertProductImages(
        matchedImages,
        validProductCodes: productCodeSet,
      );

      if (kDebugMode) {
        print('DataSyncService: Product images sync completed: $upsertedCount images upserted');
      }

      return matchedImages;
    } catch (e) {
      if (kDebugMode) {
        print('DataSyncService: Error fetching product images from server: $e');
      }
      rethrow;
    }
  }

  /// Get cached product images for a specific product
  Future<List<ProductImage>> getCachedProductImages(String productCode) async {
    return await _dbService.getProductImages(productCode);
  }

  /// Get main product image for a specific product
  Future<ProductImage?> getMainProductImage(String productCode) async {
    return await _dbService.getMainProductImage(productCode);
  }
}

/// Conflict resolution strategies
enum ConflictResolutionStrategy {
  lastWriteWins,
  userPrompt,
  merge,
}

/// WorkManager callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case 'backgroundDataSync':
          return await _performBackgroundSync(inputData ?? {});
        case 'retryDataSync':
          return await _performRetrySync(inputData ?? {});
        case 'backgroundLocationUpdate':
          return await _performBackgroundLocationUpdate(inputData ?? {});
        default:
          return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('WorkManager task failed: $e');
      }
      return false;
    }
  });
}

Future<bool> _performBackgroundSync(Map<String, dynamic> inputData) async {
  try {
    // Initialize services
    await setupServiceLocator();
    
    // Get orchestrator
    final orchestrator = sl<DataSyncOrchestrator>();
    
    if (kDebugMode) {
      print('Background sync starting...');
    }
    
    // Execute full sync
    // We use .last to wait for completion of the sync Stream
    await orchestrator.syncAll().last;
    
    if (kDebugMode) {
      print('Background sync completed successfully');
    }
    return true;
  } catch (e) {
    if (kDebugMode) {
      print('Background sync failed: $e');
    }
    return false;
  }
}

Future<bool> _performRetrySync(Map<String, dynamic> inputData) async {
  try {
    // TODO: Implement retry sync with proper service initialization
    if (kDebugMode) {
      print('Retry sync executed with data: $inputData');
    }
    return true;
  } catch (e) {
    if (kDebugMode) {
      print('Retry sync failed: $e');
    }
    return false;
  }
}

/// Background location update task
/// 
/// Bu funksiya Workmanager tomonidan fonda chaqiriladi.
/// Joylashuvni oladi va serverga yuboradi.
Future<bool> _performBackgroundLocationUpdate(Map<String, dynamic> inputData) async {
  try {
    if (kDebugMode) {
      print('Background location update starting...');
    }

    // Initialize services
    await setupServiceLocator();
    
    // Get BackgroundLocationTrackingService
    final backgroundLocationService = sl<BackgroundLocationTrackingService>();
    
    // Initialize and update location
    await backgroundLocationService.initialize();
    
    // Trigger a single location update
    // Note: The service will handle sending to server
    if (backgroundLocationService.isTrackingActive) {
      if (kDebugMode) {
        print('Background location update: Tracking is active, service will handle updates');
      }
    } else {
      // Start tracking if not active
      await backgroundLocationService.startTracking();
    }
    
    if (kDebugMode) {
      print('Background location update completed successfully');
    }
    return true;
  } catch (e) {
    if (kDebugMode) {
      print('Background location update failed: $e');
    }
    return false;
  }
}

