import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/db/notification_db_dao.dart';

/// Stable action ids shared between the notification show-call (the
/// buttons we register) and the dispatcher that fires when the user
/// taps one. Keep these short — Android passes them through bundle
/// extras.
class NotificationActionIds {
  NotificationActionIds._();

  /// "Mark as read" — local-only, mirrors the long-press menu in the
  /// notification list.
  static const String markRead = 'selup_notif_mark_read';

  /// "Snooze 1 hour" — sets snooze_until = now + 1h.
  static const String snooze1h = 'selup_notif_snooze_1h';

  /// All ids the app knows about. Anything else coming back from the
  /// plugin is logged and ignored.
  static const List<String> all = [markRead, snooze1h];

  static bool isKnown(String? id) =>
      id != null && id.isNotEmpty && all.contains(id);
}

/// iOS notification category identifier — referenced from
/// `DarwinNotificationDetails.categoryIdentifier`. iOS surfaces the
/// category's `DarwinNotificationAction`s as inline buttons.
const String darwinNotificationCategoryId = 'selup_notif_default';

/// Pure dispatcher invoked both from the foreground tap handler (where
/// the service locator is fully wired) AND from the background
/// notification-response isolate (where it isn't). Keep DB access via
/// [DatabaseHelper] only — sqflite handles cross-isolate access for us.
///
/// Returns true when the action was applied; false when the id/payload
/// were unrecognised so the caller can fall back to opening the app.
Future<bool> dispatchNotificationAction({
  required String? actionId,
  required String? notificationId,
  Database? dbOverride,
  DateTime? now,
}) async {
  if (!NotificationActionIds.isKnown(actionId)) {
    if (kDebugMode) {
      debugPrint(
        '[NOTIF-ACTION] unknown actionId=$actionId — opening the app',
      );
    }
    return false;
  }
  if (notificationId == null || notificationId.isEmpty) {
    if (kDebugMode) {
      debugPrint('[NOTIF-ACTION] missing notification id for $actionId');
    }
    return false;
  }

  final db = dbOverride ?? await DatabaseHelper().database;
  final dao = NotificationDbDao(_DbWrapper(db));
  final timestamp = now ?? DateTime.now().toUtc();

  try {
    switch (actionId) {
      case NotificationActionIds.markRead:
        await dao.markRead(notificationId, timestamp);
        // Queue the read so the next foreground sync flushes it to
        // the server via /bulk-read/. We persist locally first so the
        // badge updates the moment the user opens the app.
        await dao.enqueueReadMark(notificationId, timestamp);
        return true;

      case NotificationActionIds.snooze1h:
        await dao.snooze(
          notificationId,
          timestamp.add(const Duration(hours: 1)),
        );
        return true;
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[NOTIF-ACTION] dispatch failed for $actionId: $e');
    }
  }
  return false;
}

/// Thin DAO adapter so the dispatcher can pass an already-opened
/// [Database] (e.g. from a test) without going through the singleton
/// [DatabaseHelper].
class _DbWrapper implements DatabaseHelper {
  final Database _db;
  _DbWrapper(this._db);

  @override
  Future<Database> get database async => _db;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
