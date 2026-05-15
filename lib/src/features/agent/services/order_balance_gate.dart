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
/// Online: trust the backend's `blocked` flag (defense-in-depth — backend is
/// authoritative). Offline: re-evaluate locally using the cached
/// `ClientBalance.balance` and `UserProject.debtLimit`.
///
/// The gate also feeds the pre-submit recheck in
/// `DataSyncService.syncCreateOrders()` (M11) — there it is invoked with
/// `forceFresh: true` so the backend's cache is bypassed before an order is
/// actually pushed.
/// ============================================================================

import 'package:flutter/foundation.dart';

import 'package:gloria_marketing_flutter/src/core/services/client_balance_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/connectivity_monitor_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/project_context.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';

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
    if (activeProject == null) {
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
    final projectCode = activeProject.code;

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
          return _checkOffline(tp, projectCode,
              forceReason: 'fetch_failed');
        }

        final remoteBlocked = cb.blocked ?? _localBlocked(cb.balance, cb.debtLimit);
        return _result(
          blocked: remoteBlocked,
          balance: cb.balance,
          limit: cb.debtLimit ?? activeProject.debtLimit,
          currency: cb.currency ?? activeProject.debtLimitCurrency ?? 'UZS',
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
        if (kDebugMode) {
          print('OrderBalanceGate: online check failed, falling back: $e');
        }
        return _checkOffline(tp, projectCode, forceReason: 'fetch_failed');
      }
    }

    return _checkOffline(tp, projectCode);
  }

  Future<BalanceGateResult> _checkOffline(
    TradingPoint tp,
    String projectCode, {
    String? forceReason,
  }) async {
    final activeProject = _projectContext.activeProject;
    final limit = activeProject?.debtLimit;
    final currency = activeProject?.debtLimitCurrency ?? 'UZS';

    final cached = await _balanceService.getCachedClientBalance(
      code1c: tp.code1c,
      projectCode: projectCode,
      inn: tp.inn,
    );

    if (cached == null) {
      return _result(
        blocked: true,
        balance: 0,
        limit: limit,
        currency: currency,
        fetchedAt: null,
        externalUpdatedAt: null,
        isStale: false,
        isOffline: !_connectivity.isConnected,
        source: 'local',
        reason: forceReason ?? 'no_cached_balance',
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

  /// Passport §5 formula. Used both online (as a sanity check when the
  /// backend doesn't return `blocked`) and offline.
  static bool _localBlocked(double balance, double? limit) {
    if (limit == null) return false;
    return balance > limit;
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
