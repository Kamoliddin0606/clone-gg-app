import 'package:geolocator/geolocator.dart';

import '../../domain/entities/visit_location.dart';

/// Adapter around `geolocator` that returns the [VisitLocation] envelope
/// shape directly and surfaces mock-location detection.
///
/// `Geolocator.isMockLocation` is Android-only; on iOS we always report
/// `mocked: false`. The visit start UI is responsible for rejecting mocked
/// fixes in release builds — this service just gathers the data.
class SecureLocationService {
  SecureLocationService({GeolocatorPlatform? geolocator})
      : _geolocator = geolocator ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _geolocator;

  /// Returns a fresh fix or throws [LocationUnavailable] if permission was
  /// denied or the device's location services are off.
  Future<VisitLocation> currentPosition({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final enabled = await _geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationUnavailable('location_services_disabled');
    }
    LocationPermission permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationUnavailable('permission_denied');
    }

    final position = await _geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: desiredAccuracy,
        timeLimit: timeout,
      ),
    );

    return VisitLocation(
      lat: position.latitude,
      lng: position.longitude,
      accuracyM: position.accuracy,
      altitudeM: position.altitude,
      headingDegrees: position.heading == 0.0 ? null : position.heading,
      speedMps: position.speed == 0.0 ? null : position.speed,
      source: 'gps',
      mocked: position.isMocked,
      providerTs: position.timestamp.toUtc(),
    );
  }
}

class LocationUnavailable implements Exception {
  const LocationUnavailable(this.reason);
  final String reason;

  @override
  String toString() => 'LocationUnavailable($reason)';
}
