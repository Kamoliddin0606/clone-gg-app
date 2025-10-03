import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/kpi_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/price_type.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_price.dart';

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
      };

      await dbHelper.saveUser(userData);
    } catch (e) {
      print('Error saving prefs to users: $e');
      rethrow;
    }
  }
}