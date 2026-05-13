import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/db/notification_db_dao.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/models/notification_preferences.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/notification_preferences_service.dart';
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
///
/// **Phase 2** wiring:
///   * Client-side filter — pushes whose `type` the user disabled, OR
///     that arrive inside the DND window, are still persisted to the
///     local cache but the foreground banner is suppressed.
///   * Per-type Android channels — `selup_debt_alert`, `selup_order_new`,
///     etc. let the OS Settings app expose granular sound/vibration
///     control. Channel importance is derived from priority +
///     [NotificationPreferences.soundFor].
class PushHandlerService {
  static const _defaultAndroidChannelId = 'selup_default';
  static const _defaultAndroidChannelName = 'Boshqa bildirishnomalar';
  static const _defaultAndroidChannelDescription =
      'Default channel used when the notification type is unknown.';

  final NotificationRepository _repo;
  final NotificationDbDao _dao;
  final NotificationPreferencesService _preferences;
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
  StreamSubscription<NotificationPreferences>? _prefsSub;
  bool _initialized = false;

  PushHandlerService({
    required NotificationRepository repo,
    required NotificationDbDao dao,
    required NotificationPreferencesService preferences,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _repo = repo,
        _dao = dao,
        _preferences = preferences,
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

    // Re-sync Android channels every time the user updates the
    // sound/vibration profile, so the OS Settings panel always shows
    // the current behaviour. Channel `setImportance` cannot be lowered
    // once created (Android limitation) — fresh per-priority subchannel
    // ids are used so importance changes propagate.
    _prefsSub = _preferences.stream.listen((_) {
      _syncAndroidChannels();
    });

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
    await _prefsSub?.cancel();
    _foregroundSub = null;
    _openedAppSub = null;
    _prefsSub = null;
    _initialized = false;
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  Future<void> _handleForeground(RemoteMessage message) async {
    final id = _readNotificationId(message);
    final type = _readType(message);
    if (kDebugMode) {
      debugPrint('[PUSH] foreground id=$id type=$type data=${message.data}');
    }
    // Refresh the full record from the backend so the list, banner,
    // and detail screens all see the same canonical content.
    // The row lands in the cache REGARDLESS of preferences — the user
    // can still find it later in the list. Only the visual interrupt
    // is gated.
    if (id != null) {
      try {
        await _repo.fetchAndCache(id);
      } catch (e) {
        if (kDebugMode) debugPrint('[PUSH] foreground fetchAndCache: $e');
      }
    }

    if (!shouldShowForeground(type: type)) {
      if (kDebugMode) {
        debugPrint(
            '[PUSH] foreground suppressed (type=$type, dnd=${_preferences.value.isInDnd()})');
      }
      return;
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

  /// Public for unit tests + the marketing tab's manual preview. Pure
  /// function over the in-memory preferences snapshot.
  @visibleForTesting
  bool shouldShowForeground({String? type, DateTime? now}) {
    final prefs = _preferences.value;
    if (type != null && !prefs.isTypeEnabled(type)) return false;
    if (prefs.isInDnd(now)) return false;
    return true;
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
    await _syncAndroidChannels();
  }

  /// Create one Android channel per (type, priority) bucket. Channel
  /// ids stay stable for the same (type, soundLevel) pair so the OS
  /// settings remain meaningful across rebuilds; when the user changes
  /// the sound level we create a new channel id (Android forbids
  /// lowering channel importance after creation).
  Future<void> _syncAndroidChannels() async {
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    // Always keep the default fallback for unknown server types.
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _defaultAndroidChannelId,
        _defaultAndroidChannelName,
        description: _defaultAndroidChannelDescription,
        importance: Importance.high,
      ),
    );

    final prefs = _preferences.value;
    for (final type in NotificationTypes.all) {
      // Same channel shape for both priorities the type typically uses
      // — agents only see urgent/high for debts and normal for
      // announcements. We register one channel per type using the
      // sound level chosen for `high` priority, which is the dominant
      // bucket. Per-priority differentiation can be split later.
      final level = prefs.soundFor('high');
      final id = _channelIdFor(type, level);
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          id,
          _channelNameFor(type),
          description: _channelDescriptionFor(type),
          importance: _importanceFor(level),
          enableVibration: level != NotificationSoundLevel.silent,
          playSound: level == NotificationSoundLevel.sound,
        ),
      );
    }
  }

  Future<void> _showSystemTray(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String? ?? '';
    final body = notification?.body ?? message.data['body'] as String? ?? '';
    if (title.isEmpty && body.isEmpty) return;
    final id = _readNotificationId(message);
    final type = _readType(message);
    final priority = _readPriority(message);
    final level = _preferences.value.soundFor(priority);
    final isUrgent = priority == 'urgent';
    final isKnownType = type != null && NotificationTypes.all.contains(type);
    final channelId =
        isKnownType ? _channelIdFor(type, level) : _defaultAndroidChannelId;
    final channelName =
        isKnownType ? _channelNameFor(type) : _defaultAndroidChannelName;
    // Phase 2 stretch — grouping. Same key for all notifications of
    // the same type so iOS collapses them in the lock screen + Android
    // can attach a group summary below.
    final groupKey = groupKeyFor(type);

    await _localNotifications.show(
      _stableTrayId(id),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: _channelDescriptionFor(type ?? ''),
          // Phase 2c: urgent priority forces MAX importance so the
          // heads-up banner bypasses DND on Android. The user's
          // sound-level pref still controls whether audio plays.
          importance: isUrgent ? Importance.max : _importanceFor(level),
          priority: isUrgent ? Priority.max : _trayPriorityFor(level),
          // `alarm` category lets the OS bypass Do-Not-Disturb on
          // Android 12+ when the user has whitelisted the app.
          category: isUrgent ? AndroidNotificationCategory.alarm : null,
          playSound: level == NotificationSoundLevel.sound,
          enableVibration: level != NotificationSoundLevel.silent,
          groupKey: groupKey,
        ),
        iOS: DarwinNotificationDetails(
          presentBadge: true,
          presentSound: level == NotificationSoundLevel.sound,
          // Phase 2 stretch — iOS auto-groups by thread identifier.
          threadIdentifier: groupKey,
          // Phase 2c: urgent → critical interruption. iOS silently
          // downgrades to `timeSensitive` (or active) when the app
          // does NOT hold the `com.apple.developer.usernotifications.
          // critical-alerts` entitlement, so this is safe to ship
          // before Apple has approved the entitlement request.
          interruptionLevel: isUrgent
              ? InterruptionLevel.critical
              : InterruptionLevel.active,
        ),
      ),
      payload: id,
    );

    // Android-only: refresh the group summary card after every push
    // so the InboxStyle preview reflects the latest N rows. iOS draws
    // its own stack via `threadIdentifier` — no summary needed.
    if (isKnownType) {
      await _refreshAndroidGroupSummary(type, channelId, channelName);
    }
  }

  /// Drop or refresh the Android group summary for [type]. The summary
  /// is a separate notification with `setAsGroupSummary: true`; Android
  /// renders it as the parent card grouping all messages with the same
  /// [groupKey]. We use a stable per-type id so successive pushes
  /// replace rather than stack.
  Future<void> _refreshAndroidGroupSummary(
    String type,
    String channelId,
    String channelName,
  ) async {
    try {
      final lines = await _dao.recentUnreadByType(type, limit: 5);
      final count = await _dao.unreadCountByType(type);
      // Single notification doesn't need a summary card.
      if (lines.length <= 1) {
        await _localNotifications.cancel(summaryIdFor(type));
        return;
      }
      final groupKey = groupKeyFor(type);
      final preview = lines
          .map((n) => n.title.isEmpty
              ? n.body
              : '${n.title} — ${n.body}')
          .map(_oneLine)
          .toList(growable: false);
      final summaryTitle = summaryTitleFor(type, count);

      await _localNotifications.show(
        summaryIdFor(type),
        summaryTitle,
        // Body is hidden behind the InboxStyle on Android — provide
        // the most recent line for accessibility / older OS versions.
        preview.isEmpty ? '' : preview.first,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: _channelDescriptionFor(type),
            groupKey: groupKey,
            setAsGroupSummary: true,
            styleInformation: InboxStyleInformation(
              preview,
              summaryText: '$count ta yangi',
            ),
            // Summary should never make noise — the row notifications
            // already alerted the user.
            importance: Importance.low,
            priority: Priority.low,
            playSound: false,
            enableVibration: false,
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PUSH] group summary refresh failed (non-critical): $e');
      }
    }
  }

  /// Single-source-of-truth for the (group key, thread identifier)
  /// shared by all notifications of the same type. Public so unit
  /// tests can pin the wire format.
  @visibleForTesting
  static String groupKeyFor(String? type) {
    if (type == null || type.isEmpty) return 'selup_default';
    return 'selup_$type';
  }

  /// Stable Android notification id for the group summary card.
  /// Negative bit so it cannot collide with row hashes (those use the
  /// notification UUID hashCode masked to 31 bits non-negative).
  @visibleForTesting
  static int summaryIdFor(String type) =>
      0x40000000 | (type.hashCode & 0x3fffffff);

  /// Localised "N new TYPE" title for the group summary card.
  @visibleForTesting
  static String summaryTitleFor(String type, int count) {
    final label = _summaryLabelFor(type);
    return '$count ta yangi $label';
  }

  static String _summaryLabelFor(String type) {
    switch (type) {
      case NotificationTypes.debtAlert:
        return 'qarz ogohlantirishi';
      case NotificationTypes.orderNew:
        return 'buyurtma';
      case NotificationTypes.stockLotExpiring:
        return 'lot tugashi';
      case NotificationTypes.systemAnnouncement:
        return 'e\'lon';
      default:
        return 'bildirishnoma';
    }
  }

  static String _oneLine(String input) {
    final trimmed = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (trimmed.length <= 80) return trimmed;
    return '${trimmed.substring(0, 77)}...';
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final id = response.payload;
    if (id == null || id.isEmpty) return;
    final synthetic = RemoteMessage(data: {'notification_id': id});
    onTap?.call(synthetic);
  }

  // ---------------------------------------------------------------------------
  // Channel helpers
  // ---------------------------------------------------------------------------

  String _channelIdFor(String type, NotificationSoundLevel level) =>
      'selup_${type}_${level.name}';

  String _channelNameFor(String type) {
    switch (type) {
      case NotificationTypes.debtAlert:
        return 'Qarz ogohlantirishlari';
      case NotificationTypes.orderNew:
        return 'Yangi buyurtmalar';
      case NotificationTypes.stockLotExpiring:
        return 'Lot tugashi';
      case NotificationTypes.systemAnnouncement:
        return 'Tizim e\'lonlari';
      default:
        return 'Bildirishnomalar';
    }
  }

  String _channelDescriptionFor(String type) {
    switch (type) {
      case NotificationTypes.debtAlert:
        return 'Mijoz qarzlari bo\'yicha ogohlantirishlar.';
      case NotificationTypes.orderNew:
        return 'Yangi buyurtma kelganida bildirishnoma.';
      case NotificationTypes.stockLotExpiring:
        return 'Ombor lot muddati tugashi haqida bildirishnoma.';
      case NotificationTypes.systemAnnouncement:
        return 'Tizim va boshqaruv e\'lonlari.';
      default:
        return 'Boshqa bildirishnoma turlari.';
    }
  }

  Importance _importanceFor(NotificationSoundLevel level) {
    switch (level) {
      case NotificationSoundLevel.silent:
        return Importance.low;
      case NotificationSoundLevel.vibrate:
        return Importance.defaultImportance;
      case NotificationSoundLevel.sound:
        return Importance.high;
    }
  }

  Priority _trayPriorityFor(NotificationSoundLevel level) {
    switch (level) {
      case NotificationSoundLevel.silent:
        return Priority.low;
      case NotificationSoundLevel.vibrate:
        return Priority.defaultPriority;
      case NotificationSoundLevel.sound:
        return Priority.high;
    }
  }

  // ---------------------------------------------------------------------------
  // Message inspection
  // ---------------------------------------------------------------------------

  String? _readNotificationId(RemoteMessage message) {
    final raw = message.data['notification_id'];
    if (raw is String && raw.isNotEmpty) return raw;
    return null;
  }

  String? _readType(RemoteMessage message) {
    final raw = message.data['type'];
    if (raw is String && raw.isNotEmpty) return raw;
    return null;
  }

  String _readPriority(RemoteMessage message) {
    final raw = message.data['priority'];
    if (raw is String && raw.isNotEmpty) return raw;
    return 'normal';
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
