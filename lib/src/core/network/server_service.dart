import 'package:flutter/foundation.dart';
import '../services/shared_preferences_service.dart';

/// Server environment enumeration for different business units.
enum ServerEnv { Evyap, Garnier, PPD, Avon, AvonTest }

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
}

extension ServerEnvX on ServerEnv {
  /// Human-readable label for the server environment
  String get label => switch (this) {
    ServerEnv.Evyap    => 'Evyap',
    ServerEnv.Garnier  => 'Garnier',
    ServerEnv.PPD      => 'PPD',
    ServerEnv.Avon     => 'Avon',
    ServerEnv.AvonTest => 'Avon Test',
  };

  /// Service path for each server environment
  String get _servicePath => switch (this) {
    ServerEnv.Evyap    => '/EVYAP_UT/EVYAP_UT.1cws',
    ServerEnv.Garnier  => '/loreal_ut/loreal_ut.1cws',
    ServerEnv.PPD      => '/UT_Professionnel/UT_Professionnel.1cws',
    ServerEnv.Avon     => '/AVON_UT/AVON_UT.1cws',
    ServerEnv.AvonTest => '/TEST_UT/TEST_UT.1cws',
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

  ServerService(this._prefs);

  /// Restores previously selected server environment and working URL from storage
  Future<void> restore() async {
    final name = _prefs.getServerName();
    final env = ServerEnv.values.firstWhere(
      (e) => e.name == name,
      orElse: () => ServerEnv.Evyap,
    );
    current.value = env;
    
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

  /// Sets the current server environment and saves to storage
  Future<void> set(ServerEnv env) async {
    current.value = env;
    activeUrl.value = env.url; // Reset to primary URL
    isUsingFallback.value = false;
    
    await _prefs.setServerName(env.name);
    await _prefs.setBaseUrl(env.url);
    await _prefs.preferences.remove(_kLastWorkingUrlKey);
    
    if (kDebugMode) {
      print('[ServerService] Set environment: ${env.name}, url=${env.url}');
    }
  }

  /// Returns current base URL (may be primary or fallback)
  String get baseUrl => activeUrl.value.isNotEmpty ? activeUrl.value : current.value.url;

  /// Returns primary (domain-based) URL for current environment
  String get primaryUrl => current.value.url;

  /// Returns all available URLs for current environment in priority order
  List<String> get allUrls => current.value.allUrls;

  /// Returns URL configuration for current environment
  ServerUrlConfig get urlConfig => current.value.urlConfig;

  /// Updates the active working URL after successful connection.
  /// Saves to preferences for faster reconnection next time.
  Future<void> setWorkingUrl(String url) async {
    if (!current.value.allUrls.contains(url)) {
      if (kDebugMode) {
        print('[ServerService] Warning: URL not in current env urls: $url');
      }
      return;
    }
    
    activeUrl.value = url;
    isUsingFallback.value = url != current.value.url;
    
    await _prefs.setBaseUrl(url);
    await _prefs.preferences.setString(_kLastWorkingUrlKey, url);
    
    if (kDebugMode) {
      print('[ServerService] Working URL updated: $url (fallback: ${isUsingFallback.value})');
    }
  }

  /// Resets to primary URL. Call this periodically to check if domain is back.
  Future<void> resetToPrimaryUrl() async {
    activeUrl.value = current.value.url;
    isUsingFallback.value = false;
    
    await _prefs.setBaseUrl(current.value.url);
    await _prefs.preferences.remove(_kLastWorkingUrlKey);
    
    if (kDebugMode) {
      print('[ServerService] Reset to primary URL: ${current.value.url}');
    }
  }

  /// Gets index of URL in the priority list (0 = primary, 1+ = fallbacks)
  int getUrlIndex(String url) {
    return current.value.allUrls.indexOf(url);
  }

  /// Retrieves the current server name from shared preferences.
  String? getCurrentServerName() {
    return _prefs.getServerName();
  }
}
