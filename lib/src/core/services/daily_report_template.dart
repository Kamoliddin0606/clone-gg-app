class DailyReportTemplate {
  static String generateDailyReport({
    required String date,
    required String time,
    required String fullName,
    required String territory,
    required String phone,
    required String territoryList,
    required String okbTerritory,
    required String visitedPoints,
    required String activeClients,
    required List<String> regionLines,
    required String cash,
    required String nonCash,
    required String totalOrders,
    required List<String> categoryLines,
    required String monthlyPlan,
    required String monthlyFact,
    required String factPercent,
    required String forecast,
    required String forecastPercent,
    required String okb,
    required String akbPlan,
    required String akbFact,
    required String akbPercent,
  }) {
    // Build region section
    final regionSection = regionLines.isNotEmpty
        ? regionLines.join('\n')
        : 'Нет данных по регионам';

    // Build category section
    final categorySection = categoryLines.isNotEmpty
        ? categoryLines.join('\n')
        : 'Нет данных по категориям';

    return '''
#dailyReport
📅 Дата: $date $time
🙎🏻‍♂️ ФИО: $fullName  

Территория : $territoryList

ОКБ и АКБ:

ОКБ по территории -- $okbTerritory т.т.
Количество посещенных торговых точек -- $visitedPoints т.т.
Активные клиенты сегодня -- $activeClients т.т.

Разделение АКБ по регионам:

$regionSection

Общая стоимость заказов:

Наличные -- $cash Сум
Безналичка -- $nonCash Сум
Общая сумма заказов -- $totalOrders Сум

АКБ по категориям товаров:

$categorySection

✿•┈┈┈┈••ৡ❀ৡ•┈┈┈┈•✿

📊 Ежемесячный план и общие результаты на $date $time

План и факт:

План -- $monthlyPlan Сум
Факт -- $monthlyFact Сум
Факт в процентах -- $factPercent%
Прогноз -- $forecast Сум
Прогноз в процентах -- $forecastPercent%

ОКБ и АКБ:

ОКБ -- $okb т.т.
АКБ план -- $akbPlan т.т.
АКБ факт -- $akbFact т.т.
АКБ в процентах -- $akbPercent%
''';
  }
}