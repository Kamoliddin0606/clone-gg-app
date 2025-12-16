import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/thumbnail.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_exceptions.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

/// REST API Service for handling REST API calls to the server
/// This service handles thumbnail data retrieval and other REST API operations
/// It uses Dio for HTTP requests with proper error handling and logging
class RestApiService {
  final Dio _dio;

  RestApiService(this._dio) {
    _configureDio();
  }

  /// Configure Dio instance with interceptors and settings
  void _configureDio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);

    _dio.interceptors.addAll([
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add common headers for REST API
          options.headers.addAll({
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Cache-Control': 'no-cache',
          });
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Retry logic for network errors
          if (_shouldRetry(error)) {
            try {
              final response = await _dio.request(
                error.requestOptions.path,
                options: Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                ),
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
              );
              return handler.resolve(response);
            } catch (e) {
              // If retry fails, continue with original error
            }
          }

          // Enhanced error handling
          final errorMessage = _getErrorMessage(error);
          final enhancedError = DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: errorMessage,
          );

          return handler.next(enhancedError);
        },
      ),
    ]);
  }

  /// Determine if request should be retried based on error type
  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           error.type == DioExceptionType.sendTimeout ||
           (error.type == DioExceptionType.badResponse &&
            error.response?.statusCode == 500);
  }

  /// Get user-friendly error message from DioException
  String _getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout. Please try again.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return 'Authentication failed. Please check your token.';
        } else if (statusCode == 403) {
          return 'Access forbidden. You do not have permission.';
        } else if (statusCode == 404) {
          return 'Resource not found. Please contact support.';
        } else if (statusCode == 500) {
          return 'Server error. Please try again later.';
        } else {
          return 'Server error (${statusCode}). Please try again.';
        }
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      case DioExceptionType.unknown:
        if (error.error.toString().contains('SocketException')) {
          return 'Network error. Please check your internet connection.';
        }
        return 'Unknown error occurred. Please try again.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get thumbnails from the REST API
  /// Fetches thumbnail data from the server and returns a list of Thumbnail objects
  /// This method requires authentication token to be set in the headers
  /// Uses hardcoded URL as thumbnails come from a separate service
  ///
  /// @param authToken The authentication token for API access
  /// @return Future<List<Thumbnail>> List of thumbnail objects
  /// @throws Exception if API call fails or response parsing fails
  Future<List<Thumbnail>> getThumbnails({
    required String authToken,
  }) async {
    // Hardcoded URL for thumbnails API - separate from main app API
    // TODO: Make this configurable when expanding to multiple environments
    const String thumbnailsBaseUrl = 'http://178.218.200.120:1596';

    try {
      if (kDebugMode) {
        print('RestApiService: Fetching thumbnails from $thumbnailsBaseUrl/api/v1/thumbnails');
      }

      // Validate input parameters
      if (authToken.isEmpty) {
        throw ArgumentError('Authentication token cannot be empty');
      }

      final response = await _dio.get(
        '$thumbnailsBaseUrl/api/v1/thumbnails',
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (kDebugMode) {
        print('RestApiService: Received ${response.data.length} characters of response data');
      }

      // Parse the response data - handle both direct list and wrapped in map
      dynamic rawData = response.data;
      List<dynamic> responseData;

      if (rawData is List) {
        responseData = rawData;
      } else if (rawData is Map<String, dynamic>) {
        // Try common keys for the list
        responseData = rawData['data'] as List<dynamic>? ??
                       rawData['thumbnails'] as List<dynamic>? ??
                       rawData['results'] as List<dynamic>? ??
                       [];
        if (responseData.isEmpty && rawData.isNotEmpty) {
          if (kDebugMode) {
            print('RestApiService: Unable to find list in response map. Available keys: ${rawData.keys}');
          }
          throw Exception('Unable to find thumbnail list in response. Response keys: ${rawData.keys}');
        }
      } else {
        throw Exception('Unexpected response type: ${rawData.runtimeType}. Expected List or Map.');
      }

      if (kDebugMode) {
        print('RestApiService: Parsing ${responseData.length} thumbnail records');
      }

      final thumbnails = <Thumbnail>[];

      for (final item in responseData) {
        try {
          final thumbnail = Thumbnail.fromJson(item as Map<String, dynamic>);
          thumbnails.add(thumbnail);

          if (kDebugMode && thumbnails.length <= 3) {
            print('RestApiService: Sample thumbnail - Entity: ${thumbnail.entityType}, Code: ${thumbnail.code1c}, Name: ${thumbnail.entityName}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('RestApiService: Error parsing thumbnail item: $e');
            print('RestApiService: Problematic item: $item');
          }
          // Continue with other items instead of failing completely
        }
      }

      if (kDebugMode) {
        print('RestApiService: Successfully parsed ${thumbnails.length} thumbnails');

        // Log summary statistics
        final clientThumbnails = thumbnails.where((t) => t.entityType == 'client').length;
        final productThumbnails = thumbnails.where((t) => t.entityType == 'nomenklatura').length;
        final mainThumbnails = thumbnails.where((t) => t.isMain).length;

        print('RestApiService: Summary - Clients: $clientThumbnails, Products: $productThumbnails, Main images: $mainThumbnails');
      }

      return thumbnails;

    } on DioException catch (e) {
      if (kDebugMode) {
        print('RestApiService: DioException while fetching thumbnails: ${e.message}');
        print('RestApiService: Response status: ${e.response?.statusCode}');
        print('RestApiService: Response data: ${e.response?.data}');
      }
      throw Exception('Thumbnails ma\'lumotlarini olishda xatolik: ${e.error}');
    } catch (e) {
      if (kDebugMode) {
        print('RestApiService: Unexpected error while fetching thumbnails: $e');
      }
      throw Exception('Thumbnails ma\'lumotlarini qayta ishlashda xatolik: $e');
    }
  }

  /// Test API connectivity and authentication
  /// This method can be used to verify that the API is accessible and token is valid
  /// Uses hardcoded URL as thumbnails come from a separate service
  ///
  /// @param authToken The authentication token for API access
  /// @return Future<bool> True if API is accessible, false otherwise
  Future<bool> testApiConnectivity({
    required String authToken,
  }) async {
    // Hardcoded URL for thumbnails API - separate from main app API
    // TODO: Make this configurable when expanding to multiple environments
    const String thumbnailsBaseUrl = 'http://178.218.200.120:1596';

    try {
      if (kDebugMode) {
        print('RestApiService: Testing API connectivity to $thumbnailsBaseUrl');
      }

      // Make a simple request to test connectivity
      final response = await _dio.get(
        '$thumbnailsBaseUrl/api/v1/thumbnails',
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
          // Set shorter timeout for connectivity test
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final isSuccess = response.statusCode == 200;
      if (kDebugMode) {
        print('RestApiService: API connectivity test ${isSuccess ? 'PASSED' : 'FAILED'} (Status: ${response.statusCode})');
      }

      return isSuccess;

    } catch (e) {
      if (kDebugMode) {
        print('RestApiService: API connectivity test FAILED: $e');
      }
      return false;
    }
  }

  /// Get API health status
  /// Checks if the API server is responding (without authentication)
  ///
  /// @param baseUrl The base URL of the API server
  /// @return Future<Map<String, dynamic>> Health status information
  Future<Map<String, dynamic>> getApiHealth({
    required String baseUrl,
  }) async {
    try {
      if (kDebugMode) {
        print('RestApiService: Checking API health at $baseUrl');
      }

      final response = await _dio.get(
        '$baseUrl/api/health', // Assuming health endpoint exists
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      return {
        'status': 'healthy',
        'statusCode': response.statusCode,
        'responseTime': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      if (kDebugMode) {
        print('RestApiService: API health check failed: $e');
      }

      return {
        'status': 'unhealthy',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Upload client images in bulk to the server
  /// Uses the dedicated media server endpoint for client image uploads
  ///
  /// @param clientCode The 1C code identifier for the client
  /// @param images List of local image files to upload
  /// @return Future<List<String>> List of successfully uploaded thumbnail URLs
  /// @throws DioException on network/upload failures
  Future<List<String>> uploadClientImagesBulk({
    required String clientCode,
    required List<File> images,
  }) async {
    try {
      if (images.isEmpty) {
        if (kDebugMode) {
          print('RestApiService: No images provided for upload');
        }
        return [];
      }

      // Prepare FormData for multipart upload
      final formData = FormData.fromMap({
        'client': clientCode,
        'images': images.map((file) {
          final filename = p.basename(file.path);
          return MultipartFile.fromFileSync(
            file.path,
            filename: filename,
          );
        }).toList(),
      });

      // Use dedicated media server base URL
      const String mediaBaseUrl = 'http://178.218.200.120:1596';

      final response = await _dio.post(
        '$mediaBaseUrl/api/v1/client-image/bulk-upload/',
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
          sendTimeout: const Duration(minutes: 5), // Longer timeout for file uploads
          receiveTimeout: const Duration(minutes: 1),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>? ?? <String, dynamic>{};

        // Assume API returns list of thumbnail URLs
        final urls = List<String>.from(data['urls'] ?? data['thumbnails'] ?? []);

        if (kDebugMode) {
          print('RestApiService: Successfully uploaded ${images.length} images for client $clientCode. Received ${urls.length} URLs');
        }

        return urls;
      } else {
        final errorMsg = _getErrorMessage(DioException(
          requestOptions: RequestOptions(path: '/api/v1/client-image/bulk-upload/'),
          response: response,
          type: DioExceptionType.badResponse,
        ));
        throw Exception('Upload failed: ${response.statusCode} - $errorMsg');
      }
    } on DioException catch (e) {
      final errorMsg = _getErrorMessage(e);
      if (kDebugMode) {
        print('RestApiService: DioException during client image upload: $errorMsg');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('RestApiService: Unexpected error during client image upload: $e');
      }
      throw Exception('Rasmlarni yuklashda kutilmagan xatolik: $e');
    }
  }
}