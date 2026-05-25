// =============================================================================
// ForegroundServiceKeeper
// =============================================================================
//
// Thin wrapper around `flutter_foreground_task` whose sole purpose is to
// keep the Android app process alive while the user has the screen off or
// is in another app. The location tracking logic itself lives in
// `BackgroundLocationTrackingService` (main isolate); without a running
// foreground service Android 8+ aggressively kills the process after a
// few minutes of background activity, which silently freezes the
// tracking timers.
//
// We deliberately keep the [TaskHandler] body trivial. Moving the full
// telemetry pipeline into the foreground-task isolate would mean
// duplicating service-locator setup, prefs access, token refresh, dio
// configuration, etc. — a high-risk refactor for very little gain. The
// foreground service notification alone is what Android keys off of when
// deciding whether to keep the process alive, and the main isolate's
// `Timer.periodic` continues to fire as long as the process exists.
//
// On iOS this is a no-op: background location uses `UIBackgroundModes`
// (declared in Info.plist) instead of a foreground service. The plugin
// gracefully ignores iOS, and `start()` / `stop()` are safe to call on
// either platform.
// =============================================================================

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Entry-point for the background isolate spawned by
/// `flutter_foreground_task`. Must be a top-level function annotated
/// with `@pragma('vm:entry-point')` so the AOT compiler keeps it.
@pragma('vm:entry-point')
void backgroundLocationKeeperCallback() {
  FlutterForegroundTask.setTaskHandler(_KeeperTaskHandler());
}

/// Minimal handler — heartbeat only. Real work happens in the main
/// isolate's [BackgroundLocationTrackingService].
class _KeeperTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Nothing to bootstrap — the main isolate owns the timer.
    if (kDebugMode) {
      // ignore: avoid_print
      print('[KeeperService] onStart @ $timestamp starter=$starter');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Heartbeat tick — keeps the OS aware the service is doing work.
    // No-op in production; the very fact that this fires is enough.
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[KeeperService] onDestroy @ $timestamp');
    }
  }
}

class ForegroundServiceKeeper {
  static const String _channelId = 'background_location_keeper';
  static const String _channelName = 'Background Location';
  static const String _channelDescription =
      'Allows the app to keep reporting your location while in the background.';

  static const int _notificationId = 1000;

  bool _initialized = false;

  /// Configure the plugin. Safe to call multiple times; only the
  /// first call actually performs the native bootstrap.
  void initialize() {
    if (_initialized) return;
    if (!Platform.isAndroid) {
      _initialized = true;
      return;
    }

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: _channelName,
        channelDescription: _channelDescription,
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    _initialized = true;
  }

  /// Start the foreground service. No-op on iOS, no-op if already
  /// running. Returns true if the service is running after the call.
  Future<bool> start({
    String title = 'Location tracking active',
    String text = 'The app keeps your location updated for your team.',
  }) async {
    if (!Platform.isAndroid) return true;
    initialize();

    try {
      final isRunning = await FlutterForegroundTask.isRunningService;
      if (isRunning) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: text,
        );
        return true;
      }

      final result = await FlutterForegroundTask.startService(
        serviceId: _notificationId,
        notificationTitle: title,
        notificationText: text,
        notificationIcon: null,
        callback: backgroundLocationKeeperCallback,
      );
      if (kDebugMode) {
        // ignore: avoid_print
        print('[ForegroundServiceKeeper] startService → $result');
      }
      return result is ServiceRequestSuccess;
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[ForegroundServiceKeeper] start error: $e\n$st');
      }
      return false;
    }
  }

  /// Stop the foreground service (called when the user logs out or
  /// disables tracking).
  Future<void> stop() async {
    if (!Platform.isAndroid) return;
    try {
      final isRunning = await FlutterForegroundTask.isRunningService;
      if (!isRunning) return;
      await FlutterForegroundTask.stopService();
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[ForegroundServiceKeeper] stop error: $e');
      }
    }
  }

  Future<bool> get isRunning async {
    if (!Platform.isAndroid) return false;
    try {
      return await FlutterForegroundTask.isRunningService;
    } catch (_) {
      return false;
    }
  }
}
