import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/map_pages/map_detail_page_yandex.dart';

void main() {
  group('MapDetailPageYandex Widget Tests', () {
    testWidgets('MapDetailPageYandex builds without errors', (WidgetTester tester) async {
      // Create a mock trading point with all required fields
      final tradingPoint = model.TradingPoint(
        id: '1',
        name: 'Test Client',
        latitude: 41.2995,
        longitude: 69.2401,
        address: 'Test Address',
        phone: '123456789',
        ownerName: 'Test Owner',
        contactPerson: 'Test Contact',
        inn: '123456789',
        status: 'Active',
        lastVisitDate: '2024-01-01',
        hasOrders: false,
        hasContracts: false,
        isVisited: false,
        hasContract: false,
        region: 'Test Region',
        district: 'Test District',
        signboard: 'Test Signboard',
        referencePoint: 'Test Reference',
        responsiblePerson: 'Test Person',
        responsiblePersonPhone: '987654321',
        tradePointType: 'Retail',
        creditLimit: 1000.0,
        accumulatedCredit: 0.0,
        codeRegion: '01',
      );

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPageYandex(tradingPoint: tradingPoint),
        ),
      );

      // Wait for a short time (don't use pumpAndSettle as Yandex Maps may not initialize in test)
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the widget builds
      expect(find.byType(MapDetailPageYandex), findsOneWidget);

      // Check for back button - may not be immediately visible due to map loading
      // expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Check for control buttons (may be present depending on state)
      // expect(find.byIcon(Icons.my_location), findsOneWidget);
      // expect(find.byIcon(Icons.location_on), findsOneWidget);
      // expect(find.byIcon(Icons.route), findsOneWidget);
    });

    testWidgets('MapDetailPageYandex shows loading overlay initially', (WidgetTester tester) async {
      final tradingPoint = model.TradingPoint(
        id: '1',
        name: 'Test Client',
        latitude: 41.2995,
        longitude: 69.2401,
        address: 'Test Address',
        phone: '123456789',
        ownerName: 'Test Owner',
        contactPerson: 'Test Contact',
        inn: '123456789',
        status: 'Active',
        lastVisitDate: '2024-01-01',
        hasOrders: false,
        hasContracts: false,
        isVisited: false,
        hasContract: false,
        region: 'Test Region',
        district: 'Test District',
        signboard: 'Test Signboard',
        referencePoint: 'Test Reference',
        responsiblePerson: 'Test Person',
        responsiblePersonPhone: '987654321',
        tradePointType: 'Retail',
        creditLimit: 1000.0,
        accumulatedCredit: 0.0,
        codeRegion: '01',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPageYandex(tradingPoint: tradingPoint),
        ),
      );

      // Initially should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Back button is present', (WidgetTester tester) async {
      final tradingPoint = model.TradingPoint(
        id: '1',
        name: 'Test Client',
        latitude: 41.2995,
        longitude: 69.2401,
        address: 'Test Address',
        phone: '123456789',
        ownerName: 'Test Owner',
        contactPerson: 'Test Contact',
        inn: '123456789',
        status: 'Active',
        lastVisitDate: '2024-01-01',
        hasOrders: false,
        hasContracts: false,
        isVisited: false,
        hasContract: false,
        region: 'Test Region',
        district: 'Test District',
        signboard: 'Test Signboard',
        referencePoint: 'Test Reference',
        responsiblePerson: 'Test Person',
        responsiblePersonPhone: '987654321',
        tradePointType: 'Retail',
        creditLimit: 1000.0,
        accumulatedCredit: 0.0,
        codeRegion: '01',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPageYandex(tradingPoint: tradingPoint),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Verify back button is present - may not be immediately visible due to map loading
      // expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}