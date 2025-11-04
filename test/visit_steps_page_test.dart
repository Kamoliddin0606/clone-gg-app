import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/visit_steps_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';

// Mock classes
class MockDataSyncService extends Mock implements DataSyncService {}

void main() {
  late MockDataSyncService mockDataSyncService;

  setUp(() {
    mockDataSyncService = MockDataSyncService();
  });

  group('VisitStepsPage', () {
    testWidgets('should render VisitStepsPage correctly', (WidgetTester tester) async {
      // Create test data
      final permissions = SalesReqPermissions(
        userCode: 'test_user',
        skipTINduplicateCheck: false,
        allowCreationWithoutTIN: false,
        allowCreatingPointOfSale: false,
        visit: true,
        strictSequence: true,
        unplannedOrder: false,
        plannedRoute: false,
        editClientCoordinates: false,
        visitSteps: [
          VisitStep(stepCode: 1, stepName: 'Step 1', stepRequired: true),
          VisitStep(stepCode: 2, stepName: 'Step 2', stepRequired: false),
        ],
      );

      final tradingPoint = TradingPointWithPermissions(
        tradingPoint: model.TradingPoint(
          id: '1',
          name: 'Test Client',
          address: 'Test Address',
          phone: '+998901234567',
          contactPerson: 'Test Person',
          ownerName: 'Test Owner',
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
          tradePointType: 'Shop',
          creditLimit: 1000000.0,
          accumulatedCredit: 0.0,
          codeRegion: '01',
        ),
        permissions: permissions,
      );

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => VisitStepsBloc(dataSyncService: mockDataSyncService)
              ..add(LoadVisitSteps(tradingPoint)),
            child: VisitStepsPage(tradingPoint: tradingPoint),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify that the page renders correctly
      expect(find.text('Test Client'), findsOneWidget);
      expect(find.text('Test Address'), findsOneWidget);
      expect(find.text('Tashrif tartibi: 1'), findsOneWidget);
      expect(find.text('Step 1'), findsOneWidget);
      expect(find.text('Step 2'), findsOneWidget);
    });

    testWidgets('should show strict sequence information', (WidgetTester tester) async {
      // Create test data with strict sequence enabled
      final permissions = SalesReqPermissions(
        userCode: 'test_user',
        skipTINduplicateCheck: false,
        allowCreationWithoutTIN: false,
        allowCreatingPointOfSale: false,
        visit: true,
        strictSequence: true,
        unplannedOrder: false,
        plannedRoute: false,
        editClientCoordinates: false,
        visitSteps: [
          VisitStep(stepCode: 1, stepName: 'Step 1', stepRequired: true),
        ],
      );

      final tradingPoint = TradingPointWithPermissions(
        tradingPoint: model.TradingPoint(
          id: '1',
          name: 'Test Client',
          address: 'Test Address',
          phone: '+998901234567',
          contactPerson: 'Test Person',
          ownerName: 'Test Owner',
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
          tradePointType: 'Shop',
          creditLimit: 1000000.0,
          accumulatedCredit: 0.0,
          codeRegion: '01',
        ),
        permissions: permissions,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => VisitStepsBloc(dataSyncService: mockDataSyncService)
              ..add(LoadVisitSteps(tradingPoint)),
            child: VisitStepsPage(tradingPoint: tradingPoint),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the info button to show visit information dialog
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      // Verify strict sequence information is shown
      expect(find.text('Qat\'iy ketma-ketlik: Ha'), findsOneWidget);
      expect(find.text('Jami qadamlar: 1'), findsOneWidget);
      expect(find.text('Majburiy qadamlar: 1'), findsOneWidget);
    });

    testWidgets('should handle step completion', (WidgetTester tester) async {
      // Create test data
      final permissions = SalesReqPermissions(
        userCode: 'test_user',
        skipTINduplicateCheck: false,
        allowCreationWithoutTIN: false,
        allowCreatingPointOfSale: false,
        visit: true,
        strictSequence: false, // Non-strict for easier testing
        unplannedOrder: false,
        plannedRoute: false,
        editClientCoordinates: false,
        visitSteps: [
          VisitStep(stepCode: 1, stepName: 'Step 1', stepRequired: true),
        ],
      );

      final tradingPoint = TradingPointWithPermissions(
        tradingPoint: model.TradingPoint(
          id: '1',
          name: 'Test Client',
          address: 'Test Address',
          phone: '+998901234567',
          contactPerson: 'Test Person',
          ownerName: 'Test Owner',
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
          tradePointType: 'Shop',
          creditLimit: 1000000.0,
          accumulatedCredit: 0.0,
          codeRegion: '01',
          visitToday: true,
          visitStepNumber: 1,
        ),
        permissions: permissions,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => VisitStepsBloc(dataSyncService: mockDataSyncService)
              ..add(LoadVisitSteps(tradingPoint)),
            child: VisitStepsPage(tradingPoint: tradingPoint),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the complete button
      await tester.tap(find.text('Bajarildi'));
      await tester.pumpAndSettle();

      // Verify completion dialog appears
      expect(find.text('Step 1 bajarildi'), findsOneWidget);
      expect(find.text('Qadam bajarilganligini tasdiqlang va izoh qoldiring (ixtiyoriy):'), findsOneWidget);

      // Enter notes and confirm
      await tester.enterText(find.byType(TextField), 'Test notes');
      await tester.tap(find.text('Tasdiqlash'));
      await tester.pumpAndSettle();

      // Verify step is marked as completed
      expect(find.text('Bajarildi'), findsOneWidget);
    });

    testWidgets('should handle visit completion', (WidgetTester tester) async {
      // Create test data with completed steps
      final permissions = SalesReqPermissions(
        userCode: 'test_user',
        skipTINduplicateCheck: false,
        allowCreationWithoutTIN: false,
        allowCreatingPointOfSale: false,
        visit: true,
        strictSequence: false,
        unplannedOrder: false,
        plannedRoute: false,
        editClientCoordinates: false,
        visitSteps: [
          VisitStep(stepCode: 1, stepName: 'Step 1', stepRequired: true),
        ],
      );

      final tradingPoint = TradingPointWithPermissions(
        tradingPoint: model.TradingPoint(
          id: '1',
          name: 'Test Client',
          address: 'Test Address',
          phone: '+998901234567',
          contactPerson: 'Test Person',
          ownerName: 'Test Owner',
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
          tradePointType: 'Shop',
          creditLimit: 1000000.0,
          accumulatedCredit: 0.0,
          codeRegion: '01',
        ),
        permissions: permissions,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => VisitStepsBloc(dataSyncService: mockDataSyncService)
              ..add(LoadVisitSteps(tradingPoint)),
            child: VisitStepsPage(tradingPoint: tradingPoint),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Complete the step first
      await tester.tap(find.text('Bajarildi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tasdiqlash'));
      await tester.pumpAndSettle();

      // Now the finish visit button should be enabled
      expect(find.text('Tashrifni yakunlash'), findsOneWidget);

      // Tap finish visit
      await tester.tap(find.text('Tashrifni yakunlash'));
      await tester.pumpAndSettle();

      // Verify success message appears
      expect(find.text('Tashrif muvaffaqiyatli yakunlandi!'), findsOneWidget);
    });
  });
}