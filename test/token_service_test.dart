import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

// Mock classes
class MockDio extends Mock implements Dio {}

void main() {
  late TokenService tokenService;
  late MockDio mockDio;
  late SharedPreferencesService prefsService;

  setUp(() async {
    mockDio = MockDio();
    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    prefsService = await SharedPreferencesService.getInstance();
    tokenService = TokenService(mockDio, prefsService);
  });

  group('TokenService Tests', () {
    const baseUrl = 'http://test.example.com';
    const username = 'testuser';
    const password = 'testpass';

    group('getTokens', () {
      test('successfully gets tokens and stores them', () async {
        // Arrange
        final mockResponse = Response(
          data: {
            'access': 'access_token_123',
            'refresh': 'refresh_token_456',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '$baseUrl/api/token/'),
        );

        when(mockDio.post(
          '$baseUrl/api/token/',
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await tokenService.getTokens(
          baseUrl: baseUrl,
          username: username,
          password: password,
        );

        // Assert
        expect(result, isNotNull);
        expect(result!['access'], 'access_token_123');
        expect(result['refresh'], 'refresh_token_456');

        verify(mockDio.post(
          '$baseUrl/api/token/',
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).called(1);
      });

      test('returns null on authentication failure', () async {
        // Arrange
        when(mockDio.post(
          '$baseUrl/api/token/',
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '$baseUrl/api/token/'),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '$baseUrl/api/token/'),
          ),
          type: DioExceptionType.badResponse,
        ));

        // Act
        final result = await tokenService.getTokens(
          baseUrl: baseUrl,
          username: username,
          password: password,
        );

        // Assert
        expect(result, isNull);
      });

      test('handles network errors during token request', () async {
        // Arrange
        when(mockDio.post(
          '$baseUrl/api/token/',
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '$baseUrl/api/token/'),
          type: DioExceptionType.connectionTimeout,
        ));

        // Act & Assert
        expect(
          () => tokenService.getTokens(
            baseUrl: baseUrl,
            username: username,
            password: password,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getValidAccessToken', () {
      test('returns stored access token when available and valid', () async {
        // Arrange - Set up stored token
        await prefsService.preferences.setString('rest_api_access_token', 'valid_token_123');
        await prefsService.preferences.setString('rest_api_token_expiry',
          DateTime.now().add(const Duration(hours: 1)).toIso8601String());

        // Act
        final result = await tokenService.getValidAccessToken();

        // Assert
        expect(result, 'valid_token_123');
      });

      test('returns null when no token is stored', () async {
        // Arrange - Ensure no tokens are stored
        await prefsService.preferences.remove('rest_api_access_token');

        // Act
        final result = await tokenService.getValidAccessToken();

        // Assert
        expect(result, isNull);
      });
    });

    group('clearTokens', () {
      test('successfully clears all stored tokens', () async {
        // Arrange - Set up some tokens
        await prefsService.preferences.setString('rest_api_access_token', 'token_123');
        await prefsService.preferences.setString('rest_api_refresh_token', 'refresh_456');
        await prefsService.preferences.setString('rest_api_token_expiry', '2025-01-01');
        await prefsService.preferences.setString('rest_api_token_type', 'Bearer');

        // Act
        await tokenService.clearTokens();

        // Assert
        expect(prefsService.preferences.getString('rest_api_access_token'), isNull);
        expect(prefsService.preferences.getString('rest_api_refresh_token'), isNull);
        expect(prefsService.preferences.getString('rest_api_token_expiry'), isNull);
        expect(prefsService.preferences.getString('rest_api_token_type'), isNull);
      });
    });

    group('isAuthenticated', () {
      test('returns true when valid token exists', () async {
        // Arrange
        await prefsService.preferences.setString('rest_api_access_token', 'valid_token_123');
        await prefsService.preferences.setString('rest_api_token_expiry',
          DateTime.now().add(const Duration(hours: 1)).toIso8601String());

        // Act
        final result = await tokenService.isAuthenticated();

        // Assert
        expect(result, isTrue);
      });

      test('returns false when no valid token exists', () async {
        // Arrange
        await prefsService.preferences.remove('rest_api_access_token');

        // Act
        final result = await tokenService.isAuthenticated();

        // Assert
        expect(result, isFalse);
      });
    });

    group('authenticate', () {
      test('successfully authenticates user', () async {
        // Arrange
        final mockResponse = Response(
          data: {
            'access': 'access_token_123',
            'refresh': 'refresh_token_456',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: 'http://178.218.200.120:1596/api/token/'),
        );

        when(mockDio.post(
          'http://178.218.200.120:1596/api/token/',
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await tokenService.authenticate(
          username: username,
          password: password,
        );

        // Assert
        expect(result, isTrue);
      });

      test('returns false on authentication failure', () async {
        // Arrange
        when(mockDio.post(
          'http://178.218.200.120:1596/api/token/',
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: 'http://178.218.200.120:1596/api/token/'),
          type: DioExceptionType.badResponse,
        ));

        // Act
        final result = await tokenService.authenticate(
          username: username,
          password: password,
        );

        // Assert
        expect(result, isFalse);
      });
    });
  });
}