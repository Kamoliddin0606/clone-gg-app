import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

/// REST API Service for handling REST API calls to the server
/// This service handles client image data retrieval and other REST API operations
/// It uses Dio for HTTP requests with proper error handling and logging
class RestApiService {
  final Dio _dio;

  RestApiService(this._dio) {
    _configureDio();
  }

  /// Fetch client images from the media server REST API.
  ///
  /// This is the single source of truth for *client images* retrieval.
  /// The response is returned as a list of raw maps to keep this service
  /// independent from UI/database model classes.
  ///
  /// Endpoint:
  /// - GET http://178.218.200.120:1596/api/v1/client-image/
  ///
  /// Query params:
  /// - client (optional)
  ///
  /// Auth:
  /// - Requires Bearer token.
  Future<List<Map<String, dynamic>>> getClientImages({
    required String authToken,
    String? clientCode,
  }) async {
    const String baseUrl = 'http://178.218.200.120:1596';
    final endpoint = '$baseUrl/api/v1/client-image/';

    try {
      if (authToken.isEmpty) {
        throw ArgumentError('Authentication token cannot be empty');
      }

      final query = <String, dynamic>{};
      if (clientCode != null && clientCode.trim().isNotEmpty) {
        query['client_code_1c'] = clientCode;
      }

      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
        queryParameters: query.isEmpty ? null : query,
      );

      if (kDebugMode) {
        print('RestApiService: getClientImages queryParameters: ${query.isEmpty ? null : query}');
      }

      final raw = response.data;
      
      // Debug: Print response data to terminal
      if (kDebugMode) {
        print('=== CLIENT IMAGES API RESPONSE ===');
        print('Endpoint: $endpoint');
        print('Client Code: ${clientCode ?? "ALL"}');
        print('Response Type: ${raw.runtimeType}');
        print('Response Data: $raw');
        print('==================================');
      }
      
      if (raw is List) {
        return List<Map<String, dynamic>>.from(raw);
      }
      if (raw is Map<String, dynamic>) {
        final results = raw['results'] ?? raw['data'] ?? raw['client_images'];
        if (results is List) {
          return List<Map<String, dynamic>>.from(results);
        }
        return const <Map<String, dynamic>>[];
      }

      return const <Map<String, dynamic>>[];
    } on DioException catch (e) {
      if (kDebugMode) {
        print('RestApiService: DioException while fetching client images: ${e.message}');
        print('RestApiService: Response status: ${e.response?.statusCode}');
        print('RestApiService: Response data: ${e.response?.data}');
      }
      throw Exception('Client images ma\'lumotlarini olishda xatolik: ${e.error}');
    } catch (e) {
      if (kDebugMode) {
        print('RestApiService: Unexpected error while fetching client images: $e');
      }
      throw Exception('Client images ma\'lumotlarini qayta ishlashda xatolik: $e');
    }
  }

  /// Set a specific client image as the main image on the server
  ///
  /// This is a future extension point.
  /// The UI can call this method when a user selects a non-main image
  /// to become the new main image.
  /// Set a client image as main image
  ///
  /// Endpoint: PATCH http://178.218.200.120:1596/api/v1/client-image/{id}/
  /// Request body: {"is_main": true}
  /// Returns 200 OK on success
  ///
  /// @param authToken The authentication token for API access
  /// @param imageServerId The server ID of the image to set as main
  /// @return Future<bool> True if operation was successful, false otherwise
  Future<bool> setClientImageAsMain({
    required String authToken,
    required int imageServerId,
  }) async {
    const String mediaBaseUrl = 'http://178.218.200.120:1596';
    final String endpoint = '$mediaBaseUrl/api/v1/client-image/$imageServerId/';

    try {
      if (kDebugMode) {
        print('RestApiService: setClientImageAsMain called for imageServerId=$imageServerId');
        print('RestApiService: PATCH $endpoint');
      }

      final response = await _dio.patch(
        endpoint,
        data: {'is_main': true},
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (kDebugMode) {
        print('RestApiService: setClientImageAsMain response status: ${response.statusCode}');
        print('RestApiService: setClientImageAsMain response data: ${response.data}');
      }

      // Success: 200 OK
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('RestApiService: Image successfully set as main');
        }
        return true;
      }

      // Handle error responses
      if (response.statusCode == 401) {
        if (kDebugMode) {
          print('RestApiService: setClientImageAsMain - Unauthorized (401)');
        }
        throw Exception('Avtorizatsiya xatosi. Qayta tizimga kiring.');
      }

      if (response.statusCode == 404) {
        if (kDebugMode) {
          print('RestApiService: setClientImageAsMain - Image not found (404)');
        }
        throw Exception('Rasm serverda topilmadi.');
      }

      if (kDebugMode) {
        print('RestApiService: setClientImageAsMain failed with status ${response.statusCode}');
      }
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('RestApiService: setClientImageAsMain DioException: ${e.type}');
        print('RestApiService: Error message: ${e.message}');
      }
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Server bilan aloqa vaqti tugadi.');
      }
      
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Internetga ulanishda xatolik.');
      }
      
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('RestApiService: setClientImageAsMain error: $e');
      }
      rethrow;
    }
  }

  /// Delete a client image from the server
  ///
  /// Endpoint: DELETE http://178.218.200.120:1596/api/v1/client-image/{id}/
  /// Returns 204 No Content on success
  ///
  /// @param authToken The authentication token for API access
  /// @param imageId The server ID of the image to delete
  /// @return Future<bool> True if deletion was successful, false otherwise
  Future<bool> deleteClientImage({
    required String authToken,
    required int imageId,
  }) async {
    const String baseUrl = 'http://178.218.200.120:1596';
    final endpoint = '$baseUrl/api/v1/client-image/$imageId/';

    try {
      if (authToken.isEmpty) {
        throw ArgumentError('Authentication token cannot be empty');
      }

      if (kDebugMode) {
        print('RestApiService: Deleting client image with ID: $imageId');
        print('RestApiService: Endpoint: $endpoint');
      }

      final response = await _dio.delete(
        endpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      // 204 No Content means successful deletion
      if (response.statusCode == 204 || response.statusCode == 200) {
        if (kDebugMode) {
          print('RestApiService: Successfully deleted client image ID: $imageId');
        }
        return true;
      }

      if (kDebugMode) {
        print('RestApiService: Unexpected status code: ${response.statusCode}');
      }
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('RestApiService: DioException while deleting client image: ${e.message}');
        print('RestApiService: Response status: ${e.response?.statusCode}');
        print('RestApiService: Response data: ${e.response?.data}');
      }

      // Handle specific error cases
      if (e.response?.statusCode == 404) {
        throw Exception('Rasm serverda topilmadi (ID: $imageId)');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Autentifikatsiya muddati tugadi. Iltimos, qayta kiring.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Bu rasmni o\'chirishga ruxsatingiz yo\'q.');
      }

      throw Exception('Rasmni o\'chirishda xatolik: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('RestApiService: Unexpected error while deleting client image: $e');
      }
      throw Exception('Rasmni o\'chirishda kutilmagan xatolik: $e');
    }
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
          // Enhanced error handling without retry logic
          // Retry removed to prevent duplicate requests
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

  /// Test API connectivity and authentication
  /// This method can be used to verify that the API is accessible and token is valid
  /// Uses client images endpoint as the primary signal that the media API is reachable
  ///
  /// @param authToken The authentication token for API access
  /// @return Future<bool> True if API is accessible, false otherwise
  Future<bool> testApiConnectivity({
    required String authToken,
  }) async {
    const String baseUrl = 'http://178.218.200.120:1596';

    try {
      if (kDebugMode) {
        print('RestApiService: Testing API connectivity to $baseUrl');
      }

      // Make a simple request to test connectivity
      final response = await _dio.get(
        '$baseUrl/api/v1/client-image',
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
  /// @return Future<List<String>> List of successfully uploaded image URLs
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

        final urls = List<String>.from(data['urls'] ?? []);

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

  /// Fetch product images from the media server REST API (nomenklatura-image).
  ///
  /// This retrieves images for products (nomenklatura) from the media server.
  /// The response is returned as a list of raw maps to keep this service
  /// independent from UI/database model classes.
  ///
  /// Endpoint:
  /// - GET http://178.218.200.120:1596/api/v1/nomenklatura-image/
  ///
  /// Query params:
  /// - nomenklatura (optional) - Product code_1c filter
  /// - is_main (optional) - Filter main images only
  /// - category (optional) - Filter by category
  /// - page (optional) - Page number for pagination
  ///
  /// Auth:
  /// - Requires Bearer token.
  Future<List<Map<String, dynamic>>> getProductImages({
    required String authToken,
    String? productCode,
    bool? isMain,
    String? category,
    int? page,
  }) async {
    const String baseUrl = 'http://178.218.200.120:1596';
    final endpoint = '$baseUrl/api/v1/nomenklatura-image/';

    try {
      if (authToken.isEmpty) {
        throw ArgumentError('Authentication token cannot be empty');
      }

      final query = <String, dynamic>{};
      if (productCode != null && productCode.trim().isNotEmpty) {
        query['nomenklatura'] = productCode;
      }
      if (isMain != null) {
        query['is_main'] = isMain;
      }
      if (category != null && category.trim().isNotEmpty) {
        query['category'] = category;
      }
      if (page != null && page > 0) {
        query['page'] = page;
      }

      if (kDebugMode) {
        print('RestApiService: Fetching product images from $endpoint');
        print('RestApiService: Query params: $query');
      }

      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
        queryParameters: query.isEmpty ? null : query,
      );

      final raw = response.data;
      List<Map<String, dynamic>> results = [];

      if (raw is List) {
        results = List<Map<String, dynamic>>.from(raw);
      } else if (raw is Map<String, dynamic>) {
        // Handle paginated response
        final data = raw['results'] ?? raw['data'] ?? raw['images'];
        if (data is List) {
          results = List<Map<String, dynamic>>.from(data);
        }
      }

      if (kDebugMode) {
        print('RestApiService: Fetched ${results.length} product images');
      }

      return results;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('RestApiService: DioException while fetching product images: ${e.message}');
        print('RestApiService: Response status: ${e.response?.statusCode}');
        print('RestApiService: Response data: ${e.response?.data}');
      }
      throw Exception('Mahsulot rasmlarini olishda xatolik: ${e.error}');
    } catch (e) {
      if (kDebugMode) {
        print('RestApiService: Unexpected error while fetching product images: $e');
      }
      throw Exception('Mahsulot rasmlarini qayta ishlashda xatolik: $e');
    }
  }

  /// Fetch nomenklatura list to get ID to code_1c mapping
  ///
  /// This method fetches all nomenklatura items to create a mapping
  /// from nomenklatura ID to code_1c, which is needed to match
  /// product images with products.
  ///
  /// @param authToken The authentication token for API access
  /// @return Future<Map<int, String>> Mapping of nomenklatura ID to code_1c
  Future<Map<int, String>> getNomenklaturaIdToCodeMapping({
    required String authToken,
  }) async {
    const String baseUrl = 'http://178.218.200.120:1596';
    final endpoint = '$baseUrl/api/v1/nomenklatura/';
    final mapping = <int, String>{};
    int page = 1;
    bool hasMore = true;

    try {
      while (hasMore) {
        final response = await _dio.get(
          endpoint,
          options: Options(
            headers: {'Authorization': 'Bearer $authToken'},
          ),
          queryParameters: {'page': page, 'page_size': 500},
        );

        final raw = response.data;
        List<Map<String, dynamic>> pageResults = [];

        if (raw is Map<String, dynamic>) {
          final data = raw['results'] ?? raw['data'];
          if (data is List) {
            pageResults = List<Map<String, dynamic>>.from(data);
          }
          final nextValue = raw['next'];
          hasMore = nextValue != null &&
                    nextValue.toString().trim().isNotEmpty &&
                    nextValue.toString() != 'null';
        } else if (raw is List) {
          pageResults = List<Map<String, dynamic>>.from(raw);
          hasMore = false;
        }

        if (pageResults.isEmpty) {
          hasMore = false;
          break;
        }

        for (final item in pageResults) {
          final id = item['id'] as int?;
          final code1c = item['code_1c'] as String?;
          if (id != null && code1c != null && code1c.isNotEmpty) {
            mapping[id] = code1c;
          }
        }

        page++;
      }

      if (kDebugMode) {
        print('RestApiService: Fetched ${mapping.length} nomenklatura ID->code_1c mappings');
      }

      return mapping;
    } catch (e) {
      if (kDebugMode) {
        print('RestApiService: Error fetching nomenklatura mapping: $e');
      }
      return mapping;
    }
  }

  /// Fetch all product images with pagination support
  ///
  /// This method fetches all pages of product images from the server.
  /// Useful for initial sync of all product images.
  ///
  /// @param authToken The authentication token for API access
  /// @param onProgress Optional callback for progress updates
  /// @return Future<List<Map<String, dynamic>>> All product images
  Future<List<Map<String, dynamic>>> getAllProductImages({
    required String authToken,
    String? projectCode,
    void Function(int fetched, int? total)? onProgress,
  }) async {
    const String baseUrl = 'http://178.218.200.120:1596';
    final endpoint = '$baseUrl/api/v1/nomenklatura-image/';
    final allResults = <Map<String, dynamic>>[];
    int page = 1;
    int? totalCount;
    bool hasMore = true;

    try {
      while (hasMore) {
        if (kDebugMode) {
          print('RestApiService: Fetching product images page $page');
        }

        final response = await _dio.get(
          endpoint,
          options: Options(
            headers: {
              'Authorization': 'Bearer $authToken',
            },
          ),
          queryParameters: {
            'page': page,
            if (projectCode != null && projectCode.isNotEmpty) 'project': projectCode,
          },
        );

        final raw = response.data;
        List<Map<String, dynamic>> pageResults = [];

        if (raw is Map<String, dynamic>) {
          totalCount = raw['count'] as int?;
          final data = raw['results'] ?? raw['data'];
          if (data is List) {
            pageResults = List<Map<String, dynamic>>.from(data);
          }
          final nextValue = raw['next'];
          hasMore = nextValue != null && 
                    nextValue.toString().trim().isNotEmpty &&
                    nextValue.toString() != 'null';
        } else if (raw is List) {
          pageResults = List<Map<String, dynamic>>.from(raw);
          hasMore = false;
        }

        if (pageResults.isEmpty) {
          hasMore = false;
          break;
        }

        allResults.addAll(pageResults);
        onProgress?.call(allResults.length, totalCount);

        page++;
      }

      if (kDebugMode) {
        print('RestApiService: Fetched total ${allResults.length} product images');
      }

      return allResults;
    } catch (e) {
      if (kDebugMode) {
        print('RestApiService: Error fetching all product images: $e');
      }
      // Return what we have so far
      return allResults;
    }
  }
}