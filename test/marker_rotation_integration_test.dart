import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart' as yandex;
import 'package:flutter_map/flutter_map.dart' as osm;
import 'package:latlong2/latlong.dart' as osm_latlong;
import 'dart:math' as math;
import 'package:gloria_marketing_flutter/src/core/maps/utils/marker_rotation_utils.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_marker.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_point.dart';

void main() {
  group('Marker Rotation Integration Tests', () {
    test('Google Maps marker rotation calculation', () {
      // Test that markers are rotated correctly for Google Maps
      const double mapRotation = 45.0;
      final rotation = MarkerRotationUtils.calculateFixedMarkerRotation(mapRotation);

      // Markers should be rotated by negative of map rotation to stay upright
      expect(rotation, equals(-mapRotation));
    });

    test('Yandex Maps marker direction calculation', () {
      // Test that markers are rotated correctly for Yandex Maps
      const double mapRotation = 90.0;
      final direction = MarkerRotationUtils.calculateFixedMarkerRotation(mapRotation);

      // Direction should be negative of map rotation
      expect(direction, equals(-mapRotation));
    });

    test('Marker rotation constraints', () {
      // Test that extreme rotations are constrained
      const double extremeRotation = 180.0;
      final constrained = MarkerRotationUtils.constrainMarkerRotation(extremeRotation);

      // Should be constrained to maximum allowed rotation
      expect(constrained.abs(), lessThanOrEqualTo(90.0));
    });

    test('Rotation animation duration calculation', () {
      // Test animation duration for different rotation changes
      final smallChange = MarkerRotationUtils.calculateRotationAnimationDuration(10.0);
      final largeChange = MarkerRotationUtils.calculateRotationAnimationDuration(60.0);

      // Larger changes should have longer animation duration
      expect(largeChange, greaterThan(smallChange));
    });

    test('Marker anchor calculation', () {
      // Test that marker anchors are calculated correctly
      final mockMarker = MapMarker(
        id: 'test',
        point: MapPoint(id: 'test', latitude: 0.0, longitude: 0.0),
        type: MarkerType.default_,
      );

      final anchor = MarkerRotationUtils.calculateMarkerAnchor(mockMarker, 30.0);

      // Anchor should be valid Offset
      expect(anchor, isA<Offset>());
      expect(anchor.dx, greaterThanOrEqualTo(0.0));
      expect(anchor.dy, greaterThanOrEqualTo(0.0));
    });

    test('Marker visibility based on rotation', () {
      // Test that markers are shown/hidden based on rotation
      final mockMarker = MapMarker(
        id: 'test',
        point: MapPoint(id: 'test', latitude: 0.0, longitude: 0.0),
        type: MarkerType.cluster,
      );

      final visible = MarkerRotationUtils.shouldShowMarker(mockMarker, 30.0, null);
      final hidden = MarkerRotationUtils.shouldShowMarker(mockMarker, 50.0, null);

      // Markers should be visible at normal rotations
      expect(visible, isTrue);
      // Cluster markers are hidden at extreme rotations (> 45 degrees)
      expect(hidden, isFalse); // Fixed: cluster markers are hidden at 50 degrees
    });

    test('Marker rotation behavior extension', () {
      // Test marker extension methods
      final userMarker = MapMarker(
        id: 'user',
        point: MapPoint(id: 'user', latitude: 0.0, longitude: 0.0),
        type: MarkerType.user,
      );

      final clusterMarker = MapMarker(
        id: 'cluster',
        point: MapPoint(id: 'cluster', latitude: 0.0, longitude: 0.0),
        type: MarkerType.cluster,
      );

      // All markers should maintain upright orientation
      expect(userMarker.shouldMaintainUprightOrientation, isTrue);
      expect(clusterMarker.shouldMaintainUprightOrientation, isTrue);

      // Check rotation behavior
      expect(userMarker.rotationBehavior, equals(MarkerRotationBehavior.fixedUpright));
      expect(clusterMarker.rotationBehavior, equals(MarkerRotationBehavior.fixedUpright));
    });

    test('Marker rotation config', () {
      // Test configuration class
      const config = MarkerRotationConfig(
        enableRotationCorrection: true,
        maxRotationAngle: 90.0,
        animationDuration: Duration(milliseconds: 300),
      );

      final behavior = config.getBehaviorForType(MarkerType.user);
      expect(behavior, equals(MarkerRotationBehavior.fixedUpright));

      final modifiedConfig = config.copyWith(maxRotationAngle: 45.0);
      expect(modifiedConfig.maxRotationAngle, equals(45.0));
    });

    test('OSM map rotation tracking', () {
      // Test OSM rotation tracking functionality
      // This test verifies that OSM map rotation is properly tracked and converted

      // Simulate OSM map position with rotation in radians
      final double rotationRadians = math.pi / 4; // 45 degrees in radians
      const double expectedDegrees = 45.0;

      // Test rotation conversion (radians to degrees)
      final rotationDegrees = rotationRadians * 180.0 / math.pi;
      expect(rotationDegrees, closeTo(expectedDegrees, 0.1));

      // Test that markers are rotated correctly for OSM
      final markerRotation = MarkerRotationUtils.calculateFixedMarkerRotation(expectedDegrees);
      expect(markerRotation, equals(-expectedDegrees)); // Should be negative to stay upright
    });

    test('OSM marker layer rotation', () {
      // Test that OSM markers don't rotate with map (they should stay fixed)
      // In flutter_map, markers are automatically fixed and don't rotate with map

      final mockMarker = osm.Marker(
        width: 40.0,
        height: 40.0,
        point: osm_latlong.LatLng(41.2995, 69.2401), // Tashkent coordinates
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      );

      // Verify marker properties
      expect(mockMarker.width, equals(40.0));
      expect(mockMarker.height, equals(40.0));
      expect(mockMarker.point.latitude, closeTo(41.2995, 0.0001));
      expect(mockMarker.point.longitude, closeTo(69.2401, 0.0001));
    });

    test('OSM map options with rotation tracking', () {
      // Test that MapOptions can be configured with position change callback
      final mapOptions = osm.MapOptions(
        initialCenter: osm_latlong.LatLng(41.2995, 69.2401),
        initialZoom: 15.0,
        onPositionChanged: (position, hasGesture) {
          // This callback should handle rotation tracking
          if (position?.rotation != null) {
            final rotation = position!.rotation! * 180.0 / math.pi;
            // Rotation should be tracked here
            expect(rotation, isA<double>());
          }
        },
      );

      expect(mapOptions.initialCenter.latitude, closeTo(41.2995, 0.0001));
      expect(mapOptions.initialCenter.longitude, closeTo(69.2401, 0.0001));
      expect(mapOptions.initialZoom, equals(15.0));
      expect(mapOptions.onPositionChanged, isNotNull);
    });

    test('OSM tile layer configuration', () {
      // Test OSM tile layer setup for offline compatibility
      final tileLayer = osm.TileLayer(
        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        subdomains: const ['a', 'b', 'c'],
        userAgentPackageName: 'com.gloria.marketing.app',
        maxZoom: 19,
        minZoom: 1,
      );

      expect(tileLayer.urlTemplate, contains('openstreetmap.org'));
      expect(tileLayer.subdomains, contains('a'));
      expect(tileLayer.subdomains, contains('b'));
      expect(tileLayer.subdomains, contains('c'));
      expect(tileLayer.maxZoom, equals(19));
      expect(tileLayer.minZoom, equals(1));
    });
  });
}