import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/map_detail_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';

void main() {
  group('MapDetailPage Integration Tests', () {
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

    testWidgets('should display map detail page correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      // Check if app bar title is displayed
      expect(find.text(testTradingPoint.name), findsOneWidget);

      // Check if control buttons are present
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.byIcon(Icons.route), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
      expect(find.byIcon(Icons.edit_location_outlined), findsOneWidget);
    });

    testWidgets('should handle my_location button tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Tap my location button
      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pumpAndSettle();

      // Should show snackbar or handle location request
      // Note: Actual behavior depends on location permissions
    });

    testWidgets('should handle client_location button tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
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
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Tap route button
      await tester.tap(find.byIcon(Icons.route));
      await tester.pumpAndSettle();

      // Should attempt to calculate route
      // Note: May show snackbar if location not available
    });

    testWidgets('should handle fullscreen button tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Tap fullscreen button
      await tester.tap(find.byIcon(Icons.fullscreen));
      await tester.pumpAndSettle();

      // Should show snackbar about fullscreen (placeholder implementation)
      expect(find.text('To\'liq ekran xaritasi - amalga oshirilmoqda'), findsOneWidget);
    });

    testWidgets('should handle edit_location button tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Tap edit location button
      await tester.tap(find.byIcon(Icons.edit_location_outlined));
      await tester.pumpAndSettle();

      // Should show snackbar about camera movement
      expect(find.text('Mijoz joylashuviga kamera o\'tkazildi'), findsOneWidget);
    });

    testWidgets('should auto-collapse controls after 3 seconds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Initially controls should be expanded
      expect(find.byIcon(Icons.unfold_more), findsNothing); // Not collapsed yet

      // Wait for auto-collapse (3 seconds)
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Should show collapsed state with unfold_more icon
      expect(find.byIcon(Icons.unfold_more), findsOneWidget);
    });

    testWidgets('should expand controls when collapsed button tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Wait for auto-collapse
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Tap expand button
      await tester.tap(find.byIcon(Icons.unfold_more));
      await tester.pumpAndSettle();

      // Should show expanded controls
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.byIcon(Icons.route), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
    });

    testWidgets('should reset idle timer on any interaction', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Wait for 2 seconds
      await tester.pump(const Duration(seconds: 2));

      // Tap any control button to reset timer
      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pumpAndSettle();

      // Wait another 2 seconds (should not collapse yet)
      await tester.pump(const Duration(seconds: 2));

      // Controls should still be expanded
      expect(find.byIcon(Icons.unfold_more), findsNothing);
    });
  });
}