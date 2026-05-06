part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final UserEntity user;

  const AuthSuccess({required this.user});

  @override
  List<Object> get props => [user];
}

enum AuthErrorType {
  connectivity, // Network connection issues
  authentication, // Wrong credentials
  server, // Server errors
  unknown, // Other errors
}

/// Renamed from `AuthFailure` to avoid clashing with the new sealed
/// `AuthFailure` model under `data/models/auth_failure.dart`. The state
/// now also carries the typed [failure] (preferred over the legacy
/// [message]/[errorType] pair) so the UI can localize via `messageKey`.
class AuthFailureState extends AuthState {
  final String message;
  final AuthErrorType errorType;

  /// Typed backend failure when available. `null` for purely client-side
  /// errors (e.g. validation) where there is no `error.code` to map.
  final AuthFailure? failure;

  const AuthFailureState({
    required this.message,
    this.errorType = AuthErrorType.unknown,
    this.failure,
  });

  @override
  List<Object> get props => [message, errorType, failure ?? Object()];
}

/// Logout muvaffaqiyatli bo'lganda
class LogoutSuccess extends AuthState {
  const LogoutSuccess();
}