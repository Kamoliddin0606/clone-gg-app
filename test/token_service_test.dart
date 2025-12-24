import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

// Mock classes
class MockDio extends Mock implements Dio {}

class MockInterceptors extends Mock implements Interceptors {}

void main() {
  late TokenService tokenService;
  late MockDio mockDio;
  late SharedPreferencesService prefsService;

  setUp(() async {
    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    prefsService = await SharedPreferencesService.getInstance();
    
    // Create fresh mock instances for each test
    mockDio = MockDio();
    final mockInterceptors = MockInterceptors();
    
    // Setup interceptors stub - this must be done before TokenService instantiation
    when(mockDio.interceptors).thenReturn(mockInterceptors);
    
    // Create TokenService with mocked dependencies
    tokenService = TokenService(mockDio, prefsService);
    
    // Reset mock state to allow new stubbing in individual tests
    reset(mockDio);
    when(mockDio.interceptors).thenReturn(mockInterceptors);
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
        // ignore: deprecated_member_use_from_same_package
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
        // ignore: deprecated_member_use_from_same_package
        final result = await tokenService.authenticate(
          username: username,
          password: password,
        );

        // Assert
        expect(result, isFalse);
      });
    });

    // =========================================================================
    // YANGI 1C-LOGIN AVTORIZATSIYA TESTLARI
    // =========================================================================

    group('getTokensFrom1CLogin', () {
      /// 1C-Login uchun konstant endpoint
      const oneCLoginUrl = 'http://178.218.200.120:1596/api/v1/auth/1c-login/';
      const testLogin = 'test_login';
      const testPassword = 'test_password';
      const testProjectName = 'http://example.com/api';

      test('muvaffaqiyatli 1C-login orqali tokenlarni oladi va saqlaydi', () async {
        // Arrange - Mock response yaratish
        final mockResponse = Response(
          data: {
            'access': '1c_access_token_123',
            'refresh': '1c_refresh_token_456',
            'token_type': 'Bearer',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: oneCLoginUrl),
        );

        when(mockDio.post(
          oneCLoginUrl,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await tokenService.getTokensFrom1CLogin(
          login: testLogin,
          password: testPassword,
          projectName: testProjectName,
        );

        // Assert
        expect(result, isNotNull);
        expect(result!['access'], '1c_access_token_123');
        expect(result['refresh'], '1c_refresh_token_456');
        expect(result['token_type'], 'Bearer');
        expect(result['login_method'], '1c-login');

        // Verify API call
        verify(mockDio.post(
          oneCLoginUrl,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).called(1);
      });

      test('access_token va refresh_token formatidagi javobni ham qabul qiladi', () async {
        // Arrange - Alternative response format
        final mockResponse = Response(
          data: {
            'access_token': 'alt_access_token_123',
            'refresh_token': 'alt_refresh_token_456',
            'expires_in': 3600, // 1 soat sekundlarda
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: oneCLoginUrl),
        );

        when(mockDio.post(
          oneCLoginUrl,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await tokenService.getTokensFrom1CLogin(
          login: testLogin,
          password: testPassword,
          projectName: testProjectName,
        );

        // Assert
        expect(result, isNotNull);
        expect(result!['access'], 'alt_access_token_123');
        expect(result['refresh'], 'alt_refresh_token_456');
      });

      test('bo\'sh login bilan ArgumentError tashlaydi', () async {
        // Act & Assert
        expect(
          () => tokenService.getTokensFrom1CLogin(
            login: '',
            password: testPassword,
            projectName: testProjectName,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('bo\'sh password bilan ArgumentError tashlaydi', () async {
        // Act & Assert
        expect(
          () => tokenService.getTokensFrom1CLogin(
            login: testLogin,
            password: '',
            projectName: testProjectName,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('bo\'sh projectName bilan ArgumentError tashlaydi', () async {
        // Act & Assert
        expect(
          () => tokenService.getTokensFrom1CLogin(
            login: testLogin,
            password: testPassword,
            projectName: '',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('401 xatosida Exception tashlaydi', () async {
        // Arrange
        when(mockDio.post(
          oneCLoginUrl,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: oneCLoginUrl),
          response: Response(
            statusCode: 401,
            data: {'detail': 'Avtorizatsiya muvaffaqiyatsiz'},
            requestOptions: RequestOptions(path: oneCLoginUrl),
          ),
          type: DioExceptionType.badResponse,
        ));

        // Act & Assert
        expect(
          () => tokenService.getTokensFrom1CLogin(
            login: testLogin,
            password: testPassword,
            projectName: testProjectName,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('tarmoq xatosida (connection timeout) Exception tashlaydi', () async {
        // Arrange
        when(mockDio.post(
          oneCLoginUrl,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: oneCLoginUrl),
          type: DioExceptionType.connectionTimeout,
        ));

        // Act & Assert
        expect(
          () => tokenService.getTokensFrom1CLogin(
            login: testLogin,
            password: testPassword,
            projectName: testProjectName,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('javobda access token bo\'lmasa null qaytaradi', () async {
        // Arrange - Response without access token
        final mockResponse = Response(
          data: {
            'message': 'Success but no token',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: oneCLoginUrl),
        );

        when(mockDio.post(
          oneCLoginUrl,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await tokenService.getTokensFrom1CLogin(
          login: testLogin,
          password: testPassword,
          projectName: testProjectName,
        );

        // Assert
        expect(result, isNull);
      });
    });

    group('authenticateWith1CLogin', () {
      const oneCLoginUrl = 'http://178.218.200.120:1596/api/v1/auth/1c-login/';

      test('SharedPreferences dan credentials olgan holda muvaffaqiyatli autentifikatsiya', () async {
        // Arrange - Set up stored credentials
        await prefsService.saveCredentials('stored_login', 'stored_password', true);
        await prefsService.setBaseUrl('http://stored.project.com/api');

        final mockResponse = Response(
          data: {
            'access': 'auth_access_token',
            'refresh': 'auth_refresh_token',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: oneCLoginUrl),
        );

        when(mockDio.post(
          oneCLoginUrl,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await tokenService.authenticateWith1CLogin();

        // Assert
        expect(result, isTrue);
      });

      test('parametrlar bilan berilgan credentials dan foydalanadi', () async {
        // Arrange
        final mockResponse = Response(
          data: {
            'access': 'param_access_token',
            'refresh': 'param_refresh_token',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: oneCLoginUrl),
        );

        when(mockDio.post(
          oneCLoginUrl,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await tokenService.authenticateWith1CLogin(
          login: 'param_login',
          password: 'param_password',
          projectName: 'http://param.project.com',
        );

        // Assert
        expect(result, isTrue);
      });

      test('login mavjud bo\'lmasa false qaytaradi', () async {
        // Arrange - No login stored
        await prefsService.clearCredentials();
        await prefsService.setBaseUrl('http://some.project.com');

        // Act
        final result = await tokenService.authenticateWith1CLogin();

        // Assert
        expect(result, isFalse);
      });

      test('password mavjud bo\'lmasa false qaytaradi', () async {
        // Arrange - Login but no password
        await prefsService.preferences.setString('saved_username', 'some_login');
        await prefsService.preferences.remove('saved_password');
        await prefsService.setBaseUrl('http://some.project.com');

        // Act
        final result = await tokenService.authenticateWith1CLogin();

        // Assert
        expect(result, isFalse);
      });

      test('projectName (baseURL) mavjud bo\'lmasa false qaytaradi', () async {
        // Arrange - Credentials but no baseURL
        await prefsService.saveCredentials('some_login', 'some_password', true);
        await prefsService.clearBaseUrl();

        // Act
        final result = await tokenService.authenticateWith1CLogin();

        // Assert
        expect(result, isFalse);
      });

      test('API xatosida false qaytaradi', () async {
        // Arrange
        await prefsService.saveCredentials('test_login', 'test_password', true);
        await prefsService.setBaseUrl('http://test.project.com');

        when(mockDio.post(
          oneCLoginUrl,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: oneCLoginUrl),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: oneCLoginUrl),
          ),
        ));

        // Act
        final result = await tokenService.authenticateWith1CLogin();

        // Assert
        expect(result, isFalse);
      });
    });

    group('ensureValidToken with 1C-Login', () {
      const oneCLoginUrl = 'http://178.218.200.120:1596/api/v1/auth/1c-login/';

      test('yaroqli token mavjud bo\'lsa uni qaytaradi', () async {
        // Arrange - Set valid token
        await prefsService.preferences.setString('rest_api_access_token', 'valid_existing_token');
        await prefsService.preferences.setString('rest_api_token_expiry',
          DateTime.now().add(const Duration(hours: 2)).toIso8601String());

        // Act
        final result = await tokenService.ensureValidToken();

        // Assert
        expect(result, 'valid_existing_token');
      });

      test('token muddati tugagan bo\'lsa 1C-Login orqali yangilaydi', () async {
        // Arrange - Set expired token
        await prefsService.preferences.setString('rest_api_access_token', 'expired_token');
        await prefsService.preferences.setString('rest_api_token_expiry',
          DateTime.now().subtract(const Duration(hours: 1)).toIso8601String());
        await prefsService.preferences.remove('rest_api_refresh_token');
        
        // Set up credentials for re-auth
        await prefsService.saveCredentials('reauth_login', 'reauth_password', true);
        await prefsService.setBaseUrl('http://reauth.project.com');

        final mockResponse = Response(
          data: {
            'access': 'new_1c_token',
            'refresh': 'new_1c_refresh',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: oneCLoginUrl),
        );

        when(mockDio.post(
          oneCLoginUrl,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => mockResponse);

        // Also mock the refresh endpoint to fail
        when(mockDio.post(
          'http://178.218.200.120:1596/api/token/refresh/',
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: 'http://178.218.200.120:1596/api/token/refresh/'),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: 'http://178.218.200.120:1596/api/token/refresh/'),
          ),
        ));

        // Act
        final result = await tokenService.ensureValidToken();

        // Assert
        expect(result, 'new_1c_token');
      });

      test('credentials mavjud bo\'lmasa null qaytaradi', () async {
        // Arrange - Expired token, no credentials
        await prefsService.preferences.setString('rest_api_access_token', 'expired_token');
        await prefsService.preferences.setString('rest_api_token_expiry',
          DateTime.now().subtract(const Duration(hours: 1)).toIso8601String());
        await prefsService.preferences.remove('rest_api_refresh_token');
        await prefsService.clearCredentials();
        await prefsService.clearBaseUrl();

        // Mock refresh to fail
        when(mockDio.post(
          'http://178.218.200.120:1596/api/token/refresh/',
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: 'http://178.218.200.120:1596/api/token/refresh/'),
          type: DioExceptionType.badResponse,
        ));

        // Act
        final result = await tokenService.ensureValidToken();

        // Assert
        expect(result, isNull);
      });
    });
  });
}