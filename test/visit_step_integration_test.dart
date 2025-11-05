import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/visit_step_data_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/photo_storage_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/visit_step_validation_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/visit_step_error_recovery_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/visit_step_sync_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';

// Mock classes
class MockVisitDataRepository extends Mock implements VisitDataRepository {}
class MockSharedPreferencesService extends Mock implements SharedPreferencesService {}
class MockDataSyncService extends Mock implements DataSyncService {}

void main() {
  group('Visit Step Integration Tests', () {
    late VisitStepDataService dataService;
    late PhotoStorageService photoService;
    late VisitStepValidationService validationService;
    late VisitStepErrorRecoveryService recoveryService;
    late VisitStepSyncService syncService;

    late MockVisitDataRepository mockRepository;
    late MockSharedPreferencesService mockPrefs;
    late MockDataSyncService mockDataSync;

    late SalesReqPermissions mockPermissions;

    setUp(() {
      mockRepository = MockVisitDataRepository();
      mockPrefs = MockSharedPreferencesService();
      mockDataSync = MockDataSyncService();

      dataService = VisitStepDataService(mockRepository);
      photoService = PhotoStorageService(dataService);
      validationService = VisitStepValidationService(mockPermissions);
      recoveryService = VisitStepErrorRecoveryService(
        visitDataRepository: mockRepository,
        prefs: mockPrefs,
      );
      syncService = VisitStepSyncService(
        visitDataRepository: mockRepository,
        dataSyncService: mockDataSync,
        prefs: mockPrefs,
      );

      mockPermissions = SalesReqPermissions(
        userCode: 'test_user',
        visit: true,
        strictSequence: false,
        visitSteps: [
          VisitStep(stepCode: 1, stepName: 'Photo Step', stepRequired: true),
          VisitStep(stepCode: 2, stepName: 'Audit Step', stepRequired: false),
          VisitStep(stepCode: 3, stepName: 'Order Step', stepRequired: true),
        ],
      );
    });

    test('should handle complete photo step workflow', () async {
      // Arrange
      const visitId = 'visit_123';
      const clientCode = 'client_456';
      const stepCode = 1;
      const stepName = 'Photo Step';

      final testImageFile = File('test_image.jpg'); // Mock file

      when(mockRepository.saveVisitData(any)).thenAnswer((_) async => 1);

      // Act & Assert - Save photo
      final saveResult = await photoService.savePhoto(
        visitId: visitId,
        clientCode: clientCode,
        stepCode: stepCode,
        stepName: stepName,
        imageFile: testImageFile,
      );

      expect(saveResult, isA<Map<String, String>>());
      expect(saveResult.containsKey('imagePath'), true);
      expect(saveResult.containsKey('thumbnailPath'), true);

      // Act & Assert - Validate data
      final photoData = {
        'image_path': saveResult['imagePath'],
        'thumbnail_path': saveResult['thumbnailPath'],
        'file_size': 1024000,
      };

      final validationResult = await validationService.validateVisitStepData(
        visitId: visitId,
        clientCode: clientCode,
        stepCode: stepCode,
        stepName: stepName,
        data: photoData,
        dataType: 'photo',
      );

      expect(validationResult.isValid, true);
      expect(validationResult.errors, isEmpty);

      // Act & Assert - Save validated data
      final dataSaveResult = await dataService.savePhotoData(
        visitId: visitId,
        clientCode: clientCode,
        stepCode: stepCode,
        stepName: stepName,
        imagePath: photoData['image_path'],
        thumbnailPath: photoData['thumbnail_path'],
      );

      expect(dataSaveResult, true);

      // Verify repository was called
      verify(mockRepository.saveVisitData(any)).called(1);
    });

    test('should handle audit step workflow', () async {
      // Arrange
      const visitId = 'visit_123';
      const clientCode = 'client_456';
      const stepCode = 2;
      const stepName = 'Audit Step';

      final auditData = {
        'items': [
          {
            'product_code': 'PROD001',
            'expected': 10,
            'actual': 8,
          },
          {
            'product_code': 'PROD002',
            'expected': 5,
            'actual': 5,
          },
        ],
      };

      when(mockRepository.saveVisitData(any)).thenAnswer((_) async => 1);

      // Act - Validate audit data
      final validationResult = await validationService.validateVisitStepData(
        visitId: visitId,
        clientCode: clientCode,
        stepCode: stepCode,
        stepName: stepName,
        data: auditData,
        dataType: 'audit',
      );

      // Assert
      expect(validationResult.isValid, true);
      expect(validationResult.errors, isEmpty);

      // Act - Save audit data
      final saveResult = await dataService.saveAuditData(
        visitId: visitId,
        clientCode: clientCode,
        stepCode: stepCode,
        stepName: stepName,
        data: auditData,
      );

      expect(saveResult, true);
      verify(mockRepository.saveVisitData(any)).called(1);
    });

    test('should handle order step workflow', () async {
      // Arrange
      const visitId = 'visit_123';
      const clientCode = 'client_456';
      const stepCode = 3;
      const stepName = 'Order Step';

      final orderData = {
        'order_number': 'ORD001',
        'items': [
          {
            'product_code': 'PROD001',
            'quantity': 5,
            'price': 100.0,
          },
        ],
      };

      when(mockRepository.saveVisitData(any)).thenAnswer((_) async => 1);

      // Act - Validate order data
      final validationResult = await validationService.validateVisitStepData(
        visitId: visitId,
        clientCode: clientCode,
        stepCode: stepCode,
        stepName: stepName,
        data: orderData,
        dataType: 'order',
      );

      // Assert
      expect(validationResult.isValid, true);
      expect(validationResult.errors, isEmpty);

      // Act - Save order data
      final saveResult = await dataService.saveOrderData(
        visitId: visitId,
        clientCode: clientCode,
        stepCode: stepCode,
        stepName: stepName,
        data: orderData,
      );

      expect(saveResult, true);
      verify(mockRepository.saveVisitData(any)).called(1);
    });

    test('should handle error recovery for failed operations', () async {
      // Arrange
      const operationId = 'failed_op_123';
      final config = ErrorRecoveryConfig(
        maxRetries: 2,
        retryDelay: const Duration(milliseconds: 100),
        strategy: RecoveryStrategy.retry,
      );

      int retryCount = 0;
      Future<bool> retryOperation() async {
        retryCount++;
        if (retryCount < 2) {
          throw Exception('Network error');
        }
        return true;
      }

      when(mockRepository.markDataForOfflineSync(any)).thenAnswer((_) async {});

      // Act
      final result = await recoveryService.handleError(
        operationId: operationId,
        error: VisitStepError.networkError,
        errorData: {'some': 'data'},
        config: config,
        retryOperation: retryOperation,
      );

      // Assert - Should return false initially (async retry)
      expect(result, false);

      // Wait for retry to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify retry was attempted
      expect(retryCount, greaterThanOrEqualTo(1));
    });

    test('should handle sync workflow', () async {
      // Arrange
      final unsyncedData = [
        VisitData(
          id: 1,
          visitId: 'visit_123',
          clientCode: 'client_456',
          stepCode: 1,
          stepName: 'Photo Step',
          dataType: 'photo',
          dataContent: '{"image_path": "/path/to/image.jpg"}',
          isSynced: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(mockRepository.getUnsyncedVisitData()).thenAnswer((_) async => unsyncedData);
      when(mockRepository.markVisitDataAsSynced(any)).thenAnswer((_) async {});
      when(mockPrefs.getString(any)).thenAnswer((_) async => null);
      when(mockPrefs.setString(any, any)).thenAnswer((_) async {});

      // Act
      await syncService.syncUnsyncedData();

      // Assert
      verify(mockRepository.getUnsyncedVisitData()).called(1);
      verify(mockRepository.markVisitDataAsSynced('visit_123')).called(1);
    });

    test('should validate step sequence correctly', () {
      // Arrange
      final stepProgress = [
        VisitStepProgress(
          step: VisitStep(stepCode: 1, stepName: 'Step 1', stepRequired: true),
          status: VisitStepStatus.completed,
        ),
        VisitStepProgress(
          step: VisitStep(stepCode: 2, stepName: 'Step 2', stepRequired: true),
          status: VisitStepStatus.pending,
        ),
        VisitStepProgress(
          step: VisitStep(stepCode: 3, stepName: 'Step 3', stepRequired: false),
          status: VisitStepStatus.pending,
        ),
      ];

      // Act - Strict sequence validation
      final strictResult = validationService.validateStepSequence(
        stepProgress: stepProgress,
        isStrictSequence: true,
        currentStepIndex: 1,
      );

      // Assert
      expect(strictResult.isValid, false); // Step 2 cannot be accessed while step 1 is pending

      // Act - Non-strict sequence validation
      final nonStrictResult = validationService.validateStepSequence(
        stepProgress: stepProgress,
        isStrictSequence: false,
        currentStepIndex: 2,
      );

      // Assert
      expect(nonStrictResult.isValid, true); // Can access any step in non-strict mode
    });

    test('should validate visit completion', () {
      // Arrange
      final stepProgress = [
        VisitStepProgress(
          step: VisitStep(stepCode: 1, stepName: 'Step 1', stepRequired: true),
          status: VisitStepStatus.completed,
        ),
        VisitStepProgress(
          step: VisitStep(stepCode: 2, stepName: 'Step 2', stepRequired: true),
          status: VisitStepStatus.pending, // Required but not completed
        ),
        VisitStepProgress(
          step: VisitStep(stepCode: 3, stepName: 'Step 3', stepRequired: false),
          status: VisitStepStatus.skipped, // Optional, can be skipped
        ),
      ];

      // Act
      final result = validationService.validateVisitCompletion(stepProgress);

      // Assert
      expect(result.isValid, false); // Required step 2 is not completed
      expect(result.errors.length, 1);
    });

    test('should handle invalid data gracefully', () async {
      // Arrange
      final invalidData = {
        // Missing required fields
        'invalid_field': 'invalid_value',
      };

      // Act
      final result = await validationService.validateVisitStepData(
        visitId: '', // Invalid
        clientCode: '', // Invalid
        stepCode: 0, // Invalid
        stepName: '', // Invalid
        data: invalidData,
        dataType: 'invalid_type', // Invalid
      );

      // Assert
      expect(result.isValid, false);
      expect(result.errors.length, greaterThan(0));
    });

    test('should handle storage errors with fallback', () async {
      // Arrange
      const operationId = 'storage_failed_op';
      final config = ErrorRecoveryConfig(
        strategy: RecoveryStrategy.fallback,
        enableFallback: true,
      );

      when(mockRepository.saveWithAlternativeMethod(any, any)).thenAnswer((_) async {});

      Future<bool> retryOperation() async {
        throw Exception('Storage full');
      }

      // Act
      final result = await recoveryService.handleError(
        operationId: operationId,
        error: VisitStepError.storageError,
        errorData: {'some': 'data'},
        config: config,
        retryOperation: retryOperation,
      );

      // Assert
      expect(result, false); // Fallback attempted but may not complete immediately
      verify(mockRepository.saveWithAlternativeMethod(any, any)).called(1);
    });
  });

  group('Performance Tests', () {
    test('should handle batch photo processing efficiently', () async {
      // Arrange
      final photoService = PhotoStorageService(MockVisitStepDataService());
      final imageFiles = List.generate(
        10,
        (index) => File('test_image_$index.jpg'),
      );

      when(mockRepository.saveVisitData(any)).thenAnswer((_) async => 1);

      // Act
      final startTime = DateTime.now();
      await photoService.batchProcessPhotos('visit_batch', imageFiles);
      final endTime = DateTime.now();

      // Assert
      final duration = endTime.difference(startTime).inMilliseconds;
      expect(duration, lessThan(5000)); // Should complete within 5 seconds
    });

    test('should validate large datasets efficiently', () async {
      // Arrange
      final largeAuditData = {
        'items': List.generate(100, (index) => {
          'product_code': 'PROD${index.toString().padLeft(3, '0')}',
          'expected': 10,
          'actual': 10,
        }),
      };

      // Act
      final startTime = DateTime.now();
      final result = await validationService.validateVisitStepData(
        visitId: 'visit_large',
        clientCode: 'client_large',
        stepCode: 2,
        stepName: 'Large Audit',
        data: largeAuditData,
        dataType: 'audit',
      );
      final endTime = DateTime.now();

      // Assert
      final duration = endTime.difference(startTime).inMilliseconds;
      expect(duration, lessThan(1000)); // Should validate within 1 second
      expect(result.isValid, true);
    });
  });
}