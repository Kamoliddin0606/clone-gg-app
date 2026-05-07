import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/background_location_tracking_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/login_device_payload_builder.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/auth_failure.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/login_device_payload.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/entities/user_entity.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

// Generate mocks
@GenerateMocks([
  AuthRepository,
  DataSyncService,
  SharedPreferencesService,
])
import 'auth_validation_test.mocks.dart';

// Minimal fakes so the bloc's pre-flight V2 step succeeds during these
// tests. AuthBloc internally fetches these from `GetIt.instance` so we
// must register them — without them every login is treated as a V2
// transport error and the SOAP path under test never runs.
class _FakeTokenService extends Fake implements TokenService {
  @override
  Future<bool> obtainV2Tokens({
    required String login,
    required String password,
    LoginDevicePayload? device,
  }) async => true;

  @override
  AuthFailure? get lastV2LoginFailure => null;
}

class _FakeLoginDevicePayloadBuilder extends Fake
    implements LoginDevicePayloadBuilder {
  @override
  Future<LoginDevicePayload> build({bool forceRebuild = false}) async {
    return const LoginDevicePayload(
      clientType: 'mobile',
      appInstanceId: 'fake',
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

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;
  late MockDataSyncService mockDataSyncService;
  late MockSharedPreferencesService mockPrefs;

  final sl = GetIt.instance;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockDataSyncService = MockDataSyncService();
    mockPrefs = MockSharedPreferencesService();

    if (sl.isRegistered<TokenService>()) sl.unregister<TokenService>();
    if (sl.isRegistered<LoginDevicePayloadBuilder>()) {
      sl.unregister<LoginDevicePayloadBuilder>();
    }
    if (sl.isRegistered<BackgroundLocationTrackingService>()) {
      sl.unregister<BackgroundLocationTrackingService>();
    }
    sl.registerSingleton<TokenService>(_FakeTokenService());
    sl.registerSingleton<LoginDevicePayloadBuilder>(
      _FakeLoginDevicePayloadBuilder(),
    );
    sl.registerSingleton<BackgroundLocationTrackingService>(
      _FakeBackgroundLocationTrackingService(),
    );

    // Default stub: bloc only reads getSavedUsername in a debug print.
    when(mockPrefs.getSavedUsername()).thenReturn(null);

    authBloc = AuthBloc(
      authRepository: mockAuthRepository,
      dataSyncService: mockDataSyncService,
      prefs: mockPrefs,
    );
  });

  tearDown(() {
    authBloc.close();
    if (sl.isRegistered<TokenService>()) sl.unregister<TokenService>();
    if (sl.isRegistered<LoginDevicePayloadBuilder>()) {
      sl.unregister<LoginDevicePayloadBuilder>();
    }
    if (sl.isRegistered<BackgroundLocationTrackingService>()) {
      sl.unregister<BackgroundLocationTrackingService>();
    }
  });

  group('AuthBloc User Validation Tests', () {
    final testUser = UserEntity(
      id: 'test_id',
      username: 'testuser',
      fullName: 'Test User',
      role: 'Agent',
      code: '001',
      name: 'Test User',
      warehouseCode: 'W001',
      codeProject: 'P001',
      baseUrl: 'http://test.com',
      telegramID: '123',
      chatID: '456',
      topicID: '789',
    );

    test('should validate user data and sync when validation fails', () async {
      // Arrange
      when(mockAuthRepository.establish1cSession(
        username: 'testuser',
        password: 'password',
      )).thenAnswer((_) async => testUser);

      when(mockDataSyncService.validateUserWithDatabase())
          .thenAnswer((_) async => false); // Validation fails

      when(mockDataSyncService.clearAllCachedData())
          .thenAnswer((_) async => Future.value());

      when(mockDataSyncService.syncUserDataWithDatabase())
          .thenAnswer((_) async => Future.value());

      when(mockDataSyncService.syncAllUserData(
        userCode: testUser.code,
        password: '',
        codeProject: testUser.codeProject,
        codeSklad: testUser.warehouseCode,
      )).thenAnswer((_) async => Future.value());

      // Act
      authBloc.add(LoginButtonPressed(
        username: 'testuser',
        password: 'password',
      ));

      // Assert
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          AuthLoading(),
          AuthSuccess(user: testUser),
        ]),
      );

      verify(mockDataSyncService.validateUserWithDatabase()).called(1);
      verify(mockDataSyncService.clearAllCachedData()).called(1);
      verify(mockDataSyncService.syncUserDataWithDatabase()).called(1);
      verify(mockDataSyncService.syncAllUserData(
        userCode: testUser.code,
        password: '',
        codeProject: testUser.codeProject,
        codeSklad: testUser.warehouseCode,
      )).called(1);
    });

    test('should skip sync when user validation passes', () async {
      // Arrange
      when(mockAuthRepository.establish1cSession(
        username: 'testuser',
        password: 'password',
      )).thenAnswer((_) async => testUser);

      when(mockDataSyncService.validateUserWithDatabase())
          .thenAnswer((_) async => true); // Validation passes

      when(mockDataSyncService.syncAllUserData(
        userCode: testUser.code,
        password: '',
        codeProject: testUser.codeProject,
        codeSklad: testUser.warehouseCode,
      )).thenAnswer((_) async => Future.value());

      // Act
      authBloc.add(LoginButtonPressed(
        username: 'testuser',
        password: 'password',
      ));

      // Assert
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          AuthLoading(),
          AuthSuccess(user: testUser),
        ]),
      );

      verify(mockDataSyncService.validateUserWithDatabase()).called(1);
      verifyNever(mockDataSyncService.clearAllCachedData());
      verifyNever(mockDataSyncService.syncUserDataWithDatabase());
      verify(mockDataSyncService.syncAllUserData(
        userCode: testUser.code,
        password: '',
        codeProject: testUser.codeProject,
        codeSklad: testUser.warehouseCode,
      )).called(1);
    });

    test('should continue login on sync error', () async {
      // Arrange
      when(mockAuthRepository.establish1cSession(
        username: 'testuser',
        password: 'password',
      )).thenAnswer((_) async => testUser);

      when(mockDataSyncService.validateUserWithDatabase())
          .thenAnswer((_) async => false);

      when(mockDataSyncService.clearAllCachedData())
          .thenThrow(Exception('Sync error'));

      // Act
      authBloc.add(LoginButtonPressed(
        username: 'testuser',
        password: 'password',
      ));

      // Assert
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          AuthLoading(),
          AuthSuccess(user: testUser),
        ]),
      );

      verify(mockDataSyncService.validateUserWithDatabase()).called(1);
      verify(mockDataSyncService.clearAllCachedData()).called(1);
    });

    test('should handle authentication error', () async {
      // Arrange
      when(mockAuthRepository.establish1cSession(
        username: 'testuser',
        password: 'wrongpassword',
      )).thenThrow(Exception('Invalid credentials'));

      // Act
      authBloc.add(LoginButtonPressed(
        username: 'testuser',
        password: 'wrongpassword',
      ));

      // Assert
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          AuthLoading(),
          predicate<AuthState>((state) =>
              state is AuthFailureState &&
              state.errorType == AuthErrorType.unknown),
        ]),
      );

      verifyNever(mockDataSyncService.validateUserWithDatabase());
    });
  });
}