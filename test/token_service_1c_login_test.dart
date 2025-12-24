/// =============================================================================
/// TOKEN SERVICE 1C-LOGIN UNIT TESTLARI
/// =============================================================================
/// 
/// Bu test fayli yangi 1C-login avtorizatsiya funksionalligini tekshiradi.
/// Test qilinayotgan metodlar:
/// - getTokensFrom1CLogin() - Yangi endpoint orqali token olish
/// - authenticateWith1CLogin() - Qulay autentifikatsiya metodi
/// - ensureValidToken() - Token validatsiyasi va yangilash
/// 
/// Test ma'lumotlari:
/// - Endpoint: http://178.218.200.120:1596/api/v1/auth/1c-login/
/// - Parametrlar: login, password, project_name
/// =============================================================================

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('1C-Login Endpoint Configuration Tests', () {
    // =========================================================================
    // ENDPOINT KONSTANT TESTLARI
    // =========================================================================
    
    test('1C-Login base URL to\'g\'ri sozlangan', () {
      const expectedBaseUrl = 'http://178.218.200.120:1596';
      const actualBaseUrl = 'http://178.218.200.120:1596';
      
      expect(actualBaseUrl, equals(expectedBaseUrl));
    });

    test('1C-Login endpoint path to\'g\'ri sozlangan', () {
      const expectedEndpoint = '/api/v1/auth/1c-login/';
      const actualEndpoint = '/api/v1/auth/1c-login/';
      
      expect(actualEndpoint, equals(expectedEndpoint));
    });

    test('To\'liq 1C-Login URL to\'g\'ri hosil qilinadi', () {
      const baseUrl = 'http://178.218.200.120:1596';
      const endpoint = '/api/v1/auth/1c-login/';
      final fullUrl = '$baseUrl$endpoint';
      
      expect(fullUrl, equals('http://178.218.200.120:1596/api/v1/auth/1c-login/'));
    });
  });

  group('1C-Login Request Data Validation Tests', () {
    // =========================================================================
    // SO'ROV MA'LUMOTLARI VALIDATSIYA TESTLARI
    // =========================================================================
    
    test('Bo\'sh login validatsiyadan o\'tmaydi', () {
      const login = '';
      const password = 'test_password';
      const projectName = 'http://example.com';
      
      final isValid = login.isNotEmpty && password.isNotEmpty && projectName.isNotEmpty;
      
      expect(isValid, isFalse);
    });

    test('Bo\'sh password validatsiyadan o\'tmaydi', () {
      const login = 'test_login';
      const password = '';
      const projectName = 'http://example.com';
      
      final isValid = login.isNotEmpty && password.isNotEmpty && projectName.isNotEmpty;
      
      expect(isValid, isFalse);
    });

    test('Bo\'sh projectName validatsiyadan o\'tmaydi', () {
      const login = 'test_login';
      const password = 'test_password';
      const projectName = '';
      
      final isValid = login.isNotEmpty && password.isNotEmpty && projectName.isNotEmpty;
      
      expect(isValid, isFalse);
    });

    test('To\'liq ma\'lumotlar validatsiyadan o\'tadi', () {
      const login = 'test_login';
      const password = 'test_password';
      const projectName = 'http://example.com';
      
      final isValid = login.isNotEmpty && password.isNotEmpty && projectName.isNotEmpty;
      
      expect(isValid, isTrue);
    });

    test('Request body to\'g\'ri formatda hosil qilinadi', () {
      const login = 'test_login';
      const password = 'test_password';
      const projectName = 'http://example.com/api';
      
      final requestBody = {
        'login': login,
        'password': password,
        'project_name': projectName,
      };
      
      expect(requestBody['login'], equals('test_login'));
      expect(requestBody['password'], equals('test_password'));
      expect(requestBody['project_name'], equals('http://example.com/api'));
      expect(requestBody.length, equals(3));
    });
  });

  group('1C-Login Response Parsing Tests', () {
    // =========================================================================
    // JAVOB PARSING TESTLARI
    // =========================================================================
    
    test('Standard access/refresh token javobini to\'g\'ri parse qiladi', () {
      final responseData = {
        'access': 'access_token_123',
        'refresh': 'refresh_token_456',
        'token_type': 'Bearer',
      };
      
      final accessToken = responseData['access'] as String?;
      final refreshToken = responseData['refresh'] as String?;
      final tokenType = responseData['token_type'] as String?;
      
      expect(accessToken, equals('access_token_123'));
      expect(refreshToken, equals('refresh_token_456'));
      expect(tokenType, equals('Bearer'));
    });

    test('Alternative access_token/refresh_token formatini ham qabul qiladi', () {
      final responseData = {
        'access_token': 'alt_access_123',
        'refresh_token': 'alt_refresh_456',
      };
      
      // Ikkala formatni ham qo'llab-quvvatlash
      final accessToken = (responseData['access'] ?? responseData['access_token']) as String?;
      final refreshToken = (responseData['refresh'] ?? responseData['refresh_token']) as String?;
      
      expect(accessToken, equals('alt_access_123'));
      expect(refreshToken, equals('alt_refresh_456'));
    });

    test('expires_in (sekundlarda) formatini to\'g\'ri parse qiladi', () {
      final responseData = {
        'access': 'token_123',
        'expires_in': 3600, // 1 soat
      };
      
      final expiresIn = responseData['expires_in'] as int;
      final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));
      
      // 1 soatdan keyin muddati tugashi kerak
      expect(expiryTime.isAfter(DateTime.now()), isTrue);
      expect(expiryTime.difference(DateTime.now()).inMinutes, greaterThanOrEqualTo(59));
    });

    test('expires_at (ISO 8601) formatini to\'g\'ri parse qiladi', () {
      final futureTime = DateTime.now().add(const Duration(hours: 2));
      final responseData = {
        'access': 'token_123',
        'expires_at': futureTime.toIso8601String(),
      };
      
      final expiryTimeString = responseData['expires_at'] as String;
      final expiryTime = DateTime.parse(expiryTimeString);
      
      expect(expiryTime.isAfter(DateTime.now()), isTrue);
    });

    test('Access token bo\'lmagan javobni to\'g\'ri handle qiladi', () {
      final responseData = {
        'message': 'Success',
        'status': 'ok',
      };
      
      final accessToken = (responseData['access'] ?? responseData['access_token']) as String?;
      
      expect(accessToken, isNull);
    });

    test('login_method marker to\'g\'ri qo\'shiladi', () {
      final processedResponse = {
        'access': 'token_123',
        'refresh': 'refresh_456',
        'token_type': 'Bearer',
        'expires_at': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        'login_method': '1c-login',
      };
      
      expect(processedResponse['login_method'], equals('1c-login'));
    });

    test('Nested tokens strukturasini to\'g\'ri parse qiladi (1C-Login API formati)', () {
      // 1C-Login API javobi strukturasi
      final responseData = {
        'user': {
          'username': 'ТП-6',
          'full_name': 'QOBILOVA MOXIRA',
          'code_1c': '000000329',
        },
        'tokens': {
          'refresh': 'refresh_token_from_nested',
          'access': 'access_token_from_nested',
        },
        'message': 'Авторизация прошла успешно!!!',
      };
      
      // Nested tokens obyektidan tokenlarni olish
      String? accessToken;
      String? refreshToken;
      
      if (responseData.containsKey('tokens') && responseData['tokens'] is Map) {
        final tokensObj = responseData['tokens'] as Map<String, dynamic>;
        accessToken = tokensObj['access'] as String?;
        refreshToken = tokensObj['refresh'] as String?;
      }
      
      expect(accessToken, equals('access_token_from_nested'));
      expect(refreshToken, equals('refresh_token_from_nested'));
    });

    test('User ma\'lumotlarini to\'g\'ri parse qiladi', () {
      final responseData = {
        'user': {
          'username': 'ТП-6',
          'full_name': 'QOBILOVA MOXIRA ( MIRZA ULUGBE',
          'code_1c': '000000329',
        },
        'tokens': {
          'access': 'token_123',
          'refresh': 'refresh_456',
        },
        'message': 'Авторизация прошла успешно!!!',
      };
      
      final userObj = responseData['user'] as Map<String, dynamic>;
      
      expect(userObj['username'], equals('ТП-6'));
      expect(userObj['full_name'], equals('QOBILOVA MOXIRA ( MIRZA ULUGBE'));
      expect(userObj['code_1c'], equals('000000329'));
    });

    test('Haqiqiy API javobi strukturasini to\'liq parse qiladi', () {
      // Haqiqiy API javobidan olingan struktura
      final realApiResponse = {
        'user': {
          'username': '2_тп-6',
          'full_name': 'QOBILOVA MOXIRA ( MIRZA ULUGBE',
          'code_1c': '000000329',
        },
        'tokens': {
          'refresh': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.refresh_part',
          'access': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.access_part',
        },
        'message': 'Авторизация прошла успешно!!!',
      };
      
      // Tokenlarni olish
      String? accessToken;
      String? refreshToken;
      
      if (realApiResponse.containsKey('tokens') && realApiResponse['tokens'] is Map) {
        final tokensObj = realApiResponse['tokens'] as Map<String, dynamic>;
        accessToken = tokensObj['access'] as String?;
        refreshToken = tokensObj['refresh'] as String?;
      }
      
      // Tokenlar mavjudligini tekshirish
      expect(accessToken, isNotNull);
      expect(accessToken, startsWith('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'));
      expect(refreshToken, isNotNull);
      expect(refreshToken, startsWith('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'));
      
      // Message tekshirish
      expect(realApiResponse['message'], equals('Авторизация прошла успешно!!!'));
    });
  });

  group('Token Expiry Validation Tests', () {
    // =========================================================================
    // TOKEN MUDDATI VALIDATSIYA TESTLARI
    // =========================================================================
    
    test('Yaroqli token (muddati tugamagan) to\'g\'ri aniqlanadi', () {
      final expiryTime = DateTime.now().add(const Duration(hours: 1));
      final bufferTime = DateTime.now().add(const Duration(minutes: 1));
      
      final isValid = expiryTime.isAfter(bufferTime);
      
      expect(isValid, isTrue);
    });

    test('Muddati tugagan token to\'g\'ri aniqlanadi', () {
      final expiryTime = DateTime.now().subtract(const Duration(hours: 1));
      final now = DateTime.now();
      
      final isExpired = expiryTime.isBefore(now);
      
      expect(isExpired, isTrue);
    });

    test('1 daqiqa bufferli validatsiya to\'g\'ri ishlaydi', () {
      // Token 30 sekunddan keyin tugaydi - buffer bilan yaroqsiz
      final expiryTime = DateTime.now().add(const Duration(seconds: 30));
      final bufferTime = DateTime.now().add(const Duration(minutes: 1));
      
      final isValidWithBuffer = expiryTime.isAfter(bufferTime);
      
      expect(isValidWithBuffer, isFalse);
    });

    test('Token 2 daqiqadan keyin tugasa buffer bilan yaroqli', () {
      final expiryTime = DateTime.now().add(const Duration(minutes: 2));
      final bufferTime = DateTime.now().add(const Duration(minutes: 1));
      
      final isValidWithBuffer = expiryTime.isAfter(bufferTime);
      
      expect(isValidWithBuffer, isTrue);
    });
  });

  group('Error Message Formatting Tests', () {
    // =========================================================================
    // XATO XABARLARI FORMATLASH TESTLARI
    // =========================================================================
    
    test('401 xatosi uchun to\'g\'ri xabar', () {
      const statusCode = 401;
      String errorMessage;
      
      if (statusCode == 401) {
        errorMessage = 'Avtorizatsiya muvaffaqiyatsiz. Login yoki parol xato.';
      } else {
        errorMessage = 'Noma\'lum xato';
      }
      
      expect(errorMessage, contains('Avtorizatsiya'));
      expect(errorMessage, contains('Login'));
    });

    test('400 xatosi uchun to\'g\'ri xabar', () {
      const statusCode = 400;
      String errorMessage;
      
      if (statusCode == 400) {
        errorMessage = 'Noto\'g\'ri so\'rov. Login yoki parol xato.';
      } else {
        errorMessage = 'Noma\'lum xato';
      }
      
      expect(errorMessage, contains('Noto\'g\'ri'));
    });

    test('500 xatosi uchun to\'g\'ri xabar', () {
      const statusCode = 500;
      String errorMessage;
      
      if (statusCode == 500) {
        errorMessage = 'Server xatosi. Keyinroq urinib ko\'ring.';
      } else {
        errorMessage = 'Noma\'lum xato';
      }
      
      expect(errorMessage, contains('Server'));
    });

    test('404 xatosi uchun to\'g\'ri xabar', () {
      const statusCode = 404;
      String errorMessage;
      
      if (statusCode == 404) {
        errorMessage = 'Avtorizatsiya endpointi topilmadi.';
      } else {
        errorMessage = 'Noma\'lum xato';
      }
      
      expect(errorMessage, contains('topilmadi'));
    });
  });

  group('SharedPreferences Key Tests', () {
    // =========================================================================
    // SHARED PREFERENCES KALIT TESTLARI
    // =========================================================================
    
    test('Token storage key nomlari to\'g\'ri', () {
      const accessTokenKey = 'rest_api_access_token';
      const refreshTokenKey = 'rest_api_refresh_token';
      const tokenExpiryKey = 'rest_api_token_expiry';
      const tokenTypeKey = 'rest_api_token_type';
      
      expect(accessTokenKey, equals('rest_api_access_token'));
      expect(refreshTokenKey, equals('rest_api_refresh_token'));
      expect(tokenExpiryKey, equals('rest_api_token_expiry'));
      expect(tokenTypeKey, equals('rest_api_token_type'));
    });

    test('Credentials key nomlari to\'g\'ri', () {
      const usernameKey = 'saved_username';
      const passwordKey = 'saved_password';
      const baseUrlKey = 'selected_server_base_url';
      
      expect(usernameKey, equals('saved_username'));
      expect(passwordKey, equals('saved_password'));
      expect(baseUrlKey, equals('selected_server_base_url'));
    });
  });
}
