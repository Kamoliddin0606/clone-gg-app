import 'package:flutter_test/flutter_test.dart';

import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/services/notification_tap_router.dart';

/// Deep-link parsing — pure function tests. The router uses the parsed
/// result to choose a route and arguments; navigation itself is
/// exercised by widget tests in a separate file (out of scope for
/// Phase 1).
///
/// Contract source: `passport-mobile.md` §7.
void main() {
  group('selup://customers/...', () {
    test('plain customer id → trading-points page', () {
      final r = NotificationTapRouter.parseForTest(
          'selup://customers/00-00053242');
      expect(r, isNotNull);
      expect(r!.route, AppRouter.tradingPointsRoute);
      final args = r.arguments as Map<String, dynamic>;
      expect(args['customer_id'], '00-00053242');
      expect(args.containsKey('section'), isFalse);
    });

    test('customer id + section', () {
      final r = NotificationTapRouter.parseForTest(
          'selup://customers/00-00053242/debts');
      expect(r, isNotNull);
      final args = r!.arguments as Map<String, dynamic>;
      expect(args['customer_id'], '00-00053242');
      expect(args['section'], 'debts');
    });

    test('host alone (no id) returns null', () {
      expect(
        NotificationTapRouter.parseForTest('selup://customers'),
        isNull,
      );
    });
  });

  group('selup://orders/...', () {
    test('order id maps to orders route', () {
      final r = NotificationTapRouter.parseForTest('selup://orders/9001');
      expect(r, isNotNull);
      expect(r!.route, AppRouter.ordersRoute);
      expect((r.arguments as Map)['order_id'], '9001');
    });

    test('orders without id still maps to the list route with null args', () {
      final r = NotificationTapRouter.parseForTest('selup://orders');
      expect(r, isNotNull);
      expect(r!.route, AppRouter.ordersRoute);
      expect(r.arguments, isNull);
    });
  });

  group('selup://announcements/...', () {
    test('announcement uuid → notification detail', () {
      final r = NotificationTapRouter.parseForTest(
          'selup://announcements/uuid-1234');
      expect(r, isNotNull);
      expect(r!.route, AppRouter.notificationDetailRoute);
      expect((r.arguments as Map)['id'], 'uuid-1234');
    });

    test('announcement host alone returns null', () {
      expect(
        NotificationTapRouter.parseForTest('selup://announcements'),
        isNull,
      );
    });
  });

  group('selup://stock/lots/...', () {
    test('stock has no Phase 1 route → null (caller falls back)', () {
      expect(
        NotificationTapRouter.parseForTest('selup://stock/lots/lot-1'),
        isNull,
      );
    });
  });

  group('invalid input', () {
    test('null returns null', () {
      expect(NotificationTapRouter.parseForTest(null), isNull);
    });

    test('empty string returns null', () {
      expect(NotificationTapRouter.parseForTest(''), isNull);
    });

    test('non-selup scheme returns null', () {
      expect(
        NotificationTapRouter.parseForTest('https://example.com/customers/1'),
        isNull,
      );
    });

    test('selup with unknown host returns null', () {
      expect(
        NotificationTapRouter.parseForTest('selup://unknown/123'),
        isNull,
      );
    });
  });
}
