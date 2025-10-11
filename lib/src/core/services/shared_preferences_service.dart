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
  // static const String _serverName = 'selected_server_name';

  static SharedPreferencesService? _instance;
  // static SharedPreferences? _preferences;
  bool _isInitialized = false;
  // Singleton pattern to ensure only one instance of SharedPreferencesService
Future<void> init() async {
  if (!_isInitialized) {
    _preferences = await SharedPreferences.getInstance();
    _isInitialized = true;
  }
}
  // Future<void> init() async {
  //   _preferences = await SharedPreferences.getInstance();
  // }
  SharedPreferencesService._();

  static Future<SharedPreferencesService> getInstance() async {
    _instance ??= SharedPreferencesService._();
    // _preferences ??= await SharedPreferences.getInstance();
    await _instance!.init();
    // Ensure the instance is initialized
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
    print('Saved TelegramID: $telegramID, ChatID: $chatID, TopicID: $topicID');
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
    print('Getting user code from SharedPreferences');
    print('User code key: $_userCodeKey');
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
    print('Retrieved TelegramID: $id');
    return id;
  }

  // Get chat ID
  String? getChatID() {
    final id = _preferences.getString(_chatIDKey);
    print('Retrieved ChatID: $id');
    return id;
  }

  // Get topic ID
  String? getTopicID() {
    final id = _preferences.getString(_topicIDKey);
    print('Retrieved TopicID: $id');
    return id;
  }

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
    print('Retrieved server name: $serverName');
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
}