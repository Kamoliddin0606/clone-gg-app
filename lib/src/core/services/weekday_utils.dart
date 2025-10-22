import 'package:flutter/foundation.dart';

/// Utility class for handling weekday operations
/// Maps between Dart DateTime.weekday and database code_weekday
class WeekdayUtils {
  /// Get current weekday information
  static Map<String, dynamic> getCurrentWeekdayInfo() {
    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday

    return {
      'code': weekday,
      'name': _getWeekdayName(weekday),
    };
  }

  /// Get weekday name in Russian
  static String getWeekdayName(int weekday) {
    return _getWeekdayName(weekday);
  }

  /// Get weekday code from name
  static int? getWeekdayCode(String weekdayName) {
    const nameToCode = {
      'Понедельник': 1,
      'Вторник': 2,
      'Среда': 3,
      'Четверг': 4,
      'Пятница': 5,
      'Суббота': 6,
      'Воскресенье': 7,
    };
    return nameToCode[weekdayName];
  }

  /// Validate weekday code (1-7)
  static bool isValidWeekdayCode(int code) {
    return code >= 1 && code <= 7;
  }

  /// Get all weekday names in order
  static List<String> getAllWeekdayNames() {
    return [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье',
    ];
  }

  /// Get weekday name from code with validation
  static String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Понедельник';
      case 2:
        return 'Вторник';
      case 3:
        return 'Среда';
      case 4:
        return 'Четверг';
      case 5:
        return 'Пятница';
      case 6:
        return 'Суббота';
      case 7:
        return 'Воскресенье';
      default:
        if (kDebugMode) {
          print('Warning: Invalid weekday code: $weekday');
        }
        return 'Неизвестно';
    }
  }

  /// Get next weekday code (with wrap around)
  static int getNextWeekdayCode(int currentCode) {
    return currentCode == 7 ? 1 : currentCode + 1;
  }

  /// Get previous weekday code (with wrap around)
  static int getPreviousWeekdayCode(int currentCode) {
    return currentCode == 1 ? 7 : currentCode - 1;
  }

  /// Check if two weekday codes represent consecutive days
  static bool areConsecutiveWeekdays(int code1, int code2) {
    if (!isValidWeekdayCode(code1) || !isValidWeekdayCode(code2)) {
      return false;
    }

    final diff = (code2 - code1).abs();
    return diff == 1 || diff == 6; // 6 for Sunday(7) to Monday(1)
  }
}