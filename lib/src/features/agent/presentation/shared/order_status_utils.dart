

// =============================
// presentation/shared/order_status_utils.dart
// =============================
import 'package:flutter/material.dart';


String statusText(int status) {
  switch (status) {
    case 0: return 'Yangi';
    case 1: return 'Tasdiqlangan';
    case 2: return 'Jarayonda';
    case 3: return 'Yo‘lda';
    case 4: return 'Yetkazildi';
    case 5: return 'Qisman to‘langan';
    case 6: return 'Muddat o‘tgan';
    default: return 'Noma’lum';
  }
}


Color statusColor(BuildContext context, int status) {
  final cs = Theme.of(context).colorScheme;
  switch (status) {
    case 0: return cs.primary;
    case 1: return cs.tertiary;
    case 2: return cs.secondary;
    case 3: return cs.inversePrimary;
    case 4: return Colors.teal;
    case 5: return Colors.orange;
    case 6: return cs.error;
    default: return cs.outline;
  }
}