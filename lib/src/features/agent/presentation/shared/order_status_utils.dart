

// =============================
// presentation/shared/order_status_utils.dart
// =============================
import 'package:flutter/material.dart';


String statusText(String status) {
  switch (status) {
    case "Новый": return 'Yangi';
    case "Оператор подтвердил и в процессе комплектации": return 'Tasdiqlangan';
    case "Подтверподтверждено на складе / ожидает доставки": return 'Yetkazish jarayonida';
    case "Доставлено и оплачено": return 'Yetkazildi';
    case "Запрос на возврат": return 'Qaytarish so\'raldi';
    case "Возврат одобрен": return 'Bekor qilindi';
    case "Доставлено и ожидает оплаты": return 'Yetkazildi, to\'lanmadi';
    case "Доставлено и частично оплачено": return 'Yetkazildi, qisman to\'landi';
    case "Срок доставки истёк": return 'muddati o`tdi';
    default: return 'Noma’lum';
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