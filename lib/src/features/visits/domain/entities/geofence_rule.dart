import 'dart:math' as math;

import 'visit_location.dart';

/// Pure-function geofence checks used at visit start and finish.
///
/// All thresholds come from `PermissionThresholds`; this class doesn't read
/// settings on its own so it stays testable.
class GeofenceRule {
  const GeofenceRule._();

  /// Great-circle distance between two coordinates in metres.
  static double haversineM(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusM = 6371000.0;
    final dLat = _radians(lat2 - lat1);
    final dLng = _radians(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_radians(lat1)) *
            math.cos(_radians(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusM * c;
  }

  /// `true` when the fix is good enough to start a visit at [customerLat]/
  /// [customerLng]:
  /// * GPS accuracy ≤ `max(radiusM / 3, 30)` metres,
  /// * `mocked == false` unless [allowMocked] (debug builds),
  /// * distance ≤ [radiusM] when the visit is planned.
  ///
  /// Unplanned visits skip the distance check (radius doesn't apply) but
  /// still demand a usable fix.
  static GeofenceCheck check({
    required VisitLocation fix,
    required double customerLat,
    required double customerLng,
    required int radiusM,
    required bool planned,
    bool allowMocked = false,
  }) {
    if (fix.mocked && !allowMocked) {
      return const GeofenceCheck.failure('mock_location');
    }

    final accuracyThreshold = math.max(radiusM / 3, 30).toDouble();
    if (fix.accuracyM > accuracyThreshold) {
      return GeofenceCheck.failure(
        'low_accuracy',
        observedM: fix.accuracyM,
        requiredM: accuracyThreshold,
      );
    }

    if (planned && radiusM > 0) {
      final distance =
          haversineM(customerLat, customerLng, fix.lat, fix.lng);
      if (distance > radiusM) {
        return GeofenceCheck.failure(
          'out_of_zone',
          observedM: distance,
          requiredM: radiusM.toDouble(),
        );
      }
    }

    return const GeofenceCheck.success();
  }

  static double _radians(double degrees) => degrees * math.pi / 180.0;
}

/// Outcome of a [GeofenceRule.check] — `null` reason ⇒ pass.
class GeofenceCheck {
  const GeofenceCheck.success()
      : reason = null,
        observedM = null,
        requiredM = null;

  const GeofenceCheck.failure(this.reason, {this.observedM, this.requiredM});

  /// `'mock_location'`, `'low_accuracy'`, `'out_of_zone'`, or `null` for OK.
  final String? reason;
  final double? observedM;
  final double? requiredM;

  bool get ok => reason == null;
}
