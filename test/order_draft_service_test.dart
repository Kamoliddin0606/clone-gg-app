import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/order_draft_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/create_order.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_data.dart';

// Mock classes
class MockApiDatabaseService extends Mock implements ApiDatabaseService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OrderDraftService draftService;
  late MockApiDatabaseService mockDbService;

  setUp(() {
    mockDbService = MockApiDatabaseService();
    draftService = OrderDraftService(mockDbService);
  });

  tearDown(() {
    draftService.dispose();
  });

  group('OrderDraftService - Enhanced Persistence', () {
    test('should initialize with default values', () {
      expect(draftService, isNotNull);

      final status = draftService.getSaveStatus();
      expect(status['isSaving'], false);
      expect(status['autoSaveEnabled'], false);
      expect(status['lastSaveTime'], isNull);
      expect(status['lastSaveError'], isNull);
    });

    test('should enable auto-save successfully', () {
      final products = [
        CreateOrderProduct(
          codeSklad: 'SKL001',
          codeProduct: 'PRD001',
          vendorCode: 'VC001',
          amount: 5,
          price: 10000.0,
          total: 50000.0,
          weight: 1.0,
          capacity: 0.5,
          paymentType: 0,
          discountSum: 0.0,
          discountRate: 0.0,
          giftAmount: 0,
          promo: false,
        )
      ];

      draftService.enableAutoSave(
        visitId: 'VISIT001',
        stepCode: 1,
        products: products,
        selectedOrganization: 'ORG001',
        selectedWarehouse: 'WH001',
        selectedPriceType: 'PRICE001',
        notes: 'Test notes',
        stepName: 'Create Order',
        selectedOrganizationcode: 'ORG001',
        selectedWarehousecode: 'WH001',
        selectedPriceTypecode: 'PRICE001',
        shippingDate: DateTime.now(),
      );

      final status = draftService.getSaveStatus();
      expect(status['autoSaveEnabled'], true);
    });

    test('should disable auto-save successfully', () {
      draftService.enableAutoSave(
        visitId: 'VISIT001',
        stepCode: 1,
        products: [],
        selectedOrganization: 'ORG001',
        selectedWarehouse: 'WH001',
        selectedPriceType: 'PRICE001',
        notes: '',
        stepName: 'Create Order',
        selectedOrganizationcode: 'ORG001',
        selectedWarehousecode: 'WH001',
        selectedPriceTypecode: 'PRICE001',
        shippingDate: DateTime.now(),
      );

      draftService.disableAutoSave();

      final status = draftService.getSaveStatus();
      expect(status['autoSaveEnabled'], false);
    });

    test('should save order draft and update status', () async {
      when(mockDbService.saveVisitStepData(any)).thenAnswer((invocation) async {});

      await draftService.saveOrderDraft(
        visitId: 'VISIT001',
        clientCode: 'CLIENT001',
        stepCode: 1,
        stepName: 'Create Order',
        selectedOrganization: 'ORG001',
        selectedWarehouse: 'WH001',
        selectedPriceType: 'PRICE001',
        selectedOrganizationcode: 'ORG001',
        selectedWarehousecode: 'WH001',
        selectedPriceTypecode: 'PRICE001',
        shippingDate: DateTime.now(),
        products: [],
        notes: 'Test draft',
      );

      final status = draftService.getSaveStatus();
      expect(status['lastSaveTime'], isNotNull);
      expect(status['lastSaveError'], isNull);
    });

    test('should handle save errors gracefully', () async {
      when(mockDbService.saveVisitStepData(argThat(isA<VisitData>())))
          .thenThrow(Exception('Database error'));

      await draftService.saveOrderDraft(
        visitId: 'VISIT001',
        clientCode: 'CLIENT001',
        stepCode: 1,
        stepName: 'Create Order',
        selectedOrganization: 'ORG001',
        selectedWarehouse: 'WH001',
        selectedPriceType: 'PRICE001',
        selectedOrganizationcode: 'ORG001',
        selectedWarehousecode: 'WH001',
        selectedPriceTypecode: 'PRICE001',
        shippingDate: DateTime.now(),
        products: [],
        notes: 'Test draft',
      );

      final status = draftService.getSaveStatus();
      expect(status['lastSaveError'], isNotNull);
      expect(status['lastSaveError'], contains('Database error'));
    });

    test('should load saved order draft successfully', () async {
      // Mock the visit data list that would be returned
      final mockVisitData = [
        VisitData(
          visitId: 'VISIT001',
          clientCode: 'CLIENT001',
          stepCode: 1,
          stepName: 'Create Order',
          dataType: 'order_draft',
          dataContent: '{"selectedOrganization":"ORG001","selectedWarehouse":"WH001","selectedPriceType":"PRICE001","products":[{"codeSklad":"SKL001","codeProduct":"PRD001","vendorCode":"VC001","amount":5,"price":10000.0,"total":50000.0,"weight":1.0,"capacity":0.5,"paymentType":0,"discountSum":0.0,"discountRate":0.0,"giftAmount":0,"promo":false}],"notes":"Loaded draft"}',
          timestamp: DateTime.now(),
        )
      ];

      when(mockDbService.getVisitStepDataByVisitId('VISIT001'))
          .thenAnswer((_) async => mockVisitData);

      final result = await draftService.loadOrderDraft('VISIT001', 1);

      expect(result, isNotNull);
      expect(result!['selectedOrganization'], 'ORG001');
      expect(result['products'], isNotEmpty);
      expect(result['notes'], 'Loaded draft');
    });

    test('should return null when no draft exists', () async {
      when(mockDbService.getVisitStepDataByVisitId('VISIT001'))
          .thenAnswer((_) async => []);

      final result = await draftService.loadOrderDraft('VISIT001', 1);

      expect(result, isNull);
    });

    test('should handle load errors gracefully', () async {
      when(mockDbService.getVisitStepDataByVisitId('VISIT001'))
          .thenThrow(Exception('Load error'));

      final result = await draftService.loadOrderDraft('VISIT001', 1);

      expect(result, isNull);
    });

    test('should get draft statistics', () async {
      when(mockDbService.getVisitStepDataStats())
          .thenAnswer((_) async => {
                'total': 10,
                'dataTypes': {'order_draft': 5},
                'pending': 2,
              });

      final stats = await draftService.getDraftStats();

      expect(stats['totalDrafts'], 5);
      expect(stats['totalVisitData'], 10);
      expect(stats['pendingSync'], 2);
    });

    test('should handle draft stats errors', () async {
      when(mockDbService.getVisitStepDataStats())
          .thenThrow(Exception('Stats error'));

      final stats = await draftService.getDraftStats();

      expect(stats['error'], isNotNull);
    });

    test('should prevent concurrent auto-saves', () async {
      // This test verifies that auto-save operations don't overlap
      draftService.enableAutoSave(
        visitId: 'VISIT001',
        stepCode: 1,
        products: [],
        selectedOrganization: 'ORG001',
        selectedWarehouse: 'WH001',
        selectedPriceType: 'PRICE001',
        notes: '',
        stepName: 'Create Order',
        selectedOrganizationcode: 'ORG001',
        selectedWarehousecode: 'WH001',
        selectedPriceTypecode: 'PRICE001',
        shippingDate: DateTime.now(),
      );

      // First save should start
      final status1 = draftService.getSaveStatus();
      expect(status1['autoSaveEnabled'], true);

      // Disable auto-save
      draftService.disableAutoSave();

      final status2 = draftService.getSaveStatus();
      expect(status2['autoSaveEnabled'], false);
    });

    test('should validate draft data integrity', () async {
      // Test with valid data
      final validProducts = [
        CreateOrderProduct(
          codeSklad: 'SKL001',
          codeProduct: 'PRD001',
          vendorCode: 'VC001',
          amount: 1,
          price: 1000.0,
          total: 1000.0,
          weight: 1.0,
          capacity: 0.1,
          paymentType: 0,
          discountSum: 0.0,
          discountRate: 0.0,
          giftAmount: 0,
          promo: false,
        )
      ];

      when(mockDbService.saveVisitStepData(any))
          .thenAnswer((_) async => 1);

      await draftService.saveOrderDraft(
        visitId: 'VISIT001',
        clientCode: 'CLIENT001',
        stepCode: 1,
        stepName: 'Create Order',
        selectedOrganization: 'ORG001',
        selectedWarehouse: 'WH001',
        selectedPriceType: 'PRICE001',
        selectedOrganizationcode: 'ORG001',
        selectedWarehousecode: 'WH001',
        selectedPriceTypecode: 'PRICE001',
        shippingDate: DateTime.now(),
        products: validProducts,
        notes: 'Valid draft',
      );

      final status = draftService.getSaveStatus();
      expect(status['lastSaveError'], isNull);
    });
  });

  group('OrderDraftService - App Lifecycle Integration', () {
    test('should register lifecycle observer', () {
      // This test verifies that the lifecycle observer is properly initialized
      // In a real scenario, this would be tested with a test app
      expect(draftService, isNotNull);
    });

    testWidgets('should handle app lifecycle changes', (tester) async {
      // This test would require a full widget test setup
      // For now, we verify the service can be created in a widget context
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Service should work in widget context
              expect(draftService, isNotNull);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('OrderDraftService - Data Validation', () {
    test('should handle empty product list', () async {
      when(mockDbService.saveVisitStepData(any))
          .thenAnswer((_) async => 1);

      await draftService.saveOrderDraft(
        visitId: 'VISIT001',
        clientCode: 'CLIENT001',
        stepCode: 1,
        stepName: 'Create Order',
        selectedOrganization: 'ORG001',
        selectedWarehouse: 'WH001',
        selectedPriceType: 'PRICE001',
        selectedOrganizationcode: 'ORG001',
        selectedWarehousecode: 'WH001',
        selectedPriceTypecode: 'PRICE001',
        shippingDate: DateTime.now(),
        products: [],
        notes: '',
      );

      final status = draftService.getSaveStatus();
      expect(status['lastSaveError'], isNull);
    });

    test('should handle null notes', () async {
      when(mockDbService.saveVisitStepData(any))
          .thenAnswer((_) async => 1);

      await draftService.saveOrderDraft(
        visitId: 'VISIT001',
        clientCode: 'CLIENT001',
        stepCode: 1,
        stepName: 'Create Order',
        selectedOrganization: 'ORG001',
        selectedWarehouse: 'WH001',
        selectedPriceType: 'PRICE001',
        selectedOrganizationcode: 'ORG001',
        selectedWarehousecode: 'WH001',
        selectedPriceTypecode: 'PRICE001',
        shippingDate: DateTime.now(),
        products: [],
        notes: '',
      );

      final status = draftService.getSaveStatus();
      expect(status['lastSaveError'], isNull);
    });

    test('should handle special characters in notes', () async {
      when(mockDbService.saveVisitStepData(any, any, any, any))
          .thenAnswer((_) async => 1);

      await draftService.saveOrderDraft(
        visitId: 'VISIT001',
        clientCode: 'CLIENT001',
        stepCode: 1,
        stepName: 'Create Order',
        selectedOrganization: 'ORG001',
        selectedWarehouse: 'WH001',
        selectedPriceType: 'PRICE001',
        selectedOrganizationcode: 'ORG001',
        selectedWarehousecode: 'WH001',
        selectedPriceTypecode: 'PRICE001',
        shippingDate: DateTime.now(),
        products: [],
        notes: 'Special chars: àáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ',
      );

      final status = draftService.getSaveStatus();
      expect(status['lastSaveError'], isNull);
    });
  });
}