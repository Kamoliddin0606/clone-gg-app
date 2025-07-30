import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/kpi_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/price_type.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_price.dart';

class AgentRepository {
  final SoapApiService _apiService;
  final ApiDatabaseService _databaseService;

  AgentRepository({
    required SoapApiService apiService,
    required ApiDatabaseService databaseService,
  }) : _apiService = apiService,
       _databaseService = databaseService;

  /// Get KPI data from server and cache locally
  Future<KpiData> getKpiData({
    required String userCode,
    required String password,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        // Try to get cached data first
        final cachedData = await _databaseService.getKpiData(userCode);
        print( 'Cached KPI data: $cachedData');
        if (cachedData != null) {
          // Check if data is not too old (less than 1 hour)
          final updateTime = DateTime.parse(cachedData.updateDate);
          final now = DateTime.now();
          if (now.difference(updateTime).inHours < 1) {
            return cachedData;
          }
        }
      }

      // Fetch fresh data from server
      final kpiData = await _apiService.getKpiData(
        userCode: userCode,
        password: password,
      );
      print('Fetched KPI data: $kpiData');
      // Cache the data
      await _databaseService.saveKpiData(userCode, kpiData);
      
      return kpiData;
    } catch (e) {
      // If API fails, try to return cached data
      print('Error fetching KPI data: $e');
      final cachedData = await _databaseService.getKpiData(userCode);
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
      if (!forceRefresh) {
        // Try to get cached data first
        final cachedData = await _databaseService.getClients();
        if (cachedData.isNotEmpty) {
          return cachedData;
        }
      }

      // Fetch fresh data from server
      final clients = await _apiService.getClients(
        userCode: userCode,
        password: password,
      );
      
      // Cache the data
      await _databaseService.saveClients(clients);
      
      return clients;
    } catch (e) {
      // If API fails, try to return cached data
      final cachedData = await _databaseService.getClients();
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
      if (!forceRefresh) {
        // Try to get cached data first
        final cachedData = await _databaseService.getProducts();
        if (cachedData.isNotEmpty) {
          return cachedData;
        }
      }

      // Fetch fresh data from server
      final products = await _apiService.getProducts(
        codeProject: codeProject,
        codeSklad: codeSklad,
      );
      
      // Cache the data
      await _databaseService.saveProducts(products);
      
      return products;
    } catch (e) {
      // If API fails, try to return cached data
      final cachedData = await _databaseService.getProducts();
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
      if (!forceRefresh) {
        // Try to get cached data first
        final cachedData = await _databaseService.getPriceTypes();
        if (cachedData.isNotEmpty) {
          return cachedData;
        }
      }

      // Fetch fresh data from server
      final priceTypes = await _apiService.getPriceTypes(
        userCode: userCode,
      );
      
      // Cache the data
      await _databaseService.savePriceTypes(priceTypes);
      
      return priceTypes;
    } catch (e) {
      // If API fails, try to return cached data
      final cachedData = await _databaseService.getPriceTypes();
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
      if (!forceRefresh) {
        // Try to get cached data first
        final cachedData = await _databaseService.getProductPrices(priceTypeCode: priceTypeCode);
        if (cachedData.isNotEmpty) {
          return cachedData;
        }
      }

      // Fetch fresh data from server
      final productPrices = await _apiService.getProductPrices(
        userCode: userCode,
      );
      
      // Cache the data
      await _databaseService.saveProductPrices(productPrices);
      
      return productPrices;
    } catch (e) {
      // If API fails, try to return cached data
      final cachedData = await _databaseService.getProductPrices(priceTypeCode: priceTypeCode);
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
    final clients = await _databaseService.getClients();
    final updatedClients = clients.map((client) {
      if (client.id == clientId) {
        return client.copyWith(isVisited: isVisited);
      }
      return client;
    }).toList();
    
    await _databaseService.saveClients(updatedClients);
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _databaseService.clearAllData();
  }

  /// Sync all data from server
  Future<void> syncAllData({
    required String userCode,
    required String password,
    required String codeProject,
    required String codeSklad,
  }) async {
    try {
      // Sync KPI data
      await getKpiData(
        userCode: userCode,
        password: password,
        forceRefresh: true,
      );

      // Sync clients
      await getClients(
        userCode: userCode,
        password: password,
        forceRefresh: true,
      );

      // Sync products
      await getProducts(
        codeProject: codeProject,
        codeSklad: codeSklad,
        forceRefresh: true,
      );

      // Sync price types
      await getPriceTypes(
        userCode: userCode,
        forceRefresh: true,
      );

      // Sync product prices
      await getProductPrices(
        userCode: userCode,
        forceRefresh: true,
      );
    } catch (e) {
      throw Exception('Failed to sync data: $e');
    }
  }
}