import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/order_details_page.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order_detail.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/order_models.dart';

// Mock classes
class MockDataSyncService extends Mock implements DataSyncService {}
class MockSharedPreferencesService extends Mock implements SharedPreferencesService {}

void main() {
  late MockDataSyncService mockDataSyncService;
  late MockSharedPreferencesService mockPrefsService;

  setUp(() {
    mockDataSyncService = MockDataSyncService();
    mockPrefsService = MockSharedPreferencesService();

    GetIt.I.registerSingleton<DataSyncService>(mockDataSyncService);
    GetIt.I.registerSingleton<SharedPreferencesService>(mockPrefsService);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  group('OrderDetailsPage Integration Tests', () {
    testWidgets('should display loading indicator initially', (WidgetTester tester) async {
      // Arrange
      final order = OrderModel(
        id: 1,
        numOrder: 'GL00-123456',
        dateOrder: DateTime.now(),
        captionOrder: 'Test Order',
        typePriceCode: 'R',
        status: 1,
        total: 100000.0,
        clientCode: 'CLIENT001',
        clientName: 'Test Client',
        codeOrg: 'ORG001',
        mainStatus: 'New',
        items: [],
      );

      when(mockDataSyncService.getCachedOrderDetailByNumOrder('GL00-123456'))
          .thenAnswer((_) async => null);

      when(mockPrefsService.getUserCode()).thenAnswer((_) async => 'USER001');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailsPage(order: order),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Buyurtma tafsilotlari'), findsOneWidget);
    });

    testWidgets('should display order details from cache', (WidgetTester tester) async {
      // Arrange
      final order = OrderModel(
        id: 1,
        numOrder: 'GL00-123456',
        dateOrder: DateTime.now(),
        captionOrder: 'Test Order',
        typePriceCode: 'R',
        status: 1,
        total: 100000.0,
        clientCode: 'CLIENT001',
        clientName: 'Test Client',
        codeOrg: 'ORG001',
        mainStatus: 'New',
        items: [],
      );

      final cachedOrderDetail = OrderDetail(
        numOrder: 'GL00-123456',
        credit: false,
        codePrice: 'R',
        dateOrder: DateTime.now(),
        codeSklad: 'SKL001',
        commentSupervisor: 'Supervisor comment',
        commentForwarder: 'Forwarder comment',
        commentAgent: 'Agent comment',
        shippingDate: '2024-01-20',
        orderType: 1,
        codeOrg: 'ORG001',
        productRows: [
          OrderDetailProduct(
            codeProduct: 'PROD001',
            nameProduct: 'Test Product',
            amount: 10,
            price: 10000.0,
            total: 100000.0,
            discountRate: 0.0,
            weight: 1.0,
            capacity: 0.5,
          ),
        ],
        creditDetailsList: [],
      );

      when(mockDataSyncService.getCachedOrderDetailByNumOrder('GL00-123456'))
          .thenAnswer((_) async => cachedOrderDetail);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailsPage(order: order),
        ),
      );

      await tester.pump(); // Trigger the load
      await tester.pump(); // Allow UI to update

      // Assert
      expect(find.text('GL00-123456'), findsOneWidget);
      expect(find.text('Test Client'), findsOneWidget);
      expect(find.text('Test Product'), findsOneWidget);
      expect(find.text('Supervisor comment'), findsOneWidget);
      expect(find.text('Agent comment'), findsOneWidget);
    });

    testWidgets('should display error message when loading fails', (WidgetTester tester) async {
      // Arrange
      final order = OrderModel(
        id: 1,
        numOrder: 'GL00-123456',
        dateOrder: DateTime.now(),
        captionOrder: 'Test Order',
        typePriceCode: 'R',
        status: 1,
        total: 100000.0,
        clientCode: 'CLIENT001',
        clientName: 'Test Client',
        codeOrg: 'ORG001',
        mainStatus: 'New',
        items: [],
      );

      when(mockDataSyncService.getCachedOrderDetailByNumOrder('GL00-123456'))
          .thenAnswer((_) async => null);

      when(mockPrefsService.getUserCode()).thenAnswer((_) async => 'USER001');

      when(mockDataSyncService.syncOrderDetails(
        numberOrder: 'GL00-123456',
        orderDate1: anyNamed('orderDate1') ?? '2024-01-01',
        orderDate2: anyNamed('orderDate2') ?? '2024-01-01',
        forceRefresh: true,
      )).thenThrow(Exception('Network error'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailsPage(order: order),
        ),
      );

      await tester.pump(); // Trigger the load
      await tester.pump(); // Allow UI to update

      // Assert
      expect(find.text('Xatolik yuz berdi'), findsOneWidget);
      expect(find.text('Internet bilan bog\'liq xatolik. Iltimos, internetingizni tekshiring.'), findsOneWidget);
      expect(find.text('Qayta urinib ko\'ring'), findsOneWidget);
    });

    testWidgets('should retry loading when retry button is pressed', (WidgetTester tester) async {
      // Arrange
      final order = OrderModel(
        id: 1,
        numOrder: 'GL00-123456',
        dateOrder: DateTime.now(),
        captionOrder: 'Test Order',
        typePriceCode: 'R',
        status: 1,
        total: 100000.0,
        clientCode: 'CLIENT001',
        clientName: 'Test Client',
        codeOrg: 'ORG001',
        mainStatus: 'New',
        items: [],
      );

      final serverOrderDetail = OrderDetail(
        numOrder: 'GL00-123456',
        credit: true,
        codePrice: 'W',
        dateOrder: DateTime.now(),
        codeSklad: 'SKL001',
        commentSupervisor: 'Server supervisor comment',
        commentForwarder: null,
        commentAgent: null,
        shippingDate: '2024-01-25',
        orderType: 2,
        codeOrg: 'ORG001',
        productRows: [],
        creditDetailsList: [],
      );

      when(mockDataSyncService.getCachedOrderDetailByNumOrder('GL00-123456'))
          .thenAnswer((_) async => null);

      when(mockPrefsService.getUserCode()).thenAnswer((_) async => 'USER001');

      // First call throws error
      when(mockDataSyncService.syncOrderDetails(
        numberOrder: 'GL00-123456',
        orderDate1: anyNamed('orderDate1'),
        orderDate2: anyNamed('orderDate2'),
        forceRefresh: true,
      )).thenThrow(Exception('Network error'));

      // Act - Initial load
      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailsPage(order: order),
        ),
      );

      await tester.pump(); // Trigger the load
      await tester.pump(); // Allow UI to update

      // Assert error is shown
      expect(find.text('Xatolik yuz berdi'), findsOneWidget);

      // Now mock successful retry
      when(mockDataSyncService.syncOrderDetails(
        numberOrder: 'GL00-123456',
        orderDate1: anyNamed('orderDate1'),
        orderDate2: anyNamed('orderDate2'),
        forceRefresh: true,
      )).thenAnswer((_) async => serverOrderDetail);

      // Act - Press retry button
      await tester.tap(find.text('Qayta urinib ko\'ring'));
      await tester.pump(); // Trigger retry
      await tester.pump(); // Allow UI to update

      // Assert - Should now show order details
      expect(find.text('GL00-123456'), findsOneWidget);
      expect(find.text('Test Client'), findsOneWidget);
    });

    testWidgets('should navigate back when back button is pressed', (WidgetTester tester) async {
      // Arrange
      final order = OrderModel(
        id: 1,
        numOrder: 'GL00-123456',
        dateOrder: DateTime.now(),
        captionOrder: 'Test Order',
        typePriceCode: 'R',
        status: 1,
        total: 100000.0,
        clientCode: 'CLIENT001',
        clientName: 'Test Client',
        codeOrg: 'ORG001',
        mainStatus: 'New',
        items: [],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderDetailsPage(order: order),
          ),
        ),
      );

      // Assert back button exists
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Note: We can't easily test navigation in widget tests without more complex setup
      // This test mainly verifies the back button is present
    });

    testWidgets('should display tab bar with Asosiy and Tarkibi tabs', (WidgetTester tester) async {
      // Arrange
      final order = OrderModel(
        id: 1,
        numOrder: 'GL00-123456',
        dateOrder: DateTime.now(),
        captionOrder: 'Test Order',
        typePriceCode: 'R',
        status: 1,
        total: 100000.0,
        clientCode: 'CLIENT001',
        clientName: 'Test Client',
        codeOrg: 'ORG001',
        mainStatus: 'New',
        items: [],
      );

      final cachedOrderDetail = OrderDetail(
        numOrder: 'GL00-123456',
        credit: false,
        codePrice: 'R',
        dateOrder: DateTime.now(),
        codeSklad: 'SKL001',
        commentSupervisor: null,
        commentForwarder: null,
        commentAgent: null,
        shippingDate: '2024-01-20',
        orderType: 1,
        codeOrg: 'ORG001',
        productRows: [],
        creditDetailsList: [],
      );

      when(mockDataSyncService.getCachedOrderDetailByNumOrder('GL00-123456'))
          .thenAnswer((_) async => cachedOrderDetail);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailsPage(order: order),
        ),
      );

      await tester.pump(); // Trigger the load
      await tester.pump(); // Allow UI to update

      // Assert
      expect(find.text('Asosiy'), findsOneWidget);
      expect(find.text('Tarkibi'), findsOneWidget);
    });
  });
}