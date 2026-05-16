// =============================
// presentation/shared/order_status_utils.dart
// =============================
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

/// Canonical set of order statuses the backend can send via the SOAP
/// `m:mainStatus` element. Every UI affordance (label, color, business
/// rules like "expired-but-still-in-window") routes through this enum
/// so the three downstream switches can never drift apart again.
///
/// The string values are the *canonical* Russian names returned by
/// the live backend. Historical typo variants and whitespace are
/// normalised away in [OrderMainStatus.fromServer].
enum OrderMainStatus {
  newOrder('Новый'),
  confirmed('Оператор подтвердил и в процессе комплектации'),
  delivering('Подтверждено на складе / ожидает доставки'),
  delivered('Доставлено и оплачено'),
  returnRequested('Запрос на возврат'),
  cancelled('Возврат одобрен'),
  deliveredUnpaid('Доставлено и ожидает оплаты'),
  deliveredPartiallyPaid('Доставлено и частично оплачено'),
  expired('Срок доставки истёк'),
  unknown('');

  final String serverValue;
  const OrderMainStatus(this.serverValue);

  /// Server values we recognise as aliases of the canonical names,
  /// for example a long-standing typo that lived in the client
  /// (`Подтверподтверждено...`) and any legacy spelling the backend
  /// might still emit. Keep this list small — every entry hides a
  /// data-quality bug.
  static const Map<String, OrderMainStatus> _aliases = <String, OrderMainStatus>{
    // Client-side typo that lived in the switch tables until 2026-05.
    // Emitted by any older app build that round-trips status strings
    // through mock/preview code. Mapping it to the canonical value
    // keeps mixed-version deployments working.
    'Подтверподтверждено на складе / ожидает доставки':
        OrderMainStatus.delivering,
  };

  /// Debug-only tracker so unrecognised statuses get logged at most
  /// once per distinct value per process. Without this the orders
  /// page would spam the console on every rebuild.
  static final Set<String> _loggedUnknown = <String>{};

  /// Parse a backend status string into an [OrderMainStatus]. Returns
  /// [OrderMainStatus.unknown] for null / empty / unrecognised values.
  ///
  /// Trims whitespace and consults [_aliases] before falling back, so
  /// minor server changes (stray spaces, the historical typo) no
  /// longer push every order into the "Unknown" bucket.
  static OrderMainStatus fromServer(String? raw) {
    if (raw == null) return OrderMainStatus.unknown;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return OrderMainStatus.unknown;

    for (final s in OrderMainStatus.values) {
      if (s == OrderMainStatus.unknown) continue;
      if (s.serverValue == trimmed) return s;
    }

    final alias = _aliases[trimmed];
    if (alias != null) return alias;

    if (kDebugMode && _loggedUnknown.add(trimmed)) {
      // First time we see this status string — surface it in the
      // log so we can either add it to the enum or fix the source.
      debugPrint(
        '[OrderMainStatus] Unrecognised backend mainStatus: "$trimmed". '
        'Falling back to OrderMainStatus.unknown.',
      );
    }
    return OrderMainStatus.unknown;
  }

  /// Localised display label for this status. Falls back to an
  /// English literal when no [BuildContext] is supplied (used by the
  /// mock data path).
  String label([BuildContext? context]) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    switch (this) {
      case OrderMainStatus.newOrder:
        return l10n?.orderStatusNew ?? 'New';
      case OrderMainStatus.confirmed:
        return l10n?.orderStatusConfirmed ?? 'Confirmed';
      case OrderMainStatus.delivering:
        return l10n?.orderStatusDelivering ?? 'In delivery';
      case OrderMainStatus.delivered:
        return l10n?.orderStatusDelivered ?? 'Delivered';
      case OrderMainStatus.returnRequested:
        return l10n?.orderStatusReturnRequested ?? 'Return requested';
      case OrderMainStatus.cancelled:
        return l10n?.orderStatusCancelled ?? 'Cancelled';
      case OrderMainStatus.deliveredUnpaid:
        return l10n?.orderStatusDeliveredUnpaid ?? 'Delivered, unpaid';
      case OrderMainStatus.deliveredPartiallyPaid:
        return l10n?.orderStatusDeliveredPartiallyPaid ??
            'Delivered, partially paid';
      case OrderMainStatus.expired:
        return l10n?.orderStatusExpired ?? 'Expired';
      case OrderMainStatus.unknown:
        return l10n?.orderStatusUnknown ?? 'Unknown';
    }
  }

  /// Theme-aware accent color, used by [statusColor] and the
  /// `StatusChip` widget.
  Color color(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (this) {
      case OrderMainStatus.newOrder:
        return cs.primary;
      case OrderMainStatus.confirmed:
        return cs.tertiary;
      case OrderMainStatus.delivering:
        return cs.secondary;
      case OrderMainStatus.delivered:
        return cs.inversePrimary;
      case OrderMainStatus.returnRequested:
        return Colors.teal;
      case OrderMainStatus.cancelled:
        return Colors.orange;
      case OrderMainStatus.deliveredUnpaid:
        return cs.error;
      case OrderMainStatus.deliveredPartiallyPaid:
        return cs.onError;
      case OrderMainStatus.expired:
        return cs.onTertiary;
      case OrderMainStatus.unknown:
        return cs.outline;
    }
  }
}

/// Checks if an order is expired based on shipping date.
/// Order is considered expired only after the end of the shipping date day (23:59:59).
/// Example: If today is 13.02.2026 and shipping date is 13.02.2026,
/// the order is NOT expired until 23:59:59 of 13.02.2026.
bool isOrderExpired(DateTime? shippingDate) {
  if (shippingDate == null) return false;

  final now = DateTime.now();
  final endOfShippingDay = DateTime(
    shippingDate.year,
    shippingDate.month,
    shippingDate.day,
    23,
    59,
    59,
  );

  return now.isAfter(endOfShippingDay);
}

/// Returns the corrected backend status string. Overrides a stale
/// "expired" flag if the shipping day hasn't actually ended yet.
///
/// Output is normalised to a canonical [OrderMainStatus.serverValue],
/// so downstream switches reliably match even if the backend sent
/// a known-alias spelling.
String getCorrectedOrderStatus(String mainStatus, DateTime? shippingDate) {
  final parsed = OrderMainStatus.fromServer(mainStatus);
  if (parsed == OrderMainStatus.expired && !isOrderExpired(shippingDate)) {
    return OrderMainStatus.delivering.serverValue;
  }
  // Return the canonical spelling so consumers that re-stringify or
  // group-by status see a single value per logical state.
  if (parsed == OrderMainStatus.unknown) return mainStatus;
  return parsed.serverValue;
}

String statusText(String status, [BuildContext? context]) {
  return OrderMainStatus.fromServer(status).label(context);
}

Color statusColor(BuildContext context, String status) {
  return OrderMainStatus.fromServer(status).color(context);
}
