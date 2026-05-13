import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';

/// Translates a notification's `deep_link` field (or its raw FCM
/// payload) into a route push on the running navigator. Matches the
/// table in `passport-mobile.md` §7.
///
/// Supported schemes:
///   * `selup://customers/{id_or_code_1c}`              → customer detail
///   * `selup://customers/{id_or_code_1c}/debts`        → customer debts
///   * `selup://orders/{order_id}`                      → order detail
///   * `selup://stock/lots/{lot_id}`                    → stock lot
///   * `selup://announcements/{notification_id}`        → notification detail
///   * anything else                                    → notification detail
class NotificationTapRouter {
  /// Push the right screen for [message] using the globally-owned
  /// navigator key from [AppRouter]. Safe to call from any isolate /
  /// thread because the navigator key is process-wide.
  static void handleRemoteMessage(RemoteMessage message) {
    final id = message.data['notification_id'] as String?;
    final deepLink = message.data['deep_link'] as String?;
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
      if (kDebugMode) {
        debugPrint(
          '[NOTIF-DEEP] navigator not mounted yet — deferring deep link "$deepLink"',
        );
      }
      // Best-effort: store the pending tap on the AppRouter scope so
      // the next navigator init can replay it. For Phase 1 we just
      // drop it — the user can still tap the row from the list.
      return;
    }
    _route(navigator, deepLink: deepLink, notificationId: id);
  }

  /// Variant used from in-app contexts (list/banner) where we already
  /// have a [BuildContext]. Falls back to the navigator key when the
  /// context's navigator is the global one anyway.
  static void handleDeepLink(
    BuildContext context, {
    required String? deepLink,
    String? notificationId,
  }) {
    final navigator = Navigator.of(context, rootNavigator: true);
    _route(navigator, deepLink: deepLink, notificationId: notificationId);
  }

  static void _route(
    NavigatorState navigator, {
    required String? deepLink,
    String? notificationId,
  }) {
    final parsed = _parse(deepLink);
    if (parsed != null) {
      navigator.pushNamed(parsed.route, arguments: parsed.arguments);
      return;
    }
    // Fallback: open the detail screen if we have an id.
    if (notificationId != null && notificationId.isNotEmpty) {
      navigator.pushNamed(
        AppRouter.notificationDetailRoute,
        arguments: {'id': notificationId},
      );
      return;
    }
    navigator.pushNamed(AppRouter.notificationListRoute);
  }

  static _ResolvedRoute? _parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    if (uri.scheme != 'selup') return null;

    final segments = [uri.host, ...uri.pathSegments]
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    if (segments.isEmpty) return null;

    switch (segments.first) {
      case 'customers':
        if (segments.length >= 2) {
          // Phase 1 customer detail screens are not exposed via named
          // routes yet — surface them via the trading-points page
          // until a dedicated `/customers/:id` route lands. The
          // notification detail page acts as the safe fallback.
          return _ResolvedRoute(
            route: AppRouter.tradingPointsRoute,
            arguments: {
              'customer_id': segments[1],
              if (segments.length >= 3) 'section': segments[2],
            },
          );
        }
        break;
      case 'orders':
        return _ResolvedRoute(
          route: AppRouter.ordersRoute,
          arguments: segments.length >= 2 ? {'order_id': segments[1]} : null,
        );
      case 'stock':
        // Phase 1 has no stock-lot screen — fall through to default.
        break;
      case 'announcements':
        if (segments.length >= 2) {
          return _ResolvedRoute(
            route: AppRouter.notificationDetailRoute,
            arguments: {'id': segments[1]},
          );
        }
        break;
    }
    return null;
  }
}

class _ResolvedRoute {
  final String route;
  final Object? arguments;

  const _ResolvedRoute({required this.route, this.arguments});
}
