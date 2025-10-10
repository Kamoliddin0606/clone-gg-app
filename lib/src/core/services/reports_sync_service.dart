import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/main_report.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/business_region_report.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/akb_by_category.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_plan.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_plan_list.dart';

/// Centralized service for report data synchronization and management
class ReportsSyncService {
  final SharedPreferencesService _prefs;
  final SoapApiService _apiService;
  final ApiDatabaseService _dbService;
  final DatabaseHelper _dbHelper;

  ReportsSyncService({
    required SharedPreferencesService prefs,
    required SoapApiService apiService,
    required ApiDatabaseService dbService,
    required DatabaseHelper dbHelper,
  }) : _prefs = prefs,
        _apiService = apiService,
        _dbService = dbService,
        _dbHelper = dbHelper;

  /// Sync all reports for a user (force refresh)
  Future<void> syncAllReports({
    required String userCode,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('Starting full reports sync for user: $userCode');
      }

      // Sync reports for current month by default
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final dateStart = startOfMonth.toIso8601String().split('T')[0];
      final dateEnd = endOfMonth.toIso8601String().split('T')[0];

      await _syncReportByPeriod(userCode, dateStart, dateEnd);

      if (kDebugMode) {
        print('Full reports sync completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during full reports sync: $e');
      }
      rethrow;
    }
  }

  /// Sync all reports with progress updates
  Stream<ReportSyncStep> syncAllReportsWithProgress({
    required String userCode,
    required String password,
    required DateTime dateStart,
    required DateTime dateEnd,
  }) async* {
    final controller = StreamController<ReportSyncStep>();

    try {
      if (kDebugMode) {
        print('Starting full reports sync with progress for user: $userCode');
      }

      // Step 1: Sync main reports
      yield ReportSyncStep.syncingMainReports;
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final dateStart = startOfMonth.toIso8601String().split('T')[0];
      final dateEnd = endOfMonth.toIso8601String().split('T')[0];

      await _syncReportByPeriod(userCode, dateStart, dateEnd);

      // Step 2: Completed
      yield ReportSyncStep.completed;

      if (kDebugMode) {
        print('Full reports sync with progress completed successfully');
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error during full reports sync with progress: $e');
      }
      controller.addError(e);
    } finally {
      await controller.close();
    }

    yield* controller.stream;
  }

  /// Sync report data by period
  Future<Map<String, dynamic>> syncReportByPeriod({
    required String userCode,
    required String dateStart,
    required String dateEnd,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _dbService.getMainReports(userCode: userCode);
      final existingReport = cached.firstWhere(
        (report) => report.dateStart.toIso8601String().split('T')[0] == dateStart &&
                    report.dateEnd.toIso8601String().split('T')[0] == dateEnd,
        orElse: () => MainReport(
          userCode: '',
          dateStart: DateTime.parse(dateStart),
          dateEnd: DateTime.parse(dateEnd),
          countAKB: 0,
          countOKB: 0,
          cash: 0,
          transfer: 0,
          sum: 0,
          countVisited: 0,
        ),
      );

      if (existingReport.userCode.isNotEmpty) {
        // Return cached data with related tables
        final businessRegionReports = await _dbService.getBusinessRegionReports(mainReportId: existingReport.id);
        final akbByCategories = await _dbService.getAKBByCategories(mainReportId: existingReport.id);

        return {
          'mainReport': existingReport,
          'businessRegionReports': businessRegionReports,
          'akbByCategories': akbByCategories,
        };
      }
    }

    return await _syncReportByPeriod(userCode, dateStart, dateEnd);
  }
  /// Sync report data by period
  Future<Map<String, dynamic>> syncReportWithoutPeriod({
    required String userCode,
    required String dateStart,
    required String dateEnd,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _dbService.getMainReports(userCode: userCode);
      print('Bazada malumot bor: ${cached.length}');
      final existingReport = cached.firstWhere(
            (report) => report.userCode == userCode,
        orElse: () => MainReport(
          userCode: '',
          dateStart: DateTime.now(),
          dateEnd: DateTime.now(),
          countAKB: 0,
          countOKB: 0,
          cash: 0,
          transfer: 0,
          sum: 0,
          countVisited: 0,
        ),
      );

      if (existingReport.userCode.isNotEmpty) {
        // Return cached data with related tables
        final businessRegionReports = await _dbService.getBusinessRegionReports(mainReportId: existingReport.id);
        final akbByCategories = await _dbService.getAKBByCategories(mainReportId: existingReport.id);

        return {
          'mainReport': existingReport,
          'businessRegionReports': businessRegionReports,
          'akbByCategories': akbByCategories,
        };
      }
    }

    return await _syncReportByPeriod(userCode, dateStart, dateEnd);
  }

  Future<Map<String, dynamic>> _syncReportByPeriod(String userCode, String dateStart, String dateEnd) async {
    final reportData = await _apiService.getReportByPeriod(
      userCode: userCode,
      dateStart: dateStart,
      dateEnd: dateEnd,
    );

    final mainReport = reportData['mainReport'] as MainReport;
    final businessRegionReports = reportData['businessRegionReports'] as List<BusinessRegionReport>;
    final akbByCategories = reportData['akbByCategories'] as List<AKBByCategory>;

    if (kDebugMode) {
      print('Hisobot ma\'lumotlari yuklandi: ${businessRegionReports.length} ta biznes rayon, ${akbByCategories.length} ta kategoriya');
    }

    // Save main report first to get ID
    await _dbService.saveMainReports([mainReport]);
    await _dbService.saveBusinessRegionReports(businessRegionReports);
    await _dbService.saveAKBByCategories(akbByCategories);
    final savedReports = await _dbService.getMainReports(userCode: userCode);

    final savedReport = savedReports.firstWhere(
      (r) => r.dateStart.toIso8601String().split('T')[0] == dateStart &&
             r.dateEnd.toIso8601String().split('T')[0] == dateEnd,
    );

    // Update related tables with correct main_report_id
    final updatedBusinessRegionReports = businessRegionReports.map((report) =>
      report.copyWith(mainReportId: savedReport.id!)
    ).toList();

    final updatedAKBByCategories = akbByCategories.map((category) =>
      category.copyWith(mainReportId: savedReport.id!)
    ).toList();

    // Save related data
    await _dbService.saveBusinessRegionReports(updatedBusinessRegionReports);
    await _dbService.saveAKBByCategories(updatedAKBByCategories);

    return {
      'mainReport': savedReport,
      'businessRegionReports': updatedBusinessRegionReports,
      'akbByCategories': updatedAKBByCategories,
    };
  }

  /// Get cached data (for offline scenarios)
  Future<List<MainReport>> getCachedMainReports({String? userCode}) =>
      _dbService.getMainReports(userCode: userCode);

  Future<List<BusinessRegionReport>> getCachedBusinessRegionReports({int? mainReportId}) =>
      _dbService.getBusinessRegionReports(mainReportId: mainReportId);

  Future<List<AKBByCategory>> getCachedAKBByCategories({int? mainReportId}) =>
      _dbService.getAKBByCategories(mainReportId: mainReportId);

  Future<List<VisitPlan>> getCachedVisitPlans({int? mainReportId, String? clientCode}) =>
      _dbService.getVisitPlans(mainReportId: mainReportId, clientCode: clientCode);

  Future<List<VisitPlanList>> getCachedVisitPlanLists({int? visitPlanId}) =>
      _dbService.getVisitPlanLists(visitPlanId: visitPlanId);

  /// Clear all report data
  Future<void> clearAllReportData() async {
    try {
      if (kDebugMode) {
        print('Clearing all report data...');
      }
      await _dbService.clearMainReport();
      if (kDebugMode) {
        print('All report data cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing report data: $e');
      }
      rethrow;
    }
  }

  /// Create new main report (local only)
  Future<MainReport> createMainReport({
    required String userCode,
    required DateTime dateStart,
    required DateTime dateEnd,
    required int countAKB,
    required int countOKB,
    required double cash,
    required double transfer,
    required double sum,
    required int countVisited,
  }) async {
    try {
      // Create local report object
      final report = MainReport(
        userCode: userCode,
        dateStart: dateStart,
        dateEnd: dateEnd,
        countAKB: countAKB,
        countOKB: countOKB,
        cash: cash,
        transfer: transfer,
        sum: sum,
        countVisited: countVisited,
      );

      // Save to local database
      await _dbService.saveMainReports([report]);

      return report;
    } catch (e) {
      throw Exception('Asosiy hisobot yaratishda xatolik: $e');
    }
  }

  /// Create business region report (local only)
  Future<BusinessRegionReport> createBusinessRegionReport({
    required int mainReportId,
    required String code,
    required String name,
    required int akb,
  }) async {
    try {
      final report = BusinessRegionReport(
        mainReportId: mainReportId,
        code: code,
        name: name,
        akb: akb,
      );

      await _dbService.saveBusinessRegionReports([report]);
      return report;
    } catch (e) {
      throw Exception('Biznes rayon hisoboti yaratishda xatolik: $e');
    }
  }

  /// Create AKB by category (local only)
  Future<AKBByCategory> createAKBByCategory({
    required int mainReportId,
    required String code,
    required String name,
    required int akb,
  }) async {
    try {
      final category = AKBByCategory(
        mainReportId: mainReportId,
        code: code,
        name: name,
        akb: akb,
      );

      await _dbService.saveAKBByCategories([category]);
      return category;
    } catch (e) {
      throw Exception('AKB kategoriya yaratishda xatolik: $e');
    }
  }

  /// Create visit plan (local only)
  Future<VisitPlan> createVisitPlan({
    required int mainReportId,
    required String clientCode,
    required String clientName,
    required String plannedDate,
    bool isCompleted = false,
    String? notes,
  }) async {
    try {
      final plan = VisitPlan(
        mainReportId: mainReportId,
        clientCode: clientCode,
        clientName: clientName,
        plannedDate: plannedDate,
        isCompleted: isCompleted,
        notes: notes,
      );

      await _dbService.saveVisitPlans([plan]);
      return plan;
    } catch (e) {
      throw Exception('Tashrif reja yaratishda xatolik: $e');
    }
  }
}

/// Report sync progress steps
enum ReportSyncStep {
  syncingMainReports,
  completed,
}