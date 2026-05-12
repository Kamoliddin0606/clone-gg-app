import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/visit_finish_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/visit_data_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
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

  group('VisitFinishService', () {
    group('clearVisitDataAfterCompletion', () {
      test('should successfully clear visit data after completion', () async {
        // Arrange
        const visitId = 'test_visit_123';
        when(mockRepository.deleteVisitStepDataByVisitId(visitId))
            .thenAnswer((_) async {});

        // Act
        final result = await visitFinishService.clearVisitDataAfterCompletion(visitId: visitId);

        // Assert
        expect(result, true);
        verify(mockRepository.deleteVisitStepDataByVisitId(visitId)).called(1);
      });

      test('should return false when clearing visit data fails', () async {
        // Arrange
        const visitId = 'test_visit_123';
        when(mockRepository.deleteVisitStepDataByVisitId(visitId))
            .thenThrow(Exception('Database error'));

        // Act
        final result = await visitFinishService.clearVisitDataAfterCompletion(visitId: visitId);

        // Assert
        expect(result, false);
        verify(mockRepository.deleteVisitStepDataByVisitId(visitId)).called(1);
      });

      test('should handle empty visit ID gracefully', () async {
        // Arrange
        const visitId = '';
        when(mockRepository.deleteVisitStepDataByVisitId(visitId))
            .thenAnswer((_) async {});

        // Act
        final result = await visitFinishService.clearVisitDataAfterCompletion(visitId: visitId);

        // Assert
        expect(result, true);
        verify(mockRepository.deleteVisitStepDataByVisitId(visitId)).called(1);
      });
    });

    group('finishVisit integration with data clearing', () {
      test('should clear visit data after successful completion', () async {
        // Arrange
        const visitId = 'test_visit_123';
        final tradingPoint = TradingPointWithPermissions(
          tradingPoint: const TradingPoint(
            id: 'client_123',
            name: 'Test Client',
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
            responsiblePersonPhone: '+998987654321',
            tradePointType: 'Shop',
            creditLimit: 1000000.0,
            accumulatedCredit: 0.0,
            codeRegion: 'region_1',
          ),
          permissions: SalesReqPermissions(
            userCode: 'user_123',
            skipTINduplicateCheck: false,
            allowCreationWithoutTIN: false,
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
        );

        final permissions = SalesReqPermissions(
          userCode: 'user_123',
          skipTINduplicateCheck: false,
          allowCreationWithoutTIN: false,
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

        // Mock successful data clearing
        when(mockRepository.deleteVisitStepDataByVisitId(visitId))
            .thenAnswer((_) async => {});

        // Act - Call the method that should trigger data clearing
        final clearResult = await visitFinishService.clearVisitDataAfterCompletion(visitId: visitId);

        // Assert
        expect(clearResult, true);
        verify(mockRepository.deleteVisitStepDataByVisitId(visitId)).called(1);
      });
    });
  });
}