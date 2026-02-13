// =============================
// presentation/shared/order_status_utils.dart
// =============================
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

/// Checks if an order is expired based on shipping date
/// Order is considered expired only after the end of the shipping date day (23:59:59)
/// Example: If today is 13.02.2026 and shipping date is 13.02.2026,
/// the order is NOT expired until 23:59:59 of 13.02.2026
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

/// Gets the corrected order status based on shipping date
/// This function overrides backend status if the order is incorrectly marked as expired
/// when the shipping date hasn't ended yet (before 23:59:59)
String getCorrectedOrderStatus(String mainStatus, DateTime? shippingDate) {
  // If status is "expired" but shipping date hasn't ended yet, return a different status
  if (mainStatus == "Срок доставки истёк" && shippingDate != null) {
    if (!isOrderExpired(shippingDate)) {
      // Return "in process" status instead of expired
      return "Подтверподтверждено на складе / ожидает доставки";
    }
  }
  
  return mainStatus;
}

String statusText(String status, [BuildContext? context]) {
  final l10n = context != null ? AppLocalizations.of(context) : null;
  switch (status) {
    case "Новый": return l10n?.orderStatusNew ?? 'New';
    case "Оператор подтвердил и в процессе комплектации": return l10n?.orderStatusConfirmed ?? 'Confirmed';
    case "Подтверподтверждено на складе / ожидает доставки": return l10n?.orderStatusDelivering ?? 'In delivery';
    case "Доставлено и оплачено": return l10n?.orderStatusDelivered ?? 'Delivered';
    case "Запрос на возврат": return l10n?.orderStatusReturnRequested ?? 'Return requested';
    case "Возврат одобрен": return l10n?.orderStatusCancelled ?? 'Cancelled';
    case "Доставлено и ожидает оплаты": return l10n?.orderStatusDeliveredUnpaid ?? 'Delivered, unpaid';
    case "Доставлено и частично оплачено": return l10n?.orderStatusDeliveredPartiallyPaid ?? 'Delivered, partially paid';
    case "Срок доставки истёк": return l10n?.orderStatusExpired ?? 'Expired';
    default: return l10n?.orderStatusUnknown ?? 'Unknown';
  }
}


Color statusColor(BuildContext context, String status) {
  final cs = Theme.of(context).colorScheme;
  switch (status) {
    case "Новый": return cs.primary;
    case "Оператор подтвердил и в процессе комплектации": return cs.tertiary;
    case "Подтверподтверждено на складе / ожидает доставки": return cs.secondary;
    case "Доставлено и оплачено": return cs.inversePrimary;
    case "Запрос на возврат": return Colors.teal;
    case "Возврат одобрен": return Colors.orange;
    case "Доставлено и ожидает оплаты": return cs.error;
    case "Доставлено и частично оплачено": return cs.onError;
    case "Срок доставки истёк": return cs.onTertiary;
    default: return cs.outline;
  }
}