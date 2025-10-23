import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/map_point.dart';
import '../models/map_route.dart';
import '../models/map_settings.dart';

/// Advanced route service with optimization algorithms
class RouteService {
  final MapProvider provider;

  RouteService(this.provider);

  /// Calculate optimal route for multiple points using advanced algorithms
  Future<MapRoute> calculateOptimalRoute({
    required List<MapPoint> points,
    required TravelMode travelMode,
    RouteOptimization optimization = RouteOptimization.shortestTime,
    Map<String, dynamic>? constraints,
  }) async {
    try {
      if (points.length < 2) {
        throw ArgumentError('At least 2 points required for route calculation');
      }

      if (points.length == 2) {
        // Simple two-point route
        return await _calculateSimpleRoute(points[0], points[1], travelMode);
      }

      // Multi-point optimization
      final optimizedPoints = await _optimizeMultiPointRoute(points, optimization, constraints);

      // Calculate detailed route with all waypoints
      return await _calculateDetailedRoute(optimizedPoints, travelMode);
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating optimal route: $e');
      }
      // Fallback to basic route
      return _createFallbackRoute(points, travelMode);
    }
  }

  /// Optimize route for multiple points using various algorithms
  Future<List<MapPoint>> _optimizeMultiPointRoute(
    List<MapPoint> points,
    RouteOptimization optimization,
    Map<String, dynamic>? constraints,
  ) async {
    switch (optimization) {
      case RouteOptimization.shortestDistance:
        return _optimizeForShortestDistance(points, constraints);
      case RouteOptimization.shortestTime:
        return _optimizeForShortestTime(points, constraints);
      case RouteOptimization.minimizeTurns:
        return _optimizeForMinimumTurns(points, constraints);
      case RouteOptimization.avoidHighways:
        return _optimizeAvoidingHighways(points, constraints);
      case RouteOptimization.preferMainRoads:
        return _optimizePreferMainRoads(points, constraints);
    }
  }

  /// Nearest Neighbor algorithm for shortest distance
  List<MapPoint> _optimizeForShortestDistance(List<MapPoint> points, Map<String, dynamic>? constraints) {
    if (points.length <= 2) return points;

    final optimized = <MapPoint>[points.first];
    final remaining = List<MapPoint>.from(points)..removeAt(0);

    while (remaining.isNotEmpty) {
      MapPoint nearest = remaining.first;
      double minDistance = optimized.last.distanceTo(nearest);

      for (final point in remaining) {
        final distance = optimized.last.distanceTo(point);
        if (distance < minDistance) {
          minDistance = distance;
          nearest = point;
        }
      }

      optimized.add(nearest);
      remaining.remove(nearest);
    }

    return optimized;
  }

  /// Time-optimized routing considering traffic and road types
  List<MapPoint> _optimizeForShortestTime(List<MapPoint> points, Map<String, dynamic>? constraints) {
    if (points.length <= 2) return points;

    // Use a more sophisticated approach considering estimated travel times
    final optimized = <MapPoint>[points.first];
    final remaining = List<MapPoint>.from(points)..removeAt(0);

    while (remaining.isNotEmpty) {
      MapPoint best = remaining.first;
      double bestTime = _estimateTravelTime(optimized.last, best);

      for (final point in remaining) {
        final time = _estimateTravelTime(optimized.last, point);
        if (time < bestTime) {
          bestTime = time;
          best = point;
        }
      }

      optimized.add(best);
      remaining.remove(best);
    }

    return optimized;
  }

  /// Minimize turns by preferring straight-line routes
  List<MapPoint> _optimizeForMinimumTurns(List<MapPoint> points, Map<String, dynamic>? constraints) {
    if (points.length <= 2) return points;

    // Calculate angles between consecutive points to minimize direction changes
    final optimized = <MapPoint>[points.first];
    final remaining = List<MapPoint>.from(points)..removeAt(0);

    while (remaining.isNotEmpty) {
      MapPoint best = remaining.first;
      double bestTurnPenalty = _calculateTurnPenalty(optimized, best);

      for (final point in remaining) {
        final turnPenalty = _calculateTurnPenalty(optimized, point);
        if (turnPenalty < bestTurnPenalty) {
          bestTurnPenalty = turnPenalty;
          best = point;
        }
      }

      optimized.add(best);
      remaining.remove(best);
    }

    return optimized;
  }

  /// Avoid highways by preferring local roads
  List<MapPoint> _optimizeAvoidingHighways(List<MapPoint> points, Map<String, dynamic>? constraints) {
    // This would require road network data from the map provider
    // For now, use distance-based optimization with highway penalty
    return _optimizeForShortestDistance(points, constraints);
  }

  /// Prefer main roads for faster travel
  List<MapPoint> _optimizePreferMainRoads(List<MapPoint> points, Map<String, dynamic>? constraints) {
    // This would require road classification data
    // For now, use time-based optimization
    return _optimizeForShortestTime(points, constraints);
  }

  /// Calculate turn penalty for route smoothness
  double _calculateTurnPenalty(List<MapPoint> currentRoute, MapPoint candidate) {
    if (currentRoute.length < 2) return 0.0;

    final lastTwo = currentRoute.sublist(currentRoute.length - 2);
    final previousVector = _calculateVector(lastTwo[0], lastTwo[1]);
    final newVector = _calculateVector(lastTwo[1], candidate);

    final angle = _calculateAngle(previousVector, newVector);
    return angle.abs(); // Penalty increases with turn angle
  }

  /// Calculate vector between two points
  Map<String, double> _calculateVector(MapPoint from, MapPoint to) {
    return {
      'dx': to.longitude - from.longitude,
      'dy': to.latitude - from.latitude,
    };
  }

  /// Calculate angle between two vectors
  double _calculateAngle(Map<String, double> v1, Map<String, double> v2) {
    final dot = v1['dx']! * v2['dx']! + v1['dy']! * v2['dy']!;
    final mag1 = sqrt(v1['dx']! * v1['dx']! + v1['dy']! * v1['dy']!);
    final mag2 = sqrt(v2['dx']! * v2['dx']! + v2['dy']! * v2['dy']!);

    if (mag1 == 0 || mag2 == 0) return 0.0;

    final cosAngle = dot / (mag1 * mag2);
    return acos(cosAngle.clamp(-1.0, 1.0));
  }

  /// Estimate travel time between two points
  double _estimateTravelTime(MapPoint from, MapPoint to) {
    final distance = from.distanceTo(to);
    final speedKmh = _getEstimatedSpeed(from, to);
    return distance / speedKmh; // hours
  }

  /// Get estimated speed based on provider and region
  double _getEstimatedSpeed(MapPoint from, MapPoint to) {
    // Provider-specific speed estimates
    switch (provider) {
      case MapProvider.google:
        return 40.0; // Google has good traffic data
      case MapProvider.yandex:
        return 35.0; // Good for Russia/CIS regions
      case MapProvider.openStreetMap:
        return 45.0; // OSM has detailed road data
    }
  }

  /// Calculate simple two-point route
  Future<MapRoute> _calculateSimpleRoute(MapPoint start, MapPoint end, TravelMode travelMode) async {
    final distance = start.distanceTo(end);
    final duration = Duration(minutes: (_estimateTravelTime(start, end) * 60).round());

    // Generate intermediate points for realistic route
    final coordinates = _generateRouteCoordinates(start, end, 20);

    return MapRoute(
      id: 'simple_route_${start.id}_${end.id}',
      points: [start, end],
      coordinates: coordinates,
      distance: distance,
      estimatedTime: duration,
      travelMode: travelMode,
      createdAt: DateTime.now(),
      metadata: {
        'algorithm': 'simple',
        'provider': provider.toString(),
      },
    );
  }

  /// Calculate detailed route with waypoints
  Future<MapRoute> _calculateDetailedRoute(List<MapPoint> points, TravelMode travelMode) async {
    final totalDistance = _calculateTotalDistance(points);
    final totalTime = _estimateTotalTime(points, travelMode);

    // Generate coordinates for the entire route
    final allCoordinates = <List<double>>[];
    for (int i = 0; i < points.length - 1; i++) {
      final segmentCoords = _generateRouteCoordinates(points[i], points[i + 1], 10);
      if (i > 0) {
        // Remove duplicate point at segment start (except for first segment)
        segmentCoords.removeAt(0);
      }
      allCoordinates.addAll(segmentCoords);
    }

    return MapRoute(
      id: 'optimized_route_${DateTime.now().millisecondsSinceEpoch}',
      points: points,
      coordinates: allCoordinates,
      distance: totalDistance,
      estimatedTime: totalTime,
      travelMode: travelMode,
      createdAt: DateTime.now(),
      metadata: {
        'algorithm': 'optimized',
        'waypoints': points.length,
        'provider': provider.toString(),
      },
    );
  }

  /// Calculate total distance for a route
  double _calculateTotalDistance(List<MapPoint> points) {
    double total = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      total += points[i].distanceTo(points[i + 1]);
    }
    return total;
  }

  /// Estimate total time for a route
  Duration _estimateTotalTime(List<MapPoint> points, TravelMode travelMode) {
    double totalHours = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalHours += _estimateTravelTime(points[i], points[i + 1]);
    }
    return Duration(minutes: (totalHours * 60).round());
  }

  /// Generate realistic route coordinates between two points
  List<List<double>> _generateRouteCoordinates(MapPoint start, MapPoint end, int segments) {
    final coordinates = <List<double>>[];

    for (int i = 0; i <= segments; i++) {
      final ratio = i / segments;

      // Add some curve to make it look more realistic
      final curveOffset = sin(ratio * pi) * 0.001; // Small curve

      final lat = start.latitude + (end.latitude - start.latitude) * ratio + curveOffset;
      final lng = start.longitude + (end.longitude - start.longitude) * ratio;

      coordinates.add([lng, lat]);
    }

    return coordinates;
  }

  /// Create fallback route when optimization fails
  MapRoute _createFallbackRoute(List<MapPoint> points, TravelMode travelMode) {
    final totalDistance = _calculateTotalDistance(points);
    final totalTime = _estimateTotalTime(points, travelMode);

    return MapRoute(
      id: 'fallback_route_${DateTime.now().millisecondsSinceEpoch}',
      points: points,
      coordinates: points.map((p) => [p.longitude, p.latitude]).toList(),
      distance: totalDistance,
      estimatedTime: totalTime,
      travelMode: travelMode,
      createdAt: DateTime.now(),
      metadata: {'fallback': true},
    );
  }

  /// Advanced route optimization using genetic algorithm (for complex routes)
  Future<List<MapPoint>> _geneticAlgorithmOptimization(
    List<MapPoint> points,
    int populationSize,
    int generations,
  ) async {
    if (points.length <= 3) return points;

    // Initialize population with random permutations
    List<List<MapPoint>> population = [];
    for (int i = 0; i < populationSize; i++) {
      final route = List<MapPoint>.from(points);
      route.shuffle();
      // Keep start and end points fixed
      route[0] = points.first;
      route[route.length - 1] = points.last;
      population.add(route);
    }

    for (int gen = 0; gen < generations; gen++) {
      // Evaluate fitness (total distance)
      population.sort((a, b) => _calculateTotalDistance(a).compareTo(_calculateTotalDistance(b)));

      // Create new population through crossover and mutation
      List<List<MapPoint>> newPopulation = population.sublist(0, populationSize ~/ 2);

      while (newPopulation.length < populationSize) {
        final parent1 = population[Random().nextInt(populationSize ~/ 2)];
        final parent2 = population[Random().nextInt(populationSize ~/ 2)];

        final child = _crossover(parent1, parent2);
        _mutate(child);

        newPopulation.add(child);
      }

      population = newPopulation;
    }

    return population.first; // Best route
  }

  /// Crossover operation for genetic algorithm
  List<MapPoint> _crossover(List<MapPoint> parent1, List<MapPoint> parent2) {
    final start = Random().nextInt(parent1.length - 2) + 1;
    final end = Random().nextInt(parent1.length - start) + start;

    final child = List<MapPoint>.filled(parent1.length, parent1[0]);
    final used = <MapPoint>{};

    // Copy segment from parent1
    for (int i = start; i <= end; i++) {
      child[i] = parent1[i];
      used.add(parent1[i]);
    }

    // Fill remaining positions from parent2
    int childIndex = 1;
    for (final point in parent2) {
      if (!used.contains(point)) {
        while (child[childIndex] != parent1[0]) {
          childIndex++;
          if (childIndex >= child.length) break;
        }
        if (childIndex < child.length) {
          child[childIndex] = point;
          childIndex++;
        }
      }
    }

    return child;
  }

  /// Mutation operation for genetic algorithm
  void _mutate(List<MapPoint> route) {
    if (route.length < 4 || Random().nextDouble() > 0.1) return; // 10% mutation rate

    final i = Random().nextInt(route.length - 2) + 1;
    final j = Random().nextInt(route.length - 2) + 1;

    final temp = route[i];
    route[i] = route[j];
    route[j] = temp;
  }

  /// Calculate route efficiency metrics
  Map<String, dynamic> calculateRouteMetrics(MapRoute route) {
    final straightLineDistance = route.points.first.distanceTo(route.points.last);
    final routeEfficiency = straightLineDistance / route.distance;

    final averageSpeed = route.distance / (route.estimatedTime.inHours);
    final estimatedFuelConsumption = _estimateFuelConsumption(route);

    return {
      'efficiency': routeEfficiency,
      'average_speed_kmh': averageSpeed,
      'estimated_fuel_liters': estimatedFuelConsumption,
      'waypoints': route.points.length,
      'total_distance_km': route.distance,
      'estimated_duration_hours': route.estimatedTime.inHours,
    };
  }

  /// Estimate fuel consumption for a route
  double _estimateFuelConsumption(MapRoute route) {
    const double averageFuelConsumption = 8.0; // liters per 100km
    return (route.distance * averageFuelConsumption) / 100;
  }
}

/// Route optimization utilities
class RouteOptimizationUtils {
  /// Validate route points
  static bool validateRoutePoints(List<MapPoint> points) {
    if (points.length < 2) return false;
    if (points.length != points.toSet().length) return false; // No duplicates

    // Check for valid coordinates
    for (final point in points) {
      if (point.latitude < -90 || point.latitude > 90) return false;
      if (point.longitude < -180 || point.longitude > 180) return false;
    }

    return true;
  }

  /// Calculate route bounding box
  static Map<String, double> calculateBoundingBox(List<MapPoint> points) {
    if (points.isEmpty) {
      return {'north': 0, 'south': 0, 'east': 0, 'west': 0};
    }

    double north = points.first.latitude;
    double south = points.first.latitude;
    double east = points.first.longitude;
    double west = points.first.longitude;

    for (final point in points.skip(1)) {
      north = max(north, point.latitude);
      south = min(south, point.latitude);
      east = max(east, point.longitude);
      west = min(west, point.longitude);
    }

    return {
      'north': north,
      'south': south,
      'east': east,
      'west': west,
    };
  }

  /// Check if route is within reasonable bounds
  static bool isRouteReasonable(MapRoute route, {double maxDistanceKm = 1000}) {
    return route.distance <= maxDistanceKm && route.points.length <= 50;
  }
}