import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/map_point.dart';
import '../models/map_route.dart';
import '../models/map_marker.dart';
import '../models/map_settings.dart';
import '../services/map_service.dart';
import '../managers/marker_manager.dart' as marker_manager;
import '../managers/route_manager.dart' as route_manager;
import '../managers/location_manager.dart' as location_manager;

/// Unified map widget that integrates all map services and managers
class UnifiedMapWidget extends StatefulWidget {
  final MapProvider provider;
  final MapSettings settings;
  final List<MapMarker> initialMarkers;
  final List<MapRoute> initialRoutes;
  final MapPoint? initialCenter;
  final double? initialZoom;
  final bool enableClustering;
  final bool enableLocation;
  final bool enableRouting;
  final VoidCallback? onMapReady;
  final Function(MapPoint)? onTap;
  final Function(MapMarker)? onMarkerTap;
  final Function(MapRoute)? onRouteTap;
  final Function(LocationData)? onLocationUpdate;

  const UnifiedMapWidget({
    super.key,
    required this.provider,
    this.settings = const MapSettings(),
    this.initialMarkers = const [],
    this.initialRoutes = const [],
    this.initialCenter,
    this.initialZoom,
    this.enableClustering = true,
    this.enableLocation = false,
    this.enableRouting = true,
    this.onMapReady,
    this.onTap,
    this.onMarkerTap,
    this.onRouteTap,
    this.onLocationUpdate,
  });

  @override
  State<UnifiedMapWidget> createState() => _UnifiedMapWidgetState();
}

class _UnifiedMapWidgetState extends State<UnifiedMapWidget> {
  late final MapService _mapService;
  late final MarkerManager _markerManager;
  late final RouteManager _routeManager;
  late final LocationManager _locationManager;

  MapView? _mapView;
  bool _isInitialized = false;
  StreamSubscription<LocationData>? _locationSubscription;
  StreamSubscription<RouteEvent>? _routeSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize services
      _mapService = _createMapService();
      _markerManager = MarkerManager(
        config: MarkerClusterConfig(
          maxZoom: 15,
          minClusterSize: 2,
          gridSize: 60.0,
          enableClustering: widget.enableClustering,
        ),
        provider: widget.provider,
      );
      _routeManager = RouteManager(
        routeService: RouteService(widget.provider),
        mapService: _mapService,
        provider: widget.provider,
      );
      _locationManager = LocationManager();

      // Initialize map service
      await _mapService.initialize();

      // Create map view
      _mapView = await _mapService.createMapView(widget.settings);

      // Set up subscriptions
      if (widget.enableLocation) {
        await _setupLocationUpdates();
      }

      if (widget.enableRouting) {
        await _setupRouteUpdates();
      }

      // Add initial data
      await _addInitialData();

      setState(() {
        _isInitialized = true;
      });

      widget.onMapReady?.call();

      if (kDebugMode) {
        print('Unified map widget initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing unified map widget: $e');
      }
      // Show error state
      setState(() {
        _isInitialized = false;
      });
    }
  }

  MapService _createMapService() {
    switch (widget.provider) {
      case MapProvider.google:
        return GoogleMapsService();
      case MapProvider.yandex:
        return YandexMapsService();
      case MapProvider.openStreetMap:
        return OpenStreetMapsService();
    }
  }

  Future<void> _setupLocationUpdates() async {
    try {
      await _locationManager.initialize();
      _locationSubscription = _locationManager.locationStream.listen(
        (location) {
          widget.onLocationUpdate?.call(location);
          // Update user location marker if enabled
          if (widget.settings.showUserLocation) {
            _updateUserLocationMarker(location);
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('Location stream error: $error');
          }
        },
      );

      // Start location updates
      await _locationManager.startLocationUpdates();
    } catch (e) {
      if (kDebugMode) {
        print('Error setting up location updates: $e');
      }
    }
  }

  Future<void> _setupRouteUpdates() async {
    _routeSubscription = _routeManager.routeEvents.listen(
      (event) {
        if (kDebugMode) {
          print('Route event: ${event.type}');
        }
        // Handle route events (creation, updates, etc.)
        setState(() {});
      },
      onError: (error) {
        if (kDebugMode) {
          print('Route event error: $error');
        }
      },
    );
  }

  Future<void> _addInitialData() async {
    try {
      // Add initial markers
      if (widget.initialMarkers.isNotEmpty) {
        await addMarkers(widget.initialMarkers);
      }

      // Add initial routes
      for (final route in widget.initialRoutes) {
        await _routeManager.createRoute(
          points: route.points,
          travelMode: route.travelMode,
          displayOnMap: true,
        );
      }

      // Set initial camera position
      if (widget.initialCenter != null) {
        await _mapView?.moveCamera(widget.initialCenter!, zoom: widget.initialZoom);
      } else if (widget.initialMarkers.isNotEmpty) {
        // Fit bounds to show all markers
        final bounds = _calculateBounds(widget.initialMarkers.map((m) => m.point).toList());
        await _mapView?.fitBounds(bounds);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding initial data: $e');
      }
    }
  }

  Future<void> addMarkers(List<MapMarker> markers) async {
    if (!_isInitialized || _mapView == null) return;

    try {
      // Process markers through marker manager for clustering
      final processedMarkers = await _markerManager.processMarkersForDisplay(
        markers,
        widget.settings.defaultZoom,
        widget.initialCenter ?? MapPoint(id: 'center', latitude: 0, longitude: 0),
        400, // viewport width
        600, // viewport height
      );

      // Add to map
      await _mapView!.addMarkers(processedMarkers);
    } catch (e) {
      if (kDebugMode) {
        print('Error adding markers: $e');
      }
    }
  }

  Future<void> removeMarkers(List<String> markerIds) async {
    if (!_isInitialized || _mapView == null) return;

    try {
      await _mapView!.removeMarkers(markerIds);
    } catch (e) {
      if (kDebugMode) {
        print('Error removing markers: $e');
      }
    }
  }

  Future<void> addRoute(List<MapPoint> points, TravelMode travelMode) async {
    if (!_isInitialized) return;

    try {
      await _routeManager.createRoute(
        points: points,
        travelMode: travelMode,
        displayOnMap: true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error adding route: $e');
      }
    }
  }

  Future<void> clearRoutes() async {
    if (!_isInitialized) return;

    try {
      await _routeManager.clearAllRoutes();
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing routes: $e');
      }
    }
  }

  void _updateUserLocationMarker(LocationData location) {
    // Implementation for updating user location marker
    // This would create or update a special marker for user location
  }

  List<MapPoint> _calculateBounds(List<MapPoint> points) {
    if (points.isEmpty) return [];

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLng = min(minLng, point.longitude);
      maxLng = max(maxLng, point.longitude);
    }

    return [
      MapPoint(id: 'sw', latitude: minLat, longitude: minLng),
      MapPoint(id: 'ne', latitude: maxLat, longitude: maxLng),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return _buildMapWidget();
  }

  Widget _buildMapWidget() {
    // This is a placeholder - actual implementation would depend on the map provider
    // For Google Maps: return GoogleMap(...)
    // For Yandex Maps: return YandexMap(...)
    // For OSM: return FlutterMap(...)

    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Text('Map Widget - Provider specific implementation needed'),
      ),
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _routeSubscription?.cancel();
    _locationManager.dispose();
    _routeManager.dispose();
    _mapView?.dispose();
    super.dispose();
  }
}

/// Map controls widget for zoom, location, layers, etc.
class MapControls extends StatelessWidget {
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onMyLocation;
  final VoidCallback? onLayers;
  final bool showZoom;
  final bool showLocation;
  final bool showLayers;

  const MapControls({
    super.key,
    this.onZoomIn,
    this.onZoomOut,
    this.onMyLocation,
    this.onLayers,
    this.showZoom = true,
    this.showLocation = true,
    this.showLayers = true,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLayers) ...[
            FloatingActionButton.small(
              onPressed: onLayers,
              child: const Icon(Icons.layers),
            ),
            const SizedBox(height: 8),
          ],
          if (showLocation) ...[
            FloatingActionButton.small(
              onPressed: onMyLocation,
              child: const Icon(Icons.my_location),
            ),
            const SizedBox(height: 8),
          ],
          if (showZoom) ...[
            FloatingActionButton.small(
              onPressed: onZoomIn,
              child: const Icon(Icons.add),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.small(
              onPressed: onZoomOut,
              child: const Icon(Icons.remove),
            ),
          ],
        ],
      ),
    );
  }
}

/// Route information overlay
class RouteInfoOverlay extends StatelessWidget {
  final MapRoute? currentRoute;
  final RouteProgress? progress;
  final VoidCallback? onClose;
  final VoidCallback? onOptimize;

  const RouteInfoOverlay({
    super.key,
    this.currentRoute,
    this.progress,
    this.onClose,
    this.onOptimize,
  });

  @override
  Widget build(BuildContext context) {
    if (currentRoute == null) return const SizedBox.shrink();

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Route Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Distance: ${currentRoute!.distance.toStringAsFixed(1)} km'),
              Text('Duration: ${currentRoute!.estimatedTime.inHours}h ${currentRoute!.estimatedTime.inMinutes % 60}m'),
              if (progress != null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress!.progress),
                Text('Progress: ${(progress!.progress * 100).toStringAsFixed(1)}%'),
                Text('Remaining: ${progress!.remainingDistance.toStringAsFixed(1)} km, ${progress!.remainingTime.inMinutes} min'),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (onOptimize != null) ...[
                    TextButton.icon(
                      onPressed: onOptimize,
                      icon: const Icon(Icons.optimize),
                      label: const Text('Optimize'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton.icon(
                    onPressed: onClose,
                    icon: const Icon(Icons.directions),
                    label: const Text('Start Navigation'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Marker clustering overlay
class MarkerClusterOverlay extends StatelessWidget {
  final List<MapMarker> markers;
  final Function(MapMarker)? onMarkerTap;
  final Function(MapMarker)? onClusterTap;

  const MarkerClusterOverlay({
    super.key,
    required this.markers,
    this.onMarkerTap,
    this.onClusterTap,
  });

  @override
  Widget build(BuildContext context) {
    // This would render custom marker widgets on top of the map
    // Implementation depends on the specific map provider
    return const SizedBox.shrink();
  }
}

/// Map search widget
class MapSearchWidget extends StatefulWidget {
  final Function(String) onSearch;
  final List<String> recentSearches;
  final bool showRecent;

  const MapSearchWidget({
    super.key,
    required this.onSearch,
    this.recentSearches = const [],
    this.showRecent = true,
  });

  @override
  State<MapSearchWidget> createState() => _MapSearchWidgetState();
}

class _MapSearchWidgetState extends State<MapSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _showSuggestions = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search places...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    _controller.clear();
                    setState(() => _showSuggestions = false);
                  },
                  icon: const Icon(Icons.clear),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() => _showSuggestions = value.isNotEmpty);
                widget.onSearch(value);
              },
              onSubmitted: (value) {
                widget.onSearch(value);
                setState(() => _showSuggestions = false);
              },
            ),
          ),
          if (_showSuggestions && widget.showRecent && widget.recentSearches.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.recentSearches.map((search) => ListTile(
                  title: Text(search),
                  onTap: () {
                    _controller.text = search;
                    widget.onSearch(search);
                    setState(() => _showSuggestions = false);
                  },
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Map legend widget
class MapLegend extends StatelessWidget {
  final List<LegendItem> items;

  const MapLegend({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: 16,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Legend',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...items.map((item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: item.shape,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(item.label),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }
}

/// Legend item data class
class LegendItem {
  final String label;
  final Color color;
  final BoxShape shape;

  const LegendItem({
    required this.label,
    required this.color,
    this.shape = BoxShape.circle,
  });
}