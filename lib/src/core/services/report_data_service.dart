import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/daily_report_template.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/main_report.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/business_region_report.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/akb_by_category.dart';

/// Custom exceptions for report data operations
class ReportFetchException implements Exception {
  final String message;
  final dynamic originalError;

  ReportFetchException(this.message, [this.originalError]);

  @override
  String toString() => 'ReportFetchException: $message';
}

class DataConversionException implements Exception {
  final String message;
  final dynamic originalError;

  DataConversionException(this.message, [this.originalError]);

  @override
  String toString() => 'DataConversionException: $message';
}

/// Service responsible for fetching and formatting report data for Telegram bot
class ReportDataService {
  final SharedPreferencesService _prefs;
  final SoapApiService _soapApiService;

  ReportDataService({
    required SharedPreferencesService prefs,
    required SoapApiService soapApiService,
  }) : _prefs = prefs,
       _soapApiService = soapApiService;

  /// Fetches report data for the current period and formats it using the daily report template
  /// Returns a formatted string ready to be sent via Telegram bot
  Future<String> fetchReportData() async {
    try {
      // Get current date range (current month)
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month+1, 0);

      final dateStart = startOfMonth.toIso8601String().split('T')[0];
      final dateEnd = endOfMonth.toIso8601String().split('T')[0];

      // Get user credentials from preferences
      final userCode = _prefs.getUserCode();
      if (userCode == null || userCode.isEmpty) {
        throw ReportFetchException('User code not found in preferences');
      }

      // Fetch report data from SOAP API
      final reportData = await _soapApiService.getReportByPeriod(
        userCode: userCode,
        dateStart: dateStart,
        dateEnd: dateEnd,
      );

      // Extract and validate data from API response
      final mainReport = reportData['mainReport'] as MainReport?;
      final businessRegionReports = reportData['businessRegionReports'] as List<BusinessRegionReport>?;
      final akbByCategories = reportData['akbByCategories'] as List<AKBByCategory>?;

      if (mainReport == null) {
        throw DataConversionException('Main report data is null');
      }

      // Format data for template
      final formattedData = _formatReportData(
        mainReport: mainReport,
        businessRegionReports: businessRegionReports,
        akbByCategories: akbByCategories,
      );

      // Generate formatted report message
      return DailyReportTemplate.generateDailyReport(
        date: dateStart,
        time: DateTime.now().toString().split(' ')[1].substring(0, 8),
        fullName: _prefs.getUserName() ?? 'Agent User',
        territory: _prefs.getWarehouseCode() ?? 'Unknown',
        phone: '+998901234567', // TODO: Add phone field to user data
        territoryList: _prefs.getWarehouseCode() ?? 'Unknown Territory',
        okbTerritory: formattedData['okbTerritory'] ?? '0',
        visitedPoints: formattedData['visitedPoints'] ?? '0',
        activeClients: formattedData['activeClients'] ?? '0',
        region: formattedData['region'] ?? 'Unknown Region',
        akbRegion: formattedData['akbRegion'] ?? '0',
        cash: formattedData['cash'] ?? '0',
        nonCash: formattedData['nonCash'] ?? '0',
        totalOrders: formattedData['totalOrders'] ?? '0',
        product1: formattedData['product1'] ?? 'N/A',
        quantity1: formattedData['quantity1'] ?? '0',
        product2: formattedData['product2'] ?? 'N/A',
        quantity2: formattedData['quantity2'] ?? '0',
        product3: formattedData['product3'] ?? 'N/A',
        quantity3: formattedData['quantity3'] ?? '0',
        product4: formattedData['product4'] ?? 'N/A',
        quantity4: formattedData['quantity4'] ?? '0',
        product5: formattedData['product5'] ?? 'N/A',
        quantity5: formattedData['quantity5'] ?? '0',
        product6: formattedData['product6'] ?? 'N/A',
        quantity6: formattedData['quantity6'] ?? '0',
        monthlyPlan: formattedData['monthlyPlan'] ?? '0',
        monthlyFact: formattedData['monthlyFact'] ?? '0',
        factPercent: formattedData['factPercent'] ?? '0',
        forecast: formattedData['forecast'] ?? '0',
        forecastPercent: formattedData['forecastPercent'] ?? '0',
        okb: formattedData['okb'] ?? '0',
        akbPlan: formattedData['akbPlan'] ?? '0',
        akbFact: formattedData['akbFact'] ?? '0',
        akbPercent: formattedData['akbPercent'] ?? '0',
      );

    } on ReportFetchException {
      rethrow; // Re-throw custom exceptions
    } on DataConversionException {
      rethrow; // Re-throw custom exceptions
    } catch (e) {
      // Log unexpected errors
      if (kDebugMode) {
        print('Unexpected error in fetchReportData: $e');
      }
      throw ReportFetchException('Failed to fetch report data: $e', e);
    }
  }

  /// Formats raw API data into template-compatible format
  /// Handles null values and provides defaults
  Map<String, String> _formatReportData({
    required MainReport mainReport,
    List<BusinessRegionReport>? businessRegionReports,
    List<AKBByCategory>? akbByCategories,
  }) {
    try {
      final data = <String, String>{};

      // Extract main report data
      data['okbTerritory'] = _safeString(mainReport.countOKB);
      data['visitedPoints'] = _safeString(mainReport.countVisited);
      data['activeClients'] = _safeString(mainReport.countAKB);
      data['cash'] = _formatCurrency(mainReport.cash);
      data['nonCash'] = _formatCurrency(mainReport.transfer);
      data['totalOrders'] = _formatCurrency(mainReport.sum);

      // Note: MainReport doesn't have plan/fact/forecast fields, so we'll use defaults
      // These would need to be added to the MainReport model or calculated separately
      data['monthlyPlan'] = '0'; // TODO: Add to MainReport model or calculate
      data['monthlyFact'] = '0'; // TODO: Add to MainReport model or calculate
      data['factPercent'] = '0'; // TODO: Add to MainReport model or calculate
      data['forecast'] = '0'; // TODO: Add to MainReport model or calculate
      data['forecastPercent'] = '0'; // TODO: Add to MainReport model or calculate
      data['okb'] = _safeString(mainReport.countOKB);
      data['akbPlan'] = '0'; // TODO: Add to MainReport model
      data['akbFact'] = _safeString(mainReport.countAKB);
      data['akbPercent'] = '0'; // TODO: Add to MainReport model or calculate

      // Extract business region data (first region as example)
      if (businessRegionReports != null && businessRegionReports.isNotEmpty) {
        final firstRegion = businessRegionReports.first;
        data['region'] = firstRegion.name;
        data['akbRegion'] = _safeString(firstRegion.akb);
      } else {
        data['region'] = 'No Region Data';
        data['akbRegion'] = '0';
      }

      // Extract AKB by categories (up to 6 categories)
      if (akbByCategories != null && akbByCategories.isNotEmpty) {
        for (int i = 0; i < akbByCategories.length && i < 6; i++) {
          final category = akbByCategories[i];
          data['product${i + 1}'] = category.name;
          data['quantity${i + 1}'] = _safeString(category.akb);
        }
      }

      // Fill remaining categories with defaults if less than 6
      for (int i = akbByCategories?.length ?? 0; i < 6; i++) {
        data['product${i + 1}'] = 'N/A';
        data['quantity${i + 1}'] = '0';
      }

      return data;

    } catch (e) {
      if (kDebugMode) {
        print('Error formatting report data: $e');
      }
      throw DataConversionException('Failed to format report data: $e', e);
    }
  }

  /// Safely converts a value to string, handling nulls
  String _safeString(dynamic value) {
    if (value == null) return '0';
    return value.toString();
  }

  /// Formats numeric values as currency strings
  String _formatCurrency(dynamic value) {
    if (value == null) return '0';
    final numValue = num.tryParse(value.toString());
    if (numValue == null) return '0';

    // Format with commas for readability
    final formatted = numValue.toStringAsFixed(0);
    final buffer = StringBuffer();
    int counter = 0;

    for (int i = formatted.length - 1; i >= 0; i--) {
      buffer.write(formatted[i]);
      counter++;
      if (counter % 3 == 0 && i > 0) {
        buffer.write(',');
      }
    }

    return buffer.toString().split('').reversed.join();
  }
}