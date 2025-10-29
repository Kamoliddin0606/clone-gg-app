import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:gloria_marketing_flutter/src/core/maps/controllers/unified_map_controller.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_point.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_settings.dart';

// Mock classes for testing
class MockGoogleMapController extends Mock implements dynamic {}
class MockYandexMapWindow extends Mock implements dynamic {}
class MockOsmController extends Mock implements dynamic {}

void main() {
  group('UnifiedMapController', () {
    late UnifiedMapController controller;
    late MapPoint testPoint;

    setUp(() {
      controller = UnifiedMapController();
      testPoint = MapPoint(
        id: 'test',
        latitude: 41.2995,
        longitude: 69.2401,
        title: 'Test Location',
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('should initialize correctly', () {
      expect(controller.isReady, false);

      controller.initialize(
        provider: MapProvider.google,
        googleController: MockGoogleMapController(),
      );

      expect(controller.isReady, true);
    });

    test('should handle animateTo with valid parameters', () async {
      controller.initialize(
        provider: MapProvider.google,
        googleController: MockGoogleMapController(),
      );

      // Test with default parameters
      await controller.animateTo(target: testPoint);

      // Test with custom parameters
      await controller.animateTo(
        target: testPoint,
        zoom: 16.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.linear,
      );
    });

    test('should handle fitBounds with valid bounds', () async {
      controller.initialize(
        provider: MapProvider.google,
        googleController: MockGoogleMapController(),
      );

      final sw = MapPoint(id: 'sw', latitude: 41.0, longitude: 69.0);
      final ne = MapPoint(id: 'ne', latitude: 42.0, longitude: 70.0);

      await controller.fitBounds(
        sw: sw,
        ne: ne,
        padding: const EdgeInsets.all(16),
      );
    });

    test('should handle different map providers', () async {
      // Test Google Maps
      controller.initialize(
        provider: MapProvider.google,
        googleController: MockGoogleMapController(),
      );
      expect(controller.isReady, true);

      // Test Yandex Maps
      controller.initialize(
        provider: MapProvider.yandex,
        yandexMapWindow: MockYandexMapWindow(),
      );
      expect(controller.isReady, true);

      // Test OSM
      controller.initialize(
        provider: MapProvider.openStreetMap,
        osmController: MockOsmController(),
      );
      expect(controller.isReady, true);
    });

    test('should handle uninitialized state', () async {
      // Controller not initialized
      expect(controller.isReady, false);

      // Should not throw but handle gracefully
      await controller.animateTo(target: testPoint);
      await controller.fitBounds(
        sw: MapPoint(id: 'sw', latitude: 41.0, longitude: 69.0),
        ne: MapPoint(id: 'ne', latitude: 42.0, longitude: 70.0),
      );
    });

    test('should dispose correctly', () {
      controller.initialize(
        provider: MapProvider.google,
        googleController: MockGoogleMapController(),
      );

      expect(controller.isReady, true);

      controller.dispose();

      expect(controller.isReady, false);
    });
  });

  group('MapPoint', () {
    test('should create MapPoint correctly', () {
      final point = MapPoint(
        id: 'test',
        latitude: 41.2995,
        longitude: 69.2401,
        title: 'Test Point',
        description: 'Test Description',
      );

      expect(point.id, 'test');
      expect(point.latitude, 41.2995);
      expect(point.longitude, 69.2401);
      expect(point.title, 'Test Point');
      expect(point.description, 'Test Description');
    });

    test('should calculate distance correctly', () {
      final point1 = MapPoint(id: '1', latitude: 41.2995, longitude: 69.2401);
      final point2 = MapPoint(id: '2', latitude: 41.2995, longitude: 69.2402);

      final distance = point1.distanceTo(point2);
      expect(distance, greaterThan(0));
    });
  });

  group('MapSettings', () {
    test('should create default settings', () {
      final settings = MapSettings();

      expect(settings.provider, MapProvider.google);
      expect(settings.defaultZoom, 15.0);
      expect(settings.showUserLocation, false);
    });

    test('should copy with new values', () {
      final original = MapSettings();
      final updated = original.copyWith(
        provider: MapProvider.yandex,
        defaultZoom: 16.0,
        showUserLocation: true,
      );

      expect(updated.provider, MapProvider.yandex);
      expect(updated.defaultZoom, 16.0);
      expect(updated.showUserLocation, true);
    });
  });
}