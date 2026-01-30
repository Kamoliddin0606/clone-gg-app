import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

/// Provider for managing application locale state.
/// 
/// Language selection priority:
/// 1. User's explicit selection (highest priority)
/// 2. Cached OS locale (if matches current OS)
/// 3. Current OS locale (detected and cached)
/// 
/// This ensures user preference is always respected while also
/// tracking OS language changes when no user preference exists.
class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('uz'); // Default to Uzbek
  bool _isInitialized = false;
  bool _isAutoDetected = false; // True if locale was auto-detected from OS

  /// Supported language codes
  static const List<String> supportedLanguageCodes = ['en', 'ru', 'uz'];

  /// Default language code when no match is found
  static const String defaultLanguageCode = 'uz';

  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;
  
  /// Returns true if current locale was auto-detected from OS
  /// (i.e., user has not manually selected a language)
  bool get isAutoDetected => _isAutoDetected;

  /// Initialize the locale provider with priority-based language selection.
  /// 
  /// Priority order:
  /// 1. User's explicit selection (from settings)
  /// 2. Cached OS locale (if it matches current OS locale)
  /// 3. Current OS locale (detected fresh, then cached)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferencesService.getInstance();
      
      // Step 1: Check for and migrate legacy data
      await _migrateLegacyLanguagePreference(prefs);
      
      // Step 2: Get all relevant language codes
      final userSelectedCode = prefs.getUserSelectedLanguageCode();
      final cachedOsCode = prefs.getCachedOsLanguageCode();
      final currentOsCode = _getSystemLanguageCode();
      
      if (kDebugMode) {
        print('LocaleProvider: User selected=$userSelectedCode, '
              'Cached OS=$cachedOsCode, Current OS=$currentOsCode');
      }
      
      // Step 3: Apply priority logic
      if (userSelectedCode != null && supportedLanguageCodes.contains(userSelectedCode)) {
        // Priority 1: User has explicitly selected a language
        _locale = Locale(userSelectedCode);
        _isAutoDetected = false;
        if (kDebugMode) print('LocaleProvider: Using user selection: $_locale');
      } else if (cachedOsCode != null && cachedOsCode == currentOsCode) {
        // Priority 2: No user selection, cached OS matches current OS
        _locale = Locale(cachedOsCode);
        _isAutoDetected = true;
        if (kDebugMode) print('LocaleProvider: Using cached OS locale: $_locale');
      } else {
        // Priority 3: No user selection, OS changed or first launch
        // Use current OS locale and cache it
        _locale = Locale(currentOsCode);
        _isAutoDetected = true;
        await prefs.setCachedOsLanguageCode(currentOsCode);
        if (kDebugMode) print('LocaleProvider: Detected and cached OS locale: $_locale');
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error initializing LocaleProvider: $e');
      // Fallback to OS locale detection
      _locale = Locale(_getSystemLanguageCode());
      _isAutoDetected = true;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Migrate legacy language_code to new user_selected_language_code.
  /// This handles users upgrading from older app versions.
  Future<void> _migrateLegacyLanguagePreference(SharedPreferencesService prefs) async {
    try {
      final legacyCode = prefs.getLanguageCodeOrNull();
      final userSelectedCode = prefs.getUserSelectedLanguageCode();
      
      // Only migrate if legacy exists and new key doesn't
      if (legacyCode != null && userSelectedCode == null) {
        if (kDebugMode) print('LocaleProvider: Migrating legacy language: $legacyCode');
        await prefs.setUserSelectedLanguageCode(legacyCode);
        await prefs.clearLanguageCode(); // Clear legacy after migration
      }
    } catch (e) {
      if (kDebugMode) print('LocaleProvider: Migration error (non-fatal): $e');
      // Migration errors are non-fatal, continue with normal flow
    }
  }

  /// Get system language code from OS and validate against supported locales.
  /// Returns default language if no supported locale is found.
  String _getSystemLanguageCode() {
    try {
      final platformLocales = PlatformDispatcher.instance.locales;
      
      if (platformLocales.isNotEmpty) {
        for (final platformLocale in platformLocales) {
          final languageCode = platformLocale.languageCode.toLowerCase();
          
          if (supportedLanguageCodes.contains(languageCode)) {
            if (kDebugMode) print('LocaleProvider: Matched OS locale: $languageCode');
            return languageCode;
          }
        }
      }
      
      if (kDebugMode) print('LocaleProvider: No matching OS locale, using default');
      return defaultLanguageCode;
    } catch (e) {
      if (kDebugMode) print('LocaleProvider: Error getting OS locale: $e');
      return defaultLanguageCode;
    }
  }

  /// Set the application locale as user's explicit selection.
  /// This is called when user manually selects a language in settings.
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale && !_isAutoDetected) return;

    try {
      final prefs = await SharedPreferencesService.getInstance();
      await prefs.setUserSelectedLanguageCode(locale.languageCode);
      _locale = locale;
      _isAutoDetected = false; // User made explicit selection
      if (kDebugMode) print('LocaleProvider: User changed locale to: $_locale');
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('LocaleProvider: Error setting locale: $e');
      rethrow;
    }
  }

  /// Set locale by language code (convenience method).
  Future<void> setLocaleByCode(String languageCode) async {
    if (!supportedLanguageCodes.contains(languageCode)) {
      if (kDebugMode) print('LocaleProvider: Unsupported language code: $languageCode');
      return;
    }
    await setLocale(Locale(languageCode));
  }

  /// Reset to OS-detected locale (clears user selection).
  Future<void> resetToSystemLocale() async {
    try {
      final prefs = await SharedPreferencesService.getInstance();
      await prefs.clearUserSelectedLanguageCode();
      
      final osCode = _getSystemLanguageCode();
      await prefs.setCachedOsLanguageCode(osCode);
      _locale = Locale(osCode);
      _isAutoDetected = true;
      
      if (kDebugMode) print('LocaleProvider: Reset to system locale: $_locale');
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('LocaleProvider: Error resetting to system locale: $e');
      rethrow;
    }
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
