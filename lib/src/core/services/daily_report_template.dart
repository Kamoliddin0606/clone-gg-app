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
📅 <b>Дата:</b> $date $time
🙎🏻‍♂️ <b>ФИО:</b> $fullName

🏢 <b><i>Территория :</i></b> $territoryList

<b>ОКБ и АКБ:</b>

<i>• ОКБ по территории -- $okbTerritory т.т.
• Количество посещенных торговых точек -- $visitedPoints т.т.
• Активные клиенты сегодня -- $activeClients т.т.</i>

<b>Разделение АКБ по регионам:</b>
<i>
$regionSection</i>

<b>Общая стоимость заказов:</b>
<i>
• Наличные -- $cash Сум
• Безналичка -- $nonCash Сум
• <u>Общая сумма заказов -- $totalOrders Сум</u>
</i>
<b>АКБ по категориям товаров:</b>
<i>
$categorySection
</i>
✿•┈┈┈┈••ৡ❀ৡ•┈┈┈┈•✿

📊 <b>Ежемесячный план и общие результаты на $date $time</b>

<b>План и факт:</b>
<i>
• План -- $monthlyPlan Сум
• Факт -- $monthlyFact Сум
• Факт в процентах -- $factPercent%
</i>
<b>Прогноз:</b>
<i>
• Прогноз -- $forecast Сум
• Прогноз в процентах -- $forecastPercent%
</i>
<b>ОКБ и АКБ:</b>
<i>
• ОКБ -- $okb т.т.
• АКБ план -- $akbPlan т.т.
• АКБ факт -- $akbFact т.т.
• АКБ в процентах -- $akbPercent%
</i>
'''

    ;
  }
}