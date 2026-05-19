import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/geofence_rule.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/visit_location.dart';

VisitLocation _fix({
  required double lat,
  required double lng,
  double accuracyM = 10,
  bool mocked = false,
}) =>
    VisitLocation(
      lat: lat,
      lng: lng,
      accuracyM: accuracyM,
      source: 'gps',
      mocked: mocked,
      providerTs: DateTime.utc(2026, 5, 16, 8, 0, 0),
    );

void main() {
  group('GeofenceRule.haversineM', () {
    test('identical points return 0', () {
      expect(GeofenceRule.haversineM(41.31, 69.27, 41.31, 69.27), 0);
    });

    test('~1km apart returns ~1000m', () {
      // ~1km north of the Tashkent reference point.
      final d = GeofenceRule.haversineM(41.31, 69.27, 41.319, 69.27);
      expect(d, inInclusiveRange(950, 1050));
    });
  });

  group('GeofenceRule.check', () {
    test('passes when accuracy and distance both within limits', () {
      final res = GeofenceRule.check(
        fix: _fix(lat: 41.31, lng: 69.27, accuracyM: 12),
        customerLat: 41.31,
        customerLng: 69.27,
        radiusM: 100,
        planned: true,
      );
      expect(res.ok, isTrue);
    });

    test('rejects mock location in release mode', () {
      final res = GeofenceRule.check(
        fix: _fix(lat: 41.31, lng: 69.27, mocked: true),
        customerLat: 41.31,
        customerLng: 69.27,
        radiusM: 100,
        planned: true,
      );
      expect(res.reason, 'mock_location');
    });

    test('allows mock when debug bypass is set', () {
      final res = GeofenceRule.check(
        fix: _fix(lat: 41.31, lng: 69.27, mocked: true),
        customerLat: 41.31,
        customerLng: 69.27,
        radiusM: 100,
        planned: true,
        allowMocked: true,
      );
      expect(res.ok, isTrue);
    });

    test('rejects wide GPS accuracy (>= radius/3 with floor 30)', () {
      final res = GeofenceRule.check(
        fix: _fix(lat: 41.31, lng: 69.27, accuracyM: 50),
        customerLat: 41.31,
        customerLng: 69.27,
        radiusM: 100,
        planned: true,
      );
      expect(res.reason, 'low_accuracy');
    });

    test('rejects when outside the radius for planned visits', () {
      final res = GeofenceRule.check(
        fix: _fix(lat: 41.32, lng: 69.27, accuracyM: 10),
        customerLat: 41.31,
        customerLng: 69.27,
        radiusM: 100,
        planned: true,
      );
      expect(res.reason, 'out_of_zone');
    });

    test('skips radius check for unplanned visits', () {
      final res = GeofenceRule.check(
        fix: _fix(lat: 41.40, lng: 69.30, accuracyM: 10),
        customerLat: 41.31,
        customerLng: 69.27,
        radiusM: 100,
        planned: false,
      );
      expect(res.ok, isTrue);
    });
  });
}
