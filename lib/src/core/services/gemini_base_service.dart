import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_key_service.dart';

/// Base service for all Google Gemini AI integrations
/// 
/// This abstract class provides common functionality for all Gemini-based services
/// including API key management, request handling, and error management.
/// 
/// Features:
/// - Centralized API key retrieval from ApiKeyService
/// - Unified HTTP request handling via Dio
/// - Consistent error handling and logging
/// - Configurable timeout and retry logic
/// - Support for multiple Gemini models with fallback
/// 
/// All Gemini services should extend this base class to ensure consistency
/// and reduce code duplication.
/// 
/// Example:
/// ```dart
/// class MyGeminiService extends GeminiBaseService {
///   MyGeminiService({
///     required ApiKeyService apiKeyService,
///     required Dio dio,
///   }) : super(apiKeyService: apiKeyService, dio: dio);
///   
///   Future<Result> myMethod() async {
///     final response = await makeGeminiRequest(
///       model: 'gemini-1.5-flash',
///       body: {...},
///     );
///     return parseResponse(response);
///   }
/// }
/// ```
abstract class GeminiBaseService {
  /// API key service for retrieving Gemini API key
  final ApiKeyService _apiKeyService;
  
  /// Dio HTTP client for making API requests
  final Dio _dio;
  
  /// Base URL for Google Gemini API
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  
  /// Default timeout for API requests (10 seconds)
  /// This timeout is suitable for large image uploads and processing
  static const Duration defaultTimeout = Duration(seconds: 10);
  
  /// Default fallback API key for development
  /// TODO: Remove in production - API key should come from server
  static const String _defaultFallbackKey = 'AIzaSyDeIApWRmFwNOr5pQVvs_xwba0woIS3xYE';
  
  /// Constructor for GeminiBaseService
  /// 
  /// @param apiKeyService Service for managing API keys
  /// @param dio HTTP client for making requests
  GeminiBaseService({
    required ApiKeyService apiKeyService,
    required Dio dio,
  })  : _apiKeyService = apiKeyService,
        _dio = dio;
  
  /// Get the ApiKeyService instance (for subclasses if needed)
  @protected
  ApiKeyService get apiKeyService => _apiKeyService;
  
  /// Get the Dio instance (for subclasses if needed)
  @protected
  Dio get dio => _dio;
  
  /// Get Gemini API key from ApiKeyService with fallback support
  /// 
  /// Retrieves the API key from secure storage. Falls back to default key
  /// if no key is configured (development only).
  /// 
  /// @returns The Gemini API key
  /// @throws GeminiException if API key retrieval fails critically
  Future<String> getApiKey() async {
    try {
      final key = await _apiKeyService.getApiKeyWithFallback(
        ApiKeyService.geminiApiKey,
        fallbackKey: _defaultFallbackKey,
      );
      
      if (key == null || key.isEmpty) {
        throw GeminiException(
          code: GeminiErrorCode.apiKeyNotFound,
          message: 'Gemini API key not configured. Please configure it in settings.',
        );
      }
      
      if (kDebugMode) {
        debugPrint('[GeminiBaseService] API key retrieved successfully');
      }
      
      return key;
    } catch (e) {
      if (e is GeminiException) rethrow;
      
      if (kDebugMode) {
        debugPrint('[GeminiBaseService] Error getting API key: $e');
      }
      
      throw GeminiException(
        code: GeminiErrorCode.apiKeyError,
        message: 'Failed to retrieve API key: $e',
      );
    }
  }
  
  /// Make a request to Gemini API
  /// 
  /// Handles the HTTP request to Gemini API with proper error handling,
  /// timeout management, and logging.
  /// 
  /// @param model The Gemini model to use (e.g., 'gemini-1.5-flash')
  /// @param body The request body as a Map
  /// @param timeout Optional custom timeout duration
  /// @returns The response data as a Map
  /// @throws GeminiException for various error conditions
  Future<Map<String, dynamic>> makeGeminiRequest({
    required String model,
    required Map<String, dynamic> body,
    Duration? timeout,
  }) async {
    final requestTimeout = timeout ?? defaultTimeout;
    
    try {
      // Get API key
      final apiKey = await getApiKey();
      
      // Build URL
      final url = '$baseUrl/models/$model:generateContent?key=$apiKey';
      
      if (kDebugMode) {
        debugPrint('[GeminiBaseService] Making request to model: $model');
      }
      
      // Make request
      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: requestTimeout,
          receiveTimeout: requestTimeout,
        ),
      );
      
      if (kDebugMode) {
        debugPrint('[GeminiBaseService] Response status: ${response.statusCode}');
      }
      
      // Handle successful response
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      
      // Handle error response
      throw GeminiException(
        code: GeminiErrorCode.httpError,
        message: 'HTTP ${response.statusCode}: ${response.data}',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[GeminiBaseService] Dio error: ${e.type} - ${e.message}');
      }
      
      // Handle specific Dio errors
      throw _handleDioException(e);
    } on GeminiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GeminiBaseService] Unexpected error: $e');
      }
      
      throw GeminiException(
        code: GeminiErrorCode.unknownError,
        message: 'Unexpected error: $e',
      );
    }
  }
  
  /// Handle Dio exceptions and convert to GeminiException
  /// 
  /// @param e The DioException to handle
  /// @returns GeminiException with appropriate error code
  GeminiException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return GeminiException(
          code: GeminiErrorCode.timeout,
          message: 'Request timeout. Please check your internet connection.',
        );
      
      case DioExceptionType.connectionError:
        return GeminiException(
          code: GeminiErrorCode.networkError,
          message: 'Network error. Please check your internet connection.',
        );
      
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        
        if (statusCode == 401 || statusCode == 403) {
          return GeminiException(
            code: GeminiErrorCode.authError,
            message: 'Authentication failed. Please check your API key.',
            statusCode: statusCode,
          );
        } else if (statusCode == 429) {
          return GeminiException(
            code: GeminiErrorCode.rateLimitError,
            message: 'Rate limit exceeded. Please try again later.',
            statusCode: statusCode,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return GeminiException(
            code: GeminiErrorCode.serverError,
            message: 'Gemini server error. Please try again later.',
            statusCode: statusCode,
          );
        }
        
        return GeminiException(
          code: GeminiErrorCode.httpError,
          message: 'HTTP error: ${e.message}',
          statusCode: statusCode,
        );
      
      case DioExceptionType.cancel:
        return GeminiException(
          code: GeminiErrorCode.cancelled,
          message: 'Request was cancelled.',
        );
      
      default:
        return GeminiException(
          code: GeminiErrorCode.unknownError,
          message: 'Unknown network error: ${e.message}',
        );
    }
  }
  
  /// Make a request with model fallback
  /// 
  /// Tries multiple models in order until one succeeds.
  /// Useful for ensuring service availability when specific models fail.
  /// 
  /// @param models List of model names to try in order
  /// @param body The request body
  /// @param timeout Optional custom timeout duration per request
  /// @returns The response from the first successful model
  /// @throws GeminiException if all models fail
  Future<Map<String, dynamic>> makeGeminiRequestWithFallback({
    required List<String> models,
    required Map<String, dynamic> body,
    Duration? timeout,
  }) async {
    if (models.isEmpty) {
      throw GeminiException(
        code: GeminiErrorCode.invalidRequest,
        message: 'At least one model must be specified.',
      );
    }
    
    final errors = <String>[];
    
    for (int i = 0; i < models.length; i++) {
      final model = models[i];
      
      if (kDebugMode) {
        debugPrint('[GeminiBaseService] Trying model $model (${i + 1}/${models.length})');
      }
      
      try {
        final response = await makeGeminiRequest(
          model: model,
          body: body,
          timeout: timeout,
        );
        
        if (kDebugMode) {
          debugPrint('[GeminiBaseService] ✅ Success with model $model');
        }
        
        return response;
      } catch (e) {
        final errorMsg = '$model failed: $e';
        errors.add(errorMsg);
        
        if (kDebugMode) {
          debugPrint('[GeminiBaseService] ❌ $errorMsg');
        }
        
        // If not the last model, continue to next
        if (i < models.length - 1) {
          if (kDebugMode) {
            debugPrint('[GeminiBaseService] Falling back to next model...');
          }
          continue;
        }
      }
    }
    
    // All models failed
    throw GeminiException(
      code: GeminiErrorCode.allModelsFailed,
      message: 'All ${models.length} models failed. Errors: ${errors.join("; ")}',
    );
  }
  
  /// Extract text content from Gemini API response
  /// 
  /// Navigates the response structure to extract the text content.
  /// 
  /// @param response The raw API response
  /// @returns The extracted text content
  /// @throws GeminiException if content cannot be extracted
  @protected
  String extractTextFromResponse(Map<String, dynamic> response) {
    try {
      final candidates = response['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw GeminiException(
          code: GeminiErrorCode.noContent,
          message: 'No response candidates from AI',
        );
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw GeminiException(
          code: GeminiErrorCode.noContent,
          message: 'Empty response parts',
        );
      }

      final textContent = parts[0]['text'] as String?;
      if (textContent == null || textContent.isEmpty) {
        throw GeminiException(
          code: GeminiErrorCode.noContent,
          message: 'Empty text response',
        );
      }

      return textContent;
    } catch (e) {
      if (e is GeminiException) rethrow;
      
      throw GeminiException(
        code: GeminiErrorCode.parseError,
        message: 'Failed to extract text from response: $e',
      );
    }
  }
}

/// Error codes for Gemini API exceptions
/// 
/// Provides structured error identification for all Gemini-related failures.
/// Each code represents a specific type of error that can be handled differently.
enum GeminiErrorCode {
  /// API key not found or not configured
  apiKeyNotFound,
  
  /// Error retrieving API key from storage
  apiKeyError,
  
  /// Network connection error
  networkError,
  
  /// Request timeout
  timeout,
  
  /// Authentication error (HTTP 401, 403)
  authError,
  
  /// Rate limit exceeded (HTTP 429)
  rateLimitError,
  
  /// Server error (HTTP 5xx)
  serverError,
  
  /// HTTP error (other status codes)
  httpError,
  
  /// All fallback models failed
  allModelsFailed,
  
  /// No content in response
  noContent,
  
  /// Error parsing response
  parseError,
  
  /// Invalid request parameters
  invalidRequest,
  
  /// Request was cancelled
  cancelled,
  
  /// Unknown or unexpected error
  unknownError,
}

/// Exception class for Gemini API errors
/// 
/// Provides structured error information for all Gemini-related failures.
/// Includes error code, message, and optional HTTP status code.
/// 
/// Usage:
/// ```dart
/// try {
///   await geminiService.someMethod();
/// } on GeminiException catch (e) {
///   print('Error: ${e.code} - ${e.message}');
///   // Handle specific error types
///   if (e.code == GeminiErrorCode.authError) {
///     // Handle auth error
///   }
/// }
/// ```
class GeminiException implements Exception {
  /// Error code identifying the type of error
  final GeminiErrorCode code;
  
  /// Human-readable error message
  final String message;
  
  /// HTTP status code if applicable
  final int? statusCode;
  
  /// Constructor for GeminiException
  /// 
  /// @param code The error code
  /// @param message The error message
  /// @param statusCode Optional HTTP status code
  const GeminiException({
    required this.code,
    required this.message,
    this.statusCode,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer('GeminiException: ${code.name} - $message');
    if (statusCode != null) {
      buffer.write(' (HTTP $statusCode)');
    }
    return buffer.toString();
  }
  
  /// Check if error is retryable
  /// 
  /// Some errors like network issues or rate limits may be resolved by retrying.
  /// 
  /// @returns true if the error is potentially retryable
  bool get isRetryable {
    switch (code) {
      case GeminiErrorCode.networkError:
      case GeminiErrorCode.timeout:
      case GeminiErrorCode.rateLimitError:
      case GeminiErrorCode.serverError:
        return true;
      default:
        return false;
    }
  }
  
  /// Check if error is related to authentication
  /// 
  /// @returns true if the error is an auth error
  bool get isAuthError => code == GeminiErrorCode.authError;
  
  /// Check if error is related to API key
  /// 
  /// @returns true if the error is related to API key
  bool get isApiKeyError => 
      code == GeminiErrorCode.apiKeyNotFound || 
      code == GeminiErrorCode.apiKeyError;
}
