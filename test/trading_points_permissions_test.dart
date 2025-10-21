import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/trading_points_page.dart';
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
              permissions: tradingPointWithPermissions.permissions,
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
              permissions: tradingPointWithPermissions.permissions,
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
              permissions: tradingPointWithPermissions.permissions,
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
              permissions: tradingPointWithPermissions.permissions,
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
              permissions: tradingPointWithPermissions.permissions,
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
              permissions: tradingPointWithPermissions.permissions,
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
              permissions: tradingPointWithPermissions.permissions,
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
  });
}