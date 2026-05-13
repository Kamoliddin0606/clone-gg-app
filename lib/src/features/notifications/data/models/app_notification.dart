import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Single notification row exchanged with the V2 backend and persisted
/// locally in sqflite. The backend payload shape lives in
/// `docs/notifications/passport-mobile.md` §8 — we keep optional fields
/// nullable so newer backend versions can extend the envelope without
/// crashing older clients.
class AppNotification extends Equatable {
  /// Notification UUID. Primary key locally and on the server.
  final String id;

  /// Discriminator used to pick the icon, action button, and channel.
  /// Known values: `debt_alert`, `order_new`, `system_announcement`,
  /// `stock_lot_expiring`, ... — treat unknown values as
  /// `system_announcement`.
  final String type;

  /// One of `low`, `normal`, `high`, `urgent`. Drives the priority chip
  /// and Android channel selection in Phase 2.
  final String priority;

  final String title;
  final String body;

  /// Server-side deep link. Format `selup://<area>/<id>` — parsed by
  /// `NotificationDeepLinkRouter`. Null when the notification has no
  /// associated action.
  final String? deepLink;

  /// Free-form JSON payload that travels alongside the notification
  /// (badge counts, tenant id, custom fields). Stored as JSON text in
  /// sqflite; never logged directly.
  final Map<String, dynamic> payload;

  /// Server-issued creation timestamp.
  final DateTime createdAt;

  /// Locally tracked read time. `null` while unread. We never trust the
  /// server's read state for the badge — that's derived from local DB.
  final DateTime? readAt;

  /// Server-side expiry. Past `expiresAt` rows are soft-hidden in the
  /// list and the next sync removes them.
  final DateTime? expiresAt;

  /// When this row was last refetched from `/notifications/{id}/`.
  /// `null` for entries that arrived only via push and have never been
  /// re-fetched.
  final DateTime? lastSyncedAt;

  /// Phase 2b — when set, hide this row from the list + unread badge
  /// until this UTC moment. The row reappears automatically on the
  /// next read after the timestamp elapses (DAO filters by it).
  /// Purely client-side; the backend has no `snooze` endpoint.
  final DateTime? snoozeUntil;

  const AppNotification({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.body,
    required this.createdAt,
    this.deepLink,
    this.payload = const {},
    this.readAt,
    this.expiresAt,
    this.lastSyncedAt,
    this.snoozeUntil,
  });

  bool get isUnread => readAt == null;
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  /// True when [snoozeUntil] is set and still in the future.
  bool isSnoozed([DateTime? now]) {
    if (snoozeUntil == null) return false;
    return snoozeUntil!.isAfter(now ?? DateTime.now());
  }

  AppNotification copyWith({
    String? type,
    String? priority,
    String? title,
    String? body,
    String? deepLink,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    DateTime? readAt,
    bool clearReadAt = false,
    DateTime? expiresAt,
    DateTime? lastSyncedAt,
    DateTime? snoozeUntil,
    bool clearSnooze = false,
  }) {
    return AppNotification(
      id: id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      body: body ?? this.body,
      deepLink: deepLink ?? this.deepLink,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      readAt: clearReadAt ? null : (readAt ?? this.readAt),
      expiresAt: expiresAt ?? this.expiresAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      snoozeUntil: clearSnooze ? null : (snoozeUntil ?? this.snoozeUntil),
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value)?.toUtc();
      }
      return null;
    }

    Map<String, dynamic> readPayload(dynamic raw) {
      if (raw is Map<String, dynamic>) return raw;
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (_) {
          // Server should not send malformed JSON, but if it does we
          // ignore it rather than blowing up the whole row.
        }
      }
      return const {};
    }

    return AppNotification(
      id: json['id'] as String,
      type: (json['type'] as String?) ?? 'system_announcement',
      priority: (json['priority'] as String?) ?? 'normal',
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      deepLink: json['deep_link'] as String?,
      payload: readPayload(json['payload']),
      createdAt: parse(json['created_at']) ?? DateTime.now().toUtc(),
      readAt: parse(json['read_at']),
      expiresAt: parse(json['expires_at']),
      lastSyncedAt: DateTime.now().toUtc(),
    );
  }

  Map<String, Object?> toDbRow() {
    return {
      'id': id,
      'type': type,
      'priority': priority,
      'title': title,
      'body': body,
      'deep_link': deepLink,
      'payload': jsonEncode(payload),
      'created_at': createdAt.toUtc().toIso8601String(),
      'read_at': readAt?.toUtc().toIso8601String(),
      'expires_at': expiresAt?.toUtc().toIso8601String(),
      'last_synced_at': (lastSyncedAt ?? DateTime.now().toUtc())
          .toUtc()
          .toIso8601String(),
      'snooze_until': snoozeUntil?.toUtc().toIso8601String(),
    };
  }

  factory AppNotification.fromDbRow(Map<String, Object?> row) {
    DateTime? parse(Object? value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    Map<String, dynamic> readPayload(Object? raw) {
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (_) {}
      }
      return const {};
    }

    return AppNotification(
      id: row['id'] as String,
      type: (row['type'] as String?) ?? 'system_announcement',
      priority: (row['priority'] as String?) ?? 'normal',
      title: (row['title'] as String?) ?? '',
      body: (row['body'] as String?) ?? '',
      deepLink: row['deep_link'] as String?,
      payload: readPayload(row['payload']),
      createdAt: parse(row['created_at']) ?? DateTime.now(),
      readAt: parse(row['read_at']),
      expiresAt: parse(row['expires_at']),
      lastSyncedAt: parse(row['last_synced_at']),
      snoozeUntil: parse(row['snooze_until']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        priority,
        title,
        body,
        deepLink,
        payload,
        createdAt,
        readAt,
        expiresAt,
        lastSyncedAt,
        snoozeUntil,
      ];
}
