import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/project_context.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_project.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/login_gates_envelope.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/entities/user_entity.dart';

import 'project_context_test.mocks.dart';

@GenerateMocks([SharedPreferencesService, ApiDatabaseService])
/// Integration tests for [ProjectContext]: bootstrap, project switch,
/// scope reads from cached gates, and cache invalidation.
void main() {
  group('ProjectContext', () {
    late MockSharedPreferencesService prefs;
    late MockApiDatabaseService db;
    late ProjectContext context;

    UserEntity makeUser({String? primaryProjectId}) => UserEntity(
          id: 'user-id',
          username: 'alice',
          fullName: 'Alice',
          role: 'Agent',
          code: 'U-001',
          name: 'Alice',
          warehouseCode: 'WH-1',
          codeProject: '',
          baseUrl: '',
          telegramID: '',
          chatID: '',
          topicID: '',
          primaryProjectId: primaryProjectId,
        );

    LoginGatesEnvelope envelope({
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

    setUp(() {
      prefs = MockSharedPreferencesService();
      db = MockApiDatabaseService();
      // Default behaviour for unrelated calls — write methods are
      // covered by `Mockito.any` matchers in individual tests.
      when(prefs.setActiveProjectId(any))
          .thenAnswer((_) async => Future<void>.value());
      when(prefs.setActiveProjectSource(any))
          .thenAnswer((_) async => Future<void>.value());
      when(prefs.clearActiveProjectMeta())
          .thenAnswer((_) async => Future<void>.value());
      when(db.clearCustomerCacheForProjectSwitch())
          .thenAnswer((_) async => Future<void>.value());
      context = ProjectContext(prefs, db);
    });

    test('currentScope reads from cached gates (organization default)', () {
      when(prefs.getCachedGates()).thenReturn(null);

      expect(context.currentScope, CustomerScope.organization);
      expect(context.requiresProjectHeader, isFalse);
      expect(context.scopeKnown, isFalse);
    });

    test('currentScope reflects project scope from gates', () {
      when(prefs.getCachedGates()).thenReturn(
        envelope(scope: CustomerScope.project),
      );

      expect(context.currentScope, CustomerScope.project);
      expect(context.requiresProjectHeader, isTrue);
      expect(context.scopeKnown, isTrue);
    });

    test(
      'bootstrap on org-scope clears any stale active project meta',
      () async {
        when(prefs.getCachedGates()).thenReturn(
          envelope(scope: CustomerScope.organization),
        );

        await context.bootstrap(makeUser());

        verify(prefs.clearActiveProjectMeta()).called(1);
        expect(context.activeProject, isNull);
        expect(context.activeProjectHeaderValue, isNull);
      },
    );

    test(
      'bootstrap on project-scope auto-selects primary_project_id',
      () async {
        const primaryId = 'pid-primary';
        when(prefs.getCachedGates()).thenReturn(envelope(
          scope: CustomerScope.project,
          primaryProjectId: primaryId,
        ));
        when(prefs.getActiveProjectId()).thenReturn(null);
        when(db.getUserProjects('U-001')).thenAnswer((_) async => [
              UserProject(
                userCode: 'U-001',
                code: 'PRJ-A',
                name: 'Project A',
                idUuid: primaryId,
              ),
            ]);

        await context.bootstrap(makeUser(primaryProjectId: primaryId));

        expect(context.activeProject?.idUuid, primaryId);
        expect(context.activeProjectHeaderValue, primaryId);
        verify(prefs.setActiveProjectId(primaryId)).called(1);
      },
    );

    test(
      'bootstrap on project-scope with no resolvable id emits null',
      () async {
        when(prefs.getCachedGates()).thenReturn(envelope(
          scope: CustomerScope.project,
          primaryProjectId: null,
        ));
        when(prefs.getActiveProjectId()).thenReturn(null);
        when(db.getUserProjects(any)).thenAnswer((_) async => []);

        await context.bootstrap(makeUser());

        // Orchestrator (login page) reads this to decide whether to
        // force the picker. `null` is the signal to open it.
        expect(context.activeProjectHeaderValue, isNull);
        expect(context.activeProject, isNull);
      },
    );

    test(
      'setActiveProject wipes local customer cache on every actual switch',
      () async {
        final p1 = UserProject(
          userCode: 'U-001',
          code: 'A',
          name: 'A',
          idUuid: 'uuid-a',
        );
        final p2 = UserProject(
          userCode: 'U-001',
          code: 'B',
          name: 'B',
          idUuid: 'uuid-b',
        );

        // Two distinct projects → exactly two wipes (one per transition,
        // including the initial null → p1).
        await context.setActiveProject(p1);
        await context.setActiveProject(p2);

        verify(db.clearCustomerCacheForProjectSwitch()).called(2);
      },
    );

    test(
      'setActiveProject does NOT re-wipe when re-selecting the same project',
      () async {
        final project = UserProject(
          userCode: 'U-001',
          code: 'A',
          name: 'A',
          idUuid: 'uuid-a',
        );

        await context.setActiveProject(project);
        // Initial wipe is expected because previous header value was null.
        // The SECOND select with the same project must be a no-op.
        clearInteractions(db);

        await context.setActiveProject(project);

        verifyNever(db.clearCustomerCacheForProjectSwitch());
      },
    );

    test(
      'setActiveProject refuses to activate a project with no header value',
      () async {
        final broken = UserProject(
          userCode: 'U-001',
          code: '',
          name: 'broken',
        );

        await context.setActiveProject(broken);

        // No persistence, no cache wipe, no emission.
        verifyNever(prefs.setActiveProjectId(any));
        expect(context.activeProject, isNull);
      },
    );

    test('clearActiveProject clears persisted meta and resets memory',
        () async {
      final project = UserProject(
        userCode: 'U-001',
        code: 'A',
        name: 'A',
        idUuid: 'uuid-a',
      );
      await context.setActiveProject(project);
      expect(context.activeProject, isNotNull);

      await context.clearActiveProject();

      expect(context.activeProject, isNull);
      verify(prefs.clearActiveProjectMeta()).called(1);
    });

    test('activeProjectStream emits on switch', () async {
      final p1 = UserProject(
        userCode: 'U-001',
        code: 'A',
        name: 'A',
        idUuid: 'uuid-a',
      );

      final emitted = <UserProject?>[];
      final sub = context.activeProjectStream.listen(emitted.add);

      await context.setActiveProject(p1);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isNotEmpty);
      expect(emitted.last?.idUuid, 'uuid-a');

      await sub.cancel();
    });
  });
}
