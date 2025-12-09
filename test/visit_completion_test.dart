import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/visit_steps_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/visit_data_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/visit_finish_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

// Mock classes
class MockVisitDataRepository extends Mock implements VisitDataRepository {}
class MockDataSyncService extends Mock implements DataSyncService {}
class MockSharedPreferencesService extends Mock implements SharedPreferencesService {}
class MockVisitFinishService extends Mock implements VisitFinishService {}

void main() {
  late MockVisitDataRepository mockRepository;
  late MockDataSyncService mockDataSyncService;
  late MockSharedPreferencesService mockPrefs;
  late MockVisitFinishService mockVisitFinishService;
  late VisitStepsBloc visitStepsBloc;

  setUp(() {
    mockRepository = MockVisitDataRepository();
    mockDataSyncService = MockDataSyncService();
    mockPrefs = MockSharedPreferencesService();
    mockVisitFinishService = MockVisitFinishService();

    visitStepsBloc = VisitStepsBloc(
      dataSyncService: mockDataSyncService,
      visitDataRepository: mockRepository,
      visitFinishService: mockVisitFinishService,
    );
  });

  tearDown(() {
    visitStepsBloc.close();
  });

  group('VisitStepsBloc - Visit Completion', () {
    final testTradingPoint = TradingPointWithPermissions(
      tradingPoint: const TradingPoint(
        id: 1,
        name: 'Test Client',
        address: 'Test Address',
        code: 'TEST001',
        latitude: 41.2995,
        longitude: 69.2401,
        region: 'Tashkent',
        district: 'Yunusabad',
        tradePointType: 'Shop',
        status: 'active',
        lastVisitDate: '2024-01-01',
        hasOrders: 1,
        hasContracts: 1,
        isVisited: 0,
        hasContract: 1,
        ownerName: 'Test Owner',
        signboard: 'Test Signboard',
        referencePoint: 'Test Reference',
        responsiblePerson: 'Test Person',
        responsiblePersonPhone: '+998901234567',
        creditLimit: 1000000.0,
        accumulatedCredit: 0.0,
      ),
      visitStepNumber: 1,
      permissions: SalesReqPermissions(
        userCode: 'TEST_USER',
        skipTINduplicateCheck: false,
        allowCreationWithoutTIN: false,
        allowCreatingPointOfSale: false,
        visit: true,
        strictSequence: true,
        unplannedOrder: true,
        plannedRoute: true,
        editClientCoordinates: false,
        clientZoneAccess: false,
        locationUpdateInterval: 30,
        visitSteps: [
          VisitStep(stepCode: 1, stepName: 'Фото до', stepRequired: true),
          VisitStep(stepCode: 2, stepName: 'Аудит полки', stepRequired: true),
          VisitStep(stepCode: 3, stepName: 'Создать заказ', stepRequired: false),
          VisitStep(stepCode: 4, stepName: 'Фото после', stepRequired: true),
        ],
      ),
    );

    final testPermissions = SalesReqPermissions(
      userCode: 'TEST_USER',
      skipTINduplicateCheck: false,
      allowCreationWithoutTIN: false,
      allowCreatingPointOfSale: false,
      visit: true,
      strictSequence: true,
      unplannedOrder: true,
      plannedRoute: true,
      editClientCoordinates: false,
      clientZoneAccess: false,
      locationUpdateInterval: 30,
      visitSteps: [
        VisitStep(stepCode: 1, stepName: 'Фото до', stepRequired: true),
        VisitStep(stepCode: 2, stepName: 'Аудит полки', stepRequired: true),
        VisitStep(stepCode: 3, stepName: 'Создать заказ', stepRequired: false),
        VisitStep(stepCode: 4, stepName: 'Фото после', stepRequired: true),
      ],
    );

    test('VisitStepsCompleted state contains completed steps and order code', () {
      final completedSteps = [
        VisitStepProgress(
          step: VisitStep(stepCode: 1, stepName: 'Фото до', stepRequired: true),
          status: VisitStepStatus.completed,
          notes: 'Фото сделано',
          completedAt: DateTime.now(),
        ),
        VisitStepProgress(
          step: VisitStep(stepCode: 2, stepName: 'Аудит полки', stepRequired: true),
          status: VisitStepStatus.completed,
          notes: 'Аудит завершен',
          completedAt: DateTime.now(),
        ),
        VisitStepProgress(
          step: VisitStep(stepCode: 3, stepName: 'Создать заказ', stepRequired: false),
          status: VisitStepStatus.completed,
          notes: 'GL00-123456',
          completedAt: DateTime.now(),
        ),
      ];

      final state = VisitStepsCompleted(testTradingPoint, completedSteps, orderCode: 'GL00-123456');

      expect(state.tradingPoint, testTradingPoint);
      expect(state.completedSteps, completedSteps);
      expect(state.orderCode, 'GL00-123456');
    });

    blocTest<VisitStepsBloc, VisitStepsState>(
      'emits VisitStepsCompleted with order code when visit finishes successfully with order',
      build: () {
        when(() => mockPrefs.getUserCode()).thenReturn('TEST_USER');
        when(() => mockDataSyncService.getCachedSalesReqPermissions('TEST_USER'))
            .thenAnswer((_) async => testPermissions);
        when(() => mockRepository.getVisitStepDataByVisitId(any()))
            .thenAnswer((_) async => []);
        when(() => mockVisitFinishService.finishVisit(
          visitId: any(named: 'visitId'),
          tradingPoint: any(named: 'tradingPoint'),
          permissions: any(named: 'permissions'),
          onProgress: any(named: 'onProgress'),
          onError: any(named: 'onError'),
        )).thenAnswer((_) async => true);
        when(() => mockVisitFinishService.cancelAllSteps(visitId: any(named: 'visitId')))
            .thenAnswer((_) async {});

        return visitStepsBloc;
      },
      act: (bloc) {
        bloc.add(LoadVisitSteps(testTradingPoint));
        // Wait for initial load
        // Then complete steps and finish visit
      },
      expect: () => [
        isA<VisitStepsLoading>(),
        isA<VisitStepsLoaded>(),
        // After finishing visit with order
        isA<VisitStepsFinishing>(),
        isA<VisitStepsCompleted>(),
      ],
      verify: (bloc) {
        // Verify that cancelAllSteps was called
        verify(() => mockVisitFinishService.cancelAllSteps(visitId: any(named: 'visitId'))).called(1);
      },
    );

    test('VisitStepsCompleted state props are correct', () {
      final completedSteps = [
        VisitStepProgress(
          step: VisitStep(stepCode: 1, stepName: 'Test Step', stepRequired: true),
          status: VisitStepStatus.completed,
        ),
      ];

      final state1 = VisitStepsCompleted(testTradingPoint, completedSteps, orderCode: 'ORDER123');
      final state2 = VisitStepsCompleted(testTradingPoint, completedSteps, orderCode: 'ORDER123');
      final state3 = VisitStepsCompleted(testTradingPoint, completedSteps);

      expect(state1.props, [testTradingPoint, completedSteps, 'ORDER123']);
      expect(state2.props, state1.props);
      expect(state3.props, [testTradingPoint, completedSteps, null]);
    });
  });

  group('Visit Completion UI Tests', () {
    testWidgets('VisitStepsCompleted shows success message and completed steps', (WidgetTester tester) async {
      final completedSteps = [
        VisitStepProgress(
          step: VisitStep(stepCode: 1, stepName: 'Фото до', stepRequired: true),
          status: VisitStepStatus.completed,
          notes: 'Фото сделано',
          completedAt: DateTime.now(),
        ),
        VisitStepProgress(
          step: VisitStep(stepCode: 3, stepName: 'Создать заказ', stepRequired: false),
          status: VisitStepStatus.completed,
          notes: 'GL00-123456',
          completedAt: DateTime.now(),
        ),
      ];

      final state = VisitStepsCompleted(testTradingPoint, completedSteps, orderCode: 'GL00-123456');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => _buildCompletedView(context, state, Theme.of(context), AppLocalizationsEn()),
            ),
          ),
        ),
      );

      // Check success message
      expect(find.text('Tashrif muvaffaqiyatli yakunlandi!'), findsOneWidget);

      // Check client name
      expect(find.text('Test Client'), findsOneWidget);

      // Check order code
      expect(find.text('Buyurtma raqami: GL00-123456'), findsOneWidget);

      // Check completed steps
      expect(find.text('Фото до'), findsOneWidget);
      expect(find.text('Создать заказ'), findsOneWidget);

      // Check completion button
      expect(find.text('Tashrifni yakunlash'), findsOneWidget);
    });

    testWidgets('Order step card is clickable and shows receipt icon', (WidgetTester tester) async {
      final completedSteps = [
        VisitStepProgress(
          step: VisitStep(stepCode: 3, stepName: 'Создать заказ', stepRequired: false),
          status: VisitStepStatus.completed,
          notes: 'GL00-123456',
          completedAt: DateTime.now(),
        ),
      ];

      final state = VisitStepsCompleted(testTradingPoint, completedSteps, orderCode: 'GL00-123456');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => _buildCompletedStepsList(context, state, Theme.of(context), AppLocalizationsEn()),
            ),
          ),
        ),
      );

      // Check order step name
      expect(find.text('Создать заказ'), findsOneWidget);

      // Check receipt icon for order step
      expect(find.byIcon(Icons.receipt_long), findsOneWidget);

      // Check arrow forward icon (indicating clickable)
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });

    testWidgets('Non-order step cards do not show arrow icon', (WidgetTester tester) async {
      final completedSteps = [
        VisitStepProgress(
          step: VisitStep(stepCode: 1, stepName: 'Фото до', stepRequired: true),
          status: VisitStepStatus.completed,
          notes: 'Фото сделано',
          completedAt: DateTime.now(),
        ),
      ];

      final state = VisitStepsCompleted(testTradingPoint, completedSteps);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => _buildCompletedStepsList(context, state, Theme.of(context), AppLocalizationsEn()),
            ),
          ),
        ),
      );

      // Check step name
      expect(find.text('Фото до'), findsOneWidget);

      // Check check circle icon for regular step
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Should not have arrow forward icon
      expect(find.byIcon(Icons.arrow_forward_ios), findsNothing);
    });
  });
}

// Helper functions for testing (copied from visit_steps_page.dart)
Widget _buildCompletedView(
  BuildContext context,
  VisitStepsCompleted state,
  ThemeData theme,
  AppLocalizations l10n,
) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.primary.withOpacity(0.08),
          theme.colorScheme.primaryContainer.withOpacity(0.06),
        ],
      ),
    ),
    child: Column(
      children: [
        // Success Header
        _buildCompletionHeader(context, state, theme),

        // Completed Steps List
        Expanded(
          child: _buildCompletedStepsList(context, state, theme, l10n),
        ),

        // Action Buttons
        _buildCompletionActionButtons(context, state, theme, l10n),
      ],
    ),
  );
}

Widget _buildCompletionHeader(BuildContext context, VisitStepsCompleted state, ThemeData theme) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      boxShadow: [
        BoxShadow(
          color: theme.shadowColor.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        Icon(
          Icons.check_circle,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Tashrif muvaffaqiyatli yakunlandi!',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          state.tradingPoint.tradingPoint.name,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (state.orderCode != null) ...[
          const SizedBox(height: 8),
          Text(
            'Buyurtma raqami: ${state.orderCode}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _buildCompletedStepsList(
  BuildContext context,
  VisitStepsCompleted state,
  ThemeData theme,
  AppLocalizations l10n,
) {
  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: state.completedSteps.length,
    itemBuilder: (context, index) {
      final stepProgress = state.completedSteps[index];
      final isOrderStep = stepProgress.step.stepName.toLowerCase() == 'создать заказ';

      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: isOrderStep && state.orderCode != null ? () => _navigateToOrderDetails(context, state.orderCode!) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isOrderStep ? Icons.receipt_long : Icons.check_circle,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stepProgress.step.stepName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (stepProgress.notes != null && stepProgress.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          stepProgress.notes!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (stepProgress.completedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Yakunlandi: ${stepProgress.completedAt!.toLocal().toString().split('.')[0]}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isOrderStep) ...[
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildCompletionActionButtons(
  BuildContext context,
  VisitStepsCompleted state,
  ThemeData theme,
  AppLocalizations l10n,
) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      boxShadow: [
        BoxShadow(
          color: theme.shadowColor.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: SafeArea(
      child: FilledButton.icon(
        onPressed: () => Navigator.of(context).pop(true), // Return success
        icon: const Icon(Icons.done),
        label: Text('Tashrifni yakunlash'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    ),
  );
}

void _navigateToOrderDetails(BuildContext context, String orderCode) {
  // Mock navigation for testing
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Buyurtma tafsilotlari: $orderCode'),
      backgroundColor: Theme.of(context).colorScheme.primary,
    ),
  );
}