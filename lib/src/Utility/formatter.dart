import 'package:intl/intl.dart';

String formatSum(num? value) {
  if (value == null) return '-';
  final formatter = NumberFormat('#,###', 'uz_UZ');
  return '${formatter.format(value).replaceAll(',', ' ')} so\'m';
}
String formatProcent(num? value) {
  if (value == null) return '-';
  final formatter = NumberFormat('#,###', 'uz_UZ');
  return '${formatter.format(value).replaceAll(',', ' ')} %';
}