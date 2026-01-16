import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

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
  static final ApiKeyService _instance = ApiKeyService._internal();
  static ApiKeyService get instance => _instance;

  ApiKeyService._internal();

  late final SharedPreferencesService _prefs;

  /// Initialize the service with SharedPreferences
  Future<void> initialize(SharedPreferencesService prefs) async {
    _prefs = prefs;
    if (kDebugMode) {
      print('ApiKeyService initialized');
    }
  }

  /// API key types for different services
  static const String googleMapsApiKey = 'google_maps_api_key';
  static const String yandexMapsApiKey = 'yandex_maps_api_key';
  static const String openStreetMapsApiKey = 'openstreetmap_api_key';
  static const String serverApiKey = 'server_api_key';
  
  /// API key type for Google Gemini AI services
  /// Used for document scanning, time verification, and other AI features
  static const String geminiApiKey = 'gemini_api_key';

  /// Store API key for a specific service
  Future<bool> storeApiKey(String keyType, String apiKey) async {
    try {
      if (apiKey.isEmpty) {
        throw ArgumentError('API key cannot be empty');
      }

      await _prefs.preferences.setString(keyType, apiKey);

      if (kDebugMode) {
        print('API key stored successfully for: $keyType');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error storing API key for $keyType: $e');
      }
      return false;
    }
  }

  /// Retrieve API key for a specific service
  Future<String?> getApiKey(String keyType) async {
    try {
      final apiKey = _prefs.preferences.getString(keyType);

      if (kDebugMode && apiKey != null) {
        // API key retrieved for keyType
      }

      return apiKey;
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving API key for $keyType: $e');
      }
      return null;
    }
  }

  /// Check if API key exists for a specific service
  Future<bool> hasApiKey(String keyType) async {
    try {
      final apiKey = await getApiKey(keyType);
      if (kDebugMode) print('Checking API key existence for $keyType: $apiKey');
      return apiKey != null && apiKey.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking API key existence for $keyType: $e');
      }
      return false;
    }
  }

  /// Validate API key format for a specific service
  bool validateApiKeyFormat(String keyType, String apiKey) {
    if (apiKey.isEmpty) return false;

    switch (keyType) {
      case googleMapsApiKey:
      case geminiApiKey:
        // Google API keys (Maps and Gemini) start with 'AIza' prefix
        // and are typically 35-45 characters long
        return apiKey.startsWith('AIza') && apiKey.length >= 35 && apiKey.length <= 45;

      case yandexMapsApiKey:
        // Yandex API keys are typically UUID-like or have specific format
        return apiKey.length >= 32 && RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(apiKey);

      case openStreetMapsApiKey:
        // OpenStreetMap typically doesn't require API keys, but if present, basic validation
        return apiKey.length >= 10;

      case serverApiKey:
        // Server API keys can vary, basic non-empty check
        return apiKey.length >= 8;

      default:
        return true; // Allow custom keys
    }
  }

  /// Remove API key for a specific service
  Future<bool> removeApiKey(String keyType) async {
    try {
      final result = await _prefs.preferences.remove(keyType);

      if (kDebugMode) {
        print('API key removed for: $keyType, success: $result');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error removing API key for $keyType: $e');
      }
      return false;
    }
  }

  /// Get all stored API keys (for debugging/admin purposes)
  Future<Map<String, String>> getAllApiKeys() async {
    try {
      final keys = <String, String>{};

      for (final keyType in [
        googleMapsApiKey, 
        yandexMapsApiKey, 
        openStreetMapsApiKey, 
        serverApiKey,
        geminiApiKey,
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

  /// Clear all API keys
  Future<bool> clearAllApiKeys() async {
    try {
      bool allCleared = true;

      for (final keyType in [
        googleMapsApiKey, 
        yandexMapsApiKey, 
        openStreetMapsApiKey, 
        serverApiKey,
        geminiApiKey,
      ]) {
        final result = await removeApiKey(keyType);
        if (!result) {
          allCleared = false;
        }
      }

      if (kDebugMode) {
        print('All API keys cleared, success: $allCleared');
      }

      return allCleared;
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing all API keys: $e');
      }
      return false;
    }
  }

  /// Store and validate API key in one operation
  Future<ApiKeyResult> storeAndValidateApiKey(String keyType, String apiKey) async {
    try {
      // First validate format
      if (!validateApiKeyFormat(keyType, apiKey)) {
        return ApiKeyResult.failure('Invalid API key format for $keyType');
      }

      // Store the key
      final stored = await storeApiKey(keyType, apiKey);
      if (!stored) {
        return ApiKeyResult.failure('Failed to store API key for $keyType');
      }

      return ApiKeyResult.success(apiKey);
    } catch (e) {
      return ApiKeyResult.failure('Error storing API key: $e');
    }
  }

  /// Get API key with fallback options
  Future<String?> getApiKeyWithFallback(String keyType, {String? fallbackKey}) async {
    try {
      final storedKey = await getApiKey(keyType);
      return storedKey ?? fallbackKey;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting API key with fallback for $keyType: $e');
      }
      return fallbackKey;
    }
  }
}

/// Result class for API key operations
class ApiKeyResult {
  final bool success;
  final String? apiKey;
  final String? errorMessage;

  ApiKeyResult._(this.success, this.apiKey, this.errorMessage);

  factory ApiKeyResult.success(String apiKey) {
    return ApiKeyResult._(true, apiKey, null);
  }

  factory ApiKeyResult.failure(String errorMessage) {
    return ApiKeyResult._(false, null, errorMessage);
  }
}