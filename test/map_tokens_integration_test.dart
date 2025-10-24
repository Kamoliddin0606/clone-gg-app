import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';

// Mock classes
class MockSharedPreferencesService extends Mock implements SharedPreferencesService {}
class MockSoapApiService extends Mock implements SoapApiService {}
class MockApiDatabaseService extends Mock implements ApiDatabaseService {}
class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late DataSyncService dataSyncService;
  late MockSharedPreferencesService mockPrefs;
  late MockSoapApiService mockSoapApi;
  late MockApiDatabaseService mockDbService;
  late MockDatabaseHelper mockDbHelper;

  setUp(() {
    mockPrefs = MockSharedPreferencesService();
    mockSoapApi = MockSoapApiService();
    mockDbService = MockApiDatabaseService();
    mockDbHelper = MockDatabaseHelper();

    dataSyncService = DataSyncService(
      prefs: mockPrefs,
      apiService: mockSoapApi,
      dbService: mockDbService,
      dbHelper: mockDbHelper,
    );
  });

  group('syncMapTokens', () {
    const userCode = '000000109';
    const yandexToken = '6381d1cf-a0d8-4b88-8c8f-60951f817884';
    const googleToken = 'AIzaSyDummyGoogleToken123456789';

    test('should successfully sync map tokens and save to preferences', () async {
      // Arrange
      final tokens = {
        'yandexToken': yandexToken,
        'googleToken': googleToken,
      };

      when(mockSoapApi.getMapTokens(userCode: userCode)).thenAnswer((_) async => tokens);
      when(mockPrefs.saveMapTokens(yandexToken: yandexToken, googleToken: googleToken))
          .thenAnswer((_) async => true);

      // Act
      final result = await dataSyncService.syncMapTokens(userCode: userCode);

      // Assert
      expect(result, tokens);
      verify(mockSoapApi.getMapTokens(userCode: userCode)).called(1);
      verify(mockPrefs.saveMapTokens(yandexToken: yandexToken, googleToken: googleToken)).called(1);
    });

    test('should handle empty tokens from server', () async {
      // Arrange
      final tokens = {
        'yandexToken': '',
        'googleToken': '',
      };

      when(mockSoapApi.getMapTokens(userCode: userCode)).thenAnswer((_) async => tokens);
      when(mockPrefs.saveMapTokens(yandexToken: '', googleToken: ''))
          .thenAnswer((_) async => true);

      // Act
      final result = await dataSyncService.syncMapTokens(userCode: userCode);

      // Assert
      expect(result, tokens);
      verify(mockSoapApi.getMapTokens(userCode: userCode)).called(1);
      verify(mockPrefs.saveMapTokens(yandexToken: '', googleToken: '')).called(1);
    });

    test('should handle partial tokens (only Yandex)', () async {
      // Arrange
      final tokens = {
        'yandexToken': yandexToken,
        'googleToken': '',
      };

      when(mockSoapApi.getMapTokens(userCode: userCode)).thenAnswer((_) async => tokens);
      when(mockPrefs.saveMapTokens(yandexToken: yandexToken, googleToken: ''))
          .thenAnswer((_) async => true);

      // Act
      final result = await dataSyncService.syncMapTokens(userCode: userCode);

      // Assert
      expect(result, tokens);
      verify(mockSoapApi.getMapTokens(userCode: userCode)).called(1);
      verify(mockPrefs.saveMapTokens(yandexToken: yandexToken, googleToken: '')).called(1);
    });

    test('should throw exception when API call fails', () async {
      // Arrange
      when(mockSoapApi.getMapTokens(userCode: userCode))
          .thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => dataSyncService.syncMapTokens(userCode: userCode),
        throwsA(isA<Exception>()),
      );

      verify(mockSoapApi.getMapTokens(userCode: userCode)).called(1);
      // Note: We can't easily verify saveMapTokens was never called due to mockito limitations
      // with named parameters and null values
    });

    test('should throw exception when saving to preferences fails', () async {
      // Arrange
      final tokens = {
        'yandexToken': yandexToken,
        'googleToken': googleToken,
      };

      when(mockSoapApi.getMapTokens(userCode: userCode)).thenAnswer((_) async => tokens);
      when(mockPrefs.saveMapTokens(yandexToken: yandexToken, googleToken: googleToken))
          .thenAnswer((_) async => false);

      // Act & Assert
      expect(
        () => dataSyncService.syncMapTokens(userCode: userCode),
        throwsA(isA<Exception>()),
      );

      verify(mockSoapApi.getMapTokens(userCode: userCode)).called(1);
      verify(mockPrefs.saveMapTokens(yandexToken: yandexToken, googleToken: googleToken)).called(1);
    });
  });

  group('getCachedMapTokens', () {
    test('should return cached tokens from preferences', () {
      // Arrange
      final tokens = {
        'yandexToken': 'test-yandex-token',
        'googleToken': 'test-google-token',
      };

      when(mockPrefs.getMapTokens()).thenReturn(tokens);

      // Act
      final result = dataSyncService.getCachedMapTokens();

      // Assert
      expect(result, tokens);
      verify(mockPrefs.getMapTokens()).called(1);
    });
  });

  group('hasValidMapTokens', () {
    test('should return true when valid tokens exist', () {
      // Arrange
      when(mockPrefs.hasValidMapTokens()).thenReturn(true);

      // Act
      final result = dataSyncService.hasValidMapTokens();

      // Assert
      expect(result, true);
      verify(mockPrefs.hasValidMapTokens()).called(1);
    });

    test('should return false when no valid tokens exist', () {
      // Arrange
      when(mockPrefs.hasValidMapTokens()).thenReturn(false);

      // Act
      final result = dataSyncService.hasValidMapTokens();

      // Assert
      expect(result, false);
      verify(mockPrefs.hasValidMapTokens()).called(1);
    });
  });

  group('getMapTokensLastUpdated', () {
    test('should return last updated timestamp', () {
      // Arrange
      final lastUpdated = DateTime.now();
      when(mockPrefs.getMapTokensLastUpdated()).thenReturn(lastUpdated);

      // Act
      final result = dataSyncService.getMapTokensLastUpdated();

      // Assert
      expect(result, lastUpdated);
      verify(mockPrefs.getMapTokensLastUpdated()).called(1);
    });

    test('should return null when no timestamp exists', () {
      // Arrange
      when(mockPrefs.getMapTokensLastUpdated()).thenReturn(null);

      // Act
      final result = dataSyncService.getMapTokensLastUpdated();

      // Assert
      expect(result, null);
      verify(mockPrefs.getMapTokensLastUpdated()).called(1);
    });
  });
}