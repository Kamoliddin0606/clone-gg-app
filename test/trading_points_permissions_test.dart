import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/trading_points_page.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_settings.dart' hide MapType;
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

void main() {
  group('TradingPointsPage Permissions Tests', () {
    late TradingPoint testTradingPoint;
    late SalesReqPermissions testPermissions;

    setUp(() {
      testTradingPoint = model.TradingPoint(
        id: 'test_id',
        name: 'Test Trading Point',
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
        accumulatedCredit: 50000.0,
        codeRegion: '01',
        visitToday: true, // Set to true for visit button tests
        visitStepNumber: 1,
      );

      testPermissions = SalesReqPermissions(
        userCode: 'test_user',
        skipTINduplicateCheck: false,
        allowCreationWithoutTIN: false,
        allowCreatingPointOfSale: false,
        visit: true,
        strictSequence: false,
        unplannedOrder: true,
        plannedRoute: false,
        editClientCoordinates: false,
        visitSteps: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('Visit button enabled when permissions.visit is true', (WidgetTester tester) async {
      final tradingPointWithPermissions = TradingPointWithPermissions(
        tradingPoint: testTradingPoint,
        permissions: testPermissions,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TradingPointCard(
              tradingPoint: tradingPointWithPermissions.tradingPoint,
              onCall: () {},
              onInformVisit: () {},
              onCreateOrder: () {},
              onViewContracts: () {},
              onRefusal: () {},
              onOpenDetails: () {},
              regionNames: const {},
              locationService: null,
              permissions: tradingPointWithPermissions.permissions,
              mapProvider: MapProvider.google,
            ),
          ),
        ),
      );

      // Find the visit button
      final visitButton = find.widgetWithText(FilledButton, 'Tashrif buyurish');
      expect(visitButton, findsOneWidget);

      // Check that the button is enabled (onPressed is not null)
      final FilledButton button = tester.widget(visitButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Visit button disabled when permissions.visit is false', (WidgetTester tester) async {
      final permissionsWithNoVisit = SalesReqPermissions(
        userCode: 'test_user',
        skipTINduplicateCheck: false,
        allowCreationWithoutTIN: false,
        allowCreatingPointOfSale: false,
        visit: false, // Disabled
        strictSequence: false,
        unplannedOrder: true,
        plannedRoute: false,
        editClientCoordinates: false,
        visitSteps: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final tradingPointWithPermissions = TradingPointWithPermissions(
        tradingPoint: testTradingPoint,
        permissions: permissionsWithNoVisit,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TradingPointCard(
              tradingPoint: tradingPointWithPermissions.tradingPoint,
              onCall: () {},
              onInformVisit: () {},
              onCreateOrder: () {},
              onViewContracts: () {},
              onRefusal: () {},
              onOpenDetails: () {},
              regionNames: const {},
              locationService: null,
              permissions: tradingPointWithPermissions.permissions,
              mapProvider: MapProvider.google,
            ),
          ),
        ),
      );

      // Find the visit button
      final visitButton = find.widgetWithText(FilledButton, 'Tashrif buyurish');
      expect(visitButton, findsOneWidget);

      // Check that the button is disabled (onPressed is null)
      final FilledButton button = tester.widget(visitButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('Visit button disabled when permissions is null', (WidgetTester tester) async {
      final tradingPointWithPermissions = TradingPointWithPermissions(
        tradingPoint: testTradingPoint,
        permissions: null, // Null permissions
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TradingPointCard(
              tradingPoint: tradingPointWithPermissions.tradingPoint,
              onCall: () {},
              onInformVisit: () {},
              onCreateOrder: () {},
              onViewContracts: () {},
              onRefusal: () {},
              onOpenDetails: () {},
              regionNames: const {},
              locationService: null,
              permissions: tradingPointWithPermissions.permissions,
              mapProvider: MapProvider.google,
            ),
          ),
        ),
      );

      // Expand the card to show buttons
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // Find the visit button
      final visitButton = find.widgetWithText(FilledButton, 'Tashrif buyurish');
      expect(visitButton, findsOneWidget);

      // Check that the button is disabled (onPressed is null)
      final FilledButton button = tester.widget(visitButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('Unplanned order button enabled when permissions.unplannedOrder is true', (WidgetTester tester) async {
      final tradingPointWithPermissions = TradingPointWithPermissions(
        tradingPoint: testTradingPoint,
        permissions: testPermissions,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TradingPointCard(
              tradingPoint: tradingPointWithPermissions.tradingPoint,
              onCall: () {},
              onInformVisit: () {},
              onCreateOrder: () {},
              onViewContracts: () {},
              onRefusal: () {},
              onOpenDetails: () {},
              regionNames: const {},
              locationService: null,
              permissions: tradingPointWithPermissions.permissions,
              mapProvider: MapProvider.google,
            ),
          ),
        ),
      );

      // Find the unplanned order button
      final orderButton = find.widgetWithText(FilledButton, 'Rejadan tashqari buyurtma');
      expect(orderButton, findsOneWidget);

      // Check that the button is enabled
      final FilledButton button = tester.widget(orderButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Unplanned order button disabled when permissions.unplannedOrder is false', (WidgetTester tester) async {
      final permissionsWithNoOrder = SalesReqPermissions(
        userCode: 'test_user',
        skipTINduplicateCheck: false,
        allowCreationWithoutTIN: false,
        allowCreatingPointOfSale: false,
        visit: true,
        strictSequence: false,
        unplannedOrder: false, // Disabled
        plannedRoute: false,
        editClientCoordinates: false,
        visitSteps: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final tradingPointWithPermissions = TradingPointWithPermissions(
        tradingPoint: testTradingPoint,
        permissions: permissionsWithNoOrder,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TradingPointCard(
              tradingPoint: tradingPointWithPermissions.tradingPoint,
              onCall: () {},
              onInformVisit: () {},
              onCreateOrder: () {},
              onViewContracts: () {},
              onRefusal: () {},
              onOpenDetails: () {},
              regionNames: const {},
              locationService: null,
              permissions: tradingPointWithPermissions.permissions,
              mapProvider: MapProvider.google,
            ),
          ),
        ),
      );

      // Find the unplanned order button
      final orderButton = find.widgetWithText(FilledButton, 'Rejadan tashqari buyurtma');
      expect(orderButton, findsOneWidget);

      // Check that the button is disabled
      final FilledButton button = tester.widget(orderButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('Contracts button disabled when trading point has no contract', (WidgetTester tester) async {
      final tradingPointWithoutContract = testTradingPoint.copyWith(hasContract: false);

      final tradingPointWithPermissions = TradingPointWithPermissions(
        tradingPoint: tradingPointWithoutContract,
        permissions: testPermissions,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TradingPointCard(
              tradingPoint: tradingPointWithPermissions.tradingPoint,
              onCall: () {},
              onInformVisit: () {},
              onCreateOrder: () {},
              onViewContracts: () {},
              onRefusal: () {},
              onOpenDetails: () {},
              regionNames: const {},
              locationService: null,
              permissions: tradingPointWithPermissions.permissions,
              mapProvider: MapProvider.google,
            ),
          ),
        ),
      );

      // Find the contracts button
      final contractsButton = find.widgetWithText(OutlinedButton, 'Shartnomalar');
      expect(contractsButton, findsOneWidget);

      // Check that the button is disabled
      final OutlinedButton button = tester.widget(contractsButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('Contracts button enabled when trading point has contract', (WidgetTester tester) async {
      final tradingPointWithContract = testTradingPoint.copyWith(hasContract: true);

      final tradingPointWithPermissions = TradingPointWithPermissions(
        tradingPoint: tradingPointWithContract,
        permissions: testPermissions,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TradingPointCard(
              tradingPoint: tradingPointWithPermissions.tradingPoint,
              onCall: () {},
              onInformVisit: () {},
              onCreateOrder: () {},
              onViewContracts: () {},
              onRefusal: () {},
              onOpenDetails: () {},
              regionNames: const {},
              locationService: null,
              permissions: tradingPointWithPermissions.permissions,
              mapProvider: MapProvider.google,
            ),
          ),
        ),
      );

      // Find the contracts button
      final contractsButton = find.widgetWithText(OutlinedButton, 'Shartnomalar');
      expect(contractsButton, findsOneWidget);

      // Check that the button is enabled
      final OutlinedButton button = tester.widget(contractsButton);
      expect(button.onPressed, isNotNull);
    });

    test('TradingPointWithPermissions.fromMap correctly parses new SalesReqPermissions fields', () {
      // Test data with new fields
      final map = {
        'code': 'test_id',
        'name': 'Test Trading Point',
        'address': 'Test Address',
        'phone': '+998901234567',
        'owner_name': 'Test Owner',
        'contact_person': 'Test Contact',
        'inn': '123456789',
        'status': 'active',
        'last_visit_date': '',
        'has_orders': 0,
        'has_contracts': 0,
        'is_visited': 0,
        'has_contract': 0,
        'latitude': 41.2995,
        'longitude': 69.2401,
        'region': 'Tashkent',
        'district': 'Yunusabad',
        'signboard': 'Test Signboard',
        'reference_point': 'Test Reference',
        'responsible_person': 'Test Responsible',
        'responsible_person_phone': '+998909876543',
        'trade_point_type': 'Retail',
        'credit_limit': 1000000.0,
        'accumulated_credit': 50000.0,
        'code_region': '01',
        'visit_today': 1,
        'visit_step_number': 1,
        'planned_week_day': 'Monday',
        // Permissions data
        'permissions_id': 1,
        'user_code': 'test_user',
        'skip_tin_duplicate_check': 0,
        'allow_creation_without_tin': 0,
        'allow_creating_point_of_sale': 0,
        'visit': 1,
        'strict_sequence': 0,
        'unplanned_order': 1,
        'planned_route': 0,
        'edit_client_coordinates': 0,
        // New fields
        'client_zone_access': 5,
        'location_update_interval': 30,
      };

      final result = TradingPointWithPermissions.fromMap(map);

      expect(result.permissions, isNotNull);
      expect(result.permissions!.clientZoneAccess, 5);
      expect(result.permissions!.locationUpdateInterval, 30);
    });
  });
}