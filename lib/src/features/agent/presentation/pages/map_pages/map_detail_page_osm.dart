import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_map/flutter_map.dart' as osm;
import 'package:latlong2/latlong.dart' as osm_latlong;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart'
    as model;
import 'package:gloria_marketing_flutter/src/theme/theme_controller.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/network/server_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/permission_manager.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:dio/dio.dart';

// Constants for map configuration
const double kDefaultZoom = 15.0;
const double kRouteZoom = 16.0;
const String kOsmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const String kUserAgent = 'uz.gg.gloria_marketing';

/// OSM (OpenStreetMap) full-screen map detail page with routing functionality
/// This page displays the client's location on OpenStreetMap in full-screen mode
/// with state preservation and proper UI design matching the app theme.
/// Features:
/// - Real-time routing using OpenRouteService API
/// - Multiple transport modes: car, walking, bicycle
/// - Interactive route calculation with loading states
/// - Error handling and fallback to straight-line routes
/// - Permission-based location editing
/// - Theme-aware UI components
class MapDetailPageOsm extends StatefulWidget {
  final model.TradingPoint tradingPoint;

  const MapDetailPageOsm({super.key, required this.tradingPoint});

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
  bool _isEditMode = false;
  bool _isConfirmingLocation = false;
  bool _isPreciseMode = false; // Long press bilan aniq joylashuv tanlash rejimi
  osm_latlong.LatLng? _newClientLocation;
  osm_latlong.LatLng? _previewLocation;
  bool _showTapFeedback = false;
  Offset _tapPosition = Offset.zero;

  // Routing state
  bool _isCalculatingRoute = false;
  String _selectedTransportMode = 'driving-car'; // Default transport mode
  bool _showTransportModes = false; // Show/hide transport mode selection

  // Route data from API
  List<Map<String, dynamic>>? _routeInstructions; // Turn-by-turn instructions
  osm_latlong.LatLng? _startMarkerPoint; // Start marker from way_points[0]
  osm_latlong.LatLng? _endMarkerPoint; // End marker from way_points[18]

  // Services
  late Connectivity _connectivity;
  bool _isOnline = true;
  late final SharedPreferencesService _prefs;
  late final DataSyncService _dataSyncService;

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

      // Initialize shared preferences and data sync services
      _prefs = await SharedPreferencesService.getInstance();
      _dataSyncService = sl<DataSyncService>();

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
      widget.tradingPoint.latitude ??
          41.2995, // Default to Tashkent if no coordinates
      widget.tradingPoint.longitude ?? 69.2401,
    );

    // Create client marker
    final clientMarker = osm.Marker(
      width: 40.0,
      height: 40.0,
      alignment: Alignment.bottomCenter,
      point: _clientPoint,
      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
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

      final permissionManager = sl<PermissionManager>();
      final status = await permissionManager.checkLocationPermission();
      if (status == AppPermissionStatus.granted) {
        setState(() {
          _locationPermissionGranted = true;
        });
        _getUserLocation();
      } else {
        final result = await permissionManager.requestLocationPermission();
        setState(() {
          _locationPermissionGranted = result == AppPermissionStatus.granted;
        });
        if (result == AppPermissionStatus.granted) {
          _getUserLocation();
        } else {
          if (kDebugMode) {
            print('Location permission denied');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.locationPermissionDenied ??
                    'Joylashuv ruxsatnomasi berilmadi',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking location permission: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)?.errorOccurredPrefix ?? 'Xatolik'}: $e',
          ),
        ),
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
        print(
          'User location obtained: ${position.latitude}, ${position.longitude}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user location: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)?.errorOccurredPrefix ?? 'Xatolik'}: $e',
          ),
        ),
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
      child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
    );

    setState(() {
      // Remove existing user marker if any (identified by blue color icon)
      _markers.removeWhere(
        (marker) =>
            marker.child is Icon &&
            (marker.child as Icon).icon == Icons.my_location,
      );
      // Add new user marker
      _markers.add(userMarker);
    });

    if (kDebugMode) {
      print(
        'User marker updated at: ${_userPoint!.latitude}, ${_userPoint!.longitude}',
      );
    }
  }

  /// Calculate and display route from user to client using OpenRouteService
  /// Supports different transport modes: driving-car, foot-walking, cycling-regular
  /// Falls back to straight-line route if API fails
  /// Updates UI with loading states and route information
  Future<void> _calculateRoute() async {
    if (_userPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.userLocationNotFound ??
                'Foydalanuvchi joylashuvi aniqlanmadi',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
    });

    try {
      if (kDebugMode) {
        print(
          'Calculating route from user to client using OpenRouteService: ${widget.tradingPoint.name}',
        );
        print('Transport mode: $_selectedTransportMode');
      }

      // Get route from OpenRouteService
      final routeData = await _getRouteFromOpenRouteService(
        start: _userPoint!,
        end: _clientPoint,
        profile: _selectedTransportMode,
      );

      if (routeData != null && routeData['coordinates'] != null) {
        // Use decoded coordinates directly
        final routePoints =
            routeData['coordinates'] as List<osm_latlong.LatLng>;

        // Extract way points for start/end markers
        final wayPoints =
            routeData['way_points'] as List<osm_latlong.LatLng>? ?? [];
        osm_latlong.LatLng? startPoint;
        osm_latlong.LatLng? endPoint;

        if (wayPoints.isNotEmpty) {
          startPoint = wayPoints[0]; // way_points[0] - start marker
          if (wayPoints.length > 1) {
            endPoint = wayPoints.last; // Last way point - end marker
          }
        }

        // Extract instructions
        final instructions =
            routeData['instructions'] as List<Map<String, dynamic>>? ?? [];

        setState(() {
          _currentRoute = routePoints;
          _isRouteVisible = true;
          _isCalculatingRoute = false;
          _startMarkerPoint = startPoint;
          _endMarkerPoint = endPoint;
          _routeInstructions = instructions;
        });

        // Always fit bounds after successful route calculation
        _fitRouteBoundsFromApi(routeData['bbox']);

        // Calculate distance and time from API response
        final distanceKm =
            (routeData['summary']['distance'] as num?)?.toDouble() ?? 0.0;
        final durationSec =
            (routeData['summary']['duration'] as num?)?.toDouble() ?? 0.0;

        final distance = distanceKm / 1000; // Convert to km
        final estimatedTime = _formatDuration(durationSec);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Marshrut: ${distance.toStringAsFixed(1)} km, taxminiy ${estimatedTime}',
            ),
          ),
        );

        if (kDebugMode) {
          print(
            'Route calculated successfully with ${routePoints.length} points, ${instructions.length} instructions',
          );
        }
      } else {
        // Fallback to straight line route if API fails
        _createFallbackRoute();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating route with OpenRouteService: $e');
      }
      // Fallback to straight line route
      _createFallbackRoute();
    }
  }

  /// Create fallback straight line route when API fails
  void _createFallbackRoute() {
    final routePoints = [_userPoint!, _clientPoint];

    setState(() {
      _currentRoute = routePoints;
      _isRouteVisible = true;
      _isCalculatingRoute = false;
    });

    // Always fit bounds after successful route calculation
    _fitRouteBounds();

    // Calculate approximate distance and time
    final distance = _calculateDistance(_userPoint!, _clientPoint);
    final estimatedTime = _estimateTravelTime(distance);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'To\'g\'ri chiziq marshrut: ${distance.toStringAsFixed(1)} km, taxminiy ${estimatedTime}',
        ),
      ),
    );
  }

  /// Get route from OpenRouteService API
  /// Makes HTTP request to OpenRouteService with proper error handling
  /// Returns route coordinates, summary information, instructions, and way points
  Future<Map<String, dynamic>?> _getRouteFromOpenRouteService({
    required osm_latlong.LatLng start,
    required osm_latlong.LatLng end,
    required String profile,
  }) async {
    try {
      if (kDebugMode) {
        print("Requesting route with profile: $profile");
      }

      final url =
          'https://api.openrouteservice.org/v2/directions/$profile/geojson';
      final apiKey =
          'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImNiNDlhOTk0OGRhOTQ5ZjRiMWQ5ZGVhYWJiMDVkODg3IiwiaCI6Im11cm11cjY0In0='; // Replace with actual API key

      final startCoords = [start.longitude, start.latitude];
      final endCoords = [end.longitude, end.latitude];

      final response = await Dio().post(
        url,
        options: Options(
          headers: {
            'Authorization': apiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'coordinates': [startCoords, endCoords],
          // 'format': 'geojson',
          'instructions': true, // Enable turn-by-turn instructions
          'geometry_simplify': false, // More accurate geometry
          // 'geometry_format': 'geojson', // GeoJSON format for geometry
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (kDebugMode) {
          print('OpenRouteService response received');
        }
        if (kDebugMode) print(data);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final feature = data['features'][0];
          final geometry = feature['geometry'];
          final properties = feature['properties'];

          // Decode polyline using flutter_polyline_points
          List<osm_latlong.LatLng> decodedPoints = [];
          if (geometry['coordinates'] != null) {
            final coordinates = geometry['coordinates'] as List;
            decodedPoints = coordinates.map((coord) {
              final lng = coord[0] as double;
              final lat = coord[1] as double;
              return osm_latlong.LatLng(lat, lng);
            }).toList();
          }

          // Extract way points for start/end markers
          List<osm_latlong.LatLng> wayPoints = [];
          if (properties['way_points'] != null) {
            final wayPointIndices = properties['way_points'] as List;
            for (int index in wayPointIndices) {
              if (index < decodedPoints.length) {
                wayPoints.add(decodedPoints[index]);
              }
            }
          }

          // Extract turn-by-turn instructions
          List<Map<String, dynamic>> instructions = [];
          if (properties['segments'] != null &&
              properties['segments'].isNotEmpty) {
            final segments = properties['segments'] as List;
            final segment = segments[0];
            if (segment['steps'] != null) {
              instructions = (segment['steps'] as List).map((step) {
                return {
                  'instruction': step['instruction'] ?? '',
                  'type': step['type'] ?? 0,
                  'distance': step['distance'] ?? 0.0,
                  'duration': step['duration'] ?? 0.0,
                  'way_points': step['way_points'] ?? [],
                };
              }).toList();
            }
          }
          if (kDebugMode) {
            print(
              "________________API dan olingan ma'lumotlar_____________________",
            );
            print(decodedPoints);
            print(wayPoints);
            print(instructions);
            print(properties['bbox'] ?? data['bbox']);
          }

          return {
            'coordinates': decodedPoints,
            'way_points': wayPoints,
            'bbox': properties['bbox'] ?? data['bbox'],
            'summary': properties['summary'] ?? {'distance': 0, 'duration': 0},
            'instructions': instructions,
          };
        }
      } else {
        if (kDebugMode) {
          print('OpenRouteService API error: ${response.statusCode}');
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('OpenRouteService API error: $e');
      }
      return null;
    }
  }

  /// Format duration from seconds to readable format
  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes daqiqa';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours soat ${remainingMinutes > 0 ? '$remainingMinutes daqiqa' : ''}';
    }
  }

  /// Fit camera to show route bounds using flutter_map's built-in fitBounds
  /// Ignores API bbox and uses actual route points for accurate fitting
  void _fitBoundsToRoute(List<osm_latlong.LatLng> points) {
    if (points.isEmpty) return;

    // Handle single point case
    if (points.length == 1) {
      _osmController.move(points.first, 16.0);
      _lastZoom = 16.0;
      if (kDebugMode) {
        print(
          'Fitted camera to single point: ${points.first.latitude}, ${points.first.longitude} with zoom: 16.0',
        );
      }
      return;
    }

    final bounds = osm.LatLngBounds.fromPoints(points);
    const padding = EdgeInsets.fromLTRB(
      16,
      120,
      16,
      100,
    ); // Account for overlays

    // Calculate center and zoom manually for compatibility
    final centerLat = (bounds.north + bounds.south) / 2;
    final centerLng = (bounds.east + bounds.west) / 2;

    // Calculate zoom level based on bounds and padding
    final latDiff = bounds.north - bounds.south;
    final lngDiff = bounds.east - bounds.west;
    final maxDiff = max(latDiff.abs(), lngDiff.abs());

    // Adjust for padding (approximate)
    final adjustedLatDiff =
        latDiff +
        (padding.top + padding.bottom) / 111000; // meters to degrees approx
    final adjustedLngDiff = lngDiff + (padding.left + padding.right) / 111000;
    final adjustedMaxDiff = max(adjustedLatDiff.abs(), adjustedLngDiff.abs());

    // Calculate zoom: smaller area = higher zoom
    double zoom;
    if (adjustedMaxDiff < 0.001) {
      // Very close points (< 100m approx)
      zoom = 18.0;
    } else if (adjustedMaxDiff < 0.01) {
      // Close points (< 1km approx)
      zoom = 16.0;
    } else if (adjustedMaxDiff < 0.1) {
      // Medium distance (< 10km approx)
      zoom = 14.0;
    } else if (adjustedMaxDiff < 1.0) {
      // Large distance (< 100km approx)
      zoom = 12.0;
    } else {
      // Very large distance
      zoom = 10.0;
    }

    // Ensure zoom is within reasonable bounds
    zoom = zoom.clamp(3.0, 19.0);

    _osmController.move(osm_latlong.LatLng(centerLat, centerLng), zoom);
    _lastZoom = zoom;

    if (kDebugMode) {
      print(
        'Fitted bounds for ${points.length} points, zoom: $zoom, center: $centerLat, $centerLng',
      );
    }
  }

  /// Fit camera to show route bounds using API bbox (refactored to use helper)
  Future<void> _fitRouteBoundsFromApi(dynamic bbox) async {
    if (_currentRoute == null || _currentRoute!.isEmpty) return;
    _fitBoundsToRoute(_currentRoute!);
  }

  /// Fit camera to show route bounds (refactored to use helper)
  Future<void> _fitRouteBounds() async {
    if (_currentRoute == null || _currentRoute!.isEmpty) return;
    _fitBoundsToRoute(_currentRoute!);
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(
    osm_latlong.LatLng point1,
    osm_latlong.LatLng point2,
  ) {
    const double earthRadius = 6371; // km
    final lat1Rad = point1.latitude * pi / 180;
    final lat2Rad = point2.latitude * pi / 180;
    final deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLngRad = (point2.longitude - point1.longitude) * pi / 180;

    final a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
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
      _routeInstructions = null;
      _startMarkerPoint = null;
      _endMarkerPoint = null;
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
        print(
          'Camera moved to: ${point.latitude}, ${point.longitude} with zoom: $targetZoom',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error moving camera: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)?.errorOccurredPrefix ?? 'Xatolik'}: $e',
          ),
        ),
      );
    }
  }

  /// Toggle edit location mode
  /// When activated, allows user to drag the client marker to a new location
  /// Checks user permissions before allowing location editing
  Future<void> _toggleEditLocationMode() async {
    try {
      // Check user permissions for editing client coordinates
      final userCode = _prefs.getUserCode();
      if (userCode == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.userDataNotFound ??
                  'Foydalanuvchi ma\'lumotlari topilmadi',
            ),
          ),
        );
        return;
      }

      // Get user permissions from data sync service
      final permissions = await _dataSyncService.getCachedSalesReqPermissions(
        userCode,
      );
      if (permissions == null || !permissions.editClientCoordinates) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sizda mijoz joylashuvini o\'zgartirish uchun ruxsat yo\'q',
            ),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Permission granted - proceed with edit mode toggle
      setState(() {
        _isEditMode = !_isEditMode;
        if (!_isEditMode) {
          // Exit edit mode - reset any pending changes
          _newClientLocation = null;
          _isConfirmingLocation = false;
          _isPreciseMode = false;
        } else {
          // Enter edit mode - center camera on client marker
          _moveCameraToPoint(_clientPoint, zoom: kRouteZoom);
        }
      });

      if (kDebugMode) {
        print('Edit location mode: ${_isEditMode ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking permissions for edit location mode: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)?.errorOccurredPrefix ?? 'Xatolik'}: $e',
          ),
        ),
      );
    }
  }

  /// Toggle transport mode selection visibility
  void _toggleTransportModes() {
    setState(() {
      _showTransportModes = !_showTransportModes;
      // Clear route when hiding transport modes
      if (!_showTransportModes && !_isRouteVisible) {
        _clearRoute();
      }
    });
  }

  /// Select transport mode for routing
  /// Updates the selected transport mode and recalculates route if active
  void _selectTransportMode(String mode) {
    setState(() {
      _selectedTransportMode = mode;
      // Keep transport modes visible after selection
      // _showTransportModes = false;
    });

    // Recalculate route if one is currently visible
    if (_isRouteVisible && _userPoint != null) {
      _calculateRoute();
    }
  }

  /// Get icon for transport mode
  IconData _getTransportModeIcon(String mode) {
    switch (mode) {
      case 'driving-car':
        return Icons.directions_car;
      case 'foot-walking':
        return Icons.directions_walk;
      case 'cycling-regular':
      case 'cycling-road':
      case 'cycling-mountain':
      case 'cycling-safe':
        return Icons.directions_bike;
      default:
        return Icons.directions_car;
    }
  }

  /// Get display name for transport mode
  String _getTransportModeName(String mode) {
    switch (mode) {
      case 'driving-car':
        return 'Mashina';
      case 'foot-walking':
        return 'Piyoda';
      case 'cycling-regular':
        return 'Velosiped';
      case 'cycling-road':
        return 'Velosiped (yo\'l)';
      case 'cycling-mountain':
        return 'Velosiped (tog\')';
      case 'cycling-safe':
        return 'Velosiped (xavfsiz)';
      default:
        return 'Mashina';
    }
  }

  /// Open Google Maps with route from user to client
  Future<void> _openGoogleMaps() async {
    if (_userPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.userLocationNotFound ??
                'Foydalanuvchi joylashuvi aniqlanmadi',
          ),
        ),
      );
      return;
    }

    final origin = '${_userPoint!.latitude},${_userPoint!.longitude}';
    final destination = '${_clientPoint.latitude},${_clientPoint.longitude}';
    final url =
        'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.errorOccurredPrefix ??
                  'Google Maps ochib bo\'lmadi',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)?.errorOccurredPrefix ?? 'Xatolik'}: $e',
          ),
        ),
      );
    }
  }

  /// Open Yandex Maps with route from user to client
  Future<void> _openYandexMaps() async {
    if (_userPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.userLocationNotFound ??
                'Foydalanuvchi joylashuvi aniqlanmadi',
          ),
        ),
      );
      return;
    }

    final origin = '${_userPoint!.latitude},${_userPoint!.longitude}';
    final destination = '${_clientPoint.latitude},${_clientPoint.longitude}';

    // Try different Yandex Maps URL schemes to force app opening
    final urls = [
      'yandexmaps://maps.yandex.ru/?rtext=$origin~$destination&rtt=auto', // App scheme
      'yandexnavi://build_route_on_map?lat_from=${_userPoint!.latitude}&lon_from=${_userPoint!.longitude}&lat_to=${_clientPoint.latitude}&lon_to=${_clientPoint.longitude}', // Navigation app
      'https://yandex.ru/maps/?rtext=$origin~$destination&rtt=auto', // Web fallback
    ];

    for (final url in urls) {
      try {
        final uri = Uri.parse(url);
        //if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return; // Success, exit the loop
        //}
      } catch (e) {
        // Continue to next URL
        continue;
      }
    }

    // If all URLs failed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)?.errorOccurredPrefix ??
              'Yandex Maps ochib bo\'lmadi',
        ),
      ),
    );
  }

  /// Handle map tap in edit mode to move client marker
  void _onMapTap(osm_latlong.LatLng point) {
    if (!_isEditMode) return;

    // Show tap feedback animation
    _showTapFeedbackAnimation(point);

    setState(() {
      _newClientLocation = point;
      _isConfirmingLocation = true;
    });

    // Update marker position
    _updateClientMarkerPosition(point);

    if (kDebugMode) {
      print('Client marker moved to: ${point.latitude}, ${point.longitude}');
    }
  }

  /// Handle long press on map for precise location selection
  void _onMapLongPress(osm_latlong.LatLng point) {
    if (!_isEditMode) return;

    // Haptic feedback for long press
    HapticFeedback.mediumImpact();

    // Show tap feedback animation
    _showTapFeedbackAnimation(point);

    // Aniqlik rejimiga o'tish va kamera harakatini to'xtatish
    setState(() {
      _isPreciseMode = true;
      _newClientLocation = point;
      _isConfirmingLocation = true;
    });

    // Marker pozitsiyasini long press joyiga qo'yish
    _updateClientMarkerPosition(point);

    if (kDebugMode) {
      print(
        'Precise location selected via long press: ${point.latitude}, ${point.longitude}',
      );
    }
  }

  /// Show tap feedback animation
  void _showTapFeedbackAnimation(osm_latlong.LatLng point) {
    // Convert lat/lng to screen coordinates (approximate)
    // This is a simplified version - in production you'd use proper coordinate conversion
    setState(() {
      _showTapFeedback = true;
      _tapPosition = const Offset(
        100,
        100,
      ); // Placeholder - would need proper conversion
    });

    // Hide feedback after animation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showTapFeedback = false);
      }
    });
  }

  /// Update client marker position during edit mode
  void _updateClientMarkerPosition(osm_latlong.LatLng point) {
    setState(() {
      _clientPoint = point;
      // Update markers list
      _markers = [
        osm.Marker(
          width: 40.0,
          height: 40.0,
          alignment: Alignment.bottomCenter,
          point: point,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      ];
    });
  }

  /// Confirm the new location and show dialog with details
  void _confirmNewLocation() async {
    if (_newClientLocation == null) return;

    // Get address information for the new location
    // final addressInfo = await _getAddressFromCoordinates(_newClientLocation!);
    final addressInfo = [];

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)?.confirmLocationTitle ??
              'Joylashuvni tasdiqlash',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Text('Manzil: ${addressInfo['address'] ?? 'Aniqlanmadi'}'),
            const SizedBox(height: 8),
            Text(
              'Uzunlik: ${_newClientLocation!.longitude.toStringAsFixed(6)}',
            ),
            Text('Kenglik: ${_newClientLocation!.latitude.toStringAsFixed(6)}'),
            const SizedBox(height: 16),
            Text(
              'Eski joylashuvdan masofa: ${_calculateDistance(_clientPoint, _newClientLocation!).toStringAsFixed(2)} km',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelLocationChange();
            },
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _saveNewLocation();
            },
            child: Text(AppLocalizations.of(context)?.confirm ?? 'Tasdiqlash'),
          ),
        ],
      ),
    );
  }

  /// Cancel location change and revert to original position
  void _cancelLocationChange() {
    setState(() {
      _isEditMode = false;
      _isPreciseMode = false;
      _newClientLocation = null;
      _isConfirmingLocation = false;
      _clientPoint = osm_latlong.LatLng(
        widget.tradingPoint.latitude ?? 41.2995,
        widget.tradingPoint.longitude ?? 69.2401,
      );
      // Reset marker to original position
      _initializeMapData();
    });
  }

  /// Save the new location by calling API and updating database
  Future<void> _saveNewLocation() async {
    if (_newClientLocation == null) return;

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.loading ??
                'Joylashuv yangilanmoqda...',
          ),
        ),
      );

      // Call API to update client coordinates
      await _updateClientCoordinatesInDatabase(_newClientLocation!);

      // Update UI state
      setState(() {
        _isEditMode = false;
        _isPreciseMode = false;
        _isConfirmingLocation = false;
        _newClientLocation = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.clientLocationUpdated ??
                'Mijoz joylashuvi muvaffaqiyatli yangilandi',
          ),
        ),
      );

      if (kDebugMode) {
        print('Client location updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving new location: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)?.errorOccurredPrefix ?? 'Xatolik'}: $e',
          ),
        ),
      );
    }
  }

  /// Get address information from coordinates using Nominatim (OpenStreetMap) API
  Future<Map<String, String>> _getAddressFromCoordinates(
    osm_latlong.LatLng point,
  ) async {
    try {
      // Nominatim API request (OpenStreetMap's geocoding service)
      final url = 'https://nominatim.openstreetmap.org/reverse';
      final response = await Dio().get(
        url,
        queryParameters: {
          'format': 'json',
          'lat': point.latitude,
          'lon': point.longitude,
          'addressdetails': 1,
          'accept-language': 'uz',
          'zoom': 18, // Higher zoom for more detailed address
        },
      );
      debugPrint(
        "Kordinatalar asosida manzil aniqlash so'rovi natijasi_______________:",
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final address = data['address'] ?? {};

        // Extract city information
        String city =
            address['city'] ??
            address['town'] ??
            address['village'] ??
            address['municipality'] ??
            '';

        // Build full address
        String fullAddress = data['display_name'] ?? 'Aniqlanmadi';

        return {
          'address': fullAddress,
          'city': city.isNotEmpty ? city : 'Aniqlanmadi',
          'country': address['country'] ?? 'O\'zbekiston',
          'fullAddress': fullAddress,
        };
      }

      if (kDebugMode) print('No geocoding results found');
      return _getFallbackAddress();
    } catch (e) {
      if (kDebugMode) print('Nominatim Geocoding API error: $e');

      // Try Google Geocoding API as fallback
      try {
        return await _getAddressFromGoogleAPI(point);
      } catch (googleError) {
        if (kDebugMode)
          print('Google Geocoding API fallback also failed: $googleError');
        return _getFallbackAddress();
      }
    }
  }

  /// Get address using Google Geocoding API (fallback)
  Future<Map<String, String>> _getAddressFromGoogleAPI(
    osm_latlong.LatLng point,
  ) async {
    try {
      final apiKey = _prefs.getGoogleMapsToken();
      if (apiKey == null || apiKey.isEmpty) {
        return _getFallbackAddress();
      }

      final url = 'https://maps.googleapis.com/maps/api/geocode/json';
      final response = await Dio().get(
        url,
        queryParameters: {
          'latlng': '${point.latitude},${point.longitude}',
          'key': apiKey,
          'language': 'uz',
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final result = response.data['results'][0];
        final addressComponents = result['address_components'] as List;

        String city = '';
        String country = '';

        for (var component in addressComponents) {
          final types = component['types'] as List;
          if (types.contains('locality')) {
            city = component['long_name'];
          } else if (types.contains('country')) {
            country = component['long_name'];
          }
        }

        return {
          'address': result['formatted_address'] ?? 'Aniqlanmadi',
          'city': city.isNotEmpty ? city : 'Aniqlanmadi',
          'country': country.isNotEmpty ? country : 'O\'zbekiston',
          'fullAddress': result['formatted_address'] ?? '',
        };
      }

      return _getFallbackAddress();
    } catch (e) {
      if (kDebugMode) print('Google Geocoding API error: $e');
      return _getFallbackAddress();
    }
  }

  /// Get fallback address when APIs fail
  Map<String, String> _getFallbackAddress() {
    return {
      'address': 'Aniqlanmadi',
      'city': 'Aniqlanmadi',
      'country': 'O\'zbekiston',
      'fullAddress': '',
    };
  }

  /// Update client coordinates in database and via API
  Future<void> _updateClientCoordinatesInDatabase(
    osm_latlong.LatLng newLocation,
  ) async {
    try {
      // Get user code from preferences
      final userCode = _prefs.getUserCode();
      if (userCode == null) {
        throw Exception('User code not found in preferences');
      }

      // Call data sync service to update coordinates via API and database
      await _dataSyncService.updateClientCoordinates(
        userCode: userCode,
        clientCode: widget.tradingPoint.id,
        latitude: newLocation.latitude,
        longitude: newLocation.longitude,
      );

      if (kDebugMode) {
        print(
          'Client coordinates updated successfully: ${newLocation.latitude}, ${newLocation.longitude}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating client coordinates: $e');
      }
      rethrow;
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
                print(
                  'OSM map is ready for client: ${widget.tradingPoint.name}',
                );
              }
            },
            onTap: _isEditMode
                ? (tapPosition, point) => _onMapTap(point)
                : null,
            onLongPress: _isEditMode
                ? (tapPosition, point) => _onMapLongPress(point)
                : null,
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
                // Client marker
                osm.Marker(
                  width: 40.0,
                  height: 40.0,
                  alignment: Alignment.bottomCenter,
                  point: osm_latlong.LatLng(
                    _clientPoint.latitude,
                    _clientPoint.longitude,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
                // User location marker
                if (_userPoint != null)
                  osm.Marker(
                    width: 30.0,
                    height: 30.0,
                    alignment: Alignment.bottomCenter,
                    point: osm_latlong.LatLng(
                      _userPoint!.latitude,
                      _userPoint!.longitude,
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ),
                // Start marker from way_points[0]
                if (_startMarkerPoint != null)
                  osm.Marker(
                    width: 25.0,
                    height: 25.0,
                    alignment: Alignment.bottomCenter,
                    point: _startMarkerPoint!,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                // End marker from way_points[last]
                if (_endMarkerPoint != null)
                  osm.Marker(
                    width: 25.0,
                    height: 25.0,
                    alignment: Alignment.bottomCenter,
                    point: _endMarkerPoint!,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.stop,
                        color: Colors.white,
                        size: 16,
                      ),
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

        // Tap feedback overlay
        if (_showTapFeedback)
          Positioned(
            left: _tapPosition.dx - 25,
            top: _tapPosition.dy - 25,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.3),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 24),
            ),
          ),
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
                color: cs.surface
                    .withOpacity(isDark ? 0.95 : 0.9)
                    .withOpacity(0.8),
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

        // Bottom-left transport mode selection (when route is active or calculating)
        if (_showTransportModes || _isRouteVisible || _isCalculatingRoute)
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current transport mode indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTransportModeIcon(_selectedTransportMode),
                          size: 16,
                          color: cs.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTransportModeName(_selectedTransportMode),
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Transport mode buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Car mode
                      IconButton(
                        onPressed: () => _selectTransportMode('driving-car'),
                        icon: Icon(
                          Icons.directions_car,
                          size: 20,
                          color: _selectedTransportMode == 'driving-car'
                              ? cs.primary
                              : cs.onSurface.withOpacity(0.6),
                        ),
                        tooltip: 'Mashina',
                        style: IconButton.styleFrom(
                          backgroundColor:
                              _selectedTransportMode == 'driving-car'
                              ? cs.primary.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                      ),

                      // Walking mode
                      IconButton(
                        onPressed: () => _selectTransportMode('foot-walking'),
                        icon: Icon(
                          Icons.directions_walk,
                          size: 20,
                          color: _selectedTransportMode == 'foot-walking'
                              ? cs.primary
                              : cs.onSurface.withOpacity(0.6),
                        ),
                        tooltip: 'Piyoda',
                        style: IconButton.styleFrom(
                          backgroundColor:
                              _selectedTransportMode == 'foot-walking'
                              ? cs.primary.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                      ),

                      // Bicycle mode
                      IconButton(
                        onPressed: () =>
                            _selectTransportMode('cycling-regular'),
                        icon: Icon(
                          Icons.directions_bike,
                          size: 20,
                          color: _selectedTransportMode == 'cycling-regular'
                              ? cs.primary
                              : cs.onSurface.withOpacity(0.6),
                        ),
                        tooltip: 'Velosiped',
                        style: IconButton.styleFrom(
                          backgroundColor:
                              _selectedTransportMode == 'cycling-regular'
                              ? cs.primary.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                      ),

                      // Google Maps button
                      IconButton(
                        onPressed: _openGoogleMaps,
                        icon: Icon(
                          Icons.map,
                          size: 20,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                        tooltip: 'Google Maps',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                        ),
                      ),

                      // Yandex Maps button
                      IconButton(
                        onPressed: _openYandexMaps,
                        icon: Icon(
                          Icons.navigation,
                          size: 20,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                        tooltip: 'Yandex Maps',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                        ),
                      ),

                      // Additional bicycle modes (if needed)
                      if (_selectedTransportMode.startsWith('cycling'))
                        PopupMenuButton<String>(
                          onSelected: _selectTransportMode,
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'cycling-regular',
                              child: Text(
                                AppLocalizations.of(context)?.cyclingRegular ??
                                    'Oddiy velosiped',
                              ),
                            ),
                            PopupMenuItem(
                              value: 'cycling-road',
                              child: Text(
                                AppLocalizations.of(context)?.cyclingRoad ??
                                    'Yo\'l velosipedi',
                              ),
                            ),
                            PopupMenuItem(
                              value: 'cycling-mountain',
                              child: Text(
                                AppLocalizations.of(context)?.cyclingMountain ??
                                    'Tog\' velosipedi',
                              ),
                            ),
                            PopupMenuItem(
                              value: 'cycling-safe',
                              child: Text(
                                AppLocalizations.of(context)?.cyclingSafe ??
                                    'Xavfsiz velosiped',
                              ),
                            ),
                          ],
                          child: Icon(
                            Icons.more_vert,
                            size: 16,
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ],
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
                  onPressed: _locationPermissionGranted
                      ? () async {
                          if (_userPoint != null) {
                            _osmController.move(_userPoint!, 16.0);
                            _lastZoom = 16.0;
                            if (kDebugMode) {
                              print(
                                'Moved to user location: ${_userPoint!.latitude}, ${_userPoint!.longitude} with zoom: 16.0',
                              );
                            }
                          } else {
                            await _getUserLocation();
                          }
                        }
                      : null,
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
                    _osmController.move(_clientPoint, 16.0);
                    _lastZoom = 16.0;
                    if (kDebugMode) {
                      print(
                        'Moved to client location: ${_clientPoint.latitude}, ${_clientPoint.longitude} with zoom: 16.0',
                      );
                    }
                  },
                  iconSize: iconSize,
                  icon: Icon(Icons.location_on, color: cs.primary),
                  tooltip: 'Mijoz joylashuvi',
                ),
              ),

              // Route button with transport mode selection
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                          if (_isCalculatingRoute) {
                            // Show loading state
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Marshrut hisoblanmoqda...'),
                              ),
                            );
                          } else {
                            // Toggle transport modes when route button is pressed
                            if (_isRouteVisible) {
                              // If route is visible, hide transport modes and clear route
                              _toggleTransportModes();
                              _clearRoute();
                            } else {
                              // If no route, show transport modes and calculate route
                              _toggleTransportModes();
                              await _calculateRoute();
                            }
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Foydalanuvchi joylashuvi aniqlanmadi',
                              ),
                            ),
                          );
                        }
                      },
                      iconSize: iconSize,
                      icon: _isCalculatingRoute
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.route, color: cs.primary),
                      tooltip: _isRouteVisible
                          ? 'Marshrutni yopish'
                          : 'Marshrut (foydalanuvchidan mijozgacha)',
                    ),
                  ),
                ],
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
                  onPressed: _isEditMode
                      ? (_isConfirmingLocation ? _confirmNewLocation : null)
                      : _toggleEditLocationMode,
                  iconSize: iconSize,
                  icon: Icon(
                    _isEditMode
                        ? (_isConfirmingLocation
                              ? Icons.check
                              : Icons.edit_location)
                        : Icons.edit_location_outlined,
                    color: _isEditMode ? Colors.green : cs.primary,
                  ),
                  tooltip: _isEditMode
                      ? (_isConfirmingLocation
                            ? 'Joylashuvni tasdiqlash'
                            : 'Joylashuvni o\'zgartirish')
                      : 'Mijoz joylashuvini o\'zgartirish',
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
                  Icon(
                    _getTransportModeIcon(_selectedTransportMode),
                    color: cs.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_getTransportModeName(_selectedTransportMode)} marshruti',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Masofa va vaqt API orqali hisoblandi',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _clearRoute,
                    icon: Icon(
                      Icons.close,
                      color: cs.onSurface.withOpacity(0.7),
                    ),
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

        // Loading overlay for route calculation
        if (_isCalculatingRoute)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Marshrut hisoblanmoqda...',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_getTransportModeName(_selectedTransportMode)} rejimi',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Edit mode overlay (if edit mode is active)
        if (_isEditMode)
          Positioned(
            top: 80,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(isDark ? 0.95 : 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit_location, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isConfirmingLocation
                              ? 'Yangi joylashuvni tasdiqlang'
                              : _isPreciseMode
                              ? 'Aniq joylashuv tanlandi - tasdiqlang'
                              : 'Kamerani siljiting yoki uzun bosing',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _cancelLocationChange,
                        icon: Icon(
                          Icons.close,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        tooltip:
                            AppLocalizations.of(context)?.closeEditMode ??
                            'Tahrirlash rejimini yopish',
                        style: IconButton.styleFrom(
                          backgroundColor: cs.surfaceVariant.withOpacity(0.5),
                          foregroundColor: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  if (_isConfirmingLocation && _newClientLocation != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Uzunlik: ${_newClientLocation!.longitude.toStringAsFixed(6)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      'Kenglik: ${_newClientLocation!.latitude.toStringAsFixed(6)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildOsmMapWidget());
  }
}
