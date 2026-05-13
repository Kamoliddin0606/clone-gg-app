import 'package:flutter_test/flutter_test.dart';

import 'package:gloria_marketing_flutter/src/features/notifications/data/models/app_notification.dart';

/// Model serialization round-trips. The backend JSON shape and the
/// sqflite row layout must stay reversible: each direction has to
/// preserve every business-meaningful field. See
/// `passport-mobile.md` §8 for the wire format.
void main() {
  group('AppNotification.fromJson', () {
    test('parses every field of a fully-populated payload', () {
      final json = <String, dynamic>{
        'id': 'abc-123',
        'type': 'debt_alert',
        'priority': 'high',
        'title': 'Mijoz qarzdor',
        'body': 'Customer X muddati o\'tgan',
        'deep_link': 'selup://customers/00-00053242/debts',
        'payload': {'customer_id': '00-00053242', 'amount': 12345},
        'created_at': '2026-05-13T08:00:00Z',
        'read_at': '2026-05-13T08:05:00Z',
        'expires_at': '2026-05-20T00:00:00Z',
      };

      final n = AppNotification.fromJson(json);

      expect(n.id, 'abc-123');
      expect(n.type, 'debt_alert');
      expect(n.priority, 'high');
      expect(n.title, 'Mijoz qarzdor');
      expect(n.deepLink, 'selup://customers/00-00053242/debts');
      expect(n.payload['customer_id'], '00-00053242');
      expect(n.payload['amount'], 12345);
      expect(n.createdAt.isUtc, isTrue);
      expect(n.readAt, isNotNull);
      expect(n.expiresAt, isNotNull);
      expect(n.lastSyncedAt, isNotNull); // stamped at fromJson time
      expect(n.isUnread, isFalse);
    });

    test('falls back gracefully when optional fields are missing', () {
      final json = <String, dynamic>{
        'id': 'min-1',
        'title': 'Hello',
        'body': 'World',
        'created_at': '2026-05-13T08:00:00Z',
      };

      final n = AppNotification.fromJson(json);

      expect(n.type, 'system_announcement');
      expect(n.priority, 'normal');
      expect(n.deepLink, isNull);
      expect(n.payload, isEmpty);
      expect(n.readAt, isNull);
      expect(n.isUnread, isTrue);
      expect(n.expiresAt, isNull);
    });

    test('accepts payload encoded as a JSON string (defensive)', () {
      final n = AppNotification.fromJson({
        'id': 'p-1',
        'title': '',
        'body': '',
        'created_at': '2026-05-13T08:00:00Z',
        'payload': '{"k":"v"}',
      });
      expect(n.payload['k'], 'v');
    });

    test('ignores malformed payload string instead of throwing', () {
      final n = AppNotification.fromJson({
        'id': 'p-2',
        'title': '',
        'body': '',
        'created_at': '2026-05-13T08:00:00Z',
        'payload': '{not json',
      });
      expect(n.payload, isEmpty);
    });
  });

  group('AppNotification DB round-trip', () {
    test('toDbRow → fromDbRow preserves every field', () {
      final original = AppNotification(
        id: 'rt-1',
        type: 'order_new',
        priority: 'urgent',
        title: 'Yangi buyurtma',
        body: '5 ta mahsulot',
        deepLink: 'selup://orders/9001',
        payload: const {'order_id': '9001', 'total': 1500},
        createdAt: DateTime.utc(2026, 5, 13, 8, 0),
        readAt: null,
        expiresAt: DateTime.utc(2026, 5, 20),
        lastSyncedAt: DateTime.utc(2026, 5, 13, 8, 1),
      );

      final row = original.toDbRow();
      final restored = AppNotification.fromDbRow(row);

      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.priority, original.priority);
      expect(restored.title, original.title);
      expect(restored.body, original.body);
      expect(restored.deepLink, original.deepLink);
      expect(restored.payload, original.payload);
      expect(restored.createdAt.toUtc(), original.createdAt);
      expect(restored.expiresAt!.toUtc(), original.expiresAt);
      expect(restored.readAt, isNull);
      expect(restored.isUnread, isTrue);
    });

    test('isExpired follows expires_at vs now', () {
      final past = AppNotification(
        id: 'e-1',
        type: 'system_announcement',
        priority: 'normal',
        title: '',
        body: '',
        createdAt: DateTime.utc(2026, 1, 1),
        expiresAt: DateTime.utc(2026, 1, 2),
      );
      expect(past.isExpired, isTrue);

      final future = past.copyWith(
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );
      expect(future.isExpired, isFalse);
    });
  });
}
