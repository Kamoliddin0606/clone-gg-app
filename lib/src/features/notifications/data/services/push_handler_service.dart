import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/presentation/widgets/in_app_banner.dart';

/// One-stop wiring for the three FCM delivery states (passport §3):
///   1. **Foreground** — `onMessage`: surface in-app banner via
///      [InAppBannerController]; do NOT draw the system tray.
///   2. **Background (process alive, screen off)** — top-level
///      `onBackgroundMessage`: persist the row to sqflite so the list
///      reflects the push even if the user never taps it.
///   3. **Terminated → tap** — `getInitialMessage()` + `onMessageOpenedApp`:
///      route through [NotificationTapRouter] once the navigator is
///      mounted.
///
/// The handler is intentionally thin: every push payload carries only
/// `notification_id` + metadata (passport §3.4). The repository fetches
/// the full row when needed.
class PushHandlerService {
  static const _androidChannelId = 'selup_default';
  static const _androidChannelName = 'SelUp notifications';
  static const _androidChannelDescription =
      'Default notification channel for SelUp app push messages';

  final NotificationRepository _repo;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  /// Set once a deep-link tap should be routed. Called by the app
  /// shell after the navigator is ready.
  void Function(RemoteMessage message)? onTap;

  /// Optional foreground banner builder. Set by the app shell once the
  /// navigator's `Overlay` is available. Returning null lets the
  /// service fall back to a system-tray local notification.
  void Function(RemoteMessage message)? onForegroundBanner;

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;
  bool _initialized = false;

  PushHandlerService({
    required NotificationRepository repo,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _repo = repo,
        _messaging = messaging ?? FirebaseMessaging.instance,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  /// Idempotent — safe to call from `main()` and again after login.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _bootstrapLocalNotifications();

    // iOS-only: tell FCM to surface notifications while the app is in
    // the foreground via APNs alert (we still draw the in-app banner;
    // this just keeps badge/sound consistent).
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false, // we render our own banner
      badge: true,
      sound: true,
    );

    _foregroundSub = FirebaseMessaging.onMessage.listen(_handleForeground);
    _openedAppSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedApp);

    // Process the message that launched the app from terminated state.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      // Defer slightly so the navigator is mounted before we route.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleOpenedApp(initial);
      });
    }
  }

  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _openedAppSub?.cancel();
    _foregroundSub = null;
    _openedAppSub = null;
    _initialized = false;
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  Future<void> _handleForeground(RemoteMessage message) async {
    final id = _readNotificationId(message);
    if (kDebugMode) {
      debugPrint('[PUSH] foreground id=$id data=${message.data}');
    }
    // Refresh the full record from the backend so the list, banner,
    // and detail screens all see the same canonical content.
    if (id != null) {
      try {
        await _repo.fetchAndCache(id);
      } catch (e) {
        if (kDebugMode) debugPrint('[PUSH] foreground fetchAndCache: $e');
      }
    }
    if (onForegroundBanner != null) {
      onForegroundBanner!(message);
    } else {
      // No banner handler attached yet (e.g. on the login screen) —
      // fall back to the OS tray so the user still sees it.
      await _showSystemTray(message);
    }
  }

  Future<void> _handleOpenedApp(RemoteMessage message) async {
    final id = _readNotificationId(message);
    if (kDebugMode) {
      debugPrint('[PUSH] opened-app id=$id data=${message.data}');
    }
    if (id != null) {
      try {
        await _repo.fetchAndCache(id);
      } catch (e) {
        if (kDebugMode) debugPrint('[PUSH] opened-app fetchAndCache: $e');
      }
    }
    onTap?.call(message);
  }

  // ---------------------------------------------------------------------------
  // Local notifications (foreground fallback)
  // ---------------------------------------------------------------------------

  Future<void> _bootstrapLocalNotifications() async {
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    // Pre-create the default Android channel so the OS settings panel
    // shows a friendly name immediately, not "Miscellaneous".
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDescription,
        importance: Importance.high,
      ),
    );
  }

  Future<void> _showSystemTray(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String? ?? '';
    final body = notification?.body ?? message.data['body'] as String? ?? '';
    if (title.isEmpty && body.isEmpty) return;
    final id = _readNotificationId(message);
    await _localNotifications.show(
      _stableTrayId(id),
      title,
      body,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(presentBadge: true),
      ),
      payload: id,
    );
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final id = response.payload;
    if (id == null || id.isEmpty) return;
    final synthetic = RemoteMessage(data: {'notification_id': id});
    onTap?.call(synthetic);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String? _readNotificationId(RemoteMessage message) {
    final raw = message.data['notification_id'];
    if (raw is String && raw.isNotEmpty) return raw;
    return null;
  }

  /// Hash the notification UUID into a stable 31-bit int so repeated
  /// pushes for the same notification collapse on the tray.
  int _stableTrayId(String? id) {
    if (id == null || id.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch.remainder(0x7fffffff);
    }
    return id.hashCode & 0x7fffffff;
  }
}

/// Top-level background handler. Required by `firebase_messaging` — it
/// is invoked in a separate isolate when the app is not in the
/// foreground but the process is still alive. Must be a top-level or
/// static function (not a closure).
///
/// We keep it intentionally small: persist a stub row keyed by
/// `notification_id` so the list screen shows it on the next open. The
/// full content is fetched the next time the app comes online.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  try {
    final id = message.data['notification_id'];
    if (id is! String || id.isEmpty) return;
    // The isolate may not have the service locator initialised — guard
    // it. If unavailable, do nothing; the next foreground sync covers
    // this row.
    if (!sl.isRegistered<NotificationRepository>()) return;
    await sl<NotificationRepository>().recordBackgroundPush(message);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[PUSH] background handler error: $e');
    }
  }
}
