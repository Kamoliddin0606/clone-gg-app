import 'package:flutter/services.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

class MapTokenPlatformService {
  static const MethodChannel _channel = MethodChannel('com.gloria.map_tokens');

  static const String _setYandexToken = 'setYandexToken';
  static const String _setGoogleToken = 'setGoogleToken';
  static const String _initializeMaps = 'initializeMaps';

  /// Initialize map tokens for both platforms
  static Future<bool> initializeMapTokens() async {
    try {
      final prefs = await SharedPreferencesService.getInstance();
      final yandexToken = prefs.getYandexMapsToken();
      final googleToken = prefs.getGoogleMapsToken();

      // Set tokens for native platforms
      if (yandexToken != null && yandexToken.isNotEmpty) {
        await _channel.invokeMethod(_setYandexToken, {'token': yandexToken});
      }

      if (googleToken != null && googleToken.isNotEmpty) {
        await _channel.invokeMethod(_setGoogleToken, {'token': googleToken});
      }

      // Initialize map services with tokens
      final result = await _channel.invokeMethod(_initializeMaps);

      return result == true;
    } catch (e) {
      print('Error initializing map tokens: $e');
      return false;
    }
  }

  /// Update Yandex token dynamically
  static Future<bool> updateYandexToken(String token) async {
    try {
      await _channel.invokeMethod(_setYandexToken, {'token': token});
      return true;
    } catch (e) {
      print('Error updating Yandex token: $e');
      return false;
    }
  }

  /// Update Google token dynamically
  static Future<bool> updateGoogleToken(String token) async {
    try {
      await _channel.invokeMethod(_setGoogleToken, {'token': token});
      return true;
    } catch (e) {
      print('Error updating Google token: $e');
      return false;
    }
  }
}