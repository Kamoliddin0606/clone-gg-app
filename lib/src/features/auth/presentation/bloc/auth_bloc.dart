import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/entities/user_entity.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/network/api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/background_location_tracking_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';

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
    on<LogoutButtonPressed>(_onLogoutButtonPressed);
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

      // =========================================================================
      // REST API Token olish - Background services uchun kerak
      // =========================================================================
      await _obtainRestApiTokens(event.username, event.password);

      // =========================================================================
      // Background Location Tracking - login muvaffaqiyatli bo'lgandan keyin
      // joylashuvni kuzatishni boshlash
      // =========================================================================
      await _startBackgroundLocationTracking();

      emit(AuthSuccess(user: user));
    } catch (e) {
      // Categorize the error type
      AuthErrorType errorType;
      String message;

      if (e is ConnectivityException || e is AllServersUnavailableException) {
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
        print('Validating user data: saved username: ${_prefs.getSavedUsername()}, current user: ${user.username}');
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
        if (kDebugMode) {
          print('User data synced successfully after login validation');
        }
      } else {
        if (kDebugMode) {
          print('User data validation passed. No sync needed.');
        }
      }
    } catch (e) {
      // Log the error but don't fail the login process
      if (kDebugMode) {
        print('Error during user data validation and sync: $e');
      }
      // Continue with login success - validation is not critical for login
    }
  }

  /// Background location tracking'ni boshlash
  /// 
  /// Bu metod login muvaffaqiyatli bo'lgandan keyin chaqiriladi.
  /// Service'ni initialize qiladi va tracking'ni boshlaydi.
  /// Xato bo'lsa ham login jarayoni davom etadi.
  Future<void> _startBackgroundLocationTracking() async {
    try {
      if (kDebugMode) {
        print('AuthBloc: Starting background location tracking...');
      }

      final backgroundLocationService = sl<BackgroundLocationTrackingService>();
      
      // Service'ni initialize qilish (agar qilinmagan bo'lsa)
      await backgroundLocationService.initialize();
      
      // Tracking'ni boshlash
      final started = await backgroundLocationService.startTracking();
      
      if (kDebugMode) {
        if (started) {
          print('AuthBloc: Background location tracking started successfully');
          print('AuthBloc: Interval: ${backgroundLocationService.currentIntervalSeconds}s');
        } else {
          print('AuthBloc: Background location tracking could not be started');
        }
      }
    } catch (e) {
      // Log the error but don't fail the login process
      if (kDebugMode) {
        print('AuthBloc: Error starting background location tracking: $e');
      }
      // Continue with login success - tracking is not critical for login
    }
  }

  /// Logout event handler
  /// 
  /// Bu metod foydalanuvchi tizimdan chiqqanda chaqiriladi.
  /// Background location tracking to'xtatiladi va user ma'lumotlari tozalanadi.
  Future<void> _onLogoutButtonPressed(
    LogoutButtonPressed event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      if (kDebugMode) {
        print('AuthBloc: Logout started...');
      }

      // =========================================================================
      // 1. Background Location Tracking'ni to'xtatish
      // =========================================================================
      await _stopBackgroundLocationTracking();

      // =========================================================================
      // 2. User ma'lumotlarini tozalash
      // =========================================================================
      // Clear user code from preferences
      await _prefs.clearUserData();

      if (kDebugMode) {
        print('AuthBloc: User data cleared');
      }

      // =========================================================================
      // 3. Logout state'ini emit qilish
      // =========================================================================
      emit(const LogoutSuccess());

      if (kDebugMode) {
        print('AuthBloc: Logout completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthBloc: Logout error: $e');
      }
      // Xato bo'lsa ham logout qilish
      emit(const LogoutSuccess());
    }
  }

  /// REST API tokenlarini olish
  /// 
  /// Bu metod login muvaffaqiyatli bo'lgandan keyin chaqiriladi.
  /// 1C-Login endpointi orqali access va refresh tokenlarni oladi.
  /// BackgroundLocationTrackingService va boshqa REST API servislar uchun kerak.
  Future<void> _obtainRestApiTokens(String username, String password) async {
    try {
      if (kDebugMode) {
        print('AuthBloc: Obtaining REST API tokens via 1C-Login...');
      }

      final tokenService = sl<TokenService>();
      
      // 1C-Login orqali tokenlarni olish
      final success = await tokenService.authenticateWith1CLogin(
        login: username,
        password: password,
      );
      
      if (kDebugMode) {
        if (success) {
          print('AuthBloc: REST API tokens obtained successfully');
        } else {
          print('AuthBloc: Failed to obtain REST API tokens (non-critical)');
        }
      }
    } catch (e) {
      // Log the error but don't fail the login process
      if (kDebugMode) {
        print('AuthBloc: Error obtaining REST API tokens: $e');
      }
      // Continue with login success - REST API tokens are not critical for basic login
    }
  }

  /// Background location tracking'ni to'xtatish
  /// 
  /// Bu metod logout paytida chaqiriladi.
  /// Tracking to'xtatiladi va resurslar tozalanadi.
  Future<void> _stopBackgroundLocationTracking() async {
    try {
      if (kDebugMode) {
        print('AuthBloc: Stopping background location tracking...');
      }

      final backgroundLocationService = sl<BackgroundLocationTrackingService>();
      
      // Tracking'ni to'xtatish
      await backgroundLocationService.stopTracking();
      
      // Service'ni tozalash
      await backgroundLocationService.dispose();
      
      if (kDebugMode) {
        print('AuthBloc: Background location tracking stopped successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthBloc: Error stopping background location tracking: $e');
      }
      // Xato bo'lsa ham logout jarayoni davom etadi
    }
  }
}