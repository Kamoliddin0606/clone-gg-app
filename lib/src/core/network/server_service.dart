import 'package:flutter/foundation.dart';
import '../services/shared_preferences_service.dart';

/// Server environment enumeration for different business units.
enum ServerEnv { Evyap, Garnier, PPD, Avon, AvonTest, ProWash }

/// Configuration class holding URL endpoints for a server environment.
/// Contains primary (domain) URL and fallback IP-based URLs.
class ServerUrlConfig {
  /// Primary URL using domain name (highest priority)
  final String primaryUrl;
  
  /// List of fallback URLs using IP addresses
  final List<String> fallbackUrls;
  
  /// Service path suffix (e.g., /AVON_UT/AVON_UT.1cws)
  final String servicePath;

  const ServerUrlConfig({
    required this.primaryUrl,
    required this.fallbackUrls,
    required this.servicePath,
  });

  /// Returns all URLs in priority order: primary first, then fallbacks
  List<String> get allUrls => [primaryUrl, ...fallbackUrls];

  /// Total number of available URLs
  int get urlCount => allUrls.length;
}

/// Base hosts configuration for URL failover mechanism.
/// Domain host has priority, IP hosts are used as fallbacks.
class _ServerHosts {
  static const String domainHost = 'kit.gloriya.uz';
  static const String ipHost1 = '178.218.200.120';
  static const String ipHost2 = '109.94.175.104';
  static const int port = 5443;

  /// Builds full URL from host and service path
  static String buildUrl(String host, String servicePath) {
    return 'http://$host:$port$servicePath';
  }

  /// Accounting API service path - shared across all projects
  /// This is used for client balance queries via SOAP API
  /// Путь к API бухгалтерии - общий для всех проектов
  /// Buxgalteriya API yo'li - barcha loyihalar uchun umumiy
  static const String accountingApiPath = '/gloriya_buh2/gloriya_buh2.1cws';

  /// Returns accounting API URL configuration with failover support
  /// Возвращает конфигурацию URL API бухгалтерии с поддержкой резервных адресов
  /// Failover qo'llab-quvvatlash bilan buxgalteriya API URL konfiguratsiyasini qaytaradi
  static ServerUrlConfig get accountingApiConfig => ServerUrlConfig(
    primaryUrl: buildUrl(domainHost, accountingApiPath),
    fallbackUrls: [
      buildUrl(ipHost1, accountingApiPath),
      buildUrl(ipHost2, accountingApiPath),
    ],
    servicePath: accountingApiPath,
  );
}

extension ServerEnvX on ServerEnv {
  /// Human-readable label for the server environment
  String get label => switch (this) {
    ServerEnv.Evyap    => 'Evyap',
    ServerEnv.Garnier  => 'Garnier',
    ServerEnv.PPD      => 'PPD',
    ServerEnv.Avon     => 'Avon',
    ServerEnv.AvonTest => 'Avon Test',
    ServerEnv.ProWash  => 'ProWash',
  };

  /// Service path for each server environment
  String get _servicePath => switch (this) {
    ServerEnv.Evyap    => '/EVYAP_UT/EVYAP_UT.1cws',
    ServerEnv.Garnier  => '/loreal_ut/loreal_ut.1cws',
    ServerEnv.PPD      => '/UT_Professionnel/UT_Professionnel.1cws',
    ServerEnv.Avon     => '/AVON_UT/AVON_UT.1cws',
    ServerEnv.AvonTest => '/TEST_UT/TEST_UT.1cws',
    ServerEnv.ProWash  => '/PROWASH_UT/PROWASH_UT.1cws',
  };

  /// Returns URL configuration with primary and fallback URLs
  ServerUrlConfig get urlConfig => ServerUrlConfig(
    primaryUrl: _ServerHosts.buildUrl(_ServerHosts.domainHost, _servicePath),
    fallbackUrls: [
      _ServerHosts.buildUrl(_ServerHosts.ipHost1, _servicePath),
      _ServerHosts.buildUrl(_ServerHosts.ipHost2, _servicePath),
    ],
    servicePath: _servicePath,
  );

  /// Primary URL (domain-based) - for backward compatibility
  String get url => urlConfig.primaryUrl;

  /// All available URLs in priority order
  List<String> get allUrls => urlConfig.allUrls;
}

/// Result of URL failover attempt containing working URL and its index
class UrlFailoverResult {
  final String workingUrl;
  final int urlIndex;
  final bool usedFallback;

  const UrlFailoverResult({
    required this.workingUrl,
    required this.urlIndex,
    required this.usedFallback,
  });
}

/// Service for managing server environment selection and URL failover.
/// Handles automatic switching between domain and IP-based URLs when
/// connection issues occur.
///
/// Supports two modes:
/// 1. **Static (legacy):** server selected from the [ServerEnv] enum.
/// 2. **Dynamic:** server selected from backend-provided organization/project
///    data, where the project supplies an arbitrary `servicePath`.
///
/// When a dynamic service path is active it takes precedence over the
/// [ServerEnv]-based URL. The failover mechanism ([_ServerHosts]) is
/// shared between both modes.
class ServerService {
  // ignore: unused_field
  static const _kKey = 'selected_server_env';
  static const _kLastWorkingUrlKey = 'last_working_url';

  final SharedPreferencesService _prefs;

  /// Notifies listeners when server environment changes
  final ValueNotifier<ServerEnv> current = ValueNotifier(ServerEnv.Evyap);

  /// Notifies listeners when active URL changes (due to failover)
  final ValueNotifier<String> activeUrl = ValueNotifier('');

  /// Indicates if currently using a fallback URL instead of primary
  final ValueNotifier<bool> isUsingFallback = ValueNotifier(false);

  /// Whether the current selection was set via [setDynamic] rather than
  /// the legacy [set] method.
  bool _isDynamic = false;
  String? _dynamicServicePath;

  ServerService(this._prefs);

  /// Whether the current server config comes from backend-provided data.
  bool get isDynamic => _isDynamic;

  /// Restores previously selected server environment and working URL from storage
  Future<void> restore() async {
    // Try to restore dynamic selection first
    final dynamicPath = _prefs.getDynamicServicePath();
    if (dynamicPath != null && dynamicPath.isNotEmpty) {
      _isDynamic = true;
      _dynamicServicePath = dynamicPath;

      final config = _buildDynamicUrlConfig(dynamicPath);
      final lastWorkingUrl = _prefs.preferences.getString(_kLastWorkingUrlKey);
      if (lastWorkingUrl != null && config.allUrls.contains(lastWorkingUrl)) {
        activeUrl.value = lastWorkingUrl;
        isUsingFallback.value = lastWorkingUrl != config.primaryUrl;
      } else {
        activeUrl.value = config.primaryUrl;
        isUsingFallback.value = false;
      }

      if (kDebugMode) {
        print('[ServerService] Restored dynamic: path=$dynamicPath, '
            'activeUrl=${activeUrl.value}');
      }
      return;
    }

    // Fallback to enum-based restoration
    final name = _prefs.getServerName();
    final env = ServerEnv.values.firstWhere(
      (e) => e.name == name,
      orElse: () => ServerEnv.Evyap,
    );
    current.value = env;
    _isDynamic = false;
    _dynamicServicePath = null;

    // Restore last working URL or use primary
    final lastWorkingUrl = _prefs.preferences.getString(_kLastWorkingUrlKey);
    if (lastWorkingUrl != null && env.allUrls.contains(lastWorkingUrl)) {
      activeUrl.value = lastWorkingUrl;
      isUsingFallback.value = lastWorkingUrl != env.url;
    } else {
      activeUrl.value = env.url;
      isUsingFallback.value = false;
    }

    if (kDebugMode) {
      print('[ServerService] Restored: env=${env.name}, activeUrl=${activeUrl.value}');
    }
  }

  /// Sets the current server from backend-provided organization/project
  /// data. The [servicePath] (e.g. `/EVYAP_UT/EVYAP_UT.1cws`) is used
  /// to build SOAP URLs via [_ServerHosts].
  Future<void> setDynamic({
    required String servicePath,
    required String organizationId,
    required String organizationName,
    required String projectId,
    required String projectName,
  }) async {
    _isDynamic = true;
    _dynamicServicePath = servicePath;

    final config = _buildDynamicUrlConfig(servicePath);
    activeUrl.value = config.primaryUrl;
    isUsingFallback.value = false;

    await _prefs.setDynamicServicePath(servicePath);
    await _prefs.setDynamicOrgId(organizationId);
    await _prefs.setDynamicOrgName(organizationName);
    await _prefs.setDynamicProjectId(projectId);
    await _prefs.setDynamicProjectName(projectName);
    await _prefs.setBaseUrl(config.primaryUrl);
    await _prefs.preferences.remove(_kLastWorkingUrlKey);

    if (kDebugMode) {
      print('[ServerService] Set dynamic: org=$organizationName, '
          'project=$projectName, path=$servicePath, '
          'url=${config.primaryUrl}');
    }
  }

  /// Sets the current server environment and saves to storage (legacy).
  Future<void> set(ServerEnv env) async {
    _isDynamic = false;
    _dynamicServicePath = null;

    current.value = env;
    activeUrl.value = env.url; // Reset to primary URL
    isUsingFallback.value = false;

    await _prefs.setServerName(env.name);
    await _prefs.setBaseUrl(env.url);
    await _prefs.preferences.remove(_kLastWorkingUrlKey);
    await _prefs.clearDynamicSelection();

    if (kDebugMode) {
      print('[ServerService] Set environment: ${env.name}, url=${env.url}');
    }
  }

  /// Returns current base URL (may be primary or fallback)
  String get baseUrl => activeUrl.value.isNotEmpty ? activeUrl.value : current.value.url;

  /// Returns primary (domain-based) URL for current environment
  String get primaryUrl {
    if (_isDynamic && _dynamicServicePath != null) {
      return _buildDynamicUrlConfig(_dynamicServicePath!).primaryUrl;
    }
    return current.value.url;
  }

  /// Returns all available URLs for current environment in priority order
  List<String> get allUrls {
    if (_isDynamic && _dynamicServicePath != null) {
      return _buildDynamicUrlConfig(_dynamicServicePath!).allUrls;
    }
    return current.value.allUrls;
  }

  /// Returns URL configuration for current environment
  ServerUrlConfig get urlConfig {
    if (_isDynamic && _dynamicServicePath != null) {
      return _buildDynamicUrlConfig(_dynamicServicePath!);
    }
    return current.value.urlConfig;
  }

  /// Updates the active working URL after successful connection.
  /// Saves to preferences for faster reconnection next time.
  Future<void> setWorkingUrl(String url) async {
    final urls = allUrls;
    if (!urls.contains(url)) {
      if (kDebugMode) {
        print('[ServerService] Warning: URL not in current env urls: $url');
      }
      return;
    }

    activeUrl.value = url;
    isUsingFallback.value = url != primaryUrl;

    await _prefs.setBaseUrl(url);
    await _prefs.preferences.setString(_kLastWorkingUrlKey, url);

    if (kDebugMode) {
      print('[ServerService] Working URL updated: $url (fallback: ${isUsingFallback.value})');
    }
  }

  /// Resets to primary URL. Call this periodically to check if domain is back.
  Future<void> resetToPrimaryUrl() async {
    final primary = primaryUrl;
    activeUrl.value = primary;
    isUsingFallback.value = false;

    await _prefs.setBaseUrl(primary);
    await _prefs.preferences.remove(_kLastWorkingUrlKey);

    if (kDebugMode) {
      print('[ServerService] Reset to primary URL: $primary');
    }
  }

  /// Gets index of URL in the priority list (0 = primary, 1+ = fallbacks)
  int getUrlIndex(String url) {
    return allUrls.indexOf(url);
  }

  /// Retrieves the current server name from shared preferences.
  String? getCurrentServerName() {
    return _prefs.getServerName();
  }

  /// Human-readable label for the currently selected server / project.
  String get currentLabel {
    if (_isDynamic) {
      return _prefs.getDynamicProjectName() ?? 'Unknown';
    }
    return current.value.label;
  }

  /// Returns accounting API URL configuration for client balance queries.
  /// This is a shared endpoint across all projects.
  ServerUrlConfig get accountingApiConfig => _ServerHosts.accountingApiConfig;

  /// Builds a [ServerUrlConfig] from an arbitrary service path using the
  /// shared [_ServerHosts] infrastructure.
  static ServerUrlConfig _buildDynamicUrlConfig(String servicePath) {
    return ServerUrlConfig(
      primaryUrl: _ServerHosts.buildUrl(_ServerHosts.domainHost, servicePath),
      fallbackUrls: [
        _ServerHosts.buildUrl(_ServerHosts.ipHost1, servicePath),
        _ServerHosts.buildUrl(_ServerHosts.ipHost2, servicePath),
      ],
      servicePath: servicePath,
    );
  }
}
