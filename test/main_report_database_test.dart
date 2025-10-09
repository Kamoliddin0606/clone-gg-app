import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/main_report.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/business_region_report.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/akb_by_category.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_plan.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_plan_list.dart';

// Initialize sqflite for testing
void sqfliteTestInit() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

void main() {
  sqfliteTestInit();

  late ApiDatabaseService dbService;

  setUp(() async {
    dbService = ApiDatabaseService();
    // Clear all data before each test
    await dbService.clearAllData();
  });

  tearDown(() async {
    // Clean up after each test
    await dbService.clearAllData();
  });

  group('Main Reports Database Tests', () {
    test('Save and retrieve main reports', () async {
      final reports = [
        MainReport(
          userCode: '001',
          dateStart: DateTime(2025, 10, 1),
          dateEnd: DateTime(2025, 10, 9),
          countAKB: 79,
          countOKB: 402,
          cash: 29050010.0,
          transfer: 27082530.0,
          sum: 56132540.0,
          countVisited: 93,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MainReport(
          userCode: '002',
          dateStart: DateTime(2025, 10, 10),
          dateEnd: DateTime(2025, 10, 16),
          countAKB: 50,
          countOKB: 200,
          cash: 15000000.0,
          transfer: 12000000.0,
          sum: 27000000.0,
          countVisited: 60,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await dbService.saveMainReports(reports);
      final retrieved = await dbService.getMainReports();

      expect(retrieved.length, 2);
      final report1 = retrieved.firstWhere((r) => r.userCode == '001');
      final report2 = retrieved.firstWhere((r) => r.userCode == '002');
      expect(report1.countAKB, 79);
      expect(report1.cash, 29050010.0);
      expect(report2.countAKB, 50);
    });

    test('Retrieve main reports by user code', () async {
      final report1 = MainReport(
        userCode: '001',
        dateStart: DateTime(2025, 10, 1),
        dateEnd: DateTime(2025, 10, 9),
        countAKB: 79,
        countOKB: 402,
        cash: 29050010.0,
        transfer: 27082530.0,
        sum: 56132540.0,
        countVisited: 93,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final report2 = MainReport(
        userCode: '002',
        dateStart: DateTime(2025, 10, 1),
        dateEnd: DateTime(2025, 10, 9),
        countAKB: 30,
        countOKB: 150,
        cash: 10000000.0,
        transfer: 8000000.0,
        sum: 18000000.0,
        countVisited: 40,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dbService.saveMainReports([report1, report2]);

      final user1Reports = await dbService.getMainReports(userCode: '001');
      final user2Reports = await dbService.getMainReports(userCode: '002');
      final allReports = await dbService.getMainReports();

      expect(user1Reports.length, 1);
      expect(user2Reports.length, 1);
      expect(allReports.length, 2);
    });

    test('Get main report by ID', () async {
      final report = MainReport(
        userCode: '001',
        dateStart: DateTime(2025, 10, 1),
        dateEnd: DateTime(2025, 10, 9),
        countAKB: 79,
        countOKB: 402,
        cash: 29050010.0,
        transfer: 27082530.0,
        sum: 56132540.0,
        countVisited: 93,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dbService.saveMainReports([report]);
      final savedReports = await dbService.getMainReports(userCode: '001');
      final retrieved = await dbService.getMainReportById(savedReports[0].id!);

      expect(retrieved, isNotNull);
      expect(retrieved!.userCode, '001');
      expect(retrieved.countAKB, 79);
    });
  });

  group('Business Region Reports Database Tests', () {
    test('Save and retrieve business region reports', () async {
      // First create a main report
      final mainReport = MainReport(
        userCode: '001',
        dateStart: DateTime(2025, 10, 1),
        dateEnd: DateTime(2025, 10, 9),
        countAKB: 79,
        countOKB: 402,
        cash: 29050010.0,
        transfer: 27082530.0,
        sum: 56132540.0,
        countVisited: 93,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dbService.saveMainReports([mainReport]);
      final savedReports = await dbService.getMainReports(userCode: '001');
      final mainReportId = savedReports[0].id!;

      final regionReports = [
        BusinessRegionReport(
          mainReportId: mainReportId,
          code: '00000000713',
          name: 'Мирзо-Улугбекский район-1',
          akb: 44,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        BusinessRegionReport(
          mainReportId: mainReportId,
          code: '00000000714',
          name: 'Мирзо-Улугбекский район-2',
          akb: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await dbService.saveBusinessRegionReports(regionReports);
      final retrieved = await dbService.getBusinessRegionReports(mainReportId: mainReportId);

      expect(retrieved.length, 2);
      expect(retrieved[0].code, '00000000713');
      expect(retrieved[0].name, 'Мирзо-Улугбекский район-1');
      expect(retrieved[0].akb, 44);
      expect(retrieved[1].akb, 30);
    });

    test('Filter business region reports by main report ID', () async {
      // Create two main reports
      final mainReport1 = MainReport(
        userCode: '001',
        dateStart: DateTime(2025, 10, 1),
        dateEnd: DateTime(2025, 10, 9),
        countAKB: 79,
        countOKB: 402,
        cash: 29050010.0,
        transfer: 27082530.0,
        sum: 56132540.0,
        countVisited: 93,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mainReport2 = MainReport(
        userCode: '001',
        dateStart: DateTime(2025, 10, 10),
        dateEnd: DateTime(2025, 10, 16),
        countAKB: 50,
        countOKB: 200,
        cash: 15000000.0,
        transfer: 12000000.0,
        sum: 27000000.0,
        countVisited: 60,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dbService.saveMainReports([mainReport1, mainReport2]);
      final savedReports = await dbService.getMainReports(userCode: '001');
      final mainReportId1 = savedReports[0].id!;
      final mainReportId2 = savedReports[1].id!;

      // Add region reports for each main report
      await dbService.saveBusinessRegionReports([
        BusinessRegionReport(
          mainReportId: mainReportId1,
          code: 'R001',
          name: 'Region 1',
          akb: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      await dbService.saveBusinessRegionReports([
        BusinessRegionReport(
          mainReportId: mainReportId2,
          code: 'R002',
          name: 'Region 2',
          akb: 20,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      final regions1 = await dbService.getBusinessRegionReports(mainReportId: mainReportId1);
      final regions2 = await dbService.getBusinessRegionReports(mainReportId: mainReportId2);

      expect(regions1.length, 1);
      expect(regions1[0].code, 'R001');
      expect(regions2.length, 1);
      expect(regions2[0].code, 'R002');
    });
  });

  group('AKB By Categories Database Tests', () {
    test('Save and retrieve AKB by categories', () async {
      // First create a main report
      final mainReport = MainReport(
        userCode: '001',
        dateStart: DateTime(2025, 10, 1),
        dateEnd: DateTime(2025, 10, 9),
        countAKB: 79,
        countOKB: 402,
        cash: 29050010.0,
        transfer: 27082530.0,
        sum: 56132540.0,
        countVisited: 93,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dbService.saveMainReports([mainReport]);
      final savedReports = await dbService.getMainReports(userCode: '001');
      final mainReportId = savedReports[0].id!;

      final categories = [
        AKBByCategory(
          mainReportId: mainReportId,
          code: '00-00000003',
          name: 'DURU SOAP',
          akb: 56,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        AKBByCategory(
          mainReportId: mainReportId,
          code: '00-00000033',
          name: 'FAX SOAP',
          akb: 12,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await dbService.saveAKBByCategories(categories);
      final retrieved = await dbService.getAKBByCategories(mainReportId: mainReportId);

      expect(retrieved.length, 2);
      expect(retrieved[0].code, '00-00000003');
      expect(retrieved[0].name, 'DURU SOAP');
      expect(retrieved[0].akb, 56);
      expect(retrieved[1].akb, 12);
    });
  });

  group('Visit Plans Database Tests', () {
    test('Save and retrieve visit plans', () async {
      // First create a main report
      final mainReport = MainReport(
        userCode: '001',
        dateStart: DateTime(2025, 10, 1),
        dateEnd: DateTime(2025, 10, 9),
        countAKB: 79,
        countOKB: 402,
        cash: 29050010.0,
        transfer: 27082530.0,
        sum: 56132540.0,
        countVisited: 93,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dbService.saveMainReports([mainReport]);
      final savedReports = await dbService.getMainReports(userCode: '001');
      final mainReportId = savedReports[0].id!;

      final plans = [
        VisitPlan(
          mainReportId: mainReportId,
          clientCode: 'C001',
          clientName: 'Test Client 1',
          plannedDate: '2025-10-10',
          isCompleted: false,
          notes: 'First visit',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        VisitPlan(
          mainReportId: mainReportId,
          clientCode: 'C002',
          clientName: 'Test Client 2',
          plannedDate: '2025-10-11',
          isCompleted: true,
          actualVisitDate: '2025-10-11',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await dbService.saveVisitPlans(plans);
      final retrieved = await dbService.getVisitPlans(mainReportId: mainReportId);

      expect(retrieved.length, 2);
      expect(retrieved[0].clientCode, 'C001');
      expect(retrieved[0].isCompleted, false);
      expect(retrieved[1].isCompleted, true);
      expect(retrieved[1].actualVisitDate, '2025-10-11');
    });

    test('Filter visit plans by client code', () async {
      // First create a main report
      final mainReport = MainReport(
        userCode: '001',
        dateStart: DateTime(2025, 10, 1),
        dateEnd: DateTime(2025, 10, 9),
        countAKB: 79,
        countOKB: 402,
        cash: 29050010.0,
        transfer: 27082530.0,
        sum: 56132540.0,
        countVisited: 93,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dbService.saveMainReports([mainReport]);
      final savedReports = await dbService.getMainReports(userCode: '001');
      final mainReportId = savedReports[0].id!;

      await dbService.saveVisitPlans([
        VisitPlan(
          mainReportId: mainReportId,
          clientCode: 'C001',
          clientName: 'Test Client 1',
          plannedDate: '2025-10-10',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        VisitPlan(
          mainReportId: mainReportId,
          clientCode: 'C002',
          clientName: 'Test Client 2',
          plannedDate: '2025-10-11',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      final client1Plans = await dbService.getVisitPlans(clientCode: 'C001');
      final client2Plans = await dbService.getVisitPlans(clientCode: 'C002');

      expect(client1Plans.length, 1);
      expect(client1Plans[0].clientCode, 'C001');
      expect(client2Plans.length, 1);
      expect(client2Plans[0].clientCode, 'C002');
    });
  });

  group('Visit Plan Lists Database Tests', () {
    test('Save and retrieve visit plan lists', () async {
      // First create a main report and visit plan
      final mainReport = MainReport(
        userCode: '001',
        dateStart: DateTime(2025, 10, 1),
        dateEnd: DateTime(2025, 10, 9),
        countAKB: 79,
        countOKB: 402,
        cash: 29050010.0,
        transfer: 27082530.0,
        sum: 56132540.0,
        countVisited: 93,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dbService.saveMainReports([mainReport]);
      final savedReports = await dbService.getMainReports(userCode: '001');
      final mainReportId = savedReports[0].id!;

      await dbService.saveVisitPlans([
        VisitPlan(
          mainReportId: mainReportId,
          clientCode: 'C001',
          clientName: 'Test Client',
          plannedDate: '2025-10-10',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      final visitPlans = await dbService.getVisitPlans(mainReportId: mainReportId);
      final visitPlanId = visitPlans[0].id!;

      final planLists = [
        VisitPlanList(
          visitPlanId: visitPlanId,
          productCode: 'P001',
          productName: 'Product 1',
          plannedQuantity: 10,
          actualQuantity: 8,
          notes: 'Partial delivery',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        VisitPlanList(
          visitPlanId: visitPlanId,
          productCode: 'P002',
          productName: 'Product 2',
          plannedQuantity: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await dbService.saveVisitPlanLists(planLists);
      final retrieved = await dbService.getVisitPlanLists(visitPlanId: visitPlanId);

      expect(retrieved.length, 2);
      expect(retrieved[0].productCode, 'P001');
      expect(retrieved[0].plannedQuantity, 10);
      expect(retrieved[0].actualQuantity, 8);
      expect(retrieved[0].notes, 'Partial delivery');
      expect(retrieved[1].actualQuantity, null);
    });
  });

  group('Database Relationships Tests', () {
    test('Main report with all related data', () async {
      // Create main report
      final mainReport = MainReport(
        userCode: '001',
        dateStart: DateTime(2025, 10, 1),
        dateEnd: DateTime(2025, 10, 9),
        countAKB: 79,
        countOKB: 402,
        cash: 29050010.0,
        transfer: 27082530.0,
        sum: 56132540.0,
        countVisited: 93,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dbService.saveMainReports([mainReport]);
      final savedReports = await dbService.getMainReports(userCode: '001');
      final mainReportId = savedReports[0].id!;

      // Add business region reports
      await dbService.saveBusinessRegionReports([
        BusinessRegionReport(
          mainReportId: mainReportId,
          code: 'R001',
          name: 'Region 1',
          akb: 44,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      // Add AKB categories
      await dbService.saveAKBByCategories([
        AKBByCategory(
          mainReportId: mainReportId,
          code: 'C001',
          name: 'Category 1',
          akb: 56,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      // Add visit plan
      await dbService.saveVisitPlans([
        VisitPlan(
          mainReportId: mainReportId,
          clientCode: 'CL001',
          clientName: 'Client 1',
          plannedDate: '2025-10-10',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      final visitPlans = await dbService.getVisitPlans(mainReportId: mainReportId);
      final visitPlanId = visitPlans[0].id!;

      // Add visit plan list
      await dbService.saveVisitPlanLists([
        VisitPlanList(
          visitPlanId: visitPlanId,
          productCode: 'P001',
          productName: 'Product 1',
          plannedQuantity: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      // Verify all relationships
      final regions = await dbService.getBusinessRegionReports(mainReportId: mainReportId);
      final categories = await dbService.getAKBByCategories(mainReportId: mainReportId);
      final plans = await dbService.getVisitPlans(mainReportId: mainReportId);
      final planLists = await dbService.getVisitPlanLists(visitPlanId: visitPlanId);

      expect(regions.length, 1);
      expect(categories.length, 1);
      expect(plans.length, 1);
      expect(planLists.length, 1);

      // Verify foreign key relationships
      expect(regions[0].mainReportId, mainReportId);
      expect(categories[0].mainReportId, mainReportId);
      expect(plans[0].mainReportId, mainReportId);
      expect(planLists[0].visitPlanId, visitPlanId);
    });
  });

  group('Clear All Data Tests', () {
    test('Clear all data removes all records', () async {
      // Create data
      final mainReport = MainReport(
        userCode: '001',
        dateStart: DateTime(2025, 10, 1),
        dateEnd: DateTime(2025, 10, 9),
        countAKB: 79,
        countOKB: 402,
        cash: 29050010.0,
        transfer: 27082530.0,
        sum: 56132540.0,
        countVisited: 93,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dbService.saveMainReports([mainReport]);
      final savedReports = await dbService.getMainReports(userCode: '001');
      final mainReportId = savedReports[0].id!;

      await dbService.saveBusinessRegionReports([
        BusinessRegionReport(
          mainReportId: mainReportId,
          code: 'R001',
          name: 'Region 1',
          akb: 44,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      // Verify data exists
      var reports = await dbService.getMainReports();
      var regions = await dbService.getBusinessRegionReports();
      expect(reports.isNotEmpty, true);
      expect(regions.isNotEmpty, true);

      // Clear all data
      await dbService.clearAllData();

      // Verify data is cleared
      reports = await dbService.getMainReports();
      regions = await dbService.getBusinessRegionReports();
      expect(reports.isEmpty, true);
      expect(regions.isEmpty, true);
    });
  });
}