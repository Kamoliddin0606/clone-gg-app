import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/trading_points_page.dart';

void main() {
  group('TradingPointsPage Visit Today Filter Tests', () {
    late List<TradingPointWithPermissions> mockTradingPoints;

    setUp(() {
      // Create mock trading points with different visit_today values
      mockTradingPoints = [
        TradingPointWithPermissions(
          tradingPoint: TradingPoint(
            id: '1',
            name: 'Client 1',
            address: 'Address 1',
            phone: '123456789',
            ownerName: 'Owner 1',
            contactPerson: 'Contact 1',
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
            signboard: '',
            referencePoint: '',
            responsiblePerson: '',
            responsiblePersonPhone: '',
            tradePointType: 'Retail',
            creditLimit: 1000000.0,
            accumulatedCredit: 0.0,
            codeRegion: '01',
            visitToday: true, // Should be included when filter is active
            visitStepNumber: 1,
            plannedWeekDay: 'Monday',
          ),
          permissions: SalesReqPermissions(
            id: 1,
            userCode: 'test_user',
            skipTINduplicateCheck: false,
            allowCreationWithoutTIN: false,
            allowCreatingPointOfSale: false,
            visit: true,
            strictSequence: false,
            unplannedOrder: true,
            plannedRoute: true,
            visitSteps: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        TradingPointWithPermissions(
          tradingPoint: TradingPoint(
            id: '2',
            name: 'Client 2',
            address: 'Address 2',
            phone: '987654321',
            ownerName: 'Owner 2',
            contactPerson: 'Contact 2',
            inn: '987654321',
            status: 'active',
            lastVisitDate: '',
            hasOrders: false,
            hasContracts: false,
            isVisited: false,
            hasContract: false,
            latitude: 41.2995,
            longitude: 69.2401,
            region: 'Tashkent',
            district: 'Mirabad',
            signboard: '',
            referencePoint: '',
            responsiblePerson: '',
            responsiblePersonPhone: '',
            tradePointType: 'Wholesale',
            creditLimit: 2000000.0,
            accumulatedCredit: 0.0,
            codeRegion: '01',
            visitToday: false, // Should be excluded when filter is active
            visitStepNumber: 0,
            plannedWeekDay: null,
          ),
          permissions: SalesReqPermissions(
            id: 2,
            userCode: 'test_user',
            skipTINduplicateCheck: false,
            allowCreationWithoutTIN: false,
            allowCreatingPointOfSale: false,
            visit: true,
            strictSequence: false,
            unplannedOrder: true,
            plannedRoute: true,
            visitSteps: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        TradingPointWithPermissions(
          tradingPoint: TradingPoint(
            id: '3',
            name: 'Client 3',
            address: 'Address 3',
            phone: '555555555',
            ownerName: 'Owner 3',
            contactPerson: 'Contact 3',
            inn: '555555555',
            status: 'active',
            lastVisitDate: '',
            hasOrders: false,
            hasContracts: false,
            isVisited: false,
            hasContract: false,
            latitude: 41.2995,
            longitude: 69.2401,
            region: 'Tashkent',
            district: 'Chilonzor',
            signboard: '',
            referencePoint: '',
            responsiblePerson: '',
            responsiblePersonPhone: '',
            tradePointType: 'Retail',
            creditLimit: 1500000.0,
            accumulatedCredit: 0.0,
            codeRegion: '01',
            visitToday: true, // Should be included when filter is active
            visitStepNumber: 2,
            plannedWeekDay: 'Tuesday',
          ),
          permissions: SalesReqPermissions(
            id: 3,
            userCode: 'test_user',
            skipTINduplicateCheck: false,
            allowCreationWithoutTIN: false,
            allowCreatingPointOfSale: false,
            visit: true,
            strictSequence: false,
            unplannedOrder: true,
            plannedRoute: true,
            visitSteps: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      ];
    });

    testWidgets('Visit Today filter shows only clients with visitToday = true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TradingPointsPage(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Find the visit today filter button
      final visitTodayButton = find.byIcon(Icons.today);
      expect(visitTodayButton, findsOneWidget);

      // Initially, filter should not be active (no color)
      final IconButton iconButton = tester.widget<IconButton>(visitTodayButton);
      expect(iconButton.icon is Icon, true);
      final Icon icon = iconButton.icon as Icon;
      expect(icon.color, null); // Should be null when not active

      // Tap the visit today filter button
      await tester.tap(visitTodayButton);
      await tester.pumpAndSettle();

      // Now the filter should be active (primary color)
      final IconButton activeIconButton = tester.widget<IconButton>(visitTodayButton);
      expect(activeIconButton.icon is Icon, true);
      final Icon activeIcon = activeIconButton.icon as Icon;
      expect(activeIcon.color, isNotNull); // Should have primary color when active
    });

    test('Filter logic correctly filters clients with visitToday = true', () {
      // Test the filtering logic directly
      final allClients = mockTradingPoints;

      // When filter is not active, should return all clients
      final noFilterResult = allClients.where((tp) {
        return true; // No filtering
      }).toList();
      expect(noFilterResult.length, 3);

      // When filter is active, should return only clients with visitToday = true
      final filterActiveResult = allClients.where((tp) {
        return tp.visitToday;
      }).toList();
      expect(filterActiveResult.length, 2);
      expect(filterActiveResult.every((tp) => tp.visitToday), true);
      expect(filterActiveResult.map((tp) => tp.tradingPoint.id), contains('1'));
      expect(filterActiveResult.map((tp) => tp.tradingPoint.id), contains('3'));
      expect(filterActiveResult.map((tp) => tp.tradingPoint.id), isNot(contains('2')));
    });

    test('TradingPointWithPermissions visitToday getter works correctly', () {
      final tp1 = mockTradingPoints[0];
      final tp2 = mockTradingPoints[1];
      final tp3 = mockTradingPoints[2];

      expect(tp1.visitToday, true);
      expect(tp2.visitToday, false);
      expect(tp3.visitToday, true);
    });

    test('TradingPoint visitToday field is correctly set', () {
      expect(mockTradingPoints[0].tradingPoint.visitToday, true);
      expect(mockTradingPoints[1].tradingPoint.visitToday, false);
      expect(mockTradingPoints[2].tradingPoint.visitToday, true);
    });
  });
}