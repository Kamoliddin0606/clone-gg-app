import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/map_detail_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/core/maps/widgets/map_widget.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_settings.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_point.dart';
import 'package:gloria_marketing_flutter/src/core/maps/managers/location_manager.dart' as location_manager;
import 'package:gloria_marketing_flutter/src/core/maps/managers/route_manager.dart' as route_manager;
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

// Mock classes
class MockSharedPreferencesService extends Mock implements SharedPreferencesService {}

class MockLocationManager extends Mock implements location_manager.LocationManager {}

class MockRouteManager extends Mock implements route_manager.RouteManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSharedPreferencesService mockPrefs;
  late MockLocationManager mockLocationManager;
  late MockRouteManager mockRouteManager;
  late TradingPoint testTradingPoint;

  setUp(() {
    mockPrefs = MockSharedPreferencesService();
    mockLocationManager = MockLocationManager();
    mockRouteManager = MockRouteManager();

    testTradingPoint = TradingPoint(
      id: 'test_client_1',
      name: 'Test Client',
      latitude: 41.2995,
      longitude: 69.2401,
      address: 'Test Address',
      phone: '+998901234567',
      ownerName: 'Test Owner',
      contactPerson: 'Test Contact',
      inn: '123456789',
      status: 'active',
      lastVisitDate: DateTime.now().toIso8601String(),
      hasOrders: false,
      hasContracts: true,
      hasContract: true,
      isVisited: false,
      region: 'Tashkent',
      district: 'Test District',
      signboard: 'Test Signboard',
      referencePoint: 'Test Reference',
      responsiblePerson: 'Test Responsible',
      responsiblePersonPhone: '+998987654321',
      tradePointType: 'retail',
      creditLimit: 1000000.0,
      accumulatedCredit: 0.0,
      codeRegion: '01',
    );
  });

  group('MapDetailPage Unified Widget Tests', () {
    testWidgets('should display map with client marker', (WidgetTester tester) async {
      // Arrange
      when(mockPrefs.preferences.getString('default_map_provider'))
          .thenReturn('google');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(UnifiedMapWidget), findsOneWidget);
      expect(find.text('Test Client'), findsOneWidget);
    });

    testWidgets('should show control buttons overlay', (WidgetTester tester) async {
      // Arrange
      when(mockPrefs.preferences.getString('default_map_provider'))
          .thenReturn('google');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Check for control buttons
      expect(find.byIcon(Icons.my_location), findsOneWidget); // User position
      expect(find.byIcon(Icons.location_on), findsOneWidget); // Client position
      expect(find.byIcon(Icons.route), findsOneWidget); // Route
      expect(find.byIcon(Icons.fullscreen), findsOneWidget); // Fullscreen
      expect(find.byIcon(Icons.edit_location), findsOneWidget); // Update coordinates
    });

    testWidgets('should handle route button tap', (WidgetTester tester) async {
      // Arrange
      when(mockPrefs.preferences.getString('default_map_provider'))
          .thenReturn('google');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Tap route button
      await tester.tap(find.byIcon(Icons.route));
      await tester.pumpAndSettle();

      // Assert - Should show snackbar (since user location not available in test)
      expect(find.text('Foydalanuvchi joylashuvi aniqlanmadi'), findsOneWidget);
    });

    testWidgets('should handle user position button tap', (WidgetTester tester) async {
      // Arrange
      when(mockPrefs.preferences.getString('default_map_provider'))
          .thenReturn('google');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Tap user position button
      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pumpAndSettle();

      // Assert - Should show snackbar (camera movement message)
      expect(find.textContaining('ga kamera o\'tkazildi'), findsOneWidget);
    });

    testWidgets('should handle client position button tap', (WidgetTester tester) async {
      // Arrange
      when(mockPrefs.preferences.getString('default_map_provider'))
          .thenReturn('google');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Tap client position button
      await tester.tap(find.byIcon(Icons.location_on));
      await tester.pumpAndSettle();

      // Assert - Should show snackbar (camera movement message)
      expect(find.textContaining('ga kamera o\'tkazildi'), findsOneWidget);
    });

    testWidgets('should handle fullscreen button tap', (WidgetTester tester) async {
      // Arrange
      when(mockPrefs.preferences.getString('default_map_provider'))
          .thenReturn('google');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Tap fullscreen button
      await tester.tap(find.byIcon(Icons.fullscreen));
      await tester.pumpAndSettle();

      // Assert - Should show placeholder message
      expect(find.text('To\'liq ekran xaritasi - amalga oshirilmoqda'), findsOneWidget);
    });

    testWidgets('should handle update coordinates button tap', (WidgetTester tester) async {
      // Arrange
      when(mockPrefs.preferences.getString('default_map_provider'))
          .thenReturn('google');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Tap update coordinates button
      await tester.tap(find.byIcon(Icons.edit_location));
      await tester.pumpAndSettle();

      // Assert - Should show placeholder message
      expect(find.text('Koordinatalarni yangilash - amalga oshirilmoqda'), findsOneWidget);
    });

    testWidgets('should initialize with correct client data', (WidgetTester tester) async {
      // Arrange
      when(mockPrefs.preferences.getString('default_map_provider'))
          .thenReturn('google');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Client'), findsOneWidget);

      // Check that UnifiedMapWidget is initialized with correct data
      final unifiedMapWidget = tester.widget<UnifiedMapWidget>(
        find.byType(UnifiedMapWidget),
      );

      expect(unifiedMapWidget.provider, MapProvider.google);
      expect(unifiedMapWidget.initialMarkers.length, 1);
      expect(unifiedMapWidget.initialMarkers.first.title, 'Test Client');
    });
  });

  group('MapDetailPage Manager Integration Tests', () {
    testWidgets('should initialize managers correctly', (WidgetTester tester) async {
      // Arrange
      when(mockPrefs.preferences.getString('default_map_provider'))
          .thenReturn('google');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Widget should be built without errors
      expect(find.byType(UnifiedMapWidget), findsOneWidget);
      expect(find.byType(MapDetailPage), findsOneWidget);
    });

    testWidgets('should handle different map providers', (WidgetTester tester) async {
      // Test Google Maps
      when(mockPrefs.preferences.getString('default_map_provider'))
          .thenReturn('google');

      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      UnifiedMapWidget googleMap = tester.widget(find.byType(UnifiedMapWidget));
      expect(googleMap.provider, MapProvider.google);

      // Test Yandex Maps
      when(mockPrefs.preferences.getString('default_map_provider'))
          .thenReturn('yandex');

      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      UnifiedMapWidget yandexMap = tester.widget(find.byType(UnifiedMapWidget));
      expect(yandexMap.provider, MapProvider.yandex);

      // Test OpenStreetMap
      when(mockPrefs.preferences.getString('default_map_provider'))
          .thenReturn('openStreetMap');

      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      UnifiedMapWidget osmMap = tester.widget(find.byType(UnifiedMapWidget));
      expect(osmMap.provider, MapProvider.openStreetMap);
    });
  });
}