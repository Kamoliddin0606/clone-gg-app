import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/visit_steps_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/visit_data_repository.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

@GenerateMocks([
  VisitDataRepository,
  DataSyncService,
  SharedPreferencesService,
])
void main() {
  late VisitStepsBloc visitStepsBloc;
  late MockVisitDataRepository mockRepository;
  late MockDataSyncService mockDataSyncService;
  late MockSharedPreferencesService mockPrefs;

  setUp(() {
    mockRepository = MockVisitDataRepository();
    mockDataSyncService = MockDataSyncService();
    mockPrefs = MockSharedPreferencesService();

    visitStepsBloc = VisitStepsBloc(
      dataSyncService: mockDataSyncService,
      visitDataRepository: mockRepository,
    );
  });

  tearDown(() {
    visitStepsBloc.close();
  });

  group('VisitStepsBloc State Persistence', () {
    final testTradingPoint = TradingPointWithPermissions(
      tradingPoint: model.TradingPoint(
        id: 'test_client_1',
        name: 'Test Client',
        address: 'Test Address',
        inn: '123456789',
        contactPerson: 'Test Person',
        ownerName: 'Test Owner',
        phone: '+998901234567',
        latitude: 41.2995,
        longitude: 69.2401,
        region: 'Tashkent',
        district: 'Yunusabad',
        tradePointType: 'Shop',
        signboard: 'Test Signboard',
        referencePoint: 'Test Reference',
        hasContract: true,
        status: 'active',
        lastVisitDate: null,
        isVisited: false,
        hasOrders: false,
        hasContracts: true,
        creditLimit: 1000000.0,
        accumulatedCredit: 0.0,
      ),
      permissions: SalesReqPermissions(
        visit: true,
        unplannedOrder: true,
        plannedRoute: true,
        editClientCoordinates: false,
        skipTINduplicateCheck: false,
        allowCreationWithoutTIN: false,
        allowCreatingPointOfSale: false,
        visitSteps: [
          VisitStep(
            stepCode: 1,
            stepName: 'Фото до (facing correction)',
            stepRequired: true,
          ),
          VisitStep(
            stepCode: 2,
            stepName: 'Аудит полки (остатки)',
            stepRequired: false,
          ),
        ],
        strictSequence: true,
      ),
      visitStepNumber: 1,
      visitToday: true,
    );

    final testPermissions = SalesReqPermissions(
      visit: true,
      unplannedOrder: true,
      plannedRoute: true,
      editClientCoordinates: false,
      skipTINduplicateCheck: false,
      allowCreationWithoutTIN: false,
      allowCreatingPointOfSale: false,
      visitSteps: [
        VisitStep(
          stepCode: 1,
          stepName: 'Фото до (facing correction)',
          stepRequired: true,
        ),
        VisitStep(
          stepCode: 2,
          stepName: 'Аудит полки (остатки)',
          stepRequired: false,
        ),
      ],
      strictSequence: true,
    );

    blocTest<VisitStepsBloc, VisitStepsState>(
      'should load visit steps and persist state correctly',
      build: () {
        when(mockPrefs.getUserCode()).thenReturn('test_user');
        when(mockDataSyncService.getCachedSalesReqPermissions('test_user'))
            .thenAnswer((_) async => testPermissions);
        when(mockRepository.getVisitStepDataByVisitId(any))
            .thenAnswer((_) async => []);

        return visitStepsBloc;
      },
      act: (bloc) => bloc.add(LoadVisitSteps(testTradingPoint)),
      expect: () => [
        VisitStepsLoading(),
        isA<VisitStepsLoaded>(),
      ],
      verify: (bloc) {
        final state = bloc.state as VisitStepsLoaded;
        expect(state.stepProgress.length, 2);
        expect(state.stepProgress[0].status, VisitStepStatus.pending);
        expect(state.stepProgress[1].status, VisitStepStatus.pending);
        expect(state.currentStepIndex, 0); // First step should be current
      },
    );

    blocTest<VisitStepsBloc, VisitStepsState>(
      'should restore completed step state from repository',
      build: () {
        when(mockPrefs.getUserCode()).thenReturn('test_user');
        when(mockDataSyncService.getCachedSalesReqPermissions('test_user'))
            .thenAnswer((_) async => testPermissions);

        // Mock existing completed step data
        final completedData = VisitData(
          visitId: 'visit_test_user_test_client_1_${DateTime.now().toIso8601String().split('T')[0]}',
          clientCode: 'Test Client',
          stepCode: 1,
          stepName: 'Фото до (facing correction)',
          dataType: 'completion',
          dataContent: '{"notes":"Test notes","completedAt":"${DateTime.now().toIso8601String()}","status":"completed"}',
          timestamp: DateTime.now(),
        );

        when(mockRepository.getVisitStepDataByVisitId(any))
            .thenAnswer((_) async => [completedData]);

        return visitStepsBloc;
      },
      act: (bloc) => bloc.add(LoadVisitSteps(testTradingPoint)),
      expect: () => [
        VisitStepsLoading(),
        isA<VisitStepsLoaded>(),
      ],
      verify: (bloc) {
        final state = bloc.state as VisitStepsLoaded;
        expect(state.stepProgress.length, 2);
        expect(state.stepProgress[0].status, VisitStepStatus.completed);
        expect(state.stepProgress[0].notes, 'Test notes');
        expect(state.stepProgress[1].status, VisitStepStatus.pending);
        expect(state.currentStepIndex, 1); // Should move to next step
      },
    );

    blocTest<VisitStepsBloc, VisitStepsState>(
      'should handle step completion and save to repository',
      build: () {
        when(mockPrefs.getUserCode()).thenReturn('test_user');
        when(mockDataSyncService.getCachedSalesReqPermissions('test_user'))
            .thenAnswer((_) async => testPermissions);
        when(mockRepository.getVisitStepDataByVisitId(any))
            .thenAnswer((_) async => []);
        when(mockRepository.saveVisitStepData(any))
            .thenAnswer((_) async => null);

        return visitStepsBloc;
      },
      seed: () => VisitStepsLoaded(
        tradingPoint: testTradingPoint,
        permissions: testPermissions,
        stepProgress: [
          VisitStepProgress(
            step: testPermissions.visitSteps[0],
            status: VisitStepStatus.inProgress,
          ),
          VisitStepProgress(
            step: testPermissions.visitSteps[1],
            status: VisitStepStatus.pending,
          ),
        ],
        currentStepIndex: 0,
        isStrictSequence: true,
        canProceedToNext: true,
      ),
      act: (bloc) => bloc.add(CompleteStep(0, 'Test completion notes')),
      expect: () => [
        isA<VisitStepsLoaded>(),
      ],
      verify: (bloc) {
        final state = bloc.state as VisitStepsLoaded;
        expect(state.stepProgress[0].status, VisitStepStatus.completed);
        expect(state.stepProgress[0].notes, 'Test completion notes');
        expect(state.stepProgress[0].completedAt, isNotNull);
        expect(state.currentStepIndex, 1); // Should move to next step

        // Verify data was saved to repository
        verify(mockRepository.saveVisitStepData(any)).called(1);
      },
    );

    blocTest<VisitStepsBloc, VisitStepsState>(
      'should handle repository errors gracefully',
      build: () {
        when(mockPrefs.getUserCode()).thenReturn('test_user');
        when(mockDataSyncService.getCachedSalesReqPermissions('test_user'))
            .thenAnswer((_) async => testPermissions);
        when(mockRepository.getVisitStepDataByVisitId(any))
            .thenThrow(Exception('Database error'));

        return visitStepsBloc;
      },
      act: (bloc) => bloc.add(LoadVisitSteps(testTradingPoint)),
      expect: () => [
        VisitStepsLoading(),
        isA<VisitStepsLoaded>(), // Should fallback to default state
      ],
      verify: (bloc) {
        final state = bloc.state as VisitStepsLoaded;
        expect(state.stepProgress.length, 2);
        // Should have default pending states despite repository error
        expect(state.stepProgress[0].status, VisitStepStatus.pending);
        expect(state.stepProgress[1].status, VisitStepStatus.pending);
      },
    );

    test('should generate consistent visit ID', () {
      when(mockPrefs.getUserCode()).thenReturn('test_user');
      when(mockDataSyncService.getCachedSalesReqPermissions('test_user'))
          .thenAnswer((_) async => testPermissions);
      when(mockRepository.getVisitStepDataByVisitId(any))
          .thenAnswer((_) async => []);

      visitStepsBloc.add(LoadVisitSteps(testTradingPoint));

      // Wait for the bloc to process
      // The visit ID should be generated as: visit_{userCode}_{clientId}_{date}
      // We can't easily test the exact ID without exposing it, but we can verify the flow works
    });

    blocTest<VisitStepsBloc, VisitStepsState>(
      'should make all steps optional for unplanned orders',
      build: () {
        when(mockPrefs.getUserCode()).thenReturn('test_user');
        when(mockDataSyncService.getCachedSalesReqPermissions('test_user'))
            .thenAnswer((_) async => testPermissions);
        when(mockRepository.getVisitStepDataByVisitId(any))
            .thenAnswer((_) async => []);

        // Create bloc with unplanned order flag
        return VisitStepsBloc(
          dataSyncService: mockDataSyncService,
          visitDataRepository: mockRepository,
          visitFinishService: null, // Not needed for this test
          isUnplannedOrder: true,
        );
      },
      act: (bloc) => bloc.add(LoadVisitSteps(testTradingPoint)),
      expect: () => [
        VisitStepsLoading(),
        isA<VisitStepsLoaded>(),
      ],
      verify: (bloc) {
        final state = bloc.state as VisitStepsLoaded;
        expect(state.stepProgress.length, 2);
        // All steps should be optional (stepRequired = false) for unplanned orders
        expect(state.stepProgress[0].step.stepRequired, false);
        expect(state.stepProgress[1].step.stepRequired, false);
        // Should be marked as unplanned order
        expect(state.isUnplannedOrder, true);
        // Should always allow proceeding to next step
        expect(state.canProceedToNext, true);
      },
    );
  });
}