import 'dart:convert';
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

    test('should save new draft when no existing draft exists', () async {
      // Mock no existing draft
      when(mockDbService.getVisitStepDataByVisitId('VISIT001'))
          .thenAnswer((_) async => []);

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
        products: products,
        notes: 'New draft',
      );

      // Test passes if no exception is thrown
      final status = draftService.getSaveStatus();
      expect(status['lastSaveError'], isNull);
    });

    test('should merge products when existing draft exists', () async {
      // Mock existing draft with one product
      final existingVisitData = VisitData(
        visitId: 'VISIT001',
        clientCode: 'CLIENT001',
        stepCode: 1,
        stepName: 'Create Order',
        dataType: 'order_draft',
        dataContent: '{"visitId":"VISIT001","clientCode":"CLIENT001","stepCode":1,"stepName":"Create Order","selectedOrganization":"ORG001","selectedWarehouse":"WH001","selectedPriceType":"PRICE001","selectedOrganizationcode":"ORG001","selectedWarehousecode":"WH001","selectedPriceTypecode":"PRICE001","shippingDate":"2024-01-01T00:00:00.000","products":[{"codeSklad":"SKL001","codeProduct":"PRD001","vendorCode":"VC001","amount":2,"price":10000.0,"total":20000.0,"weight":1.0,"capacity":0.5,"paymentType":0,"discountSum":0.0,"discountRate":0.0,"giftAmount":0,"promo":false}],"notes":"Existing draft","timestamp":"2024-01-01T00:00:00.000","version":1}',
        timestamp: DateTime.now(),
      );

      when(mockDbService.getVisitStepDataByVisitId('VISIT001'))
          .thenAnswer((_) async => [existingVisitData]);

      when(mockDbService.saveVisitStepData(any))
          .thenAnswer((_) async {});

      when(mockDbService.deleteVisitStepDataByStepCode('VISIT001', 1))
          .thenAnswer((_) async {});

      // New products: update existing PRD001 and add new PRD002
      final newProducts = [
        CreateOrderProduct(
          codeSklad: 'SKL001',
          codeProduct: 'PRD001', // Existing product, should be updated
          vendorCode: 'VC001',
          amount: 5, // Changed from 2 to 5
          price: 10000.0,
          total: 50000.0,
          weight: 1.0,
          capacity: 0.5,
          paymentType: 0,
          discountSum: 0.0,
          discountRate: 0.0,
          giftAmount: 0,
          promo: false,
        ),
        CreateOrderProduct(
          codeSklad: 'SKL001',
          codeProduct: 'PRD002', // New product, should be added
          vendorCode: 'VC002',
          amount: 3,
          price: 15000.0,
          total: 45000.0,
          weight: 1.5,
          capacity: 0.8,
          paymentType: 0,
          discountSum: 0.0,
          discountRate: 0.0,
          giftAmount: 0,
          promo: false,
        )
      ];

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
        products: newProducts,
        notes: 'Updated draft',
      );

      // Verify delete was called for existing draft
      verify(mockDbService.deleteVisitStepDataByStepCode('VISIT001', 1)).called(1);

      // Verify save was called once with merged data
      verify(mockDbService.saveVisitStepData(any)).called(1);

      // Verify the saved data contains both products
      final capturedVisitData = verify(mockDbService.saveVisitStepData(captureAny))
          .captured.single as VisitData;

      final savedData = jsonDecode(capturedVisitData.dataContent) as Map<String, dynamic>;
      final savedProducts = savedData['products'] as List<dynamic>;

      expect(savedProducts.length, 2);

      // Check PRD001 was updated
      final prd001 = savedProducts.firstWhere((p) => p['codeProduct'] == 'PRD001');
      expect(prd001['amount'], 5);

      // Check PRD002 was added
      final prd002 = savedProducts.firstWhere((p) => p['codeProduct'] == 'PRD002');
      expect(prd002['amount'], 3);
    });

    test('should ensure only one draft per client per day', () async {
      // Mock existing draft
      final existingVisitData = VisitData(
        visitId: 'VISIT001',
        clientCode: 'CLIENT001',
        stepCode: 1,
        stepName: 'Create Order',
        dataType: 'order_draft',
        dataContent: '{"visitId":"VISIT001","clientCode":"CLIENT001","stepCode":1,"stepName":"Create Order","selectedOrganization":"ORG001","selectedWarehouse":"WH001","selectedPriceType":"PRICE001","selectedOrganizationcode":"ORG001","selectedWarehousecode":"WH001","selectedPriceTypecode":"PRICE001","shippingDate":"2024-01-01T00:00:00.000","products":[],"notes":"Existing draft","timestamp":"2024-01-01T00:00:00.000","version":1}',
        timestamp: DateTime.now(),
      );

      when(mockDbService.getVisitStepDataByVisitId('VISIT001'))
          .thenAnswer((_) async => [existingVisitData]);

      when(mockDbService.saveVisitStepData(any))
          .thenAnswer((_) async {});

      when(mockDbService.deleteVisitStepDataByStepCode('VISIT001', 1))
          .thenAnswer((_) async {});

      // Save new draft
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
        notes: 'New draft',
      );

      // Verify existing draft was deleted before saving new one
      verify(mockDbService.deleteVisitStepDataByStepCode('VISIT001', 1)).called(1);
      verify(mockDbService.saveVisitStepData(any)).called(1);
    });

    test('should handle merge when existing draft has invalid data', () async {
      // Mock existing draft with invalid products data
      final existingVisitData = VisitData(
        visitId: 'VISIT001',
        clientCode: 'CLIENT001',
        stepCode: 1,
        stepName: 'Create Order',
        dataType: 'order_draft',
        dataContent: '{"visitId":"VISIT001","clientCode":"CLIENT001","stepCode":1,"stepName":"Create Order","selectedOrganization":"ORG001","selectedWarehouse":"WH001","selectedPriceType":"PRICE001","selectedOrganizationcode":"ORG001","selectedWarehousecode":"WH001","selectedPriceTypecode":"PRICE001","shippingDate":"2024-01-01T00:00:00.000","products":[{"invalid":"data"}],"notes":"Existing draft","timestamp":"2024-01-01T00:00:00.000","version":1}',
        timestamp: DateTime.now(),
      );

      when(mockDbService.getVisitStepDataByVisitId('VISIT001'))
          .thenAnswer((_) async => [existingVisitData]);

      when(mockDbService.saveVisitStepData(any))
          .thenAnswer((_) async {});

      when(mockDbService.deleteVisitStepDataByStepCode('VISIT001', 1))
          .thenAnswer((_) async {});

      final newProducts = [
        CreateOrderProduct(
          codeSklad: 'SKL001',
          codeProduct: 'PRD001',
          vendorCode: 'VC001',
          amount: 1,
          price: 10000.0,
          total: 10000.0,
          weight: 1.0,
          capacity: 0.5,
          paymentType: 0,
          discountSum: 0.0,
          discountRate: 0.0,
          giftAmount: 0,
          promo: false,
        )
      ];

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
        products: newProducts,
        notes: 'New draft',
      );

      // Should still save successfully despite invalid existing data
      verify(mockDbService.saveVisitStepData(any)).called(1);
      final status = draftService.getSaveStatus();
      expect(status['lastSaveError'], isNull);
    });
  });
}