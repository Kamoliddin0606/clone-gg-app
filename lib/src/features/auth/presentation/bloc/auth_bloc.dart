import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/entities/user_entity.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/network/api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final DataSyncService dataSyncService;
  final SharedPreferencesService _prefs;

  AuthBloc({
    required this.authRepository,
    required this.dataSyncService,
    required SharedPreferencesService prefs,
  }) : _prefs = prefs,
        super(AuthInitial()) {
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

      // Validate user data with database after successful login
      await _validateAndSyncUserData(user);

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

  /// Validate user data with database and sync if necessary
  Future<void> _validateAndSyncUserData(UserEntity user) async {
    try {
      if (kDebugMode) {
        print('Validating user data with database after login...');
      }

      // Check if preferences user data matches database user table first row
      final isValid = await dataSyncService.validateUserWithDatabase();

      if (!isValid) {
        if (kDebugMode) {
          print('User data validation failed. Clearing database and syncing user data...');
        }

        // Clear all user-related data from database
        await dataSyncService.clearAllCachedData();

        // Sync user data with database
        await dataSyncService.syncUserDataWithDatabase();

        if (kDebugMode) {
          print('User data synced successfully after login validation');
        }
      } else {
        if (kDebugMode) {
          print('User data validation passed. No sync needed.');
        }
      }

      // Send syncAllUserData command to server
      try {
        await dataSyncService.syncAllUserData(
          userCode: user.code,
          password: '', // Password not stored for security
          codeProject: user.codeProject,
          codeSklad: user.warehouseCode,
        );

        if (kDebugMode) {
          print('syncAllUserData command sent to server successfully');
        }
      } catch (syncError) {
        // Log the error but don't fail the login process
        if (kDebugMode) {
          print('Error during syncAllUserData: $syncError');
        }
        // Continue with login success
      }

    } catch (e) {
      // Log the error but don't fail the login process
      if (kDebugMode) {
        print('Error during user data validation and sync: $e');
      }
      // Continue with login success - validation is not critical for login
    }
  }
}