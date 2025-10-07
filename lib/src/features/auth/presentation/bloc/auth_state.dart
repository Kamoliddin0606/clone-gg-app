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

class AuthFailure extends AuthState {
  final String message;
  final AuthErrorType errorType;

  const AuthFailure({
    required this.message,
    this.errorType = AuthErrorType.unknown,
  });

  @override
  List<Object> get props => [message, errorType];
}