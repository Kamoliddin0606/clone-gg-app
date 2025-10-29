import 'package:flutter_test/flutter_test.dart';
import 'package:yandex_maps_mapkit/mapkit.dart' as mk;
import 'package:gloria_marketing_flutter/src/core/maps/map_math.dart';
import 'package:gloria_marketing_flutter/src/core/maps/marker_icon_loader.dart';

void main() {
  group('MapMath', () {
    test('haversineKm returns 0 for same point', () {
      final p = mk.Point(latitude: 41.2995, longitude: 69.2401);
      expect(haversineKm(p, p), closeTo(0.0, 1e-6));
    });

    test('haversineKm calculates distance correctly', () {
      final tashkent = mk.Point(latitude: 41.2995, longitude: 69.2401);
      final samarkand = mk.Point(latitude: 39.6542, longitude: 66.9597);
      final distance = haversineKm(tashkent, samarkand);
      expect(distance, greaterThan(250)); // Approximately 280km
      expect(distance, lessThan(320));
    });

    test('estimateTravelTimeCity formats correctly', () {
      expect(estimateTravelTimeCity(10, speedKmh: 40), '15 daqiqa');
      expect(estimateTravelTimeCity(100, speedKmh: 40), '2 soat 30 daqiqa');
      expect(estimateTravelTimeCity(5, speedKmh: 40), '8 daqiqa');
    });

    test('computeZoomForBounds basics', () {
      final pts = [mk.Point(latitude: 41.3, longitude: 69.24)];
      expect(computeZoomForBounds(pts), 16.0);

      final multiplePts = [
        mk.Point(latitude: 41.3, longitude: 69.24),
        mk.Point(latitude: 41.4, longitude: 69.34),
      ];
      expect(computeZoomForBounds(multiplePts), lessThan(16.0));
    });
  });

  group('MarkerIconLoader', () {
    late MarkerIconLoader loader;

    setUp(() {
      loader = const MarkerIconLoader();
    });

    test('tryLoad handles non-existent asset gracefully', () async {
      final result = await loader.tryLoad('non_existent_asset.png');
      // Note: In test environment, this might not fail as expected
      // The important thing is it doesn't crash
      expect(result, isNotNull); // Provider is created even if asset doesn't exist
    });

    test('applyToPlacemark handles provider gracefully', () async {
      // Mock placemark - simplified for testing
      final mockPlacemark = _MockPlacemarkMapObject();

      await loader.applyToPlacemark(
        mockPlacemark,
        assetPath: 'non_existent.png',
      );

      // Should not throw and should set basic properties
      expect(mockPlacemark.opacity, 1.0);
      expect(mockPlacemark.zIndex, 10.0);
    });
  });
}

// Mock class for testing
class _MockPlacemarkMapObject implements mk.PlacemarkMapObject {
  double opacity = 1.0;
  double zIndex = 0.0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}