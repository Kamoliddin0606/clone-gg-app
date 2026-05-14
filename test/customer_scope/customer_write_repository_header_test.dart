import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/project_context.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_project.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/customer_write_repository.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/login_gates_envelope.dart';

import 'customer_write_repository_header_test.mocks.dart';

@GenerateMocks([Dio, TokenService, SharedPreferencesService, ApiDatabaseService])
/// Integration tests for `X-Project-Id` header injection in
/// [CustomerWriteRepository]. Mocks Dio + Token + Prefs so we can
/// inspect the request headers without hitting any server.
void main() {
  late MockDio dio;
  late MockTokenService tokenService;
  late MockSharedPreferencesService prefs;
  late MockApiDatabaseService db;
  late ProjectContext projectContext;
  late CustomerWriteRepository repo;

  LoginGatesEnvelope gates({
    required CustomerScope scope,
    String? primaryProjectId,
  }) =>
      LoginGatesEnvelope(
        accessToken: 'a',
        refreshToken: 'r',
        userActiveEnd: null,
        licenseValidTo: null,
        organizationId: 'org',
        serverTime: DateTime.utc(2026, 5, 14),
        bypass: false,
        customerScope: scope,
        primaryProjectId: primaryProjectId,
        customerScopeProvided: true,
      );

  setUp(() async {
    dio = MockDio();
    tokenService = MockTokenService();
    prefs = MockSharedPreferencesService();
    db = MockApiDatabaseService();

    when(tokenService.ensureValidV2Token()).thenAnswer((_) async => 'bearer');
    when(prefs.setActiveProjectId(any))
        .thenAnswer((_) async => Future<void>.value());
    when(prefs.setActiveProjectSource(any))
        .thenAnswer((_) async => Future<void>.value());
    when(prefs.clearActiveProjectMeta())
        .thenAnswer((_) async => Future<void>.value());
    when(db.clearCustomerCacheForProjectSwitch())
        .thenAnswer((_) async => Future<void>.value());

    projectContext = ProjectContext(prefs, db);
    repo = CustomerWriteRepository(
      dio: dio,
      tokenService: tokenService,
      prefs: prefs,
      projectContext: projectContext,
    );

    // Register repo dependencies on GetIt — required by the repository's
    // permission-denied path. We never trigger it in these tests, but
    // GetIt lookups must still succeed.
    if (!GetIt.I.isRegistered<SharedPreferencesService>()) {
      GetIt.I.registerSingleton<SharedPreferencesService>(prefs);
    }
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Future<TradingPointResponse> successfulResponse() async {
    return TradingPointResponse(
      requestOptions: RequestOptions(path: '/'),
      statusCode: 201,
      data: <String, dynamic>{
        'id': 'uuid-customer',
        'code': 'C-AB12CD34',
        'code_1c': '',
        'status': 'pending_1c',
        'name': 'Test',
        'latitude': '40.000000',
        'longitude': '70.000000',
      },
    );
  }

  group('updateCoordinates header injection', () {
    test('omits X-Project-Id under customer_scope=organization', () async {
      when(prefs.getCachedGates())
          .thenReturn(gates(scope: CustomerScope.organization));
      when(dio.patch<dynamic>(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => await successfulResponse());

      await repo.updateCoordinates(
        customerId: 'cust-1',
        latitude: 41.0,
        longitude: 69.0,
      );

      final captured = verify(dio.patch<dynamic>(
        any,
        data: anyNamed('data'),
        options: captureAnyNamed('options'),
      )).captured.single as Options;
      final headers = captured.headers!.cast<String, dynamic>();

      expect(headers.containsKey('X-Project-Id'), isFalse);
      expect(headers['Authorization'], 'Bearer bearer');
    });

    test('attaches X-Project-Id when scope=project + active set', () async {
      when(prefs.getCachedGates())
          .thenReturn(gates(scope: CustomerScope.project));
      await projectContext.setActiveProject(UserProject(
        userCode: 'U-001',
        code: 'PRJ',
        name: 'P',
        idUuid: 'pid-uuid',
      ));
      when(dio.patch<dynamic>(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => await successfulResponse());

      await repo.updateCoordinates(
        customerId: 'cust-1',
        latitude: 41.0,
        longitude: 69.0,
      );

      final captured = verify(dio.patch<dynamic>(
        any,
        data: anyNamed('data'),
        options: captureAnyNamed('options'),
      )).captured.single as Options;
      final headers = captured.headers!.cast<String, dynamic>();

      expect(headers['X-Project-Id'], 'pid-uuid');
    });

    test(
      'throws customer_project_required when scope=project but no active project',
      () async {
        when(prefs.getCachedGates())
            .thenReturn(gates(scope: CustomerScope.project));
        // No setActiveProject call → activeProjectHeaderValue is null.

        await expectLater(
          repo.updateCoordinates(
            customerId: 'cust-1',
            latitude: 41.0,
            longitude: 69.0,
          ),
          throwsA(
            isA<CustomerWriteException>().having(
              (e) => e.code,
              'code',
              'customer_project_required',
            ),
          ),
        );
        verifyNever(dio.patch<dynamic>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
        ));
      },
    );

    test(
      'falls back to id1c when idUuid is missing on UserProject',
      () async {
        when(prefs.getCachedGates())
            .thenReturn(gates(scope: CustomerScope.project));
        await projectContext.setActiveProject(UserProject(
          userCode: 'U-001',
          code: 'PRJ',
          name: 'P',
          id1c: '00-0042',
        ));
        when(dio.patch<dynamic>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => await successfulResponse());

        await repo.updateCoordinates(
          customerId: 'cust-1',
          latitude: 41.0,
          longitude: 69.0,
        );

        final captured = verify(dio.patch<dynamic>(
          any,
          data: anyNamed('data'),
          options: captureAnyNamed('options'),
        )).captured.single as Options;

        expect(
          captured.headers!['X-Project-Id'],
          '00-0042',
        );
      },
    );
  });
}

typedef TradingPointResponse = Response<dynamic>;
