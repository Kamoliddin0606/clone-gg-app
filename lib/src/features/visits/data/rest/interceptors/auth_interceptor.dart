import 'package:dio/dio.dart';

/// Reads the access token from a callback (so we never cache a stale value)
/// and tags every outbound request. 401 handling is left to the dispatcher
/// loop — interceptors don't refresh tokens themselves because the refresh
/// call must hit a different Dio instance to avoid recursion.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required Future<String?> Function() accessTokenLoader})
      : _loader = accessTokenLoader;

  final Future<String?> Function() _loader;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _loader();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
