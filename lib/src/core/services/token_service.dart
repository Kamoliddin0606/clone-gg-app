import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:gloria_marketing_flutter/src/core/auth/backend_permission_store.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/auth_failure.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/login_device_payload.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/login_gates_envelope.dart';

/// Token Service for managing authentication tokens for REST API
/// This service handles token acquisition, storage, refresh, and validation
/// for the REST API endpoints that require authentication
class TokenService {
  final Dio _dio;
  final SharedPreferencesService _prefsService;

  // Token storage keys
  static const String _accessTokenKey = 'rest_api_access_token';
  static const String _refreshTokenKey = 'rest_api_refresh_token';
  static const String _tokenExpiryKey = 'rest_api_token_expiry';
  static const String _tokenTypeKey = 'rest_api_token_type';

  // =========================================================================
  // 1C LOGIN AUTHENTICATION CONSTANTS
  // =========================================================================

  /// Yangi 1C-login avtorizatsiya endpointi.
  /// Bu endpoint foydalanuvchi login, password va project_name (baseURL) ma'lumotlarini
  /// qabul qilib, access va refresh tokenlarni qaytaradi.
  ///
  /// Override at build time with `--dart-define=SOAP_BASE_URL=http://host:port`.
  static const String _1cLoginBaseUrl = String.fromEnvironment(
    'SOAP_BASE_URL',
    defaultValue: 'http://178.218.200.120:1596',
  );
  static const String _1cLoginEndpoint = '/api/v1/auth/1c-login/';

  // =========================================================================
  // V2 (NEW SERVER) AUTHENTICATION CONSTANTS
  // =========================================================================
  // Yangi server JWT auth endpointlari — faqat lokatsiya/telemetry servislari
  // tomonidan ishlatiladi. Eski server REST endpointlari va ularga bog'liq
  // servislarga tegmasdan, parallel ishlaydi.

  /// Yangi server base URL.
  ///
  /// Override at build time with `--dart-define=V2_BASE_URL=http://host:port`.
  /// NOTE: real iPhone/Android cannot reach `localhost` — that resolves to
  /// the device itself, not the developer's Mac. Pass the LAN IP / public host
  /// via `--dart-define` for on-device runs.
  static const String v2BaseUrl = String.fromEnvironment(
    'V2_BASE_URL',
    defaultValue: 'http://192.168.0.123:8080',
  );

  /// JWT access + refresh juftligini olish endpointi.
  static const String _v2TokenEndpoint = '/api/auth/token/';

  /// Refresh token orqali yangi access (va yangi refresh — rotation) olish.
  static const String _v2RefreshEndpoint = '/api/auth/token/refresh/';

  /// Token validligini tekshirish endpointi.
  static const String _v2VerifyEndpoint = '/api/auth/token/verify/';

  /// V2 token storage keylari (eski REST tokenlardan ajratilgan).
  static const String _v2AccessTokenKey = 'rest_v2_access_token';
  static const String _v2RefreshTokenKey = 'rest_v2_refresh_token';
  static const String _v2TokenExpiryKey = 'rest_v2_token_expiry';

  /// V2 access token muddati (yangi server: 60 minut).
  static const Duration _v2AccessTokenTtl = Duration(minutes: 60);

  TokenService(this._dio, this._prefsService) {
    _configureDio();
  }

  /// Configure Dio instance with token interceptors
  void _configureDio() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Skip adding token for ALL authentication endpoints
          // This includes /api/token and /api/v1/auth/ endpoints
          if (options.path.contains('/api/token') || 
              options.path.contains('/api/v1/auth/')) {
            if (kDebugMode) {
              print('TokenService: Skipping token addition for auth endpoint: ${options.path}');
            }
            return handler.next(options);
          }
          
          // Add authorization header for other endpoints if we have a valid token
          final token = await getValidAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            if (kDebugMode) {
              print('TokenService: Added Bearer token to request: ${options.path}');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Suppressed: V2 telemetry/policy/device responses already log
          // under their own Dio instances. This interceptor was firing on
          // every response and duplicating output.
          // if (kDebugMode) {
          //   print('TokenService: Response received from ${response.requestOptions.path}');
          //   print('TokenService: Status code: ${response.statusCode}');
          // }
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          // Handle token refresh on 401 errors
          if (error.response?.statusCode == 401) {
            // Don't retry authentication endpoints
            if (error.requestOptions.path.contains('/api/token') || 
                error.requestOptions.path.contains('/api/v1/auth/')) {
              if (kDebugMode) {
                print('TokenService: 401 on auth endpoint, not retrying: ${error.requestOptions.path}');
              }
              return handler.next(error);
            }
            
            try {
              final newToken = await _refreshAccessToken();
              if (newToken != null) {
                // Retry the original request with new token
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $newToken';

                final response = await _dio.request(
                  options.path,
                  options: Options(
                    method: options.method,
                    headers: options.headers,
                  ),
                  data: options.data,
                  queryParameters: options.queryParameters,
                );

                return handler.resolve(response);
              }
            } catch (refreshError) {
              if (kDebugMode) {
                print('TokenService: Failed to refresh token: $refreshError');
              }
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// Get authentication tokens from the server
  /// This method authenticates with the server using username/password
  /// and retrieves access and refresh tokens
  ///
  /// @param baseUrl The base URL of the API server
  /// @param username The username for authentication
  /// @param password The password for authentication
  /// @return Future<Map<String, dynamic>?> Token information or null if failed
  @Deprecated('Use getTokensFrom1CLogin instead for new 1C authentication flow')
  Future<Map<String, dynamic>?> getTokens({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('TokenService: Requesting tokens from $baseUrl/api/token/');
      }

      // Validate input parameters
      if (baseUrl.isEmpty) {
        throw ArgumentError('Base URL cannot be empty');
      }
      if (username.isEmpty) {
        throw ArgumentError('Username cannot be empty');
      }
      if (password.isEmpty) {
        throw ArgumentError('Password cannot be empty');
      }

      final response = await _dio.post(
        '$baseUrl/api/token/',
        data: {
          'username': username,
          'password': password,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final tokenData = response.data as Map<String, dynamic>;

        // Extract token information
        final accessToken = tokenData['access'] as String?;
        final refreshToken = tokenData['refresh'] as String?;
        final tokenType = 'Bearer'; // Default for JWT

        if (accessToken != null && refreshToken != null) {
          // Calculate expiry time (assuming JWT tokens are valid for 1 hour)
          final expiryTime = DateTime.now().add(const Duration(hours: 1));

          // Store tokens
          await _storeTokens(accessToken, refreshToken, tokenType, expiryTime);

          if (kDebugMode) {
            print('TokenService: Successfully obtained and stored tokens');
            print('TokenService: Access token expires at: $expiryTime');
          }

          return {
            'access': accessToken,
            'refresh': refreshToken,
            'token_type': tokenType,
            'expires_at': expiryTime.toIso8601String(),
          };
        } else {
          if (kDebugMode) {
            print('TokenService: Token response missing required fields');
          }
          return null;
        }
      } else {
        if (kDebugMode) {
          print('TokenService: Token request failed with status: ${response.statusCode}');
        }
        return null;
      }

    } on DioException catch (e) {
      if (kDebugMode) {
        print('TokenService: DioException while getting tokens: ${e.message}');
        print('TokenService: Response status: ${e.response?.statusCode}');
        print('TokenService: Response data: ${e.response?.data}');
      }
      throw Exception('Token olishda xatolik: ${e.error}');
    } catch (e) {
      if (kDebugMode) {
        print('TokenService: Unexpected error while getting tokens: $e');
      }
      throw Exception('Token olishda kutilmagan xatolik: $e');
    }
  }

  // ===========================================================================
  // YANGI 1C-LOGIN AVTORIZATSIYA METODI
  // ===========================================================================

  /// Yangi 1C-login avtorizatsiya endpointi orqali tokenlarni olish.
  /// 
  /// Bu metod yangi avtorizatsiya tizimi uchun ishlatiladi.
  /// Endpoint: http://178.218.200.120:1596/api/v1/auth/1c-login/
  /// 
  /// Ma'lumotlar:
  /// - [login] - Foydalanuvchi logini (SharedPreferences: saved_username)
  /// - [password] - Foydalanuvchi paroli (SharedPreferences: saved_password)
  /// - [projectName] - Foydalanuvchi baseURL/project nomi (SharedPreferences: selected_server_base_url)
  /// 
  /// Qaytaradi:
  /// - Map<String, dynamic>? - Token ma'lumotlari yoki null agar muvaffaqiyatsiz bo'lsa
  /// 
  /// Xatolar:
  /// - ArgumentError - Majburiy parametrlar bo'sh bo'lsa
  /// - DioException - Tarmoq xatoliklari
  /// - Exception - Boshqa kutilmagan xatolar
  Future<Map<String, dynamic>?> getTokensFrom1CLogin({
    required String login,
    required String password,
    required String projectName,
  }) async {
    // So'rov URL'ini yaratish
    final requestUrl = '$_1cLoginBaseUrl$_1cLoginEndpoint';
    
    try {
      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════════════');
        print('TokenService: 1C-LOGIN AVTORIZATSIYA BOSHLANDI');
        print('TokenService: Endpoint: $requestUrl');
        print('TokenService: Login: $login');
        print('TokenService: Project Name: $projectName');
        print('═══════════════════════════════════════════════════════════════');
      }

      // =========================================================================
      // PARAMETRLARNI VALIDATSIYA QILISH
      // =========================================================================
      if (login.isEmpty) {
        throw ArgumentError('Login (foydalanuvchi nomi) bo\'sh bo\'lishi mumkin emas');
      }
      if (password.isEmpty) {
        throw ArgumentError('Password (parol) bo\'sh bo\'lishi mumkin emas');
      }
      if (projectName.isEmpty) {
        throw ArgumentError('Project name (baseURL) bo\'sh bo\'lishi mumkin emas');
      }

      // =========================================================================
      // API SO'ROVINI YUBORISH
      // =========================================================================
      final response = await _dio.post(
        requestUrl,
        data: {
          'login': login,           // Foydalanuvchi logini
          'password': password,     // Foydalanuvchi paroli
          'project_name': projectName,  // BaseURL / project nomi
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          // Ulanish va javob olish uchun timeout
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      // =========================================================================
      // JAVOBNI QAYTA ISHLASH
      // =========================================================================
      if (response.statusCode == 200 && response.data != null) {
        final tokenData = response.data as Map<String, dynamic>;

        if (kDebugMode) {
          print('TokenService: 1C-Login javob olindi');
          print('TokenService: Response keys: ${tokenData.keys.toList()}');
        }

        // Token ma'lumotlarini ajratib olish
        // API javobi strukturasi:
        // {
        //   "user": { "username": "...", "full_name": "...", "code_1c": "..." },
        //   "tokens": { "access": "...", "refresh": "..." },
        //   "message": "..."
        // }
        
        String? accessToken;
        String? refreshToken;
        String tokenType = 'Bearer';
        
        // 1. Avval nested 'tokens' obyektini tekshirish (1C-Login API formati)
        if (tokenData.containsKey('tokens') && tokenData['tokens'] is Map) {
          final tokensObj = tokenData['tokens'] as Map<String, dynamic>;
          accessToken = (tokensObj['access'] ?? tokensObj['access_token']) as String?;
          refreshToken = (tokensObj['refresh'] ?? tokensObj['refresh_token']) as String?;
          tokenType = (tokensObj['token_type'] ?? 'Bearer') as String;
          
          if (kDebugMode) {
            print('TokenService: Tokens obyekti ichidan olindi');
            print('TokenService: Access token: ${accessToken != null ? "mavjud" : "mavjud emas"}');
            print('TokenService: Refresh token: ${refreshToken != null ? "mavjud" : "mavjud emas"}');
          }
        } 
        // 2. Agar 'tokens' obyekti yo'q bo'lsa, root levelda qidirish
        else {
          accessToken = (tokenData['access'] ?? tokenData['access_token']) as String?;
          refreshToken = (tokenData['refresh'] ?? tokenData['refresh_token']) as String?;
          tokenType = (tokenData['token_type'] ?? 'Bearer') as String;
          
          if (kDebugMode) {
            print('TokenService: Tokenlar root levelda qidirildi');
          }
        }
        
        // User ma'lumotlarini ham saqlash (agar kerak bo'lsa)
        if (tokenData.containsKey('user') && tokenData['user'] is Map) {
          final userObj = tokenData['user'] as Map<String, dynamic>;
          if (kDebugMode) {
            print('TokenService: User ma\'lumotlari: ${userObj['username']} - ${userObj['full_name']}');
          }
        }

        // Token muddati (agar serverdan kelsa)
        DateTime expiryTime;
        if (tokenData.containsKey('expires_in')) {
          // expires_in sekundlarda bo'lsa
          final expiresIn = tokenData['expires_in'] as int;
          expiryTime = DateTime.now().add(Duration(seconds: expiresIn));
        } else if (tokenData.containsKey('expires_at')) {
          // expires_at ISO 8601 formatida bo'lsa
          expiryTime = DateTime.parse(tokenData['expires_at'] as String);
        } else {
          // Default: 1 soat
          expiryTime = DateTime.now().add(const Duration(hours: 1));
        }

        // Access token mavjudligini tekshirish
        if (accessToken != null && accessToken.isNotEmpty) {
          // Tokenlarni saqlash
          await _storeTokens(
            accessToken,
            refreshToken ?? '', // Refresh token bo'lmasligi mumkin
            tokenType,
            expiryTime,
          );

          if (kDebugMode) {
            print('═══════════════════════════════════════════════════════════════');
            print('TokenService: 1C-LOGIN MUVAFFAQIYATLI');
            print('TokenService: Access Token: ${accessToken.substring(0, accessToken.length > 20 ? 20 : accessToken.length)}...');
            print('TokenService: Refresh Token: ${refreshToken != null && refreshToken.isNotEmpty ? "mavjud" : "mavjud emas"}');
            print('TokenService: Token muddati: $expiryTime');
            print('═══════════════════════════════════════════════════════════════');
          }

          return {
            'access': accessToken,
            'refresh': refreshToken ?? '',
            'token_type': tokenType,
            'expires_at': expiryTime.toIso8601String(),
            'login_method': '1c-login', // Qaysi metod orqali olinganini belgilash
          };
        } else {
          if (kDebugMode) {
            print('TokenService: 1C-Login javobida access token topilmadi');
            print('TokenService: Response data: $tokenData');
          }
          return null;
        }
      } else {
        if (kDebugMode) {
          print('TokenService: 1C-Login so\'rovi muvaffaqiyatsiz');
          print('TokenService: Status code: ${response.statusCode}');
          print('TokenService: Response data: ${response.data}');
        }
        return null;
      }

    } on DioException catch (e) {
      // =========================================================================
      // DIO XATOLARINI QAYTA ISHLASH
      // =========================================================================
      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════════════');
        print('TokenService: 1C-LOGIN DIO XATOSI');
        print('TokenService: Xato turi: ${e.type}');
        print('TokenService: Xabar: ${e.message}');
        print('TokenService: Status code: ${e.response?.statusCode}');
        print('TokenService: Response data: ${e.response?.data}');
        print('═══════════════════════════════════════════════════════════════');
      }

      // Foydalanuvchiga tushunarli xato xabarini qaytarish
      String errorMessage;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage = 'Serverga ulanish vaqti tugadi. Internet aloqasini tekshiring.';
          break;
        case DioExceptionType.sendTimeout:
          errorMessage = 'So\'rov yuborish vaqti tugadi. Qaytadan urinib ko\'ring.';
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Javob kutish vaqti tugadi. Qaytadan urinib ko\'ring.';
          break;
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          if (statusCode == 400) {
            errorMessage = 'Noto\'g\'ri so\'rov. Login yoki parol xato.';
          } else if (statusCode == 401) {
            errorMessage = 'Avtorizatsiya muvaffaqiyatsiz. Login yoki parol xato.';
          } else if (statusCode == 403) {
            errorMessage = 'Kirish taqiqlangan. Ruxsatingiz yo\'q.';
          } else if (statusCode == 404) {
            errorMessage = 'Avtorizatsiya endpointi topilmadi.';
          } else if (statusCode == 500) {
            errorMessage = 'Server xatosi. Keyinroq urinib ko\'ring.';
          } else {
            errorMessage = 'Server xatosi ($statusCode).';
          }
          break;
        case DioExceptionType.cancel:
          errorMessage = 'So\'rov bekor qilindi.';
          break;
        case DioExceptionType.unknown:
          if (e.error.toString().contains('SocketException')) {
            errorMessage = 'Tarmoq xatosi. Internet aloqasini tekshiring.';
          } else {
            errorMessage = 'Noma\'lum xato yuz berdi.';
          }
          break;
        default:
          errorMessage = 'Kutilmagan xato yuz berdi.';
      }

      throw Exception('1C-Login avtorizatsiya xatosi: $errorMessage');
    } catch (e) {
      // =========================================================================
      // BOSHQA XATOLARNI QAYTA ISHLASH
      // =========================================================================
      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════════════');
        print('TokenService: 1C-LOGIN KUTILMAGAN XATO');
        print('TokenService: Xato: $e');
        print('═══════════════════════════════════════════════════════════════');
      }
      throw Exception('1C-Login avtorizatsiyada kutilmagan xatolik: $e');
    }
  }

  /// Refresh access token using refresh token
  /// This method uses the stored refresh token to get a new access token
  ///
  /// @return Future<String?> New access token or null if refresh failed
  Future<String?> _refreshAccessToken() async {
    try {
      final refreshToken = _prefsService.preferences.getString(_refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        // V1 refresh token is no longer issued at login — this branch is
        // expected to fire for every authenticated REST request. Logging
        // it would flood the terminal.
        return null;
      }

      // Get base URL from stored preferences or use default
      final baseUrl = await _getBaseUrl();

      final response = await _dio.post(
        '$baseUrl/api/token/refresh/',
        data: {
          'refresh': refreshToken,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      if (kDebugMode) {
        print('TokenService: Refresh response status: ${response.statusCode}');
        print('TokenService: Refresh response data: ${response.data}');
      }
      if (response.statusCode == 200 && response.data != null) {
        final tokenData = response.data as Map<String, dynamic>;
        final newAccessToken = tokenData['access'] as String?;
        if (kDebugMode) {
          print('TokenService: New access token: $newAccessToken');
        }
        if (newAccessToken != null) {
          // Update stored access token and expiry
          final expiryTime = DateTime.now().add(const Duration(hours: 1));
          await _prefsService.preferences.setString(_accessTokenKey, newAccessToken);
          await _prefsService.preferences.setString(_tokenExpiryKey, expiryTime.toIso8601String());

          if (kDebugMode) {
            print('TokenService: Successfully refreshed access token');
          }

          return newAccessToken;
        }
      } else if (response.statusCode == 401) {
        if (kDebugMode) {
          print('TokenService: Refresh token invalid (401), clearing tokens and redirecting to re-auth');
        }
        await clearTokens();
        // TODO: Navigate to login or emit event for re-auth
        return null;
      } else if (response.statusCode == 400) {
        if (kDebugMode) {
          print('TokenService: Bad request (400) during token refresh: ${response.data}');
        }
        return null;
      } else {
        if (kDebugMode) {
          print('TokenService: Token refresh failed with status: ${response.statusCode}, data: ${response.data}');
        }
        return null;
      }

      if (kDebugMode) {
        print('TokenService: Token refresh failed');
      }
      return null;

    } catch (e) {
      if (kDebugMode) {
        print('TokenService: Error refreshing token: $e');
        if (e is DioException) {
          print('TokenService: DioException response status: ${e.response?.statusCode}');
          print('TokenService: DioException response data: ${e.response?.data}');
        }
      }
      return null;
    }
  }

  /// Public wrapper for refreshing access token
  Future<String?> refreshAccessToken() async {
    return _refreshAccessToken();
  }

  /// Get a valid access token (refresh if necessary)
  /// This method returns a valid access token, refreshing it if expired
  ///
  /// @return Future<String?> Valid access token or null if unavailable
  Future<String?> getValidAccessToken() async {
    try {
      final accessToken = _prefsService.preferences.getString(_accessTokenKey);
      final expiryString = _prefsService.preferences.getString(_tokenExpiryKey);

      if (accessToken == null || accessToken.isEmpty) {
        // Expected when V1 tokens are not yet issued — silenced to avoid
        // log spam. The refresh attempt below covers diagnostics.
        final newToken = await _refreshAccessToken();
        if (newToken != null && newToken.isNotEmpty) {
          return newToken;
        }
        return null;
      }

      // Check if token is expired
      if (expiryString != null) {
        final expiryTime = DateTime.parse(expiryString);
        final now = DateTime.now();

        // If token is expired, refresh it
        if (expiryTime.isBefore(now)) {
          if (kDebugMode) {
            print('TokenService: Access token expired, refreshing... $accessToken');
          }
          final newToken = await _refreshAccessToken();
          if (newToken != null) {
            return newToken;
          } else {
            // Refresh failed, don't return expired token
            return null;
          }
        }
      }

      return accessToken;

    } catch (e) {
      if (kDebugMode) {
        print('TokenService: Error getting valid access token: $e');
      }
      return null;
    }
  }

  /// Store tokens in shared preferences
  Future<void> _storeTokens(
    String accessToken,
    String refreshToken,
    String tokenType,
    DateTime expiryTime,
  ) async {
    await _prefsService.preferences.setString(_accessTokenKey, accessToken);
    await _prefsService.preferences.setString(_refreshTokenKey, refreshToken);
    await _prefsService.preferences.setString(_tokenTypeKey, tokenType);
    await _prefsService.preferences.setString(_tokenExpiryKey, expiryTime.toIso8601String());
  }

  /// Clear all stored tokens
  /// This method removes all token-related data from storage
  Future<void> clearTokens() async {
    await _prefsService.preferences.remove(_accessTokenKey);
    await _prefsService.preferences.remove(_refreshTokenKey);
    await _prefsService.preferences.remove(_tokenTypeKey);
    await _prefsService.preferences.remove(_tokenExpiryKey);

    if (kDebugMode) {
      print('TokenService: All tokens cleared');
    }
  }

  /// Check if user is authenticated (has valid tokens)
  /// @return Future<bool> True if user has valid tokens, false otherwise
  Future<bool> isAuthenticated() async {
    final token = await getValidAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Get token information for debugging
  /// @return Future<Map<String, dynamic>> Token status information
  Future<Map<String, dynamic>> getTokenInfo() async {
    try {
      final accessToken = _prefsService.preferences.getString(_accessTokenKey);
      final refreshToken = _prefsService.preferences.getString(_refreshTokenKey);
      final tokenType = _prefsService.preferences.getString(_tokenTypeKey);
      final expiryString = _prefsService.preferences.getString(_tokenExpiryKey);

      DateTime? expiryTime;
      bool isExpired = true;

      if (expiryString != null) {
        expiryTime = DateTime.parse(expiryString);
        isExpired = expiryTime.isBefore(DateTime.now());
      }

      return {
        'has_access_token': accessToken != null && accessToken.isNotEmpty,
        'has_refresh_token': refreshToken != null && refreshToken.isNotEmpty,
        'token_type': tokenType ?? 'Unknown',
        'expires_at': expiryTime?.toIso8601String(),
        'is_expired': isExpired,
        'is_authenticated': await isAuthenticated(),
      };

    } catch (e) {
      return {
        'error': e.toString(),
        'is_authenticated': false,
      };
    }
  }

  /// Get base URL for token operations
  /// Client images and tokens use a separate API endpoint that is different from the main app API
  /// This is hardcoded for now but designed to be configurable in the future
  Future<String> _getBaseUrl() async {
    // Hardcoded URL for client images and token operations
    // TODO: Make this configurable through app configuration when expanding to multiple environments
    return 'http://178.218.200.120:1596';
  }

  /// Authenticate user and get tokens
  /// Convenience method that combines token retrieval with authentication
  ///
  /// @param username The username for authentication
  /// @param password The password for authentication
  /// @return Future<bool> True if authentication successful, false otherwise
  @Deprecated('Use authenticateWith1CLogin instead for new 1C authentication flow')
  Future<bool> authenticate({
    required String username,
    required String password,
  }) async {
    try {
      final baseUrl = await _getBaseUrl();
      // ignore: deprecated_member_use_from_same_package
      final tokens = await getTokens(
        baseUrl: baseUrl,
        username: username,
        password: password,
      );

      return tokens != null;
    } catch (e) {
      if (kDebugMode) {
        print('TokenService: Authentication failed: $e');
      }
      return false;
    }
  }

  // ===========================================================================
  // YANGI 1C-LOGIN AVTORIZATSIYA METODI (QULAYLIK UCHUN)
  // ===========================================================================

  /// Yangi 1C-login avtorizatsiya endpointi orqali foydalanuvchini autentifikatsiya qilish.
  /// 
  /// Bu metod SharedPreferences'dan credentials'ni o'qib, yangi 1C-login endpointiga yuboradi.
  /// Agar parametrlar berilmasa, SharedPreferences'dan o'qiladi.
  /// 
  /// Ma'lumotlar:
  /// - [login] - Foydalanuvchi logini (opsional, SharedPreferences: saved_username)
  /// - [password] - Foydalanuvchi paroli (opsional, SharedPreferences: saved_password)
  /// - [projectName] - BaseURL/project nomi (opsional, SharedPreferences: selected_server_base_url)
  /// 
  /// Qaytaradi:
  /// - Future<bool> - True agar autentifikatsiya muvaffaqiyatli bo'lsa
  Future<bool> authenticateWith1CLogin({
    String? login,
    String? password,
    String? projectName,
  }) async {
    try {
      // SharedPreferences'dan credentials'ni olish (agar parametrlar berilmagan bo'lsa)
      final authLogin = login ?? _prefsService.getSavedUsername();
      final authPassword = password ?? _prefsService.getPassword();
      final authProjectName = projectName ?? _prefsService.getBaseUrl();

      if (kDebugMode) {
        print('TokenService: authenticateWith1CLogin boshlandi');
        print('TokenService: Login: ${authLogin != null ? "***" : "null"}');
        print('TokenService: Password: ${authPassword != null ? "***" : "null"}');
        print('TokenService: Project Name: $authProjectName');
      }

      // Majburiy parametrlarni tekshirish
      if (authLogin == null || authLogin.isEmpty) {
        if (kDebugMode) {
          print('TokenService: Login (username) mavjud emas');
        }
        return false;
      }
      if (authPassword == null || authPassword.isEmpty) {
        if (kDebugMode) {
          print('TokenService: Password mavjud emas');
        }
        return false;
      }
      if (authProjectName == null || authProjectName.isEmpty) {
        if (kDebugMode) {
          print('TokenService: Project name (baseURL) mavjud emas');
        }
        return false;
      }

      // 1C-login endpointiga so'rov yuborish
      final tokens = await getTokensFrom1CLogin(
        login: authLogin,
        password: authPassword,
        projectName: authProjectName,
      );

      final success = tokens != null;
      
      if (kDebugMode) {
        print('TokenService: authenticateWith1CLogin natijasi: ${success ? "MUVAFFAQIYATLI" : "MUVAFFAQIYATSIZ"}');
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('TokenService: authenticateWith1CLogin xatosi: $e');
      }
      return false;
    }
  }

  /// Logout user by clearing tokens
  Future<void> logout() async {
    await clearTokens();
    if (kDebugMode) {
      print('TokenService: User logged out, tokens cleared');
    }
  }

  /// Ensure a valid token is available with complete auth flow
  /// This method implements the full token validation sequence:
  /// 1. Check if access token exists and is not expired -> return it
  /// 2. If expired, try to refresh using refresh token
  /// 3. If refresh fails, re-authenticate using stored credentials (1C-Login)
  /// 
  /// @param username Optional username for re-authentication (uses stored if not provided)
  /// @param password Optional password for re-authentication (uses stored if not provided)
  /// @return Future<String?> Valid access token or null if all methods fail
  /// @throws Exception if re-authentication is required but credentials are not available
  Future<String?> ensureValidToken({
    String? username,
    String? password,
  }) async {
    try {
      // =========================================================================
      // 1-BOSQICH: Mavjud tokenni tekshirish
      // =========================================================================
      final accessToken = _prefsService.preferences.getString(_accessTokenKey);
      final expiryString = _prefsService.preferences.getString(_tokenExpiryKey);

      if (accessToken != null && accessToken.isNotEmpty && expiryString != null) {
        final expiryTime = DateTime.parse(expiryString);
        // 1 daqiqa bufer qo'shish (edge case'larni oldini olish uchun)
        if (expiryTime.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
          if (kDebugMode) {
            print('TokenService: Mavjud token yaroqli, qaytarilmoqda');
          }
          return accessToken;
        }
      }

      if (kDebugMode) {
        print('TokenService: Token muddati tugagan yoki mavjud emas, yangilash urinilmoqda...');
      }

      // =========================================================================
      // 2-BOSQICH: Tokenni yangilash (refresh)
      // =========================================================================
      final refreshedToken = await _refreshAccessToken();
      if (refreshedToken != null && refreshedToken.isNotEmpty) {
        if (kDebugMode) {
          print('TokenService: Token muvaffaqiyatli yangilandi');
        }
        return refreshedToken;
      }

      // V1 1C-Login re-authentication is disabled — all auth now flows
      // through the V2 backend (`obtainV2Tokens` / `refreshAccessV2`).
      // Parameters are intentionally kept on the public signature for
      // backwards binary compatibility with callers; they are no longer used.
      if (kDebugMode) {
        print('TokenService: V1 1C-Login re-auth is disabled — returning null without network call (login=${username == null ? "null" : "***"})');
      }
      // Muvaffaqiyatsiz bo'lsa tokenlarni tozalash
      await clearTokens();
      return null;

    } catch (e) {
      if (kDebugMode) {
        print('TokenService: ensureValidToken xatosi: $e');
      }
      return null;
    }
  }

  /// Check if access token is expired
  /// @return bool True if token is expired or doesn't exist
  bool isTokenExpired() {
    final expiryString = _prefsService.preferences.getString(_tokenExpiryKey);
    if (expiryString == null) return true;
    
    try {
      final expiryTime = DateTime.parse(expiryString);
      return expiryTime.isBefore(DateTime.now());
    } catch (e) {
      return true;
    }
  }

  /// Get stored access token without validation
  /// Use ensureValidToken for validated token retrieval
  String? getStoredAccessToken() {
    return _prefsService.preferences.getString(_accessTokenKey);
  }

  /// Get stored refresh token
  String? getStoredRefreshToken() {
    return _prefsService.preferences.getString(_refreshTokenKey);
  }

  /// Get stored V2 access token without refreshing.
  String? getStoredV2AccessToken() {
    return _prefsService.preferences.getString(_v2AccessTokenKey);
  }

  // ===========================================================================
  // ===========================================================================
  //                     V2 (NEW SERVER) AUTHENTICATION
  // ===========================================================================
  // ===========================================================================
  // Bu bo'lim yangi server (http://localhost:8000) bilan ishlash uchun.
  // Eski server REST tokenlari va metodlari TEGMAYDI — ular boshqa REST
  // servislari (RestApiService, ClientImagesService, FakturaService, ...)
  // tomonidan eski serverga so'rov yuborish uchun ishlatilishda davom etadi.
  //
  // Yangi V2 tokenlari faqat yangi server endpointlariga (telemetry, device
  // register, tracking policy) yuborilgan so'rovlarda ishlatiladi.
  // ===========================================================================

  /// Yangi serverdan JWT access + refresh juftligini olish.
  ///
  /// Endpoint: POST {v2BaseUrl}/api/auth/token/
  /// Request body: `{login, password}` (eski 1c-login dan farqli, project_name YO'Q).
  /// Response: `{access, refresh}` — flat struktura.
  ///
  /// Tokenlar [_v2AccessTokenKey] / [_v2RefreshTokenKey] kalitlari ostida
  /// saqlanadi. Eski [_accessTokenKey] / [_refreshTokenKey] tegmaydi.
  ///
  /// Qaytaradi: tokenlar saqlangan bo'lsa true, aks holda false.
  Future<bool> obtainV2Tokens({
    required String login,
    required String password,
    LoginDevicePayload? device,
  }) async {
    final url = '$v2BaseUrl$_v2TokenEndpoint';
    try {
      if (login.isEmpty || password.isEmpty) {
        return false;
      }

      if (kDebugMode) {
        print('TokenService[V2]: Obtaining tokens from $url '
            '(device=${device == null ? "absent" : "present"})');
      }

      // Compose the request body. The `device` block is sent ONLY when
      // the caller provided one — Stage 1 of the binding rollout treats
      // it as optional. Stage 2 onwards will reject device-less mobile
      // logins with HTTP 400 `DEVICE_PAYLOAD_REQUIRED`.
      final body = <String, dynamic>{
        'login': login,
        'password': password,
      };
      if (device != null) {
        body['device'] = device.toJson();
      }

      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final access = data['access'] as String?;
        final refresh = data['refresh'] as String?;

        if (access != null && access.isNotEmpty) {
          await _storeV2Tokens(access, refresh);
          // Persist the `gates` envelope + the `device` echo so
          // AppStartGuard and the React admin's binding list stay in
          // sync across cold starts. Tolerates missing fields.
          try {
            final envelope = LoginGatesEnvelope.fromJson(data);
            await _prefsService.setCachedGates(envelope);
            await _prefsService.setCachedDeviceBinding(envelope.device);
            _logPermissionsFromEnvelope(
              source: 'POST $url',
              data: data,
              envelope: envelope,
            );
            await _syncBackendPermissions(
              envelope.permissions,
              provided: envelope.permissionsProvided,
            );
          } catch (_) {
            // Backend may not return gates yet — non-fatal. Still
            // record the failure so the "Backend ruxsatlari" sync
            // card in the settings tab reflects it.
            await _recordBackendPermissionsFailure('parse_error');
          }
          _lastV2LoginFailure = null;
          if (kDebugMode) {
            print('═══════════════════════════════════════════════════════════════');
            print('TokenService[V2]: ✅ TOKENS RECEIVED FROM SERVER');
            print('  endpoint   : $url');
            print('  status     : ${response.statusCode}');
            print('  access     : ${access.substring(0, access.length > 40 ? 40 : access.length)}...');
            print('  refresh    : ${refresh != null ? "${refresh.substring(0, refresh.length > 40 ? 40 : refresh.length)}..." : "null"}');
            print('  expires_at : ${DateTime.now().add(_v2AccessTokenTtl)}');
            print('  stored_keys: $_v2AccessTokenKey, $_v2RefreshTokenKey, $_v2TokenExpiryKey');
            print('═══════════════════════════════════════════════════════════════');
          }
          return true;
        }
      }

      if (kDebugMode) {
        print('TokenService[V2]: Unexpected response status=${response.statusCode}, data=${response.data}');
      }
      _lastV2LoginFailure = const UnknownAuthFailure();
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('TokenService[V2]: DioException ${e.type} status=${e.response?.statusCode} message=${e.message}');
      }
      _lastV2LoginFailure = _mapDioToFailure(e);
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('TokenService[V2]: Unexpected error: $e');
      }
      _lastV2LoginFailure = const UnknownAuthFailure();
      return false;
    }
  }

  // Most recent typed failure from `obtainV2Tokens` / `refreshAccessV2`.
  // Surfaced via [lastV2LoginFailure] / [lastV2RefreshFailure] so the UI
  // and AppStartGuard can show actionable copy. Reset to `null` on success.
  AuthFailure? _lastV2LoginFailure;
  AuthFailure? _lastV2RefreshFailure;

  /// Last typed failure from `/api/auth/token/`. `null` when the most
  /// recent call succeeded (or none has been made).
  AuthFailure? get lastV2LoginFailure => _lastV2LoginFailure;

  /// Last typed failure from `/api/auth/token/refresh/`.
  AuthFailure? get lastV2RefreshFailure => _lastV2RefreshFailure;

  /// Public wrapper around the private V2 refresh that also persists the
  /// fresh `gates` envelope. Returns the new access token on success or
  /// `null` on any failure (consult [lastV2RefreshFailure] for context).
  Future<String?> refreshAccessV2() => _refreshV2AccessToken();

  /// Convenience accessor for `AppStartGuard` so it does not couple to
  /// SharedPreferences directly.
  LoginGatesEnvelope? getCachedGates() => _prefsService.getCachedGates();

  /// Sync the backend-sourced permission codenames after every login /
  /// refresh. Tolerant of the store not being registered yet (defensive
  /// during unit tests / staged rollout): a failure here must never
  /// take the auth pipeline down.
  Future<void> _syncBackendPermissions(
    List<String> permissions, {
    required bool provided,
  }) async {
    try {
      if (GetIt.I.isRegistered<BackendPermissionStore>()) {
        await GetIt.I<BackendPermissionStore>()
            .replaceFromLogin(permissions, provided: provided);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[GATES-FLOW] ⚠️  BackendPermissionStore sync failed: $e',
        );
      }
      await _recordBackendPermissionsFailure('store_write_error');
    }
  }

  /// Curated debug dump of the V2 permission payload returned by the
  /// auth endpoints. Shows exactly which API supplied the codenames
  /// and what the server actually sent — used to diagnose mismatches
  /// between mobile gates and backend RBAC (e.g. 403 on PATCH after
  /// mobile thought the user held the codename).
  ///
  /// Logs three layers:
  /// 1. Source endpoint (e.g. `POST .../api/auth/token/`).
  /// 2. Raw `gates.permissions` field as returned (or "missing").
  /// 3. Parsed envelope fields the mobile will use
  ///    (`permissions`, `permissionsProvided`, `organizationId`, etc.).
  ///
  /// Backend reference:
  /// - Endpoint handler: `api/auth/token/` and `.../refresh/` views in
  ///   the `auth` Django app. They embed `gates` into the response
  ///   alongside the JWT `access` / `refresh` strings.
  /// - `gates.permissions` is computed server-side from the user's
  ///   Django auth permissions (`User.user_permissions` +
  ///   `Group.permissions` joined), filtered to the `customers.*`
  ///   namespace by the staff-permissions runbook. The list is a
  ///   flat array of dotted codenames; absence of the field means
  ///   the server has not yet shipped the staff-permissions feature
  ///   (rollout window) — see backend runbook §"Login gates".
  void _logPermissionsFromEnvelope({
    required String source,
    required Map<String, dynamic> data,
    required LoginGatesEnvelope envelope,
  }) {
    if (!kDebugMode) return;
    final gatesRaw = data['gates'];
    final permissionsRaw = gatesRaw is Map<String, dynamic>
        ? gatesRaw['permissions']
        : null;
    final permissionsType = permissionsRaw == null
        ? 'MISSING'
        : '${permissionsRaw.runtimeType}';
    debugPrint(
      '═══════════════════════════════════════════════════════════════\n'
      '[GATES-FLOW] 🔑 V2 PERMISSIONS RESPONSE\n'
      '  source                : $source\n'
      '  raw gates.permissions : $permissionsRaw\n'
      '  raw type              : $permissionsType\n'
      '  parsed permissions    : ${envelope.permissions}\n'
      '  permissions count     : ${envelope.permissions.length}\n'
      '  permissionsProvided   : ${envelope.permissionsProvided}\n'
      '  organization_id       : ${envelope.organizationId}\n'
      '  bypass (superuser)    : ${envelope.bypass}\n'
      '  user_active_end       : ${envelope.userActiveEnd}\n'
      '  license_valid_to      : ${envelope.licenseValidTo}\n'
      '  server_time           : ${envelope.serverTime}\n'
      '  ──── backend source ────\n'
      '  Django view: `api/auth/token/` (and `.../refresh/`)\n'
      '  Permissions: User.user_permissions ∪ Group.permissions\n'
      '                filtered to `customers.*` codenames\n'
      '═══════════════════════════════════════════════════════════════',
    );
  }

  /// Mirror of [_syncBackendPermissions] for the failure path —
  /// surfaces a "failed" event in the sync card without overwriting
  /// the last-known granted set. Used when the envelope itself was
  /// unparseable (backend rollout still in flight, transient corruption).
  Future<void> _recordBackendPermissionsFailure(String code) async {
    try {
      if (GetIt.I.isRegistered<BackendPermissionStore>()) {
        await GetIt.I<BackendPermissionStore>().recordFailure(code);
      }
    } catch (_) {
      // Telemetry path only — never throw further up the auth stack.
    }
  }

  /// Map a Dio failure to an [AuthFailure]. HTTP error envelopes carry
  /// `error.code`; pure transport failures fall through to [NetworkFailure].
  AuthFailure _mapDioToFailure(DioException e) {
    final response = e.response;
    final body = response?.data;
    if (response != null && body is Map<String, dynamic>) {
      return AuthFailure.fromErrorEnvelope(body, response.statusCode ?? 0);
    }
    return const NetworkFailure();
  }

  /// V2 access tokenni refresh qilish (rotation: yangi refresh ham keladi).
  ///
  /// Endpoint: POST {v2BaseUrl}/api/auth/token/refresh/
  /// Request body: `{refresh}`. Response: `{access, refresh}`.
  ///
  /// Eski refresh blacklist qilinadi (server tomondan), shuning uchun yangi
  /// refresh ham albatta saqlanadi.
  Future<String?> _refreshV2AccessToken() async {
    try {
      final refreshToken = _prefsService.preferences.getString(_v2RefreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        if (kDebugMode) {
          print('TokenService[V2]: No refresh token available');
        }
        return null;
      }

      final url = '$v2BaseUrl$_v2RefreshEndpoint';
      final response = await _dio.post(
        url,
        data: {'refresh': refreshToken},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final newAccess = data['access'] as String?;
        final newRefresh = data['refresh'] as String? ?? refreshToken;

        if (newAccess != null && newAccess.isNotEmpty) {
          await _storeV2Tokens(newAccess, newRefresh);
          // Backend recomputes `gates` AND `device` on every refresh.
          // Overwrite both caches so license extensions / window changes
          // / freshly rotated session ids propagate within ~60 min.
          try {
            final envelope = LoginGatesEnvelope.fromJson(data);
            await _prefsService.setCachedGates(envelope);
            await _prefsService.setCachedDeviceBinding(envelope.device);
            _logPermissionsFromEnvelope(
              source: 'POST $url (refresh)',
              data: data,
              envelope: envelope,
            );
            await _syncBackendPermissions(
              envelope.permissions,
              provided: envelope.permissionsProvided,
            );
          } catch (_) {
            // Skip silently when payload omits gates — but reflect
            // the missed refresh in the permissions sync card.
            await _recordBackendPermissionsFailure('parse_error');
          }
          _lastV2RefreshFailure = null;
          if (kDebugMode) {
            final rotated = data['refresh'] != null;
            print('═══════════════════════════════════════════════════════════════');
            print('TokenService[V2]: ✅ TOKEN REFRESHED');
            print('  endpoint    : $url');
            print('  status      : ${response.statusCode}');
            print('  new access  : ${newAccess.substring(0, newAccess.length > 40 ? 40 : newAccess.length)}...');
            print('  new refresh : ${rotated ? "${newRefresh.substring(0, newRefresh.length > 40 ? 40 : newRefresh.length)}... (rotated)" : "(server did not rotate)"}');
            print('  expires_at  : ${DateTime.now().add(_v2AccessTokenTtl)}');
            print('═══════════════════════════════════════════════════════════════');
          }
          return newAccess;
        }
      }

      if (response.statusCode == 401) {
        if (kDebugMode) {
          print('TokenService[V2]: Refresh token invalid (401), clearing V2 tokens');
        }
        await clearV2Tokens();
        await _prefsService.clearCachedGates();
        _lastV2RefreshFailure = const InvalidCredentialsFailure();
        return null;
      }

      if (kDebugMode) {
        print('TokenService[V2]: Refresh failed status=${response.statusCode}');
      }
      _lastV2RefreshFailure = const UnknownAuthFailure();
      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('TokenService[V2]: Refresh DioException ${e.type} status=${e.response?.statusCode}');
      }
      _lastV2RefreshFailure = _mapDioToFailure(e);
      if (e.response?.statusCode == 401) {
        await clearV2Tokens();
        await _prefsService.clearCachedGates();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('TokenService[V2]: Refresh unexpected error: $e');
      }
      _lastV2RefreshFailure = const UnknownAuthFailure();
      return null;
    }
  }

  /// Yaroqli V2 access tokenni qaytaradi (kerak bo'lsa refresh qiladi, kerak
  /// bo'lsa saqlangan credentials bilan qayta login qiladi).
  ///
  /// 3 bosqich:
  ///   1) Cached access mavjud va eskirmagan → qaytariladi
  ///   2) Refresh urinish — yangi access + yangi refresh
  ///   3) SharedPreferences'dagi saqlangan login/password bilan qayta login
  Future<String?> ensureValidV2Token({
    String? login,
    String? password,
  }) async {
    try {
      // 1-bosqich: cached access
      final cached = _prefsService.preferences.getString(_v2AccessTokenKey);
      final expiryStr = _prefsService.preferences.getString(_v2TokenExpiryKey);
      if (cached != null && cached.isNotEmpty && expiryStr != null) {
        try {
          final expiry = DateTime.parse(expiryStr);
          // 1 daqiqalik bufer
          if (expiry.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
            if (kDebugMode) {
              print('TokenService[V2]: stage1 cached access still valid (expires=$expiry)');
            }
            return cached;
          }
          if (kDebugMode) {
            print('TokenService[V2]: stage1 cached access expired (expiry=$expiry), trying refresh');
          }
        } catch (_) {
          // expiry parse xatosi — refresh'ga o'tamiz
        }
      } else {
        if (kDebugMode) {
          print('TokenService[V2]: stage1 no cached access, trying refresh');
        }
      }

      // 2-bosqich: refresh
      final refreshed = await _refreshV2AccessToken();
      if (refreshed != null && refreshed.isNotEmpty) {
        if (kDebugMode) {
          print('TokenService[V2]: stage2 refresh OK');
        }
        return refreshed;
      }
      if (kDebugMode) {
        print('TokenService[V2]: stage2 refresh failed, trying re-login');
      }

      // 3-bosqich: re-login
      final authLogin = login ?? _prefsService.getSavedUsername();
      final authPassword = password ?? _prefsService.getPassword();
      if (authLogin == null || authLogin.isEmpty ||
          authPassword == null || authPassword.isEmpty) {
        if (kDebugMode) {
          print('TokenService[V2]: stage3 no saved credentials, giving up');
        }
        await clearV2Tokens();
        return null;
      }

      final ok = await obtainV2Tokens(login: authLogin, password: authPassword);
      if (ok) {
        if (kDebugMode) {
          print('TokenService[V2]: stage3 re-login OK');
        }
        return _prefsService.preferences.getString(_v2AccessTokenKey);
      }

      if (kDebugMode) {
        print('TokenService[V2]: stage3 re-login failed, clearing tokens');
      }
      await clearV2Tokens();
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('TokenService[V2]: ensureValidV2Token error: $e');
      }
      return null;
    }
  }

  /// V2 tokenlarni saqlash (access + refresh + expiry).
  Future<void> _storeV2Tokens(String access, String? refresh) async {
    final expiry = DateTime.now().add(_v2AccessTokenTtl);
    await _prefsService.preferences.setString(_v2AccessTokenKey, access);
    if (refresh != null && refresh.isNotEmpty) {
      await _prefsService.preferences.setString(_v2RefreshTokenKey, refresh);
    }
    await _prefsService.preferences.setString(_v2TokenExpiryKey, expiry.toIso8601String());
  }

  /// V2 tokenlarni tozalash.
  Future<void> clearV2Tokens() async {
    await _prefsService.preferences.remove(_v2AccessTokenKey);
    await _prefsService.preferences.remove(_v2RefreshTokenKey);
    await _prefsService.preferences.remove(_v2TokenExpiryKey);
    if (kDebugMode) {
      print('TokenService[V2]: V2 tokens cleared');
    }
  }

  /// V2 access token mavjudligini va eskirmaganligini tekshiradi (refresh qilmasdan).
  bool hasValidV2Token() {
    final access = _prefsService.preferences.getString(_v2AccessTokenKey);
    final expiryStr = _prefsService.preferences.getString(_v2TokenExpiryKey);
    if (access == null || access.isEmpty || expiryStr == null) return false;
    try {
      return DateTime.parse(expiryStr).isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  /// V2 access tokenni serverda tekshirish (verify endpoint).
  /// Asosan diagnostika uchun.
  Future<bool> verifyV2Token(String token) async {
    try {
      final url = '$v2BaseUrl$_v2VerifyEndpoint';
      final response = await _dio.post(
        url,
        data: {'token': token},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}