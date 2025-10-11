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
    required String region,
    required String akbRegion,
    required String cash,
    required String nonCash,
    required String totalOrders,
    required String product1,
    required String quantity1,
    required String product2,
    required String quantity2,
    required String product3,
    required String quantity3,
    required String product4,
    required String quantity4,
    required String product5,
    required String quantity5,
    required String product6,
    required String quantity6,
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
    return '''
#dailyReport
📅 Дата: $date $time
🙎🏻‍♂️ ФИО: $fullName ($territory) $phone

Территория : $territoryList

ОКБ и АКБ:

ОКБ по территории -- $okbTerritory т.т.
Количество посещенных торговых точек -- $visitedPoints т.т.
Активные клиенты сегодня -- $activeClients т.т.

Разделение АКБ по регионам:

$region -- $akbRegion т.т.

Общая стоимость заказов:

Наличные -- $cash Сум
Безналичка -- $nonCash Сум
Общая сумма заказов -- $totalOrders Сум

АКБ по категориям товаров:

$product1 -- $quantity1 т.т.
$product2 -- $quantity2 т.т.
$product3 -- $quantity3 т.т.
$product4 -- $quantity4 т.т.
$product5 -- $quantity5 т.т.
$product6 -- $quantity6 т.т.

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