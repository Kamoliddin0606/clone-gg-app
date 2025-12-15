import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

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

  TokenService(this._dio, this._prefsService) {
    _configureDio();
  }

  /// Configure Dio instance with token interceptors
  void _configureDio() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Skip adding token for token-related endpoints
          if (!options.path.contains('/api/token')) {
            // Add authorization header if we have a valid token
            final token = await getValidAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Handle token refresh on 401 errors
          if (error.response?.statusCode == 401) {
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

  /// Refresh access token using refresh token
  /// This method uses the stored refresh token to get a new access token
  ///
  /// @return Future<String?> New access token or null if refresh failed
  Future<String?> _refreshAccessToken() async {
    try {
      final refreshToken = _prefsService.preferences.getString(_refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        if (kDebugMode) {
          print('TokenService: No refresh token available');
        }
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
      print('TokenService: Refresh response status: ${response.statusCode}');
      print('TokenService: Refresh response data: ${response.data}');
      if (response.statusCode == 200 && response.data != null) {
        final tokenData = response.data as Map<String, dynamic>;
        final newAccessToken = tokenData['access'] as String?;
        print('TokenService: New access token: $newAccessToken');
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

  /// Get a valid access token (refresh if necessary)
  /// This method returns a valid access token, refreshing it if expired
  ///
  /// @return Future<String?> Valid access token or null if unavailable
  Future<String?> getValidAccessToken() async {
    try {
      final accessToken = _prefsService.preferences.getString(_accessTokenKey);
      final expiryString = _prefsService.preferences.getString(_tokenExpiryKey);

      if (accessToken == null || accessToken.isEmpty) {
        if (kDebugMode) {
          print('TokenService: No access token stored');
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
  /// Thumbnails and tokens use a separate API endpoint that is different from the main app API
  /// This is hardcoded for now but designed to be configurable in the future
  Future<String> _getBaseUrl() async {
    // Hardcoded URL for thumbnails and token operations
    // TODO: Make this configurable through app configuration when expanding to multiple environments
    return 'http://178.218.200.120:1596';
  }

  /// Authenticate user and get tokens
  /// Convenience method that combines token retrieval with authentication
  ///
  /// @param username The username for authentication
  /// @param password The password for authentication
  /// @return Future<bool> True if authentication successful, false otherwise
  Future<bool> authenticate({
    required String username,
    required String password,
  }) async {
    try {
      final baseUrl = await _getBaseUrl();
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

  /// Logout user by clearing tokens
  Future<void> logout() async {
    await clearTokens();
    if (kDebugMode) {
      print('TokenService: User logged out, tokens cleared');
    }
  }
}