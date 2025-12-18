import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order_status.dart';

// Mock classes
class MockSharedPreferencesService extends Mock implements SharedPreferencesService {}
class MockSoapApiService extends Mock implements SoapApiService {}
class MockApiDatabaseService extends Mock implements ApiDatabaseService {}
class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockDio extends Mock implements Dio {}

void main() {
  late DataSyncService dataSyncService;
  late MockSharedPreferencesService mockPrefs;
  late MockSoapApiService mockApiService;
  late MockApiDatabaseService mockDbService;
  late MockDatabaseHelper mockDbHelper;
  late MockDio mockDio;

  setUp(() {
    mockPrefs = MockSharedPreferencesService();
    mockApiService = MockSoapApiService();
    mockDbService = MockApiDatabaseService();
    mockDbHelper = MockDatabaseHelper();
    mockDio = MockDio();

    dataSyncService = DataSyncService(
      prefs: mockPrefs,
      apiService: mockApiService,
      dbService: mockDbService,
      dbHelper: mockDbHelper,
    );
  });

  group('DataSyncService Order Status Tests', () {
    test('syncOrderStatuses returns statuses with database IDs', () async {
      // Arrange
      const userCode = 'TEST001';

      // Mock API response - statuses without IDs (as returned by SOAP API)
      final apiStatuses = [
        OrderStatus(message: 'Новый'),
        OrderStatus(message: 'Доставлено'),
        OrderStatus(message: 'В обработке'),
      ];

      // Mock database response - statuses with IDs (as stored in DB)
      final dbStatuses = [
        OrderStatus(id: 1, message: 'Новый'),
        OrderStatus(id: 2, message: 'Доставлено'),
        OrderStatus(id: 3, message: 'В обработке'),
      ];

      when(mockApiService.getOrderStatusList(userCode: userCode))
          .thenAnswer((_) async => apiStatuses);
      when(mockDbService.saveOrderStatuses(apiStatuses))
          .thenAnswer((_) async => Future.value());
      when(mockDbService.getOrderStatuses())
          .thenAnswer((_) async => dbStatuses);

      // Act
      final result = await dataSyncService.syncOrderStatuses(userCode: userCode);

      // Assert
      expect(result.length, 3);
      expect(result[0].id, isNotNull);
      expect(result[0].message, 'Новый');
      expect(result[1].id, isNotNull);
      expect(result[1].message, 'Доставлено');
      expect(result[2].id, isNotNull);
      expect(result[2].message, 'В обработке');

      // Verify API was called
      verify(mockApiService.getOrderStatusList(userCode: userCode)).called(1);
      // Verify data was saved
      verify(mockDbService.saveOrderStatuses(apiStatuses)).called(1);
      // Verify data was retrieved from DB
      verify(mockDbService.getOrderStatuses()).called(1);
    });

    test('syncOrderStatuses handles empty API response', () async {
      // Arrange
      const userCode = 'TEST001';

      when(mockApiService.getOrderStatusList(userCode: userCode))
          .thenAnswer((_) async => []);
      when(mockDbService.saveOrderStatuses([]))
          .thenAnswer((_) async => Future.value());
      when(mockDbService.getOrderStatuses())
          .thenAnswer((_) async => []);

      // Act
      final result = await dataSyncService.syncOrderStatuses(userCode: userCode);

      // Assert
      expect(result, isEmpty);

      verify(mockApiService.getOrderStatusList(userCode: userCode)).called(1);
      verify(mockDbService.saveOrderStatuses([])).called(1);
      verify(mockDbService.getOrderStatuses()).called(1);
    });
  });
}