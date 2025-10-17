import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/trading_points_page.dart' as page;
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;
import 'package:gloria_marketing_flutter/src/core/services/location_service.dart';

// Use the model alias
typedef TradingPoint = model.TradingPoint;

// Mock classes
class MockLocationService extends Mock implements LocationService {}

void main() {
  group('TradingPointsPage Distance Overlay Tests', () {
    late MockLocationService mockLocationService;

    setUp(() {
      mockLocationService = MockLocationService();
    });

    testWidgets('should display distance overlay on grid view cards when location service is available',
        (WidgetTester tester) async {
      // Arrange
      final tradingPoint = TradingPoint(
        id: '1',
        name: 'Test Client',
        address: 'Test Address',
        phone: '123456789',
        inn: '123456789',
        latitude: 41.2995,
        longitude: 69.2401,
        codeRegion: '01',
        contactPerson: 'Test Contact',
        ownerName: 'Test Owner',
        isVisited: false,
        hasContract: false,
        tradePointType: 'Retail',
        region: 'Tashkent',
        district: 'Center',
        responsiblePerson: 'Test Responsible',
        responsiblePersonPhone: '987654321',
        signboard: 'Test Signboard',
        referencePoint: 'Test Reference',
      );

      // Mock location service to return a distance
      when(mockLocationService.getDistanceToTradingPoint(41.2995, 69.2401))
          .thenReturn(2.5);

      // Create a test widget that includes the grid tile
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: page._TradingPointGridTile(
              tp: tradingPoint,
              onCall: () {},
              onInformVisit: () {},
              onCreateOrder: () {},
              onViewContracts: () {},
              onRefusal: () {},
              onOpenDetails: () {},
              locationService: mockLocationService,
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      // Check that the distance overlay is displayed
      expect(find.text('2.5km'), findsOneWidget);

      // Check that the overlay has the correct styling (semi-transparent background)
      final containerFinder = find.ancestor(
        of: find.text('2.5km'),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsOneWidget);

      final Container container = tester.widget(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.black.withOpacity(0.7));
    });

    testWidgets('should not display distance overlay when location service is null',
        (WidgetTester tester) async {
      // Arrange
      final tradingPoint = TradingPoint(
        id: '1',
        name: 'Test Client',
        address: 'Test Address',
        phone: '123456789',
        inn: '123456789',
        latitude: 41.2995,
        longitude: 69.2401,
        codeRegion: '01',
        contactPerson: 'Test Contact',
        ownerName: 'Test Owner',
        isVisited: false,
        hasContract: false,
        tradePointType: 'Retail',
        region: 'Tashkent',
        district: 'Center',
        responsiblePerson: 'Test Responsible',
        responsiblePersonPhone: '987654321',
        signboard: 'Test Signboard',
        referencePoint: 'Test Reference',
        status: 'Active',
        lastVisitDate: '',
        hasOrders: false,
        hasContracts: false,
        creditLimit: 0.0,
        accumulatedCredit: 0.0,
      );

      // Create a test widget with null location service
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: page._TradingPointGridTile(
              tp: tradingPoint,
              onCall: () {},
              onInformVisit: () {},
              onCreateOrder: () {},
              onViewContracts: () {},
              onRefusal: () {},
              onOpenDetails: () {},
              locationService: null, // No location service
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      // Check that no distance text is displayed
      expect(find.textContaining('km'), findsNothing);
    });

    testWidgets('should not display distance overlay when distance is null',
        (WidgetTester tester) async {
      // Arrange
      final tradingPoint = TradingPoint(
        id: '1',
        name: 'Test Client',
        address: 'Test Address',
        phone: '123456789',
        inn: '123456789',
        latitude: 41.2995,
        longitude: 69.2401,
        codeRegion: '01',
        contactPerson: 'Test Contact',
        ownerName: 'Test Owner',
        isVisited: false,
        hasContract: false,
        tradePointType: 'Retail',
        region: 'Tashkent',
        district: 'Center',
        responsiblePerson: 'Test Responsible',
        responsiblePersonPhone: '987654321',
        signboard: 'Test Signboard',
        referencePoint: 'Test Reference',
        status: 'Active',
        lastVisitDate: '',
        hasOrders: false,
        hasContracts: false,
        creditLimit: 0.0,
        accumulatedCredit: 0.0,
      );

      // Mock location service to return null distance
      when(mockLocationService.getDistanceToTradingPoint(41.2995, 69.2401))
          .thenReturn(null);

      // Create a test widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: page._TradingPointGridTile(
              tp: tradingPoint,
              onCall: () {},
              onInformVisit: () {},
              onCreateOrder: () {},
              onViewContracts: () {},
              onRefusal: () {},
              onOpenDetails: () {},
              locationService: mockLocationService,
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      // Check that no distance text is displayed
      expect(find.textContaining('km'), findsNothing);
    });

    testWidgets('should format distance correctly for different ranges',
        (WidgetTester tester) async {
      // Test cases for different distance ranges
      final testCases = [
        {'distance': 0.5, 'expected': '0.5km'},
        {'distance': 2.3, 'expected': '2.3km'},
        {'distance': 15.7, 'expected': '15.7km'},
      ];

      for (final testCase in testCases) {
        final distance = testCase['distance'] as double;
        final expectedText = testCase['expected'] as String;

        final tradingPoint = TradingPoint(
          id: '1',
          name: 'Test Client',
          address: 'Test Address',
          phone: '123456789',
          inn: '123456789',
          latitude: 41.2995,
          longitude: 69.2401,
          codeRegion: '01',
          contactPerson: 'Test Contact',
          ownerName: 'Test Owner',
          isVisited: false,
          hasContract: false,
          tradePointType: 'Retail',
          region: 'Tashkent',
          district: 'Center',
          responsiblePerson: 'Test Responsible',
          responsiblePersonPhone: '987654321',
          signboard: 'Test Signboard',
          referencePoint: 'Test Reference',
        );

        // Mock location service
        when(mockLocationService.getDistanceToTradingPoint(41.2995, 69.2401))
            .thenReturn(distance);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TradingPointGridTile(
                tp: tradingPoint,
                onCall: () {},
                onInformVisit: () {},
                onCreateOrder: () {},
                onViewContracts: () {},
                onRefusal: () {},
                onOpenDetails: () {},
                locationService: mockLocationService,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.text(expectedText), findsOneWidget);
      }
    });
  });
}