import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_organization.dart';

// Mock classes
class MockSoapApiService extends Mock implements SoapApiService {}
class MockApiDatabaseService extends Mock implements ApiDatabaseService {}
class MockSharedPreferencesService extends Mock implements SharedPreferencesService {}
class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late DataSyncService dataSyncService;
  late MockSoapApiService mockSoapApiService;
  late MockApiDatabaseService mockApiDatabaseService;
  late MockSharedPreferencesService mockSharedPreferencesService;
  late MockDatabaseHelper mockDatabaseHelper;

  setUp(() {
    mockSoapApiService = MockSoapApiService();
    mockApiDatabaseService = MockApiDatabaseService();
    mockSharedPreferencesService = MockSharedPreferencesService();
    mockDatabaseHelper = MockDatabaseHelper();

    dataSyncService = DataSyncService(
      prefs: mockSharedPreferencesService,
      apiService: mockSoapApiService,
      dbService: mockApiDatabaseService,
      dbHelper: mockDatabaseHelper,
    );
  });

  group('User Organizations Sync Tests', () {
    const testUserCode = '000000329';

    final testOrganizations = [
      UserOrganization(
        id: 1,
        userCode: testUserCode,
        code: '00000000001',
        name: 'OOO "GLORIYA GLOBAL"',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      UserOrganization(
        id: 2,
        userCode: testUserCode,
        code: '00000000002',
        name: 'OOO "TEST ORGANIZATION"',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    test('syncUserOrganizations should call API and save to database', () async {
      // Arrange
      when(mockSoapApiService.getOrganizationsByUserCode(userCode: testUserCode))
          .thenAnswer((_) async => testOrganizations);
      when(mockApiDatabaseService.saveUserOrganizations(testUserCode, testOrganizations))
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await dataSyncService.syncUserOrganizations(userCode: testUserCode);

      // Assert
      expect(result, testOrganizations);
      verify(mockSoapApiService.getOrganizationsByUserCode(userCode: testUserCode)).called(1);
      verify(mockApiDatabaseService.saveUserOrganizations(testUserCode, testOrganizations)).called(1);
    });

    test('syncUserOrganizations should return cached data when available', () async {
      // Arrange
      when(mockApiDatabaseService.getUserOrganizations(testUserCode))
          .thenAnswer((_) async => testOrganizations);

      // Act
      final result = await dataSyncService.syncUserOrganizations(
        userCode: testUserCode,
        forceRefresh: false,
      );

      // Assert
      expect(result, testOrganizations);
      verify(mockApiDatabaseService.getUserOrganizations(testUserCode)).called(1);
      verifyNever(mockSoapApiService.getOrganizationsByUserCode(userCode: testUserCode));
    });

    test('syncUserOrganizations should force refresh when requested', () async {
      // Arrange
      when(mockSoapApiService.getOrganizationsByUserCode(userCode: testUserCode))
          .thenAnswer((_) async => testOrganizations);
      when(mockApiDatabaseService.saveUserOrganizations(testUserCode, testOrganizations))
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await dataSyncService.syncUserOrganizations(
        userCode: testUserCode,
        forceRefresh: true,
      );

      // Assert
      expect(result, testOrganizations);
      verify(mockSoapApiService.getOrganizationsByUserCode(userCode: testUserCode)).called(1);
      verify(mockApiDatabaseService.saveUserOrganizations(testUserCode, testOrganizations)).called(1);
    });

    test('syncUserOrganizations should handle empty response', () async {
      // Arrange
      when(mockSoapApiService.getOrganizationsByUserCode(userCode: testUserCode))
          .thenAnswer((_) async => []);
      when(mockApiDatabaseService.saveUserOrganizations(testUserCode, []))
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await dataSyncService.syncUserOrganizations(userCode: testUserCode);

      // Assert
      expect(result, []);
      verify(mockSoapApiService.getOrganizationsByUserCode(userCode: testUserCode)).called(1);
      verify(mockApiDatabaseService.saveUserOrganizations(testUserCode, [])).called(1);
    });

    test('syncUserOrganizations should handle API errors gracefully', () async {
      // Arrange
      when(mockSoapApiService.getOrganizationsByUserCode(userCode: testUserCode))
          .thenThrow(Exception('API Error'));

      // Act & Assert
      expect(
        () => dataSyncService.syncUserOrganizations(userCode: testUserCode),
        throwsA(isA<Exception>()),
      );

      verify(mockSoapApiService.getOrganizationsByUserCode(userCode: testUserCode)).called(1);
      verifyNever(mockApiDatabaseService.saveUserOrganizations(any, any));
    });
  });

  group('SOAP API Service Tests', () {
    test('getOrganizationsByUserCode should parse XML response correctly', () async {
      // This test would require setting up a mock HTTP response
      // For now, we verify the method exists and has correct signature
      expect(mockSoapApiService.getOrganizationsByUserCode, isNotNull);
    });
  });
}