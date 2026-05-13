import 'dart:async';
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import 'package:gloria_marketing_flutter/src/core/services/local_uuid_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/notification_api_service.dart';

/// FCM token lifecycle (passport-mobile.md §2):
///
/// * `registerOnLogin()` — call once after a successful V2 login.
///   Fetches the current FCM token, gathers device metadata, and
///   submits `POST /notifications/devices/`. The returned device row id
///   is persisted so logout can revoke it.
/// * `onTokenRefresh` listener — wired in `registerOnLogin`; re-submits
///   the new token to the same endpoint (the backend marks the prior
///   row inactive automatically).
/// * `revokeOnLogout()` — fires `DELETE /devices/{id}/` and then
///   `FirebaseMessaging.deleteToken()` so the next login starts fresh.
///
/// Permission requests live in the UI layer per pasport §2.4 — this
/// service never prompts on its own.
class FcmTokenService {
  static const String _deviceTokenIdKey = 'notif_device_token_id';
  static const String _lastFcmTokenKey = 'notif_last_fcm_token';
  static const _uuid = Uuid();

  final NotificationApiService _api;
  final SharedPreferencesService _prefs;
  final LocalUuidService _uuidService;
  final FirebaseMessaging _messaging;
  final DeviceInfoPlugin _deviceInfo;

  StreamSubscription<String>? _refreshSub;

  FcmTokenService({
    required NotificationApiService api,
    required SharedPreferencesService prefs,
    required LocalUuidService uuidService,
    FirebaseMessaging? messaging,
    DeviceInfoPlugin? deviceInfo,
  })  : _api = api,
        _prefs = prefs,
        _uuidService = uuidService,
        _messaging = messaging ?? FirebaseMessaging.instance,
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  /// Locally cached `UserDeviceToken.id` — needed for revoke. `null`
  /// before the first successful register.
  String? get currentDeviceTokenId =>
      _prefs.preferences.getString(_deviceTokenIdKey);

  /// Locally cached FCM token last sent to the backend. Used to skip
  /// no-op re-registers (heartbeat path).
  String? get lastFcmTokenSent =>
      _prefs.preferences.getString(_lastFcmTokenKey);

  /// Register the current FCM token with the backend. Idempotent: safe
  /// to call on every login / app boot once authenticated.
  ///
  /// Returns the persisted device token id, or `null` if FCM did not
  /// produce a token (e.g. iOS notification permission denied).
  Future<String?> registerOnLogin({String? forcedFcmToken}) async {
    try {
      // On iOS the token is only minted after APNs registration. We
      // don't force it here — the UI requests permission at first
      // relevant action (§2.4). If permission was already granted
      // earlier, getToken() will return a value.
      final fcmToken = forcedFcmToken ?? await _messaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        if (kDebugMode) {
          debugPrint(
              '[FCM] getToken() returned null — permission likely not granted yet');
        }
        // Still listen for rotation so we register once the OS issues a
        // token after permission is granted.
        _attachRefreshListener();
        return null;
      }

      // Skip if the same token was already pushed AND we have a stored
      // device row id. Otherwise force a fresh register (eg. server
      // reset, app reinstall).
      final lastSent = lastFcmTokenSent;
      final storedRowId = currentDeviceTokenId;
      if (lastSent == fcmToken &&
          storedRowId != null &&
          storedRowId.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('[FCM] token unchanged, skipping re-register');
        }
        _attachRefreshListener();
        return storedRowId;
      }

      final row = await _submit(fcmToken);
      await _prefs.preferences.setString(_deviceTokenIdKey, row.id);
      await _prefs.preferences.setString(_lastFcmTokenKey, fcmToken);

      _attachRefreshListener();

      if (kDebugMode) {
        debugPrint(
            '[FCM] registered device row=${row.id} platform=${row.platform}');
      }
      return row.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] registerOnLogin failed: $e');
      }
      // Listener still installed so a later rotation re-attempts.
      _attachRefreshListener();
      return null;
    }
  }

  /// Logout — revoke the cached device row server-side and clear the
  /// local FCM token so the next login starts a fresh subscription.
  Future<void> revokeOnLogout() async {
    final id = currentDeviceTokenId;
    try {
      if (id != null && id.isNotEmpty) {
        await _api.revokeDevice(id);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] revokeDevice failed (non-critical): $e');
      }
    }

    try {
      await _messaging.deleteToken();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] deleteToken failed (non-critical): $e');
      }
    }

    await _prefs.preferences.remove(_deviceTokenIdKey);
    await _prefs.preferences.remove(_lastFcmTokenKey);

    await _detachRefreshListener();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _attachRefreshListener() {
    if (_refreshSub != null) return;
    _refreshSub = _messaging.onTokenRefresh.listen((newToken) async {
      try {
        if (newToken.isEmpty) return;
        if (newToken == lastFcmTokenSent) return;
        final row = await _submit(newToken);
        await _prefs.preferences.setString(_deviceTokenIdKey, row.id);
        await _prefs.preferences.setString(_lastFcmTokenKey, newToken);
        if (kDebugMode) {
          debugPrint('[FCM] rotated → row=${row.id}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[FCM] rotation submit failed: $e');
        }
      }
    });
  }

  Future<void> _detachRefreshListener() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
  }

  Future<DeviceTokenRow> _submit(String fcmToken) async {
    final platform = Platform.isIOS
        ? 'ios'
        : Platform.isAndroid
            ? 'android'
            : 'unknown';
    final deviceId = await _resolveDeviceId();
    final appVersion = await _resolveAppVersion();
    final clientUuid = await _uuidService.getOrCreateLocalUuid();
    return _api.registerDevice(
      fcmToken: fcmToken,
      platform: platform,
      deviceId: deviceId,
      appVersion: appVersion,
      clientUuid: clientUuid,
      idempotencyKey: _uuid.v4(),
    );
  }

  Future<String> _resolveDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return info.id;
      }
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return info.identifierForVendor ?? '';
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] _resolveDeviceId failed: $e');
      }
    }
    return '';
  }

  Future<String> _resolveAppVersion() async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      return pkg.version;
    } catch (_) {
      return '';
    }
  }
}
