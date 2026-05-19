import 'package:equatable/equatable.dart';

/// Domain-level failure surface. UI layers switch on subtype; the data layer
/// (Dio interceptors) produces them from HTTP responses / network errors.
sealed class Failure extends Equatable {
  const Failure(this.message, {this.code, this.details});

  final String message;

  /// Wire code from `error.code` (`VISITS_GEOFENCE_VIOLATION`, etc.) when the
  /// failure originated from the server's error envelope.
  final String? code;

  final Map<String, dynamic>? details;

  @override
  List<Object?> get props => [runtimeType, message, code, details];
}

class GeofenceFailure extends Failure {
  const GeofenceFailure(super.message, {super.code, super.details});
}

class ClockDriftFailure extends Failure {
  const ClockDriftFailure(super.message, {super.code, super.details});
}

class PhotoMissingFailure extends Failure {
  const PhotoMissingFailure(super.message, {super.code, super.details});
}

class IdempotencyMismatchFailure extends Failure {
  const IdempotencyMismatchFailure(super.message,
      {super.code, super.details});
}

class VisitConflictFailure extends Failure {
  const VisitConflictFailure(super.message, {super.code, super.details});
}

class NetworkFailure extends Failure {
  const NetworkFailure(
    super.message, {
    super.code,
    super.details,
    this.transient = true,
  });

  /// `true` for timeouts / 5xx / connectivity loss — outbox retries; `false`
  /// would mean unrecoverable transport error.
  final bool transient;

  @override
  List<Object?> get props => [...super.props, transient];
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code, super.details});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code, super.details});
}

class SecurityFailure extends Failure {
  const SecurityFailure(super.message, {super.code, super.details});
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code, super.details});
}
