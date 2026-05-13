import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gloria_marketing_flutter/src/core/services/local_uuid_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/fcm_token_service.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/notification_api_service.dart';

/// Token lifecycle (passport-mobile.md §2). We exercise the contract
/// the way AuthBloc uses it:
///   * registerOnLogin → API hit + row id persisted.
///   * Repeat register with the same token → no extra API call.
///   * Repeat with a new token → API hit again.
///   * revokeOnLogout → DELETE /devices/{id} + deleteToken + prefs wipe.

class _FakeMessaging extends Fake implements FirebaseMessaging {
  String? token = 'fcm-token-1';
  bool deleteCalled = false;
  final StreamController<String> _refreshController =
      StreamController<String>.broadcast();

  @override
  Future<String?> getToken({String? vapidKey}) async => token;

  @override
  Stream<String> get onTokenRefresh => _refreshController.stream;

  @override
  Future<void> deleteToken() async {
    deleteCalled = true;
    token = null;
  }

  void emitRefresh(String newToken) {
    _refreshController.add(newToken);
  }

  Future<void> dispose() async {
    await _refreshController.close();
  }
}

class _FakeApi extends Fake implements NotificationApiService {
  int registerCalls = 0;
  int revokeCalls = 0;
  bool revokeThrows = false;
  String nextRowId = 'row-1';
  String? lastFcmTokenSent;

  @override
  Future<DeviceTokenRow> registerDevice({
    required String fcmToken,
    required String platform,
    required String deviceId,
    required String appVersion,
    required String clientUuid,
    String? idempotencyKey,
  }) async {
    registerCalls++;
    lastFcmTokenSent = fcmToken;
    return DeviceTokenRow(
      id: nextRowId,
      fcmToken: fcmToken,
      platform: platform,
    );
  }

  @override
  Future<void> revokeDevice(String id) async {
    revokeCalls++;
    if (revokeThrows) {
      throw const NotificationApiException(
        code: 'network_error',
        message: 'offline',
      );
    }
  }
}

class _FakeUuid extends Fake implements LocalUuidService {
  @override
  Future<String> getOrCreateLocalUuid() async => 'install-uuid';
}

void main() {
  late SharedPreferencesService prefs;
  late _FakeMessaging messaging;
  late _FakeApi api;
  late FcmTokenService service;

  setUp(() async {
    // SharedPreferencesService is a cached async singleton — the
    // mock-values reset alone does not flush its in-memory cache.
    // Explicitly clear so each test starts with empty prefs.
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferencesService.getInstance();
    await prefs.preferences.clear();
    messaging = _FakeMessaging();
    api = _FakeApi();
    service = FcmTokenService(
      api: api,
      prefs: prefs,
      uuidService: _FakeUuid(),
      messaging: messaging,
    );
  });

  tearDown(() async {
    await messaging.dispose();
  });

  group('registerOnLogin', () {
    test('happy path: registers + caches row id', () async {
      final rowId = await service.registerOnLogin();

      expect(rowId, 'row-1');
      expect(api.registerCalls, 1);
      expect(api.lastFcmTokenSent, 'fcm-token-1');
      expect(service.currentDeviceTokenId, 'row-1');
      expect(service.lastFcmTokenSent, 'fcm-token-1');
    });

    test('skips re-register when token + row id unchanged', () async {
      await service.registerOnLogin();
      await service.registerOnLogin();

      expect(api.registerCalls, 1,
          reason: 'second call must short-circuit (no-op)');
    });

    test('re-registers when FCM rotates the token', () async {
      await service.registerOnLogin();
      expect(api.registerCalls, 1);

      // Simulate FCM issuing a fresh token (server reset, app reinstall).
      messaging.token = 'fcm-token-2';
      api.nextRowId = 'row-2';
      await service.registerOnLogin();

      expect(api.registerCalls, 2);
      expect(api.lastFcmTokenSent, 'fcm-token-2');
      expect(service.currentDeviceTokenId, 'row-2');
    });

    test('FCM returning null token → no API call, no crash', () async {
      messaging.token = null;
      final rowId = await service.registerOnLogin();

      expect(rowId, isNull);
      expect(api.registerCalls, 0);
      expect(service.currentDeviceTokenId, isNull);
    });

    test('explicit forcedFcmToken overrides FCM', () async {
      final rowId = await service.registerOnLogin(
        forcedFcmToken: 'override-token',
      );

      expect(rowId, 'row-1');
      expect(api.lastFcmTokenSent, 'override-token');
    });

    test('API failure is swallowed (auth flow must not block)', () async {
      // Wire an API that throws on register.
      final throwingApi = _FakeApi();
      final svc = FcmTokenService(
        api: _ThrowingApi(throwingApi),
        prefs: prefs,
        uuidService: _FakeUuid(),
        messaging: messaging,
      );
      // Should NOT rethrow.
      final rowId = await svc.registerOnLogin();
      expect(rowId, isNull);
      // No row id persisted on failure.
      expect(svc.currentDeviceTokenId, isNull);
    });
  });

  group('onTokenRefresh listener', () {
    test('rotation emits → API re-register + cache update', () async {
      await service.registerOnLogin();
      expect(api.registerCalls, 1);

      api.nextRowId = 'row-rotated';
      messaging.emitRefresh('fcm-token-rotated');
      // Let the async listener finish.
      await Future<void>.delayed(Duration.zero);

      expect(api.registerCalls, 2);
      expect(api.lastFcmTokenSent, 'fcm-token-rotated');
      expect(service.currentDeviceTokenId, 'row-rotated');
    });

    test('rotation to the SAME token is skipped', () async {
      await service.registerOnLogin();
      expect(api.registerCalls, 1);

      messaging.emitRefresh('fcm-token-1'); // same as initial
      await Future<void>.delayed(Duration.zero);

      expect(api.registerCalls, 1);
    });
  });

  group('revokeOnLogout', () {
    test('hits API + clears local state', () async {
      await service.registerOnLogin();
      expect(service.currentDeviceTokenId, 'row-1');

      await service.revokeOnLogout();

      expect(api.revokeCalls, 1);
      expect(messaging.deleteCalled, isTrue);
      expect(service.currentDeviceTokenId, isNull);
      expect(service.lastFcmTokenSent, isNull);
    });

    test('survives API failure and still clears local state', () async {
      await service.registerOnLogin();
      api.revokeThrows = true;

      await service.revokeOnLogout();

      expect(service.currentDeviceTokenId, isNull,
          reason: 'local cleanup must run even if the server call failed');
    });

    test('no-op when no device id was ever cached', () async {
      // No registerOnLogin first.
      await service.revokeOnLogout();
      expect(api.revokeCalls, 0,
          reason: 'no device id → no DELETE attempt');
      expect(messaging.deleteCalled, isTrue,
          reason: 'still wipe the FCM token locally');
    });
  });
}

class _ThrowingApi extends Fake implements NotificationApiService {
  _ThrowingApi(this._inner);
  // ignore: unused_field
  final _FakeApi _inner;

  @override
  Future<DeviceTokenRow> registerDevice({
    required String fcmToken,
    required String platform,
    required String deviceId,
    required String appVersion,
    required String clientUuid,
    String? idempotencyKey,
  }) async {
    throw const NotificationApiException(
      code: 'network_error',
      message: 'offline',
    );
  }

  @override
  Future<void> revokeDevice(String id) async {}
}
