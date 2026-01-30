import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  late final SharedPreferences _preferences;
  static const String _usernameKey = 'saved_username';
  static const String _passwordKey = 'saved_password';
  static const String _rememberMeKey = 'remember_me';
  static const String _userCodeKey = 'user_code';
  static const String _userNameKey = 'user_name';
  static const String _warehouseCodeKey = 'warehouse_code';
  static const String _codeProjectKey = 'code_project';
  static const String _telegramIDKey = 'telegram_id';
  static const String _chatIDKey = 'chat_id';
  static const String _topicIDKey = 'topic_id';

  static const String _serverNameKey = 'selected_server_env';
  static const String _baseUrlKey = 'selected_server_base_url';
  static const String _isOfflineModeKey = 'is_offline_mode';
  static const String _languageCodeKey = 'language_code'; // Legacy key, kept for migration
  static const String _userSelectedLanguageCodeKey = 'user_selected_language_code';
  static const String _cachedOsLanguageCodeKey = 'cached_os_language_code';
  static const String _bgSyncEnabledKey = 'bg_sync_enabled';
  static const String _bgSyncIntervalKey = 'bg_sync_interval_hours';
  static const String _bgSyncCustomMinutesKey = 'bg_sync_custom_minutes';
  static const String _syncNeededKey = 'sync_needed';
  static const String _isFirstTimeSyncKey = 'is_first_time_sync';
  static const String _timeLimitKey = 'time_limit';

  static SharedPreferencesService? _instance;
  bool _isInitialized = false;

  SharedPreferencesService._();

  Future<void> init() async {
    if (!_isInitialized) {
      _preferences = await SharedPreferences.getInstance();
      _isInitialized = true;
    }
  }

  static Future<SharedPreferencesService> getInstance() async {
    if (_instance == null) {
      _instance = SharedPreferencesService._();
      await _instance!.init();
    }
    return _instance!;
  }

  // Save login credentials
  Future<void> saveCredentials(String username, String password, bool rememberMe ) async {
    await _preferences.setString(_usernameKey, username);
    await _preferences.setString(_passwordKey, password);
    await _preferences.setBool(_rememberMeKey, rememberMe);
  }

  // Save user data after successful login
  Future<void> saveUserData({
    required String userCode,
    required String userName,
    required String warehouseCode,
    required String codeProject,
    required String telegramID,
    required String chatID,
    required String topicID,
  }) async {
    await _preferences.setString(_userCodeKey, userCode);
    await _preferences.setString(_userNameKey, userName);
    await _preferences.setString(_warehouseCodeKey, warehouseCode);
    await _preferences.setString(_codeProjectKey, codeProject);
    await _preferences.setString(_telegramIDKey, telegramID);
    await _preferences.setString(_chatIDKey, chatID);
    await _preferences.setString(_topicIDKey, topicID);
    // Log for debugging
    if (kDebugMode) print('Saved TelegramID: $telegramID, ChatID: $chatID, TopicID: $topicID');
  }

  // Get saved username
  String? getSavedUsername() {
    return _preferences.getString(_usernameKey);
  }

  // Get saved password
  String? getSavedPassword() {
    return _preferences.getString(_passwordKey);
  }

  // Check if remember me is enabled
  bool isRememberMeEnabled() {
    return _preferences.getBool(_rememberMeKey) ?? false;
  }

  // Clear saved credentials
  Future<void> clearCredentials() async {
    await _preferences.remove(_usernameKey);
    await _preferences.remove(_passwordKey);
    await _preferences.setBool(_rememberMeKey, false);
  }

  // Set remember me preference
  Future<void> setRememberMe(bool value) async {
    await _preferences.setBool(_rememberMeKey, value);
  }

  // Get user code
  String? getUserCode() {
    if (kDebugMode) {
      print('Getting user code from SharedPreferences');
      print('User code key: $_userCodeKey');
    }
    return _preferences.getString(_userCodeKey);
  }

  // Get user name
  String? getUserName() {
    return _preferences.getString(_userNameKey);
  }

  // Get warehouse code
  String? getWarehouseCode() {
    return _preferences.getString(_warehouseCodeKey);
  }

  // Get code project
  String? getCodeProject() {
    return _preferences.getString(_codeProjectKey);
  }

  // Get telegram ID
  String? getTelegramID() {
    final id = _preferences.getString(_telegramIDKey);
    if (kDebugMode) print('Retrieved TelegramID: $id');
    return id;
  }

  // Get chat ID
  String? getChatID() {
    final id = _preferences.getString(_chatIDKey);
    if (kDebugMode) print('Retrieved ChatID: $id');
    return id;
  }

  // Get topic ID
  String? getTopicID() {
    final id = _preferences.getString(_topicIDKey);
    if (kDebugMode) print('Retrieved TopicID: $id');
    return id;
  }

  // Get SharedPreferences instance (for other services)
  SharedPreferences get preferences => _preferences;

  // Get password (for API calls)
  String? getPassword() {
    return _preferences.getString(_passwordKey);
  }

  // Clear all user data
  Future<void> clearUserData() async {
    await _preferences.remove(_userCodeKey);
    await _preferences.remove(_userNameKey);
    await _preferences.remove(_warehouseCodeKey);
    await _preferences.remove(_codeProjectKey);
    await _preferences.remove(_telegramIDKey);
    await _preferences.remove(_chatIDKey);
    await _preferences.remove(_topicIDKey);
  }

  Future<bool> setServerName(String name) async =>
      _preferences.setString(_serverNameKey, name);

  String? getServerName() {
    final serverName = _preferences.getString(_serverNameKey);
    if (kDebugMode) print('Retrieved server name: $serverName');
    return serverName;
  }

  Future<bool> clearServerName() async =>
      _preferences.remove(_serverNameKey);

  Future<bool> setBaseUrl(String url) async =>
      _preferences.setString(_baseUrlKey, url);

  String? getBaseUrl() =>
      _preferences.getString(_baseUrlKey);

  Future<bool> clearBaseUrl() async =>
      _preferences.remove(_baseUrlKey);

  // Offline mode management
  Future<void> setOfflineMode(bool isOffline) async {
    await _preferences.setBool(_isOfflineModeKey, isOffline);
  }

  bool isOfflineMode() {
    return _preferences.getBool(_isOfflineModeKey) ?? false;
  }

  Future<void> clearOfflineMode() async {
    await _preferences.remove(_isOfflineModeKey);
  }

  // ============================================================================
  // Language Management
  // ============================================================================
  // 
  // The language system uses two separate keys:
  // 1. _userSelectedLanguageCodeKey - User's explicit language choice (highest priority)
  // 2. _cachedOsLanguageCodeKey - Cached OS locale for change detection
  //
  // Priority: User Selection > Cached OS (if matches current) > Current OS
  // ============================================================================

  /// Sets user's explicit language selection.
  /// This has the highest priority and overrides OS locale detection.
  Future<void> setUserSelectedLanguageCode(String languageCode) async {
    try {
      await _preferences.setString(_userSelectedLanguageCodeKey, languageCode);
      if (kDebugMode) print('User selected language saved: $languageCode');
    } catch (e) {
      if (kDebugMode) print('Error saving user selected language: $e');
      rethrow;
    }
  }

  /// Gets user's explicit language selection.
  /// Returns null if user has not manually selected a language.
  String? getUserSelectedLanguageCode() {
    try {
      final code = _preferences.getString(_userSelectedLanguageCodeKey);
      if (kDebugMode) print('User selected language: $code');
      return code;
    } catch (e) {
      if (kDebugMode) print('Error getting user selected language: $e');
      return null;
    }
  }

  /// Checks if user has explicitly selected a language.
  bool hasUserSelectedLanguage() {
    return _preferences.containsKey(_userSelectedLanguageCodeKey);
  }

  /// Clears user's language selection.
  /// After this, app will fall back to OS locale detection.
  Future<void> clearUserSelectedLanguageCode() async {
    try {
      await _preferences.remove(_userSelectedLanguageCodeKey);
      if (kDebugMode) print('User selected language cleared');
    } catch (e) {
      if (kDebugMode) print('Error clearing user selected language: $e');
      rethrow;
    }
  }

  /// Sets cached OS language code for change detection.
  /// Called when app starts and detects OS locale.
  Future<void> setCachedOsLanguageCode(String languageCode) async {
    try {
      await _preferences.setString(_cachedOsLanguageCodeKey, languageCode);
      if (kDebugMode) print('Cached OS language saved: $languageCode');
    } catch (e) {
      if (kDebugMode) print('Error saving cached OS language: $e');
      rethrow;
    }
  }

  /// Gets previously cached OS language code.
  /// Used to detect if OS language has changed since last app launch.
  String? getCachedOsLanguageCode() {
    try {
      final code = _preferences.getString(_cachedOsLanguageCodeKey);
      if (kDebugMode) print('Cached OS language: $code');
      return code;
    } catch (e) {
      if (kDebugMode) print('Error getting cached OS language: $e');
      return null;
    }
  }

  /// Clears cached OS language code.
  Future<void> clearCachedOsLanguageCode() async {
    try {
      await _preferences.remove(_cachedOsLanguageCodeKey);
      if (kDebugMode) print('Cached OS language cleared');
    } catch (e) {
      if (kDebugMode) print('Error clearing cached OS language: $e');
      rethrow;
    }
  }

  // Legacy language methods - kept for backward compatibility and migration
  // TODO: Remove these after migration period

  /// [LEGACY] Sets language code - use setUserSelectedLanguageCode instead.
  @Deprecated('Use setUserSelectedLanguageCode for user selections')
  Future<void> setLanguageCode(String languageCode) async {
    try {
      await _preferences.setString(_languageCodeKey, languageCode);
      if (kDebugMode) print('Legacy language code saved: $languageCode');
    } catch (e) {
      if (kDebugMode) print('Error saving legacy language code: $e');
      rethrow;
    }
  }

  /// [LEGACY] Gets language code with default fallback.
  @Deprecated('Use getUserSelectedLanguageCode or getCachedOsLanguageCode')
  String getLanguageCode() {
    try {
      final languageCode = _preferences.getString(_languageCodeKey) ?? 'uz';
      if (kDebugMode) print('Legacy language code: $languageCode');
      return languageCode;
    } catch (e) {
      if (kDebugMode) print('Error getting legacy language code: $e');
      return 'uz';
    }
  }

  /// [LEGACY] Gets language code or null - used for migration detection.
  String? getLanguageCodeOrNull() {
    try {
      final languageCode = _preferences.getString(_languageCodeKey);
      if (kDebugMode) print('Legacy language code or null: $languageCode');
      return languageCode;
    } catch (e) {
      if (kDebugMode) print('Error getting legacy language code: $e');
      return null;
    }
  }

  /// [LEGACY] Clears legacy language code after migration.
  Future<void> clearLanguageCode() async {
    try {
      await _preferences.remove(_languageCodeKey);
      if (kDebugMode) print('Legacy language code cleared');
    } catch (e) {
      if (kDebugMode) print('Error clearing legacy language code: $e');
      rethrow;
    }
  }

  // Report sent to Telegram (date-aware)
  Future<void> setReportSentToTelegram(bool value) async {
    await _preferences.setBool('isReportSentToTelegram', value);
    if (value) {
      // Set today's date when marking as sent
      final today = DateTime.now().toIso8601String().split('T')[0]; // yyyy-MM-dd format
      await _preferences.setString('sentTelegramReportDate', today);
    } else {
      // Clear the date when resetting
      await _preferences.remove('sentTelegramReportDate');
    }
  }

  bool isReportSentToTelegram() {
    final savedDate = _preferences.getString('sentTelegramReportDate');
    final today = DateTime.now().toIso8601String().split('T')[0]; // yyyy-MM-dd format

    // If no date saved or date doesn't match today, reset to false
    if (savedDate == null || savedDate != today) {
      // Reset the flag since it's a new day
      _preferences.setBool('isReportSentToTelegram', false);
      _preferences.remove('sentTelegramReportDate');
      return false;
    }

    // Return the current value
    return _preferences.getBool('isReportSentToTelegram') ?? false;
  }

  /// Save map tokens (Yandex and Google) to shared preferences
  Future<bool> saveMapTokens({
    required String yandexToken,
    required String googleToken,
  }) async {
    try {
      await _preferences.setString('yandex_maps_api_key', yandexToken);
      await _preferences.setString('google_maps_api_key', googleToken);
      await _preferences.setString('map_tokens_last_updated', DateTime.now().toIso8601String());

      if (kDebugMode) print('Map tokens saved successfully - Yandex: ${yandexToken.isNotEmpty ? 'Present' : 'Empty'}, Google: ${googleToken.isNotEmpty ? 'Present' : 'Empty'}');

      return true;
    } catch (e) {
      if (kDebugMode) print('Error saving map tokens: $e');
      return false;
    }
  }

  /// Get map tokens from shared preferences
  Map<String, String> getMapTokens() {
    try {
      final yandexToken = _preferences.getString('yandex_maps_api_key') ?? '';
      final googleToken = _preferences.getString('google_maps_api_key') ?? '';

      return {
        'yandexToken': yandexToken,
        'googleToken': googleToken,
      };
    } catch (e) {
      if (kDebugMode) print('Error getting map tokens: $e');
      return {
        'yandexToken': '',
        'googleToken': '',
      };
    }
  }

  /// Get Yandex maps token
  String? getYandexMapsToken() {
    return _preferences.getString('yandex_maps_api_key');
  }

  /// Get Google maps token
  String? getGoogleMapsToken() {
    return _preferences.getString('google_maps_api_key');
  }

  /// Check if map tokens are valid (not empty and recently updated)
  bool hasValidMapTokens() {
    try {
      final yandexToken = getYandexMapsToken();
      final googleToken = getGoogleMapsToken();

      // Check if at least one token is present
      final hasTokens = (yandexToken != null && yandexToken.isNotEmpty) ||
                       (googleToken != null && googleToken.isNotEmpty);

      if (!hasTokens) return false;

      // Check if tokens were updated recently (within 30 days)
      final lastUpdatedStr = _preferences.getString('map_tokens_last_updated');
      if (lastUpdatedStr == null) return false;

      final lastUpdated = DateTime.parse(lastUpdatedStr);
      final now = DateTime.now();
      final difference = now.difference(lastUpdated);

      return difference.inDays <= 30;
    } catch (e) {
      if (kDebugMode) print('Error checking map token validity: $e');
      return false;
    }
  }

  /// Get last time map tokens were updated
  DateTime? getMapTokensLastUpdated() {
    try {
      final lastUpdatedStr = _preferences.getString('map_tokens_last_updated');
      return lastUpdatedStr != null ? DateTime.parse(lastUpdatedStr) : null;
    } catch (e) {
      if (kDebugMode) print('Error getting map tokens last updated: $e');
      return null;
    }
  }

  /// Clear map tokens
  Future<bool> clearMapTokens() async {
    try {
      await _preferences.remove('yandex_maps_api_key');
      await _preferences.remove('google_maps_api_key');
      await _preferences.remove('map_tokens_last_updated');

      if (kDebugMode) print('Map tokens cleared successfully');

      return true;
    } catch (e) {
      if (kDebugMode) print('Error clearing map tokens: $e');
      return false;
    }
  }

  // Background Sync Settings
  Future<void> setBgSyncEnabled(bool enabled) async {
    await _preferences.setBool(_bgSyncEnabledKey, enabled);
  }

  bool isBgSyncEnabled() {
    return _preferences.getBool(_bgSyncEnabledKey) ?? false;
  }

  Future<void> setBgSyncInterval(int hours) async {
    await _preferences.setInt(_bgSyncIntervalKey, hours);
  }

  int getBgSyncInterval() {
    return _preferences.getInt(_bgSyncIntervalKey) ?? 6; // Default 6 hours
  }

  Future<void> setBgSyncCustomMinutes(int? minutes) async {
    if (minutes == null) {
      await _preferences.remove(_bgSyncCustomMinutesKey);
    } else {
      await _preferences.setInt(_bgSyncCustomMinutesKey, minutes);
    }
  }

  int? getBgSyncCustomMinutes() {
    return _preferences.getInt(_bgSyncCustomMinutesKey);
  }

  // Sync needed flag methods
  Future<void> setSyncNeeded(bool value) async {
    await _preferences.setBool(_syncNeededKey, value);
  }

  bool isSyncNeeded() {
    return _preferences.getBool(_syncNeededKey) ?? false;
  }

  Future<void> setIsFirstTimeSync(bool value) async {
    await _preferences.setBool(_isFirstTimeSyncKey, value);
  }

  bool isFirstTimeSync() {
    return _preferences.getBool(_isFirstTimeSyncKey) ?? false;
  }

  // Time limit management for server time verification
  
  /// Save time limit to preferences
  /// Time limit is stored in ISO 8601 format for consistency
  Future<void> setTimeLimit(DateTime limit) async {
    try {
      await _preferences.setString(_timeLimitKey, limit.toIso8601String());
      if (kDebugMode) {
        print('Time limit saved: ${limit.toIso8601String()}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving time limit: $e');
      }
      rethrow;
    }
  }

  /// Get time limit from preferences
  /// Returns null if no time limit is stored
  DateTime? getTimeLimit() {
    try {
      final limitStr = _preferences.getString(_timeLimitKey);
      if (limitStr == null) {
        if (kDebugMode) {
          print('No time limit found in preferences');
        }
        return null;
      }
      final limit = DateTime.parse(limitStr);
      if (kDebugMode) {
        print('Retrieved time limit: ${limit.toIso8601String()}');
      }
      return limit;
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving time limit: $e');
      }
      return null;
    }
  }

  /// Clear time limit from preferences
  Future<void> clearTimeLimit() async {
    try {
      await _preferences.remove(_timeLimitKey);
      if (kDebugMode) {
        print('Time limit cleared from preferences');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing time limit: $e');
      }
      rethrow;
    }
  }

  /// Check if time limit exists in preferences
  bool hasTimeLimit() {
    final hasLimit = _preferences.containsKey(_timeLimitKey);
    if (kDebugMode) {
      print('Has time limit: $hasLimit');
    }
    return hasLimit;
  }

  /// Check if stored time limit is still valid (not expired)
  /// Uses local device time for comparison
  bool isTimeLimitValid() {
    final limit = getTimeLimit();
    if (limit == null) {
      return false;
    }
    final now = DateTime.now();
    final isValid = now.isBefore(limit);
    if (kDebugMode) {
      print('Time limit validity check: $isValid (now: $now, limit: $limit)');
    }
    return isValid;
  }
}