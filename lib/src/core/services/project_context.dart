import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_project.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/login_gates_envelope.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/entities/user_entity.dart';

import 'api_database_service.dart';
import 'client_balance_service.dart';
import 'service_locator.dart';
import 'shared_preferences_service.dart';

/// Origin of the currently-active project selection.
enum ActiveProjectSource {
  /// Resolved automatically from `gates.primary_project_id` on login.
  primary,

  /// Picked by the user via the project picker UI.
  picker,

  /// Fallback path — e.g. the only project the user has.
  fallback,
}

/// Centralised active-project tracker for `customer_scope=project` tenants.
///
/// Reads `customer_scope` and `primary_project_id` from the cached login
/// gates and exposes a single source of truth for:
///
///   * whether `X-Project-Id` must be sent on mobile customer endpoints,
///   * the active project's identifier value to use in that header,
///   * a stream that customer screens listen to for refresh on switch.
///
/// Org-scope tenants get a no-op: [requiresProjectHeader] returns `false`,
/// [activeProjectHeaderValue] returns `null`, and the header is omitted by
/// callers — preserving the historic behaviour.
class ProjectContext extends ChangeNotifier {
  ProjectContext(this._prefs, this._db);

  final SharedPreferencesService _prefs;
  final ApiDatabaseService _db;

  UserProject? _activeProject;
  UserEntity? _user;
  final StreamController<UserProject?> _streamController =
      StreamController<UserProject?>.broadcast();

  /// Emits whenever the active project changes (including `null` on clear).
  Stream<UserProject?> get activeProjectStream => _streamController.stream;

  /// Currently-active project resolved at bootstrap or via [setActiveProject].
  /// `null` until [bootstrap] runs or while the user hasn't picked one.
  UserProject? get activeProject => _activeProject;

  /// Scope the backend assigned to the user's tenant. Defaults to
  /// [CustomerScope.organization] when gates are missing or the field
  /// hasn't been provided yet (rollout window).
  CustomerScope get currentScope {
    final gates = _prefs.getCachedGates();
    return gates?.customerScope ?? CustomerScope.organization;
  }

  /// `true` when callers must attach `X-Project-Id` to mobile customer
  /// endpoint calls.
  bool get requiresProjectHeader => currentScope == CustomerScope.project;

  /// `true` when the backend has explicitly told this client which scope
  /// applies. When `false`, the mobile app is still in the rollout window
  /// and should NOT send the header.
  bool get scopeKnown {
    final gates = _prefs.getCachedGates();
    return gates?.customerScopeProvided ?? false;
  }

  /// Value to send in `X-Project-Id`. UUID is preferred, with 1C ref and
  /// SOAP `code` as progressive fallbacks (backend accepts either form).
  /// Returns `null` when no project is active — callers must surface
  /// `customer_project_required` and force the picker.
  String? get activeProjectHeaderValue => _activeProject?.headerValue;

  /// Should be invoked once per successful login (and after every refresh
  /// that may have flipped scope on the admin side). Reconciles the cached
  /// gates with the currently-stored active project:
  ///
  ///   * Scope=project and cached/primary project resolves → activate it.
  ///   * Scope=project and nothing resolves → emit `null` so orchestrators
  ///     know to force the picker.
  ///   * Scope=organization → still pick an active project (cached → first
  ///     available row in `user_projects`). The `X-Project-Id` header is
  ///     still suppressed via [requiresProjectHeader], but downstream
  ///     consumers (`ClientBalanceCubit`, `OrderBalanceGate`, the new
  ///     Settings → Loyihalar tab) need a non-null project to operate.
  Future<void> bootstrap(UserEntity user) async {
    _user = user;

    // Step 1: try the cached selection regardless of scope.
    final cachedId = _readActiveProjectId();
    if (cachedId != null && cachedId.isNotEmpty) {
      final project = await _resolveProjectByAnyId(user.code, cachedId);
      if (project != null) {
        _activeProject = project;
        _streamController.add(project);
        notifyListeners();
        return;
      }
    }

    if (requiresProjectHeader) {
      // Project-scope: fall through to gates.primary_project_id (UUID).
      final primaryId =
          user.primaryProjectId ?? _prefs.getCachedGates()?.primaryProjectId;
      if (primaryId != null && primaryId.isNotEmpty) {
        final project = await _resolveProjectByAnyId(user.code, primaryId);
        if (project != null) {
          await setActiveProject(project, source: ActiveProjectSource.primary);
          return;
        }
      }
      // Last resort for project-scope too: auto-pick the first row in
      // `user_projects` that carries a header value. Without this the
      // device sits with `_activeProject = null` and every customer
      // endpoint throws `customer_project_required` — leaving the user
      // stuck unless they hand-pick a project. Selecting a sensible
      // default and letting them change it later from
      // Settings → Loyihalar matches the org-scope behaviour below.
      try {
        final projects = await _db.getUserProjects(user.code);
        for (final candidate in projects) {
          final header = candidate.headerValue;
          if (header != null && header.isNotEmpty) {
            await setActiveProject(candidate,
                source: ActiveProjectSource.fallback);
            return;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('ProjectContext: project-scope fallback pick failed: $e');
        }
      }
      // Nothing resolved — orchestrator should open the picker.
      _activeProject = null;
      _streamController.add(null);
      notifyListeners();
      return;
    }

    // Step 2 (org-scope): auto-pick the first row in `user_projects`. This
    // is the user's default working project on a tenant that does not
    // expose a picker. Persisted via `setActiveProject` so the selection
    // survives restarts and can be changed from Settings → Loyihalar.
    try {
      final projects = await _db.getUserProjects(user.code);
      if (projects.isNotEmpty) {
        await setActiveProject(projects.first,
            source: ActiveProjectSource.fallback);
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print('ProjectContext: org-scope auto-pick failed: $e');
      }
    }

    // Nothing in `user_projects` yet (sync hasn't run). Org-scope is
    // allowed to operate without a project; downstream code handles null.
    _activeProject = null;
    _streamController.add(null);
    notifyListeners();
  }

  /// Switch active project and invalidate any cached customer data that
  /// would leak the previous project's rows.
  Future<void> setActiveProject(
    UserProject project, {
    ActiveProjectSource source = ActiveProjectSource.picker,
  }) async {
    final headerValue = project.headerValue;
    if (headerValue == null) {
      if (kDebugMode) {
        print(
            'ProjectContext: refused to activate project ${project.code} — no header value');
      }
      return;
    }
    final previous = _activeProject;
    _activeProject = project;
    await _prefs.setActiveProjectId(headerValue);
    await _prefs.setActiveProjectSource(source.name);
    if (previous?.headerValue != headerValue) {
      // Wipe local SQLite caches scoped to the old project.
      await _db.clearCustomerCacheForProjectSwitch();
      // SQLite tozalansa ham `ClientBalanceService` ning in-memory
      // mapllari (INN bo'yicha kalitlangan) eski loyihaning balansini
      // saqlab qoladi va 10s cooldown qayta-yuklashni bloklaydi.
      if (sl.isRegistered<ClientBalanceService>()) {
        sl<ClientBalanceService>().clearInMemoryCaches();
      }
    }
    _streamController.add(project);
    notifyListeners();
  }

  /// Drop the active project — e.g. on logout or scope downgrade.
  Future<void> clearActiveProject() async {
    await _clearInternal();
    notifyListeners();
  }

  /// Re-evaluates state against the latest cached gates. Called after a
  /// token refresh, since the server may have flipped `customer_scope`
  /// admin-side. Safe to call repeatedly.
  Future<void> refreshFromGates() async {
    if (_user == null) return;
    await bootstrap(_user!);
  }

  Future<void> _clearInternal() async {
    _activeProject = null;
    await _prefs.clearActiveProjectMeta();
    _streamController.add(null);
  }

  String? _readActiveProjectId() {
    return _prefs.getActiveProjectId();
  }

  /// Resolves a [UserProject] from the local DB by trying [idUuid], [id1c]
  /// and then [code] (in that preference order) so that whichever form
  /// the caller cached works.
  Future<UserProject?> _resolveProjectByAnyId(
    String userCode,
    String idOrCode,
  ) async {
    try {
      final all = await _db.getUserProjects(userCode);
      for (final project in all) {
        if (project.idUuid == idOrCode ||
            project.id1c == idOrCode ||
            project.code == idOrCode) {
          return project;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ProjectContext: failed to resolve project $idOrCode: $e');
      }
    }
    return null;
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }
}
