import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/services/app_start_guard.dart';
import 'package:gloria_marketing_flutter/src/core/services/connectivity_monitor_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/core/utils/clock.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/auth_failure.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/login_gates_envelope.dart';

/// Hand-rolled fakes — keeps the test focused on the decision tree
/// without dragging in mockito codegen for service classes that have
/// complex constructors.
class _FakePrefs implements SharedPreferencesService {
  LoginGatesEnvelope? cached;
  bool migrated = false;

  @override
  LoginGatesEnvelope? getCachedGates() => cached;

  @override
  Future<void> setCachedGates(LoginGatesEnvelope envelope) async {
    cached = envelope;
  }

  @override
  Future<void> clearCachedGates() async {
    cached = null;
  }

  @override
  Future<void> migrateLegacyKeys() async {
    migrated = true;
  }

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

class _FakeTokenService implements TokenService {
  String? refreshAccessReturn;
  AuthFailure? refreshFailure;
  bool refreshCalled = false;

  @override
  Future<String?> refreshAccessV2() async {
    refreshCalled = true;
    return refreshAccessReturn;
  }

  @override
  AuthFailure? get lastV2RefreshFailure => refreshFailure;

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

class _FakeConnectivity implements ConnectivityMonitorService {
  bool online;
  _FakeConnectivity({required this.online});

  @override
  Future<bool> hasConnection() async => online;

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

class _FakeClock extends Clock {
  final DateTime now;
  const _FakeClock(this.now);
  @override
  DateTime nowUtc() => now;
}

LoginGatesEnvelope _envelope({
  DateTime? userActiveEnd,
  DateTime? licenseValidTo,
  bool bypass = false,
  DateTime? serverTime,
}) {
  return LoginGatesEnvelope(
    accessToken: 'a',
    refreshToken: 'r',
    userActiveEnd: userActiveEnd,
    licenseValidTo: licenseValidTo,
    organizationId: 'org-1',
    serverTime: serverTime ?? DateTime.utc(2026, 5, 1),
    bypass: bypass,
  );
}

void main() {
  group('AppStartGuard.decide', () {
    late _FakePrefs prefs;
    late _FakeTokenService token;
    late _FakeConnectivity connectivity;

    setUp(() {
      prefs = _FakePrefs();
      token = _FakeTokenService();
      connectivity = _FakeConnectivity(online: false);
    });

    test('1. no cached gates → showLogin', () async {
      final guard = AppStartGuard(
        prefs: prefs,
        tokenService: token,
        connectivity: connectivity,
        clock: _FakeClock(DateTime.utc(2026, 6, 1)),
      );
      final result = await guard.decide();
      expect(result.decision, StartDecision.showLogin);
      expect(prefs.migrated, isTrue);
    });

    test('2. clock tampering (now < serverTime) → revoked + clear', () async {
      prefs.cached = _envelope(serverTime: DateTime.utc(2026, 6, 1));
      final guard = AppStartGuard(
        prefs: prefs,
        tokenService: token,
        connectivity: connectivity,
        clock: _FakeClock(DateTime.utc(2026, 5, 1)), // earlier than serverTime
      );
      final result = await guard.decide();
      expect(result.decision, StartDecision.showLoginRevoked);
      expect(prefs.cached, isNull);
    });

    test('3a. online + refresh OK → showHome', () async {
      prefs.cached = _envelope(serverTime: DateTime.utc(2026, 5, 1));
      connectivity.online = true;
      token.refreshAccessReturn = 'new-access';
      final guard = AppStartGuard(
        prefs: prefs,
        tokenService: token,
        connectivity: connectivity,
        clock: _FakeClock(DateTime.utc(2026, 6, 1)),
      );
      final result = await guard.decide();
      expect(result.decision, StartDecision.showHome);
      expect(token.refreshCalled, isTrue);
    });

    test('3b. online + refresh denied → revoked + clear', () async {
      prefs.cached = _envelope(serverTime: DateTime.utc(2026, 5, 1));
      connectivity.online = true;
      token.refreshAccessReturn = null;
      token.refreshFailure = const LicenseExpiredFailure();
      final guard = AppStartGuard(
        prefs: prefs,
        tokenService: token,
        connectivity: connectivity,
        clock: _FakeClock(DateTime.utc(2026, 6, 1)),
      );
      final result = await guard.decide();
      expect(result.decision, StartDecision.showLoginRevoked);
      expect(result.reason, isA<LicenseExpiredFailure>());
      expect(prefs.cached, isNull);
    });

    test('4. offline + license expired → showLoginExpired', () async {
      prefs.cached = _envelope(
        licenseValidTo: DateTime.utc(2026, 4, 1),
        serverTime: DateTime.utc(2026, 3, 1),
      );
      connectivity.online = false;
      final guard = AppStartGuard(
        prefs: prefs,
        tokenService: token,
        connectivity: connectivity,
        clock: _FakeClock(DateTime.utc(2026, 6, 1)),
      );
      final result = await guard.decide();
      expect(result.decision, StartDecision.showLoginExpired);
      expect(result.reason, isA<LicenseExpiredFailure>());
      expect(prefs.cached, isNull);
    });

    test('5. offline + user_active_end passed → showLoginExpired', () async {
      prefs.cached = _envelope(
        userActiveEnd: DateTime.utc(2026, 4, 1),
        serverTime: DateTime.utc(2026, 3, 1),
      );
      connectivity.online = false;
      final guard = AppStartGuard(
        prefs: prefs,
        tokenService: token,
        connectivity: connectivity,
        clock: _FakeClock(DateTime.utc(2026, 6, 1)),
      );
      final result = await guard.decide();
      expect(result.decision, StartDecision.showLoginExpired);
      expect(result.reason, isA<UserOutsideActiveWindowFailure>());
    });

    test('6. offline + valid cache → showHome', () async {
      prefs.cached = _envelope(
        licenseValidTo: DateTime.utc(2027, 1, 1),
        serverTime: DateTime.utc(2026, 5, 1),
      );
      connectivity.online = false;
      final guard = AppStartGuard(
        prefs: prefs,
        tokenService: token,
        connectivity: connectivity,
        clock: _FakeClock(DateTime.utc(2026, 6, 1)),
      );
      final result = await guard.decide();
      expect(result.decision, StartDecision.showHome);
    });

    test('superuser bypass: license null is treated as no-expiry', () async {
      prefs.cached = _envelope(
        bypass: true,
        licenseValidTo: null,
        serverTime: DateTime.utc(2026, 5, 1),
      );
      connectivity.online = false;
      final guard = AppStartGuard(
        prefs: prefs,
        tokenService: token,
        connectivity: connectivity,
        clock: _FakeClock(DateTime.utc(2030, 6, 1)),
      );
      final result = await guard.decide();
      expect(result.decision, StartDecision.showHome);
    });
  });
}

