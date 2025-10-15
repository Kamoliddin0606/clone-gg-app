import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/pages/login_page.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/entities/user_entity.dart';

// Mock classes
class MockSharedPreferencesService extends Mock implements SharedPreferencesService {}
class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockDataSyncService extends Mock implements DataSyncService {}

void main() {
  late MockSharedPreferencesService mockPrefs;
  late MockDatabaseHelper mockDbHelper;
  late MockDataSyncService mockDataSyncService;

  setUp(() {
    mockPrefs = MockSharedPreferencesService();
    mockDbHelper = MockDatabaseHelper();
    mockDataSyncService = MockDataSyncService();

    // Setup service locator mocks
    sl.registerSingleton<SharedPreferencesService>(mockPrefs);
    sl.registerSingleton<DatabaseHelper>(mockDbHelper);
    sl.registerSingleton<DataSyncService>(mockDataSyncService);
  });

  tearDown(() {
    sl.reset();
  });

  group('LoginPage Data Sync Tests', () {
    testWidgets('should show data sync dialog when user data does not match',
        (WidgetTester tester) async {
      // Arrange
      final user = UserEntity(
        id: '001',
        username: 'testuser',
        fullName: 'Test User',
        role: 'Agent',
        code: '001',
        name: 'Test User',
        warehouseCode: 'W001',
        codeProject: 'P001',
        baseUrl: 'http://test.com',
        telegramID: '',
        chatID: '',
        topicID: '',
      );

      // Mock database returns different user data
      when(mockDbHelper.getUserByCode('001')).thenAnswer((_) async => {
        'code': '001',
        'name': 'Old User',
        'warehouse_code': 'W002',
        'code_project': 'P002',
        'base_url': 'http://old.com',
      });

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => AuthBloc(
              authRepository: MockAuthRepository(),
              dataSyncService: mockDataSyncService,
              prefs: mockPrefs,
            ),
            child: const LoginPage(),
          ),
        ),
      );

      // Trigger login success
      final authBloc = BlocProvider.of<AuthBloc>(tester.element(find.byType(LoginPage)));
      authBloc.emit(AuthSuccess(user: user));

      await tester.pump();

      // Assert
      expect(find.text('Ma\'lumotlar yangilanmoqda...'), findsOneWidget);
      verify(mockDataSyncService.syncAllUserDataWithProgress(
        userCode: '001',
        password: '',
        codeProject: 'P001',
        codeSklad: 'W001',
      )).called(1);
    });

    testWidgets('should not show data sync dialog when user data matches',
        (WidgetTester tester) async {
      // Arrange
      final user = UserEntity(
        id: '001',
        username: 'testuser',
        fullName: 'Test User',
        role: 'Agent',
        code: '001',
        name: 'Test User',
        warehouseCode: 'W001',
        codeProject: 'P001',
        baseUrl: 'http://test.com',
        telegramID: '',
        chatID: '',
        topicID: '',
      );

      // Mock database returns matching user data
      when(mockDbHelper.getUserByCode('001')).thenAnswer((_) async => {
        'code': '001',
        'name': 'Test User',
        'warehouse_code': 'W001',
        'code_project': 'P001',
        'base_url': 'http://test.com',
      });

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => AuthBloc(
              authRepository: MockAuthRepository(),
              dataSyncService: mockDataSyncService,
              prefs: mockPrefs,
            ),
            child: const LoginPage(),
          ),
        ),
      );

      // Trigger login success
      final authBloc = BlocProvider.of<AuthBloc>(tester.element(find.byType(LoginPage)));
      authBloc.emit(AuthSuccess(user: user));

      await tester.pump();

      // Assert
      expect(find.text('Ma\'lumotlar yangilanmoqda...'), findsNothing);
      verifyNever(mockDataSyncService.syncAllUserDataWithProgress(
        userCode: anyNamed('userCode'),
        password: anyNamed('password'),
        codeProject: anyNamed('codeProject'),
        codeSklad: anyNamed('codeSklad'),
      ));
    });

    testWidgets('should show data sync dialog when no user in database',
        (WidgetTester tester) async {
      // Arrange
      final user = UserEntity(
        id: '001',
        username: 'testuser',
        fullName: 'Test User',
        role: 'Agent',
        code: '001',
        name: 'Test User',
        warehouseCode: 'W001',
        codeProject: 'P001',
        baseUrl: 'http://test.com',
        telegramID: '',
        chatID: '',
        topicID: '',
      );

      // Mock database returns null (no user)
      when(mockDbHelper.getUserByCode('001')).thenAnswer((_) async => null);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => AuthBloc(
              authRepository: MockAuthRepository(),
              dataSyncService: mockDataSyncService,
              prefs: mockPrefs,
            ),
            child: const LoginPage(),
          ),
        ),
      );

      // Trigger login success
      final authBloc = BlocProvider.of<AuthBloc>(tester.element(find.byType(LoginPage)));
      authBloc.emit(AuthSuccess(user: user));

      await tester.pump();

      // Assert
      expect(find.text('Ma\'lumotlar yangilanmoqda...'), findsOneWidget);
      verify(mockDataSyncService.syncAllUserDataWithProgress(
        userCode: '001',
        password: '',
        codeProject: 'P001',
        codeSklad: 'W001',
      )).called(1);
    });
  });
}

// Mock AuthRepository for testing
class MockAuthRepository extends Mock {
  @override
  Future<UserEntity> login({required String username, required String password}) async {
    return UserEntity(
      id: '001',
      username: username,
      fullName: 'Test User',
      role: 'Agent',
      code: '001',
      name: 'Test User',
      warehouseCode: 'W001',
      codeProject: 'P001',
      baseUrl: 'http://test.com',
      telegramID: '',
      chatID: '',
      topicID: '',
    );
  }
}