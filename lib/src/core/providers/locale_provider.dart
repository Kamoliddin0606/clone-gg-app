import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

/// Provider for managing application locale state
class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('uz'); // Default to Uzbek
  bool _isInitialized = false;

  /// Supported language codes
  static const List<String> supportedLanguageCodes = ['en', 'ru', 'uz'];

  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;

  /// Initialize the locale provider by loading saved language preference
  /// If no preference is saved, use OS locale
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferencesService.getInstance();
      final savedLanguageCode = prefs.getLanguageCodeOrNull();
      
      if (savedLanguageCode != null) {
        // User has explicitly set a language preference
        _locale = Locale(savedLanguageCode);
        if (kDebugMode) print('LocaleProvider initialized with saved locale: $_locale');
      } else {
        // No saved preference, use OS locale
        _locale = _getSystemLocale();
        if (kDebugMode) print('LocaleProvider initialized with OS locale: $_locale');
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error initializing LocaleProvider: $e');
      // Fallback to OS locale or default
      _locale = _getSystemLocale();
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Get system locale from OS and match with supported locales
  Locale _getSystemLocale() {
    try {
      // Get system locales from platform dispatcher
      final platformLocales = PlatformDispatcher.instance.locales;
      
      if (platformLocales.isNotEmpty) {
        // Try to find a matching supported locale
        for (final platformLocale in platformLocales) {
          final languageCode = platformLocale.languageCode.toLowerCase();
          
          // Check if this language is supported
          if (supportedLanguageCodes.contains(languageCode)) {
            if (kDebugMode) print('Matched OS locale: $languageCode');
            return Locale(languageCode);
          }
        }
      }
      
      // No match found, use default
      if (kDebugMode) print('No matching OS locale found, using default: uz');
      return const Locale('uz');
    } catch (e) {
      if (kDebugMode) print('Error getting system locale: $e');
      return const Locale('uz');
    }
  }

  /// Set the application locale
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    try {
      final prefs = await SharedPreferencesService.getInstance();
      await prefs.setLanguageCode(locale.languageCode);
      _locale = locale;
      if (kDebugMode) print('Locale changed to: $_locale');
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error setting locale: $e');
      rethrow;
    }
  }

  /// Set locale by language code
  Future<void> setLocaleByCode(String languageCode) async {
    final newLocale = Locale(languageCode);
    await setLocale(newLocale);
  }

  /// Get current language code
  String get currentLanguageCode => _locale.languageCode;

  /// Check if current locale is Uzbek
  bool get isUzbek => _locale.languageCode == 'uz';

  /// Check if current locale is Russian
  bool get isRussian => _locale.languageCode == 'ru';

  /// Check if current locale is English
  bool get isEnglish => _locale.languageCode == 'en';
}