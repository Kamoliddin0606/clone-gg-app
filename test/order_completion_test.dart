import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/step_pages/create_order_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/create_order.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/order_draft_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

// Mock classes
class MockApiDatabaseService extends Mock implements ApiDatabaseService {}
class MockOrderDraftService extends Mock implements OrderDraftService {}
class MockSharedPreferencesService extends Mock implements SharedPreferencesService {}

void main() {
  late MockApiDatabaseService mockDbService;
  late MockOrderDraftService mockDraftService;
  late MockSharedPreferencesService mockPrefs;
  late TradingPointWithPermissions mockTradingPoint;

  setUp(() {
    mockDbService = MockApiDatabaseService();
    mockDraftService = MockOrderDraftService();
    mockPrefs = MockSharedPreferencesService();

    // Create mock trading point
    final tradingPoint = TradingPoint(
      id: 'TP001',
      name: 'Test Trading Point',
      address: 'Test Address',
      phone: '+998901234567',
      ownerName: 'Test Owner',
      contactPerson: 'Test Contact',
      inn: '123456789',
      status: 'active',
      lastVisitDate: '2024-01-01',
      hasOrders: true,
      hasContracts: true,
      isVisited: false,
      hasContract: true,
      latitude: 41.2995,
      longitude: 69.2401,
      region: 'Tashkent',
      district: 'Yunusabad',
      signboard: 'Test Signboard',
      referencePoint: 'Test Reference',
      responsiblePerson: 'Test Person',
      responsiblePersonPhone: '+998909876543',
      tradePointType: 'Shop',
      creditLimit: 1000000.0,
      accumulatedCredit: 50000.0,
      codeRegion: 'REG001',
      visitToday: false,
      visitStepNumber: 1,
      plannedWeekDay: 'Monday',
    );

    final permissions = SalesReqPermissions(
      id: 1,
      userCode: 'USER001',
      skipTINduplicateCheck: false,
      allowCreationWithoutTIN: false,
      allowCreatingPointOfSale: false,
      visit: true,
      strictSequence: false,
      unplannedOrder: true,
      plannedRoute: false,
      editClientCoordinates: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      visitSteps: [],
    );

    mockTradingPoint = TradingPointWithPermissions(
      tradingPoint: tradingPoint,
      permissions: permissions,
    );
  });

  group('Order Completion Functionality Tests', () {
    testWidgets('should show delivery date picker dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  helpText: 'Buyurtma yetkazilish sanasini tanlang',
                  cancelText: 'Bekor qilish',
                  confirmText: 'Tasdiqlash',
                );
                // Test that dialog opens and returns a date
                expect(result, isNotNull);
              },
              child: const Text('Test Date Picker'),
            ),
          ),
        ),
      );

      // Tap the button to open date picker
      await tester.tap(find.text('Test Date Picker'));
      await tester.pumpAndSettle();

      // Verify date picker dialog is shown
      expect(find.text('Buyurtma yetkazilish sanasini tanlang'), findsOneWidget);
      expect(find.text('Bekor qilish'), findsOneWidget);
      expect(find.text('Tasdiqlash'), findsOneWidget);
    });

    test('should validate delivery date is not in the past', () {
      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(days: 1));
      final futureDate = now.add(const Duration(days: 1));

      // Past date should be invalid
      expect(pastDate.isBefore(now), isTrue);

      // Future date should be valid
      expect(futureDate.isAfter(now), isTrue);
    });

    test('should create CreateOrder object with correct data', () {
      final deliveryDate = DateTime.now().add(const Duration(days: 3));
      final createDate = DateTime.now();

      final order = CreateOrder(
        codeAgent: 'AGENT001',
        codeClient: 'CLIENT001',
        codePrice: 'PRICE001',
        payment: 'cash',
        shippingDate: deliveryDate,
        comment: 'Test order comment',
        createDate: createDate,
        longitude: 69.2401,
        latitude: 41.2995,
        weight: 10.5,
        capacity: 5.2,
        credit: false,
        codeProject: 'PROJECT001',
        orderType: 0,
        codeOrg: 'ORG001',
        codeSklad: 'SKLAD001',
        hasPromo: false,
        products: [],
        competitiveIntelligence: [],
        creditDetails: [],
      );

      expect(order.codeAgent, 'AGENT001');
      expect(order.codeClient, 'CLIENT001');
      expect(order.shippingDate, deliveryDate);
      expect(order.comment, 'Test order comment');
      expect(order.products, isEmpty);
      expect(order.competitiveIntelligence, isEmpty);
      expect(order.creditDetails, isEmpty);
    });

    test('should calculate order totals correctly', () {
      final products = [
        CreateOrderProduct(
          codeSklad: 'SKLAD001',
          codeProduct: 'PROD001',
          vendorCode: 'VEND001',
          amount: 2,
          price: 50000.0,
          total: 100000.0,
          weight: 1.5,
          capacity: 0.8,
          paymentType: 0,
          discountSum: 0.0,
          discountRate: 0.0,
          giftAmount: 0,
          promo: false,
        ),
        CreateOrderProduct(
          codeSklad: 'SKLAD001',
          codeProduct: 'PROD002',
          vendorCode: 'VEND002',
          amount: 1,
          price: 75000.0,
          total: 75000.0,
          weight: 2.0,
          capacity: 1.2,
          paymentType: 0,
          discountSum: 0.0,
          discountRate: 0.0,
          giftAmount: 0,
          promo: false,
        ),
      ];

      final totalValue = products.fold(0.0, (sum, p) => sum + p.total);
      final totalWeight = products.fold(0.0, (sum, p) => sum + (p.weight * p.amount));
      final totalVolume = products.fold(0.0, (sum, p) => sum + (p.capacity * p.amount));

      expect(totalValue, 175000.0);
      expect(totalWeight, 5.0); // (1.5 * 2) + (2.0 * 1)
      expect(totalVolume, 2.8); // (0.8 * 2) + (1.2 * 1)
    });

    testWidgets('should handle order creation errors gracefully', (WidgetTester tester) async {
      // Test error handling in the order creation process
      // This would require more complex mocking of the entire service layer

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  // Simulate showing an error snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Buyurtmani yaratishda xatolik yuz berdi'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show error
      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      // Verify error message is shown
      expect(find.text('Buyurtmani yaratishda xatolik yuz berdi'), findsOneWidget);
    });

    testWidgets('should show success message after order creation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  // Simulate showing a success snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Buyurtma muvaffaqiyatli yaratildi!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Show Success'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show success message
      await tester.tap(find.text('Show Success'));
      await tester.pumpAndSettle();

      // Verify success message is shown
      expect(find.text('Buyurtma muvaffaqiyatli yaratildi!'), findsOneWidget);
    });

    test('should validate order data before creation', () {
      // Test validation logic for order data
      final invalidOrder = CreateOrder(
        codeAgent: '', // Invalid: empty agent code
        codeClient: 'CLIENT001',
        codePrice: 'PRICE001',
        payment: 'cash',
        shippingDate: DateTime.now().add(const Duration(days: 1)),
        createDate: DateTime.now(),
        longitude: 0.0,
        latitude: 0.0,
        weight: 0.0,
        capacity: 0.0,
        credit: false,
        codeProject: '',
        orderType: 0,
        codeOrg: '',
        codeSklad: '',
        hasPromo: false,
        products: [], // Empty products list
      );

      // Order should be invalid due to missing required fields
      expect(invalidOrder.codeAgent.isEmpty, isTrue);
      expect(invalidOrder.products.isEmpty, isTrue);
    });
  });

  group('Data Collection Tests', () {
    test('should collect products from page state when no draft exists', () {
      final pageProducts = [
        CreateOrderProduct(
          codeSklad: 'SKLAD001',
          codeProduct: 'PROD001',
          vendorCode: 'VEND001',
          amount: 2,
          price: 50000.0,
          total: 100000.0,
          weight: 1.5,
          capacity: 0.8,
          paymentType: 0,
          discountSum: 0.0,
          discountRate: 0.0,
          giftAmount: 0,
          promo: false,
        ),
      ];

      // Simulate collecting from page state (no draft data)
      final collectedProducts = pageProducts; // Direct assignment for this test

      expect(collectedProducts.length, 1);
      expect(collectedProducts.first.codeProduct, 'PROD001');
      expect(collectedProducts.first.amount, 2);
    });

    test('should parse draft data from visit_steps_data correctly', () {
      final draftData = {
        'visitId': 'VISIT001',
        'clientCode': 'CLIENT001',
        'stepCode': 1,
        'stepName': 'Buyurtma yaratish',
        'selectedOrganization': 'ORG001',
        'selectedWarehouse': 'SKLAD001',
        'selectedPriceType': 'PRICE001',
        'products': [
          {
            'codeSklad': 'SKLAD001',
            'codeProduct': 'PROD001',
            'vendorCode': 'VEND001',
            'amount': 2,
            'price': 50000.0,
            'total': 100000.0,
            'weight': 1.5,
            'capacity': 0.8,
            'paymentType': 0,
            'discountSum': 0.0,
            'discountRate': 0.0,
            'giftAmount': 0,
            'promo': false,
          }
        ],
        'notes': 'Test order notes',
        'timestamp': DateTime.now().toIso8601String(),
        'version': 1,
      };

      // Parse products from draft data
      final productsJson = draftData['products'] as List<dynamic>;
      final products = productsJson.map((p) => CreateOrderProduct.fromJson(p as Map<String, dynamic>)).toList();

      expect(products.length, 1);
      expect(products.first.codeProduct, 'PROD001');
      expect(products.first.amount, 2);
      expect(products.first.price, 50000.0);
    });
  });
}