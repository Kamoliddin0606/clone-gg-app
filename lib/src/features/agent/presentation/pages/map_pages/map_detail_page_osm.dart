import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_map/flutter_map.dart' as osm;
import 'package:latlong2/latlong.dart' as osm_latlong;
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;
import 'package:gloria_marketing_flutter/src/theme/theme_controller.dart';

// Constants for map configuration
const double kDefaultZoom = 15.0;
const double kRouteZoom = 16.0;
const String kOsmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const String kUserAgent = 'uz.gg.gloria_marketing';

/// OSM (OpenStreetMap) full-screen map detail page
/// This page displays the client's location on OpenStreetMap in full-screen mode
/// with state preservation and proper UI design matching the app theme
class MapDetailPageOsm extends StatefulWidget {
  final model.TradingPoint tradingPoint;

  const MapDetailPageOsm({
    super.key,
    required this.tradingPoint,
  });

  @override
  State<MapDetailPageOsm> createState() => _MapDetailPageOsmState();
}

class _MapDetailPageOsmState extends State<MapDetailPageOsm> {
  // Map controller
  late final osm.MapController _osmController;

  // Camera state management
  double? _lastZoom;

  // Map data
  late osm_latlong.LatLng _clientPoint;
  osm_latlong.LatLng? _userPoint;
  List<osm_latlong.LatLng>? _currentRoute;
  List<osm.Marker> _markers = [];

  // UI state
  bool _locationPermissionGranted = false;
  bool _isRouteVisible = false;

  // Services
  late Connectivity _connectivity;
  bool _isOnline = true;

  // Theme management
  late final ThemeController _themeController;
  late VoidCallback _themeListener;

  @override
  void initState() {
    super.initState();
    _osmController = osm.MapController();
    _initializeThemeController();
    _initializeServices();
    _checkLocationPermission();
    _initializeMapData();
    _initializeCameraState();
  }

  @override
  void dispose() {
    _themeController.mode.removeListener(_themeListener);
    super.dispose();
  }

  /// Initialize theme controller and set up theme mode listener
  void _initializeThemeController() {
    _themeController = ThemeController.I;
    _themeListener = () {
      if (mounted) {
        setState(() {});
      }
    };
    _themeController.mode.addListener(_themeListener);
  }

  /// Initialize services - simplified without custom managers
  /// Sets up connectivity monitoring for offline/online status
  Future<void> _initializeServices() async {
    try {
      // Initialize connectivity monitoring
      _connectivity = Connectivity();
      _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

      final result = await _connectivity.checkConnectivity();
      _isOnline = result != ConnectivityResult.none;

      if (kDebugMode) {
        print('Services initialized successfully. Online status: $_isOnline');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing services: $e');
      }
      // Continue without connectivity monitoring if it fails
      _isOnline = true;
    }
  }

  /// Initialize map data from trading point
  void _initializeMapData() {
    // Create client point from trading point coordinates
    _clientPoint = osm_latlong.LatLng(
      widget.tradingPoint.latitude ?? 41.2995, // Default to Tashkent if no coordinates
      widget.tradingPoint.longitude ?? 69.2401,
    );

    // Create client marker
    final clientMarker = osm.Marker(
      width: 40.0,
      height: 40.0,
      alignment: Alignment.bottomCenter,
      point: _clientPoint,
      child: const Icon(
        Icons.location_on,
        color: Colors.red,
        size: 40,
      ),
    );
    _markers = [clientMarker];
  }

  /// Initialize camera state for position and zoom tracking
  void _initializeCameraState() {
    _lastZoom = kDefaultZoom; // Default zoom level
  }

  /// Check and request location permission
  /// Handles permission states and provides user feedback
  Future<void> _checkLocationPermission() async {
    try {
      if (kDebugMode) {
        print('Checking location permission...');
      }

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
        } else {
          if (kDebugMode) {
            print('Location permission denied');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joylashuv ruxsatnomasi berilmadi')),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking location permission: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ruxsatnoma tekshirishda xatolik: $e')),
      );
    }
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

  /// Get current user location using Geolocator directly
  Future<void> _getUserLocation() async {
    try {
      if (kDebugMode) {
        print('Getting user location...');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userPoint = osm_latlong.LatLng(position.latitude, position.longitude);
      });
      _updateUserMarker();

      if (kDebugMode) {
        print('User location obtained: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user location: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joylashuvni aniqlashda xatolik: $e')),
      );
    }
  }

  /// Update user location marker directly
  void _updateUserMarker() {
    if (_userPoint == null) return;

    final userMarker = osm.Marker(
      width: 30.0,
      height: 30.0,
      alignment: Alignment.bottomCenter,
      point: _userPoint!,
      child: const Icon(
        Icons.my_location,
        color: Colors.blue,
        size: 30,
      ),
    );

    setState(() {
      // Remove existing user marker if any (identified by blue color icon)
      _markers.removeWhere((marker) =>
          marker.child is Icon &&
          (marker.child as Icon).icon == Icons.my_location);
      // Add new user marker
      _markers.add(userMarker);
    });

    if (kDebugMode) {
      print('User marker updated at: ${_userPoint!.latitude}, ${_userPoint!.longitude}');
    }
  }

  /// Calculate and display simple straight line route from user to client
  /// Note: For full routing functionality, integrate with a routing service like OSRM
  Future<void> _calculateRoute() async {
    try {
      if (kDebugMode) {
        print('Creating straight line route from user to client: ${widget.tradingPoint.name}');
      }

      if (_userPoint == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foydalanuvchi joylashuvi aniqlanmadi')),
        );
        return;
      }

      // Create simple straight line route (2 points)
      final routePoints = [_userPoint!, _clientPoint];

      setState(() {
        _currentRoute = routePoints;
        _isRouteVisible = true;
      });

      // Fit camera to show the route
      _fitRouteBounds();

      // Calculate approximate distance and time
      final distance = _calculateDistance(_userPoint!, _clientPoint);
      final estimatedTime = _estimateTravelTime(distance);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('To\'g\'ri chiziq marshrut: ${distance.toStringAsFixed(1)} km, taxminiy ${estimatedTime}')),
      );

      if (kDebugMode) {
        print('Straight line route created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating route: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marshrut yaratishda xatolik: $e')),
      );
    }
  }

  /// Fit camera to show route bounds
  Future<void> _fitRouteBounds() async {
    if (_currentRoute == null || _currentRoute!.isEmpty) return;

    try {
      // Calculate bounds from route points
      final points = _currentRoute!;
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;

      for (final point in points) {
        minLat = min(minLat, point.latitude);
        maxLat = max(maxLat, point.latitude);
        minLng = min(minLng, point.longitude);
        maxLng = max(maxLng, point.longitude);
      }

      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;

      // Calculate zoom level based on bounds
      final latDiff = maxLat - minLat;
      final lngDiff = maxLng - minLng;
      final maxDiff = max(latDiff.abs(), lngDiff.abs());
      final zoom = max(0.0, 16.0 - log(maxDiff * 111000) / log(2));

      // Move to center with calculated zoom
      _osmController.move(osm_latlong.LatLng(centerLat, centerLng), zoom);

      if (kDebugMode) {
        print('Fitted camera to route bounds: ${points.length} points');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fitting route bounds: $e');
      }
    }
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(osm_latlong.LatLng point1, osm_latlong.LatLng point2) {
    const double earthRadius = 6371; // km
    final lat1Rad = point1.latitude * pi / 180;
    final lat2Rad = point2.latitude * pi / 180;
    final deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLngRad = (point2.longitude - point1.longitude) * pi / 180;

    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Estimate travel time based on distance (assuming average speed of 40 km/h in city)
  String _estimateTravelTime(double distanceKm) {
    const double averageSpeedKmh = 40.0;
    final timeHours = distanceKm / averageSpeedKmh;
    final timeMinutes = (timeHours * 60).round();

    if (timeMinutes < 60) {
      return '$timeMinutes daqiqa';
    } else {
      final hours = timeMinutes ~/ 60;
      final minutes = timeMinutes % 60;
      return '$hours soat ${minutes > 0 ? '$minutes daqiqa' : ''}';
    }
  }

  /// Clear current route
  void _clearRoute() {
    setState(() {
      _currentRoute = null;
      _isRouteVisible = false;
    });

    if (kDebugMode) {
      print('Route cleared');
    }
  }

  /// Move camera to specific point with proper controller usage
  void _moveCameraToPoint(osm_latlong.LatLng point, {double? zoom}) {
    try {
      final targetZoom = zoom ?? _lastZoom ?? kDefaultZoom;
      final targetPosition = point;

      _osmController.move(targetPosition, targetZoom);

      // Update state for tracking
      _lastZoom = targetZoom;

      if (kDebugMode) {
        print('Camera moved to: ${point.latitude}, ${point.longitude} with zoom: $targetZoom');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error moving camera: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kamera harakatida xatolik: $e')),
      );
    }
  }

  /// Navigate to update client coordinates page
  /// Currently shows a placeholder message as the feature is not yet implemented
  void _openUpdateCoordinatesPage() {
    try {
      if (kDebugMode) {
        print('Opening update coordinates page for client: ${widget.tradingPoint.name}');
      }

      // TODO: Implement update coordinates page navigation
      // This would typically navigate to a page where user can update trading point coordinates
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koordinatalarni yangilash sahifasi - tez orada')),
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

  /// Build OSM map widget with markers, polylines, and control overlays
  /// This widget displays the interactive map with all visual elements
  Widget _buildOsmMapWidget() {
    return Stack(
      children: [
        // Main OSM map widget
        osm.FlutterMap(
          mapController: _osmController,
          options: osm.MapOptions(
            initialCenter: _clientPoint,
            initialZoom: kDefaultZoom,
            onMapReady: () {
              if (kDebugMode) {
                print('OSM map is ready for client: ${widget.tradingPoint.name}');
              }
            },
          ),
          children: [
            osm.TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const [],
              userAgentPackageName: 'uz.gg.gloria_marketing',
              maxZoom: 19,
              minZoom: 1,
              errorTileCallback: (tile, error, stackTrace) {
                if (kDebugMode) {
                  print('OSM tile error: ${tile.toString()} - $error');
                }
              },
            ),
            osm.MarkerLayer(
              markers: [
                osm.Marker(
                  width: 40.0,
                  height: 40.0,
                  alignment: Alignment.bottomCenter,
                  point: osm_latlong.LatLng(_clientPoint.latitude, _clientPoint.longitude),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
                if (_userPoint != null)
                  osm.Marker(
                    width: 30.0,
                    height: 30.0,
                    alignment: Alignment.bottomCenter,
                    point: osm_latlong.LatLng(_userPoint!.latitude, _userPoint!.longitude),
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ),
              ],
            ),
            if (_currentRoute != null)
              osm.PolylineLayer(
                polylines: [
                  osm.Polyline(
                    points: _currentRoute!,
                    strokeWidth: 4.0,
                    color: Colors.blue,
                  ),
                ],
              ),
          ],
        ),

        // Control overlays
        _buildControlOverlays(),
      ],
    );
  }

  /// Build control icons overlay with navigation and action buttons
  /// Provides user interface controls for map interaction
  Widget _buildControlOverlays() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    // Responsive icon size
    final iconSize = screenSize.width > 600 ? 32.0 : 28.0;

    return Stack(
      children: [
        // Top-left back button
        Positioned(
          top: 16,
          left: 16,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(isDark ? 0.95 : 0.9).withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outline.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.4)
                        : Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back,
                color: cs.onSurface,
                size: iconSize,
              ),
            ),
          ),
        ),

        // Bottom-right controls
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User position button
              Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(isDark ? 0.95 : 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.outline.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.4)
                          : Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _locationPermissionGranted ? () async {
                    if (_userPoint != null && _osmController != null) {
                      _osmController!.move(
                        osm_latlong.LatLng(_userPoint!.latitude, _userPoint!.longitude),
                        16.0,
                      );
                    } else {
                      await _getUserLocation();
                    }
                  } : null,
                  iconSize: iconSize,
                  icon: Icon(
                    Icons.my_location,
                    color: _locationPermissionGranted
                        ? cs.primary
                        : cs.onSurface.withOpacity(0.4),
                  ),
                  tooltip: 'Foydalanuvchi joylashuvi',
                ),
              ),

              // Client position button
              Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(isDark ? 0.95 : 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.outline.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.4)
                          : Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () async {
                    if (_osmController != null) {
                      _osmController!.move(
                        osm_latlong.LatLng(_clientPoint.latitude, _clientPoint.longitude),
                        16.0,
                      );
                    }
                  },
                  iconSize: iconSize,
                  icon: Icon(Icons.location_on, color: cs.primary),
                  tooltip: 'Mijoz joylashuvi',
                ),
              ),

              // Route button
              Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(isDark ? 0.95 : 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.outline.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.4)
                          : Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () async {
                    if (_userPoint != null) {
                      await _calculateRoute();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Foydalanuvchi joylashuvi aniqlanmadi')),
                      );
                    }
                  },
                  iconSize: iconSize,
                  icon: Icon(Icons.route, color: cs.primary),
                  tooltip: 'Marshrut (foydalanuvchidan mijozgacha)',
                ),
              ),

              // Update coordinates button (top-right)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(isDark ? 0.95 : 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.outline.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.4)
                          : Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _openUpdateCoordinatesPage,
                  iconSize: iconSize,
                  icon: Icon(Icons.edit_location_outlined, color: cs.primary),
                  tooltip: 'Mijoz joylashuvini o\'zgartirish',
                ),
              ),
            ],
          ),
        ),

        // Route info overlay (if route is active)
        if (_isRouteVisible && _currentRoute != null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(isDark ? 0.95 : 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outline.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.4)
                        : Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.route, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Masofa: ${_calculateDistance(_userPoint!, _clientPoint).toStringAsFixed(1)} km',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Taxminiy vaqt: ${_estimateTravelTime(_calculateDistance(_userPoint!, _clientPoint))}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _clearRoute,
                    icon: Icon(Icons.close, color: cs.onSurface.withOpacity(0.7)),
                    tooltip: 'Marshrutni yopish',
                    style: IconButton.styleFrom(
                      backgroundColor: cs.surfaceVariant.withOpacity(0.5),
                      foregroundColor: cs.onSurface,
                    ),
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
    return Scaffold(
      body: _buildOsmMapWidget(),
    );
  }
}