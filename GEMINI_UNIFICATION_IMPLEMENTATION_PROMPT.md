# Professional Implementation Prompt: Gemini API Unification

## 🎯 Project Objective

Refactor and unify the Gemini API integration in the Flutter application to eliminate code duplication, centralize API key management, and establish a scalable, maintainable architecture following industry best practices.

---

## 📋 Current State Analysis

### Existing Services

1. **GeminiDocumentScannerService** (`lib/src/core/services/gemini_document_scanner_service.dart`)
   - Document scanning with OCR capabilities
   - Smart fallback system with 3 models
   - Image compression (5MB → 500KB)
   - Uses `http` package
   - Hardcoded API key in `create_client_page.dart`
   - NOT registered in service locator

2. **GeminiTimeVerificationService** (`lib/src/core/services/gemini_time_verification_service.dart`)
   - Real-time verification using device location
   - Uses `Dio` HTTP client
   - Separate API key management via SharedPreferences
   - Registered in service locator

3. **ApiKeyService** (`lib/src/core/services/api_key_service.dart`)
   - Centralized API key management
   - Supports Google Maps, Yandex, OpenStreetMap, Server keys
   - Format validation
   - Singleton pattern
   - NOT used for Gemini API keys

### Problems Identified

- ❌ Code duplication in API key management
- ❌ Inconsistent HTTP client usage (http vs Dio)
- ❌ Service registration inconsistency
- ❌ Hardcoded API keys in UI layer
- ❌ No unified error handling
- ❌ Difficult to maintain and extend

---

## 🎯 Implementation Requirements

### 1. Architecture & Design Principles

**SOLID Principles:**
- **Single Responsibility**: Each service handles one specific concern
- **Open/Closed**: Open for extension, closed for modification
- **Liskov Substitution**: Derived classes must be substitutable
- **Interface Segregation**: No client forced to depend on unused methods
- **Dependency Inversion**: Depend on abstractions, not concretions

**Design Patterns:**
- ✅ Singleton pattern for services
- ✅ Factory pattern for service creation
- ✅ Strategy pattern for model fallback
- ✅ Repository pattern for API key storage
- ✅ Dependency Injection via service locator

**Clean Code Principles:**
- ✅ DRY (Don't Repeat Yourself)
- ✅ KISS (Keep It Simple, Stupid)
- ✅ YAGNI (You Aren't Gonna Need It)
- ✅ Separation of Concerns
- ✅ High Cohesion, Low Coupling

### 2. Code Quality Standards

**Documentation:**
- All classes must have comprehensive English documentation
- All public methods must have English doc comments
- All parameters must be documented with `@param` tags
- All return values must be documented with `@returns` tags
- Complex logic must have inline English comments
- Usage examples in class documentation

**Naming Conventions:**
- Classes: PascalCase (e.g., `GeminiBaseService`)
- Methods: camelCase (e.g., `makeGeminiRequest`)
- Private members: prefix with underscore (e.g., `_apiKeyService`)
- Constants: UPPER_SNAKE_CASE or lowerCamelCase for const
- Descriptive, self-documenting names

**Error Handling:**
- Custom exception classes for different error types
- Detailed error messages with context
- Proper error propagation
- Logging for debugging (debug mode only)
- User-friendly error messages in UI

**Testing:**
- Unit tests for all business logic
- Integration tests for API calls
- Mock services for testing
- Test coverage > 80%

### 3. Performance Requirements

**Efficiency:**
- ✅ Singleton pattern to prevent multiple instances
- ✅ Lazy initialization where appropriate
- ✅ Connection pooling via shared Dio instance
- ✅ Image compression before API calls
- ✅ Caching strategies for repeated requests
- ✅ Timeout handling (10 seconds max)
- ✅ Retry logic with exponential backoff

**Memory Management:**
- ✅ Proper disposal of resources
- ✅ Stream cleanup
- ✅ Avoid memory leaks
- ✅ Efficient data structures

### 4. Security Requirements

**API Key Management:**
- ✅ Never hardcode API keys in code
- ✅ Store keys securely in SharedPreferences
- ✅ Support for server-provided keys
- ✅ Key rotation capability
- ✅ Validation before storage
- ✅ Encryption support (future enhancement)

**Data Protection:**
- ✅ Secure HTTP (HTTPS only)
- ✅ Input validation
- ✅ Output sanitization
- ✅ No sensitive data in logs (production)

### 5. Localization Requirements

**Supported Languages:**
- 🇬🇧 English (EN) - Primary
- 🇷🇺 Russian (RU) - Full support
- 🇺🇿 Uzbek (UZ) - Full support

**Localization Strings Required:**

```dart
// Error messages
"geminiApiKeyNotFound": "Gemini API key not configured",
"geminiApiKeyNotFoundRu": "Ключ API Gemini не настроен",
"geminiApiKeyNotFoundUz": "Gemini API kaliti sozlanmagan",

"geminiNetworkError": "Network error occurred",
"geminiNetworkErrorRu": "Произошла ошибка сети",
"geminiNetworkErrorUz": "Tarmoq xatosi yuz berdi",

"geminiAuthError": "Authentication failed. Check API key",
"geminiAuthErrorRu": "Ошибка аутентификации. Проверьте ключ API",
"geminiAuthErrorUz": "Autentifikatsiya xatosi. API kalitini tekshiring",

"geminiRateLimitError": "Rate limit exceeded. Please try again later",
"geminiRateLimitErrorRu": "Превышен лимит запросов. Попробуйте позже",
"geminiRateLimitErrorUz": "So'rovlar limiti oshib ketdi. Keyinroq urinib ko'ring",

"geminiServerError": "Server error. Please try again",
"geminiServerErrorRu": "Ошибка сервера. Попробуйте снова",
"geminiServerErrorUz": "Server xatosi. Qaytadan urinib ko'ring",

"geminiTimeoutError": "Request timeout. Check your connection",
"geminiTimeoutErrorRu": "Превышено время ожидания. Проверьте соединение",
"geminiTimeoutErrorUz": "So'rov vaqti tugadi. Ulanishni tekshiring",

// Success messages
"geminiApiKeyConfigured": "Gemini API key configured successfully",
"geminiApiKeyConfiguredRu": "Ключ API Gemini успешно настроен",
"geminiApiKeyConfiguredUz": "Gemini API kaliti muvaffaqiyatli sozlandi",

// Settings
"geminiApiKeyLabel": "Gemini API Key",
"geminiApiKeyLabelRu": "Ключ API Gemini",
"geminiApiKeyLabelUz": "Gemini API kaliti",

"geminiApiKeyHint": "Enter your Gemini API key",
"geminiApiKeyHintRu": "Введите ваш ключ API Gemini",
"geminiApiKeyHintUz": "Gemini API kalitingizni kiriting",
```

### 6. UI/UX Requirements

**Modern Design:**
- ✅ Material Design 3 guidelines
- ✅ Smooth animations and transitions
- ✅ Loading indicators for async operations
- ✅ Clear error messages with recovery options
- ✅ Responsive design
- ✅ Accessibility support

**User Feedback:**
- ✅ Progress indicators during API calls
- ✅ Success/error snackbars
- ✅ Retry buttons on errors
- ✅ Clear status messages
- ✅ Localized messages

---

## 🏗️ Implementation Plan

### Phase 1: Foundation (2 hours)

#### Step 1.1: Extend ApiKeyService

**File:** `lib/src/core/services/api_key_service.dart`

**Tasks:**
1. Add Gemini API key constant
2. Add validation for Gemini API key format
3. Update `getAllApiKeys()` method
4. Update `clearAllApiKeys()` method
5. Add comprehensive English documentation

**Code Requirements:**
```dart
/// Service for managing API keys with SharedPreferences persistence
/// 
/// This service provides centralized API key management for all external services
/// including Google Maps, Yandex Maps, OpenStreetMap, Server APIs, and Gemini AI.
/// 
/// Features:
/// - Secure storage using SharedPreferences
/// - Format validation for each key type
/// - Singleton pattern for global access
/// - Support for fallback keys
/// 
/// Usage:
/// ```dart
/// final apiKeyService = sl<ApiKeyService>();
/// await apiKeyService.storeApiKey(ApiKeyService.geminiApiKey, 'your-key');
/// final key = await apiKeyService.getApiKey(ApiKeyService.geminiApiKey);
/// ```
class ApiKeyService {
  // ... existing code ...
  
  /// API key type for Google Gemini AI services
  /// Used for document scanning, time verification, and other AI features
  static const String geminiApiKey = 'gemini_api_key';
  
  /// Validate API key format for a specific service
  /// 
  /// Performs format validation based on the key type.
  /// Each service has specific format requirements.
  /// 
  /// @param keyType The type of API key to validate
  /// @param apiKey The API key string to validate
  /// @returns true if the format is valid, false otherwise
  bool validateApiKeyFormat(String keyType, String apiKey) {
    if (apiKey.isEmpty) return false;

    switch (keyType) {
      case googleMapsApiKey:
      case geminiApiKey:  // Add this
        // Google API keys start with 'AIza' and are 35-45 characters
        return apiKey.startsWith('AIza') && 
               apiKey.length >= 35 && 
               apiKey.length <= 45;
      
      // ... rest of cases
    }
  }
  
  /// Get all stored API keys (for debugging/admin purposes)
  /// 
  /// Returns a map of all stored API keys with their types as keys.
  /// Useful for debugging and administrative interfaces.
  /// 
  /// @returns Map of key types to API key values
  Future<Map<String, String>> getAllApiKeys() async {
    try {
      final keys = <String, String>{};

      for (final keyType in [
        googleMapsApiKey, 
        yandexMapsApiKey, 
        openStreetMapsApiKey, 
        serverApiKey,
        geminiApiKey,  // Add this
      ]) {
        final apiKey = await getApiKey(keyType);
        if (apiKey != null) {
          keys[keyType] = apiKey;
        }
      }

      return keys;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all API keys: $e');
      }
      return {};
    }
  }
}
```

#### Step 1.2: Create GeminiBaseService

**File:** `lib/src/core/services/gemini_base_service.dart`

**Tasks:**
1. Create abstract base class for all Gemini services
2. Implement common API request logic
3. Implement unified error handling
4. Add comprehensive English documentation
5. Add logging for debugging

**Code Requirements:**
```dart
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
/// - Support for multiple Gemini models
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
  static const Duration timeout = Duration(seconds: 10);
  
  /// Constructor for GeminiBaseService
  /// 
  /// @param apiKeyService Service for managing API keys
  /// @param dio HTTP client for making requests
  GeminiBaseService({
    required ApiKeyService apiKeyService,
    required Dio dio,
  })  : _apiKeyService = apiKeyService,
        _dio = dio;
  
  /// Get Gemini API key from ApiKeyService
  /// 
  /// Retrieves the API key from secure storage. Throws GeminiException
  /// if the key is not found or is invalid.
  /// 
  /// @returns The Gemini API key
  /// @throws GeminiException if API key is not configured
  Future<String> getApiKey() async {
    try {
      final key = await _apiKeyService.getApiKey(ApiKeyService.geminiApiKey);
      
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
  /// @returns The response data as a Map
  /// @throws GeminiException for various error conditions
  Future<Map<String, dynamic>> makeGeminiRequest({
    required String model,
    required Map<String, dynamic> body,
  }) async {
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
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
      );
      
      if (kDebugMode) {
        debugPrint('[GeminiBaseService] Response status: ${response.statusCode}');
      }
      
      // Handle response
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw GeminiException(
          code: GeminiErrorCode.httpError,
          message: 'HTTP ${response.statusCode}: ${response.data}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[GeminiBaseService] Dio error: ${e.type} - ${e.message}');
      }
      
      // Handle specific Dio errors
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw GeminiException(
            code: GeminiErrorCode.timeout,
            message: 'Request timeout. Please check your internet connection.',
          );
        
        case DioExceptionType.connectionError:
          throw GeminiException(
            code: GeminiErrorCode.networkError,
            message: 'Network error. Please check your internet connection.',
          );
        
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          if (statusCode == 401 || statusCode == 403) {
            throw GeminiException(
              code: GeminiErrorCode.authError,
              message: 'Authentication failed. Please check your API key.',
              statusCode: statusCode,
            );
          } else if (statusCode == 429) {
            throw GeminiException(
              code: GeminiErrorCode.rateLimitError,
              message: 'Rate limit exceeded. Please try again later.',
              statusCode: statusCode,
            );
          } else if (statusCode != null && statusCode >= 500) {
            throw GeminiException(
              code: GeminiErrorCode.serverError,
              message: 'Gemini server error. Please try again later.',
              statusCode: statusCode,
            );
          }
          throw GeminiException(
            code: GeminiErrorCode.httpError,
            message: 'HTTP error: ${e.message}',
            statusCode: statusCode,
          );
        
        default:
          throw GeminiException(
            code: GeminiErrorCode.unknownError,
            message: 'Unknown error: ${e.message}',
          );
      }
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
  
  /// Make a request with model fallback
  /// 
  /// Tries multiple models in order until one succeeds.
  /// Useful for ensuring service availability when specific models fail.
  /// 
  /// @param models List of model names to try in order
  /// @param body The request body
  /// @returns The response from the first successful model
  /// @throws GeminiException if all models fail
  Future<Map<String, dynamic>> makeGeminiRequestWithFallback({
    required List<String> models,
    required Map<String, dynamic> body,
  }) async {
    final errors = <String>[];
    
    for (int i = 0; i < models.length; i++) {
      final model = models[i];
      
      if (kDebugMode) {
        debugPrint('[GeminiBaseService] Trying model $model (${i + 1}/${models.length})');
      }
      
      try {
        final response = await makeGeminiRequest(model: model, body: body);
        
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
}

/// Error codes for Gemini API exceptions
enum GeminiErrorCode {
  /// API key not found or not configured
  apiKeyNotFound,
  
  /// Error retrieving API key
  apiKeyError,
  
  /// Network connection error
  networkError,
  
  /// Request timeout
  timeout,
  
  /// Authentication error (401, 403)
  authError,
  
  /// Rate limit exceeded (429)
  rateLimitError,
  
  /// Server error (5xx)
  serverError,
  
  /// HTTP error (other status codes)
  httpError,
  
  /// All fallback models failed
  allModelsFailed,
  
  /// Unknown error
  unknownError,
}

/// Exception class for Gemini API errors
/// 
/// Provides structured error information for all Gemini-related failures.
/// Includes error code, message, and optional HTTP status code.
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
  GeminiException({
    required this.code,
    required this.message,
    this.statusCode,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer('GeminiException: $code - $message');
    if (statusCode != null) {
      buffer.write(' (HTTP $statusCode)');
    }
    return buffer.toString();
  }
  
  /// Get localized error message
  /// 
  /// Returns a user-friendly error message based on the error code.
  /// Should be used in UI to display errors to users.
  /// 
  /// @param l10n Localization object
  /// @returns Localized error message
  String getLocalizedMessage(dynamic l10n) {
    switch (code) {
      case GeminiErrorCode.apiKeyNotFound:
        return l10n.geminiApiKeyNotFound;
      case GeminiErrorCode.networkError:
        return l10n.geminiNetworkError;
      case GeminiErrorCode.authError:
        return l10n.geminiAuthError;
      case GeminiErrorCode.rateLimitError:
        return l10n.geminiRateLimitError;
      case GeminiErrorCode.serverError:
        return l10n.geminiServerError;
      case GeminiErrorCode.timeout:
        return l10n.geminiTimeoutError;
      default:
        return message;
    }
  }
}
```

### Phase 2: Service Refactoring (3 hours)

#### Step 2.1: Refactor GeminiDocumentScannerService

**File:** `lib/src/core/services/gemini_document_scanner_service.dart`

**Tasks:**
1. Extend GeminiBaseService
2. Remove hardcoded API key
3. Use makeGeminiRequestWithFallback
4. Update constructor to accept ApiKeyService and Dio
5. Maintain all existing functionality
6. Add comprehensive English documentation
7. Keep image compression logic
8. Keep response parsing logic

**Key Changes:**
```dart
/// Service for scanning organization certificates using Google Gemini AI
/// 
/// This service uses Gemini's vision capabilities to extract structured data
/// from organization certificates, business licenses, and similar documents.
/// 
/// Features:
/// - Smart model fallback (tries 3 models in priority order)
/// - Automatic image compression (5MB → 500KB)
/// - 10-second timeout per model
/// - Structured data extraction with confidence scores
/// - Support for multiple document formats (JPEG, PNG, WebP, HEIC)
/// 
/// Usage:
/// ```dart
/// final scanner = sl<GeminiDocumentScannerService>();
/// final data = await scanner.scanDocument(imageBytes);
/// print('Organization: ${data.organizationName}');
/// print('INN: ${data.inn}');
/// ```
class GeminiDocumentScannerService extends GeminiBaseService {
  /// Model fallback chain in priority order
  /// Priority: Flash 2.5 > Flash 2.0 Exp > Flash 2.0
  static const List<String> modelFallbackChain = [
    'gemini-2.5-flash',          // Latest - 1.2s response
    'gemini-2.0-flash-exp',      // Fastest - 1.0s response
    'gemini-2.0-flash',          // Stable - 1.1s response
  ];
  
  /// Constructor for GeminiDocumentScannerService
  /// 
  /// @param apiKeyService Service for managing API keys
  /// @param dio HTTP client for making requests
  GeminiDocumentScannerService({
    required ApiKeyService apiKeyService,
    required Dio dio,
  }) : super(apiKeyService: apiKeyService, dio: dio);
  
  /// Scan organization certificate image and extract data
  /// 
  /// Compresses the image, sends it to Gemini AI, and extracts structured
  /// data including organization name, INN, director, address, etc.
  /// 
  /// @param imageBytes The image data as bytes
  /// @returns Extracted document data
  /// @throws GeminiException if scanning fails
  Future<ScannedDocumentData> scanDocument(Uint8List imageBytes) async {
    if (imageBytes.isEmpty) {
      throw GeminiException(
        code: GeminiErrorCode.unknownError,
        message: 'Image data is empty',
      );
    }

    // Compress image
    final compressedBytes = await _compressImage(imageBytes);
    
    if (kDebugMode) {
      debugPrint('[GeminiDocumentScanner] Original: ${imageBytes.length} bytes');
      debugPrint('[GeminiDocumentScanner] Compressed: ${compressedBytes.length} bytes');
    }

    // Convert to base64
    final base64Image = base64Encode(compressedBytes);
    final mimeType = _detectMimeType(compressedBytes);

    // Build request
    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': _buildExtractionPrompt()},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'topK': 32,
        'topP': 0.95,
        'maxOutputTokens': 1024,
        'responseMimeType': 'application/json',
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
      ],
    };

    // Use base service with fallback
    final response = await makeGeminiRequestWithFallback(
      models: modelFallbackChain,
      body: requestBody,
    );
    
    return _parseResponse(response);
  }
  
  // ... rest of existing methods with English documentation
}
```

#### Step 2.2: Refactor GeminiTimeVerificationService

**File:** `lib/src/core/services/gemini_time_verification_service.dart`

**Tasks:**
1. Extend GeminiBaseService
2. Remove duplicate API key management code
3. Use makeGeminiRequest from base service
4. Update constructor
5. Maintain all existing functionality
6. Add comprehensive English documentation

**Key Changes:**
```dart
/// Service for verifying real time using Google Gemini AI
/// 
/// This service uses Gemini to verify the actual current time based on
/// device location coordinates. This prevents time manipulation attacks
/// by getting verified time from an external trusted source.
/// 
/// Features:
/// - Location-based time verification
/// - Retry logic with exponential backoff
/// - Configurable Gemini model selection
/// - Fallback to device time if verification fails
/// 
/// Usage:
/// ```dart
/// final service = sl<GeminiTimeVerificationService>();
/// final verifiedTime = await service.verifyRealTime();
/// print('Verified time: $verifiedTime');
/// ```
class GeminiTimeVerificationService extends GeminiBaseService {
  /// Default Gemini model for time verification
  static const String defaultModel = 'gemini-1.5-flash';
  
  /// Maximum retry attempts for time verification
  static const int maxRetries = 3;
  
  /// Delay between retry attempts
  static const Duration retryDelay = Duration(seconds: 2);
  
  /// Constructor for GeminiTimeVerificationService
  /// 
  /// @param apiKeyService Service for managing API keys
  /// @param dio HTTP client for making requests
  GeminiTimeVerificationService({
    required ApiKeyService apiKeyService,
    required Dio dio,
  }) : super(apiKeyService: apiKeyService, dio: dio);
  
  /// Verify real time using Gemini AI
  /// 
  /// Gets device location and sends it to Gemini to get the actual
  /// current time for that location. This prevents time manipulation.
  /// 
  /// @param model Optional Gemini model to use
  /// @returns Verified current DateTime
  /// @throws GeminiException if verification fails
  Future<DateTime> verifyRealTime({String? model}) async {
    // Get device location
    final position = await _getDeviceLocation();
    
    // Build prompt
    final prompt = '''Based on the geographic coordinates (latitude: ${position.latitude}, longitude: ${position.longitude}), 
what is the current date and time in ISO 8601 format (YYYY-MM-DDTHH:mm:ss)?

Respond with ONLY the datetime string, no additional text.''';
    
    // Build request
    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 50,
      },
    };
    
    // Make request using base service
    final response = await makeGeminiRequest(
      model: model ?? defaultModel,
      body: requestBody,
    );
    
    return _parseTimeResponse(response);
  }
  
  // ... rest of existing methods with English documentation
}
```

### Phase 3: Service Registration (1 hour)

#### Step 3.1: Update Service Locator

**File:** `lib/src/core/services/service_locator.dart`

**Tasks:**
1. Register GeminiDocumentScannerService
2. Update GeminiTimeVerificationService registration
3. Ensure proper dependency injection
4. Add English documentation

**Code:**
```dart
// Gemini AI Services - Unified API key management
// All Gemini services use ApiKeyService for centralized key management
// and share the same Dio instance for efficient HTTP connection pooling

if (!sl.isRegistered<GeminiDocumentScannerService>()) {
  sl.registerLazySingleton<GeminiDocumentScannerService>(() => 
    GeminiDocumentScannerService(
      apiKeyService: sl<ApiKeyService>(),
      dio: sl<Dio>(),
    )
  );
}

if (!sl.isRegistered<GeminiTimeVerificationService>()) {
  sl.registerLazySingleton<GeminiTimeVerificationService>(() => 
    GeminiTimeVerificationService(
      apiKeyService: sl<ApiKeyService>(),
      dio: sl<Dio>(),
    )
  );
}
```

### Phase 4: UI Integration (2 hours)

#### Step 4.1: Update create_client_page.dart

**File:** `lib/src/features/agent/presentation/pages/create_client_page.dart`

**Tasks:**
1. Remove hardcoded API key constant
2. Get GeminiDocumentScannerService from service locator
3. Update error handling with localized messages
4. Add English documentation

**Changes:**
```dart
// Remove this line:
// const String _geminiApiKey = 'AIzaSyDeIApWRmFwNOr5pQVvs_xwba0woIS3xYE';

// In the widget:
class _CreateClientPageState extends State<CreateClientPage> {
  late final GeminiDocumentScannerService _scannerService;
  
  @override
  void initState() {
    super.initState();
    // Get service from service locator
    _scannerService = sl<GeminiDocumentScannerService>();
  }
  
  // Update DocumentScannerWidget usage:
  DocumentScannerWidget(
    scannerService: _scannerService,  // Pass service instead of API key
    onScanStarted: _clearFormForScan,
    onDataExtracted: _handleScannedData,
  ),
}
```

#### Step 4.2: Update document_scanner_widget.dart

**File:** `lib/src/features/agent/presentation/widgets/document_scanner_widget.dart`

**Tasks:**
1. Accept GeminiDocumentScannerService instead of API key
2. Update error handling with localized messages
3. Add English documentation

**Changes:**
```dart
/// Widget for scanning documents using Gemini AI
/// 
/// Provides a user-friendly interface for capturing or selecting images
/// and extracting structured data using Gemini AI.
class DocumentScannerWidget extends StatefulWidget {
  /// Gemini document scanner service
  final GeminiDocumentScannerService scannerService;
  
  /// Callback when scan starts
  final VoidCallback? onScanStarted;
  
  /// Callback when data is extracted
  final Function(ScannedDocumentData) onDataExtracted;
  
  const DocumentScannerWidget({
    super.key,
    required this.scannerService,
    this.onScanStarted,
    required this.onDataExtracted,
  });
  
  @override
  State<DocumentScannerWidget> createState() => _DocumentScannerWidgetState();
}

class _DocumentScannerWidgetState extends State<DocumentScannerWidget> {
  // Remove: late GeminiDocumentScannerService _scannerService;
  
  @override
  void initState() {
    super.initState();
    // Remove: _scannerService = GeminiDocumentScannerService(apiKey: widget.apiKey);
  }
  
  Future<void> _scanDocument(Uint8List imageBytes) async {
    try {
      // Use widget.scannerService instead of _scannerService
      final data = await widget.scannerService.scanDocument(imageBytes);
      widget.onDataExtracted(data);
    } on GeminiException catch (e) {
      // Show localized error message
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.getLocalizedMessage(l10n))),
      );
    }
  }
}
```

#### Step 4.3: Initialize API Key in main.dart

**File:** `lib/main.dart`

**Tasks:**
1. Initialize Gemini API key on app startup
2. Add fallback to default key
3. Add English documentation

**Code:**
```dart
Future<void> main() async {
  // ... existing initialization ...
  
  // Initialize Gemini API key
  // In production, this should be fetched from server
  try {
    final apiKeyService = sl<ApiKeyService>();
    
    // Check if Gemini API key exists
    final hasKey = await apiKeyService.hasApiKey(ApiKeyService.geminiApiKey);
    
    if (!hasKey) {
      // Use default key for development
      // TODO: Replace with server-provided key in production
      const defaultGeminiKey = 'AIzaSyDeIApWRmFwNOr5pQVvs_xwba0woIS3xYE';
      await apiKeyService.storeApiKey(ApiKeyService.geminiApiKey, defaultGeminiKey);
      
      if (kDebugMode) {
        debugPrint('[Main] Gemini API key initialized with default');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Main] Error initializing Gemini API key: $e');
    }
  }
  
  runApp(const App());
}
```

### Phase 5: Localization (1 hour)

#### Step 5.1: Add Localization Strings

**Files:** 
- `lib/l10n/app_en.arb`
- `lib/l10n/app_ru.arb`
- `lib/l10n/app_uz.arb`

**Tasks:**
1. Add all Gemini-related error messages
2. Add settings labels
3. Add success messages
4. Generate localization files

**English (app_en.arb):**
```json
{
  "geminiApiKeyNotFound": "Gemini API key not configured",
  "geminiNetworkError": "Network error occurred. Please check your connection",
  "geminiAuthError": "Authentication failed. Please check your API key in settings",
  "geminiRateLimitError": "Rate limit exceeded. Please try again in a few minutes",
  "geminiServerError": "Server error occurred. Please try again later",
  "geminiTimeoutError": "Request timeout. Please check your internet connection",
  "geminiApiKeyConfigured": "Gemini API key configured successfully",
  "geminiApiKeyLabel": "Gemini API Key",
  "geminiApiKeyHint": "Enter your Gemini API key (starts with AIza)",
  "geminiApiKeyDescription": "Used for document scanning and AI features",
  "geminiApiKeyInvalid": "Invalid API key format. Key should start with 'AIza'"
}
```

**Russian (app_ru.arb):**
```json
{
  "geminiApiKeyNotFound": "Ключ API Gemini не настроен",
  "geminiNetworkError": "Произошла ошибка сети. Проверьте подключение",
  "geminiAuthError": "Ошибка аутентификации. Проверьте ключ API в настройках",
  "geminiRateLimitError": "Превышен лимит запросов. Попробуйте через несколько минут",
  "geminiServerError": "Ошибка сервера. Попробуйте позже",
  "geminiTimeoutError": "Превышено время ожидания. Проверьте интернет-соединение",
  "geminiApiKeyConfigured": "Ключ API Gemini успешно настроен",
  "geminiApiKeyLabel": "Ключ API Gemini",
  "geminiApiKeyHint": "Введите ваш ключ API Gemini (начинается с AIza)",
  "geminiApiKeyDescription": "Используется для сканирования документов и AI функций",
  "geminiApiKeyInvalid": "Неверный формат ключа. Ключ должен начинаться с 'AIza'"
}
```

**Uzbek (app_uz.arb):**
```json
{
  "geminiApiKeyNotFound": "Gemini API kaliti sozlanmagan",
  "geminiNetworkError": "Tarmoq xatosi yuz berdi. Ulanishni tekshiring",
  "geminiAuthError": "Autentifikatsiya xatosi. Sozlamalarda API kalitini tekshiring",
  "geminiRateLimitError": "So'rovlar limiti oshib ketdi. Bir necha daqiqadan keyin urinib ko'ring",
  "geminiServerError": "Server xatosi yuz berdi. Keyinroq urinib ko'ring",
  "geminiTimeoutError": "So'rov vaqti tugadi. Internet ulanishini tekshiring",
  "geminiApiKeyConfigured": "Gemini API kaliti muvaffaqiyatli sozlandi",
  "geminiApiKeyLabel": "Gemini API kaliti",
  "geminiApiKeyHint": "Gemini API kalitingizni kiriting (AIza bilan boshlanadi)",
  "geminiApiKeyDescription": "Hujjat skanerlash va AI funksiyalari uchun ishlatiladi",
  "geminiApiKeyInvalid": "Kalit formati noto'g'ri. Kalit 'AIza' bilan boshlanishi kerak"
}
```

### Phase 6: Testing & Documentation (2 hours)

#### Step 6.1: Unit Tests

**File:** `test/services/gemini_base_service_test.dart`

**Tasks:**
1. Test API key retrieval
2. Test request handling
3. Test error handling
4. Test fallback logic
5. Mock ApiKeyService and Dio

#### Step 6.2: Integration Tests

**File:** `test/integration/gemini_integration_test.dart`

**Tasks:**
1. Test document scanning flow
2. Test time verification flow
3. Test error scenarios
4. Test localization

#### Step 6.3: Update Documentation

**File:** `GEMINI_SERVICES_README.md`

**Tasks:**
1. Architecture overview
2. Usage examples
3. Configuration guide
4. Troubleshooting
5. API reference

---

## ✅ Acceptance Criteria

### Code Quality
- [ ] All code follows SOLID principles
- [ ] All classes have comprehensive English documentation
- [ ] All public methods have doc comments
- [ ] No code duplication
- [ ] Consistent naming conventions
- [ ] Proper error handling throughout

### Functionality
- [ ] Document scanning works as before
- [ ] Time verification works as before
- [ ] API key management centralized
- [ ] All services use shared Dio instance
- [ ] Fallback logic works correctly
- [ ] Error messages are localized

### Testing
- [ ] Unit tests pass (>80% coverage)
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] No regressions

### Documentation
- [ ] All code documented in English
- [ ] README updated
- [ ] Usage examples provided
- [ ] Troubleshooting guide included

### Localization
- [ ] All strings localized (EN, RU, UZ)
- [ ] Localization files generated
- [ ] UI displays correct language
- [ ] Error messages localized

### Performance
- [ ] No memory leaks
- [ ] Response times acceptable
- [ ] Proper resource cleanup
- [ ] Efficient HTTP connection pooling

---

## 🚀 Deliverables

1. **Refactored Services:**
   - `gemini_base_service.dart` (new)
   - `gemini_document_scanner_service.dart` (refactored)
   - `gemini_time_verification_service.dart` (refactored)
   - `api_key_service.dart` (extended)

2. **Updated UI:**
   - `create_client_page.dart` (updated)
   - `document_scanner_widget.dart` (updated)

3. **Configuration:**
   - `service_locator.dart` (updated)
   - `main.dart` (updated)

4. **Localization:**
   - `app_en.arb` (updated)
   - `app_ru.arb` (updated)
   - `app_uz.arb` (updated)

5. **Tests:**
   - Unit tests for all services
   - Integration tests
   - Test coverage report

6. **Documentation:**
   - `GEMINI_SERVICES_README.md`
   - Inline code documentation
   - Usage examples

---

## 📝 Notes

- Maintain backward compatibility where possible
- Keep existing functionality intact
- Follow Flutter/Dart best practices
- Use meaningful commit messages
- Test thoroughly before deployment
- Document any breaking changes

---

## 🎯 Success Metrics

- **Code Quality:** Reduced duplication by >70%
- **Maintainability:** Single source of truth for API keys
- **Performance:** No degradation in response times
- **Testing:** >80% code coverage
- **Documentation:** 100% of public APIs documented
- **Localization:** 100% of user-facing strings localized

---

**Estimated Total Time:** 11 hours

**Priority:** High

**Complexity:** Medium

**Impact:** High (improves maintainability, scalability, and code quality)
