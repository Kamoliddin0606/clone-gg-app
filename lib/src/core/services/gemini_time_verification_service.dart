import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_key_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/gemini_base_service.dart';

/// Service for verifying real time using Google Gemini AI
/// 
/// This service uses Gemini's capabilities to verify the actual current time
/// based on device location coordinates. This prevents time manipulation attacks
/// by getting verified time from an external trusted source.
/// 
/// Features:
/// - Location-based time verification
/// - Retry logic with configurable attempts
/// - Configurable Gemini model selection
/// - Unified API key management via ApiKeyService
/// - Consistent error handling via GeminiBaseService
/// 
/// This service extends [GeminiBaseService] for unified API key management
/// and consistent error handling across all Gemini services.
/// 
/// Usage:
/// ```dart
/// final service = sl<GeminiTimeVerificationService>();
/// final verifiedTime = await service.verifyRealTime();
/// print('Verified time: $verifiedTime');
/// ```
class GeminiTimeVerificationService extends GeminiBaseService {
  /// Default Gemini model for time verification
  /// Uses gemini-2.0-flash for fast response times
  static const String defaultModel = 'gemini-2.0-flash';
  
  /// Alternative models for fallback
  /// Models are tried in order until one succeeds
  static const List<String> fallbackModels = [
    'gemini-2.0-flash',
    'gemini-2.0-flash-exp',
    'gemini-1.5-pro',
  ];
  
  /// Maximum retry attempts for time verification
  static const int defaultMaxRetries = 3;
  
  /// Delay between retry attempts
  static const Duration defaultRetryDelay = Duration(seconds: 2);
  
  /// Timeout for time verification requests
  static const Duration verificationTimeout = Duration(seconds: 15);
  
  /// Constructor for GeminiTimeVerificationService
  /// 
  /// @param apiKeyService Service for managing API keys
  /// @param dio HTTP client for making requests
  GeminiTimeVerificationService({
    required ApiKeyService apiKeyService,
    required Dio dio,
  }) : super(apiKeyService: apiKeyService, dio: dio);

  /// Get device location coordinates
  /// 
  /// Returns Position object with latitude and longitude.
  /// Handles permission checks and service availability.
  /// 
  /// @returns Device position with coordinates
  /// @throws GeminiException if location cannot be obtained
  Future<Position> _getDeviceLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw GeminiException(
          code: GeminiErrorCode.invalidRequest,
          message: 'Location services are disabled. Please enable GPS.',
        );
      }
      
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw GeminiException(
            code: GeminiErrorCode.invalidRequest,
            message: 'Location permissions are denied.',
          );
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw GeminiException(
          code: GeminiErrorCode.invalidRequest,
          message: 'Location permissions are permanently denied. Please enable in settings.',
        );
      }
      
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      
      if (kDebugMode) {
        debugPrint('[GeminiTimeVerification] Location: ${position.latitude}, ${position.longitude}');
      }
      
      return position;
    } on GeminiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GeminiTimeVerification] Error getting location: $e');
      }
      throw GeminiException(
        code: GeminiErrorCode.unknownError,
        message: 'Failed to get device location: $e',
      );
    }
  }
  
  /// Verify real time using Gemini AI
  /// 
  /// Gets device location and sends it to Gemini to get the actual
  /// current time for that location. This prevents time manipulation.
  /// 
  /// @param model Optional Gemini model to use (defaults to gemini-1.5-flash)
  /// @returns Verified current DateTime
  /// @throws GeminiException if verification fails
  Future<DateTime> verifyRealTime({String? model}) async {
    try {
      // Get device location
      final position = await _getDeviceLocation();
      
      // Get verified time from Gemini
      final verifiedTime = await _getTimeFromGemini(
        latitude: position.latitude,
        longitude: position.longitude,
        model: model ?? defaultModel,
      );
      
      if (kDebugMode) {
        debugPrint('[GeminiTimeVerification] Verified time: $verifiedTime');
      }
      
      return verifiedTime;
    } on GeminiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GeminiTimeVerification] Error verifying real time: $e');
      }
      throw GeminiException(
        code: GeminiErrorCode.unknownError,
        message: 'Time verification failed: $e',
      );
    }
  }
  
  /// Get time from Gemini AI based on coordinates
  /// 
  /// @param latitude Device latitude
  /// @param longitude Device longitude
  /// @param model Gemini model to use
  /// @returns Verified DateTime
  /// @throws GeminiException if request fails
  Future<DateTime> _getTimeFromGemini({
    required double latitude,
    required double longitude,
    required String model,
  }) async {
    // Construct prompt for Gemini
    final prompt = '''
Based on the geographic coordinates (latitude: $latitude, longitude: $longitude), 
please provide the current accurate date and time for this location.

Respond ONLY with the date and time in ISO 8601 format (YYYY-MM-DDTHH:MM:SS).
Do not include any additional text, explanations, or formatting.

Example format: 2026-01-16T18:30:45
''';
    
    // Build request body
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
        'maxOutputTokens': 100,
      }
    };
    
    try {
      // Use base service to make request
      final response = await makeGeminiRequest(
        model: model,
        body: requestBody,
        timeout: verificationTimeout,
      );
      
      // Parse response using base service helper
      final text = extractTextFromResponse(response);
      
      // Extract and parse datetime from response
      final cleanedText = text.trim();
      
      if (kDebugMode) {
        debugPrint('[GeminiTimeVerification] Gemini response: $cleanedText');
      }
      
      // Try to parse the datetime
      final dateTime = _parseDateTime(cleanedText);
      
      if (kDebugMode) {
        debugPrint('[GeminiTimeVerification] Parsed datetime: $dateTime');
      }
      
      return dateTime;
    } on GeminiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GeminiTimeVerification] Error getting time from Gemini: $e');
      }
      throw GeminiException(
        code: GeminiErrorCode.parseError,
        message: 'Failed to parse time from Gemini response: $e',
      );
    }
  }
  
  /// Parse datetime string from Gemini response
  /// 
  /// Handles various formats and cleans the response.
  /// 
  /// @param text Raw text from Gemini
  /// @returns Parsed DateTime
  /// @throws FormatException if parsing fails
  DateTime _parseDateTime(String text) {
    // Clean the text - remove any extra whitespace or characters
    String cleaned = text.trim();
    
    // Remove any markdown or code formatting
    if (cleaned.startsWith('`')) {
      cleaned = cleaned.replaceAll('`', '');
    }
    
    // Try direct parsing first
    try {
      return DateTime.parse(cleaned);
    } catch (_) {
      // If direct parsing fails, try to extract datetime pattern
      final regex = RegExp(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}');
      final match = regex.firstMatch(cleaned);
      
      if (match != null) {
        return DateTime.parse(match.group(0)!);
      }
      
      // Try date only format
      final dateRegex = RegExp(r'\d{4}-\d{2}-\d{2}');
      final dateMatch = dateRegex.firstMatch(cleaned);
      
      if (dateMatch != null) {
        return DateTime.parse(dateMatch.group(0)!);
      }
      
      throw FormatException('Unable to parse datetime: $cleaned');
    }
  }
  
  /// Verify time with retry logic
  /// 
  /// Attempts to verify time multiple times before giving up.
  /// Useful for handling transient network issues.
  /// 
  /// @param maxRetries Maximum number of retry attempts
  /// @param retryDelay Delay between retries
  /// @param model Optional Gemini model to use
  /// @returns Verified DateTime
  /// @throws GeminiException after all retries fail
  Future<DateTime> verifyRealTimeWithRetry({
    int maxRetries = defaultMaxRetries,
    Duration retryDelay = defaultRetryDelay,
    String? model,
  }) async {
    int attempts = 0;
    GeminiException? lastException;
    
    while (attempts < maxRetries) {
      try {
        return await verifyRealTime(model: model);
      } on GeminiException catch (e) {
        attempts++;
        lastException = e;
        
        if (kDebugMode) {
          debugPrint('[GeminiTimeVerification] Attempt $attempts failed: ${e.message}');
        }
        
        // Don't retry for auth errors or API key issues
        if (e.isAuthError || e.isApiKeyError) {
          rethrow;
        }
        
        if (attempts < maxRetries) {
          if (kDebugMode) {
            debugPrint('[GeminiTimeVerification] Retrying in ${retryDelay.inSeconds}s...');
          }
          await Future.delayed(retryDelay);
        }
      } catch (e) {
        attempts++;
        lastException = GeminiException(
          code: GeminiErrorCode.unknownError,
          message: e.toString(),
        );
        
        if (kDebugMode) {
          debugPrint('[GeminiTimeVerification] Attempt $attempts failed: $e');
        }
        
        if (attempts < maxRetries) {
          await Future.delayed(retryDelay);
        }
      }
    }
    
    if (kDebugMode) {
      debugPrint('[GeminiTimeVerification] All $maxRetries retry attempts failed');
    }
    
    throw lastException ?? GeminiException(
      code: GeminiErrorCode.allModelsFailed,
      message: 'Failed to verify time after $maxRetries attempts',
    );
  }
  
  /// Verify time with model fallback
  /// 
  /// Tries multiple models until one succeeds.
  /// 
  /// @returns Verified DateTime
  /// @throws GeminiException if all models fail
  Future<DateTime> verifyRealTimeWithFallback() async {
    final errors = <String>[];
    
    for (int i = 0; i < fallbackModels.length; i++) {
      final model = fallbackModels[i];
      
      if (kDebugMode) {
        debugPrint('[GeminiTimeVerification] Trying model $model (${i + 1}/${fallbackModels.length})');
      }
      
      try {
        return await verifyRealTime(model: model);
      } on GeminiException catch (e) {
        errors.add('$model: ${e.message}');
        
        if (kDebugMode) {
          debugPrint('[GeminiTimeVerification] ❌ $model failed: ${e.message}');
        }
        
        // Don't try other models for auth errors
        if (e.isAuthError || e.isApiKeyError) {
          rethrow;
        }
      }
    }
    
    throw GeminiException(
      code: GeminiErrorCode.allModelsFailed,
      message: 'All models failed: ${errors.join("; ")}',
    );
  }
  
  /// Check if Gemini service is available
  /// 
  /// Attempts to reach the Gemini API to verify connectivity.
  /// 
  /// @returns true if service can be reached, false otherwise
  Future<bool> isServiceAvailable() async {
    try {
      // Try to get API key - if this fails, service is not available
      await getApiKey();
      
      // Make a simple request to check connectivity
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': 'Hello'}
            ]
          }
        ],
        'generationConfig': {
          'maxOutputTokens': 10,
        }
      };
      
      await makeGeminiRequest(
        model: defaultModel,
        body: requestBody,
        timeout: const Duration(seconds: 5),
      );
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GeminiTimeVerification] Service availability check failed: $e');
      }
      return false;
    }
  }
}
