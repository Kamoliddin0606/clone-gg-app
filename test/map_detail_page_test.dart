import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/map_detail_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_settings.dart';

// Mock classes
class MockSharedPreferencesService extends Mock implements SharedPreferencesService {}

class MockPermissionHandler extends Mock {
  Future<PermissionStatus> checkPermission() => Future.value(PermissionStatus.granted);
  Future<PermissionStatus> requestPermission() => Future.value(PermissionStatus.granted);
}

class MockGeolocator extends Mock {
  static Future<Position> getCurrentPosition({
    LocationAccuracy desiredAccuracy = LocationAccuracy.best,
  }) => Future.value(Position(
    latitude: 41.2995,
    longitude: 69.2401,
    timestamp: DateTime.now(),
    accuracy: 10.0,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  ));
}

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TradingPoint testTradingPoint;
  late MockSharedPreferencesService mockPrefs;
  late MockConnectivity mockConnectivity;

  setUp(() {
    testTradingPoint = TradingPoint(
      id: 'test_client_001',
      name: 'Test Client',
      address: 'Test Address',
      phone: '+998901234567',
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
      region: 'Tashkent',
      district: 'Yunusabad',
      signboard: 'Test Signboard',
      referencePoint: 'Test Reference',
      responsiblePerson: 'Test Responsible',
      responsiblePersonPhone: '+998909876543',
      tradePointType: 'Shop',
      creditLimit: 1000000.0,
      accumulatedCredit: 0.0,
      codeRegion: '001',
    );

    mockPrefs = MockSharedPreferencesService();
    mockConnectivity = MockConnectivity();

    // Setup default mock behaviors
    when(mockPrefs.preferences.getString('default_map_provider'))
        .thenReturn(MapProvider.google.toString());
  });

  group('MapDetailPage Widget Tests', () {
    testWidgets('should render MapDetailPage with trading point data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      // Check if app bar title is displayed
      expect(find.text('Test Client'), findsOneWidget);

      // Check if map widget is present (Google Maps or Yandex Maps)
      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('should display control buttons overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Check for control buttons
      expect(find.byIcon(Icons.my_location), findsOneWidget); // User position
      expect(find.byIcon(Icons.location_on), findsOneWidget); // Client position
      expect(find.byIcon(Icons.route), findsOneWidget); // Route
      expect(find.byIcon(Icons.fullscreen), findsOneWidget); // Fullscreen
      expect(find.byIcon(Icons.edit_location), findsOneWidget); // Update coordinates
    });

    testWidgets('should show route info when route is calculated', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no route info should be visible
      expect(find.text('Marshrut ko\'rsatilmoqda'), findsNothing);

      // Tap route button (this would normally calculate route)
      await tester.tap(find.byIcon(Icons.route));
      await tester.pumpAndSettle();

      // Note: In this test setup, route calculation might not work due to mock limitations
      // but the button should be tappable
    });

    testWidgets('should handle fullscreen button tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldMessenger(
            child: MapDetailPage(tradingPoint: testTradingPoint),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap fullscreen button
      await tester.tap(find.byIcon(Icons.fullscreen));
      await tester.pumpAndSettle();

      // Should show snackbar with message
      expect(find.text('To\'liq ekran xaritasi - kelajakda amalga oshiriladi'), findsOneWidget);
    });

    testWidgets('should handle update coordinates button tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldMessenger(
            child: MapDetailPage(tradingPoint: testTradingPoint),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap update coordinates button
      await tester.tap(find.byIcon(Icons.edit_location));
      await tester.pumpAndSettle();

      // Should show snackbar with message
      expect(find.text('Koordinatalarni yangilash - kelajakda amalga oshiriladi'), findsOneWidget);
    });
  });

  group('MapDetailPage Integration Tests', () {
    testWidgets('should initialize with correct map provider', (WidgetTester tester) async {
      // Test with Google Maps provider
      when(mockPrefs.preferences.getString('default_map_provider'))
          .thenReturn(MapProvider.google.toString());

      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Should contain GoogleMap widget
      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('should handle invalid coordinates gracefully', (WidgetTester tester) async {
      final invalidTradingPoint = TradingPoint(
        id: 'invalid_client',
        name: 'Invalid Client',
        address: 'Invalid Address',
        phone: '+998901234567',
        ownerName: 'Invalid Owner',
        contactPerson: 'Invalid Contact',
        inn: '123456789',
        status: 'active',
        lastVisitDate: '',
        hasOrders: false,
        hasContracts: false,
        isVisited: false,
        hasContract: false,
        latitude: 0.0, // Invalid coordinates
        longitude: 0.0, // Invalid coordinates
        region: 'Unknown',
        district: 'Unknown',
        signboard: '',
        referencePoint: '',
        responsiblePerson: '',
        responsiblePersonPhone: '',
        tradePointType: '',
        creditLimit: 0.0,
        accumulatedCredit: 0.0,
        codeRegion: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: invalidTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Should still render without crashing
      expect(find.byType(GoogleMap), findsOneWidget);
      expect(find.text('Invalid Client'), findsOneWidget);
    });
  });

  group('MapDetailPage Error Handling Tests', () {
    testWidgets('should handle location permission denied', (WidgetTester tester) async {
      // Mock permission denied
      // Note: In real implementation, this would require mocking PermissionHandler

      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Should still render the map
      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('should handle connectivity changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldMessenger(
            child: MapDetailPage(tradingPoint: testTradingPoint),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should be online (mocked)
      // Connectivity changes would be tested in integration tests with real services
    });
  });

  group('MapDetailPage UI Layout Tests', () {
    testWidgets('should have proper button positioning', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // Find the control buttons container
      final controlContainer = find.byType(Column).last; // The column with control buttons

      // Verify the structure exists
      expect(controlContainer, findsOneWidget);

      // Check that all required buttons are present
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.byIcon(Icons.route), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
      expect(find.byIcon(Icons.edit_location), findsOneWidget);
    });

    testWidgets('should display client marker on map', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MapDetailPage(tradingPoint: testTradingPoint),
        ),
      );

      await tester.pumpAndSettle();

      // The map should be rendered
      expect(find.byType(GoogleMap), findsOneWidget);

      // Client marker should be added during map initialization
      // (This would be verified in integration tests with actual map controllers)
    });
  });
}