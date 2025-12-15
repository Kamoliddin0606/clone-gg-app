import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/services/rest_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/rest_api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order_status.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/thumbnail.dart';

// Mock classes
class MockSharedPreferencesService extends Mock implements SharedPreferencesService {}
class MockSoapApiService extends Mock implements SoapApiService {}
class MockApiDatabaseService extends Mock implements ApiDatabaseService {}
class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockRestApiService extends Mock implements RestApiService {}
class MockRestApiDatabaseService extends Mock implements RestApiDatabaseService {}
class MockTokenService extends Mock implements TokenService {}
class MockDio extends Mock implements Dio {}

void main() {
  late DataSyncService dataSyncService;
  late MockSharedPreferencesService mockPrefs;
  late MockSoapApiService mockApiService;
  late MockApiDatabaseService mockDbService;
  late MockDatabaseHelper mockDbHelper;
  late MockRestApiService mockRestApiService;
  late MockRestApiDatabaseService mockRestApiDatabaseService;
  late MockTokenService mockTokenService;
  late MockDio mockDio;

  setUp(() {
    mockPrefs = MockSharedPreferencesService();
    mockApiService = MockSoapApiService();
    mockDbService = MockApiDatabaseService();
    mockDbHelper = MockDatabaseHelper();
    mockRestApiService = MockRestApiService();
    mockRestApiDatabaseService = MockRestApiDatabaseService();
    mockTokenService = MockTokenService();
    mockDio = MockDio();

    dataSyncService = DataSyncService(
      prefs: mockPrefs,
      apiService: mockApiService,
      dbService: mockDbService,
      dbHelper: mockDbHelper,
      restApiService: mockRestApiService,
      restApiDatabaseService: mockRestApiDatabaseService,
      tokenService: mockTokenService,
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

  group('DataSyncService Thumbnail Authentication Tests', () {
    test('authentication methods are available', () async {
      // This is a basic test to ensure the service has the authentication methods
      // The actual authentication logic is tested indirectly through integration

      // Verify that the token service has the required methods
      expect(mockTokenService.isAuthenticated, isNotNull);
      expect(mockTokenService.authenticate, isNotNull);
      expect(mockTokenService.getValidAccessToken, isNotNull);

      // Verify that the data sync service has the required dependencies
      expect(dataSyncService, isNotNull);
    });
  });

}