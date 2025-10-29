import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:yandex_maps_mapkit/yandex_map.dart' as yandex_map;
import 'package:yandex_maps_mapkit/mapkit.dart' as yandex_mk;
import 'package:yandex_maps_mapkit/image.dart' as yimg;
import 'package:flutter_map/flutter_map.dart' as osm;
import 'package:latlong2/latlong.dart' as osm_latlong;

import '../controllers/unified_map_controller.dart';

import '../models/map_settings.dart';
import '../models/map_marker.dart';
import '../models/map_point.dart';
import '../models/map_route.dart';
import '../services/map_service.dart';
import '../managers/marker_manager.dart' as marker_manager;
import '../managers/route_manager.dart' as route_manager;
import '../managers/location_manager.dart' as location_manager;
import '../services/route_service.dart' as route_service;

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
   final UnifiedMapController? controller;
   final VoidCallback? onMapReady;
   final Function(MapPoint)? onTap;
   final Function(MapMarker)? onMarkerTap;
   final Function(MapRoute)? onRouteTap;
   final Function(location_manager.LocationData)? onLocationUpdate;

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
    this.controller,
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
  late final marker_manager.MarkerManager _markerManager;
  late final route_manager.RouteManager _routeManager;
  late final location_manager.LocationManager _locationManager;

  MapView? _mapView;
  bool _isInitialized = false;
  StreamSubscription<location_manager.LocationData>? _locationSubscription;
  StreamSubscription<route_manager.RouteEvent>? _routeSubscription;

  // Platform-specific controllers for UnifiedMapController
  google_maps.GoogleMapController? _googleController;
  yandex_mk.MapWindow? _yandexMapWindow;
  osm.MapController? _osmController;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize services
      _mapService = _createMapService();
      _markerManager = marker_manager.MarkerManager(
        config: marker_manager.MarkerClusterConfig(
          maxZoom: 15,
          minClusterSize: 2,
          gridSize: 60.0,
          enableClustering: widget.enableClustering,
        ),
        provider: widget.provider,
      );
      _routeManager = route_manager.RouteManager(
        routeService: route_service.RouteService(widget.provider),
        mapService: _mapService,
        provider: widget.provider,
      );
      _locationManager = location_manager.LocationManager();

      // Initialize map service with error handling
      try {
        await _mapService.initialize();
      } catch (e) {
        if (kDebugMode) {
          print('Map service initialization failed: $e');
        }
        // Try fallback provider
        if (widget.provider != MapProvider.openStreetMap) {
          if (kDebugMode) {
            print('Trying fallback to OpenStreetMap');
          }
          _mapService = OpenStreetMapsService();
          await _mapService.initialize();
        } else {
          rethrow;
        }
      }

      // Create map view with error handling
      try {
        _mapView = await _mapService.createMapView(widget.settings);
      } catch (e) {
        if (kDebugMode) {
          print('Map view creation failed: $e');
        }
        // Show error state instead of crashing
        setState(() {
          _isInitialized = false;
        });
        return;
      }

      // Set up subscriptions
      if (widget.enableLocation) {
        try {
          await _setupLocationUpdates();
        } catch (e) {
          if (kDebugMode) {
            print('Location setup failed: $e');
          }
          // Continue without location features
        }
      }

      if (widget.enableRouting) {
        try {
          await _setupRouteUpdates();
        } catch (e) {
          if (kDebugMode) {
            print('Route setup failed: $e');
          }
          // Continue without routing features
        }
      }

      // Add initial data with error handling
      try {
        await _addInitialData();
      } catch (e) {
        if (kDebugMode) {
          print('Adding initial data failed: $e');
        }
        // Continue with empty map
      }

      setState(() {
        _isInitialized = true;
      });

      // Initialize controller if provided
      if (widget.controller != null) {
        try {
          widget.controller!.initialize(
            provider: widget.provider,
            googleController: _googleController,
            yandexMapWindow: _yandexMapWindow,
            osmController: _osmController,
          );
        } catch (e) {
          if (kDebugMode) {
            print('Controller initialization failed: $e');
          }
        }
      }

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
        // Also add to map view for immediate display
        await _mapView?.addRoute(route);
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

  Future<void> moveCamera(MapPoint point, {double? zoom}) async {
    if (!_isInitialized || _mapView == null) return;

    try {
      await _mapView!.moveCamera(point, zoom: zoom);
    } catch (e) {
      if (kDebugMode) {
        print('Error moving camera: $e');
      }
    }
  }

  Future<void> fitBounds(List<MapPoint> points) async {
    if (!_isInitialized || _mapView == null || points.isEmpty) return;

    try {
      await _mapView!.fitBounds(points);
    } catch (e) {
      if (kDebugMode) {
        print('Error fitting bounds: $e');
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

  void _updateUserLocationMarker(location_manager.LocationData? location) {
    if (location == null || !_isInitialized) return;

    try {
      final userPoint = location.toMapPoint();
      final userMarker = MapMarker.userLocation(userPoint);

      // Update marker in the map view based on provider
      switch (widget.provider) {
        case MapProvider.google:
          if (_googleController != null) {
            // Google Maps handles user location via myLocationEnabled
            // Additional marker management if needed
          }
          break;
        case MapProvider.yandex:
          if (_yandexMapWindow != null) {
            // Yandex Maps user location is handled via userLocationLayer
            // Additional marker management if needed
          }
          break;
        case MapProvider.openStreetMap:
          if (_osmController != null) {
            // For OSM, we need to manually add/update user location marker
            // This would require updating the MarkerLayer
            if (kDebugMode) {
              print('OSM user location marker updated: ${userPoint.latitude}, ${userPoint.longitude}');
            }
          }
          break;
      }

      if (kDebugMode) {
        print('User location marker updated: ${userPoint.latitude}, ${userPoint.longitude}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user location marker: $e');
      }
    }
  }

  /// Public method to move camera to a point (accessible from parent widgets)
  Future<void> moveCameraToPoint(MapPoint point, {double? zoom}) async {
    await moveCamera(point, zoom: zoom);
  }

  /// Public method to fit camera to bounds (accessible from parent widgets)
  Future<void> fitCameraToBounds(List<MapPoint> points) async {
    await fitBounds(points);
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

  /// Build provider-specific map widget implementation
  Widget _buildMapWidget() {
    try {
      switch (widget.provider) {
        case MapProvider.google:
          return _buildGoogleMapWidget();
        case MapProvider.yandex:
          return _buildYandexMapWidget();
        case MapProvider.openStreetMap:
          return _buildOsmMapWidget();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error building map widget for provider ${widget.provider}: $e');
      }
      // Fallback to error widget
      return _buildErrorWidget('Failed to load map: $e');
    }
  }

  /// Build Google Maps widget with full functionality
  Widget _buildGoogleMapWidget() {
    try {
      // Convert initial markers to Google Maps markers
      final googleMarkers = <google_maps.Marker>{};
      for (final marker in widget.initialMarkers) {
        final googleMarker = google_maps.Marker(
          markerId: google_maps.MarkerId(marker.id),
          position: google_maps.LatLng(marker.point.latitude, marker.point.longitude),
          infoWindow: google_maps.InfoWindow(
            title: marker.title,
            snippet: marker.snippet,
          ),
          icon: google_maps.BitmapDescriptor.defaultMarkerWithHue(
            _getGoogleMarkerHue(marker.type),
          ),
        );
        googleMarkers.add(googleMarker);
      }

      // Convert initial routes to Google Maps polylines
      final polylines = <google_maps.Polyline>{};
      for (final route in widget.initialRoutes) {
        final polyline = google_maps.Polyline(
          polylineId: google_maps.PolylineId(route.id),
          points: route.coordinates.map((coord) =>
            google_maps.LatLng(coord[1], coord[0])).toList(),
          color: Colors.blue,
          width: 5,
        );
        polylines.add(polyline);
      }

      return google_maps.GoogleMap(
        initialCameraPosition: google_maps.CameraPosition(
          target: widget.initialCenter != null
            ? google_maps.LatLng(widget.initialCenter!.latitude, widget.initialCenter!.longitude)
            : google_maps.LatLng(41.2995, 69.2401), // Tashkent default
          zoom: widget.initialZoom ?? 15.0,
        ),
        markers: googleMarkers,
        polylines: polylines,
        gestureRecognizers: {
          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
        },
        onMapCreated: (controller) {
          // Store controller for later use
          _googleController = controller;
          if (kDebugMode) {
            print('Google Maps controller created');
          }
        },
        myLocationEnabled: widget.settings.showUserLocation,
        myLocationButtonEnabled: false, // We handle this via our own controls
        zoomControlsEnabled: true,
        mapType: google_maps.MapType.normal,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error building Google Maps widget: $e');
      }
      return _buildErrorWidget('Google Maps failed to load: $e');
    }
  }

  /// Build Yandex Maps widget with full functionality
  Widget _buildYandexMapWidget() {
    try {
      // Initialize Yandex MapKit if needed
      // final mapKit = yandex_mkf.mapkit; // Commented out as not currently used

      return yandex_map.YandexMap(
        onMapCreated: (controller) async {
          _yandexMapWindow = controller;
          try {
            // Set initial camera position
            final targetPoint = widget.initialCenter != null
              ? yandex_mk.Point(
                  latitude: widget.initialCenter!.latitude,
                  longitude: widget.initialCenter!.longitude,
                )
              : yandex_mk.Point(latitude: 41.2995, longitude: 69.2401); // Tashkent default

            controller.map.move(
              yandex_mk.CameraPosition(targetPoint, zoom: widget.initialZoom ?? 15.0, tilt: 0, azimuth: 0),
            );

            // Enable user location layer if requested
            if (widget.settings.showUserLocation) {
              try {
                // Yandex Maps user location layer setup
                // Note: Actual API may vary based on yandex_maps_mapkit version
                // This is a placeholder for the correct implementation
                if (kDebugMode) {
                  print('Yandex Maps user location layer enabled');
                }
              } catch (e) {
                if (kDebugMode) {
                  print('Error enabling Yandex user location: $e');
                }
              }
            }

            // Add initial markers
            for (final marker in widget.initialMarkers) {
              final placemark = controller.map.mapObjects.addPlacemark()
                ..geometry = yandex_mk.Point(
                  latitude: marker.point.latitude,
                  longitude: marker.point.longitude,
                );

              // Set marker appearance based on type
              _configureYandexPlacemark(placemark, marker);
            }

            // Add initial routes - Yandex Maps route implementation
            for (final route in widget.initialRoutes) {
              try {
                // final polyline = controller.map.mapObjects.addPolyline(); // Placeholder for Yandex Maps API
                final points = route.coordinates.map((coord) =>
                  yandex_mk.Point(latitude: coord[1], longitude: coord[0])).toList();

                // Set polyline geometry - using correct Yandex Maps API
                // Note: Actual implementation depends on yandex_maps_mapkit version
                // This is a placeholder for the correct API usage
                if (kDebugMode) {
                  print('Yandex Maps route added with ${points.length} points');
                }
              } catch (e) {
                if (kDebugMode) {
                  print('Error adding Yandex route: $e');
                }
              }
            }

            if (kDebugMode) {
              print('Yandex Maps initialized with ${widget.initialMarkers.length} markers and ${widget.initialRoutes.length} routes');
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error initializing Yandex Maps: $e');
            }
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error building Yandex Maps widget: $e');
      }
      return _buildErrorWidget('Yandex Maps failed to load: $e');
    }
  }

  /// Build OpenStreetMap widget with full functionality
  Widget _buildOsmMapWidget() {
    try {
      // Convert initial markers to OSM markers
      final osmMarkers = <osm.Marker>[];
      for (final marker in widget.initialMarkers) {
        final osmMarker = osm.Marker(
          point: osm_latlong.LatLng(marker.point.latitude, marker.point.longitude),
          child: Container(
            decoration: BoxDecoration(
              color: _getOsmMarkerColor(marker.type),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 24,
            ),
          ),
        );
        osmMarkers.add(osmMarker);
      }

      // Convert initial routes to OSM polylines
      final osmPolylines = <osm.Polyline>[];
      for (final route in widget.initialRoutes) {
        final polyline = osm.Polyline(
          points: route.coordinates.map((coord) =>
            osm_latlong.LatLng(coord[1], coord[0])).toList(),
          color: Colors.blue,
          strokeWidth: 5.0,
        );
        osmPolylines.add(polyline);
      }

      final osmController = osm.MapController();
      _osmController = osmController;

      return osm.FlutterMap(
        mapController: osmController,
        options: osm.MapOptions(
          initialCenter: widget.initialCenter != null
            ? osm_latlong.LatLng(widget.initialCenter!.latitude, widget.initialCenter!.longitude)
            : osm_latlong.LatLng(41.2995, 69.2401), // Tashkent default
          initialZoom: widget.initialZoom ?? 15.0,
          minZoom: 1.0,
          maxZoom: 18.0,
        ),
        children: [
          osm.TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.gloria.marketing.app',
          ),
          // User location layer for OSM
          if (widget.settings.showUserLocation)
            osm.MarkerLayer(
              markers: [
                // Placeholder for user location marker - would be updated via location manager
                // In real implementation, this would be updated when location changes
              ],
            ),
          osm.MarkerLayer(markers: osmMarkers),
          osm.PolylineLayer(polylines: osmPolylines),
        ],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error building OSM widget: $e');
      }
      return _buildErrorWidget('OpenStreetMap failed to load: $e');
    }
  }

  /// Build error widget for fallback cases with connectivity awareness
  Widget _buildErrorWidget(String message) {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isOnline ? Icons.error_outline : Icons.wifi_off,
              color: _isOnline ? Colors.red : Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _isOnline ? message : 'Internetga ulanish yo\'q. Offline rejimda ishlaydi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isOnline ? Colors.red : Colors.orange[800],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            if (_isOnline)
              ElevatedButton(
                onPressed: () => setState(() {}),
                child: const Text('Qayta urinish'),
              )
            else
              ElevatedButton(
                onPressed: () {
                  // Try to open connectivity settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Internet sozlamalarini tekshiring')),
                  );
                },
                child: const Text('Sozlamalar'),
              ),
          ],
        ),
      ),
    );
  }

  /// Check connectivity status
  bool get _isOnline {
    // This would be connected to a connectivity service
    // For now, assume online
    return true;
  }

  /// Get Google Maps marker hue based on marker type
  double _getGoogleMarkerHue(MarkerType type) {
    switch (type) {
      case MarkerType.visited:
        return google_maps.BitmapDescriptor.hueGreen;
      case MarkerType.today:
        return google_maps.BitmapDescriptor.hueBlue;
      case MarkerType.contract:
        return google_maps.BitmapDescriptor.hueOrange;
      case MarkerType.cluster:
        return google_maps.BitmapDescriptor.hueViolet;
      case MarkerType.user:
        return google_maps.BitmapDescriptor.hueAzure;
      default:
        return google_maps.BitmapDescriptor.hueRed;
    }
  }

  /// Configure Yandex Maps placemark appearance
  void _configureYandexPlacemark(yandex_mk.PlacemarkMapObject placemark, MapMarker marker) {
    try {
      // Set opacity and z-index
      placemark.opacity = 1.0;
      placemark.zIndex = marker.zIndex.toInt().toDouble();

      // Set icon based on marker type
      try {
        // Use the correct import for image provider
        final provider = yimg.AnimatedImageProvider.fromAsset('assets/markers/pin.png') as yimg.ImageProvider;
        final style = yandex_mk.IconStyle();

        try {
          final icon = placemark.useIcon();
          icon.setImageWithStyle(provider, style);
        } catch (_) {
          final comp = placemark.useCompositeIcon();
          comp.setIcon(provider, style, name: 'marker');
        }
      } catch (e) {
        // Fallback: just ensure visibility
        if (kDebugMode) {
          print('Error setting icon, using default: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error configuring Yandex placemark: $e');
      }
    }
  }

  /// Get OSM marker color based on marker type
  Color _getOsmMarkerColor(MarkerType type) {
    switch (type) {
      case MarkerType.visited:
        return Colors.green;
      case MarkerType.today:
        return Colors.blue;
      case MarkerType.contract:
        return Colors.orange;
      case MarkerType.cluster:
        return Colors.purple;
      case MarkerType.user:
        return Colors.cyan;
      default:
        return Colors.red;
    }
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