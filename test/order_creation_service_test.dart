import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/location_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/order_creation_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/create_order.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/visit_data_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/order_draft_service.dart';

// Mock classes
class MockVisitDataRepository extends Mock implements VisitDataRepository {}
class MockOrderDraftService extends Mock implements OrderDraftService {}
class MockSharedPreferencesService extends Mock implements SharedPreferencesService {}
class MockLocationService extends Mock implements LocationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OrderCreationService orderCreationService;
  late MockVisitDataRepository mockVisitDataRepository;
  late MockOrderDraftService mockOrderDraftService;
  late MockSharedPreferencesService mockPrefs;
  late MockLocationService mockLocationService;

  setUp(() {
    mockVisitDataRepository = MockVisitDataRepository();
    mockOrderDraftService = MockOrderDraftService();
    mockPrefs = MockSharedPreferencesService();
    mockLocationService = MockLocationService();

    orderCreationService = OrderCreationService(
      visitDataRepository: mockVisitDataRepository,
      orderDraftService: mockOrderDraftService,
      prefs: mockPrefs,
      locationService: mockLocationService,
    );
  });

  group('OrderCreationService - Core Functionality', () {
    test('should create OrderCreationService instance', () {
      expect(orderCreationService, isNotNull);
    });

    test('should build CreateOrder successfully with visit data only', () async {
      // Mock visit step data
      final visitData = VisitData(
        visitId: 'VISIT001',
        clientCode: 'CLIENT001',
        stepCode: 1,
        stepName: 'Create Order',
        dataType: 'completion',
        dataContent: jsonEncode({
          'selectedOrganizationcode': 'ORG001',
          'selectedWarehousecode': 'WH001',
          'selectedPriceTypecode': 'PRICE001',
          'shippingDate': DateTime.now().toIso8601String(),
          'products': [
            {
              'codeSklad': 'SKL001',
              'codeProduct': 'PRD001',
              'vendorCode': 'VC001',
              'amount': 5,
              'price': 10000.0,
              'total': 50000.0,
              'weight': 1.0,
              'capacity': 0.5,
              'paymentType': 0,
              'discountSum': 0.0,
              'discountRate': 0.0,
              'giftAmount': 0,
              'promo': false,
            }
          ],
          'notes': 'Test order',
        }),
        timestamp: DateTime.now(),
      );

      when(mockVisitDataRepository.getVisitStepDataByStep('VISIT001', 1))
          .thenAnswer((_) async => [visitData]);

      when(mockOrderDraftService.loadOrderDraft('VISIT001', 1))
          .thenAnswer((_) async => null);

      when(mockPrefs.getUserCode()).thenReturn('USER001');
      when(mockPrefs.getCodeProject()).thenReturn('PROJ001');

      when(mockLocationService.getStoredLocation())
          .thenReturn({'longitude': 69.2401, 'latitude': 41.2995});

      final tradingPoint = TradingPointWithPermissions(
        tradingPoint: TradingPoint(
          id: 'CLIENT001',
          name: 'Test Client',
          address: 'Test Address',
          latitude: 41.2995,
          longitude: 69.2401,
          tradePointType: 'retail',
          region: 'Tashkent',
          district: 'Yunusabad',
        ),
        permissions: SalesReqPermissions(
          userCode: 'USER001',
          visitSteps: [],
        ),
      );

      final result = await orderCreationService.buildCreateOrder(
        visitId: 'VISIT001',
        stepCode: 1,
        tradingPoint: tradingPoint,
      );

      expect(result, isA<CreateOrder>());
      expect(result.codeAgent, 'USER001');
      expect(result.codeClient, 'CLIENT001');
      expect(result.products.length, 1);
      expect(result.products.first.amount, 5);
      expect(result.weight, 5.0); // 5 products * 1.0 weight each
      expect(result.capacity, 2.5); // 5 products * 0.5 capacity each
      expect(result.hasPromo, false);
    });

    test('should build CreateOrder successfully with draft data only', () async {
      // Mock no visit data
      when(mockVisitDataRepository.getVisitStepDataByStep('VISIT001', 1))
          .thenAnswer((_) async => []);

      // Mock draft data
      final draftData = {
        'selectedOrganizationcode': 'ORG001',
        'selectedWarehousecode': 'WH001',
        'selectedPriceTypecode': 'PRICE001',
        'shippingDate': DateTime.now().toIso8601String(),
        'products': [
          {
            'codeSklad': 'SKL001',
            'codeProduct': 'PRD001',
            'vendorCode': 'VC001',
            'amount': 3,
            'price': 15000.0,
            'total': 45000.0,
            'weight': 2.0,
            'capacity': 1.0,
            'paymentType': 0,
            'discountSum': 0.0,
            'discountRate': 0.0,
            'giftAmount': 0,
            'promo': true,
          }
        ],
        'notes': 'Draft order',
      };

      when(mockOrderDraftService.loadOrderDraft('VISIT001', 1))
          .thenAnswer((_) async => draftData);

      when(mockPrefs.getUserCode()).thenReturn('USER001');
      when(mockPrefs.getCodeProject()).thenReturn('PROJ001');

      when(mockLocationService.getStoredLocation())
          .thenReturn({'longitude': 69.2401, 'latitude': 41.2995});

      final tradingPoint = TradingPointWithPermissions(
        tradingPoint: TradingPoint(
          id: 'CLIENT001',
          name: 'Test Client',
          address: 'Test Address',
          latitude: 41.2995,
          longitude: 69.2401,
          tradePointType: 'retail',
          region: 'Tashkent',
          district: 'Yunusabad',
        ),
        permissions: SalesReqPermissions(
          userCode: 'USER001',
          visitSteps: [],
        ),
      );

      final result = await orderCreationService.buildCreateOrder(
        visitId: 'VISIT001',
        stepCode: 1,
        tradingPoint: tradingPoint,
      );

      expect(result, isA<CreateOrder>());
      expect(result.products.length, 1);
      expect(result.products.first.amount, 3);
      expect(result.weight, 6.0); // 3 products * 2.0 weight each
      expect(result.capacity, 3.0); // 3 products * 1.0 capacity each
      expect(result.hasPromo, true);
    });

    test('should merge visit and draft data with draft taking precedence', () async {
      // Mock visit data
      final visitData = VisitData(
        visitId: 'VISIT001',
        clientCode: 'CLIENT001',
        stepCode: 1,
        stepName: 'Create Order',
        dataType: 'completion',
        dataContent: jsonEncode({
          'selectedOrganizationcode': 'ORG001',
          'selectedWarehousecode': 'WH001',
          'selectedPriceTypecode': 'PRICE001',
          'shippingDate': DateTime.now().toIso8601String(),
          'products': [
            {
              'codeSklad': 'SKL001',
              'codeProduct': 'PRD001',
              'vendorCode': 'VC001',
              'amount': 2,
              'price': 10000.0,
              'total': 20000.0,
              'weight': 1.0,
              'capacity': 0.5,
              'paymentType': 0,
              'discountSum': 0.0,
              'discountRate': 0.0,
              'giftAmount': 0,
              'promo': false,
            }
          ],
          'notes': 'Visit notes',
        }),
        timestamp: DateTime.now(),
      );

      when(mockVisitDataRepository.getVisitStepDataByStep('VISIT001', 1))
          .thenAnswer((_) async => [visitData]);

      // Mock draft data (should override visit data)
      final draftData = {
        'selectedOrganizationcode': 'ORG002', // Different from visit
        'selectedWarehousecode': 'WH002', // Different from visit
        'selectedPriceTypecode': 'PRICE002', // Different from visit
        'products': [
          {
            'codeSklad': 'SKL001',
            'codeProduct': 'PRD001',
            'vendorCode': 'VC001',
            'amount': 5, // Different amount
            'price': 10000.0,
            'total': 50000.0,
            'weight': 1.0,
            'capacity': 0.5,
            'paymentType': 0,
            'discountSum': 0.0,
            'discountRate': 0.0,
            'giftAmount': 0,
            'promo': false,
          }
        ],
        'notes': 'Draft notes', // Should override visit notes
      };

      when(mockOrderDraftService.loadOrderDraft('VISIT001', 1))
          .thenAnswer((_) async => draftData);

      when(mockPrefs.getUserCode()).thenReturn('USER001');
      when(mockPrefs.getCodeProject()).thenReturn('PROJ001');

      when(mockLocationService.getStoredLocation())
          .thenReturn({'longitude': 69.2401, 'latitude': 41.2995});

      final tradingPoint = TradingPointWithPermissions(
        tradingPoint: TradingPoint(
          id: 'CLIENT001',
          name: 'Test Client',
          address: 'Test Address',
          latitude: 41.2995,
          longitude: 69.2401,
          tradePointType: 'retail',
          region: 'Tashkent',
          district: 'Yunusabad',
        ),
        permissions: SalesReqPermissions(
          userCode: 'USER001',
          visitSteps: [],
        ),
      );

      final result = await orderCreationService.buildCreateOrder(
        visitId: 'VISIT001',
        stepCode: 1,
        tradingPoint: tradingPoint,
      );

      expect(result, isA<CreateOrder>());
      expect(result.codeOrg, 'ORG002'); // From draft
      expect(result.codeSklad, 'WH002'); // From draft
      expect(result.codePrice, 'PRICE002'); // From draft
      expect(result.comment, 'Draft notes'); // From draft
      expect(result.products.first.amount, 5); // From draft
    });

    test('should handle missing visit data gracefully', () async {
      when(mockVisitDataRepository.getVisitStepDataByStep('VISIT001', 1))
          .thenAnswer((_) async => []);

      when(mockOrderDraftService.loadOrderDraft('VISIT001', 1))
          .thenAnswer((_) async => null);

      final tradingPoint = TradingPointWithPermissions(
        tradingPoint: TradingPoint(
          id: 'CLIENT001',
          name: 'Test Client',
          address: 'Test Address',
          latitude: 41.2995,
          longitude: 69.2401,
          tradePointType: 'retail',
          region: 'Tashkent',
          district: 'Yunusabad',
        ),
        permissions: SalesReqPermissions(
          userCode: 'USER001',
          skipTINduplicateCheck: false,
          allowCreationWithoutTIN: false,
          allowCreatingPointOfSale: false,
          visit: true,
          strictSequence: false,
          unplannedOrder: false,
          plannedRoute: false,
          editClientCoordinates: false,
          visitSteps: [],
        ),
      );

      expect(
        () => orderCreationService.buildCreateOrder(
          visitId: 'VISIT001',
          stepCode: 1,
          tradingPoint: tradingPoint,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle missing agent code', () async {
      final visitData = VisitData(
        visitId: 'VISIT001',
        clientCode: 'CLIENT001',
        stepCode: 1,
        stepName: 'Create Order',
        dataType: 'completion',
        dataContent: jsonEncode({
          'selectedOrganizationcode': 'ORG001',
          'selectedWarehousecode': 'WH001',
          'selectedPriceTypecode': 'PRICE001',
          'products': [],
        }),
        timestamp: DateTime.now(),
      );

      when(mockVisitDataRepository.getVisitStepDataByStep('VISIT001', 1))
          .thenAnswer((_) async => [visitData]);

      when(mockOrderDraftService.loadOrderDraft('VISIT001', 1))
          .thenAnswer((_) async => null);

      when(mockPrefs.getUserCode()).thenReturn(null); // Missing agent code

      final tradingPoint = TradingPointWithPermissions(
        tradingPoint: TradingPoint(
          id: 'CLIENT001',
          name: 'Test Client',
          address: 'Test Address',
          latitude: 41.2995,
          longitude: 69.2401,
          tradePointType: 'retail',
          region: 'Tashkent',
          district: 'Yunusabad',
        ),
        permissions: SalesReqPermissions(
          userCode: 'USER001',
          visitSteps: [],
        ),
      );

      expect(
        () => orderCreationService.buildCreateOrder(
          visitId: 'VISIT001',
          stepCode: 1,
          tradingPoint: tradingPoint,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle location service errors gracefully', () async {
      final visitData = VisitData(
        visitId: 'VISIT001',
        clientCode: 'CLIENT001',
        stepCode: 1,
        stepName: 'Create Order',
        dataType: 'completion',
        dataContent: jsonEncode({
          'selectedOrganizationcode': 'ORG001',
          'selectedWarehousecode': 'WH001',
          'selectedPriceTypecode': 'PRICE001',
          'products': [
            {
              'codeSklad': 'SKL001',
              'codeProduct': 'PRD001',
              'vendorCode': 'VC001',
              'amount': 1,
              'price': 10000.0,
              'total': 10000.0,
              'weight': 1.0,
              'capacity': 0.5,
              'paymentType': 0,
              'discountSum': 0.0,
              'discountRate': 0.0,
              'giftAmount': 0,
              'promo': false,
            }
          ],
        }),
        timestamp: DateTime.now(),
      );

      when(mockVisitDataRepository.getVisitStepDataByStep('VISIT001', 1))
          .thenAnswer((_) async => [visitData]);

      when(mockOrderDraftService.loadOrderDraft('VISIT001', 1))
          .thenAnswer((_) async => null);

      when(mockPrefs.getUserCode()).thenReturn('USER001');
      when(mockPrefs.getCodeProject()).thenReturn('PROJ001');

      when(mockLocationService.getStoredLocation())
          .thenThrow(Exception('Location service error'));

      final tradingPoint = TradingPointWithPermissions(
        tradingPoint: TradingPoint(
          id: 'CLIENT001',
          name: 'Test Client',
          address: 'Test Address',
          latitude: 41.2995,
          longitude: 69.2401,
          tradePointType: 'retail',
          region: 'Tashkent',
          district: 'Yunusabad',
        ),
        permissions: SalesReqPermissions(
          userCode: 'USER001',
          visitSteps: [],
        ),
      );

      final result = await orderCreationService.buildCreateOrder(
        visitId: 'VISIT001',
        stepCode: 1,
        tradingPoint: tradingPoint,
      );

      expect(result, isA<CreateOrder>());
      expect(result.longitude, 0.0); // Default value
      expect(result.latitude, 0.0); // Default value
    });

    test('should handle invalid JSON in visit data', () async {
      final visitData = VisitData(
        visitId: 'VISIT001',
        clientCode: 'CLIENT001',
        stepCode: 1,
        stepName: 'Create Order',
        dataType: 'completion',
        dataContent: 'invalid json',
        timestamp: DateTime.now(),
      );

      when(mockVisitDataRepository.getVisitStepDataByStep('VISIT001', 1))
          .thenAnswer((_) async => [visitData]);

      when(mockOrderDraftService.loadOrderDraft('VISIT001', 1))
          .thenAnswer((_) async => null);

      final tradingPoint = TradingPointWithPermissions(
        tradingPoint: TradingPoint(
          id: 'CLIENT001',
          name: 'Test Client',
          address: 'Test Address',
          latitude: 41.2995,
          longitude: 69.2401,
          tradePointType: 'retail',
          region: 'Tashkent',
          district: 'Yunusabad',
        ),
        permissions: SalesReqPermissions(
          userCode: 'USER001',
          visitSteps: [],
        ),
      );

      expect(
        () => orderCreationService.buildCreateOrder(
          visitId: 'VISIT001',
          stepCode: 1,
          tradingPoint: tradingPoint,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle empty products list', () async {
      final visitData = VisitData(
        visitId: 'VISIT001',
        clientCode: 'CLIENT001',
        stepCode: 1,
        stepName: 'Create Order',
        dataType: 'completion',
        dataContent: jsonEncode({
          'selectedOrganizationcode': 'ORG001',
          'selectedWarehousecode': 'WH001',
          'selectedPriceTypecode': 'PRICE001',
          'products': [],
        }),
        timestamp: DateTime.now(),
      );

      when(mockVisitDataRepository.getVisitStepDataByStep('VISIT001', 1))
          .thenAnswer((_) async => [visitData]);

      when(mockOrderDraftService.loadOrderDraft('VISIT001', 1))
          .thenAnswer((_) async => null);

      when(mockPrefs.getUserCode()).thenReturn('USER001');
      when(mockPrefs.getCodeProject()).thenReturn('PROJ001');

      when(mockLocationService.getStoredLocation())
          .thenReturn({'longitude': 69.2401, 'latitude': 41.2995});

      final tradingPoint = TradingPointWithPermissions(
        tradingPoint: TradingPoint(
          id: 'CLIENT001',
          name: 'Test Client',
          address: 'Test Address',
          latitude: 41.2995,
          longitude: 69.2401,
          tradePointType: 'retail',
          region: 'Tashkent',
          district: 'Yunusabad',
        ),
        permissions: SalesReqPermissions(
          userCode: 'USER001',
          visitSteps: [],
        ),
      );

      final result = await orderCreationService.buildCreateOrder(
        visitId: 'VISIT001',
        stepCode: 1,
        tradingPoint: tradingPoint,
      );

      expect(result, isA<CreateOrder>());
      expect(result.products, isEmpty);
      expect(result.weight, 0.0);
      expect(result.capacity, 0.0);
      expect(result.hasPromo, false);
    });

    test('should calculate correct totals for multiple products', () async {
      final visitData = VisitData(
        visitId: 'VISIT001',
        clientCode: 'CLIENT001',
        stepCode: 1,
        stepName: 'Create Order',
        dataType: 'completion',
        dataContent: jsonEncode({
          'selectedOrganizationcode': 'ORG001',
          'selectedWarehousecode': 'WH001',
          'selectedPriceTypecode': 'PRICE001',
          'products': [
            {
              'codeSklad': 'SKL001',
              'codeProduct': 'PRD001',
              'vendorCode': 'VC001',
              'amount': 2,
              'price': 10000.0,
              'total': 20000.0,
              'weight': 1.5,
              'capacity': 0.8,
              'paymentType': 0,
              'discountSum': 0.0,
              'discountRate': 0.0,
              'giftAmount': 0,
              'promo': false,
            },
            {
              'codeSklad': 'SKL001',
              'codeProduct': 'PRD002',
              'vendorCode': 'VC002',
              'amount': 3,
              'price': 15000.0,
              'total': 45000.0,
              'weight': 2.0,
              'capacity': 1.2,
              'paymentType': 0,
              'discountSum': 0.0,
              'discountRate': 0.0,
              'giftAmount': 0,
              'promo': true,
            }
          ],
        }),
        timestamp: DateTime.now(),
      );

      when(mockVisitDataRepository.getVisitStepDataByStep('VISIT001', 1))
          .thenAnswer((_) async => [visitData]);

      when(mockOrderDraftService.loadOrderDraft('VISIT001', 1))
          .thenAnswer((_) async => null);

      when(mockPrefs.getUserCode()).thenReturn('USER001');
      when(mockPrefs.getCodeProject()).thenReturn('PROJ001');

      when(mockLocationService.getStoredLocation())
          .thenReturn({'longitude': 69.2401, 'latitude': 41.2995});

      final tradingPoint = TradingPointWithPermissions(
        tradingPoint: TradingPoint(
          id: 'CLIENT001',
          name: 'Test Client',
          address: 'Test Address',
          latitude: 41.2995,
          longitude: 69.2401,
          tradePointType: 'retail',
          region: 'Tashkent',
          district: 'Yunusabad',
        ),
        permissions: SalesReqPermissions(
          userCode: 'USER001',
          visitSteps: [],
        ),
      );

      final result = await orderCreationService.buildCreateOrder(
        visitId: 'VISIT001',
        stepCode: 1,
        tradingPoint: tradingPoint,
      );

      expect(result, isA<CreateOrder>());
      expect(result.products.length, 2);
      expect(result.weight, 9.0); // (2*1.5) + (3*2.0)
      expect(result.capacity, 5.2); // (2*0.8) + (3*1.2)
      expect(result.hasPromo, true); // One product has promo
    });
  });
}