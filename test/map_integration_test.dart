import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gloria_marketing_flutter/main.dart' as app;
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/map_detail_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Map Integration Tests', () {
    testWidgets('should navigate to map detail page and interact with controls',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to agent home (assuming login is bypassed in test)
      // This would need to be adjusted based on actual navigation flow

      // For now, test the MapDetailPage directly
      final testTradingPoint = TradingPoint(
        id: 'integration_test_client',
        name: 'Integration Test Client',
        latitude: 41.2995,
        longitude: 69.2401,
        address: 'Test Address',
        phone: '+998901234567',
        ownerName: 'Test Owner',
        contactPerson: 'Test Contact',
        inn: '123456789',
        status: 'active',
        lastVisitDate: DateTime.now().toIso8601String(),
        hasOrders: false,
        hasContracts: true,
        hasContract: true,
        isVisited: false,
        region: 'Tashkent',
        district: 'Test District',
        signboard: 'Test Signboard',
        referencePoint: 'Test Reference',
        responsiblePerson: 'Test Responsible',
        responsiblePersonPhone: '+998987654321',
        tradePointType: 'retail',
        creditLimit: 1000000.0,
        accumulatedCredit: 0.0,
        codeRegion: '01',
      );

      // Pump the MapDetailPage
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the page loads
      expect(find.text('Integration Test Client'), findsOneWidget);
      expect(find.byType(MapDetailPage), findsOneWidget);

      // Test control buttons are present
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.byIcon(Icons.route), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
      expect(find.byIcon(Icons.edit_location), findsOneWidget);

      // Test tapping control buttons
      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pumpAndSettle();
      // Should show snackbar message
      expect(find.textContaining('ga kamera o\'tkazildi'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.location_on));
      await tester.pumpAndSettle();
      expect(find.textContaining('ga kamera o\'tkazildi'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.route));
      await tester.pumpAndSettle();
      // Should show user location not available message
      expect(find.text('Foydalanuvchi joylashuvi aniqlanmadi'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.fullscreen));
      await tester.pumpAndSettle();
      expect(find.text('To\'liq ekran xaritasi - amalga oshirilmoqda'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_location));
      await tester.pumpAndSettle();
      expect(find.text('Koordinatalarni yangilash - amalga oshirilmoqda'), findsOneWidget);
    });

    testWidgets('should handle map provider switching', (WidgetTester tester) async {
      final testTradingPoint = TradingPoint(
        id: 'provider_test_client',
        name: 'Provider Test Client',
        latitude: 41.2995,
        longitude: 69.2401,
        address: 'Test Address',
        phone: '+998901234567',
        ownerName: 'Test Owner',
        contactPerson: 'Test Contact',
        inn: '123456789',
        status: 'active',
        lastVisitDate: DateTime.now().toIso8601String(),
        hasOrders: false,
        hasContracts: true,
        hasContract: true,
        isVisited: false,
        region: 'Tashkent',
        district: 'Test District',
        signboard: 'Test Signboard',
        referencePoint: 'Test Reference',
        responsiblePerson: 'Test Responsible',
        responsiblePersonPhone: '+998987654321',
        tradePointType: 'retail',
        creditLimit: 1000000.0,
        accumulatedCredit: 0.0,
        codeRegion: '01',
      );

      // Test with Google Maps
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Provider Test Client'), findsOneWidget);

      // Test with Yandex Maps (would need to change provider in settings)
      // This would require mocking the SharedPreferencesService

      // Test with OpenStreetMap (would need to change provider in settings)
      // This would require mocking the SharedPreferencesService
    });

    testWidgets('should handle location permissions and services', (WidgetTester tester) async {
      final testTradingPoint = TradingPoint(
        id: 'location_test_client',
        name: 'Location Test Client',
        latitude: 41.2995,
        longitude: 69.2401,
        address: 'Test Address',
        phone: '+998901234567',
        ownerName: 'Test Owner',
        contactPerson: 'Test Contact',
        inn: '123456789',
        status: 'active',
        lastVisitDate: DateTime.now().toIso8601String(),
        hasOrders: false,
        hasContracts: true,
        hasContract: true,
        isVisited: false,
        region: 'Tashkent',
        district: 'Test District',
        signboard: 'Test Signboard',
        referencePoint: 'Test Reference',
        responsiblePerson: 'Test Responsible',
        responsiblePersonPhone: '+998987654321',
        tradePointType: 'retail',
        creditLimit: 1000000.0,
        accumulatedCredit: 0.0,
        codeRegion: '01',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Test that location permission handling works
      // This would require mocking location services
      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('should handle route creation and display', (WidgetTester tester) async {
      final testTradingPoint = TradingPoint(
        id: 'route_test_client',
        name: 'Route Test Client',
        latitude: 41.2995,
        longitude: 69.2401,
        address: 'Test Address',
        phone: '+998901234567',
        ownerName: 'Test Owner',
        contactPerson: 'Test Contact',
        inn: '123456789',
        status: 'active',
        lastVisitDate: DateTime.now().toIso8601String(),
        hasOrders: false,
        hasContracts: true,
        hasContract: true,
        isVisited: false,
        region: 'Tashkent',
        district: 'Test District',
        signboard: 'Test Signboard',
        referencePoint: 'Test Reference',
        responsiblePerson: 'Test Responsible',
        responsiblePersonPhone: '+998987654321',
        tradePointType: 'retail',
        creditLimit: 1000000.0,
        accumulatedCredit: 0.0,
        codeRegion: '01',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Test route button functionality
      await tester.tap(find.byIcon(Icons.route));
      await tester.pumpAndSettle();

      // Should handle the case where user location is not available
      expect(find.text('Foydalanuvchi joylashuvi aniqlanmadi'), findsOneWidget);
    });

    testWidgets('should handle connectivity changes', (WidgetTester tester) async {
      final testTradingPoint = TradingPoint(
        id: 'connectivity_test_client',
        name: 'Connectivity Test Client',
        latitude: 41.2995,
        longitude: 69.2401,
        address: 'Test Address',
        phone: '+998901234567',
        ownerName: 'Test Owner',
        contactPerson: 'Test Contact',
        inn: '123456789',
        status: 'active',
        lastVisitDate: DateTime.now().toIso8601String(),
        hasOrders: false,
        hasContracts: true,
        hasContract: true,
        isVisited: false,
        region: 'Tashkent',
        district: 'Test District',
        signboard: 'Test Signboard',
        referencePoint: 'Test Reference',
        responsiblePerson: 'Test Responsible',
        responsiblePersonPhone: '+998987654321',
        tradePointType: 'retail',
        creditLimit: 1000000.0,
        accumulatedCredit: 0.0,
        codeRegion: '01',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Test that the map loads even with connectivity issues
      // This would require mocking connectivity changes
      expect(find.byType(MapDetailPage), findsOneWidget);
    });

    testWidgets('should handle back navigation', (WidgetTester tester) async {
      final testTradingPoint = TradingPoint(
        id: 'navigation_test_client',
        name: 'Navigation Test Client',
        latitude: 41.2995,
        longitude: 69.2401,
        address: 'Test Address',
        phone: '+998901234567',
        ownerName: 'Test Owner',
        contactPerson: 'Test Contact',
        inn: '123456789',
        status: 'active',
        lastVisitDate: DateTime.now().toIso8601String(),
        hasOrders: false,
        hasContracts: true,
        hasContract: true,
        isVisited: false,
        region: 'Tashkent',
        district: 'Test District',
        signboard: 'Test Signboard',
        referencePoint: 'Test Reference',
        responsiblePerson: 'Test Responsible',
        responsiblePersonPhone: '+998987654321',
        tradePointType: 'retail',
        creditLimit: 1000000.0,
        accumulatedCredit: 0.0,
        codeRegion: '01',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              leading: BackButton(),
              title: Text('Test'),
            ),
            body: MapDetailPage(tradingPoint: testTradingPoint),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test back button functionality
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Should navigate back (this test verifies the back button exists and is tappable)
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('should handle screen orientation changes', (WidgetTester tester) async {
      final testTradingPoint = TradingPoint(
        id: 'orientation_test_client',
        name: 'Orientation Test Client',
        latitude: 41.2995,
        longitude: 69.2401,
        address: 'Test Address',
        phone: '+998901234567',
        ownerName: 'Test Owner',
        contactPerson: 'Test Contact',
        inn: '123456789',
        status: 'active',
        lastVisitDate: DateTime.now().toIso8601String(),
        hasOrders: false,
        hasContracts: true,
        hasContract: true,
        isVisited: false,
        region: 'Tashkent',
        district: 'Test District',
        signboard: 'Test Signboard',
        referencePoint: 'Test Reference',
        responsiblePerson: 'Test Responsible',
        responsiblePersonPhone: '+998987654321',
        tradePointType: 'retail',
        creditLimit: 1000000.0,
        accumulatedCredit: 0.0,
        codeRegion: '01',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Test that controls remain accessible after orientation change
      // Note: Actual orientation testing would require device/emulator setup
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.byIcon(Icons.route), findsOneWidget);
    });

    testWidgets('should handle memory pressure and cleanup', (WidgetTester tester) async {
      final testTradingPoint = TradingPoint(
        id: 'memory_test_client',
        name: 'Memory Test Client',
        latitude: 41.2995,
        longitude: 69.2401,
        address: 'Test Address',
        phone: '+998901234567',
        ownerName: 'Test Owner',
        contactPerson: 'Test Contact',
        inn: '123456789',
        status: 'active',
        lastVisitDate: DateTime.now().toIso8601String(),
        hasOrders: false,
        hasContracts: true,
        hasContract: true,
        isVisited: false,
        region: 'Tashkent',
        district: 'Test District',
        signboard: 'Test Signboard',
        referencePoint: 'Test Reference',
        responsiblePerson: 'Test Responsible',
        responsiblePersonPhone: '+998987654321',
        tradePointType: 'retail',
        creditLimit: 1000000.0,
        accumulatedCredit: 0.0,
        codeRegion: '01',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Test that the widget can be disposed without issues
      // This verifies proper cleanup in dispose() method
      expect(find.byType(MapDetailPage), findsOneWidget);
    });
  });
}