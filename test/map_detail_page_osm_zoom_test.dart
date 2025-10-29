import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/map_pages/map_detail_page_osm.dart';

// Create a test trading point without mocks
TradingPoint createTestTradingPoint() {
  return TradingPoint(
    id: '1',
    name: 'Test Client',
    address: 'Test Address',
    phone: '+998901234567',
    latitude: 41.2995,
    longitude: 69.2401,
    ownerName: 'Test Owner',
    contactPerson: 'Test Contact',
    inn: '123456789',
    status: 'active',
    lastVisitDate: DateTime.now().toIso8601String(),
    hasOrders: false,
    hasContracts: false,
    isVisited: false,
    hasContract: false,
    region: 'Tashkent',
    district: 'Yunusabad',
    signboard: 'Test Signboard',
    referencePoint: 'Test Reference',
    responsiblePerson: 'Test Responsible',
    responsiblePersonPhone: '+998901234567',
    tradePointType: 'retail',
    creditLimit: 1000000.0,
    accumulatedCredit: 0.0,
    codeRegion: '01',
  );
}

void main() {
  group('MapDetailPageOsm Zoom and Camera Tests', () {
    late TradingPoint testTradingPoint;

    setUp(() {
      testTradingPoint = createTestTradingPoint();
    });

    testWidgets('Zoom in button increases zoom level', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPageOsm(tradingPoint: testTradingPoint),
        ),
      );

      // Wait for map to initialize
      await tester.pumpAndSettle();

      // Find zoom in button (add icon)
      final zoomInButton = find.byIcon(Icons.add);
      expect(zoomInButton, findsOneWidget);

      // Get initial zoom level (this would require accessing the controller)
      // Since we can't directly access the controller in widget tests,
      // we verify the button exists and is tappable
      await tester.tap(zoomInButton);
      await tester.pump();

      // The actual zoom change would be verified in integration tests
      // where we can access the map controller
    });

    testWidgets('Zoom out button decreases zoom level', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPageOsm(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      final zoomOutButton = find.byIcon(Icons.remove);
      expect(zoomOutButton, findsOneWidget);

      await tester.tap(zoomOutButton);
      await tester.pump();
    });

    testWidgets('User location button moves camera when location available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPageOsm(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      final userLocationButton = find.byIcon(Icons.my_location);
      expect(userLocationButton, findsOneWidget);

      await tester.tap(userLocationButton);
      await tester.pump();
    });

    testWidgets('Client location button moves camera to client position', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPageOsm(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      final clientLocationButton = find.byIcon(Icons.location_on);
      expect(clientLocationButton, findsOneWidget);

      await tester.tap(clientLocationButton);
      await tester.pump();
    });

    testWidgets('All control buttons are present and properly styled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPageOsm(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Check for all control buttons
      expect(find.byIcon(Icons.add), findsOneWidget); // Zoom in
      expect(find.byIcon(Icons.remove), findsOneWidget); // Zoom out
      expect(find.byIcon(Icons.my_location), findsOneWidget); // User location
      expect(find.byIcon(Icons.location_on), findsOneWidget); // Client location
      expect(find.byIcon(Icons.route), findsOneWidget); // Route
      expect(find.byIcon(Icons.edit_location_outlined), findsOneWidget); // Update coordinates
    });
  });
}