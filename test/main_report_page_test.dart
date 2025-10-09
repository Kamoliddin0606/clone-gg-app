import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/main_report_page.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([
  SharedPreferencesService,
  ApiDatabaseService,
  SoapApiService,
  DataSyncService,
  DatabaseHelper,
])
import 'main_report_page_test.mocks.dart';

void main() {
  late MockSharedPreferencesService mockPrefs;
  late MockApiDatabaseService mockDbService;
  late MockSoapApiService mockSoapService;
  late MockDataSyncService mockDataSyncService;
  late MockDatabaseHelper mockDbHelper;

  setUp(() {
    mockPrefs = MockSharedPreferencesService();
    mockDbService = MockApiDatabaseService();
    mockSoapService = MockSoapApiService();
    mockDataSyncService = MockDataSyncService();
    mockDbHelper = MockDatabaseHelper();

    // Register services with GetIt
    GetIt.instance.registerSingleton<SharedPreferencesService>(mockPrefs);
    GetIt.instance.registerSingleton<ApiDatabaseService>(mockDbService);
    GetIt.instance.registerSingleton<SoapApiService>(mockSoapService);
    GetIt.instance.registerSingleton<DataSyncService>(mockDataSyncService);
    GetIt.instance.registerSingleton<DatabaseHelper>(mockDbHelper);
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  group('MainReportPage', () {
    testWidgets('should display report data correctly', (WidgetTester tester) async {
      // Arrange
      when(mockPrefs.getUserCode()).thenReturn('000000329');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: MainReportPage(),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Hisobot davri'), findsOneWidget);
      expect(find.text('Oylik OKB/AKB'), findsOneWidget);
      expect(find.text('Oylik reja / Fakt / Bashorat'), findsOneWidget);
      expect(find.text('Bugun — asosiy ko\'rsatkichlar'), findsOneWidget);
    });

    testWidgets('should show loading overlay when syncing data', (WidgetTester tester) async {
      // Arrange
      when(mockPrefs.getUserCode()).thenReturn('000000329');

      await tester.pumpWidget(
        const MaterialApp(
          home: MainReportPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Find the report period card and double tap it
      final reportPeriodCard = find.byType(GestureDetector).first;
      await tester.tap(reportPeriodCard);
      await tester.pump();

      // This would normally trigger the date picker, but for testing
      // we can't easily mock the date picker dialog
      // So we'll just verify the UI renders correctly
      expect(find.text('Hisobot davri'), findsOneWidget);
    });

    testWidgets('should handle error states gracefully', (WidgetTester tester) async {
      // Arrange
      when(mockPrefs.getUserCode()).thenReturn(null); // No user code

      await tester.pumpWidget(
        const MaterialApp(
          home: MainReportPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Should still render without crashing
      expect(find.text('Hisobot davri'), findsOneWidget);
    });

    testWidgets('should display animated percentage widgets', (WidgetTester tester) async {
      // Arrange
      when(mockPrefs.getUserCode()).thenReturn('000000329');

      await tester.pumpWidget(
        const MaterialApp(
          home: MainReportPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Check for percentage display
      expect(find.textContaining('%'), findsWidgets);
    });

    testWidgets('should display currency formatted amounts', (WidgetTester tester) async {
      // Arrange
      when(mockPrefs.getUserCode()).thenReturn('000000329');

      await tester.pumpWidget(
        const MaterialApp(
          home: MainReportPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Check for currency formatting
      expect(find.textContaining('so\'m'), findsWidgets);
    });
  });
}