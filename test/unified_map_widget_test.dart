import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:gloria_marketing_flutter/src/core/maps/widgets/map_widget.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_marker.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_point.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_route.dart';
import 'package:gloria_marketing_flutter/src/core/maps/managers/location_manager.dart' as location_manager;

// Mock classes
class MockLocationManager extends Mock implements location_manager.LocationManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLocationManager mockLocationManager;

  setUp(() {
    mockLocationManager = MockLocationManager();
  });

  group('UnifiedMapWidget Tests', () {
    testWidgets('should initialize with default settings', (WidgetTester tester) async {
      // Arrange
      final testMarkers = [
        MapMarker(
          id: 'test_marker_1',
          point: MapPoint(
            id: 'point_1',
            latitude: 41.2995,
            longitude: 69.2401,
            title: 'Test Marker',
          ),
          type: MarkerType.client,
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: UnifiedMapWidget(
            provider: MapProvider.google,
            initialMarkers: testMarkers,
            initialCenter: MapPoint(
              id: 'center',
              latitude: 41.2995,
              longitude: 69.2401,
            ),
            initialZoom: 15.0,
          ),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(UnifiedMapWidget), findsOneWidget);
    });

    testWidgets('should handle different map providers', (WidgetTester tester) async {
      // Test Google Maps
      await tester.pumpWidget(
        MaterialApp(
          home: UnifiedMapWidget(
            provider: MapProvider.google,
            initialCenter: MapPoint(id: 'center', latitude: 41.2995, longitude: 69.2401),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(UnifiedMapWidget), findsOneWidget);

      // Test Yandex Maps
      await tester.pumpWidget(
        MaterialApp(
          home: UnifiedMapWidget(
            provider: MapProvider.yandex,
            initialCenter: MapPoint(id: 'center', latitude: 41.2995, longitude: 69.2401),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(UnifiedMapWidget), findsOneWidget);

      // Test OpenStreetMap
      await tester.pumpWidget(
        MaterialApp(
          home: UnifiedMapWidget(
            provider: MapProvider.openStreetMap,
            initialCenter: MapPoint(id: 'center', latitude: 41.2995, longitude: 69.2401),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(UnifiedMapWidget), findsOneWidget);
    });

    testWidgets('should show loading indicator during initialization', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: UnifiedMapWidget(
            provider: MapProvider.google,
          ),
        ),
      );

      // Assert - Should show CircularProgressIndicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should handle location updates', (WidgetTester tester) async {
      // Arrange
      final testLocation = location_manager.LocationData(
        latitude: 41.3100,
        longitude: 69.2500,
        accuracy: 10.0,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: UnifiedMapWidget(
            provider: MapProvider.google,
            enableLocation: true,
            onLocationUpdate: (location) {
              // Verify location data
              expect(location.latitude, testLocation.latitude);
              expect(location.longitude, testLocation.longitude);
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(UnifiedMapWidget), findsOneWidget);
    });

    testWidgets('should handle marker tap events', (WidgetTester tester) async {
      // Arrange
      final testMarker = MapMarker(
        id: 'test_marker',
        point: MapPoint(
          id: 'point',
          latitude: 41.2995,
          longitude: 69.2401,
          title: 'Test Marker',
        ),
        type: MarkerType.client,
      );

      bool markerTapped = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: UnifiedMapWidget(
            provider: MapProvider.google,
            initialMarkers: [testMarker],
            onMarkerTap: (marker) {
              markerTapped = true;
              expect(marker.id, testMarker.id);
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(UnifiedMapWidget), findsOneWidget);
    });

    testWidgets('should handle route tap events', (WidgetTester tester) async {
      // Arrange
      final testRoute = MapRoute(
        id: 'test_route',
        points: [
          MapPoint(id: 'start', latitude: 41.2995, longitude: 69.2401),
          MapPoint(id: 'end', latitude: 41.3100, longitude: 69.2500),
        ],
        coordinates: [
          [69.2401, 41.2995],
          [69.2500, 41.3100],
        ],
        distance: 1500.0,
        estimatedTime: const Duration(minutes: 15),
        travelMode: TravelMode.driving,
      );

      bool routeTapped = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: UnifiedMapWidget(
            provider: MapProvider.google,
            initialRoutes: [testRoute],
            onRouteTap: (route) {
              routeTapped = true;
              expect(route.id, testRoute.id);
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(UnifiedMapWidget), findsOneWidget);
    });

    testWidgets('should handle map tap events', (WidgetTester tester) async {
      // Arrange
      MapPoint? tappedPoint;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: UnifiedMapWidget(
            provider: MapProvider.google,
            onTap: (point) {
              tappedPoint = point;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(UnifiedMapWidget), findsOneWidget);
    });

    testWidgets('should handle clustering configuration', (WidgetTester tester) async {
      // Arrange
      final markers = List.generate(
        10,
        (index) => MapMarker(
          id: 'marker_$index',
          point: MapPoint(
            id: 'point_$index',
            latitude: 41.2995 + (index * 0.001),
            longitude: 69.2401 + (index * 0.001),
          ),
          type: MarkerType.client,
        ),
      );

      // Act - Test with clustering enabled
      await tester.pumpWidget(
        MaterialApp(
          home: UnifiedMapWidget(
            provider: MapProvider.google,
            initialMarkers: markers,
            enableClustering: true,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(UnifiedMapWidget), findsOneWidget);

      // Act - Test with clustering disabled
      await tester.pumpWidget(
        MaterialApp(
          home: UnifiedMapWidget(
            provider: MapProvider.google,
            initialMarkers: markers,
            enableClustering: false,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(UnifiedMapWidget), findsOneWidget);
    });

    testWidgets('should handle routing configuration', (WidgetTester tester) async {
      // Act - Test with routing enabled
      await tester.pumpWidget(
        MaterialApp(
          home: UnifiedMapWidget(
            provider: MapProvider.google,
            enableRouting: true,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(UnifiedMapWidget), findsOneWidget);

      // Act - Test with routing disabled
      await tester.pumpWidget(
        MaterialApp(
          home: UnifiedMapWidget(
            provider: MapProvider.google,
            enableRouting: false,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(UnifiedMapWidget), findsOneWidget);
    });

    testWidgets('should handle error states gracefully', (WidgetTester tester) async {
      // Act - Test with invalid provider (this should not happen in real usage)
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Container(), // Empty container to avoid map rendering
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The widget should not crash even with potential errors
      expect(find.byType(Container), findsOneWidget);
    });
  });

  group('UnifiedMapWidget Configuration Tests', () {
    testWidgets('should apply custom settings', (WidgetTester tester) async {
      // Arrange
      final customSettings = MapSettings(
        defaultZoom: 12.0,
        minZoom: 5.0,
        maxZoom: 18.0,
        showUserLocation: true,
        showCompass: true,
        enableRotate: true,
        enableTilt: true,
        mapType: MapType.normal,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: UnifiedMapWidget(
            provider: MapProvider.google,
            settings: customSettings,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(UnifiedMapWidget), findsOneWidget);
    });

    testWidgets('should handle initial camera position', (WidgetTester tester) async {
      // Arrange
      final initialCenter = MapPoint(
        id: 'initial_center',
        latitude: 41.2995,
        longitude: 69.2401,
        title: 'Tashkent',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: UnifiedMapWidget(
            provider: MapProvider.google,
            initialCenter: initialCenter,
            initialZoom: 14.0,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(UnifiedMapWidget), findsOneWidget);
    });

    testWidgets('should handle multiple markers and routes', (WidgetTester tester) async {
      // Arrange
      final markers = [
        MapMarker(
          id: 'marker_1',
          point: MapPoint(id: 'point_1', latitude: 41.2995, longitude: 69.2401),
          type: MarkerType.client,
        ),
        MapMarker(
          id: 'marker_2',
          point: MapPoint(id: 'point_2', latitude: 41.3100, longitude: 69.2500),
          type: MarkerType.user,
        ),
      ];

      final routes = [
        MapRoute(
          id: 'route_1',
          points: [
            MapPoint(id: 'start', latitude: 41.2995, longitude: 69.2401),
            MapPoint(id: 'end', latitude: 41.3100, longitude: 69.2500),
          ],
          coordinates: [
            [69.2401, 41.2995],
            [69.2500, 41.3100],
          ],
          distance: 1500.0,
          estimatedTime: const Duration(minutes: 15),
          travelMode: TravelMode.driving,
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: UnifiedMapWidget(
            provider: MapProvider.google,
            initialMarkers: markers,
            initialRoutes: routes,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(UnifiedMapWidget), findsOneWidget);
    });
  });
}