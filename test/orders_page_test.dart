import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/orders_page.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order_status.dart';

// Mock classes
class MockDataSyncService extends Mock implements DataSyncService {}
class MockSharedPreferencesService extends Mock implements SharedPreferencesService {}

void main() {
  late MockDataSyncService mockDataSyncService;
  late MockSharedPreferencesService mockPrefsService;

  setUp(() {
    mockDataSyncService = MockDataSyncService();
    mockPrefsService = MockSharedPreferencesService();

    // Register mocks with GetIt
    GetIt.I.registerSingleton<DataSyncService>(mockDataSyncService);
    GetIt.I.registerSingleton<SharedPreferencesService>(mockPrefsService);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  group('OrdersPage Tests', () {
    testWidgets('should display loading indicator initially', (WidgetTester tester) async {
      // Arrange
      when(mockPrefsService.getUserCode()).thenAnswer((_) async => 'test_user');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: OrdersPage(),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Buyurtmalar'), findsOneWidget);
    });

    testWidgets('should display error message when loading fails', (WidgetTester tester) async {
      // Arrange
      when(mockPrefsService.getUserCode()).thenThrow(Exception('Network error'));

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: OrdersPage(),
        ),
      );
      await tester.pump(); // Allow error state to be set

      // Assert
      expect(find.text('Xatolik yuz berdi'), findsOneWidget);
      expect(find.text('Qayta urinib ko\'ring'), findsOneWidget);
    });

    testWidgets('should load orders successfully', (WidgetTester tester) async {
      // Arrange
      final testOrders = [
        Order(
          numOrder: 'TEST-001',
          dateOrder: DateTime.now(),
          captionOrder: 'Test Order',
          typePriceCode: 'R',
          status: 2,
          total: 100000.0,
          clientCode: 'CLIENT-001',
          clientName: 'Test Client',
          codeOrg: 'ORG-001',
          mainStatus: 'В процессе',
        ),
      ];

      final testStatuses = [
        OrderStatus(id: 2, message: 'В процессе'),
        OrderStatus(id: 4, message: 'Доставлено'),
      ];

      when(mockPrefsService.getUserCode()).thenReturn('test_user');
      when(mockDataSyncService.getCachedOrderStatuses()).thenAnswer((_) async => testStatuses);
      when(mockDataSyncService.getCachedOrders()).thenAnswer((_) async => testOrders);

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: OrdersPage(),
        ),
      );
      await tester.pumpAndSettle(); // Wait for all async operations

      // Assert
      expect(find.text('Buyurtmalar'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Barchasi'), findsOneWidget);
      expect(find.text('В процессе'), findsOneWidget);
    });

    testWidgets('should filter orders by status tab', (WidgetTester tester) async {
      // Arrange
      final testOrders = [
        Order(
          numOrder: 'TEST-001',
          dateOrder: DateTime.now(),
          captionOrder: 'Test Order 1',
          typePriceCode: 'R',
          status: 2,
          total: 100000.0,
          clientCode: 'CLIENT-001',
          clientName: 'Test Client 1',
          codeOrg: 'ORG-001',
          mainStatus: 'В процессе',
        ),
        Order(
          numOrder: 'TEST-002',
          dateOrder: DateTime.now(),
          captionOrder: 'Test Order 2',
          typePriceCode: 'R',
          status: 4,
          total: 200000.0,
          clientCode: 'CLIENT-002',
          clientName: 'Test Client 2',
          codeOrg: 'ORG-002',
          mainStatus: 'Доставлено',
        ),
      ];

      final testStatuses = [
        OrderStatus(id: 2, message: 'В процессе'),
        OrderStatus(id: 4, message: 'Доставлено'),
      ];

      when(mockPrefsService.getUserCode()).thenReturn('test_user');
      when(mockDataSyncService.getCachedOrderStatuses()).thenAnswer((_) async => testStatuses);
      when(mockDataSyncService.getCachedOrders()).thenAnswer((_) async => testOrders);

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: OrdersPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Initially should show all orders
      expect(find.text('Buyurtmalar soni: 2'), findsOneWidget);

      // Tap on "В процессе" tab
      await tester.tap(find.text('В процессе'));
      await tester.pumpAndSettle();

      // Should show only orders with status 2
      expect(find.text('Buyurtmalar soni: 1'), findsOneWidget);
      expect(find.text('TEST-001'), findsOneWidget);
      expect(find.text('TEST-002'), findsNothing);
    });

    testWidgets('should search orders by text', (WidgetTester tester) async {
      // Arrange
      final testOrders = [
        Order(
          numOrder: 'TEST-001',
          dateOrder: DateTime.now(),
          captionOrder: 'Test Order 1',
          typePriceCode: 'R',
          status: 2,
          total: 100000.0,
          clientCode: 'CLIENT-001',
          clientName: 'Test Client 1',
          codeOrg: 'ORG-001',
          mainStatus: 'В процессе',
        ),
        Order(
          numOrder: 'TEST-002',
          dateOrder: DateTime.now(),
          captionOrder: 'Test Order 2',
          typePriceCode: 'R',
          status: 4,
          total: 200000.0,
          clientCode: 'CLIENT-002',
          clientName: 'Test Client 2',
          codeOrg: 'ORG-002',
          mainStatus: 'Доставлено',
        ),
      ];

      final testStatuses = [
        OrderStatus(id: 2, message: 'В процессе'),
        OrderStatus(id: 4, message: 'Доставлено'),
      ];

      when(mockPrefsService.getUserCode()).thenReturn('test_user');
      when(mockDataSyncService.getCachedOrderStatuses()).thenAnswer((_) async => testStatuses);
      when(mockDataSyncService.getCachedOrders()).thenAnswer((_) async => testOrders);

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: OrdersPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Initially should show all orders
      expect(find.text('Buyurtmalar soni: 2'), findsOneWidget);

      // Search for "Client 1"
      await tester.enterText(find.byType(TextField), 'Client 1');
      await tester.pumpAndSettle();

      // Should show only matching order
      expect(find.text('Buyurtmalar soni: 1'), findsOneWidget);
      expect(find.text('TEST-001'), findsOneWidget);
      expect(find.text('TEST-002'), findsNothing);
    });

    testWidgets('should handle empty order list', (WidgetTester tester) async {
      // Arrange
      final testStatuses = [
        OrderStatus(id: 2, message: 'В процессе'),
      ];

      when(mockPrefsService.getUserCode()).thenAnswer((_) async => 'test_user');
      when(mockDataSyncService.getCachedOrderStatuses()).thenAnswer((_) async => testStatuses);
      when(mockDataSyncService.getCachedOrders()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: OrdersPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Buyurtmalar soni: 0'), findsOneWidget);
    });
  });
}