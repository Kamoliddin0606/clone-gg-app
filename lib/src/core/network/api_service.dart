import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/network/server_service.dart';
import 'package:gloria_marketing_flutter/src/core/network/url_failover_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
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
///
/// Two transports live on this class:
///   * [_dio] / [post] / [get] — historical SOAP transport. `baseUrl` is
///     [ServerService.baseUrl] which points at the 1C `*.1cws` endpoint
///     (e.g. `http://kit.gloriya.uz:5443/EVYAP_UT/EVYAP_UT.1cws`). DO NOT
///     use this for REST endpoints — they get appended onto the SOAP path
///     and the 1C box tries to parse the JSON body as a SOAP envelope.
///   * [_restDio] / [restPost] / [restGet] — Django V2 transport. `baseUrl`
///     is [TokenService.v2BaseUrl]. Used for every `/api/mobile/v2/...`
///     REST endpoint. Bearer token is attached automatically.
class ApiService {
  final Dio _dio = Dio();

  /// Dedicated REST transport for the Django V2 backend. Constructed lazily
  /// so unit tests that swap [TokenService] before the service is touched
  /// still see the override.
  Dio? _restDioInstance;

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

  /// Build the REST Dio on first access.
  ///
  /// Lives separately from [_dio] so the SOAP base URL never bleeds into
  /// REST calls. Attaches the V2 access token via a request interceptor
  /// that re-resolves the token on every call — covers silent refresh
  /// and post-login session pickup without touching the cached Dio.
  Dio get _restDio {
    final existing = _restDioInstance;
    if (existing != null) return existing;
    final dio = Dio(BaseOptions(
      baseUrl: TokenService.v2BaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await sl<TokenService>().ensureValidV2Token();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          if (kDebugMode) {
            print('ApiService.rest: token refresh failed: $e');
          }
        }
        return handler.next(options);
      },
      onError: (err, handler) {
        if (kDebugMode) {
          print(
              'ApiService.rest: ${err.requestOptions.method} ${err.requestOptions.path} → ${err.response?.statusCode} ${err.message}');
        }
        return handler.next(err);
      },
    ));
    _restDioInstance = dio;
    return dio;
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
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.get(path, queryParameters: queryParameters, options: options);

  /// Standard POST request (without failover - use for non-critical requests)
  Future<Response> post(String path, {dynamic data, Options? options}) =>
      _dio.post(path, data: data, options: options);

  /// REST POST to the Django V2 backend.
  ///
  /// Use this for every `/api/...` endpoint. Unlike [post], this routes
  /// to [TokenService.v2BaseUrl] (not the 1C SOAP box) and attaches the
  /// V2 Bearer token automatically.
  Future<Response> restPost(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _restDio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

  /// REST GET counterpart to [restPost]. Same rules apply.
  Future<Response> restGet(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _restDio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );

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

  /// Get server time and time limit from GetServerTime SOAP endpoint
  /// 
  /// Returns SOAP response string containing:
  /// - DateTime: Current server time
  /// - DateTimeLimit: User access expiration time
  /// 
  /// Throws:
  /// - [ConnectivityException] on network errors
  /// - [AllServersUnavailableException] if all servers fail
  /// - [ServerException] on SOAP Fault or server errors
  Future<String> getServerTime() async {
    final result = await _failoverService.executeSoapWithFailover(
      body: '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
  <soap:Header/>
  <soap:Body>
    <sam:GetServerTime/>
  </soap:Body>
</soap:Envelope>''',
    );
    
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

  bool _isConnectionError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
           e.type == DioExceptionType.receiveTimeout ||
           e.type == DioExceptionType.sendTimeout ||
           e.type == DioExceptionType.connectionError ||
           (e.type == DioExceptionType.unknown && 
            e.error.toString().contains('SocketException'));
  }
}