part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginButtonPressed extends AuthEvent {
  final String username;
  final String password;

  const LoginButtonPressed({
    required this.username,
    required this.password,
  });

  @override
  List<Object> get props => [username, password];
}

/// Logout event - foydalanuvchi tizimdan chiqish
/// 
/// Bu event chaqirilganda:
/// 1. Background location tracking to'xtatiladi
/// 2. User ma'lumotlari tozalanadi
/// 3. Login sahifasiga yo'naltiriladi
class LogoutButtonPressed extends AuthEvent {
  const LogoutButtonPressed();
}