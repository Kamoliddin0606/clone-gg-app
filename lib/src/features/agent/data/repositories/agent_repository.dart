import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
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

class AgentRepository {
  final DataSyncService _dataSyncService;

  AgentRepository({
    required DataSyncService dataSyncService,
  }) : _dataSyncService = dataSyncService;

  /// Get KPI data from server and cache locally
  Future<KpiData> getKpiData({
    required String userCode,
    required String password,
    bool forceRefresh = false,
  }) async {
    try {
      return await _dataSyncService.syncKpiData(
        userCode: userCode,
        password: password,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      // If API fails, try to return cached data
      print('Error fetching KPI data: $e');
      final cachedData = await _dataSyncService.getCachedKpiData(userCode);
      if (cachedData != null) {
        print('Returning cached KPI data: $cachedData');
        return cachedData;
      }

      // If no cached data, return default values
      return KpiData(
        plan: '0',
        fact: '0',
        totalPercent: '0%',
        totalForecast: '0',
        totalPercentForecastFact: '0%',
        akbPlan: '0',
        akbFact: '0',
        akbPercent: '0%',
        okb: '0',
        updateDate: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Get clients list from server and cache locally
  Future<List<TradingPoint>> getClients({
    required String userCode,
    required String password,
    bool forceRefresh = false,
  }) async {
    try {
      return await _dataSyncService.syncClients(
        userCode: userCode,
        password: password,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      // If API fails, try to return cached data
      final cachedData = await _dataSyncService.getCachedClients();
      if (cachedData.isNotEmpty) {
        return cachedData;
      }

      // Return empty list if no cached data
      return [];
    }
  }

  /// Get products list from server and cache locally
  Future<List<ProductData>> getProducts({
    required String codeProject,
    required String codeSklad,
    bool forceRefresh = false,
  }) async {
    try {
      return await _dataSyncService.syncProducts(
        codeProject: codeProject,
        codeSklad: codeSklad,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      // If API fails, try to return cached data
      final cachedData = await _dataSyncService.getCachedProducts();
      if (cachedData.isNotEmpty) {
        return cachedData;
      }

      // Return empty list if no cached data
      return [];
    }
  }

  /// Get price types from server and cache locally
  Future<List<PriceType>> getPriceTypes({
    required String userCode,
    bool forceRefresh = false,
  }) async {
    try {
      return await _dataSyncService.syncPriceTypes(
        userCode: userCode,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      // If API fails, try to return cached data
      final cachedData = await _dataSyncService.getCachedPriceTypes();
      if (cachedData.isNotEmpty) {
        return cachedData;
      }

      // Return empty list if no cached data
      return [];
    }
  }

  /// Get product prices from server and cache locally
  Future<List<ProductPrice>> getProductPrices({
    required String userCode,
    bool forceRefresh = false,
    String? priceTypeCode,
  }) async {
    try {
      return await _dataSyncService.syncProductPrices(
        userCode: userCode,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      // If API fails, try to return cached data
      final cachedData = await _dataSyncService.getCachedProductPrices(priceTypeCode: priceTypeCode);
      if (cachedData.isNotEmpty) {
        return cachedData;
      }

      // Return empty list if no cached data
      return [];
    }
  }

  /// Get products with prices using optimized JOIN query
  Future<List<ProductWithPrice>> getProductsWithPrices({
    required String priceTypeCode,
    List<String>? warehouseCodes,
    String? searchQuery,
    String? codeProject,
  }) async {
    try {
      return await _dataSyncService.getCachedProductsWithPrices(
        priceTypeCode: priceTypeCode,
        warehouseCodes: warehouseCodes,
        searchQuery: searchQuery,
        codeProject: codeProject,
      );
    } catch (e) {
      print('Error fetching products with prices: $e');
      return [];
    }
  }

  /// Update client visit status
  Future<void> updateClientVisitStatus(String clientId, bool isVisited) async {
    // TODO: Send visit status to server
    // For now, just update local cache
    final clients = await _dataSyncService.getCachedClients();
    final updatedClients = clients.map((client) {
      if (client.id == clientId) {
        return client.copyWith(isVisited: isVisited);
      }
      return client;
    }).toList();

    await _dataSyncService.updateCachedClients(updatedClients);
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _dataSyncService.clearAllCachedData();
  }

  /// Sync all data from server
  Future<void> syncAllData({
    required String userCode,
    required String password,
    required String codeProject,
    required String codeSklad,
  }) async {
    await _dataSyncService.syncAllUserData(
      userCode: userCode,
      password: password,
      codeProject: codeProject,
      codeSklad: codeSklad,
    );
  }

  /// Get cached business regions
  Future<List<BusinessRegion>> getCachedBusinessRegions() async {
    return await _dataSyncService.getCachedBusinessRegions();
  }

  /// Sync business regions from server
  Future<List<BusinessRegion>> syncBusinessRegions({
    required String userCode,
    bool forceRefresh = false,
  }) async {
    return await _dataSyncService.syncBusinessRegions(
      userCode: userCode,
      forceRefresh: forceRefresh,
    );
  }

  /// Get cached user warehouses
  Future<List<UserWarehouse>> getCachedUserWarehouses() async {
    return await _dataSyncService.getCachedUserWarehouses();
  }

  /// Sync user warehouses from server
  Future<List<UserWarehouse>> syncUserWarehouses({
    required String userCode,
    bool forceRefresh = false,
  }) async {
    return await _dataSyncService.syncUserWarehouses(
      userCode: userCode,
      forceRefresh: forceRefresh,
    );
  }

  /// Save user data from shared preferences to database
  Future<void> savePrefsToUsers() async {
    try {
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();
      final dbHelper = DatabaseHelper();

      final userData = {
        'code': prefs.getUserCode() ?? '',
        'username': prefs.getSavedUsername() ?? '',
        'password': prefs.getPassword() ?? '',
        'name': prefs.getUserName() ?? '',
        'role': 'Agent',
        'warehouse_code': prefs.getWarehouseCode() ?? '',
        'code_project': prefs.getCodeProject() ?? '',
        'base_url': prefs.getBaseUrl() ?? '',
      };

      await dbHelper.saveUser(userData);
    } catch (e) {
      print('Error saving prefs to users: $e');
      rethrow;
    }
  }

  /// Get cached product balances
  Future<List<ProductBalance>> getCachedProductBalances({
    String? warehouseCode,
    String? productBrand,
    String? productSeries,
  }) async {
    return await _dataSyncService.getCachedProductBalances(
      warehouseCode: warehouseCode,
      productBrand: productBrand,
      productSeries: productSeries,
    );
  }

  /// Get cached product brands
  Future<List<ProductBrand>> getCachedProductBrands() async {
    return await _dataSyncService.getCachedProductBrands();
  }

  /// Get cached product series (categories)
  Future<List<ProductSeries>> getCachedProductSeries({String? brandName}) async {
    return await _dataSyncService.getCachedProductSeries(brandName: brandName);
  }
}