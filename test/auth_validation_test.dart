import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
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

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;
  late MockDataSyncService mockDataSyncService;
  late MockSharedPreferencesService mockPrefs;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockDataSyncService = MockDataSyncService();
    mockPrefs = MockSharedPreferencesService();

    authBloc = AuthBloc(
      authRepository: mockAuthRepository,
      dataSyncService: mockDataSyncService,
      prefs: mockPrefs,
    );
  });

  tearDown(() {
    authBloc.close();
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
      when(mockAuthRepository.login(
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
      when(mockAuthRepository.login(
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
      when(mockAuthRepository.login(
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
      when(mockAuthRepository.login(
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
              state is AuthFailure &&
              state.errorType == AuthErrorType.unknown),
        ]),
      );

      verifyNever(mockDataSyncService.validateUserWithDatabase());
    });
  });
}