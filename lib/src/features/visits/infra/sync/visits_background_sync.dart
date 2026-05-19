import 'dart:async';
import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';
import 'package:workmanager/workmanager.dart';

import '../photo/photo_upload_service.dart';
import 'outbox_dispatcher.dart';

/// Background sync task name. Kept top-level so the Workmanager
/// dispatcher can reach it without a class instance.
const String visitsOutboxTaskName = 'visits_v2.outbox_sync';

/// Periodic interval for the background sync. Android enforces a 15-min
/// minimum so anything tighter is rounded up by the OS.
const Duration visitsOutboxInterval = Duration(minutes: 15);

/// Public surface for scheduling the background sync from app start.
///
/// The Workmanager callback dispatcher must be a top-level function
/// (Dart isolate constraint) — see [visitsCallbackDispatcher] below.
class VisitsBackgroundSync {
  const VisitsBackgroundSync._();

  /// Registers the periodic task and the callback dispatcher. Idempotent
  /// via the `keep` policy — re-running on hot restart leaves the existing
  /// schedule alone.
  ///
  /// **Constraint tuning** (battery-friendly, balanced against staleness):
  ///   * `networkType: connected` — never burn battery on a cellular
  ///     handshake when there's no link; the foreground coordinator
  ///     covers users who are mostly online.
  ///   * `requiresBatteryNotLow: true` — defer when the OS reports
  ///     low-battery state. Outbox rows are durable; agents prefer to
  ///     sync at the next charge cycle than be stranded with a dead
  ///     phone mid-visit.
  ///   * `requiresCharging: false` — agents work all day; gating on
  ///     charging would create a 12+ hour sync gap on a heavy day.
  ///   * `requiresDeviceIdle: false` — same reason.
  ///   * `requiresStorageNotLow: true` — protects the local sqflite
  ///     when the device is almost out of space (writing a stale row
  ///     during a low-storage state is the fastest way to brick the
  ///     visits DB).
  static Future<void> schedule() async {
    await Workmanager().initialize(visitsCallbackDispatcher);
    await Workmanager().registerPeriodicTask(
      visitsOutboxTaskName,
      visitsOutboxTaskName,
      frequency: visitsOutboxInterval,
      // Workmanager applies a fuzziness window on iOS BGProcessingTask —
      // the actual fire interval is "no sooner than `frequency`". 15 min
      // is the Android floor; iOS may run the task hours later, which
      // is fine for our durable outbox.
      initialDelay: const Duration(minutes: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      // Workmanager backs off exponentially on task failure. We start at
      // 30s (one tick after the foreground coordinator's 60s timer fires)
      // and double up to 5 min — same shape as the outbox dispatcher's
      // own backoff so the two layers don't fight.
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 30),
    );
  }

  static Future<void> cancel() => Workmanager().cancelByUniqueName(visitsOutboxTaskName);
}

/// Top-level Workmanager entry point.
///
/// Runs in a fresh isolate, so it cannot share GetIt with the UI. The
/// caller must ensure `setupServiceLocator()` is called from this entry
/// before any visit service is resolved — typically by exposing a
/// dedicated bootstrap function in the host app and invoking it here.
///
/// The default implementation assumes the host has wired
/// `GetIt.instance` in a way that's safe to query from the isolate. If
/// it hasn't, the call no-ops and the foreground coordinator will catch
/// up on the next resume.
@pragma('vm:entry-point')
void visitsCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != visitsOutboxTaskName) return true;

    final sl = GetIt.instance;
    if (!sl.isRegistered<OutboxDispatcher>() ||
        !sl.isRegistered<PhotoUploadService>()) {
      developer.log(
        'Visits background sync invoked before DI was ready — skipping',
        name: 'visits.bg',
      );
      return true;
    }
    try {
      await sl<PhotoUploadService>().cycle();
      await sl<OutboxDispatcher>().cycle();
    } catch (e, st) {
      developer.log('Visits background sync failed',
          name: 'visits.bg', error: e, stackTrace: st);
      return false; // Workmanager retries with its own backoff.
    }
    return true;
  });
}
