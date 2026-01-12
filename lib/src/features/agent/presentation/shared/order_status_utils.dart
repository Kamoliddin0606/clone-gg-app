// =============================
// presentation/shared/order_status_utils.dart
// =============================
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';


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