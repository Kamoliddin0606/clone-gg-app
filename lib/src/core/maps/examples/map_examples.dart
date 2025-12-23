import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/map_widget.dart';
import '../models/map_point.dart';
import '../models/map_marker.dart';
import '../models/map_route.dart';
import '../models/map_settings.dart';
import '../managers/marker_manager.dart';
import '../managers/route_manager.dart';
import '../managers/location_manager.dart';
import '../services/route_service.dart';
import '../services/map_service.dart';

/// Comprehensive examples demonstrating the map system's capabilities
class MapExamples {
  /// Example 1: Basic Map Display
  static Widget basicMapExample() {
    return Scaffold(
      appBar: AppBar(title: Text('Basic Map Example')),
      body: UnifiedMapWidget(
        provider: MapProvider.google,
        initialCenter: MapPoint(
          id: 'tashkent_center',
          latitude: 41.2995,
          longitude: 69.2401,
          title: 'Tashkent',
          description: 'Capital of Uzbekistan',
        ),
        initialZoom: 12.0,
        onMapReady: () {
          if (kDebugMode) print('Basic map is ready!');
        },
      ),
    );
  }

  /// Example 2: Map with Markers
  static Widget markersMapExample() {
    final markers = [
      MapMarker(
        id: 'client_1',
        point: MapPoint(
          id: 'point_1',
          latitude: 41.2995,
          longitude: 69.2401,
          title: 'Main Office',
          description: 'Headquarters location',
        ),
        type: MarkerType.contract,
        title: 'Main Office',
        snippet: 'Our headquarters',
      ),
      MapMarker(
        id: 'client_2',
        point: MapPoint(
          id: 'point_2',
          latitude: 41.3100,
          longitude: 69.2500,
          title: 'Branch Office',
          description: 'Downtown branch',
        ),
        type: MarkerType.contract,
        title: 'Branch Office',
        snippet: 'Downtown location',
      ),
      MapMarker(
        id: 'warehouse_1',
        point: MapPoint(
          id: 'point_3',
          latitude: 41.2900,
          longitude: 69.2300,
          title: 'Central Warehouse',
          description: 'Main storage facility',
        ),
        type: MarkerType.user,
        title: 'Central Warehouse',
        snippet: 'Storage facility',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Markers Example')),
      body: UnifiedMapWidget(
        provider: MapProvider.google,
        initialMarkers: markers,
        enableClustering: true,
        onMarkerTap: (marker) {
          if (kDebugMode) print('Tapped marker: ${marker.title}');
        },
      ),
    );
  }

  /// Example 3: Route Planning and Navigation
  static Widget routePlanningExample() {
    return RoutePlanningExample();
  }
}

class RoutePlanningExample extends StatefulWidget {
  @override
  _RoutePlanningExampleState createState() => _RoutePlanningExampleState();
}

class _RoutePlanningExampleState extends State<RoutePlanningExample> {
  final List<MapPoint> _waypoints = [
    MapPoint(
      id: 'start',
      latitude: 41.2995,
      longitude: 69.2401,
      title: 'Starting Point',
    ),
    MapPoint(
      id: 'waypoint1',
      latitude: 41.3100,
      longitude: 69.2500,
      title: 'Client A',
    ),
    MapPoint(
      id: 'waypoint2',
      latitude: 41.3200,
      longitude: 69.2600,
      title: 'Client B',
    ),
    MapPoint(
      id: 'end',
      latitude: 41.3300,
      longitude: 69.2700,
      title: 'Warehouse',
    ),
  ];

  MapRoute? _currentRoute;
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Route Planning'),
        actions: [
          IconButton(
            icon: Icon(Icons.directions),
            onPressed: _createRoute,
          ),
          if (_currentRoute != null) ...[
            IconButton(
              icon: Icon(_isNavigating ? Icons.stop : Icons.navigation),
              onPressed: _toggleNavigation,
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          UnifiedMapWidget(
            provider: MapProvider.google,
            initialRoutes: _currentRoute != null ? [_currentRoute!] : [],
            enableRouting: true,
            onRouteTap: (route) {
              if (kDebugMode) print('Route tapped: ${route.id}');
            },
          ),
          if (_currentRoute != null)
            RouteInfoOverlay(
              currentRoute: _currentRoute,
              onClose: () {
                setState(() => _currentRoute = null);
              },
              onOptimize: _optimizeRoute,
            ),
        ],
      ),
      bottomNavigationBar: _buildRouteControls(),
    );
  }

  Widget _buildRouteControls() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Route Waypoints',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          ..._waypoints.map((point) => ListTile(
                leading: Icon(Icons.location_on),
                title: Text(point.title ?? 'Waypoint'),
                subtitle: Text('${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _removeWaypoint(point.id),
                ),
              )),
          SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _addWaypoint,
            icon: Icon(Icons.add),
            label: Text('Add Waypoint'),
          ),
        ],
      ),
    );
  }

  void _createRoute() async {
    // This would normally use RouteManager
    // For demo purposes, we'll create a mock route
    final mockRoute = MapRoute(
      id: 'demo_route',
      points: _waypoints,
      coordinates: _waypoints.map((p) => [p.longitude, p.latitude]).toList(),
      distance: 15.5, // km
      estimatedTime: Duration(minutes: 45),
      travelMode: TravelMode.driving,
      createdAt: DateTime.now(),
    );

    setState(() => _currentRoute = mockRoute);
  }

  void _optimizeRoute() {
    // Implement route optimization
    if (kDebugMode) print('Optimizing route...');
  }

  void _toggleNavigation() {
    setState(() => _isNavigating = !_isNavigating);
  }

  void _addWaypoint() {
    // Add new waypoint at random location
    final newPoint = MapPoint(
      id: 'waypoint_${DateTime.now().millisecondsSinceEpoch}',
      latitude: 41.2995 + (DateTime.now().millisecond % 100) * 0.001,
      longitude: 69.2401 + (DateTime.now().millisecond % 100) * 0.001,
      title: 'New Waypoint',
    );

    setState(() => _waypoints.add(newPoint));
  }

  void _removeWaypoint(String id) {
    setState(() => _waypoints.removeWhere((p) => p.id == id));
  }
}

class RouteInfoOverlay extends StatelessWidget {
  final MapRoute? currentRoute;
  final VoidCallback onClose;
  final VoidCallback onOptimize;

  const RouteInfoOverlay({
    super.key,
    required this.currentRoute,
    required this.onClose,
    required this.onOptimize,
  });

  @override
  Widget build(BuildContext context) {
    final route = currentRoute;
    if (route == null) return const SizedBox.shrink();

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Route',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Distance: ${route.distance.toStringAsFixed(1)} km'),
              Text('ETA: ${route.estimatedTime.inMinutes} min'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onOptimize,
                      child: const Text('Optimize'),
                    ),
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

/// Example 4: Location Services and Geofencing
class LocationServicesExample extends StatefulWidget {
  @override
  _LocationServicesExampleState createState() => _LocationServicesExampleState();
}

class _LocationServicesExampleState extends State<LocationServicesExample> {
  final LocationManager _locationManager = LocationManager();
  LocationData? _currentLocation;
  StreamSubscription<LocationData>? _locationSubscription;
  StreamSubscription<GeofenceEvent>? _geofenceSubscription;

  final List<LocationRegion> _geofenceRegions = [
    LocationRegion.circle(
      id: 'office_area',
      name: 'Office Area',
      center: MapPoint(
        id: 'office_center',
        latitude: 41.2995,
        longitude: 69.2401,
      ),
      radius: 500.0, // 500 meters
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeLocationServices();
  }

  Future<void> _initializeLocationServices() async {
    try {
      await _locationManager.initialize();

      // Start location updates
      _locationSubscription = _locationManager.locationStream.listen(
        (location) {
          setState(() => _currentLocation = location);
        },
        onError: (error) {
          if (kDebugMode) print('Location error: $error');
        },
      );

      await _locationManager.startLocationUpdates();

      // Set up geofencing
      _geofenceSubscription = _locationManager.monitorGeofences(_geofenceRegions).listen(
        (event) {
          _showGeofenceNotification(event);
        },
        onError: (error) {
          if (kDebugMode) print('Geofence error: $error');
        },
      );
    } catch (e) {
      if (kDebugMode) print('Error initializing location services: $e');
    }
  }

  void _showGeofenceNotification(GeofenceEvent event) {
    final action = event.type == GeofenceEventType.entered ? 'Entered' : 'Exited';
    if (kDebugMode) print('$action region: ${event.region.name}');
    // Show notification to user
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Location Services')),
      body: Column(
        children: [
          Expanded(
            child: UnifiedMapWidget(
              provider: MapProvider.google,
              enableLocation: true,
              onLocationUpdate: (location) {
                if (kDebugMode) print('Location updated: ${location.latitude}, ${location.longitude}');
              },
            ),
          ),
          _buildLocationInfo(),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Location Information',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          if (_currentLocation != null) ...[
            Text('Latitude: ${_currentLocation!.latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${_currentLocation!.longitude.toStringAsFixed(6)}'),
            Text('Accuracy: ${_currentLocation!.accuracy?.toStringAsFixed(1)}m'),
            Text('Speed: ${_currentLocation!.speed?.toStringAsFixed(1)}m/s'),
            Text('Heading: ${_currentLocation!.heading?.toStringAsFixed(1)}°'),
          ] else ...[
            Text('Location not available'),
          ],
          SizedBox(height: 16),
          Text(
            'Geofence Regions',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ..._geofenceRegions.map((region) => ListTile(
            leading: Icon(Icons.location_on),
            title: Text(region.name),
            subtitle: Text('Radius: ${region.radius}m'),
          )),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _geofenceSubscription?.cancel();
    _locationManager.dispose();
    super.dispose();
  }
}

/// Example 5: Offline Maps and Caching
class OfflineMapsExample extends StatefulWidget {
  @override
  _OfflineMapsExampleState createState() => _OfflineMapsExampleState();
}

class _OfflineMapsExampleState extends State<OfflineMapsExample> {
  bool _isOfflineMode = false;
  double _cacheSize = 0;

  @override
  void initState() {
    super.initState();
    _checkCacheStatus();
  }

  Future<void> _checkCacheStatus() async {
    // This would check cache status using MapCacheService
    // For demo purposes, we'll simulate
    setState(() => _cacheSize = 45.2); // MB
  }

  Future<void> _downloadOfflineArea() async {
    // This would use MapCacheService to cache tiles
    if (kDebugMode) print('Downloading offline area...');
    // Simulate download progress
    await Future.delayed(Duration(seconds: 2));
    if (kDebugMode) print('Offline area downloaded');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Offline Maps'),
        actions: [
          IconButton(
            icon: Icon(_isOfflineMode ? Icons.wifi : Icons.wifi_off),
            onPressed: () => setState(() => _isOfflineMode = !_isOfflineMode),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildOfflineControls(),
          Expanded(
            child: UnifiedMapWidget(
              provider: MapProvider.openStreetMap, // OSM works well offline
              // Offline mode would be configured here
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineControls() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_isOfflineMode ? Icons.cloud_off : Icons.cloud),
              SizedBox(width: 8),
              Text(
                _isOfflineMode ? 'Offline Mode' : 'Online Mode',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Text('${_cacheSize.toStringAsFixed(1)} MB cached'),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Offline Areas',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(Icons.location_city),
              title: Text('Tashkent City Center'),
              subtitle: Text('12.5 MB • Last updated: Today'),
              trailing: IconButton(
                icon: Icon(Icons.download),
                onPressed: _downloadOfflineArea,
              ),
            ),
          ),
          SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              // Clear cache
              if (kDebugMode) print('Clearing cache...');
            },
            icon: Icon(Icons.delete_sweep),
            label: Text('Clear Cache'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}

/// Example 6: Advanced Marker Clustering
class MarkerClusteringExample extends StatelessWidget {
  final List<MapMarker> _markers = List.generate(
    200, // Generate 200 markers for clustering demo
    (index) => MapMarker(
      id: 'marker_$index',
      point: MapPoint(
        id: 'point_$index',
        latitude: 41.2995 + (index % 20 - 10) * 0.01,
        longitude: 69.2401 + (index ~/ 20 - 5) * 0.01,
        title: 'Marker $index',
      ),
      type: MarkerType.user,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Marker Clustering (${_markers.length} markers)')),
      body: UnifiedMapWidget(
        provider: MapProvider.google,
        initialMarkers: _markers,
        enableClustering: true,
        initialCenter: MapPoint(
          id: 'center',
          latitude: 41.2995,
          longitude: 69.2401,
        ),
        initialZoom: 12.0,
      ),
    );
  }
}

/// Example 7: Custom Map Styling and Theming
class CustomStylingExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Custom Map Styling')),
      body: UnifiedMapWidget(
        provider: MapProvider.google,
        settings: MapSettings(
          mapType: MapType.satellite,
          // theme: MapTheme.dark,
          showUserLocation: true,
          showCompass: true,
          enableRotation: true,
          enableTilt: true,
        ),
        initialCenter: MapPoint(
          id: 'styled_center',
          latitude: 41.2995,
          longitude: 69.2401,
        ),
      ),
    );
  }
}

/// Example 8: Real-time Multi-user Tracking
class MultiUserTrackingExample extends StatefulWidget {
  @override
  _MultiUserTrackingExampleState createState() => _MultiUserTrackingExampleState();
}

class _MultiUserTrackingExampleState extends State<MultiUserTrackingExample> {
  final Map<String, MapMarker> _userMarkers = {};
  final LocationManager _locationManager = LocationManager();

  @override
  void initState() {
    super.initState();
    _initializeMultiUserTracking();
  }

  Future<void> _initializeMultiUserTracking() async {
    // Simulate multiple users
    final users = ['Alice', 'Bob', 'Charlie', 'Diana'];

    for (final user in users) {
      // In real app, this would come from server/location service
      final marker = MapMarker(
        id: 'user_$user',
        point: MapPoint(
          id: 'user_location_$user',
          latitude: 41.2995 + (users.indexOf(user) - 1.5) * 0.005,
          longitude: 69.2401 + (users.indexOf(user) - 1.5) * 0.005,
          title: user,
          description: 'User location',
        ),
        type: MarkerType.user,
        title: user,
        snippet: 'Last seen: ${DateTime.now().toString()}',
      );

      _userMarkers[user] = marker;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Multi-user Tracking (${_userMarkers.length} users)')),
      body: UnifiedMapWidget(
        provider: MapProvider.google,
        initialMarkers: _userMarkers.values.toList(),
        enableLocation: true,
        enableClustering: false, // Don't cluster user markers
      ),
    );
  }

  @override
  void dispose() {
    _locationManager.dispose();
    super.dispose();
  }
}

/// Example launcher widget
class MapExamplesLauncher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Map System Examples')),
      body: ListView(
        children: [
          _buildExampleTile(
            context,
            'Basic Map',
            'Simple map display',
            MapExamples.basicMapExample(),
          ),
          _buildExampleTile(
            context,
            'Markers',
            'Map with markers and clustering',
            MapExamples.markersMapExample(),
          ),
          _buildExampleTile(
            context,
            'Route Planning',
            'Multi-point routing and navigation',
            MapExamples.routePlanningExample(),
          ),
          _buildExampleTile(
            context,
            'Location Services',
            'GPS, geofencing, and location tracking',
            LocationServicesExample(),
          ),
          _buildExampleTile(
            context,
            'Offline Maps',
            'Offline tile caching and storage',
            OfflineMapsExample(),
          ),
          _buildExampleTile(
            context,
            'Marker Clustering',
            'Advanced clustering with 200 markers',
            MarkerClusteringExample(),
          ),
          _buildExampleTile(
            context,
            'Custom Styling',
            'Custom themes and map styling',
            CustomStylingExample(),
          ),
          _buildExampleTile(
            context,
            'Multi-user Tracking',
            'Real-time user location tracking',
            MultiUserTrackingExample(),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleTile(BuildContext context, String title, String description, Widget example) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(title),
        subtitle: Text(description),
        trailing: Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => example),
          );
        },
      ),
    );
  }
}