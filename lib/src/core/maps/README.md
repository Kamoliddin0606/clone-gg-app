# Gloria Marketing Flutter - Advanced Map System

A comprehensive, production-ready map system for Flutter applications with support for Google Maps, Yandex Maps, and OpenStreetMap. Features advanced routing, marker clustering, offline caching, and location services.

## 🚀 Features

### Core Capabilities
- **Multi-Provider Support**: Google Maps, Yandex Maps, OpenStreetMap
- **Advanced Routing**: Multi-point optimization with genetic algorithms
- **Marker Clustering**: Intelligent clustering with multiple algorithms
- **Offline Support**: Tile and route caching for offline use
- **Location Services**: GPS, network positioning, geofencing
- **Real-time Updates**: Reactive architecture with streaming

### Advanced Features
- **Route Optimization**: 5 different optimization algorithms
- **Geofencing**: Circle, rectangle, and polygon regions
- **Navigation**: Turn-by-turn navigation with progress tracking
- **Performance**: Optimized for mobile devices with 1000+ markers
- **Customization**: Extensive configuration and theming options

## 📁 Project Structure

```
lib/src/core/maps/
├── models/                 # Data models and enums
│   ├── map_point.dart     # Geographic points with metadata
│   ├── map_route.dart     # Routes with waypoints and metadata
│   ├── map_marker.dart    # Markers with clustering support
│   └── map_settings.dart  # Map configuration and settings
├── services/              # Core service implementations
│   ├── map_service.dart   # Abstract map service interface
│   ├── route_service.dart # Advanced routing algorithms
│   ├── google_maps_service.dart
│   ├── yandex_maps_service.dart
│   └── osm_service.dart
├── managers/              # High-level managers
│   ├── marker_manager.dart # Marker clustering and management
│   ├── route_manager.dart  # Route lifecycle management
│   └── location_manager.dart # GPS and geofencing
├── widgets/               # Flutter UI components
│   └── map_widget.dart    # Unified map widget
└── README.md             # This documentation
```

## 🛠 Installation & Setup

### 1. Add Dependencies

```yaml
dependencies:
  # Core map dependencies
  google_maps_flutter: ^2.5.0
  yandex_mapkit: ^4.0.0
  flutter_map: ^6.0.0
  latlong2: ^0.9.0

  # Location and utilities
  geolocator: ^11.0.0
  geocoding: ^3.0.0
  path_provider: ^2.1.0

  # Additional utilities
  dio: ^5.4.0
  sqflite: ^2.3.0
  shared_preferences: ^2.2.0
```

### 2. Platform Setup

#### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- For offline caching -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

#### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access for map functionality</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access for navigation features</string>
```

### 3. API Keys Setup

#### Google Maps
```dart
// In main.dart or initialization
import 'package:google_maps_flutter/google_maps_flutter.dart';
void main() {
  // Add your API key
  // Note: API key setup depends on platform
}
```

#### Yandex Maps
```dart
// In main.dart
import 'package:yandex_mapkit/yandex_mapkit.dart';
void main() {
  AndroidYandexMap.useApiKey('YOUR_YANDEX_API_KEY');
}
```

## 📖 Basic Usage

### Simple Map Display

```dart
import 'package:gloria_marketing_flutter/src/core/maps/widgets/map_widget.dart';

class SimpleMapPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Simple Map')),
      body: UnifiedMapWidget(
        provider: MapProvider.google,
        initialCenter: MapPoint(
          id: 'tashkent',
          latitude: 41.2995,
          longitude: 69.2401,
          title: 'Tashkent',
        ),
        initialZoom: 12.0,
      ),
    );
  }
}
```

### Advanced Map with Markers and Routes

```dart
class AdvancedMapPage extends StatefulWidget {
  @override
  _AdvancedMapPageState createState() => _AdvancedMapPageState();
}

class _AdvancedMapPageState extends State<AdvancedMapPage> {
  late UnifiedMapWidget _mapWidget;
  final List<MapMarker> _markers = [];
  final List<MapRoute> _routes = [];

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }

  void _initializeMapData() {
    // Add sample markers
    _markers.addAll([
      MapMarker(
        id: 'client_1',
        point: MapPoint(
          id: 'point_1',
          latitude: 41.2995,
          longitude: 69.2401,
          title: 'Client A',
          description: 'Main client location',
        ),
        type: MarkerType.client,
      ),
      MapMarker(
        id: 'client_2',
        point: MapPoint(
          id: 'point_2',
          latitude: 41.3100,
          longitude: 69.2500,
          title: 'Client B',
        ),
        type: MarkerType.client,
      ),
    ]);

    // Create route between markers
    _createRoute();
  }

  Future<void> _createRoute() async {
    if (_markers.length >= 2) {
      final points = _markers.map((m) => m.point).toList();

      // This would be handled by the RouteManager internally
      // The widget manages this automatically
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Advanced Map'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_location),
            onPressed: _addNewMarker,
          ),
          IconButton(
            icon: Icon(Icons.directions),
            onPressed: _createRoute,
          ),
        ],
      ),
      body: Stack(
        children: [
          UnifiedMapWidget(
            provider: MapProvider.google,
            initialMarkers: _markers,
            initialRoutes: _routes,
            enableClustering: true,
            enableLocation: true,
            enableRouting: true,
            onMarkerTap: _onMarkerTapped,
            onRouteTap: _onRouteTapped,
            onLocationUpdate: _onLocationUpdate,
            onMapReady: () {
              print('Map is ready!');
            },
          ),
          // Additional UI overlays can be added here
        ],
      ),
    );
  }

  void _addNewMarker() {
    // Add marker at current location or user selection
    // Implementation depends on your use case
  }

  void _onMarkerTapped(MapMarker marker) {
    print('Marker tapped: ${marker.title}');
    // Show marker details, navigate, etc.
  }

  void _onRouteTapped(MapRoute route) {
    print('Route tapped: ${route.id}');
    // Show route details, start navigation, etc.
  }

  void _onLocationUpdate(LocationData location) {
    print('Location updated: ${location.latitude}, ${location.longitude}');
    // Update UI with location data
  }
}
```

## 🔧 Advanced Configuration

### Map Settings

```dart
final mapSettings = MapSettings(
  defaultZoom: 15.0,
  minZoom: 8.0,
  maxZoom: 20.0,
  showUserLocation: true,
  showCompass: true,
  enableRotate: true,
  enableTilt: true,
  mapType: MapType.normal,
  theme: MapTheme.light,
);
```

### Marker Clustering Configuration

```dart
final clusterConfig = MarkerClusterConfig(
  maxZoom: 16,
  minClusterSize: 3,
  gridSize: 60.0,
  enableClustering: true,
  animationDuration: Duration(milliseconds: 300),
);
```

### Route Optimization

```dart
// Create optimized route
final route = await routeManager.createRoute(
  points: waypoints,
  travelMode: TravelMode.driving,
  optimization: RouteOptimization.shortestTime,
  constraints: RouteConstraints(
    avoidTolls: true,
    avoidHighways: false,
  ),
);
```

### Geofencing

```dart
// Set up geofence monitoring
final regions = [
  LocationRegion.circle(
    id: 'work_area',
    name: 'Work Area',
    center: MapPoint(id: 'work', latitude: 41.2995, longitude: 69.2401),
    radius: 1000.0, // 1km radius
  ),
];

locationManager.monitorGeofences(regions).listen((event) {
  if (event.type == GeofenceEventType.entered) {
    print('Entered region: ${event.region.name}');
  } else if (event.type == GeofenceEventType.exited) {
    print('Exited region: ${event.region.name}');
  }
});
```

## 📚 API Reference

### Core Classes

#### MapPoint
Represents a geographic location with metadata.

```dart
MapPoint({
  required String id,
  required double latitude,
  required double longitude,
  String? title,
  String? description,
  Map<String, dynamic>? metadata,
});
```

#### MapMarker
Represents a map marker with clustering support.

```dart
MapMarker({
  required String id,
  required MapPoint point,
  MarkerType type = MarkerType.default_,
  String? title,
  String? snippet,
  bool isDraggable = false,
  bool isVisible = true,
});
```

#### MapRoute
Represents a route with waypoints and metadata.

```dart
MapRoute({
  required String id,
  required List<MapPoint> points,
  required List<List<double>> coordinates,
  required double distance,
  required Duration estimatedTime,
  TravelMode travelMode = TravelMode.driving,
});
```

### Managers

#### MarkerManager
Handles marker clustering and display optimization.

```dart
final markerManager = MarkerManager(
  config: clusterConfig,
  provider: MapProvider.google,
);

// Process markers for display
final processedMarkers = await markerManager.processMarkersForDisplay(
  markers,
  zoomLevel,
  mapCenter,
  viewportWidth,
  viewportHeight,
);
```

#### RouteManager
Manages route creation, optimization, and navigation.

```dart
final routeManager = RouteManager(
  routeService: RouteService(provider),
  mapService: mapService,
  provider: provider,
);

// Create route
final route = await routeManager.createRoute(
  points: waypoints,
  travelMode: TravelMode.driving,
);

// Start navigation
await routeManager.startNavigation(route.id);
```

#### LocationManager
Handles GPS positioning and geofencing.

```dart
final locationManager = LocationManager();

// Get current location
final location = await locationManager.getCurrentLocation();

// Start location updates
await locationManager.startLocationUpdates();

// Monitor geofences
locationManager.monitorGeofences(regions).listen((event) {
  // Handle geofence events
});
```

## 🎯 Best Practices

### Performance Optimization

1. **Enable Clustering**: Always enable marker clustering for large datasets
2. **Use Appropriate Zoom Levels**: Set reasonable min/max zoom limits
3. **Implement Caching**: Use offline caching for frequently accessed areas
4. **Batch Operations**: Group marker/route updates when possible
5. **Memory Management**: Dispose of managers and widgets properly

### User Experience

1. **Loading States**: Show appropriate loading indicators
2. **Error Handling**: Provide meaningful error messages
3. **Permissions**: Request location permissions gracefully
4. **Offline Support**: Handle network failures gracefully
5. **Accessibility**: Support screen readers and keyboard navigation

### Code Organization

1. **Separation of Concerns**: Keep business logic separate from UI
2. **Dependency Injection**: Use DI for better testability
3. **Error Boundaries**: Wrap map components with error boundaries
4. **State Management**: Use appropriate state management for complex apps
5. **Testing**: Write unit and integration tests for critical functionality

## 🐛 Troubleshooting

### Common Issues

#### Map Not Loading
- Check API keys are properly configured
- Verify internet connectivity
- Ensure proper platform setup (AndroidManifest, Info.plist)

#### Location Permissions
- Request permissions before initializing location services
- Handle permission denials gracefully
- Check location service status

#### Performance Issues
- Enable marker clustering for large datasets
- Use appropriate zoom levels
- Implement viewport culling
- Cache frequently used data

#### Memory Leaks
- Dispose of StreamSubscriptions
- Clear cached data periodically
- Use weak references where appropriate

## 📄 License

This map system is part of the Gloria Marketing Flutter application.

## 🤝 Contributing

When contributing to the map system:

1. Follow the existing code style and architecture
2. Add comprehensive tests for new features
3. Update documentation for API changes
4. Ensure backward compatibility
5. Test on multiple platforms (Android, iOS)

## 📞 Support

For support and questions:
- Check the troubleshooting section above
- Review the API documentation
- Create an issue with detailed reproduction steps
- Include device/platform information and error logs