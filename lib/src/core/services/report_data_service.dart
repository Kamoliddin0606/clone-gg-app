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
      final startOfMonth = now;
      final endOfMonth = now;

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

      // Build dynamic region and category lines
      final regionLines = _buildRegionLines(businessRegionReports);
      final categoryLines = _buildCategoryLines(akbByCategories);
      final territoryList = _buildTerritoryList(businessRegionReports);

      // Generate formatted report message
      return DailyReportTemplate.generateDailyReport(
        date: dateStart,
        time: DateTime.now().toString().split(' ')[1].substring(0, 8),
        fullName: _prefs.getUserName() ?? 'Agent User',
        territory: _prefs.getWarehouseCode() ?? 'Unknown',
        phone: '-', // TODO: Add phone field to user data
        territoryList: territoryList,
        okbTerritory: _safeString(mainReport.countOKB),
        visitedPoints: _safeString(mainReport.countVisited),
        activeClients: _safeString(mainReport.countAKB),
        regionLines: regionLines,
        cash: _formatCurrency(mainReport.cash),
        nonCash: _formatCurrency(mainReport.transfer),
        totalOrders: _formatCurrency(mainReport.sum),
        categoryLines: categoryLines,
        monthlyPlan: '0', // TODO: Add to MainReport model or calculate
        monthlyFact: '0', // TODO: Add to MainReport model or calculate
        factPercent: '0', // TODO: Add to MainReport model or calculate
        forecast: '0', // TODO: Add to MainReport model or calculate
        forecastPercent: '0', // TODO: Add to MainReport model or calculate
        okb: "0", // TODO: Add to MainReport model or calculate
        akbPlan: '0', // TODO: Add to MainReport model
        akbFact: '0', // TODO: Add to MainReport model
        akbPercent: '0', // TODO: Add to MainReport model or calculate
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

  /// Builds dynamic region lines from business region reports
  /// Returns a list of formatted strings for each region
  List<String> _buildRegionLines(List<BusinessRegionReport>? businessRegionReports) {
    if (businessRegionReports == null || businessRegionReports.isEmpty) {
      return ['Нет данных по регионам'];
    }

    return businessRegionReports.map((region) {
      return '${region.name} -- ${_safeString(region.akb)} т.т.';
    }).toList();
  }

  /// Builds dynamic category lines from AKB by categories
  /// Returns a list of formatted strings for each category
  List<String> _buildCategoryLines(List<AKBByCategory>? akbByCategories) {
    if (akbByCategories == null || akbByCategories.isEmpty) {
      return ['Нет данных по категориям'];
    }

    return akbByCategories.map((category) {
      return '${category.name} -- ${_safeString(category.akb)} т.т.';
    }).toList();
  }

  /// Builds territory list as comma-separated region names
  /// Returns a string with all region names joined by commas
  String _buildTerritoryList(List<BusinessRegionReport>? businessRegionReports) {
    if (businessRegionReports == null || businessRegionReports.isEmpty) {
      return _prefs.getWarehouseCode() ?? 'Unknown Territory';
    }

    final regionNames = businessRegionReports.map((region) => region.name).toList();
    return regionNames.join(', ');
  }
}