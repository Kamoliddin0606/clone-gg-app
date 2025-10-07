import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/entities/user_entity.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/network/api_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final DataSyncService dataSyncService;

  AuthBloc({
    required this.authRepository,
    required this.dataSyncService,
  }) : super(AuthInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
  }

  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.login(
        username: event.username,
        password: event.password,
      );

      emit(AuthSuccess(user: user));
    } catch (e) {
      // Categorize the error type
      AuthErrorType errorType;
      String message;

      if (e is ConnectivityException) {
        errorType = AuthErrorType.connectivity;
        message = 'Internet bilan bog\'lanishda xatolik. Iltimos, internetni tekshiring.';
      } else if (e is ServerException) {
        errorType = AuthErrorType.server;
        message = 'Server xatoligi. Iltimos, keyinroq urinib ko\'ring.';
      } else if (e.toString().contains('CodeError') || e.toString().contains('login error')) {
        errorType = AuthErrorType.authentication;
        message = 'Login yoki parol xato. Iltimos, tekshirib qayta kiriting.';
      } else {
        errorType = AuthErrorType.unknown;
        message = e.toString();
      }

      emit(AuthFailure(message: message, errorType: errorType));
    }
  }
}