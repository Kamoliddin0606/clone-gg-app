import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/core/services/location_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/trading_points_page.dart';

// Mock classes
class MockLocationService extends Mock implements LocationService {}

void main() {
  group('DistanceValidationDialog Tests', () {
    late MockLocationService mockLocationService;
    late TradingPointWithPermissions testTradingPoint;

    setUp(() {
      mockLocationService = MockLocationService();

      // Create test data
      final tradingPoint = model.TradingPoint(
        id: 'test_id',
        name: 'Test Trading Point',
        address: 'Test Address',
        phone: '123456789',
        ownerName: 'Test Owner',
        contactPerson: 'Test Contact',
        inn: '123456789',
        status: 'active',
        lastVisitDate: '',
        hasOrders: false,
        hasContracts: false,
        isVisited: false,
        hasContract: false,
        latitude: 41.2995,
        longitude: 69.2401,
        region: 'Test Region',
        district: 'Test District',
        signboard: '',
        referencePoint: '',
        responsiblePerson: '',
        responsiblePersonPhone: '',
        tradePointType: '',
        creditLimit: 0.0,
        accumulatedCredit: 0.0,
        codeRegion: '',
        visitToday: true,
        visitStepNumber: 1,
        plannedWeekDay: null,
      );

      final permissions = SalesReqPermissions(
        userCode: 'test_user',
        skipTINduplicateCheck: false,
        allowCreationWithoutTIN: false,
        allowCreatingPointOfSale: false,
        visit: true,
        strictSequence: false,
        unplannedOrder: false,
        plannedRoute: false,
        editClientCoordinates: false,
        clientZoneAccess: 100, // 100 meters
        locationUpdateInterval: 0,
        visitSteps: [],
      );

      testTradingPoint = TradingPointWithPermissions(
        tradingPoint: tradingPoint,
        permissions: permissions,
      );
    });

    testWidgets('Shows dialog with correct initial data', (WidgetTester tester) async {
      // Mock location service to return 50 meters distance
      when(mockLocationService.getDistanceToTradingPoint(41.2995, 69.2401)).thenReturn(0.05); // 50 meters in km
      when(mockLocationService.getStoredLocation()).thenReturn({
        'accuracy': 5.0,
      });

      bool onConditionsMetCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => DistanceValidationDialog(
                      tradingPointWithPermissions: testTradingPoint,
                      locationService: mockLocationService,
                      onConditionsMet: () => onConditionsMetCalled = true,
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pump(); // Show dialog
      await tester.pump(); // Update dialog content

      // Verify dialog is shown
      expect(find.text('Masofa tekshiruvi'), findsOneWidget);

      // Debug: print all text widgets
      final textWidgets = find.byType(Text);
      final textContents = tester.widgetList<Text>(textWidgets).map((w) => w.data).toList();
      print('Found text widgets: $textContents');

      // Check if content is there
      expect(find.textContaining('Test Trading Point'), findsOneWidget);
      expect(find.textContaining('Talab qilingan masofa'), findsOneWidget);
    });

    testWidgets('Shows compliant status when distance is within limit', (WidgetTester tester) async {
      // Mock location service to return 80 meters distance (within 100m limit)
      when(mockLocationService.getDistanceToTradingPoint(41.2995, 69.2401)).thenReturn(0.08);
      when(mockLocationService.getStoredLocation()).thenReturn({
        'accuracy': 3.0,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => DistanceValidationDialog(
                tradingPointWithPermissions: testTradingPoint,
                locationService: mockLocationService,
                onConditionsMet: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Should show compliant status
      expect(find.text('Masofa talabiga javob beradi'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('Shows non-compliant status when distance exceeds limit', (WidgetTester tester) async {
      // Mock location service to return 150 meters distance (exceeds 100m limit)
      when(mockLocationService.getDistanceToTradingPoint(41.2995, 69.2401)).thenReturn(0.15);
      when(mockLocationService.getStoredLocation()).thenReturn({
        'accuracy': 5.0,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => DistanceValidationDialog(
                tradingPointWithPermissions: testTradingPoint,
                locationService: mockLocationService,
                onConditionsMet: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Should show non-compliant status
      expect(find.text('Masofa talabiga javob bermaydi'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('Updates data every 2 seconds', (WidgetTester tester) async {
      // Mock initial distance
      when(mockLocationService.getDistanceToTradingPoint(41.2995, 69.2401)).thenReturn(0.12); // 120m
      when(mockLocationService.getStoredLocation()).thenReturn({
        'accuracy': 5.0,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceValidationDialog(
              tradingPointWithPermissions: testTradingPoint,
              locationService: mockLocationService,
              onConditionsMet: () {},
            ),
          ),
        ),
      );

      await tester.pump();

      // Initial state should show 120m
      expect(find.textContaining('Joriy masofa: 120m'), findsOneWidget);

      // Mock updated distance after 2 seconds
      when(mockLocationService.getDistanceToTradingPoint(41.2995, 69.2401)).thenReturn(0.06); // 60m
      when(mockLocationService.getStoredLocation()).thenReturn({
        'accuracy': 3.0,
      });

      // Wait for 2 seconds update
      await tester.pump(const Duration(seconds: 2));

      // Should now show 60m
      expect(find.textContaining('Joriy masofa: 60m'), findsOneWidget);
      expect(find.textContaining('GPS aniqligi: 3.0m'), findsOneWidget);
    });

    testWidgets('Calls onConditionsMet when conditions become met', (WidgetTester tester) async {
      // Start with non-compliant distance
      when(mockLocationService.getDistanceToTradingPoint(41.2995, 69.2401)).thenReturn(0.15); // 150m
      when(mockLocationService.getStoredLocation()).thenReturn({
        'accuracy': 5.0,
      });

      bool onConditionsMetCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceValidationDialog(
              tradingPointWithPermissions: testTradingPoint,
              locationService: mockLocationService,
              onConditionsMet: () => onConditionsMetCalled = true,
            ),
          ),
        ),
      );

      await tester.pump();

      // Initially should not be called
      expect(onConditionsMetCalled, false);

      // Update to compliant distance
      when(mockLocationService.getDistanceToTradingPoint(41.2995, 69.2401)).thenReturn(0.05); // 50m

      // Wait for update
      await tester.pump(const Duration(seconds: 2));

      // Should now be called
      expect(onConditionsMetCalled, true);
    });
  });

  group('DistanceValidationDialog Initialization Tests', () {
    late MockLocationService mockLocationService;
    late TradingPointWithPermissions testTradingPoint;

    setUp(() {
      mockLocationService = MockLocationService();

      // Create test data with compliant distance
      final tradingPoint = model.TradingPoint(
        id: 'test_id',
        name: 'Test Trading Point',
        address: 'Test Address',
        phone: '123456789',
        ownerName: 'Test Owner',
        contactPerson: 'Test Contact',
        inn: '123456789',
        status: 'active',
        lastVisitDate: '',
        hasOrders: false,
        hasContracts: false,
        isVisited: false,
        hasContract: false,
        latitude: 41.2995,
        longitude: 69.2401,
        region: 'Test Region',
        district: 'Test District',
        signboard: '',
        referencePoint: '',
        responsiblePerson: '',
        responsiblePersonPhone: '',
        tradePointType: '',
        creditLimit: 0.0,
        accumulatedCredit: 0.0,
        codeRegion: '',
        visitToday: true,
        visitStepNumber: 1,
        plannedWeekDay: null,
      );

      final permissions = SalesReqPermissions(
        userCode: 'test_user',
        skipTINduplicateCheck: false,
        allowCreationWithoutTIN: false,
        allowCreatingPointOfSale: false,
        visit: true,
        strictSequence: false,
        unplannedOrder: false,
        plannedRoute: false,
        editClientCoordinates: false,
        clientZoneAccess: 100, // 100 meters
        locationUpdateInterval: 0,
        visitSteps: [],
      );

      testTradingPoint = TradingPointWithPermissions(
        tradingPoint: tradingPoint,
        permissions: permissions,
      );
    });

    testWidgets('Dialog renders fully before checking conditions - prevents premature closure',
        (WidgetTester tester) async {
      // Mock location service to return compliant distance immediately
      // This simulates the scenario where conditions ARE met from the start
      when(mockLocationService.getDistanceToTradingPoint(41.2995, 69.2401))
          .thenReturn(0.05); // 50 meters (within 100m limit)
      // Omit latitude/longitude to skip FlutterMap rendering (avoids test issues)
      when(mockLocationService.getStoredLocation()).thenReturn({
        'accuracy': 5.0,
      });

      bool onConditionsMetCalled = false;
      int onConditionsMetCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) => DistanceValidationDialog(
                      tradingPointWithPermissions: testTradingPoint,
                      locationService: mockLocationService,
                      onConditionsMet: () {
                        onConditionsMetCalled = true;
                        onConditionsMetCallCount++;
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      
      // First pump - starts showing dialog
      await tester.pump();
      
      // At this point, dialog should be visible but onConditionsMet should NOT be called yet
      // because addPostFrameCallback hasn't fired
      expect(find.text('Masofa tekshiruvi'), findsOneWidget);
      
      // After pumpAndSettle, the postFrameCallback will fire
      await tester.pumpAndSettle();
      
      // Now onConditionsMet should have been called (conditions are met)
      expect(onConditionsMetCalled, true);
      // Should only be called once (not multiple times)
      expect(onConditionsMetCallCount, 1);
    });

    testWidgets('Dialog shows content when conditions are not met',
        (WidgetTester tester) async {
      // Mock location service to return non-compliant distance
      when(mockLocationService.getDistanceToTradingPoint(41.2995, 69.2401))
          .thenReturn(0.15); // 150 meters (exceeds 100m limit)
      // Omit latitude/longitude to skip FlutterMap rendering (avoids test issues)
      when(mockLocationService.getStoredLocation()).thenReturn({
        'accuracy': 5.0,
      });

      bool onConditionsMetCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) => DistanceValidationDialog(
                      tradingPointWithPermissions: testTradingPoint,
                      locationService: mockLocationService,
                      onConditionsMet: () {
                        onConditionsMetCalled = true;
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Dialog should be visible and onConditionsMet should NOT be called
      expect(find.text('Masofa tekshiruvi'), findsOneWidget);
      expect(find.text('Masofa talabiga javob bermaydi'), findsOneWidget);
      expect(onConditionsMetCalled, false);
      
      // Cancel button should be visible
      expect(find.text('Bekor qilish'), findsOneWidget);
      
      // Continue button should NOT be visible (conditions not met)
      expect(find.text('Davom etish'), findsNothing);
    });

    testWidgets('Timer only checks conditions after dialog is ready',
        (WidgetTester tester) async {
      // Start with non-compliant distance (no user location to avoid map rendering)
      when(mockLocationService.getDistanceToTradingPoint(41.2995, 69.2401))
          .thenReturn(0.15); // 150 meters
      when(mockLocationService.getStoredLocation()).thenReturn({
        'accuracy': 5.0,
        // Intentionally omit latitude/longitude to skip map rendering
      });

      bool onConditionsMetCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) => DistanceValidationDialog(
                      tradingPointWithPermissions: testTradingPoint,
                      locationService: mockLocationService,
                      onConditionsMet: () {
                        onConditionsMetCalled = true;
                      },
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      
      // Should not be called yet (distance is non-compliant)
      expect(onConditionsMetCalled, false);

      // Update to compliant distance
      when(mockLocationService.getDistanceToTradingPoint(41.2995, 69.2401))
          .thenReturn(0.05); // 50 meters

      // Wait for 2 second timer update
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(); // Additional pump for setState

      // Now should be called (timer checked conditions after dialog was ready)
      expect(onConditionsMetCalled, true);
      
      // Clean up - close dialog to avoid timer issues
      await tester.tap(find.text('Bekor qilish'));
      await tester.pumpAndSettle();
    });
  });

  group('DistanceComplianceProgressBar Tests', () {
    testWidgets('Shows compliant progress bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DistanceComplianceProgressBar(
              currentDistance: 50,
              requiredDistance: 100,
              tradingPointId: 'test_id',
            ),
          ),
        ),
      );

      expect(find.text('Masofa mosligi'), findsOneWidget);
      expect(find.text('Masofa talabiga javob beradi'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('Shows non-compliant progress bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DistanceComplianceProgressBar(
              currentDistance: 150,
              requiredDistance: 100,
              tradingPointId: 'test_id',
            ),
          ),
        ),
      );

      expect(find.text('Masofa talabiga javob bermaydi'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}