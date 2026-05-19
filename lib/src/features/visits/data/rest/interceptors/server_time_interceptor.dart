import 'package:dio/dio.dart';

/// Records the server's `X-Server-Time` header into [onServerTime]. The
/// callback is intentionally side-effectful (the interceptor doesn't import
/// the time service to avoid a layering cycle).
class ServerTimeInterceptor extends Interceptor {
  ServerTimeInterceptor({required this.onServerTime});

  final void Function(DateTime serverTime) onServerTime;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _capture(response.headers);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response != null) {
      _capture(err.response!.headers);
    }
    handler.next(err);
  }

  void _capture(Headers headers) {
    final raw = headers.value('x-server-time') ?? headers.value('X-Server-Time');
    if (raw == null || raw.isEmpty) return;
    try {
      onServerTime(DateTime.parse(raw));
    } catch (_) {
      // Garbage value — ignore. The time service has its own staleness check.
    }
  }
}
