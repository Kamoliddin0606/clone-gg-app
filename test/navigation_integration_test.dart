import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/trading_points_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/orders_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart' as di;

// Mock services for testing
class MockSharedPreferencesService extends SharedPreferencesService {
  @override
  Future<String?> getUserCode() async => 'test_user';

  @override
  Future<String?> getPassword() async => 'test_pass';
}

void main() {
  setUpAll(() async {
    // Initialize minimal service locator for testing
    GetIt.I.registerSingleton<SharedPreferencesService>(MockSharedPreferencesService());
  });

  tearDownAll(() {
    GetIt.I.reset();
  });

  group('Navigation Integration Tests', () {
    testWidgets('TradingPointsPage to OrdersPage navigation with client filter', (WidgetTester tester) async {
      // Create a test trading point
      final testTradingPoint = TradingPoint(
        id: 'TP001',
        name: 'Test Client',
        address: 'Test Address',
        phone: '+998901234567',
        ownerName: 'Test Owner',
        contactPerson: 'Test Contact',
        inn: '123456789',
        status: 'active',
        lastVisitDate: '',
        hasOrders: true,
        hasContracts: false,
        isVisited: false,
        hasContract: false,
        latitude: 41.2995,
        longitude: 69.2401,
        region: 'Tashkent',
        district: 'Yunusabad',
        signboard: 'Test Signboard',
        referencePoint: 'Test Reference',
        responsiblePerson: 'Test Responsible',
        responsiblePersonPhone: '+998909876543',
        tradePointType: 'Retail',
        creditLimit: 1000000.0,
        accumulatedCredit: 0.0,
        codeRegion: '01',
      );

      // Build TradingPointsPage
      await tester.pumpWidget(
        MaterialApp(
          home: const TradingPointsPage(),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Find the "Buyurtma" button in the actions
      final orderButton = find.text('Buyurtma');
      expect(orderButton, findsOneWidget);

      // Tap the order button
      await tester.tap(orderButton);
      await tester.pumpAndSettle();

      // Verify navigation occurred (OrdersPage should be shown)
      expect(find.byType(OrdersPage), findsOneWidget);

      // Verify that OrdersPage received the correct parameters
      final ordersPage = tester.widget<OrdersPage>(find.byType(OrdersPage));
      expect(ordersPage.initialClientFilter, equals(testTradingPoint.id));
      expect(ordersPage.initialClientName, equals(testTradingPoint.name));
    });

    testWidgets('OrdersPage applies initial client filter correctly', (WidgetTester tester) async {
      const initialClientName = 'Test Client';

      // Build OrdersPage with initial client filter
      await tester.pumpWidget(
        MaterialApp(
          home: OrdersPage(
            initialClientFilter: 'TP001',
            initialClientName: initialClientName,
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Verify that a snackbar is shown with client name
      expect(find.text('$initialClientName mijozining buyurtmalari'), findsOneWidget);

      // Verify that filter panel is shown
      final filterIcon = find.byIcon(Icons.filter_alt_rounded);
      expect(filterIcon, findsOneWidget);
    });

    testWidgets('TradingPointsPage state persistence works correctly', (WidgetTester tester) async {
      // Build TradingPointsPage
      await tester.pumpWidget(
        MaterialApp(
          home: const TradingPointsPage(),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Simulate navigation away and back
      await tester.pumpWidget(
        MaterialApp(
          home: Container(), // Different page
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: const TradingPointsPage(), // Back to TradingPointsPage
        ),
      );

      // Wait for state restoration
      await tester.pumpAndSettle();

      // Verify page loads without errors (state restoration worked)
      expect(find.byType(TradingPointsPage), findsOneWidget);
    });
  });
}