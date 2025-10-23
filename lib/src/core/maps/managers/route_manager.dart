import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/map_route.dart';
import '../models/map_point.dart';
import '../models/map_settings.dart';
import '../services/route_service.dart' as route_service;
import '../services/map_service.dart' as map_service;

/// Centralized route management system
class RouteManager {
  final route_service.RouteService _routeService;
  final map_service.MapService _mapService;
  final MapProvider _provider;

  RouteManager({
    required route_service.RouteService routeService,
    required map_service.MapService mapService,
    required MapProvider provider,
  }) : _routeService = routeService,
       _mapService = mapService,
       _provider = provider;

  /// Active routes being managed
  final Map<String, MapRoute> _activeRoutes = {};

  /// Route event listeners
  final StreamController<RouteEvent> _routeEvents = StreamController<RouteEvent>.broadcast();

  /// Stream of route events
  Stream<RouteEvent> get routeEvents => _routeEvents.stream;

  /// Calculate and display a new route
  Future<MapRoute?> createRoute({
    required List<MapPoint> points,
    required TravelMode travelMode,
    RouteOptimization optimization = RouteOptimization.shortestTime,
    Map<String, dynamic>? constraints,
    bool displayOnMap = true,
  }) async {
    try {
      if (kDebugMode) {
        print('Creating route with ${points.length} points');
      }

      // Calculate optimal route
      final route = await _routeService.calculateOptimalRoute(
        points: points,
        travelMode: travelMode,
        optimization: optimization,
        constraints: constraints,
      );

      if (route != null) {
        // Add to active routes
        _activeRoutes[route.id] = route;

        // Display on map if requested
        if (displayOnMap) {
          await _displayRouteOnMap(route);
        }

        // Emit route created event
        _routeEvents.add(RouteEvent.created(route));

        if (kDebugMode) {
          print('Route created successfully: ${route.id}');
        }
      }

      return route;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating route: $e');
      }
      _routeEvents.add(RouteEvent.error('Failed to create route: $e'));
      return null;
    }
  }

  /// Update existing route
  Future<MapRoute?> updateRoute({
    required String routeId,
    List<MapPoint>? newPoints,
    TravelMode? newTravelMode,
    RouteOptimization? newOptimization,
    Map<String, dynamic>? newConstraints,
  }) async {
    try {
      final existingRoute = _activeRoutes[routeId];
      if (existingRoute == null) {
        throw ArgumentError('Route not found: $routeId');
      }

      // Remove old route from map
      await _removeRouteFromMap(routeId);

      // Calculate new route
      final updatedRoute = await _routeService.calculateOptimalRoute(
        points: newPoints ?? existingRoute.points,
        travelMode: newTravelMode ?? existingRoute.travelMode,
        optimization: newOptimization ?? RouteOptimization.shortestTime,
        constraints: newConstraints,
      );

      if (updatedRoute != null) {
        // Update active routes
        _activeRoutes[routeId] = updatedRoute;

        // Display updated route
        await _displayRouteOnMap(updatedRoute);

        // Emit route updated event
        _routeEvents.add(RouteEvent.updated(updatedRoute));

        if (kDebugMode) {
          print('Route updated successfully: $routeId');
        }
      }

      return updatedRoute;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating route: $e');
      }
      _routeEvents.add(RouteEvent.error('Failed to update route: $e'));
      return null;
    }
  }

  /// Remove route
  Future<void> removeRoute(String routeId) async {
    try {
      if (!_activeRoutes.containsKey(routeId)) {
        return;
      }

      // Remove from map
      await _removeRouteFromMap(routeId);

      // Remove from active routes
      final route = _activeRoutes.remove(routeId);

      // Emit route removed event
      if (route != null) {
        _routeEvents.add(RouteEvent.removed(route));
      }

      if (kDebugMode) {
        print('Route removed: $routeId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error removing route: $e');
      }
      _routeEvents.add(RouteEvent.error('Failed to remove route: $e'));
    }
  }

  /// Clear all routes
  Future<void> clearAllRoutes() async {
    try {
      final routeIds = _activeRoutes.keys.toList();

      for (final routeId in routeIds) {
        await _removeRouteFromMap(routeId);
      }

      _activeRoutes.clear();

      // Emit routes cleared event
      _routeEvents.add(RouteEvent.cleared());

      if (kDebugMode) {
        print('All routes cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing routes: $e');
      }
      _routeEvents.add(RouteEvent.error('Failed to clear routes: $e'));
    }
  }

  /// Get route by ID
  MapRoute? getRoute(String routeId) {
    return _activeRoutes[routeId];
  }

  /// Get all active routes
  List<MapRoute> getAllRoutes() {
    return _activeRoutes.values.toList();
  }

  /// Get routes by travel mode
  List<MapRoute> getRoutesByTravelMode(TravelMode travelMode) {
    return _activeRoutes.values
        .where((route) => route.travelMode == travelMode)
        .toList();
  }

  /// Calculate route metrics
  Future<Map<String, dynamic>> getRouteMetrics(String routeId) async {
    try {
      final route = _activeRoutes[routeId];
      if (route == null) {
        return {};
      }

      return _routeService.calculateRouteMetrics(route);
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating route metrics: $e');
      }
      return {};
    }
  }

  /// Optimize existing route
  Future<MapRoute?> optimizeRoute({
    required String routeId,
    RouteOptimization optimization = RouteOptimization.shortestTime,
    Map<String, dynamic>? constraints,
  }) async {
    try {
      final route = _activeRoutes[routeId];
      if (route == null) {
        throw ArgumentError('Route not found: $routeId');
      }

      // Remove old route from map
      await _removeRouteFromMap(routeId);

      // Calculate optimized route
      final optimizedRoute = await _routeService.calculateOptimalRoute(
        points: route.points,
        travelMode: route.travelMode,
        optimization: optimization,
        constraints: constraints,
      );

      if (optimizedRoute != null) {
        // Update active routes
        _activeRoutes[routeId] = optimizedRoute;

        // Display optimized route
        await _displayRouteOnMap(optimizedRoute);

        // Emit route optimized event
        _routeEvents.add(RouteEvent.optimized(optimizedRoute));

        if (kDebugMode) {
          print('Route optimized: $routeId');
        }
      }

      return optimizedRoute;
    } catch (e) {
      if (kDebugMode) {
        print('Error optimizing route: $e');
      }
      _routeEvents.add(RouteEvent.error('Failed to optimize route: $e'));
      return null;
    }
  }

  /// Start route navigation
  Future<void> startNavigation(String routeId) async {
    try {
      final route = _activeRoutes[routeId];
      if (route == null) {
        throw ArgumentError('Route not found: $routeId');
      }

      // Emit navigation started event
      _routeEvents.add(RouteEvent.navigationStarted(route));

      if (kDebugMode) {
        print('Navigation started for route: $routeId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting navigation: $e');
      }
      _routeEvents.add(RouteEvent.error('Failed to start navigation: $e'));
    }
  }

  /// Stop route navigation
  Future<void> stopNavigation(String routeId) async {
    try {
      final route = _activeRoutes[routeId];
      if (route == null) {
        throw ArgumentError('Route not found: $routeId');
      }

      // Emit navigation stopped event
      _routeEvents.add(RouteEvent.navigationStopped(route));

      if (kDebugMode) {
        print('Navigation stopped for route: $routeId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping navigation: $e');
      }
      _routeEvents.add(RouteEvent.error('Failed to stop navigation: $e'));
    }
  }

  /// Get route progress
  Future<RouteProgress?> getRouteProgress(String routeId, MapPoint currentLocation) async {
    try {
      final route = _activeRoutes[routeId];
      if (route == null) return null;

      return _calculateRouteProgress(route, currentLocation);
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating route progress: $e');
      }
      return null;
    }
  }

  /// Calculate route progress
  RouteProgress _calculateRouteProgress(MapRoute route, MapPoint currentLocation) {
    // Find nearest point on route
    double minDistance = double.infinity;
    int nearestIndex = 0;

    for (int i = 0; i < route.coordinates.length; i++) {
      final coord = route.coordinates[i];
      final routePoint = MapPoint(
        id: 'route_point_$i',
        latitude: coord[1],
        longitude: coord[0],
      );

      final distance = currentLocation.distanceTo(routePoint);
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    // Calculate progress percentage
    final progress = nearestIndex / route.coordinates.length;

    // Estimate remaining distance and time
    final remainingPoints = route.coordinates.length - nearestIndex;
    final avgDistancePerPoint = route.distance / route.coordinates.length;
    final remainingDistance = remainingPoints * avgDistancePerPoint;

    final avgTimePerPoint = route.estimatedTime.inSeconds / route.coordinates.length;
    final remainingTime = Duration(seconds: (remainingPoints * avgTimePerPoint).round());

    return RouteProgress(
      routeId: route.id,
      progress: progress,
      currentIndex: nearestIndex,
      remainingDistance: remainingDistance,
      remainingTime: remainingTime,
      nearestPoint: MapPoint(
        id: 'nearest_${route.id}',
        latitude: route.coordinates[nearestIndex][1],
        longitude: route.coordinates[nearestIndex][0],
      ),
    );
  }

  /// Display route on map
  Future<void> _displayRouteOnMap(MapRoute route) async {
    try {
      final mapView = await _mapService.createMapView(MapSettings());
      await mapView.addRoute(route);
    } catch (e) {
      if (kDebugMode) {
        print('Error displaying route on map: $e');
      }
    }
  }

  /// Remove route from map
  Future<void> _removeRouteFromMap(String routeId) async {
    try {
      final mapView = await _mapService.createMapView(MapSettings());
      await mapView.removeRoute(routeId);
    } catch (e) {
      if (kDebugMode) {
        print('Error removing route from map: $e');
      }
    }
  }

  /// Get route statistics
  Future<Map<String, dynamic>> getRouteStatistics() async {
    try {
      final routes = _activeRoutes.values.toList();
      final totalDistance = routes.fold<double>(0, (sum, route) => sum + route.distance);
      final totalTime = routes.fold<Duration>(
        Duration.zero,
        (sum, route) => sum + route.estimatedTime,
      );

      final routesByMode = <TravelMode, int>{};
      for (final route in routes) {
        routesByMode[route.travelMode] = (routesByMode[route.travelMode] ?? 0) + 1;
      }

      return {
        'totalRoutes': routes.length,
        'totalDistance': totalDistance,
        'totalTime': totalTime.inMinutes,
        'routesByMode': routesByMode.map((k, v) => MapEntry(k.toString(), v)),
        'averageDistance': routes.isEmpty ? 0 : totalDistance / routes.length,
        'averageTime': routes.isEmpty ? 0 : totalTime.inMinutes / routes.length,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating route statistics: $e');
      }
      return {};
    }
  }

  /// Export route data
  Future<String> exportRoute(String routeId, RouteExportFormat format) async {
    try {
      final route = _activeRoutes[routeId];
      if (route == null) {
        throw ArgumentError('Route not found: $routeId');
      }

      switch (format) {
        case RouteExportFormat.json:
          return _exportRouteAsJson(route);
        case RouteExportFormat.gpx:
          return _exportRouteAsGpx(route);
        case RouteExportFormat.kml:
          return _exportRouteAsKml(route);
        default:
          throw UnsupportedError('Export format not supported: $format');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting route: $e');
      }
      rethrow;
    }
  }

  /// Export route as JSON
  String _exportRouteAsJson(MapRoute route) {
    return '''
{
  "route": {
    "id": "${route.id}",
    "distance": ${route.distance},
    "estimatedTime": ${route.estimatedTime.inSeconds},
    "travelMode": "${route.travelMode}",
    "points": ${route.points.map((p) => '{"lat": ${p.latitude}, "lng": ${p.longitude}}').toList()},
    "coordinates": ${route.coordinates.map((c) => '[${c[0]}, ${c[1]}]').toList()}
  }
}
''';
  }

  /// Export route as GPX
  String _exportRouteAsGpx(MapRoute route) {
    final points = route.coordinates.map((coord) =>
      '    <trkpt lat="${coord[1]}" lon="${coord[0]}"></trkpt>'
    ).join('\n');

    return '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="RouteManager">
  <trk>
    <name>${route.id}</name>
    <trkseg>
${points}
    </trkseg>
  </trk>
</gpx>''';
  }

  /// Export route as KML
  String _exportRouteAsKml(MapRoute route) {
    final coordinates = route.coordinates.map((coord) => '${coord[0]},${coord[1]},0').join(' ');

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Placemark>
    <name>${route.id}</name>
    <LineString>
      <coordinates>${coordinates}</coordinates>
    </LineString>
  </Placemark>
</kml>''';
  }

  /// Dispose of resources
  void dispose() {
    _routeEvents.close();
    _activeRoutes.clear();
  }
}

/// Route event types
class RouteEvent {
  final RouteEventType type;
  final MapRoute? route;
  final String? error;

  RouteEvent._(this.type, {this.route, this.error});

  factory RouteEvent.created(MapRoute route) => RouteEvent._(RouteEventType.created, route: route);
  factory RouteEvent.updated(MapRoute route) => RouteEvent._(RouteEventType.updated, route: route);
  factory RouteEvent.removed(MapRoute route) => RouteEvent._(RouteEventType.removed, route: route);
  factory RouteEvent.optimized(MapRoute route) => RouteEvent._(RouteEventType.optimized, route: route);
  factory RouteEvent.navigationStarted(MapRoute route) => RouteEvent._(RouteEventType.navigationStarted, route: route);
  factory RouteEvent.navigationStopped(MapRoute route) => RouteEvent._(RouteEventType.navigationStopped, route: route);
  factory RouteEvent.cleared() => RouteEvent._(RouteEventType.cleared);
  factory RouteEvent.error(String error) => RouteEvent._(RouteEventType.error, error: error);
}

/// Route event types
enum RouteEventType {
  created,
  updated,
  removed,
  optimized,
  navigationStarted,
  navigationStopped,
  cleared,
  error,
}

/// Route progress information
class RouteProgress {
  final String routeId;
  final double progress; // 0.0 to 1.0
  final int currentIndex;
  final double remainingDistance;
  final Duration remainingTime;
  final MapPoint nearestPoint;

  RouteProgress({
    required this.routeId,
    required this.progress,
    required this.currentIndex,
    required this.remainingDistance,
    required this.remainingTime,
    required this.nearestPoint,
  });

  @override
  String toString() {
    return 'RouteProgress(routeId: $routeId, progress: ${(progress * 100).round()}%, remaining: ${remainingDistance.toStringAsFixed(1)}km, ${remainingTime.inMinutes}min)';
  }
}

/// Route export formats
enum RouteExportFormat {
  json,
  gpx,
  kml,
}

/// Route constraints for optimization
class RouteConstraints {
  final double? maxDistance;
  final Duration? maxTime;
  final List<String>? avoidRoads;
  final List<String>? preferRoads;
  final bool? avoidTolls;
  final bool? avoidHighways;

  RouteConstraints({
    this.maxDistance,
    this.maxTime,
    this.avoidRoads,
    this.preferRoads,
    this.avoidTolls,
    this.avoidHighways,
  });
}