import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/network/server_service.dart';
import 'package:gloria_marketing_flutter/src/core/network/url_failover_service.dart';
import '../services/service_locator.dart';

/// Exception thrown when network connectivity issues occur
class ConnectivityException implements Exception {
  final String message;
  final bool allServersFailed;
  
  ConnectivityException(this.message, {this.allServersFailed = false});

  @override
  String toString() => message;
}

/// Exception thrown when server returns an error response
class ServerException implements Exception {
  final String message;
  ServerException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when all fallback URLs have been exhausted
class AllServersUnavailableException implements Exception {
  final String message;
  final List<String> triedUrls;
  
  AllServersUnavailableException(this.message, {this.triedUrls = const []});

  @override
  String toString() => message;
}

/// API Service with automatic URL failover support.
/// Tries primary domain URL first, then falls back to IP-based URLs
/// if connection issues occur.
class ApiService {
  final Dio _dio = Dio();
  final ServerService _server;
  final UrlFailoverService _failoverService;
  
  /// Notifies listeners when URL changes due to failover
  final ValueNotifier<String> currentUrlNotifier = ValueNotifier('');
  
  /// Notifies listeners when using fallback URL
  final ValueNotifier<bool> isUsingFallbackNotifier = ValueNotifier(false);

  ApiService({
    ServerService? serverService,
    UrlFailoverService? failoverService,
  }) : _server = serverService ?? sl<ServerService>(),
       _failoverService = failoverService ?? sl<UrlFailoverService>() {
    _initDio();
    _setupListeners();
  }

  void _initDio() {
    _dio.options = BaseOptions(
      baseUrl: _server.baseUrl,
      connectTimeout: const Duration(milliseconds: 8000),
      receiveTimeout: const Duration(milliseconds: 15000),
    );
    
    currentUrlNotifier.value = _server.baseUrl;
    isUsingFallbackNotifier.value = _server.isUsingFallback.value;
  }

  void _setupListeners() {
    // Update Dio baseUrl when server environment changes
    _server.current.addListener(() {
      _dio.options.baseUrl = _server.baseUrl;
      currentUrlNotifier.value = _server.baseUrl;
    });
    
    // Update Dio baseUrl when active URL changes (failover)
    _server.activeUrl.addListener(() {
      _dio.options.baseUrl = _server.baseUrl;
      currentUrlNotifier.value = _server.baseUrl;
      isUsingFallbackNotifier.value = _server.isUsingFallback.value;
    });
    
    // Listen for failover URL changes
    _failoverService.addUrlChangeListener((newUrl, isFallback) {
      if (kDebugMode) {
        print('[ApiService] URL changed to: $newUrl (fallback: $isFallback)');
      }
    });
  }

  /// Standard GET request (without failover - use for non-critical requests)
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);

  /// Standard POST request (without failover - use for non-critical requests)
  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  /// Perform SOAP request with automatic URL failover.
  /// Tries primary URL first, then fallback URLs if connection fails.
  Future<String> performSoapRequest(String body) async {
    final result = await _failoverService.executeSoapWithFailover(body: body);
    
    if (result.isSuccess && result.data != null) {
      return result.data!;
    }
    
    // Handle different error scenarios
    if (result.allUrlsFailed) {
      throw AllServersUnavailableException(
        'All servers are unavailable. Please check your internet connection.',
        triedUrls: _server.allUrls,
      );
    }
    
    // Check if it's a connectivity error
    if (result.error?.contains('Connection') == true ||
        result.error?.contains('timeout') == true) {
      throw ConnectivityException(
        'Network connection error: ${result.error}',
        allServersFailed: result.allUrlsFailed,
      );
    }
    
    throw ServerException('Server error: ${result.error}');
  }

  /// Perform SOAP request with manual URL specification (for testing/debugging)
  Future<String> performSoapRequestWithUrl(String body, String url) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(milliseconds: 8000),
        receiveTimeout: const Duration(milliseconds: 15000),
      ));
      
      final res = await dio.post(
        '',
        data: body,
        options: Options(headers: {'Content-Type': 'text/xml; charset=utf-8'}),
      );
      return res.data;
    } on DioException catch (e) {
      if (_isConnectionError(e)) {
        throw ConnectivityException('Network connection error: ${e.message}');
      } else {
        throw ServerException('Server error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to perform SOAP request: $e');
    }
  }

  /// Force retry with primary URL (useful when user wants to check if domain is back)
  Future<String> performSoapRequestWithPrimaryRetry(String body) async {
    final result = await _failoverService.executeWithFailover(
      request: (dio, baseUrl) => dio.post(
        '',
        data: body,
        options: Options(headers: {'Content-Type': 'text/xml; charset=utf-8'}),
      ),
      forceRetryPrimary: true,
    );
    
    if (result.isSuccess && result.data != null) {
      return result.data!.data?.toString() ?? '';
    }
    
    if (result.allUrlsFailed) {
      throw AllServersUnavailableException(
        'All servers are unavailable',
        triedUrls: _server.allUrls,
      );
    }
    
    throw ServerException('Request failed: ${result.error}');
  }

  /// Reset failover state and force primary URL
  Future<void> resetToPrimaryUrl() async {
    await _failoverService.reset();
  }

  /// Check if currently using a fallback URL
  bool get isUsingFallback => _failoverService.isUsingFallback;

  /// Get currently active URL
  String get currentUrl => _failoverService.currentUrl;

  /// Get primary (domain) URL
  String get primaryUrl => _failoverService.primaryUrl;

  /// Get all available URLs for current server environment
  List<String> get allUrls => _server.allUrls;

  bool _isConnectionError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
           e.type == DioExceptionType.receiveTimeout ||
           e.type == DioExceptionType.sendTimeout ||
           e.type == DioExceptionType.connectionError ||
           (e.type == DioExceptionType.unknown && 
            e.error.toString().contains('SocketException'));
  }
}