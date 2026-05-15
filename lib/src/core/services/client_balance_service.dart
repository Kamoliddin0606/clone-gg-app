/// ============================================================================
/// Client Balance Service
/// ============================================================================
/// Service for fetching, storing and managing client balance data.
///
/// Transport: backend REST endpoint
/// `POST /api/mobile/v2/customers/balance/` (Customer Balance Passport §2).
/// Backend forwards the request to the 1C SOAP server, applies the cache /
/// debt-limit / blocked decision, and returns the JSON shape declared in the
/// passport. The mobile no longer talks SOAP for balances.
///
/// Cache & DB tables (`client_balances`, `client_balance_contracts`,
/// `client_balance_orders`) are kept INN-keyed for backward compatibility
/// with `ClientBalanceCubit`, `ClientBalanceWidgetV2` and
/// `ClientBalanceDetailsPage` which all read by INN.
///
/// Main functions:
/// - [fetchClientBalance]      — REST fetch + cache + DB write
/// - [getCachedClientBalance]  — gate-friendly cache lookup
/// - [getClientBalanceFromDb]  — read-through DB
/// - [getClientBalanceFromCache] / [canRefresh] — legacy helpers used by Cubit
/// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_balance.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/customer_balance_status_cache.dart';
import 'package:gloria_marketing_flutter/src/core/network/api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/network/url_failover_service.dart';
import 'package:gloria_marketing_flutter/src/core/network/server_service.dart';

class ClientBalanceService {
  final ApiDatabaseService _dbService;

  /// Kept for the upcoming SOAP teardown (M2). The legacy SOAP failover
  /// service is no longer invoked from this class; callers that still query
  /// `getFailoverStatistics`/`resetEndpointStatus` continue to work.
  final UrlFailoverService _failoverService;

  /// Same rationale as [_failoverService]: legacy accessor for accounting
  /// API config — soon to be deleted in M2.
  final ServerService _serverService;

  /// Optional REST client override — primarily for testability. When `null`
  /// the registered `sl<ApiService>()` is resolved on first use so existing
  /// constructor sites keep working without DI churn.
  ApiService? _apiServiceOverride;

  /// Minimum time between user-triggered refreshes (in seconds).
  static const int refreshCooldownSeconds = 10;

  /// In-memory cache keyed by INN (matches `ClientBalanceCubit` lookups).
  final Map<String, ClientBalance> _cache = {};

  /// Most-recent fetch time per INN — drives the cooldown UI in the cubit.
  final Map<String, DateTime> _lastRefreshTimes = {};

  /// Reverse lookup so `getCachedClientBalance(code1c:, projectCode:)` can
  /// resolve to an INN that the local DB is keyed by. Filled on every fetch
  /// from the response. Cold-start fallback below queries the DB by
  /// `(project_name = projectCode)` and returns the first match.
  final Map<String, String> _code1cToInn = {};

  ClientBalanceService({
    required ApiDatabaseService dbService,
    required UrlFailoverService failoverService,
    required ServerService serverService,
    SharedPreferencesService? prefs, // legacy, unused since REST switch
    ApiService? apiService,
  })  : _dbService = dbService,
        _failoverService = failoverService,
        _serverService = serverService,
        _apiServiceOverride = apiService;

  ApiService get _apiService => _apiServiceOverride ??= sl<ApiService>();

  // ---------------------------------------------------------------------------
  // Cooldown helpers (used by ClientBalanceCubit)
  // ---------------------------------------------------------------------------

  bool canRefresh(String inn) {
    final lastRefresh = _lastRefreshTimes[inn];
    if (lastRefresh == null) return true;
    final elapsed = DateTime.now().difference(lastRefresh).inSeconds;
    return elapsed >= refreshCooldownSeconds;
  }

  int getSecondsUntilRefresh(String inn) {
    final lastRefresh = _lastRefreshTimes[inn];
    if (lastRefresh == null) return 0;
    final elapsed = DateTime.now().difference(lastRefresh).inSeconds;
    final remaining = refreshCooldownSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  // ---------------------------------------------------------------------------
  // Primary fetch — backend REST
  // ---------------------------------------------------------------------------

  /// Fetch the customer balance via the backend balance proxy.
  ///
  /// [code1c]      — `TradingPoint.code1c`, the 1C customer ID the backend
  ///                 forwards to the SOAP system. Required.
  /// [projectCode] — `UserProject.code`, the active project on the device.
  ///                 Required.
  /// [inn]         — Optional. Used only for cooldown and cache fallback so
  ///                 we can return previously-cached data on transport
  ///                 failures without re-fetching.
  /// [forceRefresh] — bypasses both the local cooldown and the backend's
  ///                 60-second cache (Passport §4).
  Future<ClientBalance?> fetchClientBalance({
    required String code1c,
    required String projectCode,
    String? inn,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && inn != null && inn.isNotEmpty && !canRefresh(inn)) {
      if (kDebugMode) {
        print(
            'ClientBalanceService: cooldown active for INN $inn, ${getSecondsUntilRefresh(inn)}s remaining');
      }
      return _cache[inn] ?? await getClientBalanceFromDb(inn);
    }

    if (kDebugMode) {
      print(
          'ClientBalanceService: REST fetch code_1c=$code1c project_code=$projectCode forceRefresh=$forceRefresh');
    }

    try {
      final response = await _apiService.post(
        '/api/mobile/v2/customers/balance/',
        data: {
          'code_1c': code1c,
          'project_code': projectCode,
          'force_refresh': forceRefresh,
        },
      );

      final data = response.data;
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        final balance = ClientBalance.fromJson(data);
        if (balance.inn.isNotEmpty) {
          _cache[balance.inn] = balance;
          _lastRefreshTimes[balance.inn] = DateTime.now();
          _code1cToInn[code1c] = balance.inn;
          await saveClientBalance(balance);
        }
        if (kDebugMode) {
          print(
              'ClientBalanceService: REST ok inn=${balance.inn} balance=${balance.balance} blocked=${balance.blocked} source=${balance.source}');
        }
        return balance;
      }

      if (kDebugMode) {
        print(
            'ClientBalanceService: REST non-200 status=${response.statusCode} payload=${data.runtimeType}');
      }
      return _fallbackFromCache(inn);
    } on DioException catch (e) {
      if (kDebugMode) {
        print(
            'ClientBalanceService: REST DioException type=${e.type} status=${e.response?.statusCode} body=${e.response?.data}');
      }
      return _fallbackFromCache(inn);
    } catch (e) {
      if (kDebugMode) {
        print('ClientBalanceService: REST unexpected error: $e');
      }
      return _fallbackFromCache(inn);
    }
  }

  Future<ClientBalance?> _fallbackFromCache(String? inn) async {
    if (inn == null || inn.isEmpty) return null;
    return _cache[inn] ?? await getClientBalanceFromDb(inn);
  }

  // ---------------------------------------------------------------------------
  // Gate-facing accessors
  // ---------------------------------------------------------------------------

  /// Used by [OrderBalanceGate] when offline. Resolves the most recently
  /// cached balance for a `(code_1c, project_code)` pair, with INN as the
  /// physical lookup key into the existing INN-indexed tables.
  ///
  /// Pass [inn] when the caller has it (e.g. `TradingPoint.inn`) — that is
  /// the fast path. Without [inn] the method does a project-scoped lookup
  /// in `client_balances` so a recently-fetched row can still be matched
  /// across cold restarts.
  Future<ClientBalance?> getCachedClientBalance({
    required String code1c,
    required String projectCode,
    String? inn,
  }) async {
    String? lookupInn = inn != null && inn.isNotEmpty ? inn : null;
    lookupInn ??= _code1cToInn[code1c];

    if (lookupInn != null) {
      final cached = _cache[lookupInn];
      if (cached != null) return cached;
      final db = await getClientBalanceFromDb(lookupInn);
      if (db != null) return db;
    }

    // Cold-start fallback: scan by project_name = projectCode and pick the
    // newest row. This is best-effort only — when [inn] is not supplied and
    // the in-memory map is empty we cannot disambiguate a customer.
    try {
      final db = await _dbService.database;
      final rows = await db.query(
        'client_balances',
        where: 'project_name = ?',
        whereArgs: [projectCode],
        orderBy: 'last_updated DESC',
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final fallbackInn = rows.first['inn'] as String?;
      if (fallbackInn == null || fallbackInn.isEmpty) return null;
      _code1cToInn[code1c] = fallbackInn;
      return await getClientBalanceFromDb(fallbackInn);
    } catch (_) {
      return null;
    }
  }

  ClientBalance? getClientBalanceFromCache(String inn) => _cache[inn];

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<ClientBalance?> getClientBalanceFromDb(String inn) async {
    try {
      final db = await _dbService.database;

      final balanceResult = await db.query(
        'client_balances',
        where: 'inn = ?',
        whereArgs: [inn],
        limit: 1,
      );

      if (balanceResult.isEmpty) return null;

      final balanceRow = balanceResult.first;

      final contractsResult = await db.query(
        'client_balance_contracts',
        where: 'inn = ?',
        whereArgs: [inn],
      );
      final contractBalances = contractsResult
          .map((row) => ClientBalanceByContract.fromJson(row))
          .toList();

      final ordersResult = await db.query(
        'client_balance_orders',
        where: 'inn = ?',
        whereArgs: [inn],
      );
      final orderBalances =
          ordersResult.map((row) => ClientBalanceByOrder.fromJson(row)).toList();

      final blockedRaw = balanceRow['blocked'];
      final clientBalance = ClientBalance(
        inn: inn,
        clientCode: balanceRow['client_code'] as String?,
        balance: (balanceRow['balance'] as num?)?.toDouble() ?? 0.0,
        contractBalances: contractBalances,
        orderBalances: orderBalances,
        lastUpdated: DateTime.parse(balanceRow['last_updated'] as String),
        serverDataUpdatedAt: balanceRow['server_data_updated_at'] != null
            ? DateTime.parse(balanceRow['server_data_updated_at'] as String)
            : null,
        projectName: balanceRow['project_name'] as String? ?? '',
        debtLimit: (balanceRow['debt_limit'] as num?)?.toDouble(),
        debtLimitCurrency: balanceRow['debt_limit_currency'] as String?,
        currency: balanceRow['currency'] as String?,
        blocked: blockedRaw == null ? null : (blockedRaw as int) != 0,
        blockReason: balanceRow['block_reason'] as String?,
        source: balanceRow['source'] as String?,
        lastError: balanceRow['last_error'] as String?,
      );

      _cache[inn] = clientBalance;
      return clientBalance;
    } catch (e) {
      if (kDebugMode) {
        print('ClientBalanceService: DB read error for INN $inn: $e');
      }
      return null;
    }
  }

  Future<void> saveClientBalance(ClientBalance balance) async {
    try {
      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      await db.transaction((txn) async {
        await txn.delete('client_balances',
            where: 'inn = ?', whereArgs: [balance.inn]);
        await txn.delete('client_balance_contracts',
            where: 'inn = ?', whereArgs: [balance.inn]);
        await txn.delete('client_balance_orders',
            where: 'inn = ?', whereArgs: [balance.inn]);

        await txn.insert('client_balances', {
          'inn': balance.inn,
          'client_code': balance.clientCode,
          'balance': balance.balance,
          'project_name': balance.projectName,
          'last_updated': balance.lastUpdated.toIso8601String(),
          'server_data_updated_at':
              balance.serverDataUpdatedAt?.toIso8601String(),
          'debt_limit': balance.debtLimit,
          'debt_limit_currency': balance.debtLimitCurrency,
          'currency': balance.currency,
          'blocked': balance.blocked == null ? null : (balance.blocked! ? 1 : 0),
          'block_reason': balance.blockReason,
          'source': balance.source,
          'last_error': balance.lastError,
          'created_at': now,
          'updated_at': now,
        });

        for (final contract in balance.contractBalances) {
          await txn.insert('client_balance_contracts', {
            'inn': balance.inn,
            'client_code': balance.clientCode,
            ...contract.toJson(),
            'created_at': now,
            'updated_at': now,
          });
        }

        for (final order in balance.orderBalances) {
          await txn.insert('client_balance_orders', {
            'inn': balance.inn,
            'client_code': balance.clientCode,
            ...order.toJson(),
            'created_at': now,
            'updated_at': now,
          });
        }
      });

      if (kDebugMode) {
        print(
            'ClientBalanceService: persisted INN ${balance.inn} (blocked=${balance.blocked}, source=${balance.source})');
      }

      // Push the freshly-persisted row into the visual status cache so the
      // trading-points list/grid + visit-step tile re-render with the new
      // tint/indicator without waiting for the next bootstrap. Wrapped in
      // a try/check so test environments without the cache registered don't
      // crash. See docs/customer-balance-mobile.md M12 (rebuilt).
      try {
        if (sl.isRegistered<CustomerBalanceStatusCache>()) {
          sl<CustomerBalanceStatusCache>().onBalanceUpdated(balance);
        }
      } catch (_) {
        // Pure UI side-effect; never fail the write because of it.
      }
    } catch (e) {
      if (kDebugMode) {
        print('ClientBalanceService: DB write error: $e');
      }
    }
  }

  Future<void> deleteClientBalance(String inn) async {
    try {
      final db = await _dbService.database;
      await db.delete('client_balances', where: 'inn = ?', whereArgs: [inn]);
      await db.delete('client_balance_contracts',
          where: 'inn = ?', whereArgs: [inn]);
      await db.delete('client_balance_orders',
          where: 'inn = ?', whereArgs: [inn]);
      _cache.remove(inn);
      _lastRefreshTimes.remove(inn);
    } catch (e) {
      if (kDebugMode) {
        print('ClientBalanceService: delete error: $e');
      }
    }
  }

  Future<void> clearAllBalances() async {
    try {
      final db = await _dbService.database;
      await db.delete('client_balances');
      await db.delete('client_balance_contracts');
      await db.delete('client_balance_orders');
      _cache.clear();
      _lastRefreshTimes.clear();
      _code1cToInn.clear();
    } catch (e) {
      if (kDebugMode) {
        print('ClientBalanceService: clear error: $e');
      }
    }
  }

  Future<int> getBalanceCount() async {
    try {
      final db = await _dbService.database;
      final result = await db
          .rawQuery('SELECT COUNT(*) as count FROM client_balances');
      return result.first['count'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ---------------------------------------------------------------------------
  // Legacy SOAP accessors — kept until M2 (SOAP teardown).
  // ---------------------------------------------------------------------------

  /// Legacy SOAP project-name resolver. After the REST switch this is
  /// effectively a no-op for balance fetches; the cubit and v1 widget still
  /// call it so it remains for back-compat. M2 deletes it.
  String getProjectNameForServer(String? serverName) {
    switch (serverName?.toLowerCase()) {
      case 'evyap':
        return 'Evyap_-';
      case 'garnier':
        return 'Garnier_-';
      case 'ppd':
        return 'PPD_-';
      case 'avon':
        return 'Avon_-';
      case 'avontest':
        return 'AvonTest_-';
      default:
        return 'Evyap_-';
    }
  }

  Map<String, UrlStatus> getFailoverStatistics() => _failoverService.urlStatuses;

  Future<void> resetEndpointStatus() async {
    await _failoverService.reset();
  }

  ServerUrlConfig getAccountingApiConfig() => _serverService.accountingApiConfig;
}
