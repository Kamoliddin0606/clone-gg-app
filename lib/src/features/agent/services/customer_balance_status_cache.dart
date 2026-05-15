import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/project_context.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_balance.dart';

import 'customer_balance_status.dart';

/// One row in the cache: enough to render the indicator + the bottom-sheet
/// details without re-querying the DB.
@immutable
class CustomerBalanceStatusEntry {
  final CustomerBalanceStatus status;
  final double balance;
  final double? limit;
  final String currency;
  final DateTime? lastUpdated;

  const CustomerBalanceStatusEntry({
    required this.status,
    required this.balance,
    required this.limit,
    required this.currency,
    required this.lastUpdated,
  });
}

/// Shared in-memory map of `inn → CustomerBalanceStatusEntry`. Owned by
/// [GetIt], read by every customer-card / detail-sheet / visit-step tile.
///
/// Refresh strategy:
///   * **Bootstrap** — first read after app start (lazy) and after every
///     project switch. Reads `client_balances` rows for the active project
///     in one query, then fills the map.
///   * **Push update** — `ClientBalanceService.saveClientBalance` calls
///     [onBalanceUpdated] with the freshly-fetched row so the indicator
///     reflects the new value without a re-query.
///   * **Project switch** — listens to [ProjectContext.activeProjectStream]
///     and bootstraps with the new project context. Old rows from the
///     previous project are cleared.
///
/// The class is a [ChangeNotifier] so widgets can `ListenableBuilder` on
/// it cheaply; granular per-INN streams would be over-engineered at this
/// list size (a few hundred customers).
class CustomerBalanceStatusCache extends ChangeNotifier {
  CustomerBalanceStatusCache({
    required ApiDatabaseService dbService,
    required ProjectContext projectContext,
  })  : _db = dbService,
        _projectContext = projectContext {
    _projectSub = _projectContext.activeProjectStream.listen((_) {
      // Project changed → previous rows are no longer relevant.
      _entries.clear();
      _bootstrapped = false;
      notifyListeners();
      // Trigger a bootstrap; failures are swallowed so a missing balance
      // table never crashes the UI.
      // ignore: discarded_futures
      bootstrap();
    });
  }

  final ApiDatabaseService _db;
  final ProjectContext _projectContext;
  StreamSubscription<dynamic>? _projectSub;

  final Map<String, CustomerBalanceStatusEntry> _entries = {};
  bool _bootstrapped = false;
  Future<void>? _inFlightBootstrap;

  /// Synchronous read used by widgets. Returns `null` while the bootstrap
  /// hasn't run for this INN; callers render the neutral state in that case.
  CustomerBalanceStatusEntry? entryFor(String inn) {
    if (inn.isEmpty) return null;
    return _entries[inn];
  }

  /// Convenience: just the status, defaulting to [CustomerBalanceStatus.unknown].
  CustomerBalanceStatus statusFor(String inn) =>
      entryFor(inn)?.status ?? CustomerBalanceStatus.unknown;

  /// Lazy bootstrap. Safe to call from `build` paths — repeated invocations
  /// share the in-flight future and only one DB scan happens per project.
  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    return _inFlightBootstrap ??= _doBootstrap().whenComplete(() {
      _inFlightBootstrap = null;
    });
  }

  Future<void> _doBootstrap() async {
    try {
      final db = await _db.database;
      final activeLimit = _projectContext.activeProject?.debtLimit;
      final activeCurrency =
          _projectContext.activeProject?.debtLimitCurrency ?? 'UZS';

      // Read every cached balance row. We don't filter by `project_name`
      // because legacy rows (pre-M1) may not match the active project's
      // code/name reliably; the visual cost of an over-broad set is nil
      // — entries for customers not on the active project are simply
      // never queried by `entryFor`.
      final rows = await db.query(
        'client_balances',
        columns: const [
          'inn',
          'balance',
          'debt_limit',
          'currency',
          'last_updated',
        ],
      );

      _entries.clear();
      for (final row in rows) {
        final inn = row['inn'] as String?;
        if (inn == null || inn.isEmpty) continue;
        final balance = (row['balance'] as num?)?.toDouble() ?? 0.0;
        final perRowLimit = (row['debt_limit'] as num?)?.toDouble();
        final limit = perRowLimit ?? activeLimit;
        final currency = (row['currency'] as String?) ?? activeCurrency;
        final lastUpdated = row['last_updated'] is String
            ? DateTime.tryParse(row['last_updated'] as String)
            : null;

        _entries[inn] = CustomerBalanceStatusEntry(
          status: computeCustomerBalanceStatus(balance: balance, limit: limit),
          balance: balance,
          limit: limit,
          currency: currency,
          lastUpdated: lastUpdated,
        );
      }
      _bootstrapped = true;
      notifyListeners();
      if (kDebugMode) {
        print(
            'CustomerBalanceStatusCache: bootstrapped ${_entries.length} entries');
      }
    } catch (e) {
      if (kDebugMode) {
        print('CustomerBalanceStatusCache: bootstrap failed: $e');
      }
      // Leave _bootstrapped=false so a future call can retry.
    }
  }

  /// Push update from [ClientBalanceService.saveClientBalance]. Updates the
  /// single entry and fires `notifyListeners` so visible cards re-render.
  void onBalanceUpdated(ClientBalance balance) {
    if (balance.inn.isEmpty) return;
    final activeLimit = _projectContext.activeProject?.debtLimit;
    final activeCurrency =
        _projectContext.activeProject?.debtLimitCurrency ?? 'UZS';
    final limit = balance.debtLimit ?? activeLimit;

    _entries[balance.inn] = CustomerBalanceStatusEntry(
      status: computeCustomerBalanceStatus(
        balance: balance.balance,
        limit: limit,
      ),
      balance: balance.balance,
      limit: limit,
      currency: balance.currency ?? activeCurrency,
      lastUpdated: balance.lastUpdated,
    );
    notifyListeners();
  }

  /// Force a fresh bootstrap (e.g. after a full sync). Discards the cache
  /// and re-reads from the DB.
  Future<void> refresh() async {
    _entries.clear();
    _bootstrapped = false;
    await bootstrap();
  }

  /// Drop a single entry and notify listeners. Called by
  /// `ClientBalanceService.deleteClientBalance` so the indicator on the
  /// affected card immediately disappears (M12 P1.2).
  void invalidate(String inn) {
    if (inn.isEmpty) return;
    if (_entries.remove(inn) != null) {
      notifyListeners();
    }
  }

  /// Drop everything. Called by `ClientBalanceService.clearAllBalances`
  /// — the bootstrap flag is reset so the next read re-loads from the DB
  /// (which is also empty after the clear, so this is a true reset).
  void clear() {
    _entries.clear();
    _bootstrapped = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _projectSub?.cancel();
    super.dispose();
  }
}
