import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/kpi_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/price_type.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_price.dart';
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
        _dbHelper = dbHelper;

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

      // Sync product prices
      await _syncProductPrices(userCode);

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

      // Step 7: Sync product prices
      yield SyncStep.syncingProductPrices;
      await _syncProductPrices(userCode);

      // Step 8: Completed
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
    await _dbService.saveProductPrices(productPrices);
    return productPrices;
  }

  /// Get cached data (for offline scenarios)
  Future<KpiData?> getCachedKpiData(String userCode) => _dbService.getKpiData(userCode);
  Future<List<TradingPoint>> getCachedClients() => _dbService.getClients();
  Future<List<ProductData>> getCachedProducts() => _dbService.getProducts();
  Future<List<PriceType>> getCachedPriceTypes() => _dbService.getPriceTypes();
  Future<List<ProductPrice>> getCachedProductPrices({String? priceTypeCode}) =>
      _dbService.getProductPrices(priceTypeCode: priceTypeCode);

  /// Update cached clients (for local updates like visit status)
  Future<void> updateCachedClients(List<TradingPoint> clients) async {
    await _dbService.saveClients(clients);
  }
}