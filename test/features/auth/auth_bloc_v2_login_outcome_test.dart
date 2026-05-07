import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:gloria_marketing_flutter/src/core/services/background_location/background_location_tracking_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/login_device_payload_builder.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/auth_failure.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/login_device_payload.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/entities/user_entity.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/bloc/auth_bloc.dart';

class _FakeAuthRepository extends Fake implements AuthRepository {
  int establish1cCalls = 0;

  @override
  Future<UserEntity> establish1cSession({
    required String username,
    required String password,
    String? appVersion,
  }) async {
    establish1cCalls++;
    return UserEntity(
      id: 'id',
      username: username,
      fullName: '',
      role: 'Agent',
      code: '001',
      name: '',
      warehouseCode: 'W',
      codeProject: 'P',
      baseUrl: 'http://test',
      telegramID: '',
      chatID: '',
      topicID: '',
    );
  }
}

class _FakeTokenService extends Fake implements TokenService {
  bool ok = true;
  AuthFailure? failure;

  @override
  Future<bool> obtainV2Tokens({
    required String login,
    required String password,
    LoginDevicePayload? device,
  }) async => ok;

  @override
  AuthFailure? get lastV2LoginFailure => failure;
}

class _FakeLoginDevicePayloadBuilder extends Fake
    implements LoginDevicePayloadBuilder {
  @override
  Future<LoginDevicePayload> build({bool forceRebuild = false}) async {
    return const LoginDevicePayload(
      clientType: 'mobile',
      appInstanceId: 'fake-uuid',
      platform: 'ios',
      deviceName: 'Fake',
      osVersion: 'iOS 26',
      appVersion: '0.0.0',
    );
  }
}

class _FakeBackgroundLocationTrackingService extends Fake
    implements BackgroundLocationTrackingService {
  @override
  Future<bool> initialize() async => true;
  @override
  Future<bool> startTracking() async => true;
  @override
  Future<void> stopTracking() async {}
  @override
  Future<void> dispose() async {}
  @override
  int get currentIntervalSeconds => 0;
}

class _FakeSharedPreferencesService extends Fake
    implements SharedPreferencesService {
  @override
  String? getSavedUsername() => null;
}

class _FakeDataSyncService extends Fake implements DataSyncService {
  @override
  Future<bool> validateUserWithDatabase() async => true;
}

void main() {
  final sl = GetIt.instance;
  late _FakeAuthRepository fakeRepo;
  late _FakeTokenService fakeTokenService;
  late AuthBloc bloc;

  setUp(() {
    fakeRepo = _FakeAuthRepository();
    fakeTokenService = _FakeTokenService();

    if (sl.isRegistered<TokenService>()) sl.unregister<TokenService>();
    if (sl.isRegistered<LoginDevicePayloadBuilder>()) {
      sl.unregister<LoginDevicePayloadBuilder>();
    }
    if (sl.isRegistered<BackgroundLocationTrackingService>()) {
      sl.unregister<BackgroundLocationTrackingService>();
    }
    sl.registerSingleton<TokenService>(fakeTokenService);
    sl.registerSingleton<LoginDevicePayloadBuilder>(
      _FakeLoginDevicePayloadBuilder(),
    );
    sl.registerSingleton<BackgroundLocationTrackingService>(
      _FakeBackgroundLocationTrackingService(),
    );

    bloc = AuthBloc(
      authRepository: fakeRepo,
      dataSyncService: _FakeDataSyncService(),
      prefs: _FakeSharedPreferencesService(),
    );
  });

  tearDown(() async {
    await bloc.close();
    if (sl.isRegistered<TokenService>()) sl.unregister<TokenService>();
    if (sl.isRegistered<LoginDevicePayloadBuilder>()) {
      sl.unregister<LoginDevicePayloadBuilder>();
    }
    if (sl.isRegistered<BackgroundLocationTrackingService>()) {
      sl.unregister<BackgroundLocationTrackingService>();
    }
  });

  group('AuthBloc V2LoginOutcome', () {
    test('V2 transport error → AuthFailureState(NetworkFailure) AND '
        'establish1cSession is NEVER called', () async {
      fakeTokenService.ok = false;
      fakeTokenService.failure = const NetworkFailure();

      bloc.add(const LoginButtonPressed(username: 'u', password: 'p'));

      final emitted = <AuthState>[];
      final sub = bloc.stream.listen(emitted.add);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await sub.cancel();

      expect(emitted.first, isA<AuthLoading>());
      final failureState = emitted.last as AuthFailureState;
      expect(failureState.failure, isA<NetworkFailure>());
      expect(failureState.errorType, AuthErrorType.connectivity);

      // The critical invariant: SOAP must NOT run when V2 transport fails.
      expect(fakeRepo.establish1cCalls, 0,
          reason: 'SOAP fallback would bypass device-binding enforcement');
    });

    test('V2 server denial (423 user-bound-to-other-device) → '
        'AuthFailureState(MobileUserBoundToOtherDeviceFailure) AND '
        'establish1cSession is NEVER called', () async {
      fakeTokenService.ok = false;
      fakeTokenService.failure = const MobileUserBoundToOtherDeviceFailure();

      bloc.add(const LoginButtonPressed(username: 'u', password: 'p'));

      final emitted = <AuthState>[];
      final sub = bloc.stream.listen(emitted.add);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await sub.cancel();

      final failureState = emitted.last as AuthFailureState;
      expect(failureState.failure, isA<MobileUserBoundToOtherDeviceFailure>());
      expect(failureState.errorType, AuthErrorType.authentication);
      expect(fakeRepo.establish1cCalls, 0);
    });

    test('V2 success → establish1cSession runs exactly once', () async {
      fakeTokenService.ok = true;

      bloc.add(const LoginButtonPressed(username: 'u', password: 'p'));

      final emitted = <AuthState>[];
      final sub = bloc.stream.listen(emitted.add);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await sub.cancel();

      expect(fakeRepo.establish1cCalls, 1);
      expect(emitted.last, isA<AuthSuccess>());
    });
  });
}
