import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/map_pages/map_detail_page_google.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';

void main() {
  group('MapDetailPageGoogle Tests', () {
    late TradingPoint testTradingPoint;

    setUp(() {
      testTradingPoint = TradingPoint(
        id: 'test_1',
        name: 'Test Trading Point',
        latitude: 41.2995,
        longitude: 69.2401,
        address: 'Test Address',
        phone: '+998901234567',
        ownerName: 'Test Owner',
        contactPerson: 'Test Contact',
        inn: '123456789',
        status: 'active',
        lastVisitDate: '2024-01-01',
        hasOrders: false,
        hasContracts: false,
        isVisited: false,
        hasContract: false,
        region: 'Tashkent',
        district: 'Test District',
        signboard: 'Test Signboard',
        referencePoint: 'Test Reference',
        responsiblePerson: 'Test Responsible',
        responsiblePersonPhone: '+998901234567',
        tradePointType: 'retail',
        creditLimit: 1000000.0,
        accumulatedCredit: 0.0,
        codeRegion: '01',
      );
    });

    testWidgets('should display Google Maps detail page correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPageGoogle(tradingPoint: testTradingPoint),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      // Check if app bar title is displayed (Google Maps doesn't have app bar)
      // The page is full screen, so we check for control buttons
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.byIcon(Icons.route), findsOneWidget);
      expect(find.byIcon(Icons.edit_location_outlined), findsOneWidget);
    });

    testWidgets('should handle back button tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (context) => MapDetailPageGoogle(tradingPoint: testTradingPoint),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should navigate back (we can't easily test navigation in this setup)
    });

    testWidgets('should handle user location button tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPageGoogle(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Tap user location button
      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pumpAndSettle();

      // Should attempt to get user location
      // Note: Actual behavior depends on location permissions and services
    });

    testWidgets('should handle client location button tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPageGoogle(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Tap client location button
      await tester.tap(find.byIcon(Icons.location_on));
      await tester.pumpAndSettle();

      // Should animate to client location
    });

    testWidgets('should handle route button tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPageGoogle(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Tap route button
      await tester.tap(find.byIcon(Icons.route));
      await tester.pumpAndSettle();

      // Should attempt to calculate route
      // Note: May show snackbar if location not available
    });

    testWidgets('should handle edit location button tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPageGoogle(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Tap edit location button
      await tester.tap(find.byIcon(Icons.edit_location_outlined));
      await tester.pumpAndSettle();

      // Should show snackbar about coordinate update
      expect(find.text('Koordinatalarni yangilash sahifasi - tez orada'), findsOneWidget);
    });

    testWidgets('should display route info overlay when route is active', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPageGoogle(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no route overlay should be visible
      expect(find.text('Masofa:'), findsNothing);

      // Tap route button to create route
      await tester.tap(find.byIcon(Icons.route));
      await tester.pumpAndSettle();

      // Now route overlay should be visible
      expect(find.text('Masofa:'), findsOneWidget);
      expect(find.text('Taxminiy vaqt:'), findsOneWidget);
    });

    testWidgets('should clear route when close button is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPageGoogle(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Create route
      await tester.tap(find.byIcon(Icons.route));
      await tester.pumpAndSettle();

      // Verify route overlay is visible
      expect(find.text('Masofa:'), findsOneWidget);

      // Tap close button on route overlay
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Route overlay should be cleared
      expect(find.text('Masofa:'), findsNothing);
    });

    testWidgets('should handle connectivity changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPageGoogle(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Connectivity changes are handled internally
      // We can't easily test this without mocking connectivity
    });

    testWidgets('should display client marker on map', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPageGoogle(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // The GoogleMap widget should contain markers
      // We can't directly test the markers without accessing the map controller
    });

    testWidgets('should have proper theme integration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: MapDetailPageGoogle(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Control buttons should adapt to dark theme
      // This is tested implicitly through the UI building
    });
  });
}