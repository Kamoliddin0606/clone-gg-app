import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

import 'package:gloria_marketing_flutter/src/core/services/local_uuid_service.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/db/notification_db_dao.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/models/app_notification.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/notification_api_service.dart';

/// Orchestrates the local cache (sqflite) + the backend API. Mobile UI
/// always reads from here; never from the API or DAO directly.
///
/// Streams exposed:
///   * [unreadCountStream] — live integer for the bell badge. Wired
///     into the local cache, so optimistic mark-reads update instantly.
///   * [listStream] — most recent rows ordered by `created_at DESC`.
///     Page-2+ comes via [loadMore] (cursor pagination).
class NotificationRepository {
  static const _uuid = Uuid();

  final NotificationApiService _api;
  final NotificationDbDao _dao;
  final LocalUuidService _uuidService;

  final BehaviorSubject<int> _unreadCount = BehaviorSubject<int>.seeded(0);
  final BehaviorSubject<List<AppNotification>> _list =
      BehaviorSubject<List<AppNotification>>.seeded(const []);

  String? _nextCursor;
  DateTime? _lastSyncAt;
  bool _initialised = false;

  NotificationRepository({
    required NotificationApiService api,
    required NotificationDbDao dao,
    required LocalUuidService uuidService,
  })  : _api = api,
        _dao = dao,
        _uuidService = uuidService;

  Stream<int> get unreadCountStream => _unreadCount.stream.distinct();
  Stream<List<AppNotification>> get listStream => _list.stream;
  int get unreadCountValue => _unreadCount.value;
  List<AppNotification> get listValue => _list.value;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Hydrate the streams from the local cache. Cheap — call from
  /// `main()` after the DB is open.
  Future<void> bootstrap() async {
    if (_initialised) return;
    _initialised = true;
    final cached = await _dao.getAll();
    _list.add(cached);
    _unreadCount.add(await _dao.unreadCount());
  }

  Future<void> dispose() async {
    await _unreadCount.close();
    await _list.close();
  }

  // ---------------------------------------------------------------------------
  // Sync
  // ---------------------------------------------------------------------------

  /// Incremental sync — `GET /notifications/?since=<last_sync>`.
  /// Server is authoritative on overlap. Also flushes the offline read
  /// queue. Tolerant of failure: errors are logged in debug builds and
  /// the local cache stays as-is.
  Future<void> syncIncremental({bool force = false}) async {
    try {
      // Push pending reads first so the list reflects them once the
      // server replies.
      await flushPendingReads();

      final since = force ? null : (_lastSyncAt ?? await _dao.lastSyncedAt());
      final page = await _api.list(
        since: since,
        limit: 50,
      );
      if (page.items.isNotEmpty) {
        await _dao.upsertAll(page.items);
      }
      _nextCursor = page.nextCursor;
      _lastSyncAt = DateTime.now().toUtc();
      await _publish();
      await _dao.evictOld();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NOTIF] syncIncremental failed: $e');
      }
    }
  }

  /// Loads the next page of older rows. Returns `true` when there may
  /// be more, `false` when the cursor is exhausted.
  Future<bool> loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || cursor.isEmpty) return false;
    try {
      final page = await _api.list(cursor: cursor, limit: 50);
      await _dao.upsertAll(page.items);
      _nextCursor = page.nextCursor;
      await _publish();
      return _nextCursor != null && _nextCursor!.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NOTIF] loadMore failed: $e');
      }
      return false;
    }
  }

  /// Fetch + cache a single row. Used by the detail screen and by the
  /// push handlers (always-fetch rule, passport §3.4).
  Future<AppNotification?> fetchAndCache(String id) async {
    try {
      final fresh = await _api.detail(id);
      await _dao.upsert(fresh);
      await _publish();
      return fresh;
    } on NotificationApiException catch (e) {
      if (e.isNotFound || e.isExpired) {
        await _dao.deleteById(id);
        await _publish();
      }
      if (kDebugMode) {
        debugPrint('[NOTIF] fetchAndCache($id) failed: $e');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NOTIF] fetchAndCache($id) unexpected: $e');
      }
      return null;
    }
  }

  Future<AppNotification?> getById(String id) async {
    final local = await _dao.getById(id);
    return local;
  }

  // ---------------------------------------------------------------------------
  // Mark read
  // ---------------------------------------------------------------------------

  /// Mark a single notification read. Optimistic local update + HTTP
  /// in the background. Network failures land in [pending_read_marks]
  /// so the next sync flushes them.
  Future<void> markRead(String id) async {
    final now = DateTime.now().toUtc();
    await _dao.markRead(id, now);
    await _publish();

    try {
      final serverReadAt = await _api.markRead(id);
      if (kDebugMode) {
        debugPrint(
            '[NOTIF] markRead($id) → server confirmed (read_at=$serverReadAt)');
      }
    } catch (e) {
      await _dao.enqueueReadMark(id, now);
      if (kDebugMode) {
        debugPrint('[NOTIF] markRead($id) deferred to queue: $e');
      }
    }
  }

  /// Phase 2b — local-only "Mark as unread". The backend has no
  /// `unread` endpoint (passport §8); this flips the cached row's
  /// `read_at` back to NULL so the badge re-counts it and the list
  /// shows the unread dot.
  Future<void> markUnread(String id) async {
    await _dao.markUnread(id);
    await _publish();
  }

  /// Phase 2b — snooze a notification for [duration]. The row is
  /// hidden from list + badge until the timer elapses; once
  /// `snooze_until <= now`, the next [_publish] will re-include it.
  Future<void> snooze(String id, Duration duration) async {
    final until = DateTime.now().toUtc().add(duration);
    await _dao.snooze(id, until);
    await _publish();
  }

  /// Clear any active snooze. Used when the user explicitly taps the
  /// row to read it (open the detail screen) — they obviously want to
  /// see it now.
  Future<void> unsnooze(String id) async {
    await _dao.unsnooze(id);
    await _publish();
  }

  /// Mark every unread notification as read locally and flush ids to
  /// the server in one bulk call.
  Future<void> markAllRead() async {
    final unreadIds = _list.value
        .where((n) => n.isUnread)
        .map((n) => n.id)
        .toList(growable: false);
    if (unreadIds.isEmpty) return;
    final now = DateTime.now().toUtc();
    await _dao.markAllRead(now);
    await _publish();

    try {
      await _api.bulkMarkRead(
        ids: unreadIds,
        clientUuid: await _uuidService.getOrCreateLocalUuid(),
        idempotencyKey: _uuid.v4(),
      );
    } catch (e) {
      // Stash all of them so the next sync flushes.
      for (final id in unreadIds) {
        await _dao.enqueueReadMark(id, now);
      }
      if (kDebugMode) {
        debugPrint('[NOTIF] markAllRead deferred: $e');
      }
    }
  }

  /// Drain the offline queue via the bulk endpoint. Safe to call on
  /// every sync tick. Returns the number of ids actually flushed
  /// (0 if the queue was empty or the call failed).
  Future<int> flushPendingReads() async {
    final ids = await _dao.pendingReadIds();
    if (ids.isEmpty) {
      if (kDebugMode) {
        debugPrint('[NOTIF] flushPendingReads: queue empty, nothing to do');
      }
      return 0;
    }
    if (kDebugMode) {
      debugPrint('[NOTIF] flushPendingReads: draining ${ids.length} id(s)');
    }
    try {
      final marked = await _api.bulkMarkRead(
        ids: ids,
        clientUuid: await _uuidService.getOrCreateLocalUuid(),
        idempotencyKey: _uuid.v4(),
      );
      await _dao.dequeueReadMarks(ids);
      if (kDebugMode) {
        debugPrint('[NOTIF] flushPendingReads: drained $marked id(s)');
      }
      return marked;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NOTIF] flushPendingReads kept ${ids.length}: $e');
      }
      return 0;
    }
  }

  /// Live view of the offline read-mark queue size. The Settings
  /// Diagnostika section surfaces this so users + support can tell
  /// when mark-read calls are not reaching the backend.
  Future<int> pendingReadCount() async {
    final ids = await _dao.pendingReadIds();
    return ids.length;
  }

  // ---------------------------------------------------------------------------
  // Background push (top-level handler)
  // ---------------------------------------------------------------------------

  /// Persist a stub row when a push arrives while the app is in the
  /// background. The actual content is fetched on the next sync.
  Future<void> recordBackgroundPush(RemoteMessage message) async {
    final id = message.data['notification_id'];
    if (id is! String || id.isEmpty) return;

    // Don't overwrite a richer existing row — only insert a stub if
    // we've never seen this id.
    final existing = await _dao.getById(id);
    if (existing != null) return;

    final notification = message.notification;
    final stub = AppNotification(
      id: id,
      type: (message.data['type'] as String?) ?? 'system_announcement',
      priority: (message.data['priority'] as String?) ?? 'normal',
      title: notification?.title ?? (message.data['title'] as String? ?? ''),
      body: notification?.body ?? (message.data['body'] as String? ?? ''),
      deepLink: message.data['deep_link'] as String?,
      payload: const {},
      createdAt: DateTime.now().toUtc(),
      lastSyncedAt: null,
    );
    await _dao.upsert(stub);
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  Future<void> clearForLogout() async {
    await _dao.clearAll();
    _list.add(const []);
    _unreadCount.add(0);
    _nextCursor = null;
    _lastSyncAt = null;
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _publish() async {
    final rows = await _dao.getAll();
    _list.add(rows);
    _unreadCount.add(await _dao.unreadCount());
  }
}
