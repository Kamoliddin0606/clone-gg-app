import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/business_region.dart';

// Generate mocks
@GenerateMocks([
  SharedPreferencesService,
  SoapApiService,
  ApiDatabaseService,
  DatabaseHelper,
])
import 'business_region_sync_test.mocks.dart';

void main() {
  late MockSharedPreferencesService mockPrefs;
  late MockSoapApiService mockApiService;
  late MockApiDatabaseService mockDbService;
  late MockDatabaseHelper mockDbHelper;
  late DataSyncService dataSyncService;

  setUp(() {
    mockPrefs = MockSharedPreferencesService();
    mockApiService = MockSoapApiService();
    mockDbService = MockApiDatabaseService();
    mockDbHelper = MockDatabaseHelper();

    dataSyncService = DataSyncService(
      prefs: mockPrefs,
      apiService: mockApiService,
      dbService: mockDbService,
      dbHelper: mockDbHelper,
    );
  });

  group('BusinessRegion Sync Operations', () {
    test('syncBusinessRegions should fetch from API and save to database', () async {
      // Arrange
      const userCode = 'TEST_USER';
      final regions = [
        BusinessRegion(code: 'REG001', name: 'Region 1'),
        BusinessRegion(code: 'REG002', name: 'Region 2'),
      ];

      when(mockApiService.getBusinessRegions(userCode: userCode))
          .thenAnswer((_) async => regions);
      when(mockDbService.getBusinessRegions())
          .thenAnswer((_) async => []);

      // Act
      final result = await dataSyncService.syncBusinessRegions(userCode: userCode);

      // Assert
      expect(result, regions);
      verify(mockApiService.getBusinessRegions(userCode: userCode)).called(1);
      verify(mockDbService.saveBusinessRegions(regions)).called(1);
    });

    test('syncBusinessRegions should return cached data when available', () async {
      // Arrange
      const userCode = 'TEST_USER';
      final cachedRegions = [
        BusinessRegion(code: 'REG001', name: 'Region 1'),
      ];

      when(mockDbService.getBusinessRegions())
          .thenAnswer((_) async => cachedRegions);

      // Act
      final result = await dataSyncService.syncBusinessRegions(
        userCode: userCode,
        forceRefresh: false,
      );

      // Assert
      expect(result, cachedRegions);
      verifyNever(mockApiService.getBusinessRegions(userCode: userCode));
      verifyNever(mockDbService.saveBusinessRegions(any));
    });

    test('createBusinessRegion should validate input and call API', () async {
      // Arrange
      const userCode = 'TEST_USER';
      const code = 'REG001';
      const name = 'Test Region';
      final expectedRegion = BusinessRegion(
        code: code,
        name: name,
        createdAt: anyNamed('createdAt'),
        updatedAt: anyNamed('updatedAt'),
      );

      when(mockDbService.getBusinessRegionByCode(code))
          .thenAnswer((_) async => null);
      when(mockApiService.createBusinessRegion(
        userCode: userCode,
        code: code,
        name: name,
      )).thenAnswer((_) async => 'Success');
      when(mockDbService.saveBusinessRegion(any))
          .thenAnswer((_) async {});

      // Act
      final result = await dataSyncService.createBusinessRegion(
        userCode: userCode,
        code: code,
        name: name,
      );

      // Assert
      expect(result.code, code);
      expect(result.name, name);
      verify(mockApiService.createBusinessRegion(
        userCode: userCode,
        code: code,
        name: name,
      )).called(1);
      verify(mockDbService.saveBusinessRegion(any)).called(1);
    });

    test('createBusinessRegion should throw error for empty code', () async {
      // Act & Assert
      expect(
        () => dataSyncService.createBusinessRegion(
          userCode: 'TEST_USER',
          code: '',
          name: 'Test Region',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Kod va nom bo\'sh bo\'lishi mumkin emas'),
        )),
      );
    });

    test('createBusinessRegion should throw error for duplicate code', () async {
      // Arrange
      const code = 'REG001';
      final existingRegion = BusinessRegion(code: code, name: 'Existing');

      when(mockDbService.getBusinessRegionByCode(code))
          .thenAnswer((_) async => existingRegion);

      // Act & Assert
      expect(
        () => dataSyncService.createBusinessRegion(
          userCode: 'TEST_USER',
          code: code,
          name: 'New Region',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Bu kod bilan biznes rayoni allaqachon mavjud'),
        )),
      );
    });

    test('updateBusinessRegion should validate and update', () async {
      // Arrange
      const userCode = 'TEST_USER';
      const code = 'REG001';
      const newName = 'Updated Region';
      final existingRegion = BusinessRegion(code: code, name: 'Old Name');

      when(mockDbService.getBusinessRegionByCode(code))
          .thenAnswer((_) async => existingRegion);
      when(mockApiService.updateBusinessRegion(
        userCode: userCode,
        code: code,
        name: newName,
      )).thenAnswer((_) async => 'Success');
      when(mockDbService.updateBusinessRegion(code, any))
          .thenAnswer((_) async {});

      // Act
      final result = await dataSyncService.updateBusinessRegion(
        userCode: userCode,
        code: code,
        name: newName,
      );

      // Assert
      expect(result.code, code);
      expect(result.name, newName);
      verify(mockApiService.updateBusinessRegion(
        userCode: userCode,
        code: code,
        name: newName,
      )).called(1);
      verify(mockDbService.updateBusinessRegion(code, any)).called(1);
    });

    test('deleteBusinessRegion should delete when no dependencies', () async {
      // Arrange
      const userCode = 'TEST_USER';
      const code = 'REG001';
      final region = BusinessRegion(code: code, name: 'Test Region');

      when(mockDbService.getBusinessRegionByCode(code))
          .thenAnswer((_) async => region);
      when(mockApiService.deleteBusinessRegion(
        userCode: userCode,
        code: code,
      )).thenAnswer((_) async => 'Success');
      when(mockDbService.deleteBusinessRegion(code))
          .thenAnswer((_) async {});

      // Act
      await dataSyncService.deleteBusinessRegion(
        userCode: userCode,
        code: code,
      );

      // Assert
      verify(mockApiService.deleteBusinessRegion(
        userCode: userCode,
        code: code,
      )).called(1);
      verify(mockDbService.deleteBusinessRegion(code)).called(1);
    });

    test('deleteAllBusinessRegions should delete all regions', () async {
      // Arrange
      const userCode = 'TEST_USER';

      when(mockApiService.deleteAllBusinessRegions(userCode: userCode))
          .thenAnswer((_) async => 'Success');
      when(mockDbService.clearAllData()).thenAnswer((_) async {});

      // Act
      await dataSyncService.deleteAllBusinessRegions(userCode: userCode);

      // Assert
      verify(mockApiService.deleteAllBusinessRegions(userCode: userCode)).called(1);
      verify(mockDbService.clearAllData()).called(1);
    });

    test('getCachedBusinessRegions should return cached data', () async {
      // Arrange
      final cachedRegions = [
        BusinessRegion(code: 'REG001', name: 'Region 1'),
      ];

      when(mockDbService.getBusinessRegions())
          .thenAnswer((_) async => cachedRegions);

      // Act
      final result = await dataSyncService.getCachedBusinessRegions();

      // Assert
      expect(result, cachedRegions);
      verify(mockDbService.getBusinessRegions()).called(1);
    });
  });
}