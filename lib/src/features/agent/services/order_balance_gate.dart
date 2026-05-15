/// ============================================================================
/// Order Balance Gate
/// ============================================================================
/// Decides whether the agent can proceed with the "create order" step inside
/// a visit, based on the customer's balance and the active project's debt
/// limit.
///
/// Rules (Customer Balance Passport §5):
///
///   blocked = (limit != null) AND (balance > limit)
///
/// Sign convention (Passport §2.2 / §6.1, mirrored by the rest of the
/// UI in `client_balance.dart`):
///   * `balance` > 0 — customer owes us money (debtor).
///   * `balance` < 0 — customer has prepaid / has credit (overpayment).
///   * `limit`   — maximum debt the project tolerates before further
///     orders must be blocked (positive value).
///
/// `limit == null` ⇒ no cap configured ⇒ never blocked.
///
/// Online: trust the backend's `blocked` flag (defense-in-depth — backend is
/// authoritative). Offline: re-evaluate locally using the cached
/// `ClientBalance.balance` and `UserProject.debtLimit`.
///
/// The gate also feeds the pre-submit recheck in
/// `DataSyncService.syncCreateOrders()` (M11) — there it is invoked with
/// `forceFresh: true` so the backend's cache is bypassed before an order is
/// actually pushed.
/// ============================================================================

import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/client_balance_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/connectivity_monitor_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/project_context.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_balance.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_project.dart';

/// Outcome of a [OrderBalanceGate.check] call. Carries everything the UI
/// (`DebtBlockedDialog`, `OrdersPage` badge) needs to explain the decision.
class BalanceGateResult {
  final bool blocked;
  final double balance;
  final double? limit;
  final String currency;
  final DateTime? fetchedAt;
  final DateTime? externalUpdatedAt;
  final bool isStale;
  final bool isOffline;

  /// `"fresh"` | `"cache"` | `"stale"` | `"local"` — `"local"` is offline.
  final String source;

  /// `"debt_limit_exceeded"` | `"no_cached_balance"` | `"fetch_failed"` |
  /// `"no_active_project"` | `null` (not blocked).
  final String? reason;

  const BalanceGateResult({
    required this.blocked,
    required this.balance,
    required this.limit,
    required this.currency,
    required this.fetchedAt,
    required this.externalUpdatedAt,
    required this.isStale,
    required this.isOffline,
    required this.source,
    required this.reason,
  });
}

class OrderBalanceGate {
  final ClientBalanceService _balanceService;
  final ConnectivityMonitorService _connectivity;
  final ProjectContext _projectContext;

  /// Considered stale after this many hours offline. Surfaced in the dialog
  /// so the agent knows the cached value is old.
  static const Duration staleAfter = Duration(hours: 24);

  OrderBalanceGate({
    required ClientBalanceService balanceService,
    required ConnectivityMonitorService connectivity,
    required ProjectContext projectContext,
  })  : _balanceService = balanceService,
        _connectivity = connectivity,
        _projectContext = projectContext;

  Future<BalanceGateResult> check(
    TradingPoint tp, {
    bool forceFresh = false,
  }) async {
    final activeProject = _projectContext.activeProject;
    final requiresProject = _projectContext.requiresProjectHeader;
    // `ProjectContext.bootstrap` now auto-selects the first available
    // project for both scopes (org-scope no longer leaves it null on
    // purpose). `_resolveFallbackProject()` therefore only kicks in for
    // a narrow cold-start window — for example, when the gate fires
    // before bootstrap has finished or before the project sync has
    // populated `user_projects` at all.
    final fallbackProject =
        activeProject ?? await _resolveFallbackProject();
    // ignore: avoid_print
    print('[GATE] check tp.inn=${tp.inn} tp.code1c=${tp.code1c} '
        'forceFresh=$forceFresh online=${_connectivity.isConnected} '
        'scope=${requiresProject ? "project" : "organization"} '
        'activeProject=${activeProject?.code} '
        'fallbackProject=${fallbackProject?.code} '
        'fallbackLimit=${fallbackProject?.debtLimit} '
        'fallbackCurrency=${fallbackProject?.debtLimitCurrency}');

    if (fallbackProject == null) {
      if (requiresProject) {
        // Project-scope tenant has not picked an active project AND
        // there is nothing usable in the local cache either — picker
        // must be forced. Block defensively.
        // ignore: avoid_print
        print(
            '[GATE] check → BLOCK (no_active_project, scope=project, no fallback)');
        return _result(
          blocked: true,
          balance: 0,
          limit: null,
          currency: 'UZS',
          fetchedAt: null,
          externalUpdatedAt: null,
          isStale: false,
          isOffline: !_connectivity.isConnected,
          source: 'local',
          reason: 'no_active_project',
        );
      }
      // Org-scope, but `user_projects` is empty (no sync yet, or wiped).
      // Nothing to enforce — let the order proceed; backend will
      // re-check at submission.
      // ignore: avoid_print
      print('[GATE] check → ALLOW (org-scope, no projects in local cache)');
      return _result(
        blocked: false,
        balance: 0,
        limit: null,
        currency: 'UZS',
        fetchedAt: null,
        externalUpdatedAt: null,
        isStale: false,
        isOffline: !_connectivity.isConnected,
        source: 'local',
        reason: null,
      );
    }
    final projectCode = fallbackProject.code;

    if (_connectivity.isConnected) {
      try {
        final cb = await _balanceService.fetchClientBalance(
          code1c: tp.code1c,
          projectCode: projectCode,
          inn: tp.inn,
          forceRefresh: forceFresh,
        );
        if (cb == null) {
          // REST returned null AND no cached fallback existed.
          // ignore: avoid_print
          print('[GATE] online: fetchClientBalance returned null → falling back to offline path');
          return _checkOffline(tp, projectCode,
              forceReason: 'fetch_failed');
        }

        // ignore: avoid_print
        print('[GATE] online: backend balance=${cb.balance} '
            'cb.debtLimit=${cb.debtLimit} cb.blocked=${cb.blocked} '
            'cb.blockReason=${cb.blockReason} cb.source=${cb.source} '
            'cb.currency=${cb.currency}');

        // Resolve THIS customer's project from the balance response.
        // `cb.projectName` carries the project identifier the backend
        // associated with the customer; we match it against the local
        // `user_projects` rows so the gate applies the correct
        // per-project limit even when the user has multiple projects
        // (org-scope) or has the "wrong" one active in the picker.
        final customerProject = await _resolveProjectForBalance(cb);
        final effectiveProject = customerProject ?? fallbackProject;
        final effectiveLimit = cb.debtLimit ?? effectiveProject.debtLimit;
        final remoteBlocked =
            cb.blocked ?? _localBlocked(cb.balance, effectiveLimit);
        // ignore: avoid_print
        print('[GATE] online → ${remoteBlocked ? 'BLOCK' : 'ALLOW'} '
            '(authoritative=${cb.blocked != null ? 'backend' : 'local'}) '
            'cb.projectName=${cb.projectName} '
            'customerProject=${customerProject?.code} '
            'effectiveLimit=$effectiveLimit '
            '(cb.debtLimit=${cb.debtLimit}, '
            'customerProject.debtLimit=${customerProject?.debtLimit}, '
            'fallbackProject.debtLimit=${fallbackProject.debtLimit})');
        return _result(
          blocked: remoteBlocked,
          balance: cb.balance,
          limit: effectiveLimit,
          currency:
              cb.currency ?? effectiveProject.debtLimitCurrency ?? 'UZS',
          fetchedAt: cb.lastUpdated,
          externalUpdatedAt: cb.serverDataUpdatedAt,
          isStale: cb.source == 'stale',
          isOffline: false,
          source: cb.source ?? 'fresh',
          reason: remoteBlocked
              ? (cb.blockReason ?? 'debt_limit_exceeded')
              : null,
        );
      } catch (e) {
        // ignore: avoid_print
        print('[GATE] online: fetchClientBalance threw → fallback to offline path. error=$e');
        return _checkOffline(tp, projectCode, forceReason: 'fetch_failed');
      }
    }

    // ignore: avoid_print
    print('[GATE] offline path (device not connected)');
    return _checkOffline(tp, projectCode);
  }

  Future<BalanceGateResult> _checkOffline(
    TradingPoint tp,
    String projectCode, {
    String? forceReason,
  }) async {
    final fallbackProject =
        _projectContext.activeProject ?? await _resolveFallbackProject();

    final cached = await _balanceService.getCachedClientBalance(
      code1c: tp.code1c,
      projectCode: projectCode,
      inn: tp.inn,
    );

    // Prefer the per-customer project from the cached balance row when
    // available, so the limit matches the customer's actual project
    // (correct for multi-project tenants). Falls back to the
    // active/fallback project when no cache row exists yet.
    final customerProject =
        cached != null ? await _resolveProjectForBalance(cached) : null;
    final project = customerProject ?? fallbackProject;
    final limit = project?.debtLimit;
    final currency = project?.debtLimitCurrency ?? 'UZS';

    if (cached == null) {
      // Passport §5: blocked = (limit != null) AND (balance > limit).
      // When the project has no debt limit, the gate must allow the
      // order even if the balance is unknown — there is nothing to
      // compare against. Only block when a limit exists; that preserves
      // the defense-in-depth behaviour for projects that actually run
      // on a debt cap.
      final blocked = limit != null;
      return _result(
        blocked: blocked,
        balance: 0,
        limit: limit,
        currency: currency,
        fetchedAt: null,
        externalUpdatedAt: null,
        isStale: false,
        isOffline: !_connectivity.isConnected,
        source: 'local',
        reason: blocked ? (forceReason ?? 'no_cached_balance') : null,
      );
    }

    final isStale = DateTime.now().difference(cached.lastUpdated) > staleAfter;
    final blocked = _localBlocked(cached.balance, limit);
    return _result(
      blocked: blocked,
      balance: cached.balance,
      limit: limit,
      currency: cached.currency ?? currency,
      fetchedAt: cached.lastUpdated,
      externalUpdatedAt: cached.serverDataUpdatedAt,
      isStale: isStale,
      isOffline: !_connectivity.isConnected,
      source: 'local',
      reason: blocked
          ? 'debt_limit_exceeded'
          : (forceReason == 'fetch_failed' ? 'fetch_failed' : null),
    );
  }

  /// Resolves the user's project list once per gate call. Returns the
  /// list in deterministic order (ASC by name). Empty list when there
  /// is no logged-in user or no synced projects.
  Future<List<UserProject>> _loadUserProjects() async {
    try {
      if (!sl.isRegistered<SharedPreferencesService>() ||
          !sl.isRegistered<ApiDatabaseService>()) {
        return const [];
      }
      final userCode = sl<SharedPreferencesService>().getUserCode();
      if (userCode == null || userCode.isEmpty) return const [];
      return await sl<ApiDatabaseService>().getUserProjects(userCode);
    } catch (e) {
      // ignore: avoid_print
      print('[GATE] _loadUserProjects failed (ignored): $e');
      return const [];
    }
  }

  /// Resolves a project to use when nothing else identifies one — typical
  /// for org-scope tenants (no picker) or for cold starts where the
  /// customer's balance hasn't been fetched yet. Returns the first row
  /// of `user_projects` (deterministic, ASC by name).
  Future<UserProject?> _resolveFallbackProject() async {
    final projects = await _loadUserProjects();
    if (projects.isEmpty) return null;
    return projects.first;
  }

  /// Resolves the per-customer project from a fetched/cached balance
  /// row. Necessary for tenants with **multiple projects** so the gate
  /// applies each customer's own project limit instead of a global one.
  ///
  /// Match strategy mirrors
  /// [ApiDatabaseService.updateUserProjectDebtLimitByAnyKey]:
  ///   1. `user_projects.code == cb.projectName`
  ///   2. `user_projects.id_1c == cb.projectName`
  ///   3. `user_projects.id_uuid == cb.projectName`
  ///   4. case-insensitive prefix match on `user_projects.name`
  ///
  /// Returns `null` when [ClientBalance.projectName] is empty or no
  /// local row matches. Callers should fall back to the active /
  /// fallback project in that case.
  Future<UserProject?> _resolveProjectForBalance(ClientBalance cb) async {
    final key = cb.projectName.trim();
    if (key.isEmpty) return null;
    final projects = await _loadUserProjects();
    if (projects.isEmpty) return null;

    for (final p in projects) {
      if (p.code == key) return p;
    }
    for (final p in projects) {
      if (p.id1c != null && p.id1c == key) return p;
    }
    for (final p in projects) {
      if (p.idUuid != null && p.idUuid == key) return p;
    }
    final upperKey = key.toUpperCase();
    for (final p in projects) {
      if (p.name.toUpperCase().startsWith(upperKey)) return p;
    }
    return null;
  }

  /// Passport §5 formula. Used both online (as a sanity check when the
  /// backend doesn't return `blocked`) and offline.
  ///
  /// `balance > 0` = debt, `limit` = max debt the project tolerates. The
  /// diagnostic print is unconditional so the comparison can be verified
  /// from the device log (`grep '\[GATE\]'`).
  static bool _localBlocked(double balance, double? limit) {
    if (limit == null) {
      // ignore: avoid_print
      print('[GATE] _localBlocked: limit=null balance=$balance → ALLOW');
      return false;
    }
    final blocked = balance > limit;
    // ignore: avoid_print
    print('[GATE] _localBlocked: balance=$balance limit=$limit '
        'rule=(balance>limit) → ${blocked ? 'BLOCK' : 'ALLOW'}');
    return blocked;
  }

  BalanceGateResult _result({
    required bool blocked,
    required double balance,
    required double? limit,
    required String currency,
    required DateTime? fetchedAt,
    required DateTime? externalUpdatedAt,
    required bool isStale,
    required bool isOffline,
    required String source,
    required String? reason,
  }) {
    return BalanceGateResult(
      blocked: blocked,
      balance: balance,
      limit: limit,
      currency: currency,
      fetchedAt: fetchedAt,
      externalUpdatedAt: externalUpdatedAt,
      isStale: isStale,
      isOffline: isOffline,
      source: source,
      reason: reason,
    );
  }
}
