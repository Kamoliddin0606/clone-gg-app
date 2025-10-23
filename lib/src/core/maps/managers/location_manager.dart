import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import '../models/map_point.dart';

/// Enhanced location manager with GPS, network positioning, and advanced features
class LocationManager {
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const double _defaultAccuracy = 10.0; // meters

  final LocationSettings _settings;

  LocationManager({
    LocationSettings? settings,
  }) : _settings = settings ?? LocationSettings();

  /// Stream of location updates
  Stream<LocationData> get locationStream => _locationStreamController.stream;
  final StreamController<LocationData> _locationStreamController = StreamController<LocationData>.broadcast();

  /// Stream of location status updates
  Stream<LocationStatus> get statusStream => _statusStreamController.stream;
  final StreamController<LocationStatus> _statusStreamController = StreamController<LocationStatus>.broadcast();

  StreamSubscription<geolocator.Position>? _positionSubscription;
  bool _isInitialized = false;
  LocationData? _lastKnownLocation;

  /// Initialize location services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check location permissions
      final permission = await _checkPermissions();
      if (!permission) {
        _statusStreamController.add(LocationStatus.permissionDenied);
        return;
      }

      // Check if location services are enabled
      final serviceEnabled = await _checkLocationServices();
      if (!serviceEnabled) {
        _statusStreamController.add(LocationStatus.servicesDisabled);
        return;
      }

      _isInitialized = true;
      _statusStreamController.add(LocationStatus.ready);

      if (kDebugMode) {
        print('Location manager initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing location manager: $e');
      }
      _statusStreamController.add(LocationStatus.error);
      rethrow;
    }
  }

  /// Get current location with high accuracy
  Future<LocationData?> getCurrentLocation({
    Duration? timeout,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    await _ensureInitialized();

    try {
      final position = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: _convertAccuracy(accuracy),
        timeLimit: timeout ?? _defaultTimeout,
      );

      final locationData = LocationData.fromPosition(position);
      _lastKnownLocation = locationData;

      _locationStreamController.add(locationData);
      _statusStreamController.add(LocationStatus.active);

      return locationData;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current location: $e');
      }
      _statusStreamController.add(LocationStatus.error);
      return _lastKnownLocation; // Return last known location as fallback
    }
  }

  /// Start continuous location updates
  Future<void> startLocationUpdates({
    Duration interval = const Duration(seconds: 5),
    double distanceFilter = 5.0, // meters
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    await _ensureInitialized();

    try {
      // Stop existing subscription
      await stopLocationUpdates();

      _positionSubscription = geolocator.Geolocator.getPositionStream(
        locationSettings: geolocator.LocationSettings(
          accuracy: _convertAccuracy(accuracy),
          distanceFilter: distanceFilter.toInt(),
        ),
      ).listen(
        (geolocator.Position position) {
          final locationData = LocationData.fromPosition(position);
          _lastKnownLocation = locationData;

          _locationStreamController.add(locationData);
          _statusStreamController.add(LocationStatus.active);
        },
        onError: (error) {
          if (kDebugMode) {
            print('Location stream error: $error');
          }
          _statusStreamController.add(LocationStatus.error);
        },
      );

      _statusStreamController.add(LocationStatus.updating);

      if (kDebugMode) {
        print('Started location updates with interval: ${interval.inSeconds}s');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting location updates: $e');
      }
      _statusStreamController.add(LocationStatus.error);
      rethrow;
    }
  }

  /// Stop location updates
  Future<void> stopLocationUpdates() async {
    try {
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      _statusStreamController.add(LocationStatus.ready);

      if (kDebugMode) {
        print('Stopped location updates');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping location updates: $e');
      }
    }
  }

  /// Get last known location
  LocationData? getLastKnownLocation() {
    return _lastKnownLocation;
  }

  /// Calculate distance between two points
  double calculateDistance(MapPoint from, MapPoint to) {
    return from.distanceTo(to);
  }

  /// Calculate bearing between two points
  double calculateBearing(MapPoint from, MapPoint to) {
    final lat1 = from.latitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final deltaLng = (to.longitude - from.longitude) * pi / 180;

    final y = sin(deltaLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLng);

    final bearing = atan2(y, x);
    return (bearing * 180 / pi + 360) % 360; // Convert to degrees (0-360)
  }

  /// Check if location is within region
  bool isLocationInRegion(MapPoint location, LocationRegion region) {
    switch (region.type) {
      case RegionType.circle:
        return calculateDistance(location, region.center) <= (region.radius ?? 0.0);
      case RegionType.rectangle:
        return location.latitude >= region.bounds!['south']! &&
               location.latitude <= region.bounds!['north']! &&
               location.longitude >= region.bounds!['west']! &&
               location.longitude <= region.bounds!['east']!;
      case RegionType.polygon:
        return _isPointInPolygon(location, region.polygonPoints!);
    }
  }

  /// Monitor geofence regions
  Stream<GeofenceEvent> monitorGeofences(List<LocationRegion> regions) async* {
    await _ensureInitialized();

    LocationData? previousLocation;

    await for (final locationData in locationStream) {
      for (final region in regions) {
        final isInside = isLocationInRegion(locationData.toMapPoint(), region);
        final wasInside = previousLocation != null &&
                         isLocationInRegion(previousLocation.toMapPoint(), region);

        if (isInside && !wasInside) {
          yield GeofenceEvent.entered(region, locationData);
        } else if (!isInside && wasInside) {
          yield GeofenceEvent.exited(region, locationData);
        }
      }

      previousLocation = locationData;
    }
  }

  /// Get location accuracy information
  Future<LocationAccuracyInfo> getAccuracyInfo() async {
    await _ensureInitialized();

    try {
      final position = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: _convertAccuracy(LocationAccuracy.best),
        timeLimit: _defaultTimeout,
      );

      return LocationAccuracyInfo(
        accuracy: position.accuracy,
        altitudeAccuracy: position.altitudeAccuracy,
        headingAccuracy: position.headingAccuracy,
        speedAccuracy: position.speedAccuracy,
        timestamp: position.timestamp,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting accuracy info: $e');
      }
      return LocationAccuracyInfo.empty();
    }
  }

  /// Request location permissions
  Future<bool> requestPermissions() async {
    try {
      final permission = await geolocator.Geolocator.requestPermission();

      final granted = permission == geolocator.LocationPermission.always ||
                       permission == geolocator.LocationPermission.whileInUse;

      if (granted) {
        _statusStreamController.add(LocationStatus.ready);
      } else {
        _statusStreamController.add(LocationStatus.permissionDenied);
      }

      return granted;
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting permissions: $e');
      }
      _statusStreamController.add(LocationStatus.error);
      return false;
    }
  }

  /// Check location permissions
  Future<bool> _checkPermissions() async {
    try {
      final permission = await geolocator.Geolocator.checkPermission();
      return permission == geolocator.LocationPermission.always ||
             permission == geolocator.LocationPermission.whileInUse;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking permissions: $e');
      }
      return false;
    }
  }

  /// Check if location services are enabled
  Future<bool> _checkLocationServices() async {
    try {
      return await geolocator.Geolocator.isLocationServiceEnabled();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking location services: $e');
      }
      return false;
    }
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    try {
      return await geolocator.Geolocator.openLocationSettings();
    } catch (e) {
      if (kDebugMode) {
        print('Error opening location settings: $e');
      }
      return false;
    }
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    try {
      return await geolocator.Geolocator.openAppSettings();
    } catch (e) {
      if (kDebugMode) {
        print('Error opening app settings: $e');
      }
      return false;
    }
  }

  /// Get location service status
  Future<LocationServiceStatus> getServiceStatus() async {
    try {
      final permissionsGranted = await _checkPermissions();
      final servicesEnabled = await _checkLocationServices();

      return LocationServiceStatus(
        permissionsGranted: permissionsGranted,
        servicesEnabled: servicesEnabled,
        isInitialized: _isInitialized,
        hasLastLocation: _lastKnownLocation != null,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting service status: $e');
      }
      return LocationServiceStatus.empty();
    }
  }

  /// Calculate estimated arrival time
  Duration calculateETA(MapPoint current, MapPoint destination, double speedKmh) {
    final distance = calculateDistance(current, destination);
    final hours = distance / speedKmh;
    return Duration(minutes: (hours * 60).round());
  }

  /// Get compass heading to destination
  double getHeadingToDestination(MapPoint current, MapPoint destination) {
    return calculateBearing(current, destination);
  }

  /// Check if point is inside polygon (ray casting algorithm)
  bool _isPointInPolygon(MapPoint point, List<MapPoint> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final pi = polygon[i];
      final pj = polygon[j];

      if (((pi.latitude > point.latitude) != (pj.latitude > point.latitude)) &&
          (point.longitude < (pj.longitude - pi.longitude) * (point.latitude - pi.latitude) /
          (pj.latitude - pi.latitude) + pi.longitude)) {
        inside = !inside;
      }

      j = i;
    }

    return inside;
  }

  /// Convert custom accuracy to Geolocator accuracy
  geolocator.LocationAccuracy _convertAccuracy(LocationAccuracy accuracy) {
    switch (accuracy) {
      case LocationAccuracy.lowest:
        return geolocator.LocationAccuracy.lowest;
      case LocationAccuracy.low:
        return geolocator.LocationAccuracy.low;
      case LocationAccuracy.medium:
        return geolocator.LocationAccuracy.medium;
      case LocationAccuracy.high:
        return geolocator.LocationAccuracy.high;
      case LocationAccuracy.best:
        return geolocator.LocationAccuracy.best;
      case LocationAccuracy.bestForNavigation:
        return geolocator.LocationAccuracy.bestForNavigation;
    }
  }

  /// Ensure manager is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Dispose resources
  void dispose() {
    stopLocationUpdates();
    _locationStreamController.close();
    _statusStreamController.close();
  }
}

/// Location data wrapper
class LocationData {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? heading;
  final double? speed;
  final DateTime? timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.heading,
    this.speed,
    this.timestamp,
  });

  factory LocationData.fromPosition(geolocator.Position position) {
    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      heading: position.heading,
      speed: position.speed,
      timestamp: position.timestamp,
    );
  }

  MapPoint toMapPoint() {
    return MapPoint(
      id: 'location_${timestamp?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}',
      latitude: latitude,
      longitude: longitude,
      title: 'Current Location',
    );
  }

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, acc: ${accuracy?.toStringAsFixed(1)}m)';
  }
}

/// Location status enum
enum LocationStatus {
  uninitialized,
  ready,
  active,
  updating,
  permissionDenied,
  servicesDisabled,
  error,
}

/// Location accuracy enum
enum LocationAccuracy {
  lowest,
  low,
  medium,
  high,
  best,
  bestForNavigation,
}

/// Location region for geofencing
class LocationRegion {
  final String id;
  final String name;
  final RegionType type;
  final MapPoint center;
  final double? radius; // For circle regions
  final Map<String, double>? bounds; // For rectangle regions: north, south, east, west
  final List<MapPoint>? polygonPoints; // For polygon regions

  LocationRegion.circle({
    required this.id,
    required this.name,
    required this.center,
    required this.radius,
  }) : type = RegionType.circle,
       bounds = null,
       polygonPoints = null;

  LocationRegion.rectangle({
    required this.id,
    required this.name,
    required double north,
    required double south,
    required double east,
    required double west,
  }) : type = RegionType.rectangle,
       center = MapPoint(id: '${id}_center', latitude: (north + south) / 2, longitude: (east + west) / 2),
       radius = null,
       bounds = {'north': north, 'south': south, 'east': east, 'west': west},
       polygonPoints = null;

  LocationRegion.polygon({
    required this.id,
    required this.name,
    required this.polygonPoints,
  }) : type = RegionType.polygon,
       center = _calculatePolygonCenter(polygonPoints ?? []),
       radius = null,
       bounds = null;

  static MapPoint _calculatePolygonCenter(List<MapPoint> points) {
    double latSum = 0;
    double lngSum = 0;

    for (final point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }

    return MapPoint(
      id: 'polygon_center',
      latitude: latSum / points.length,
      longitude: lngSum / points.length,
    );
  }
}

/// Region type enum
enum RegionType {
  circle,
  rectangle,
  polygon,
}

/// Geofence event
class GeofenceEvent {
  final GeofenceEventType type;
  final LocationRegion region;
  final LocationData location;

  GeofenceEvent._(this.type, this.region, this.location);

  factory GeofenceEvent.entered(LocationRegion region, LocationData location) {
    return GeofenceEvent._(GeofenceEventType.entered, region, location);
  }

  factory GeofenceEvent.exited(LocationRegion region, LocationData location) {
    return GeofenceEvent._(GeofenceEventType.exited, region, location);
  }

  @override
  String toString() {
    return 'GeofenceEvent(type: $type, region: ${region.name}, location: $location)';
  }
}

/// Geofence event type
enum GeofenceEventType {
  entered,
  exited,
}

/// Location accuracy information
class LocationAccuracyInfo {
  final double? accuracy;
  final double? altitudeAccuracy;
  final double? headingAccuracy;
  final double? speedAccuracy;
  final DateTime? timestamp;

  LocationAccuracyInfo({
    this.accuracy,
    this.altitudeAccuracy,
    this.headingAccuracy,
    this.speedAccuracy,
    this.timestamp,
  });

  factory LocationAccuracyInfo.empty() {
    return LocationAccuracyInfo();
  }

  @override
  String toString() {
    return 'LocationAccuracyInfo(acc: ${accuracy?.toStringAsFixed(1)}m, alt_acc: ${altitudeAccuracy?.toStringAsFixed(1)}m)';
  }
}

/// Location service status
class LocationServiceStatus {
  final bool permissionsGranted;
  final bool servicesEnabled;
  final bool isInitialized;
  final bool hasLastLocation;

  LocationServiceStatus({
    required this.permissionsGranted,
    required this.servicesEnabled,
    required this.isInitialized,
    required this.hasLastLocation,
  });

  factory LocationServiceStatus.empty() {
    return LocationServiceStatus(
      permissionsGranted: false,
      servicesEnabled: false,
      isInitialized: false,
      hasLastLocation: false,
    );
  }

  bool get isReady => permissionsGranted && servicesEnabled && isInitialized;

  @override
  String toString() {
    return 'LocationServiceStatus(ready: $isReady, permissions: $permissionsGranted, services: $servicesEnabled)';
  }
}

/// Location settings
class LocationSettings {
  final Duration updateInterval;
  final double distanceFilter;
  final LocationAccuracy accuracy;
  final Duration timeout;
  final bool enableBackgroundUpdates;

  const LocationSettings({
    this.updateInterval = const Duration(seconds: 5),
    this.distanceFilter = 5.0,
    this.accuracy = LocationAccuracy.high,
    this.timeout = const Duration(seconds: 30),
    this.enableBackgroundUpdates = false,
  });

  LocationSettings copyWith({
    Duration? updateInterval,
    double? distanceFilter,
    LocationAccuracy? accuracy,
    Duration? timeout,
    bool? enableBackgroundUpdates,
  }) {
    return LocationSettings(
      updateInterval: updateInterval ?? this.updateInterval,
      distanceFilter: distanceFilter ?? this.distanceFilter,
      accuracy: accuracy ?? this.accuracy,
      timeout: timeout ?? this.timeout,
      enableBackgroundUpdates: enableBackgroundUpdates ?? this.enableBackgroundUpdates,
    );
  }
}