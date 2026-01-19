import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'server_service.dart';
import '../services/service_locator.dart';

/// Configuration for URL failover behavior
class FailoverConfig {
  /// Timeout for each URL attempt (in milliseconds)
  final int connectionTimeoutMs;
  
  /// Timeout for receiving response (in milliseconds)
  final int receiveTimeoutMs;
  
  /// How often to retry primary URL when using fallback (in minutes)
  final int primaryUrlRetryIntervalMinutes;
  
  /// Maximum number of consecutive failures before trying next URL
  final int maxFailuresPerUrl;

  const FailoverConfig({
    this.connectionTimeoutMs = 8000,
    this.receiveTimeoutMs = 15000,
    this.primaryUrlRetryIntervalMinutes = 5,
    this.maxFailuresPerUrl = 1,
  });
}

/// Tracks the status of each URL in the failover chain
class UrlStatus {
  final String url;
  int failureCount;
  DateTime? lastFailure;
  DateTime? lastSuccess;
  bool isAvailable;

  UrlStatus({
    required this.url,
    this.failureCount = 0,
    this.lastFailure,
    this.lastSuccess,
    this.isAvailable = true,
  });

  void recordFailure() {
    failureCount++;
    lastFailure = DateTime.now();
    isAvailable = false;
  }

  void recordSuccess() {
    failureCount = 0;
    lastSuccess = DateTime.now();
    isAvailable = true;
  }
}

/// Result of a failover request attempt
class FailoverRequestResult<T> {
  final T? data;
  final String usedUrl;
  final int urlIndex;
  final bool usedFallback;
  final String? error;
  final bool allUrlsFailed;

  const FailoverRequestResult({
    this.data,
    required this.usedUrl,
    required this.urlIndex,
    required this.usedFallback,
    this.error,
    this.allUrlsFailed = false,
  });

  bool get isSuccess => data != null && error == null;
}

/// Callback type for URL change notifications
typedef UrlChangeCallback = void Function(String newUrl, bool isFallback);

/// Service that handles automatic URL failover when connection issues occur.
/// Tries URLs in priority order: domain URL first, then IP-based fallbacks.
class UrlFailoverService {
  final ServerService _serverService;
  final FailoverConfig _config;
  final Dio _dio;
  
  /// Tracks status of each URL
  final Map<String, UrlStatus> _urlStatuses = {};
  
  /// Last time we tried the primary URL
  DateTime? _lastPrimaryUrlAttempt;
  
  /// Callbacks to notify when URL changes
  final List<UrlChangeCallback> _urlChangeCallbacks = [];

  UrlFailoverService({
    ServerService? serverService,
    FailoverConfig? config,
    Dio? dio,
  })  : _serverService = serverService ?? sl<ServerService>(),
        _config = config ?? const FailoverConfig(),
        _dio = dio ?? Dio();

  /// Initialize URL statuses for current server environment
  void _initUrlStatuses() {
    final urls = _serverService.allUrls;
    for (final url in urls) {
      if (!_urlStatuses.containsKey(url)) {
        _urlStatuses[url] = UrlStatus(url: url);
      }
    }
  }

  /// Register callback for URL change notifications
  void addUrlChangeListener(UrlChangeCallback callback) {
    _urlChangeCallbacks.add(callback);
  }

  /// Remove URL change listener
  void removeUrlChangeListener(UrlChangeCallback callback) {
    _urlChangeCallbacks.remove(callback);
  }

  /// Notify all listeners about URL change
  void _notifyUrlChange(String newUrl, bool isFallback) {
    for (final callback in _urlChangeCallbacks) {
      callback(newUrl, isFallback);
    }
  }

  /// Check if we should try primary URL again
  bool _shouldRetryPrimaryUrl() {
    if (_lastPrimaryUrlAttempt == null) return true;
    
    final elapsed = DateTime.now().difference(_lastPrimaryUrlAttempt!);
    return elapsed.inMinutes >= _config.primaryUrlRetryIntervalMinutes;
  }

  /// Determines if an error is a connection-related error that warrants failover
  bool _isConnectionError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
           e.type == DioExceptionType.receiveTimeout ||
           e.type == DioExceptionType.sendTimeout ||
           e.type == DioExceptionType.connectionError ||
           (e.type == DioExceptionType.unknown && 
            e.error.toString().contains('SocketException'));
  }

  /// Get ordered list of URLs to try, starting with most likely to work
  /// 
  /// [customUrlConfig] - Optional custom URL configuration for specific endpoints
  /// If provided, uses custom URLs instead of default server URLs
  /// 
  /// [customUrlConfig] - Опциональная пользовательская конфигурация URL для специфических endpoint'ов
  /// Если указана, использует пользовательские URL вместо URL по умолчанию
  /// 
  /// [customUrlConfig] - Maxsus endpoint'lar uchun ixtiyoriy URL konfiguratsiyasi
  /// Agar berilgan bo'lsa, standart URL'lar o'rniga maxsus URL'lardan foydalanadi
  List<String> _getUrlsToTry({ServerUrlConfig? customUrlConfig}) {
    _initUrlStatuses();
    
    // Use custom URLs if provided, otherwise use default server URLs
    // Используем пользовательские URL если указаны, иначе URL по умолчанию
    // Agar berilgan bo'lsa maxsus URL'lardan, aks holda standart URL'lardan foydalanish
    final urls = customUrlConfig?.allUrls ?? _serverService.allUrls;
    final currentUrl = customUrlConfig?.primaryUrl ?? _serverService.baseUrl;
    
    // If using fallback and should retry primary, put primary first
    if (_serverService.isUsingFallback.value && _shouldRetryPrimaryUrl()) {
      _lastPrimaryUrlAttempt = DateTime.now();
      return urls; // Primary is already first in the list
    }
    
    // Otherwise, start with current working URL
    final result = <String>[currentUrl];
    for (final url in urls) {
      if (url != currentUrl) {
        result.add(url);
      }
    }
    return result;
  }

  /// Execute a request with automatic URL failover.
  /// Returns result with the response data and information about which URL worked.
  /// 
  /// [request] - Function that performs the actual HTTP request
  /// [forceRetryPrimary] - Force retry from primary URL
  /// [customUrlConfig] - Optional custom URL configuration for specific endpoints
  /// 
  /// [request] - Функция, выполняющая фактический HTTP запрос
  /// [forceRetryPrimary] - Принудительная попытка с основного URL
  /// [customUrlConfig] - Опциональная пользовательская конфигурация URL
  /// 
  /// [request] - Haqiqiy HTTP so'rovni bajaradigan funksiya
  /// [forceRetryPrimary] - Asosiy URL'dan majburiy urinish
  /// [customUrlConfig] - Ixtiyoriy maxsus URL konfiguratsiyasi
  Future<FailoverRequestResult<Response>> executeWithFailover({
    required Future<Response> Function(Dio dio, String baseUrl) request,
    bool forceRetryPrimary = false,
    ServerUrlConfig? customUrlConfig,
  }) async {
    final urlsToTry = forceRetryPrimary 
        ? (customUrlConfig?.allUrls ?? _serverService.allUrls)
        : _getUrlsToTry(customUrlConfig: customUrlConfig);
    
    String? lastError;
    
    for (int i = 0; i < urlsToTry.length; i++) {
      final url = urlsToTry[i];
      // Use custom config index if provided, otherwise use server service index
      // Используем индекс из пользовательской конфигурации если указана, иначе из server service
      // Agar berilgan bo'lsa maxsus konfiguratsiya indeksidan, aks holda server service indeksidan foydalanish
      final urlIndex = customUrlConfig != null 
          ? customUrlConfig.allUrls.indexOf(url)
          : _serverService.getUrlIndex(url);
      final isFallback = urlIndex > 0;
      
      try {
        if (kDebugMode) {
          print('[UrlFailover] Trying URL [$i]: $url');
        }
        
        // Configure Dio for this attempt
        _dio.options = BaseOptions(
          baseUrl: url,
          connectTimeout: Duration(milliseconds: _config.connectionTimeoutMs),
          receiveTimeout: Duration(milliseconds: _config.receiveTimeoutMs),
        );
        
        // Execute request
        final response = await request(_dio, url);
        
        // Success - update status and save working URL
        // Only update server service if not using custom config
        // Обновляем server service только если не используется пользовательская конфигурация
        // Faqat maxsus konfiguratsiya ishlatilmasa server service'ni yangilash
        _urlStatuses[url]?.recordSuccess();
        if (customUrlConfig == null) {
          await _serverService.setWorkingUrl(url);
        }
        
        if (kDebugMode) {
          print('[UrlFailover] Success with URL: $url (fallback: $isFallback)');
        }
        
        // Notify listeners if URL changed (only for default config)
        // Уведомляем слушателей об изменении URL (только для конфигурации по умолчанию)
        // URL o'zgarganligi haqida xabar berish (faqat standart konfiguratsiya uchun)
        if (customUrlConfig == null && url != _serverService.baseUrl) {
          _notifyUrlChange(url, isFallback);
        }
        
        return FailoverRequestResult(
          data: response,
          usedUrl: url,
          urlIndex: urlIndex,
          usedFallback: isFallback,
        );
        
      } on DioException catch (e) {
        if (_isConnectionError(e)) {
          // Connection error - mark URL as failed and try next
          _urlStatuses[url]?.recordFailure();
          lastError = 'Connection failed: ${e.message}';
          
          if (kDebugMode) {
            print('[UrlFailover] Connection error with URL: $url - ${e.type}');
          }
          continue; // Try next URL
        } else {
          // Server error (not connection issue) - don't failover
          lastError = 'Server error: ${e.message}';
          
          if (kDebugMode) {
            print('[UrlFailover] Server error (no failover): ${e.message}');
          }
          
          return FailoverRequestResult(
            data: null,
            usedUrl: url,
            urlIndex: urlIndex,
            usedFallback: isFallback,
            error: lastError,
          );
        }
      } catch (e) {
        lastError = 'Unexpected error: $e';
        if (kDebugMode) {
          print('[UrlFailover] Unexpected error: $e');
        }
        continue; // Try next URL
      }
    }
    
    // All URLs failed
    if (kDebugMode) {
      print('[UrlFailover] All URLs failed. Last error: $lastError');
    }
    
    return FailoverRequestResult(
      data: null,
      usedUrl: urlsToTry.last,
      urlIndex: _serverService.getUrlIndex(urlsToTry.last),
      usedFallback: true,
      error: lastError ?? 'All servers unavailable',
      allUrlsFailed: true,
    );
  }

  /// Execute a SOAP request with automatic URL failover
  /// 
  /// [body] - SOAP request body (XML)
  /// [headers] - Optional HTTP headers
  /// [customUrlConfig] - Optional custom URL configuration for specific endpoints
  ///                     (e.g., accounting API that differs from project-specific endpoints)
  /// 
  /// [body] - Тело SOAP запроса (XML)
  /// [headers] - Опциональные HTTP заголовки
  /// [customUrlConfig] - Опциональная пользовательская конфигурация URL для специфических endpoint'ов
  ///                     (например, API бухгалтерии, отличающийся от endpoint'ов проекта)
  /// 
  /// [body] - SOAP so'rov tanasi (XML)
  /// [headers] - Ixtiyoriy HTTP headerlar
  /// [customUrlConfig] - Maxsus endpoint'lar uchun ixtiyoriy URL konfiguratsiyasi
  ///                     (masalan, loyiha-spetsifik endpoint'lardan farq qiladigan buxgalteriya API)
  Future<FailoverRequestResult<String>> executeSoapWithFailover({
    required String body,
    Map<String, String>? headers,
    ServerUrlConfig? customUrlConfig,
  }) async {
    final result = await executeWithFailover(
      request: (dio, baseUrl) => dio.post(
        '',
        data: body,
        options: Options(
          headers: headers ?? {'Content-Type': 'text/xml; charset=utf-8'},
        ),
      ),
      customUrlConfig: customUrlConfig,
    );
    
    if (result.isSuccess && result.data != null) {
      return FailoverRequestResult<String>(
        data: result.data!.data?.toString(),
        usedUrl: result.usedUrl,
        urlIndex: result.urlIndex,
        usedFallback: result.usedFallback,
      );
    }
    
    return FailoverRequestResult<String>(
      data: null,
      usedUrl: result.usedUrl,
      urlIndex: result.urlIndex,
      usedFallback: result.usedFallback,
      error: result.error,
      allUrlsFailed: result.allUrlsFailed,
    );
  }

  /// Reset all URL statuses and force retry from primary
  Future<void> reset() async {
    _urlStatuses.clear();
    _lastPrimaryUrlAttempt = null;
    await _serverService.resetToPrimaryUrl();
    
    if (kDebugMode) {
      print('[UrlFailover] Reset to primary URL');
    }
  }

  /// Get current status of all URLs
  Map<String, UrlStatus> get urlStatuses {
    _initUrlStatuses();
    return Map.unmodifiable(_urlStatuses);
  }

  /// Check if currently using a fallback URL
  bool get isUsingFallback => _serverService.isUsingFallback.value;

  /// Get currently active URL
  String get currentUrl => _serverService.baseUrl;

  /// Get primary (domain) URL
  String get primaryUrl => _serverService.primaryUrl;
}
