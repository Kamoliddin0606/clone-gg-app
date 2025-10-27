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
import 'package:gloria_marketing_flutter/src/theme/theme_controller.dart';
import 'package:gloria_marketing_flutter/src/theme/theme_schemes.dart';

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

  // Animation state
  bool _controlsVisible = true;
  double _controlsOpacity = 1.0;
  bool _isExpanded = true;
  Timer? _fadeTimer;
  Timer? _collapseTimer;

  // Interactive location editing state
  bool _isEditingLocation = false;
  MapPoint? _editingCenterPoint;
  String _selectedAddress = '';
  bool _showAddressPanel = false;
  bool _showSearchField = false;
  bool _showHintText = true;
  List<String> _searchResults = [];
  String _searchQuery = '';

  // Services
  late Connectivity _connectivity;
  bool _isOnline = true;

  // Theme management
  late final ThemeController _themeController;
  late VoidCallback _themeListener;

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
    _initializeThemeController();
    _initializeServices();
    _loadDefaultMapProvider();
    _checkLocationPermission();
    _initializeConnectivity();
    _initializeMapData();
    _startFadeTimer();
    _startCollapseTimer();
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _collapseTimer?.cancel();
    _themeController.mode.removeListener(_themeListener);
    _locationManager.dispose();
    _routeManager.dispose();
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

  /// Start fade-out timer for controls
  void _startFadeTimer() {
    _fadeTimer?.cancel();
    _fadeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _controlsOpacity = 0.1;
        });
      }
    });
  }

  /// Start collapse timer for auto-collapsing controls
  void _startCollapseTimer() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isExpanded) {
        _toggleControlsExpansion();
      }
    });
  }

  /// Reset controls opacity and restart timer
  void _resetControlsOpacity() {
    _fadeTimer?.cancel();
    _collapseTimer?.cancel();
    setState(() {
      _controlsOpacity = 1.0;
      _isExpanded = true;
    });
    _startFadeTimer();
    _startCollapseTimer();
  }

  /// Toggle controls expansion state
  void _toggleControlsExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controlsOpacity = 1.0;
        _startFadeTimer();
        _startCollapseTimer();
      } else {
        _controlsOpacity = 0.3;
        _fadeTimer?.cancel();
        _collapseTimer?.cancel();
      }
    });
  }

  /// Handle global tap anywhere on screen to reset controls opacity
  void _handleGlobalTap(BuildContext context) {
    if (!mounted) return;

    // Debounce to prevent excessive calls
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _resetControlsOpacity();
        // Optional: unfocus keyboard if open
        FocusScope.of(context).unfocus();
      }
    });
  }

  /// Start interactive location editing mode
  Future<void> _startLocationEditing() async {
    if (!mounted) return;

    setState(() {
      _isEditingLocation = true;
      _showAddressPanel = false;
      _showSearchField = true;
      _editingCenterPoint = _clientPoint;
    });

    // Animate camera to client location
    try {
      // For now, show message as camera control integration is in progress
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mijoz joylashuviga kamera o\'tkazildi')),
      );

      // Update address for current location
      await _updateAddressFromCoordinates(_clientPoint.latitude, _clientPoint.longitude);
    } catch (e) {
      if (kDebugMode) {
        print('Error starting location editing: $e');
      }
    }
  }

  /// Update address from coordinates using reverse geocoding
  Future<void> _updateAddressFromCoordinates(double lat, double lng) async {
    try {
      // Mock reverse geocoding for now
      // In real implementation, use geocoding package
      setState(() {
        _selectedAddress = 'Manzil: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
        _showAddressPanel = true;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error getting address: $e');
      }
      setState(() {
        _selectedAddress = 'Manzil aniqlanmadi';
        _showAddressPanel = true;
      });
    }
  }

  /// Handle marker drag/pan updates
  void _onMarkerDragUpdate(double lat, double lng) {
    if (!mounted || !_isEditingLocation) return;

    setState(() {
      _editingCenterPoint = MapPoint(
        id: 'editing',
        latitude: lat,
        longitude: lng,
        title: 'Yangi joylashuv',
      );
      // Hide hint text when user starts dragging
      _showHintText = false;
    });

    // Update address in real-time
    _updateAddressFromCoordinates(lat, lng);
  }

  /// Handle marker drag end
  void _onMarkerDragEnd() {
    if (!mounted || !_isEditingLocation) return;

    setState(() {
      _showAddressPanel = true;
    });
  }

  /// Save new location coordinates
  Future<void> _saveNewLocation() async {
    if (!mounted || _editingCenterPoint == null) return;

    try {
      // Show loading message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koordinatalar serverga yuborilmoqda...')),
      );

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Update client point
      setState(() {
        _clientPoint = _editingCenterPoint!;
        _isEditingLocation = false;
        _showAddressPanel = false;
        _showSearchField = false;
      });

      // Update markers
      _updateClientMarker();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koordinatalar muvaffaqiyatli yangilandi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: $e')),
      );
    }
  }

  /// Update client marker position
  void _updateClientMarker() {
    setState(() {
      // Remove existing client marker
      _markers.removeWhere((marker) => marker.id == 'client');
      // Add updated client marker
      final clientMarker = MapMarker.fromTradingPoint(widget.tradingPoint).copyWith(
        point: _clientPoint,
      );
      _markers.add(clientMarker);
    });
  }

  /// Handle search query changes
  void _onSearchQueryChanged(String query) {
    setState(() {
      _searchQuery = query;
    });

    // Mock search results
    if (query.isNotEmpty) {
      setState(() {
        _searchResults = [
          '$query ko\'chasi, Toshkent',
          '$query mahallasi, Samarqand',
          '$query shaharchasi, Buxoro',
          '$query tumani, Andijon',
          '$query viloyati, Farg\'ona',
        ];
      });
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  /// Handle search result selection
  void _onSearchResultSelected(String address) {
    // Mock coordinates for selected address
    final mockLat = 41.2995 + (DateTime.now().millisecondsSinceEpoch % 100) * 0.001;
    final mockLng = 69.2401 + (DateTime.now().millisecondsSinceEpoch % 100) * 0.001;

    setState(() {
      _editingCenterPoint = MapPoint(
        id: 'searched',
        latitude: mockLat,
        longitude: mockLng,
        title: address,
      );
      _searchResults = [];
      _searchQuery = '';
    });

    _updateAddressFromCoordinates(mockLat, mockLng);
  }

  /// Cancel location editing
  void _cancelLocationEditing() {
    setState(() {
      _isEditingLocation = false;
      _showAddressPanel = false;
      _showSearchField = false;
      _showHintText = true;
      _editingCenterPoint = null;
      _selectedAddress = '';
      _searchResults = [];
      _searchQuery = '';
    });
  }

  /// Build control icons overlay with animations
  Widget _buildControlOverlays() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    // Get theme extension for additional colors
    final themeExtension = theme.extension<AppThemeExtension>();

    // Responsive icon size
    final iconSize = screenSize.width > 600 ? 32.0 : 28.0;
    final containerSize = screenSize.width > 600 ? 56.0 : 48.0;

    return Stack(
      children: [
        // Bottom-right controls with auto-collapse functionality
        AnimatedPositioned(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          bottom: _isExpanded ? 16 : 16,
          right: _isExpanded ? 16 : -containerSize - 16,
          child: GestureDetector(
            onTap: _resetControlsOpacity,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _controlsOpacity,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 300),
                scale: _isExpanded ? 1.0 : 0.8,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: containerSize,
                  height: _isExpanded ? null : containerSize,
                  constraints: BoxConstraints(
                    minHeight: containerSize,
                    maxHeight: _isExpanded ? containerSize * 4 + 12 : containerSize,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface.withOpacity(isDark ? 0.95 : 0.9).withOpacity(_controlsOpacity),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.outline.withOpacity(0.2 * _controlsOpacity),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.4 * _controlsOpacity)
                            : Colors.black.withOpacity(0.15 * _controlsOpacity),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: isDark
                            ? themeExtension?.accentPrimary.withOpacity(0.1 * _controlsOpacity) ?? cs.primary.withOpacity(0.1 * _controlsOpacity)
                            : Colors.white.withOpacity(0.8 * _controlsOpacity),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: _isExpanded
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Toggle button (top of expanded controls)
                            // AnimatedOpacity(
                            //   duration: const Duration(milliseconds: 200),
                            //   opacity: _controlsVisible ? 1.0 : 0.0,
                            //   child: IconButton(
                            //     onPressed: _toggleControlsExpansion,
                            //     iconSize: iconSize * 0.8,
                            //     icon: Icon(Icons.unfold_less, color: cs.primary),
                            //     tooltip: 'Yopish',
                            //   ),
                            // ),

                            // 1. User position button
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: _controlsVisible ? 1.0 : 0.0,
                              child: IconButton(
                                onPressed: _locationPermissionGranted ? () {
                                  _resetControlsOpacity();
                                  if (_userPoint != null) {
                                    // TODO: Implement camera movement to user position
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Foydalanuvchi joylashuviga o\'tish')),
                                    );
                                  } else {
                                    _getUserLocation();
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

                            // 2. Client position button
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 350),
                              opacity: _controlsVisible ? 1.0 : 0.0,
                              child: IconButton(
                                onPressed: () {
                                  _resetControlsOpacity();
                                  // TODO: Implement camera movement to client position
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Mijoz joylashuviga o\'tish')),
                                  );
                                },
                                iconSize: iconSize,
                                icon: Icon(Icons.location_on, color: cs.primary),
                                tooltip: 'Mijoz joylashuvi',
                              ),
                            ),

                            // 3. Route button
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 400),
                              opacity: _controlsVisible ? 1.0 : 0.0,
                              child: IconButton(
                                onPressed: () async {
                                  _resetControlsOpacity();
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
                                iconSize: iconSize,
                                icon: Icon(Icons.route, color: cs.primary),
                                tooltip: 'Marshrut (foydalanuvchidan mijozgacha)',
                              ),
                            ),

                            // 4. Fullscreen button
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 450),
                              opacity: _controlsVisible ? 1.0 : 0.0,
                              child: IconButton(
                                onPressed: () {
                                  _resetControlsOpacity();
                                  // TODO: Implement fullscreen map navigation
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('To\'liq ekran xaritasi - amalga oshirilmoqda')),
                                  );
                                },
                                iconSize: iconSize,
                                icon: Icon(Icons.fullscreen, color: cs.primary),
                                tooltip: 'To\'liq ekran xaritasi',
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: _controlsVisible ? 1.0 : 0.0,
                            child: IconButton(
                              onPressed: _toggleControlsExpansion,
                              iconSize: iconSize * 0.8,
                              icon: Icon(Icons.unfold_more, color: cs.primary),
                              tooltip: 'Ochish',
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),

        // Top-right control (1 icon) with animations
        Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: _resetControlsOpacity,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _controlsOpacity,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 300),
                scale: _controlsVisible ? 1.0 : 0.8,
                child: Container(
                  width: containerSize,
                  height: containerSize,
                  decoration: BoxDecoration(
                    color: cs.surface.withOpacity(isDark ? 0.95 : 0.9).withOpacity(_controlsOpacity),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.outline.withOpacity(0.2 * _controlsOpacity),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.4 * _controlsOpacity)
                            : Colors.black.withOpacity(0.15 * _controlsOpacity),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: isDark
                            ? themeExtension?.accentPrimary.withOpacity(0.1 * _controlsOpacity) ?? cs.primary.withOpacity(0.1 * _controlsOpacity)
                            : Colors.white.withOpacity(0.8 * _controlsOpacity),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _controlsVisible ? 1.0 : 0.0,
                    child: IconButton(
                      onPressed: () async {
                        _resetControlsOpacity();
                        await _startLocationEditing();
                      },
                      iconSize: iconSize,
                      icon: Icon(Icons.edit_location_outlined, color: cs.primary),
                      tooltip: 'Mijoz joylashuvini o\'zgartirish',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Search field overlay (when editing location)
        if (_isEditingLocation && _showSearchField)
          Positioned(
            top: 80,
            left: 16,
            right: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showSearchField ? 1.0 : 0.0,
              child: Container(
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
                    TextField(
                      onChanged: _onSearchQueryChanged,
                      decoration: InputDecoration(
                        hintText: 'Manzilni qidiring...',
                        prefixIcon: Icon(Icons.search, color: cs.onSurface.withOpacity(0.6)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: cs.onSurface.withOpacity(0.6)),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchResults = [];
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                    ),
                    if (_searchResults.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: cs.outline.withOpacity(0.2), width: 1),
                          ),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            return ListTile(
                              dense: true,
                              title: Text(
                                result,
                                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                              ),
                              onTap: () => _onSearchResultSelected(result),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

        // Center marker hint (when editing location)
        if (_isEditingLocation)
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 60,
            left: 16,
            right: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: (_isEditingLocation && _showHintText) ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Mijoz joylashuvini o\'zgartirish uchun markerni ekran bo\'ylab siljiting',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

        // Center marker (when editing location)
        if (_isEditingLocation)
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 24,
            left: MediaQuery.of(context).size.width / 2 - 24,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isEditingLocation ? 1.0 : 0.0,
              child: GestureDetector(
                onPanUpdate: (details) {
                  // Calculate new coordinates based on drag
                  final screenSize = MediaQuery.of(context).size;
                  final centerLat = _editingCenterPoint?.latitude ?? _clientPoint.latitude;
                  final centerLng = _editingCenterPoint?.longitude ?? _clientPoint.longitude;

                  // Simple coordinate calculation based on drag distance
                  // In real implementation, this would be more sophisticated
                  final latDelta = -details.delta.dy * 0.00001;
                  final lngDelta = details.delta.dx * 0.00001;

                  _onMarkerDragUpdate(centerLat + latDelta, centerLng + lngDelta);
                },
                onPanEnd: (_) => _onMarkerDragEnd(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: cs.onPrimary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

        // Address info panel (when editing location)
        if (_isEditingLocation && _showAddressPanel && _editingCenterPoint != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showAddressPanel ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedAddress,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lat: ${_editingCenterPoint!.latitude.toStringAsFixed(6)}, Lng: ${_editingCenterPoint!.longitude.toStringAsFixed(6)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveNewLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Saqlash'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: _cancelLocationEditing,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withOpacity(0.8),
                          ),
                          child: const Text('Bekor qilish'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Route info overlay (if route is active)
        if (_isRouteVisible && _currentRoute != null && !_isEditingLocation)
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
                  BoxShadow(
                    color: isDark
                        ? themeExtension?.accentPrimary.withOpacity(0.1) ?? cs.primary.withOpacity(0.1)
                        : Colors.white.withOpacity(0.8),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
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
                          'Marshrut: ${_currentRoute!.formattedDistance}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vaqt: ${_currentRoute!.formattedTime}',
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Get theme extension for additional colors
    final themeExtension = theme.extension<AppThemeExtension>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tradingPoint.name,
          style: theme.textTheme.titleLarge?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: cs.surface.withOpacity(isDark ? 0.95 : 0.9),
        foregroundColor: cs.onSurface,
        elevation: isDark ? 2 : 1,
        shadowColor: isDark
            ? Colors.black.withOpacity(0.2)
            : Colors.black.withOpacity(0.08),
        surfaceTintColor: cs.surfaceTint,
        iconTheme: IconThemeData(
          color: cs.onSurface.withOpacity(0.8),
        ),
        actionsIconTheme: IconThemeData(
          color: cs.onSurface.withOpacity(0.8),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _handleGlobalTap(context),
        onPanDown: (_) => _handleGlobalTap(context),
        child: Stack(
          children: [
            // Map widget
            _buildMapWidget(),

            // Control overlays using the updated method
            _buildControlOverlays(),
          ],
        ),
      ),
    );
  }
}