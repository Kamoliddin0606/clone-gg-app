import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:latlong2/latlong.dart' as osm_latlong;
import 'package:flutter_map/flutter_map.dart' as osm;
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/maps/widgets/map_widget.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_settings.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_marker.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_point.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_route.dart';
import 'package:gloria_marketing_flutter/src/core/maps/managers/location_manager.dart' as location_manager;
import 'package:gloria_marketing_flutter/src/core/maps/managers/route_manager.dart' as route_manager;
import 'package:gloria_marketing_flutter/src/core/maps/managers/marker_manager.dart' as marker_manager;
import 'package:gloria_marketing_flutter/src/core/maps/services/route_service.dart' as route_service;
import 'package:gloria_marketing_flutter/src/core/maps/services/map_service.dart' as map_service;

/// Map detail page for displaying client location with map controls
/// This page shows the client's location on map with various control icons
/// positioned similar to Yandex Maps UI design pattern
///
/// Features:
/// - 4 control icons in bottom-right corner:
///   1. User position (my_location icon)
///   2. Client position (location_on icon)
///   3. Route (route icon) - shows route from user to client
///   4. Fullscreen (fullscreen icon) - opens fullscreen map
/// - 1 control icon in top-right corner:
///   5. Update coordinates (edit_location icon) - updates client coordinates
///
/// All icons follow Material Design principles and Yandex Maps UI patterns.
/// Tap handlers currently show snackbar messages, full functionality to be implemented later.
class MapDetailPage extends StatefulWidget {
  final model.TradingPoint tradingPoint;

  const MapDetailPage({
    super.key,
    required this.tradingPoint,
  });

  @override
  State<MapDetailPage> createState() => _MapDetailPageState();
}

/// Map detail page for displaying client location with map controls
/// This page shows the client's location on map with various control icons
/// positioned similar to Yandex Maps UI design pattern
///
/// Features:
/// - 4 control icons in bottom-right corner:
///   1. User position (my_location icon)
///   2. Client position (location_on icon)
///   3. Route (route icon) - shows route from user to client
///   4. Fullscreen (fullscreen icon) - opens fullscreen map
/// - 1 control icon in top-right corner:
///   5. Update coordinates (edit_location icon) - updates client coordinates
///
/// All icons follow Material Design principles and Yandex Maps UI patterns.
/// Tap handlers currently show snackbar messages, full functionality to be implemented later.

class _MapDetailPageState extends State<MapDetailPage> {
  // Core managers
  late final location_manager.LocationManager _locationManager;
  late final route_manager.RouteManager _routeManager;
  late final marker_manager.MarkerManager _markerManager;

  // Map provider and settings
  MapProvider _defaultMapProvider = MapProvider.google;
  late MapSettings _mapSettings;

  // Map data
  late MapPoint _clientPoint;
  MapPoint? _userPoint;
  MapRoute? _currentRoute;
  List<MapMarker> _markers = [];

  // UI state
  bool _locationPermissionGranted = false;
  bool _isRouteVisible = false;

  // Services
  late Connectivity _connectivity;
  bool _isOnline = true;

  // Legacy variables for backward compatibility (to be removed)
  geolocator.Position? _userPosition;
  List<google_maps.LatLng> _routePoints = [];
  Set<google_maps.Polyline> _polylines = {};
  List<osm_latlong.LatLng> _osmRoutePoints = [];
  List<osm.Polyline> _osmPolylines = [];

  // Google Maps controller for legacy support
  google_maps.GoogleMapController? _googleMapController;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadDefaultMapProvider();
    _checkLocationPermission();
    _initializeConnectivity();
    _initializeMapData();
  }

  @override
  void dispose() {
    _locationManager.dispose();
    _routeManager.dispose();
    super.dispose();
  }

  /// Initialize core managers and services
  Future<void> _initializeServices() async {
    try {
      // Initialize core managers
      _locationManager = location_manager.LocationManager();
      await _locationManager.initialize();

      // Initialize route manager with services
      _routeManager = route_manager.RouteManager(
        routeService: route_service.RouteService(_defaultMapProvider),
        mapService: map_service.MapServiceFactory.createService(_defaultMapProvider),
        provider: _defaultMapProvider,
      );

      // Set up route events listener
      _routeManager.routeEvents.listen((event) {
        if (mounted) {
          setState(() {
            switch (event.type) {
              case route_manager.RouteEventType.created:
                _currentRoute = event.route;
                _isRouteVisible = true;
                break;
              case route_manager.RouteEventType.removed:
                _currentRoute = null;
                _isRouteVisible = false;
                break;
              case route_manager.RouteEventType.error:
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Route error: ${event.error}')),
                );
                break;
              default:
                break;
            }
          });
        }
      });

      // Initialize marker manager
      _markerManager = marker_manager.MarkerManager(
        config: marker_manager.MarkerClusterConfig(),
        provider: _defaultMapProvider,
      );

      if (kDebugMode) {
        print('Core managers initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing core managers: $e');
      }
    }
  }

  /// Initialize map data from trading point
  void _initializeMapData() {
    _clientPoint = MapPoint.fromTradingPoint(widget.tradingPoint);

    // Create client marker
    final clientMarker = MapMarker.fromTradingPoint(widget.tradingPoint);
    _markers = [clientMarker];

    // Set up map settings
    _mapSettings = MapSettings.defaultSinglePoint().copyWith(
      provider: _defaultMapProvider,
      defaultCenter: _clientPoint,
    );
  }

  /// Load default map provider from settings
  Future<void> _loadDefaultMapProvider() async {
    try {
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();
      final savedProvider = prefs.preferences.getString('default_map_provider');

      if (savedProvider != null) {
        setState(() {
          _defaultMapProvider = MapProvider.values.firstWhere(
            (provider) => provider.toString() == savedProvider,
            orElse: () => MapProvider.google,
          );
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading default map provider: $e');
      }
    }
  }

  /// Check and request location permission
  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;
    if (status.isGranted) {
      setState(() {
        _locationPermissionGranted = true;
      });
      _getUserLocation();
    } else {
      final result = await Permission.location.request();
      setState(() {
        _locationPermissionGranted = result.isGranted;
      });
      if (result.isGranted) {
        _getUserLocation();
      }
    }
  }

  /// Initialize connectivity monitoring
  Future<void> _initializeConnectivity() async {
    _connectivity = Connectivity();
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    if (mounted && wasOnline != _isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isOnline ? 'Internetga ulandi' : 'Offline rejim'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Get current user location using LocationManager
  Future<void> _getUserLocation() async {
    try {
      final locationData = await _locationManager.getCurrentLocation();
      if (locationData != null) {
        setState(() {
          _userPoint = locationData.toMapPoint();
        });
        _updateUserMarker();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user location: $e');
      }
    }
  }

  /// Update user location marker using MarkerManager
  void _updateUserMarker() {
    if (_userPoint == null) return;

    final userMarker = MapMarker.userLocation(_userPoint!);

    setState(() {
      // Remove existing user marker if any
      _markers.removeWhere((marker) => marker.type == MarkerType.user);
      // Add new user marker
      _markers.add(userMarker);
    });
  }

  /// Calculate and display route from user to client using RouteManager
  Future<void> _calculateRoute() async {
    try {
      if (kDebugMode) {
        print('Calculating route from user to client: ${widget.tradingPoint.name}');
      }

      if (_userPoint == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foydalanuvchi joylashuvi aniqlanmadi')),
        );
        return;
      }

      // Create route using RouteManager
      final route = await _routeManager.createRoute(
        points: [_userPoint!, _clientPoint],
        travelMode: TravelMode.driving,
        optimization: RouteOptimization.shortestTime,
        displayOnMap: true,
      );

      if (route != null) {
        setState(() {
          _currentRoute = route;
          _isRouteVisible = true;
        });

        // Fit camera to show the route
        _fitRouteBounds();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marshrut hisoblandi: ${route.formattedDistance}, ${route.formattedTime}')),
        );

        if (kDebugMode) {
          print('Route calculated successfully: ${route.id}');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marshrutni hisoblashda xatolik yuz berdi')),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating route: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marshrutni hisoblashda xatolik: $e')),
      );
    }
  }

  /// Fit camera to show route bounds
  void _fitRouteBounds() {
    if (_currentRoute == null) return;

    final bounds = _currentRoute!.bounds;
    // This will be handled by UnifiedMapWidget's fitBounds method
    // when we implement the camera controls
  }

  /// Clear current route
  void _clearRoute() {
    setState(() {
      _currentRoute = null;
      _isRouteVisible = false;
    });
    _routeManager.clearAllRoutes();
  }

  /// Move camera to specific point
  void _moveCameraToPoint(MapPoint point, {double? zoom}) {
    // For now, show message as camera control integration is in progress
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${point.title ?? 'Nuqta'} ga kamera o\'tkazildi')),
    );
  }

  /// Fit camera to show route bounds
  Future<void> _fitCameraToRoute(MapRoute route) async {
    if (route.points.length >= 2) {
      // Calculate bounds from route points
      final bounds = _calculateRouteBounds(route.points);
      // For now, show message as bounds fitting is in progress
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marshrut chegaralariga kamera moslandi')),
      );
    }
  }

  /// Calculate bounds for route points
  List<MapPoint> _calculateRouteBounds(List<MapPoint> points) {
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

  /// Navigate to fullscreen map page
  /// This method will open a fullscreen map view for better navigation experience
  /// TODO: Implement full functionality - currently shows placeholder message
  void _openFullscreenMap() {
    try {
      if (kDebugMode) {
        print('Opening fullscreen map for client: ${widget.tradingPoint.name}');
      }

      // TODO: Implement fullscreen map navigation
      // This will open a fullscreen map view
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('To\'liq ekran xaritasi ochiladi')),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error opening fullscreen map: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: $e')),
      );
    }
  }

  /// Navigate to update client coordinates page
  /// This method will open a page where user can update client coordinates
  /// and send the updated coordinates to the server via API
  /// TODO: Implement full functionality - currently shows placeholder message
  void _openUpdateCoordinatesPage() {
    try {
      if (kDebugMode) {
        print('Opening update coordinates page for client: ${widget.tradingPoint.name}');
      }

      // TODO: Implement update coordinates page navigation
      // This will open a page to update client coordinates and send to server
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koordinatalarni yangilash sahifasi ochiladi')),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error opening update coordinates page: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: $e')),
      );
    }
  }

  /// Build unified map widget with control overlays
  Widget _buildMapWidget() {
    return Stack(
      children: [
        // Main map widget using UnifiedMapWidget
        UnifiedMapWidget(
          provider: _defaultMapProvider,
          settings: _mapSettings,
          initialMarkers: _markers,
          initialRoutes: _currentRoute != null ? [_currentRoute!] : [],
          enableLocation: true,
          enableRouting: true,
          enableClustering: false, // Single point view
          onMapReady: () {
            if (kDebugMode) {
              print('Unified map is ready for client: ${widget.tradingPoint.name}');
            }
          },
          onMarkerTap: (marker) {
            if (kDebugMode) {
              print('Marker tapped: ${marker.title}');
            }
          },
          onLocationUpdate: (location) {
            if (mounted) {
              setState(() {
                _userPoint = location.toMapPoint();
              });
              _updateUserMarker();
            }
          },
        ),

        // Control overlays
        _buildControlOverlays(),
      ],
    );
  }

  /// Build control icons overlay
  Widget _buildControlOverlays() {
    return Stack(
      children: [
        // Bottom-right controls (4 icons)
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. User position button
                IconButton(
                  onPressed: _locationPermissionGranted ? () {
                    if (_userPoint != null) {
                      // TODO: Implement camera movement to user position
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Foydalanuvchi joylashuviga o\'tish')),
                      );
                    } else {
                      _getUserLocation();
                    }
                  } : null,
                  icon: Icon(
                    Icons.my_location,
                    color: _locationPermissionGranted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  tooltip: 'Foydalanuvchi joylashuvi',
                ),

                // 2. Client position button
                IconButton(
                  onPressed: () {
                    // TODO: Implement camera movement to client position
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mijoz joylashuviga o\'tish')),
                    );
                  },
                  icon: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                  tooltip: 'Mijoz joylashuvi',
                ),

                // 3. Route button
                IconButton(
                  onPressed: () async {
                    if (_userPoint != null) {
                      try {
                        final route = await _routeManager.createRoute(
                          points: [_userPoint!, _clientPoint],
                          travelMode: TravelMode.driving,
                          displayOnMap: true,
                        );

                        if (route != null) {
                          // Fit camera to show both points
                          await _fitCameraToRoute(route);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Marshrut muvaffaqiyatli hisoblandi')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Marshrut hisoblashda xatolik: $e')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Foydalanuvchi joylashuvi aniqlanmadi')),
                      );
                    }
                  },
                  icon: Icon(Icons.route, color: Theme.of(context).colorScheme.primary),
                  tooltip: 'Marshrut (foydalanuvchidan mijozgacha)',
                ),

                // 4. Fullscreen button
                IconButton(
                  onPressed: () {
                    // TODO: Implement fullscreen map navigation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('To\'liq ekran xaritasi - amalga oshirilmoqda')),
                    );
                  },
                  icon: Icon(Icons.fullscreen, color: Theme.of(context).colorScheme.primary),
                  tooltip: 'To\'liq ekran xaritasi',
                ),
              ],
            ),
          ),
        ),

        // Top-right control (1 icon)
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _openUpdateCoordinatesPage,
              icon: Icon(Icons.edit_location, color: Theme.of(context).colorScheme.primary),
              tooltip: 'Mijoz koordinatalarini yangilash',
            ),
          ),
        ),

        // Route info overlay (if route is active)
        if (_isRouteVisible && _currentRoute != null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.route, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Marshrut: ${_currentRoute!.formattedDistance}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Vaqt: ${_currentRoute!.formattedTime}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _clearRoute,
                    icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
                    tooltip: 'Marshrutni yopish',
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tradingPoint.name),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: Stack(
        children: [
          // Map widget
          _buildMapWidget(),

          // Control buttons overlay - Yandex Map style positioning
          // Bottom-right controls (4 icons)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. User position button (top in bottom-right group)
                  IconButton(
                    onPressed: _locationPermissionGranted ? () {
                      if (_userPoint != null) {
                        // Use UnifiedMapWidget's moveCamera method
                        // TODO: Implement camera movement through UnifiedMapWidget
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Foydalanuvchi joylashuviga kamera o\'tkazildi')),
                        );
                      } else {
                        _getUserLocation();
                      }
                    } : null,
                    icon: Icon(
                      Icons.my_location,
                      color: _locationPermissionGranted ? cs.primary : cs.onSurface.withOpacity(0.3),
                    ),
                    tooltip: 'Foydalanuvchi joylashuvi',
                  ),

                  // 2. Client position button
                  IconButton(
                    onPressed: () {
                      // Use UnifiedMapWidget's moveCamera method
                      // TODO: Implement camera movement through UnifiedMapWidget
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mijoz joylashuviga kamera o\'tkazildi')),
                      );
                    },
                    icon: Icon(Icons.location_on, color: cs.primary),
                    tooltip: 'Mijoz joylashuvi',
                  ),

                  // 3. Route button
                  IconButton(
                    onPressed: _calculateRoute,
                    icon: Icon(Icons.route, color: cs.primary),
                    tooltip: 'Marshrut (foydalanuvchidan mijozgacha)',
                  ),

                  // 4. Fullscreen button
                  IconButton(
                    onPressed: _openFullscreenMap,
                    icon: Icon(Icons.fullscreen, color: cs.primary),
                    tooltip: 'To\'liq ekran xaritasi',
                  ),
                ],
              ),
            ),
          ),

          // Top-right control (1 icon)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _openUpdateCoordinatesPage,
                icon: Icon(Icons.edit_location, color: cs.primary),
                tooltip: 'Mijoz koordinatalarini yangilash',
              ),
            ),
          ),

          // Route info overlay (if route is active)
          if (_isRouteVisible && _currentRoute != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.route, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Marshrut: ${_currentRoute!.formattedDistance}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Vaqt: ${_currentRoute!.formattedTime}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _clearRoute,
                      icon: Icon(Icons.close, color: cs.onSurface),
                      tooltip: 'Marshrutni yopish',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}