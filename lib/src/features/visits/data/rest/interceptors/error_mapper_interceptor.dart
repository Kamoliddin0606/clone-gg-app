import 'package:dio/dio.dart';

import '../../../domain/failures.dart';
import '../error_envelope.dart';

/// Translates `DioException`s into Domain `Failure`s.
///
/// We don't throw the `Failure` from the interceptor (Dio wants a
/// `DioException`); instead we stash it in `err.error` so the calling
/// service can rethrow the typed instance with one line.
class ErrorMapperInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    err = err.copyWith(error: _map(err));
    handler.next(err);
  }

  Failure _map(DioException err) {
    // Network / transport classes are always transient.
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure('Timeout', code: 'TIMEOUT', transient: true);
      case DioExceptionType.connectionError:
        return NetworkFailure('No connection',
            code: 'NETWORK', transient: true);
      case DioExceptionType.cancel:
        return NetworkFailure('Cancelled',
            code: 'CANCELLED', transient: false);
      case DioExceptionType.badCertificate:
        return SecurityFailure('Bad certificate', code: 'TLS');
      case DioExceptionType.unknown:
        // Fall through to status-code mapping below if a response came back.
        break;
      case DioExceptionType.badResponse:
        break;
    }

    final status = err.response?.statusCode ?? 0;
    final envelope = ErrorEnvelope.tryParse(err.response?.data);
    final code = envelope?.code;
    final message = envelope?.message ?? err.message ?? 'Unknown error';
    final details = envelope?.details;

    if (status >= 500) {
      return NetworkFailure(message,
          code: code ?? 'SERVER_ERROR', details: details, transient: true);
    }
    if (status == 401) {
      return AuthFailure(message, code: code ?? 'AUTH_REQUIRED');
    }
    if (status == 403) {
      return AuthFailure(message, code: code ?? 'FORBIDDEN');
    }
    if (status == 429) {
      return NetworkFailure(message,
          code: code ?? 'RATE_LIMITED', details: details, transient: true);
    }

    switch (code) {
      case 'VISITS_GEOFENCE_VIOLATION':
        return GeofenceFailure(message, code: code, details: details);
      case 'VISITS_CLOCK_DRIFT':
        return ClockDriftFailure(message, code: code, details: details);
      case 'VISITS_PHOTO_MISSING':
        return PhotoMissingFailure(message, code: code, details: details);
      case 'VISITS_IDEMPOTENCY_MISMATCH':
        return IdempotencyMismatchFailure(message,
            code: code, details: details);
      case 'VISITS_CONFLICT':
        return VisitConflictFailure(message, code: code, details: details);
      case 'VISITS_VALIDATION_FAILED':
        return ValidationFailure(message, code: code, details: details);
    }

    if (status >= 400 && status < 500) {
      return ValidationFailure(message,
          code: code ?? 'CLIENT_ERROR', details: details);
    }

    return UnknownFailure(message, code: code, details: details);
  }
}
