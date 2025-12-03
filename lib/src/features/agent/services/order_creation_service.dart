import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/location_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/create_order.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/visit_data_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/order_draft_service.dart';

/// Service for creating CreateOrder objects from visit step data and order drafts
/// This service centralizes the logic for building CreateOrder objects from various data sources
/// ensuring consistency and maintainability across the application
class OrderCreationService {
  final VisitDataRepository _visitDataRepository;
  final OrderDraftService _orderDraftService;
  final SharedPreferencesService _prefs;
  final LocationService _locationService;

  /// Constructor with dependency injection
  /// All dependencies are required for proper data mapping and validation
  OrderCreationService({
    required VisitDataRepository visitDataRepository,
    required OrderDraftService orderDraftService,
    required SharedPreferencesService prefs,
    required LocationService locationService,
  }) : _visitDataRepository = visitDataRepository,
       _orderDraftService = orderDraftService,
       _prefs = prefs,
       _locationService = locationService;

  /// Builds a CreateOrder object from visit step data and order draft data
  /// This method centralizes all the logic for creating orders from stored data
  ///
  /// Parameters:
  /// - visitId: Unique identifier for the visit session
  /// - stepCode: Code of the order creation step
  /// - tradingPoint: Trading point information containing client details
  ///
  /// Returns: A fully constructed CreateOrder object ready for server submission
  ///
  /// Throws: Exception if required data is missing or invalid
  Future<CreateOrder> buildCreateOrder({
    required String visitId,
    required int stepCode,
    required TradingPointWithPermissions tradingPoint,
  }) async {
    try {
      debugPrint('OrderCreationService: Building CreateOrder for visitId: $visitId, stepCode: $stepCode');

      // Step 1: Load visit step data (contains order creation data from UI)
      final visitData = await _loadVisitStepData(visitId, stepCode);
      if (visitData == null) {
        throw Exception('Visit step data not found for visitId: $visitId, stepCode: $stepCode');
      }

      // Step 2: Load order draft data (contains saved order state from create_order_page)
      final draftData = await _loadOrderDraftData(visitId, stepCode);

      // Step 3: Merge data sources (draft takes precedence over visit data)
      final mergedData = _mergeDataSources(visitData, draftData);

      // Step 4: Build CreateOrder object from merged data
      final order = await _buildCreateOrderFromData(mergedData, tradingPoint);

      debugPrint('OrderCreationService: Successfully built CreateOrder with ${order.products.length} products');
      return order;

    } catch (e, stackTrace) {
      debugPrint('OrderCreationService: Error building CreateOrder: $e');
      debugPrint('OrderCreationService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Loads visit step data from the repository
  /// This contains the data saved during the order creation step
  Future<Map<String, dynamic>?> _loadVisitStepData(String visitId, int stepCode) async {
    try {
      debugPrint('OrderCreationService: Loading visit step data for visitId: $visitId, stepCode: $stepCode');

      final stepData = await _visitDataRepository.getVisitStepDataByStep(visitId, stepCode);
      final completionData = stepData.where((d) => d.dataType == 'completion').toList();

      if (completionData.isEmpty) {
        debugPrint('OrderCreationService: No completion data found for step');
        return null;
      }

      final latestData = completionData.reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);
      final parsedData = jsonDecode(latestData.dataContent) as Map<String, dynamic>;

      debugPrint('OrderCreationService: Loaded visit step data with keys: ${parsedData.keys.toList()}');
      return parsedData;

    } catch (e, stackTrace) {
      debugPrint('OrderCreationService: Error loading visit step data: $e');
      debugPrint('OrderCreationService: Stack trace: $stackTrace');
      return null; // Return null to allow fallback to draft-only data
    }
  }

  /// Loads order draft data from the draft service
  /// This contains the detailed order information saved during editing
  Future<Map<String, dynamic>?> _loadOrderDraftData(String visitId, int stepCode) async {
    try {
      debugPrint('OrderCreationService: Loading order draft data for visitId: $visitId, stepCode: $stepCode');

      final draftData = await _orderDraftService.loadOrderDraft(visitId, stepCode);

      if (draftData != null) {
        debugPrint('OrderCreationService: Loaded order draft data with keys: ${draftData.keys.toList()}');
      } else {
        debugPrint('OrderCreationService: No order draft data found');
      }

      return draftData;

    } catch (e, stackTrace) {
      debugPrint('OrderCreationService: Error loading order draft data: $e');
      debugPrint('OrderCreationService: Stack trace: $stackTrace');
      return null; // Return null to allow fallback to visit data only
    }
  }

  /// Merges data from visit step and draft sources
  /// Draft data takes precedence as it contains the most recent user edits
  Map<String, dynamic> _mergeDataSources(Map<String, dynamic>? visitData, Map<String, dynamic>? draftData) {
    final merged = <String, dynamic>{};

    // Start with visit data as base
    if (visitData != null) {
      merged.addAll(visitData);
    }

    // Override with draft data (more detailed and recent)
    if (draftData != null) {
      merged.addAll(draftData);
    }

    debugPrint('OrderCreationService: Merged data contains keys: ${merged.keys.toList()}');
    return merged;
  }

  /// Builds CreateOrder object from merged data
  /// Handles all field mapping and external data fetching
  Future<CreateOrder> _buildCreateOrderFromData(
    Map<String, dynamic> data,
    TradingPointWithPermissions tradingPoint,
  ) async {
    try {
      debugPrint('OrderCreationService: Building CreateOrder from merged data');

      // Extract and validate external dependencies
      final codeAgent = await _getCodeAgent();
      final locationData = await _getLocationData();

      // Build products list
      final products = _buildProductsList(data['products']);

      // Calculate derived fields
      final totalWeight = products.fold(0.0, (sum, product) => sum + (product.weight * product.amount));
      final totalCapacity = products.fold(0.0, (sum, product) => sum + (product.capacity * product.amount));
      final hasPromo = products.any((product) => product.promo);
      final totalValue = products.fold(0.0, (sum, product) => sum + product.total);

      // Build competitive intelligence and credit details
      final competitiveIntelligence = _buildCompetitiveIntelligenceList(data['competitiveIntelligence']);
      final shippingDate = _parseDateTime(data['shippingDate']) ?? DateTime.now();
      final creditDetails = _buildCreditDetailsList(data['creditDetails'], totalValue, shippingDate);

      // Create CreateOrder object with all mapped fields
      final order = CreateOrder(
        codeAgent: codeAgent,
        codeClient: tradingPoint.tradingPoint.id,
        codePrice: data['selectedPriceTypecode'] ?? data['codePrice'] ?? '',
        payment: data['payment'] ?? '',
        shippingDate: shippingDate,
        commentSupervisor: data['commentSupervisor'],
        commentForwarder: data['commentForwarder'],
        comment: data['notes'] ?? data['comment'],
        createDate: _parseDateTime(data['createDate']) ?? DateTime.now(),
        longitude: locationData['longitude'] ?? data['longitude'] ?? 0.0,
        latitude: locationData['latitude'] ?? data['latitude'] ?? 0.0,
        weight: totalWeight,
        capacity: totalCapacity,
        credit: data['credit'] ?? false,
        codeProject: data['codeProject'] ?? await _getCodeProject(),
        orderType: (data['orderType'] as num?)?.toInt() ?? 0,
        codeOrg: data['selectedOrganizationcode'] ?? data['codeOrg'] ?? '',
        codeSklad: data['selectedWarehousecode'] ?? data['codeSklad'] ?? '',
        codeContract: data['codeContract'],
        hasPromo: hasPromo,
        products: products,
        competitiveIntelligence: competitiveIntelligence,
        creditDetails: creditDetails,
      );

      debugPrint('OrderCreationService: Created CreateOrder with ${products.length} products, weight: $totalWeight, capacity: $totalCapacity');
      return order;

    } catch (e, stackTrace) {
      debugPrint('OrderCreationService: Error building CreateOrder from data: $e');
      debugPrint('OrderCreationService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Gets the agent code from shared preferences
  Future<String> _getCodeAgent() async {
    try {
      final codeAgent = _prefs.getUserCode();
      if (codeAgent == null || codeAgent.isEmpty) {
        throw Exception('Agent code not found in preferences');
      }
      return codeAgent;
    } catch (e) {
      debugPrint('OrderCreationService: Error getting agent code: $e');
      throw Exception('Failed to get agent code: $e');
    }
  }

  /// Gets the project code from shared preferences
  Future<String> _getCodeProject() async {
    try {
      final codeProject = _prefs.getCodeProject();
      return codeProject ?? '';
    } catch (e) {
      debugPrint('OrderCreationService: Error getting project code: $e');
      return ''; // Return empty string as fallback
    }
  }

  /// Gets location data from location service
  Future<Map<String, double>> _getLocationData() async {
    try {
      final locationData = _locationService.getStoredLocation();
      if (locationData != null) {
        return {
          'longitude': (locationData['longitude'] as num?)?.toDouble() ?? 0.0,
          'latitude': (locationData['latitude'] as num?)?.toDouble() ?? 0.0,
        };
      }
      return {'longitude': 0.0, 'latitude': 0.0};
    } catch (e) {
      debugPrint('OrderCreationService: Error getting location data: $e');
      return {'longitude': 0.0, 'latitude': 0.0};
    }
  }

  /// Builds products list from data
  List<CreateOrderProduct> _buildProductsList(dynamic productsData) {
    if (productsData == null) return [];

    try {
      final products = <CreateOrderProduct>[];
      final productsList = productsData as List<dynamic>;

      for (final productData in productsList) {
        if (productData is Map<String, dynamic>) {
          products.add(CreateOrderProduct.fromJson(productData));
        }
      }

      debugPrint('OrderCreationService: Built ${products.length} products from data');
      return products;

    } catch (e) {
      debugPrint('OrderCreationService: Error building products list: $e');
      return [];
    }
  }

  /// Builds competitive intelligence list from data
  List<CompetitiveIntelligence> _buildCompetitiveIntelligenceList(dynamic ciData) {
    if (ciData == null) return [];

    try {
      final ciList = <CompetitiveIntelligence>[];
      final ciListData = ciData as List<dynamic>;

      for (final ci in ciListData) {
        if (ci is Map<String, dynamic>) {
          ciList.add(CompetitiveIntelligence.fromJson(ci));
        }
      }

      return ciList;

    } catch (e) {
      debugPrint('OrderCreationService: Error building competitive intelligence list: $e');
      return [];
    }
  }

  /// Builds credit details list from data
  /// If no credit details exist, creates a default one with order total and shipping date
  List<CreditDetail> _buildCreditDetailsList(dynamic creditData, double totalValue, DateTime shippingDate) {
    try {
      final creditList = <CreditDetail>[];

      // Try to build from existing data
      if (creditData != null) {
        final creditListData = creditData as List<dynamic>;

        for (final credit in creditListData) {
          if (credit is Map<String, dynamic>) {
            creditList.add(CreditDetail.fromJson(credit));
          }
        }
      }

      // If no credit details exist, create a default one with order total and shipping date
      if (creditList.isEmpty) {
        creditList.add(CreditDetail(
          dateOfPayment: shippingDate,
          total: totalValue,
        ));
        debugPrint('OrderCreationService: Created default credit detail with total: $totalValue, date: $shippingDate');
      }

      return creditList;

    } catch (e) {
      debugPrint('OrderCreationService: Error building credit details list: $e');
      // Return default credit detail on error
      return [CreditDetail(
        dateOfPayment: shippingDate,
        total: totalValue,
      )];
    }
  }

  /// Parses DateTime from various string formats
  DateTime? _parseDateTime(dynamic dateData) {
    if (dateData == null) return null;

    try {
      if (dateData is String) {
        return DateTime.parse(dateData);
      } else if (dateData is DateTime) {
        return dateData;
      }
      return null;
    } catch (e) {
      debugPrint('OrderCreationService: Error parsing date: $e');
      return null;
    }
  }
}