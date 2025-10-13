// =============================
// presentation/shared/formatters.dart
// =============================
import 'package:intl/intl.dart';


final NumberFormat uzsFormat =
NumberFormat.currency(locale: 'uz_UZ', symbol: 'UZS', decimalDigits: 0);
final DateFormat dateFormatShort = DateFormat('dd.MM.yyyy');
final DateFormat dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');


