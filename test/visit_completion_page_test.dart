import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/visit_completion_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

// Mock classes
class MockApiDatabaseService extends Mock implements ApiDatabaseService {}
class MockSharedPreferencesService extends Mock implements SharedPreferencesService {}

void main() {
  late MockApiDatabaseService mockApiDbService;
  late MockSharedPreferencesService mockPrefsService;

  setUp(() {
    mockApiDbService = MockApiDatabaseService();
    mockPrefsService = MockSharedPreferencesService();

    // Register mocks with GetIt
    GetIt.I.registerSingleton<ApiDatabaseService>(mockApiDbService);
    GetIt.I.registerSingleton<SharedPreferencesService>(mockPrefsService);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  group('VisitCompletionPage', () {
    testWidgets('should display completion page with completed steps', (WidgetTester tester) async {
      // Arrange
      final tradingPoint = TradingPointWithPermissions(
        tradingPoint: const TradingPoint(
          id: 'client_123',
          name: 'Test Client',
          address: 'Test Address',
          latitude: 41.2995,
          longitude: 69.2401,
          phone: '+998901234567',
          ownerName: 'Test Owner',
          contactPerson: 'Test Contact',
          inn: '123456789',
          status: 'active',
          lastVisitDate: null,
          hasOrders: false,
          hasContracts: false,
          isVisited: false,
          hasContract: false,
          signboard: 'Test Signboard',
          referencePoint: 'Test Reference',
          responsiblePerson: 'Test Responsible',
          responsiblePersonPhone: '+998987654321',
          creditLimit: 1000000.0,
          accumulatedCredit: 0.0,
          codeRegion: 'region_1',
        ),
        permissions: SalesReqPermissions(
          userCode: 'user_123',
          skipTINduplicateCheck: false,
          allowCreationWithoutTIN: false,
          allowCreatingPointOfSale: false,
          visit: true,
          strictSequence: false,
          unplannedOrder: true,
          plannedRoute: true,
          editClientCoordinates: false,
          clientZoneAccess: 0,
          locationUpdateInterval: 0,
          visitSteps: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        visitStepNumber: 1,
      );

      final permissions = SalesReqPermissions(
        userCode: 'user_123',
        skipTINduplicateCheck: false,
        allowCreationWithoutTIN: false,
        allowCreatingPointOfSale: false,
        visit: true,
        strictSequence: false,
        unplannedOrder: true,
        plannedRoute: true,
        editClientCoordinates: false,
        clientZoneAccess: 0,
        locationUpdateInterval: 0,
        visitSteps: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final completedSteps = [
        VisitStepProgress(
          step: VisitStep(
            stepCode: 1,
            stepName: 'Photo Before',
            stepRequired: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          status: VisitStepStatus.completed,
          notes: 'Photos taken successfully',
          completedAt: DateTime.now(),
        ),
        VisitStepProgress(
          step: VisitStep(
            stepCode: 2,
            stepName: 'Create Order',
            stepRequired: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          status: VisitStepStatus.completed,
          notes: 'Order created with 5 items',
          completedAt: DateTime.now(),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: VisitCompletionPage(
            tradingPoint: tradingPoint,
            permissions: permissions,
            completedSteps: completedSteps,
          ),
        ),
      );

      // Assert
      expect(find.text('Tashrif yakunlandi!'), findsOneWidget);
      expect(find.text('2 ta bosqich bajarildi'), findsOneWidget);
      expect(find.text('Photo Before'), findsOneWidget);
      expect(find.text('Create Order'), findsOneWidget);
      expect(find.text('Photos taken successfully'), findsOneWidget);
      expect(find.text('Order created with 5 items'), findsOneWidget);
      expect(find.text('Bosh sahifaga qaytish'), findsOneWidget);
    });

    testWidgets('should display success header with correct information', (WidgetTester tester) async {
      // Arrange
      final tradingPoint = TradingPointWithPermissions(
        tradingPoint: const TradingPoint(
          id: 'client_123',
          name: 'Test Client',
          address: 'Test Address',
          latitude: 41.2995,
          longitude: 69.2401,
          phone: '+998901234567',
          ownerName: 'Test Owner',
          contactPerson: 'Test Contact',
          inn: '123456789',
          status: 'active',
          lastVisitDate: null,
          hasOrders: false,
          hasContracts: false,
          isVisited: false,
          hasContract: false,
          signboard: 'Test Signboard',
          referencePoint: 'Test Reference',
          responsiblePerson: 'Test Responsible',
          responsiblePersonPhone: '+998987654321',
          creditLimit: 1000000.0,
          accumulatedCredit: 0.0,
          codeRegion: 'region_1',
        ),
        permissions: SalesReqPermissions(
          userCode: 'user_123',
          skipTINduplicateCheck: false,
          allowCreationWithoutTIN: false,
          allowCreatingPointOfSale: false,
          visit: true,
          strictSequence: false,
          unplannedOrder: true,
          plannedRoute: true,
          editClientCoordinates: false,
          clientZoneAccess: 0,
          locationUpdateInterval: 0,
          visitSteps: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        visitStepNumber: 1,
      );

      final permissions = SalesReqPermissions(
        userCode: 'user_123',
        skipTINduplicateCheck: false,
        allowCreationWithoutTIN: false,
        allowCreatingPointOfSale: false,
        visit: true,
        strictSequence: false,
        unplannedOrder: true,
        plannedRoute: true,
        editClientCoordinates: false,
        clientZoneAccess: 0,
        locationUpdateInterval: 0,
        visitSteps: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final completedSteps = [
        VisitStepProgress(
          step: VisitStep(
            stepCode: 1,
            stepName: 'Test Step',
            stepRequired: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          status: VisitStepStatus.completed,
          completedAt: DateTime.now(),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: VisitCompletionPage(
            tradingPoint: tradingPoint,
            permissions: permissions,
            completedSteps: completedSteps,
          ),
        ),
      );

      // Assert
      expect(find.text('Test Client'), findsOneWidget);
      expect(find.text('Test Address'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets); // Success icon and step icons
    });

    testWidgets('should show close button that navigates back', (WidgetTester tester) async {
      // Arrange
      final tradingPoint = TradingPointWithPermissions(
        tradingPoint: const TradingPoint(
          id: 'client_123',
          name: 'Test Client',
          address: 'Test Address',
          latitude: 41.2995,
          longitude: 69.2401,
          phone: '+998901234567',
          ownerName: 'Test Owner',
          contactPerson: 'Test Contact',
          inn: '123456789',
          status: 'active',
          lastVisitDate: null,
          hasOrders: false,
          hasContracts: false,
          isVisited: false,
          hasContract: false,
          signboard: 'Test Signboard',
          referencePoint: 'Test Reference',
          responsiblePerson: 'Test Responsible',
          responsiblePersonPhone: '+998987654321',
          creditLimit: 1000000.0,
          accumulatedCredit: 0.0,
          codeRegion: 'region_1',
        ),
        permissions: SalesReqPermissions(
          userCode: 'user_123',
          skipTINduplicateCheck: false,
          allowCreationWithoutTIN: false,
          allowCreatingPointOfSale: false,
          visit: true,
          strictSequence: false,
          unplannedOrder: true,
          plannedRoute: true,
          editClientCoordinates: false,
          clientZoneAccess: 0,
          locationUpdateInterval: 0,
          visitSteps: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        visitStepNumber: 1,
      );

      final permissions = SalesReqPermissions(
        userCode: 'user_123',
        skipTINduplicateCheck: false,
        allowCreationWithoutTIN: false,
        allowCreatingPointOfSale: false,
        visit: true,
        strictSequence: false,
        unplannedOrder: true,
        plannedRoute: true,
        editClientCoordinates: false,
        clientZoneAccess: 0,
        locationUpdateInterval: 0,
        visitSteps: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final completedSteps = [
        VisitStepProgress(
          step: VisitStep(
            stepCode: 1,
            stepName: 'Test Step',
            stepRequired: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          status: VisitStepStatus.completed,
          completedAt: DateTime.now(),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (_) => VisitCompletionPage(
                tradingPoint: tradingPoint,
                permissions: permissions,
                completedSteps: completedSteps,
              ),
            ),
          ),
        ),
      );

      // Find and tap the close button
      final closeButton = find.text('Yopish');
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // The test will pass if no exceptions are thrown
    });
  });
}