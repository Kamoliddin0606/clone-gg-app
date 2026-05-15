// Skeleton tests for OrderBalanceGate (M14).
//
// Coverage matrix per docs/customer-balance-mobile.md M14:
//   online × under-limit  → not blocked
//   online × over-limit   → blocked, source = "fresh"
//   offline × cache hit   × under-limit → not blocked, source = "local"
//   offline × cache hit   × over-limit  → blocked, source = "local"
//   offline × cache miss  → blocked, reason = "no_cached_balance"
//   no active project     → blocked, reason = "no_active_project"
//
// We hand-roll fakes instead of mockito here because mockito's `anyNamed`
// can't satisfy non-nullable parameters under null-safety without code
// generation. The fakes are intentionally minimal — they only override the
// methods the gate actually invokes.

import 'package:flutter_test/flutter_test.dart';

import 'package:gloria_marketing_flutter/src/core/services/client_balance_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/connectivity_monitor_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/project_context.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_balance.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_project.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/order_balance_gate.dart';

class _FakeBalanceService implements ClientBalanceService {
  ClientBalance? fetchResult;
  ClientBalance? cachedResult;
  bool fetchThrows = false;

  @override
  Future<ClientBalance?> fetchClientBalance({
    required String code1c,
    required String projectCode,
    String? inn,
    bool forceRefresh = false,
  }) async {
    if (fetchThrows) throw Exception('boom');
    return fetchResult;
  }

  @override
  Future<ClientBalance?> getCachedClientBalance({
    required String code1c,
    required String projectCode,
    String? inn,
  }) async =>
      cachedResult;

  // The gate doesn't touch any other ClientBalanceService surface; satisfy
  // the interface by routing everything else to noSuchMethod (returns null).
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeConnectivity implements ConnectivityMonitorService {
  bool online = true;

  @override
  bool get isConnected => online;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProjectContext implements ProjectContext {
  UserProject? project;

  @override
  UserProject? get activeProject => project;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TradingPoint _tp() => const TradingPoint(
      id: 'C-1',
      name: 'Test customer',
      address: '',
      phone: '',
      ownerName: '',
      contactPerson: '',
      inn: '308976156',
      status: 'active',
      lastVisitDate: '',
      hasOrders: false,
      hasContracts: false,
      isVisited: false,
      hasContract: false,
      latitude: 0,
      longitude: 0,
      region: '',
      district: '',
      signboard: '',
      referencePoint: '',
      responsiblePerson: '',
      responsiblePersonPhone: '',
      tradePointType: '',
      creditLimit: 0,
      accumulatedCredit: 0,
      codeRegion: '',
      code: 'C-1',
      code1c: '00-00053242',
    );

UserProject _project({double? debtLimit}) => UserProject(
      userCode: 'U1',
      code: 'EVYAP',
      name: 'EVYAP',
      debtLimit: debtLimit,
      debtLimitCurrency: 'UZS',
    );

ClientBalance _balance({
  required double value,
  double? limit,
  bool? blocked,
  String source = 'fresh',
  DateTime? lastUpdated,
}) =>
    ClientBalance(
      inn: '308976156',
      balance: value,
      contractBalances: const [],
      orderBalances: const [],
      lastUpdated: lastUpdated ?? DateTime.now(),
      projectName: 'EVYAP',
      debtLimit: limit,
      debtLimitCurrency: 'UZS',
      currency: 'UZS',
      blocked: blocked,
      source: source,
    );

void main() {
  late _FakeBalanceService balanceService;
  late _FakeConnectivity connectivity;
  late _FakeProjectContext projectContext;
  late OrderBalanceGate gate;

  setUp(() {
    balanceService = _FakeBalanceService();
    connectivity = _FakeConnectivity();
    projectContext = _FakeProjectContext();
    gate = OrderBalanceGate(
      balanceService: balanceService,
      connectivity: connectivity,
      projectContext: projectContext,
    );
  });

  group('online', () {
    setUp(() {
      connectivity.online = true;
      projectContext.project = _project(debtLimit: 5000000);
    });

    test('under limit → not blocked, source from backend', () async {
      balanceService.fetchResult =
          _balance(value: 1000000, limit: 5000000, blocked: false);

      final result = await gate.check(_tp());

      expect(result.blocked, false);
      expect(result.source, 'fresh');
      expect(result.isOffline, false);
    });

    test('blocked=true from backend wins regardless of local math', () async {
      balanceService.fetchResult =
          _balance(value: 6000000, limit: 5000000, blocked: true);

      final result = await gate.check(_tp());

      expect(result.blocked, true);
      expect(result.reason, 'debt_limit_exceeded');
    });

    test('null fetch + null cache → blocked with fetch_failed reason',
        () async {
      balanceService.fetchResult = null;
      balanceService.cachedResult = null;

      final result = await gate.check(_tp());

      expect(result.blocked, true);
      expect(result.reason, 'fetch_failed');
    });
  });

  group('offline', () {
    setUp(() {
      connectivity.online = false;
      projectContext.project = _project(debtLimit: 5000000);
    });

    test('cache hit + under limit → not blocked, source=local', () async {
      balanceService.cachedResult = _balance(value: 1000000);

      final result = await gate.check(_tp());

      expect(result.blocked, false);
      expect(result.source, 'local');
      expect(result.isOffline, true);
    });

    test('cache hit + over limit → blocked locally', () async {
      balanceService.cachedResult = _balance(value: 6000000);

      final result = await gate.check(_tp());

      expect(result.blocked, true);
      expect(result.reason, 'debt_limit_exceeded');
      expect(result.source, 'local');
    });

    test('cache miss → blocked with no_cached_balance reason', () async {
      balanceService.cachedResult = null;

      final result = await gate.check(_tp());

      expect(result.blocked, true);
      expect(result.reason, 'no_cached_balance');
    });

    test('cached balance >24h old is flagged isStale', () async {
      balanceService.cachedResult = _balance(
        value: 100,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 30)),
      );

      final result = await gate.check(_tp());

      expect(result.isStale, true);
    });
  });

  test('no active project → blocked with no_active_project reason', () async {
    connectivity.online = true;
    projectContext.project = null;

    final result = await gate.check(_tp());

    expect(result.blocked, true);
    expect(result.reason, 'no_active_project');
  });
}
