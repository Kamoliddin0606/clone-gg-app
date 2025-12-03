import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/visit_finish_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/visit_data_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';

// Mock classes
class MockVisitDataRepository extends Mock implements VisitDataRepository {}

void main() {
  late VisitFinishService visitFinishService;
  late MockVisitDataRepository mockRepository;

  setUp(() {
    mockRepository = MockVisitDataRepository();
    visitFinishService = VisitFinishService(mockRepository);
  });

  setUpAll(() {
    // Initialize Mockito
  });

  group('VisitFinishService', () {
    test('finishVisit should process all steps successfully', () async {
      // Arrange
      final visitId = 'test_visit_123';
      final mockTradingPoint = TradingPoint(
        id: 'test_client',
        name: 'Test Client',
        address: 'Test Address',
        phone: '',
        ownerName: '',
        contactPerson: '',
        inn: '',
        status: 'active',
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
        visitToday: false,
        visitStepNumber: 1,
        plannedWeekDay: null,
      );
      final tradingPoint = TradingPointWithPermissions(tradingPoint: mockTradingPoint);
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
          VisitStep(stepCode: 1, stepName: 'фото до (facing correction)', stepRequired: true),
          VisitStep(stepCode: 2, stepName: 'создать заказ', stepRequired: true),
        ],
      );

      // Mock repository calls - no need to mock visit data step as it doesn't use repository
      when(mockRepository.getVisitStepDataByStep(visitId, 1))
          .thenAnswer((_) async => [
                VisitData(
                  visitId: visitId,
                  clientCode: 'test_client',
                  stepCode: 1,
                  stepName: 'фото до (facing correction)',
                  dataType: 'completion',
                  dataContent: '{"test": "data"}',
                  timestamp: DateTime.now(),
                )
              ]);

      when(mockRepository.getVisitStepDataByStep(visitId, 2))
          .thenAnswer((_) async => [
                VisitData(
                  visitId: visitId,
                  clientCode: 'test_client',
                  stepCode: 2,
                  stepName: 'создать заказ',
                  dataType: 'completion',
                  dataContent: '{"test": "data"}',
                  timestamp: DateTime.now(),
                )
              ]);

      // Act
      final progressUpdates = <String>[];
      final errorUpdates = <String>[];

      final result = await visitFinishService.finishVisit(
        visitId: visitId,
        tradingPoint: tradingPoint,
        permissions: permissions,
        onProgress: (current, total, message, [requestData]) {
          progressUpdates.add('$current/$total: $message');
        },
        onError: (step, error) {
          errorUpdates.add('${step.stepName}: $error');
        },
      );

      // Assert
      expect(result, true);
      expect(progressUpdates.length, greaterThan(0));
      expect(errorUpdates.length, 0);
      expect(progressUpdates.last, contains('Barcha bosqichlar muvaffaqiyatli bajarildi'));
    });

    test('finishVisit should handle step failure and rollback', () async {
      // Arrange
      final visitId = 'test_visit_123';
      final mockTradingPoint = TradingPoint(
        id: 'test_client',
        name: 'Test Client',
        address: 'Test Address',
        phone: '',
        ownerName: '',
        contactPerson: '',
        inn: '',
        status: 'active',
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
        visitToday: false,
        visitStepNumber: 1,
        plannedWeekDay: null,
      );
      final tradingPoint = TradingPointWithPermissions(tradingPoint: mockTradingPoint);
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
          VisitStep(stepCode: 1, stepName: 'фото до (facing correction)', stepRequired: true),
          VisitStep(stepCode: 2, stepName: 'создать заказ', stepRequired: true),
        ],
      );

      // Mock repository calls - first step succeeds, second fails
      when(mockRepository.getVisitStepDataByStep(visitId, 1))
          .thenAnswer((_) async => [
                VisitData(
                  visitId: visitId,
                  clientCode: 'test_client',
                  stepCode: 1,
                  stepName: 'фото до (facing correction)',
                  dataType: 'completion',
                  dataContent: '{"test": "data"}',
                  timestamp: DateTime.now(),
                )
              ]);

      when(mockRepository.getVisitStepDataByStep(visitId, 2))
          .thenAnswer((_) async => []); // No completion data = failure

      // Act
      final progressUpdates = <String>[];
      final errorUpdates = <String>[];

      final result = await visitFinishService.finishVisit(
        visitId: visitId,
        tradingPoint: tradingPoint,
        permissions: permissions,
        onProgress: (current, total, message, [requestData]) {
          progressUpdates.add('$current/$total: $message');
        },
        onError: (step, error) {
          errorUpdates.add('${step.stepName}: $error');
        },
      );

      // Assert
      expect(result, false);
      expect(errorUpdates.length, 1);
      expect(errorUpdates.first, contains('создать заказ'));
    });

    test('finishVisit should handle unknown step types', () async {
      // Arrange
      final visitId = 'test_visit_123';
      final mockTradingPoint = TradingPoint(
        id: 'test_client',
        name: 'Test Client',
        address: 'Test Address',
        phone: '',
        ownerName: '',
        contactPerson: '',
        inn: '',
        status: 'active',
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
        visitToday: false,
        visitStepNumber: 1,
        plannedWeekDay: null,
      );
      final tradingPoint = TradingPointWithPermissions(tradingPoint: mockTradingPoint);
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
          VisitStep(stepCode: 99, stepName: 'Unknown Step', stepRequired: true),
        ],
      );

      // Mock repository calls
      when(mockRepository.getVisitStepDataByStep(visitId, 99))
          .thenAnswer((_) async => [
                VisitData(
                  visitId: visitId,
                  clientCode: 'test_client',
                  stepCode: 99,
                  stepName: 'Unknown Step',
                  dataType: 'completion',
                  dataContent: '{"test": "data"}',
                  timestamp: DateTime.now(),
                )
              ]);

      // Act
      final progressUpdates = <String>[];
      final errorUpdates = <String>[];

      final result = await visitFinishService.finishVisit(
        visitId: visitId,
        tradingPoint: tradingPoint,
        permissions: permissions,
        onProgress: (current, total, message, [requestData]) {
          progressUpdates.add('$current/$total: $message');
        },
        onError: (step, error) {
          errorUpdates.add('${step.stepName}: $error');
        },
      );

      // Assert
      expect(result, true);
      expect(progressUpdates.any((msg) => msg.contains('Noma\'lum bosqich')), true);
    });

    test('finishVisit should handle repository errors gracefully', () async {
      // Arrange
      final visitId = 'test_visit_123';
      final mockTradingPoint = TradingPoint(
        id: 'test_client',
        name: 'Test Client',
        address: 'Test Address',
        phone: '',
        ownerName: '',
        contactPerson: '',
        inn: '',
        status: 'active',
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
        visitToday: false,
        visitStepNumber: 1,
        plannedWeekDay: null,
      );
      final tradingPoint = TradingPointWithPermissions(tradingPoint: mockTradingPoint);
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
          VisitStep(stepCode: 1, stepName: 'фото до (facing correction)', stepRequired: true),
        ],
      );

      // Mock repository to throw error
      when(mockRepository.getVisitStepDataByStep(visitId, 1))
          .thenThrow(Exception('Database error'));

      // Act
      final progressUpdates = <String>[];
      final errorUpdates = <String>[];

      final result = await visitFinishService.finishVisit(
        visitId: visitId,
        tradingPoint: tradingPoint,
        permissions: permissions,
        onProgress: (current, total, message) {
          progressUpdates.add('$current/$total: $message');
        },
        onError: (step, error) {
          errorUpdates.add('${step.stepName}: $error');
        },
      );

      // Assert
      expect(result, false);
      expect(errorUpdates.length, 1);
      expect(errorUpdates.first, contains('Database error'));
    });
  });
}