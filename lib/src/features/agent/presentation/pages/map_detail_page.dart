import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_settings.dart' hide MapType;
import 'package:gloria_marketing_flutter/src/core/maps/services/map_cache_service.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_marker.dart' hide MarkerClusterConfig;
import 'package:gloria_marketing_flutter/src/core/maps/models/map_point.dart';
import 'package:yandex_maps_mapkit/yandex_map.dart';
import 'package:yandex_maps_mapkit/mapkit.dart' as mk;
import 'package:yandex_maps_mapkit/mapkit_factory.dart' as mkf;
import 'package:yandex_maps_mapkit/image.dart' as yimg;

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
  // Map controllers and services
  GoogleMapController? _googleMapController;
  mk.MapWindow? _yandexMapWindow;
  late final mk.MapKit _yandexMapKit;

  // Location and permission services
  bool _locationPermissionGranted = false;
  MapProvider _defaultMapProvider = MapProvider.google;

  // Map markers and overlays
  Set<Marker> _googleMarkers = {};
  List<MapMarker> _yandexMarkers = [];

  // User location tracking
  Position? _userPosition;
  bool _isTrackingUser = false;

  // Route display
  List<LatLng> _routePoints = [];
  Set<Polyline> _polylines = {};

  // Services
  late MapCacheService _mapCacheService;
  late Connectivity _connectivity;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeMapKit();
    _loadDefaultMapProvider();
    _checkLocationPermission();
    _initializeConnectivity();
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    _safeOnStop();
    _mapCacheService.dispose();
    super.dispose();
  }

  /// Initialize required services
  Future<void> _initializeServices() async {
    try {
      _mapCacheService = MapCacheService();
      await _mapCacheService.initialize();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing map cache service: $e');
      }
    }
  }

  /// Initialize Yandex MapKit
  void _initializeMapKit() {
    try {
      _yandexMapKit = mkf.mapkit;
      _safeOnStart();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Yandex MapKit: $e');
      }
    }
  }

  /// Safe start for Yandex MapKit
  void _safeOnStart() {
    try {
      _yandexMapKit.onStart();
    } catch (_) {}
  }

  /// Safe stop for Yandex MapKit
  void _safeOnStop() {
    try {
      _yandexMapKit.onStop();
    } catch (_) {}
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

  /// Get current user location
  Future<void> _getUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userPosition = position;
      });
      _updateUserMarker();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user location: $e');
      }
    }
  }

  /// Update user location marker on map
  void _updateUserMarker() {
    if (_userPosition == null) return;

    final userLatLng = LatLng(_userPosition!.latitude, _userPosition!.longitude);

    // Update Google Maps marker
    if (_defaultMapProvider == MapProvider.google) {
      final userMarker = Marker(
        markerId: const MarkerId('user_position'),
        position: userLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Sizning joylashuvingiz'),
      );

      setState(() {
        _googleMarkers.add(userMarker);
      });
    }

    // Update Yandex Maps marker
    if (_defaultMapProvider == MapProvider.yandex) {
      final userMarker = MapMarker(
        id: 'user_position',
        point: MapPoint(
          id: 'user_position',
          latitude: _userPosition!.latitude,
          longitude: _userPosition!.longitude,
        ),
        type: MarkerType.user,
        title: 'Sizning joylashuvingiz',
      );

      setState(() {
        _yandexMarkers.add(userMarker);
      });
    }
  }

  /// Calculate and display route from user to client
  /// This method calculates the route between user position and client position
  /// Currently draws a straight line, future implementation will use routing API
  /// TODO: Integrate with routing service for accurate route calculation
  Future<void> _calculateRoute() async {
    try {
      if (kDebugMode) {
        print('Calculating route from user to client: ${widget.tradingPoint.name}');
      }

      if (_userPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foydalanuvchi joylashuvi aniqlanmadi')),
        );
        return;
      }

      final userLatLng = LatLng(_userPosition!.latitude, _userPosition!.longitude);
      final clientLatLng = LatLng(
        widget.tradingPoint.latitude,
        widget.tradingPoint.longitude,
      );

      // For now, just draw a straight line
      // In future, this should use routing API
      setState(() {
        _routePoints = [userLatLng, clientLatLng];
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: _routePoints,
            color: Colors.blue,
            width: 5,
          ),
        };
      });

      // Move camera to show both points
      _fitBounds();

      // Show route calculated message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marshrut hisoblandi')),
      );

      if (kDebugMode) {
        print('Route calculated successfully between user and client');
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

  /// Fit camera to show both user and client locations
  void _fitBounds() {
    if (_userPosition == null) return;

    final userLatLng = LatLng(_userPosition!.latitude, _userPosition!.longitude);
    final clientLatLng = LatLng(
      widget.tradingPoint.latitude,
      widget.tradingPoint.longitude,
    );

    if (_defaultMapProvider == MapProvider.google && _googleMapController != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          userLatLng.latitude < clientLatLng.latitude ? userLatLng.latitude : clientLatLng.latitude,
          userLatLng.longitude < clientLatLng.longitude ? userLatLng.longitude : clientLatLng.longitude,
        ),
        northeast: LatLng(
          userLatLng.latitude > clientLatLng.latitude ? userLatLng.latitude : clientLatLng.latitude,
          userLatLng.longitude > clientLatLng.longitude ? userLatLng.longitude : clientLatLng.longitude,
        ),
      );

      _googleMapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    }
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

  /// Build map widget based on selected provider
  Widget _buildMapWidget() {
    final clientLatLng = LatLng(
      widget.tradingPoint.latitude,
      widget.tradingPoint.longitude,
    );

    switch (_defaultMapProvider) {
      case MapProvider.google:
        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: clientLatLng,
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: MarkerId(widget.tradingPoint.id),
              position: clientLatLng,
              infoWindow: InfoWindow(title: widget.tradingPoint.name),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
            ..._googleMarkers,
          },
          polylines: _polylines,
          myLocationEnabled: _locationPermissionGranted,
          myLocationButtonEnabled: false, // We'll use custom button
          compassEnabled: true,
          tiltGesturesEnabled: true,
          rotateGesturesEnabled: true,
          zoomControlsEnabled: false, // We'll use custom controls
          onMapCreated: (controller) {
            _googleMapController = controller;
            _updateUserMarker();
          },
        );

      case MapProvider.yandex:
        return YandexMap(
          onMapCreated: (mapWindow) {
            _yandexMapWindow = mapWindow;

            // Set camera position
            final target = mk.Point(
              latitude: widget.tradingPoint.latitude,
              longitude: widget.tradingPoint.longitude,
            );
            mapWindow.map.move(
              mk.CameraPosition(target, zoom: 15.0, tilt: 0, azimuth: 0),
            );

            // Add client marker
            final clientMarker = MapMarker(
              id: widget.tradingPoint.id,
              point: MapPoint(
                id: widget.tradingPoint.id,
                latitude: widget.tradingPoint.latitude,
                longitude: widget.tradingPoint.longitude,
              ),
              type: MarkerType.default_,
              title: widget.tradingPoint.name,
            );

            _addYandexMarker(clientMarker);
            _updateUserMarker();
          },
        );

      default:
        return const Center(
          child: Text('Xarita provayderi qo\'llab-quvvatlanmaydi'),
        );
    }
  }

  /// Add marker to Yandex map
  Future<void> _addYandexMarker(MapMarker marker) async {
    if (_yandexMapWindow == null) return;

    try {
      final point = mk.Point(
        latitude: marker.point.latitude,
        longitude: marker.point.longitude,
      );

      final placemark = _yandexMapWindow!.map.mapObjects.addPlacemark()..geometry = point;

      // Apply marker styling
      await _applyYandexMarkerStyle(placemark, marker.type);

      // Make visible
      placemark.opacity = 1.0;
      placemark.zIndex = 10;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding Yandex marker: $e');
      }
    }
  }

  /// Apply styling to Yandex marker
  Future<void> _applyYandexMarkerStyle(mk.PlacemarkMapObject placemark, MarkerType type) async {
    try {
      String assetPath;
      switch (type) {
        case MarkerType.user:
          assetPath = 'assets/images/marker_user.png';
          break;
        default:
          assetPath = 'assets/images/marker.png';
      }

      final provider = yimg.AnimatedImageProvider.fromAsset(assetPath) as yimg.ImageProvider;
      final style = mk.IconStyle();

      try {
        final icon = placemark.useIcon();
        icon.setImageWithStyle(provider, style);
      } catch (_) {
        final comp = placemark.useCompositeIcon();
        comp.setIcon(provider, style, name: 'marker');
      }
    } catch (_) {
      // Use default styling if asset fails
    }
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
                      if (_userPosition != null) {
                        final userLatLng = LatLng(
                          _userPosition!.latitude,
                          _userPosition!.longitude,
                        );
                        if (_defaultMapProvider == MapProvider.google && _googleMapController != null) {
                          _googleMapController!.animateCamera(
                            CameraUpdate.newLatLngZoom(userLatLng, 15),
                          );
                        }
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
                      final clientLatLng = LatLng(
                        widget.tradingPoint.latitude,
                        widget.tradingPoint.longitude,
                      );
                      if (_defaultMapProvider == MapProvider.google && _googleMapController != null) {
                        _googleMapController!.animateCamera(
                          CameraUpdate.newLatLngZoom(clientLatLng, 15),
                        );
                      }
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
          if (_routePoints.isNotEmpty)
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
                      child: Text(
                        'Marshrut ko\'rsatilmoqda',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _routePoints.clear();
                          _polylines.clear();
                        });
                      },
                      icon: Icon(Icons.close, color: cs.onSurface),
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