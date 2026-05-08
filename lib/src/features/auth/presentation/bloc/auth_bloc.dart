import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gloria_marketing_flutter/src/core/exceptions/auth_exceptions.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/entities/user_entity.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/network/api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/background_location_tracking_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/login_device_payload_builder.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/auth_failure.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/login_device_payload.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Outcome of the V2 JWT login attempt. Lets the bloc tell apart a server
/// denial (block the user with a localized banner) from a transport error
/// (offer Retry — never silently fall back to legacy SOAP).
enum V2LoginOutcome { success, serverDenied, transportError }

/// Pair of [V2LoginOutcome] + the typed [AuthFailure] that produced it.
/// Carries the failure even on `transportError` for diagnostics.
class V2LoginResult {
  final V2LoginOutcome outcome;
  final AuthFailure? failure;
  const V2LoginResult(this.outcome, [this.failure]);
}

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
      // ========================================================================
      // V2 JWT is the single source of truth for authentication.
      // - success       → continue to 1C session warm-up.
      // - serverDenied  → emit a typed AuthFailureState; STOP. Includes
      //                   license / seat / window / inactive / device-binding.
      // - transportError → emit NetworkFailure; STOP. We never silently fall
      //                   back to legacy SOAP — that bypasses the backend's
      //                   device-binding rule.
      // ========================================================================
      final v2 = await _obtainV2Tokens(event.username, event.password);
      switch (v2.outcome) {
        case V2LoginOutcome.serverDenied:
          final failure = v2.failure ?? const UnknownAuthFailure();
          emit(AuthFailureState(
            message: _legacyMessageFor(failure),
            errorType: AuthErrorType.authentication,
            failure: failure,
          ));
          return;
        case V2LoginOutcome.transportError:
          const failure = NetworkFailure();
          emit(AuthFailureState(
            message: _legacyMessageFor(failure),
            errorType: AuthErrorType.connectivity,
            failure: failure,
          ));
          return;
        case V2LoginOutcome.success:
          break;
      }

      // V2 succeeded — establish the 1C SOAP session for downstream
      // business calls (KPI / products / prices / orders). This is NOT
      // an authentication step.
      final UserEntity user;
      try {
        user = await authRepository.establish1cSession(
          username: event.username,
          password: event.password,
        );
      } on OneCUserNotFoundException {
        const failure = OneCUserNotFoundFailure();
        emit(AuthFailureState(
          message: _legacyMessageFor(failure),
          errorType: AuthErrorType.authentication,
          failure: failure,
        ));
        return;
      }

      // Validate user data with database after successful login
      await _validateAndSyncUserData(user);

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

      emit(AuthFailureState(message: message, errorType: errorType));
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
      // 2. V2 (yangi server) tokenlarini va kesh ma'lumotlarini tozalash.
      //    Eski REST tokenlar boshqa servislar tomonidan boshqariladi va bu
      //    yerda tegmaydi. Cache coherence: gates, device binding, va tokenlar
      //    har doim birga tozalanadi — biri ikkinchisisiz qolmasin.
      // =========================================================================
      try {
        await sl<TokenService>().clearV2Tokens();
        await _prefs.clearCachedGates();
        await _prefs.clearCachedDeviceBinding();
      } catch (e) {
        if (kDebugMode) {
          print('AuthBloc: Error clearing V2 caches (non-critical): $e');
        }
      }

      // =========================================================================
      // 3. User ma'lumotlarini tozalash
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

  /// V1 1C-Login is removed. Kept as a stub so any future re-introduction
  /// has a single place to revisit. Does NOT make any network calls.
  // ignore: unused_element
  Future<void> _obtainRestApiTokens(String username, String password) async {
  }

  /// Fallback non-localized message used in the legacy `state.message`
  /// field when emitting [AuthFailureState] for a typed [AuthFailure].
  /// The UI prefers the localized rendering via `state.failure.messageKey`,
  /// so this is only shown when localization is unavailable.
  String _legacyMessageFor(AuthFailure failure) {
    switch (failure) {
      case InvalidCredentialsFailure():
        return 'Login yoki parol noto\'g\'ri.';
      case UserInactiveFailure():
        return 'Hisobingiz nofaol.';
      case UserOutsideActiveWindowFailure():
        return 'Ruxsat oynasi tashqarisida.';
      case LicenseMissingFailure():
        return 'Tashkilotda faol litsenziya yo\'q.';
      case LicenseExpiredFailure():
        return 'Tashkilot litsenziyasi muddati o\'tgan.';
      case LicenseSeatExceededFailure():
        return 'Litsenziya o\'rinlari to\'la.';
      case NetworkFailure():
        return 'Server bilan bog\'lanib bo\'lmadi.';
      case UnknownAuthFailure():
        return 'Server xatoligi. Qayta urinib ko\'ring yoki administratorga murojaat qiling.';
      case MobileDeviceBoundToOtherUserFailure():
        return 'Bu qurilma boshqa foydalanuvchiga biriktirilgan.';
      case MobileUserBoundToOtherDeviceFailure():
        return 'Sizning hisobingiz boshqa qurilmaga biriktirilgan.';
      case DeviceBindingInvalidFailure():
        return 'Qurilma sessiyasi endi yaroqsiz. Qaytadan kiring.';
      case SessionRevokedFailure():
        return 'Sessiyangiz to\'xtatildi. Qaytadan kiring.';
      case OneCUserNotFoundFailure():
        return 'Bu hisob operatsion tizimda ro\'yxatdan o\'tmagan. Administratorga murojaat qiling.';
    }
  }

  /// Obtain JWT tokens from the V2 backend (`POST /api/auth/token/`).
  ///
  /// Returns a [V2LoginResult] with explicit outcome — the caller MUST
  /// branch on it. A `transportError` outcome blocks the login (no SOAP
  /// fallback) so the backend's device-binding rule cannot be bypassed
  /// by an offline client.
  Future<V2LoginResult> _obtainV2Tokens(String username, String password) async {
    try {
      if (kDebugMode) {
        print('AuthBloc: Obtaining V2 (new server) tokens...');
      }
      final tokenService = sl<TokenService>();

      // Build the device-binding payload. Failure-tolerant: if any
      // plugin throws (rare), we send the request without the block —
      // Stage 1 of the rollout still accepts device-less logins.
      LoginDevicePayload? device;
      try {
        device = await sl<LoginDevicePayloadBuilder>().build();
      } catch (e) {
        if (kDebugMode) {
          print('AuthBloc: device payload build failed (non-fatal): $e');
        }
      }

      final ok = await tokenService.obtainV2Tokens(
        login: username,
        password: password,
        device: device,
      );
      if (ok) {
        if (kDebugMode) print('AuthBloc: V2 tokens obtained successfully');
        return const V2LoginResult(V2LoginOutcome.success);
      }

      final failure = tokenService.lastV2LoginFailure;
      // Only `NetworkFailure` (no HTTP response at all) is a true
      // transport error. `UnknownAuthFailure` carries an HTTP response
      // body the backend produced — even if we don't recognise the
      // `error.code`, the server reached us. Routing it through
      // `transportError` would mask a credentials/permission denial
      // behind the generic "no internet" banner. Surface it as
      // `serverDenied` so the UI shows the typed failure instead.
      if (failure is NetworkFailure) {
        if (kDebugMode) {
          print('AuthBloc: V2 transport failure — login blocked, '
              'no SOAP fallback (failure=NetworkFailure)');
        }
        return V2LoginResult(V2LoginOutcome.transportError, failure);
      }
      if (failure != null) {
        if (kDebugMode) {
          print('AuthBloc: V2 server denial: ${failure.runtimeType} '
              '${failure is UnknownAuthFailure ? "(rawCode=${failure.rawCode}) " : ""}'
              '→ blocking login');
        }
        return V2LoginResult(V2LoginOutcome.serverDenied, failure);
      }
      // No typed failure available (V2 returned false without setting
      // `lastV2LoginFailure`). This is genuinely unknown territory —
      // treat as transport so the user can retry rather than seeing a
      // misleading "credentials wrong" message.
      if (kDebugMode) {
        print('AuthBloc: V2 returned false but no typed failure — '
            'classifying as transport error');
      }
      return const V2LoginResult(V2LoginOutcome.transportError);
    } catch (e) {
      if (kDebugMode) {
        print('AuthBloc: Error obtaining V2 tokens (transport error): $e');
      }
      return const V2LoginResult(V2LoginOutcome.transportError);
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