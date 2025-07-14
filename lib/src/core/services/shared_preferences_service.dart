import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  late final SharedPreferences _preferences;
  static const String _usernameKey = 'saved_username';
  static const String _passwordKey = 'saved_password';
  static const String _rememberMeKey = 'remember_me';
  static const String _userCodeKey = 'user_code';
  static const String _userNameKey = 'user_name';
  static const String _warehouseCodeKey = 'warehouse_code';

  static SharedPreferencesService? _instance;
  // static SharedPreferences? _preferences;
  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }
  SharedPreferencesService._();

  static Future<SharedPreferencesService> getInstance() async {
    _instance ??= SharedPreferencesService._();
    // _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // Save login credentials
  Future<void> saveCredentials(String username, String password) async {
    await _preferences!.setString(_usernameKey, username);
    await _preferences!.setString(_passwordKey, password);
    await _preferences!.setBool(_rememberMeKey, true);
  }

  // Save user data after successful login
  Future<void> saveUserData({
    required String userCode,
    required String userName,
    required String warehouseCode,
  }) async {
    await _preferences!.setString(_userCodeKey, userCode);
    await _preferences!.setString(_userNameKey, userName);
    await _preferences!.setString(_warehouseCodeKey, warehouseCode);
  }

  // Get saved username
  String? getSavedUsername() {
    return _preferences!.getString(_usernameKey);
  }

  // Get saved password
  String? getSavedPassword() {
    return _preferences!.getString(_passwordKey);
  }

  // Check if remember me is enabled
  bool isRememberMeEnabled() {
    return _preferences!.getBool(_rememberMeKey) ?? false;
  }

  // Clear saved credentials
  Future<void> clearCredentials() async {
    await _preferences!.remove(_usernameKey);
    await _preferences!.remove(_passwordKey);
    await _preferences!.setBool(_rememberMeKey, false);
  }

  // Set remember me preference
  Future<void> setRememberMe(bool value) async {
    await _preferences!.setBool(_rememberMeKey, value);
  }

  // Get user code
  String? getUserCode() {
    return _preferences!.getString(_userCodeKey);
  }

  // Get user name
  String? getUserName() {
    return _preferences!.getString(_userNameKey);
  }

  // Get warehouse code
  String? getWarehouseCode() {
    return _preferences!.getString(_warehouseCodeKey);
  }

  // Get password (for API calls)
  String? getPassword() {
    return _preferences!.getString(_passwordKey);
  }

  // Clear all user data
  Future<void> clearUserData() async {
    await _preferences!.remove(_userCodeKey);
    await _preferences!.remove(_userNameKey);
    await _preferences!.remove(_warehouseCodeKey);
  }
}