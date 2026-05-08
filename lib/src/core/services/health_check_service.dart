import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/telemetry_v2/rest_logging.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';

/// Outcome of a backend health probe.
@immutable
class HealthCheckResult {
  final bool ok;
  final int? statusCode;
  final Duration? latency;
  final String? errorMessage;

  const HealthCheckResult({
    required this.ok,
    this.statusCode,
    this.latency,
    this.errorMessage,
  });

  @override
  String toString() {
    if (ok) {
      final ms = latency?.inMilliseconds ?? -1;
      return 'HealthCheckResult(ok=true, status=$statusCode, latency=${ms}ms)';
    }
    return 'HealthCheckResult(ok=false, status=$statusCode, '
        'error=$errorMessage)';
  }
}

/// Lightweight liveness probe for the V2 backend.
///
/// Used at startup (debug-only fire-and-forget log) and from the LoginPage
/// "Test connection" button. Owns its own [Dio] instance — no shared
/// interceptors — and re-reads [TokenService.v2BaseUrl] at every call so
/// `--dart-define` overrides take effect without rebuilding the singleton.
class HealthCheckService {
  static const String _tag = 'HEALTH';
  static const Duration _timeout = Duration(seconds: 5);

  /// Pings the V2 backend. Hits `/api/auth/token/verify/` with no body —
  /// expects a 4xx (token missing) which still proves the backend is up.
  /// Any 2xx/4xx is treated as reachable; only timeouts and 5xx fail.
  Future<HealthCheckResult> pingV2() async {
    final baseUrl = TokenService.v2BaseUrl;
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      sendTimeout: _timeout,
      validateStatus: (_) => true,
    ));
    attachRestLogger(dio, _tag);

    // Cached access tokenni body'ga qo'shamiz — yo'q bo'lsa endpoint 400
    // qaytaradi (liveness uchun yetarli, lekin loglarni ifloslantiradi).
    final cachedToken = sl.isRegistered<TokenService>()
        ? sl<TokenService>().getStoredV2AccessToken()
        : null;
    final body = (cachedToken != null && cachedToken.isNotEmpty)
        ? {'token': cachedToken}
        : <String, dynamic>{};

    final stopwatch = Stopwatch()..start();
    try {
      final response = await dio.post('/api/auth/token/verify/', data: body);
      stopwatch.stop();
      final code = response.statusCode ?? 0;
      final reachable = code >= 200 && code < 500;
      restLog(
        _tag,
        reachable
            ? 'V2 backend reachable in ${stopwatch.elapsed.inMilliseconds}ms '
                '(status=$code)'
            : 'V2 backend returned $code in ${stopwatch.elapsed.inMilliseconds}ms',
      );
      return HealthCheckResult(
        ok: reachable,
        statusCode: code,
        latency: stopwatch.elapsed,
        errorMessage: reachable ? null : 'HTTP $code',
      );
    } on DioException catch (e) {
      stopwatch.stop();
      final reason = _describe(e);
      restLog(_tag, 'V2 backend UNREACHABLE: $reason');
      return HealthCheckResult(
        ok: false,
        statusCode: e.response?.statusCode,
        latency: stopwatch.elapsed,
        errorMessage: reason,
      );
    } catch (e) {
      stopwatch.stop();
      restLog(_tag, 'V2 backend UNREACHABLE (unexpected): $e');
      return HealthCheckResult(
        ok: false,
        latency: stopwatch.elapsed,
        errorMessage: e.toString(),
      );
    } finally {
      dio.close();
    }
  }

  static String _describe(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'connection timeout';
      case DioExceptionType.receiveTimeout:
        return 'receive timeout';
      case DioExceptionType.sendTimeout:
        return 'send timeout';
      case DioExceptionType.connectionError:
        return 'connection error: ${e.message ?? 'unknown'}';
      case DioExceptionType.badCertificate:
        return 'bad TLS certificate';
      case DioExceptionType.cancel:
        return 'cancelled';
      case DioExceptionType.badResponse:
        return 'HTTP ${e.response?.statusCode ?? '?'}';
      case DioExceptionType.unknown:
        return e.message ?? 'unknown error';
    }
  }
}
