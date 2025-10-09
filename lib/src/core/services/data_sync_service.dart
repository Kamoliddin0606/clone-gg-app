import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/network/server_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/kpi_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/price_type.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_price.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/business_region.dart';
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
import 'package:gloria_marketing_flutter/src/features/marketing/data/models/promotion_model.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/entities/user_entity.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/data_sync_progress_widget.dart';

/// Centralized service for data synchronization and user validation
class DataSyncService {
  final SharedPreferencesService _prefs;
  final SoapApiService _apiService;
  final ApiDatabaseService _dbService;
  final DatabaseHelper _dbHelper;

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
    String? userCode,
    String? password,
    String? codeProject,
    String? codeSklad,
  }) async {
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
    try {
      final prefsUserCode = _prefs.getUserCode();
      final prefsUserName = _prefs.getUserName();
      final prefsWarehouseCode = _prefs.getWarehouseCode();
      final prefsCodeProject = _prefs.getCodeProject();

      // If no stored preferences, consider it valid
      if (prefsUserCode == null || prefsUserName == null) {
        return true;
      }

      // Get user from database
      final dbUser = await _dbHelper.getUserByCode(prefsUserCode);

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
      rethrow;
    }
  }

  /// Sync all data for a user (force refresh)
  Future<void> syncAllUserData({
    required String userCode,
    required String password,
    required String codeProject,
    required String codeSklad,
  }) async {
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

      // Sync promotions
      await _syncPromotions(null); // No auth token needed for now

      // Sync reports (current month by default)
      try {
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);

        final dateStart = startOfMonth.toIso8601String().split('T')[0];
        final dateEnd = endOfMonth.toIso8601String().split('T')[0];

        await _syncReportByPeriod(userCode, dateStart, dateEnd);
      } catch (e) {
        if (kDebugMode) {
          print('Error syncing reports: $e');
        }
        // Continue with other steps - reports are optional
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

      // Step 12: Sync promotions
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

      // Step 14: Completed
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
    final kpiData = await _apiService.getKpiData(
      userCode: userCode,
      password: password,
    );
    if (kDebugMode) {
      print('KPI ma\'lumotlari yuklandi: $kpiData');
    }
    await _dbService.saveKpiData(userCode, kpiData);
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
      print(cached);
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
    await _dbService.saveClients(clients);
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
    await _dbService.saveProducts(products);
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
    await _dbService.saveProductPrices(productPrices);
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

    await _dbService.saveProductBalances(balances);
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
    print('[$timestamp] DEBUG SYNC: syncPromotions called, forceRefresh: $forceRefresh');

    if (!forceRefresh) {
      print('[$timestamp] DEBUG SYNC: Checking cached promotions');
      final cached = await _dbService.getPromotions();
      print('[$timestamp] DEBUG SYNC: Cached promotions count: ${cached.length}');

      if (cached.isNotEmpty) {
        // Check if data is recent (less than 24 hours old)
        final mostRecentSync = cached
            .where((p) => p.lastSynced != null)
            .map((p) => p.lastSynced!)
            .fold<DateTime?>(null, (prev, curr) => prev == null || curr.isAfter(prev) ? curr : prev);

        print('[$timestamp] DEBUG SYNC: Most recent sync: $mostRecentSync');

        if (mostRecentSync != null) {
          final now = DateTime.now();
          final diff = now.difference(mostRecentSync).inHours;
          print('[$timestamp] DEBUG SYNC: Time difference: ${diff} hours');

          if (diff < 24) {
            print('[$timestamp] DEBUG SYNC: Returning cached data (recent)');
            return cached;
          }
        }
      }
    }

    print('[$timestamp] DEBUG SYNC: Proceeding with fresh sync');
    return await _syncPromotions(authToken);
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

  Future<List<PromotionModel>> _syncPromotions(String? authToken) async {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] DEBUG SYNC: _syncPromotions called');

    try {
      print('[$timestamp] DEBUG SYNC: Calling _apiService.getPromotions');
      final promotions = await _apiService.getPromotions(authToken: authToken);
      print('[$timestamp] DEBUG SYNC: API returned ${promotions.length} promotions');

      if (kDebugMode) {
        print('Aksiyalar ma\'lumotlari yuklandi: ${promotions.length} ta aksiya');
      }

      print('[$timestamp] DEBUG SYNC: Saving promotions to database');
      await _dbService.savePromotions(promotions);
      print('[$timestamp] DEBUG SYNC: Promotions saved to database');

      return promotions;
    } catch (e) {
      print('[$timestamp] DEBUG SYNC: Error syncing promotions: $e');

      // If promotion API fails, return cached data instead of failing the entire sync
      try {
        final cachedPromotions = await _dbService.getPromotions();
        print('[$timestamp] DEBUG SYNC: Returning ${cachedPromotions.length} cached promotions');
        return cachedPromotions;
      } catch (cacheError) {
        print('[$timestamp] DEBUG SYNC: Error getting cached promotions: $cacheError');
        // Return empty list if both API and cache fail
        return [];
      }
    }
  }

  /// Sync report data
  Future<Map<String, dynamic>> syncReportByPeriod({
    required String userCode,
    required String dateStart,
    required String dateEnd,
    bool forceRefresh = false,
  }) async {
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

  Future<Map<String, dynamic>> _syncReportByPeriod(String userCode, String dateStart, String dateEnd) async {
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
    final savedReports = await _dbService.getMainReports(userCode: userCode);
    final savedReport = savedReports.firstWhere(
      (r) => r.dateStart.toIso8601String().split('T')[0] == dateStart &&
             r.dateEnd.toIso8601String().split('T')[0] == dateEnd,
    );

    // Update related tables with correct main_report_id
    final updatedBusinessRegionReports = businessRegionReports.map((report) =>
      report.copyWith(mainReportId: savedReport.id)
    ).toList();

    final updatedAKBByCategories = akbByCategories.map((category) =>
      category.copyWith(mainReportId: savedReport.id)
    ).toList();

    // Save related data
    await _dbService.saveBusinessRegionReports(updatedBusinessRegionReports);
    await _dbService.saveAKBByCategories(updatedAKBByCategories);

    return {
      'mainReport': savedReport,
      'businessRegionReports': updatedBusinessRegionReports,
      'akbByCategories': updatedAKBByCategories,
    };
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
    // TODO: Implement background sync with proper service initialization
    // For now, this is a placeholder
    if (kDebugMode) {
      print('Background sync executed with data: $inputData');
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

