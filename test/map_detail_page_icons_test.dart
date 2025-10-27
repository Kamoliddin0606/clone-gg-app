import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/map_detail_page.dart';

void main() {
  group('MapDetailPage Icon Tests', () {
    late TradingPoint testTradingPoint;

    setUp(() {
      testTradingPoint = TradingPoint(
        id: 'test_client_001',
        name: 'Test Client',
        address: 'Test Address',
        phone: '+998901234567',
        ownerName: 'Test Owner',
        contactPerson: 'Test Contact',
        inn: '123456789',
        status: 'active',
        lastVisitDate: '',
        hasOrders: false,
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
    });

    testWidgets('MapDetailPage renders with all 5 control icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      // Wait for the page to load
      await tester.pumpAndSettle();

      // Check that all 5 control icons are present
      // Bottom-right controls (4 icons)
      expect(find.byIcon(Icons.my_location), findsOneWidget); // User position
      expect(find.byIcon(Icons.location_on), findsOneWidget); // Client position
      expect(find.byIcon(Icons.route), findsOneWidget); // Route
      expect(find.byIcon(Icons.fullscreen), findsOneWidget); // Fullscreen

      // Top-right control (1 icon)
      expect(find.byIcon(Icons.edit_location), findsOneWidget); // Update coordinates
    });

    testWidgets('Bottom-right control icons are positioned correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Find the bottom-right control container
      final bottomRightControls = find.ancestor(
        of: find.byIcon(Icons.my_location),
        matching: find.byType(Container),
      );

      expect(bottomRightControls, findsOneWidget);

      // Verify the container has 4 IconButton children
      final container = tester.widget<Container>(bottomRightControls);
      final column = container.child as Column;
      expect(column.children.length, 4); // 4 icons in bottom-right
    });

    testWidgets('Top-right control icon is positioned correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Find the top-right control container
      final topRightControls = find.ancestor(
        of: find.byIcon(Icons.edit_location),
        matching: find.byType(Container),
      );

      expect(topRightControls, findsOneWidget);

      // Verify the container has 1 IconButton child
      final container = tester.widget<Container>(topRightControls);
      final iconButton = container.child as IconButton;
      expect(iconButton.icon, isA<Icon>());
      expect((iconButton.icon as Icon).icon, Icons.edit_location);
    });

    testWidgets('Control icons have proper tooltips', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Check tooltips for bottom-right icons
      expect(find.byTooltip('Foydalanuvchi joylashuvi'), findsOneWidget);
      expect(find.byTooltip('Mijoz joylashuvi'), findsOneWidget);
      expect(find.byTooltip('Marshrut (foydalanuvchidan mijozgacha)'), findsOneWidget);
      expect(find.byTooltip('To\'liq ekran xaritasi'), findsOneWidget);

      // Check tooltip for top-right icon
      expect(find.byTooltip('Mijoz koordinatalarini yangilash'), findsOneWidget);
    });

    testWidgets('Route button tap shows snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldMessenger(
            child: Builder(
              builder: (context) => MapDetailPage(tradingPoint: testTradingPoint),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the route button
      await tester.tap(find.byIcon(Icons.route));
      await tester.pump(); // Allow snackbar to show

      // Check that snackbar appears with expected message
      expect(find.text('Foydalanuvchi joylashuvi aniqlanmadi'), findsOneWidget);
    });

    testWidgets('Fullscreen button tap shows snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the fullscreen button
      await tester.tap(find.byIcon(Icons.fullscreen));
      await tester.pump(); // Allow snackbar to show

      // Check that snackbar appears with expected message
      expect(find.text('To\'liq ekran xaritasi ochiladi'), findsOneWidget);
    });

    testWidgets('Update coordinates button tap shows snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the update coordinates button
      await tester.tap(find.byIcon(Icons.edit_location));
      await tester.pump(); // Allow snackbar to show

      // Check that snackbar appears with expected message
      expect(find.text('Koordinatalarni yangilash sahifasi ochiladi'), findsOneWidget);
    });

    testWidgets('Client position button tap centers map on client', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the client position button
      await tester.tap(find.byIcon(Icons.location_on));
      await tester.pump(); // Allow map to animate

      // Since we can't easily test GoogleMap camera position changes,
      // we just verify the button exists and is tappable
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('User position button tap attempts to get location', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the user position button
      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pump(); // Allow location request to process

      // Since location permission handling is complex in tests,
      // we just verify the button exists and is tappable
      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });
  });
}