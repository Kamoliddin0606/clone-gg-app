import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:gloria_marketing_flutter/src/core/services/reports_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/main_report.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/business_region_report.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/akb_by_category.dart';

// Generate mocks
// flutter pub run build_runner build

// Mock classes
class MockSharedPreferencesService extends Mock implements SharedPreferencesService {}
class MockSoapApiService extends Mock implements SoapApiService {}
class MockApiDatabaseService extends Mock implements ApiDatabaseService {}
class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late ReportsSyncService reportsSyncService;
  late MockSharedPreferencesService mockPrefs;
  late MockSoapApiService mockApiService;
  late MockApiDatabaseService mockDbService;
  late MockDatabaseHelper mockDbHelper;

  setUp(() {
    mockPrefs = MockSharedPreferencesService();
    mockApiService = MockSoapApiService();
    mockDbService = MockApiDatabaseService();
    mockDbHelper = MockDatabaseHelper();

    reportsSyncService = ReportsSyncService(
      prefs: mockPrefs,
      apiService: mockApiService,
      dbService: mockDbService,
      dbHelper: mockDbHelper,
    );
  });

  group('ReportsSyncService Tests', () {
    test('syncAllReports calls syncReportByPeriod', () async {
      // Arrange
      const userCode = 'TEST001';
      const password = 'password123';

      when(mockApiService.getReportByPeriod(
        userCode: userCode,
        dateStart: '2025-10-01',
        dateEnd: '2025-10-31',
      )).thenAnswer((_) async => {
        'mainReport': MainReport(
          userCode: userCode,
          dateStart: DateTime(2025, 10, 1),
          dateEnd: DateTime(2025, 10, 31),
          countAKB: 10,
          countOKB: 20,
          cash: 1000.0,
          transfer: 2000.0,
          sum: 3000.0,
          countVisited: 5,
        ),
        'businessRegionReports': <BusinessRegionReport>[],
        'akbByCategories': <AKBByCategory>[],
      });

      // Act
      await reportsSyncService.syncAllReports(
        userCode: userCode,
        password: password,
      );

      // Assert
      verify(mockApiService.getReportByPeriod(
        userCode: userCode,
        dateStart: '2025-10-01',
        dateEnd: '2025-10-31',
      )).called(1);
    });

    test('syncReportByPeriod fetches from API when no cache', () async {
      // Arrange
      const userCode = 'TEST001';
      const dateStart = '2025-10-01';
      const dateEnd = '2025-10-31';

      final apiReport = MainReport(
        userCode: userCode,
        dateStart: DateTime.parse(dateStart),
        dateEnd: DateTime.parse(dateEnd),
        countAKB: 15,
        countOKB: 25,
        cash: 1500.0,
        transfer: 2500.0,
        sum: 4000.0,
        countVisited: 8,
      );

      when(mockDbService.getMainReports(userCode: userCode))
          .thenAnswer((_) async => []);
      when(mockApiService.getReportByPeriod(
        userCode: userCode,
        dateStart: dateStart,
        dateEnd: dateEnd,
      )).thenAnswer((_) async => {
        'mainReport': apiReport,
        'businessRegionReports': <BusinessRegionReport>[],
        'akbByCategories': <AKBByCategory>[],
      });

      // Act
      final result = await reportsSyncService.syncReportByPeriod(
        userCode: userCode,
        dateStart: dateStart,
        dateEnd: dateEnd,
        forceRefresh: false,
      );

      // Assert
      expect(result['mainReport'].userCode, equals(userCode));
    });

    test('createMainReport saves report to database', () async {
      // Arrange
      const userCode = 'TEST001';
      final dateStart = DateTime(2025, 10, 1);
      final dateEnd = DateTime(2025, 10, 31);

      // Act
      final result = await reportsSyncService.createMainReport(
        userCode: userCode,
        dateStart: dateStart,
        dateEnd: dateEnd,
        countAKB: 10,
        countOKB: 20,
        cash: 1000.0,
        transfer: 2000.0,
        sum: 3000.0,
        countVisited: 5,
      );

      // Assert
      expect(result.userCode, equals(userCode));
      expect(result.dateStart, equals(dateStart));
      expect(result.countAKB, equals(10));
    });

    test('createBusinessRegionReport saves report to database', () async {
      // Arrange
      const mainReportId = 1;
      const code = 'REGION001';
      const name = 'Test Region';
      const akb = 50;

      // Act
      final result = await reportsSyncService.createBusinessRegionReport(
        mainReportId: mainReportId,
        code: code,
        name: name,
        akb: akb,
      );

      // Assert
      expect(result.mainReportId, equals(mainReportId));
      expect(result.code, equals(code));
      expect(result.name, equals(name));
      expect(result.akb, equals(akb));
    });

    test('createAKBByCategory saves category to database', () async {
      // Arrange
      const mainReportId = 1;
      const code = 'CAT001';
      const name = 'Test Category';
      const akb = 30;

      // Act
      final result = await reportsSyncService.createAKBByCategory(
        mainReportId: mainReportId,
        code: code,
        name: name,
        akb: akb,
      );

      // Assert
      expect(result.mainReportId, equals(mainReportId));
      expect(result.code, equals(code));
      expect(result.name, equals(name));
      expect(result.akb, equals(akb));
    });

    test('createVisitPlan saves plan to database', () async {
      // Arrange
      const mainReportId = 1;
      const clientCode = 'CLIENT001';
      const clientName = 'Test Client';
      const plannedDate = '2025-10-15';
      const isCompleted = false;
      const notes = 'Test notes';

      // Act
      final result = await reportsSyncService.createVisitPlan(
        mainReportId: mainReportId,
        clientCode: clientCode,
        clientName: clientName,
        plannedDate: plannedDate,
        isCompleted: isCompleted,
        notes: notes,
      );

      // Assert
      expect(result.mainReportId, equals(mainReportId));
      expect(result.clientCode, equals(clientCode));
      expect(result.clientName, equals(clientName));
      expect(result.plannedDate, equals(plannedDate));
      expect(result.isCompleted, equals(isCompleted));
      expect(result.notes, equals(notes));
    });

    test('getCachedMainReports returns data from database', () async {
      // Arrange
      final reports = [
        MainReport(
          userCode: 'TEST001',
          dateStart: DateTime(2025, 10, 1),
          dateEnd: DateTime(2025, 10, 31),
          countAKB: 10,
          countOKB: 20,
          cash: 1000.0,
          transfer: 2000.0,
          sum: 3000.0,
          countVisited: 5,
        ),
      ];

      when(mockDbService.getMainReports(userCode: anyNamed('userCode')))
          .thenAnswer((_) async => reports);

      // Act
      final result = await reportsSyncService.getCachedMainReports(userCode: 'TEST001');

      // Assert
      expect(result, equals(reports));
      verify(mockDbService.getMainReports(userCode: 'TEST001')).called(1);
    });

    test('clearAllReportData calls database clear methods', () async {
      // Act
      await reportsSyncService.clearAllReportData();

      // Assert
      verify(mockDbService.clearMainReport()).called(1);
    });

  });
}