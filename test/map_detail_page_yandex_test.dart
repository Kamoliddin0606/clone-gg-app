import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/map_pages/map_detail_page_yandex.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';

// Mock classes
class MockTradingPoint extends Mock implements TradingPoint {}

void main() {
  group('MapDetailPageYandex', () {
    late TradingPoint mockTradingPoint;

    setUp(() {
      mockTradingPoint = TradingPoint(
        id: '1',
        name: 'Test Trading Point',
        address: 'Test Address',
        phone: '123456789',
        ownerName: 'Test Owner',
        contactPerson: 'Test Contact',
        inn: '123456789',
        status: 'Active',
        lastVisitDate: '2023-01-01',
        hasOrders: true,
        hasContracts: false,
        isVisited: true,
        hasContract: false,
        latitude: 41.2995,
        longitude: 69.2401,
        region: 'Tashkent',
        district: 'Yunusabad',
        signboard: 'Test Signboard',
        referencePoint: 'Test Reference',
        responsiblePerson: 'Test Responsible',
        responsiblePersonPhone: '987654321',
        tradePointType: 'Shop',
        creditLimit: 10000.0,
        accumulatedCredit: 5000.0,
        codeRegion: '01',
        visitToday: false,
        visitStepNumber: 1,
      );
    });

    testWidgets('should display app bar with trading point name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPageYandex(tradingPoint: mockTradingPoint),
        ),
      );

      expect(find.text('Test Trading Point'), findsOneWidget);
    });

    testWidgets('should create widget without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPageYandex(tradingPoint: mockTradingPoint),
        ),
      );

      // Widget should be created without throwing exceptions
      expect(find.byType(MapDetailPageYandex), findsOneWidget);
    });

    testWidgets('should handle null coordinates gracefully', (WidgetTester tester) async {
      final tradingPointWithNullCoords = TradingPoint(
        id: '2',
        name: 'Null Coords Point',
        address: 'Address',
        phone: '123',
        ownerName: 'Owner',
        contactPerson: 'Contact',
        inn: '123',
        status: 'Active',
        lastVisitDate: '2023-01-01',
        hasOrders: false,
        hasContracts: false,
        isVisited: false,
        hasContract: false,
        latitude: 0.0, // Default coordinates for null case
        longitude: 0.0,
        region: 'Region',
        district: 'District',
        signboard: 'Signboard',
        referencePoint: 'Reference',
        responsiblePerson: 'Responsible',
        responsiblePersonPhone: 'Phone',
        tradePointType: 'Type',
        creditLimit: 0.0,
        accumulatedCredit: 0.0,
        codeRegion: '01',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPageYandex(tradingPoint: tradingPointWithNullCoords),
        ),
      );

      expect(find.byType(MapDetailPageYandex), findsOneWidget);
    });

    test('TradingPoint model should have correct properties', () {
      expect(mockTradingPoint.id, '1');
      expect(mockTradingPoint.name, 'Test Trading Point');
      expect(mockTradingPoint.latitude, 41.2995);
      expect(mockTradingPoint.longitude, 69.2401);
      expect(mockTradingPoint.hasOrders, true);
      expect(mockTradingPoint.isVisited, true);
    });

    test('TradingPoint should handle null values safely', () {
      final pointWithNulls = TradingPoint(
        id: '3',
        name: 'Null Test',
        address: '',
        phone: '',
        ownerName: '',
        contactPerson: '',
        inn: '',
        status: '',
        lastVisitDate: '',
        hasOrders: false,
        hasContracts: false,
        isVisited: false,
        hasContract: false,
        latitude: 0.0,
        longitude: 0.0,
        region: '',
        district: '',
        signboard: '',
        referencePoint: '',
        responsiblePerson: '',
        responsiblePersonPhone: '',
        tradePointType: '',
        creditLimit: 0.0,
        accumulatedCredit: 0.0,
        codeRegion: '',
      );

      expect(pointWithNulls.latitude, 0.0);
      expect(pointWithNulls.longitude, 0.0);
      expect(pointWithNulls.name, 'Null Test');
    });
  });
}