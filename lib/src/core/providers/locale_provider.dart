import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

/// Provider for managing application locale state
class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('uz'); // Default to Uzbek
  bool _isInitialized = false;

  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;

  /// Initialize the locale provider by loading saved language preference
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferencesService.getInstance();
      final languageCode = prefs.getLanguageCode();
      _locale = Locale(languageCode);
      _isInitialized = true;
      if (kDebugMode) print('LocaleProvider initialized with locale: $_locale');
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error initializing LocaleProvider: $e');
      // Fallback to default locale
      _locale = const Locale('uz');
      _isInitialized = true;
      notifyListeners();
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