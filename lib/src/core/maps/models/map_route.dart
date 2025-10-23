import 'package:equatable/equatable.dart';
import 'map_point.dart';

/// Route data structure for map navigation
class MapRoute extends Equatable {
  final String id;
  final List<MapPoint> points;
  final List<dynamic> coordinates; // Provider-specific coordinate format
  final double distance; // in kilometers
  final Duration estimatedTime;
  final TravelMode travelMode;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const MapRoute({
    required this.id,
    required this.points,
    required this.coordinates,
    required this.distance,
    required this.estimatedTime,
    required this.travelMode,
    this.metadata,
    required this.createdAt,
  });

  /// Create optimized route from points
  factory MapRoute.optimized({
    required String id,
    required List<MapPoint> points,
    required TravelMode mode,
    double? distance,
    Duration? estimatedTime,
  }) {
    // Calculate straight-line distance if not provided
    final calculatedDistance = distance ?? _calculateTotalDistance(points);
    final estimatedDuration = estimatedTime ?? _estimateDuration(calculatedDistance, mode);

    return MapRoute(
      id: id,
      points: points,
      coordinates: points.map((p) => [p.longitude, p.latitude]).toList(),
      distance: calculatedDistance,
      estimatedTime: estimatedDuration,
      travelMode: mode,
      createdAt: DateTime.now(),
    );
  }

  /// Calculate total distance for a list of points
  static double _calculateTotalDistance(List<MapPoint> points) {
    if (points.length < 2) return 0.0;

    double total = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      total += points[i].distanceTo(points[i + 1]);
    }
    return total;
  }

  /// Estimate travel time based on distance and mode
  static Duration _estimateDuration(double distanceKm, TravelMode mode) {
    const double walkingSpeedKmh = 5.0; // km/h
    const double drivingSpeedKmh = 40.0; // km/h average city speed
    const double cyclingSpeedKmh = 15.0; // km/h

    double speedKmh;
    switch (mode) {
      case TravelMode.walking:
        speedKmh = walkingSpeedKmh;
        break;
      case TravelMode.driving:
        speedKmh = drivingSpeedKmh;
        break;
      case TravelMode.cycling:
        speedKmh = cyclingSpeedKmh;
        break;
      case TravelMode.transit:
        // Transit is more complex, use driving speed as approximation
        speedKmh = drivingSpeedKmh * 0.8; // Account for stops
        break;
    }

    final hours = distanceKm / speedKmh;
    return Duration(minutes: (hours * 60).round());
  }

  /// Get formatted distance string
  String get formattedDistance {
    if (distance < 1) {
      return '${(distance * 1000).round()}m';
    } else if (distance < 10) {
      return '${distance.toStringAsFixed(1)}km';
    } else {
      return '${distance.round()}km';
    }
  }

  /// Get formatted time string
  String get formattedTime {
    final hours = estimatedTime.inHours;
    final minutes = estimatedTime.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Check if route is valid
  bool get isValid => points.length >= 2 && distance > 0;

  /// Get route bounds for map fitting
  Map<String, double> get bounds {
    if (points.isEmpty) {
      return {'north': 0, 'south': 0, 'east': 0, 'west': 0};
    }

    double north = points.first.latitude;
    double south = points.first.latitude;
    double east = points.first.longitude;
    double west = points.first.longitude;

    for (final point in points) {
      north = north > point.latitude ? north : point.latitude;
      south = south < point.latitude ? south : point.latitude;
      east = east > point.longitude ? east : point.longitude;
      west = west < point.longitude ? west : point.longitude;
    }

    return {
      'north': north,
      'south': south,
      'east': east,
      'west': west,
    };
  }

  @override
  List<Object?> get props => [id, points, distance, estimatedTime, travelMode];

  @override
  String toString() {
    return 'MapRoute(id: $id, points: ${points.length}, distance: $formattedDistance, time: $formattedTime, mode: $travelMode)';
  }
}

/// Route optimization criteria
enum RouteOptimization {
  shortestDistance,
  shortestTime,
  minimizeTurns,
  avoidHighways,
  preferMainRoads,
}

/// Route calculation options
class RouteOptions {
  final TravelMode travelMode;
  final bool avoidTolls;
  final bool avoidHighways;
  final bool preferMainRoads;
  final DateTime? departureTime;
  final RouteOptimization optimization;

  const RouteOptions({
    this.travelMode = TravelMode.driving,
    this.avoidTolls = false,
    this.avoidHighways = false,
    this.preferMainRoads = true,
    this.departureTime,
    this.optimization = RouteOptimization.shortestTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'travelMode': travelMode.toString(),
      'avoidTolls': avoidTolls,
      'avoidHighways': avoidHighways,
      'preferMainRoads': preferMainRoads,
      'departureTime': departureTime?.toIso8601String(),
      'optimization': optimization.toString(),
    };
  }
}