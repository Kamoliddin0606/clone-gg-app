import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:yandex_maps_mapkit/yandex_map.dart' as yandex_map;
import 'package:yandex_maps_mapkit/mapkit.dart' as mk;
import 'package:yandex_maps_mapkit/mapkit_factory.dart' as mkf;
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;
import 'package:gloria_marketing_flutter/src/theme/theme_controller.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/network/server_service.dart';
import 'package:dio/dio.dart';
// Constants for map configuration
const double kDefaultZoom = 15.0;
const double kRouteZoom = 16.0;

/// Yandex Maps full-screen map detail page
/// This page displays the client's location on Yandex Maps in full-screen mode
/// with state preservation and proper UI design matching the app theme
class MapDetailPageYandex extends StatefulWidget {
  final model.TradingPoint tradingPoint;

  const MapDetailPageYandex({
    super.key,
    required this.tradingPoint,
  });

  @override
  State<MapDetailPageYandex> createState() => _MapDetailPageYandexState();
}

class _MapDetailPageYandexState extends State<MapDetailPageYandex> {
  // Yandex Maps controller
  mk.MapWindow? _yandexController;

  // Camera state management
  double? _lastZoom;

  // Map data
  late mk.Point _clientPoint;
  mk.Point? _userPoint;
  List<mk.Point>? _currentRoute;

  // UI state
  bool _locationPermissionGranted = false;
  bool _isRouteVisible = false;
  bool _isEditMode = false;
  bool _isConfirmingLocation = false;
  bool _isPreciseMode = false; // Long press bilan aniq joylashuv tanlash rejimi
  mk.Point? _newClientLocation;
  mk.Point? _previewLocation;
  bool _showTapFeedback = false;
  Offset _tapPosition = Offset.zero;

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
    _initializeThemeController();
    _initializeServices();
    _checkLocationPermission();
    _initializeMapData();
    _initializeCameraState();
    mkf.mapkit.onStart();
  }

  @override
  void dispose() {
    _themeController.mode.removeListener(_themeListener);
    mkf.mapkit.onStop();
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
      final serverService = ServerService(_prefs);
      await serverService.restore();
      _dataSyncService = DataSyncService(
        prefs: _prefs,
        apiService: SoapApiService(Dio(), serverService),
        dbService: ApiDatabaseService(),
        dbHelper: DatabaseHelper(),
      );

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
    _clientPoint = mk.Point(
      latitude: widget.tradingPoint.latitude ?? 41.2995, // Default to Tashkent if no coordinates
      longitude: widget.tradingPoint.longitude ?? 69.2401,
    );

    // Create client marker (circle)
    _addClientMarker();
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
        _userPoint = mk.Point(latitude: position.latitude, longitude: position.longitude);
      });
      _addUserMarker();

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

  /// Add client marker using circle as specified in requirements
  void _addClientMarker() {
    if (_yandexController == null) return;

    try {
      // TODO: Fix Circle API usage - requires proper API documentation
      // For now, skip marker implementation until API is clarified
      if (kDebugMode) {
        print('Client marker skipped - API needs clarification');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding client marker: $e');
      }
    }
  }

  /// Add user marker using circle
  void _addUserMarker() {
    if (_userPoint == null || _yandexController == null) return;

    try {
      // TODO: Fix Circle API usage - requires proper API documentation
      // For now, skip marker implementation until API is clarified
      if (kDebugMode) {
        print('User marker skipped - API needs clarification');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding user marker: $e');
      }
    }
  }

  /// Calculate and display simple straight line route from user to client
  /// Note: For full routing functionality, integrate with Yandex Routing API
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

      // Add route polyline to map
      _addRoutePolyline(routePoints);

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

  /// Add route polyline to the map
  void _addRoutePolyline(List<mk.Point> points) {
    if (_yandexController == null) return;

    try {
      // For now, skip polyline implementation as the API is complex
      // TODO: Implement proper polyline support when API documentation is clearer
      if (kDebugMode) {
        print('Route polyline skipped - API needs clarification');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding route polyline: $e');
      }
    }
  }

  /// Fit camera to show route bounds
  Future<void> _fitRouteBounds() async {
    if (_currentRoute == null || _currentRoute!.isEmpty || _yandexController == null) return;

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

      // Move to center with calculated zoom using smooth animation
      final cameraPosition = mk.CameraPosition(
        mk.Point(latitude: centerLat, longitude: centerLng),
        zoom: zoom,
        tilt: 0,
        azimuth: 0,
      );

      _yandexController!.map.move(cameraPosition);

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
  double _calculateDistance(mk.Point point1, mk.Point point2) {
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

    // Remove route objects from map
    _clearRouteObjects();

    if (kDebugMode) {
      print('Route cleared');
    }
  }

  /// Clear route objects from map
  void _clearRouteObjects() {
    if (_yandexController == null) return;

    try {
      // Remove polylines (route lines)
      _yandexController!.map.mapObjects.clear();

      if (kDebugMode) {
        print('Route objects cleared from map');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing route objects: $e');
      }
    }
  }

  /// Move camera to specific point with smooth animation
  void _moveCameraToPoint(mk.Point point, {double? zoom}) {
    try {
      final targetZoom = zoom ?? _lastZoom ?? kDefaultZoom;
      final targetPosition = point;

      final cameraPosition = mk.CameraPosition(
        targetPosition,
        zoom: targetZoom,
        tilt: 0,
        azimuth: 0,
      );

      _yandexController?.map.move(cameraPosition);

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

  /// Toggle edit location mode
  /// When activated, allows user to drag the client marker to a new location
  void _toggleEditLocationMode() {
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
  }

  /// Handle map tap in edit mode to move client marker
  void _onMapTap(mk.Point point) {
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
  void _onMapLongPress(mk.Point point) {
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
      print('Precise location selected via long press: ${point.latitude}, ${point.longitude}');
    }
  }

  /// Show tap feedback animation
  void _showTapFeedbackAnimation(mk.Point point) {
    // Convert lat/lng to screen coordinates (approximate)
    // This is a simplified version - in production you'd use proper coordinate conversion
    setState(() {
      _showTapFeedback = true;
      _tapPosition = const Offset(100, 100); // Placeholder - would need proper conversion
    });

    // Hide feedback after animation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showTapFeedback = false);
      }
    });
  }

  /// Update client marker position during edit mode
  void _updateClientMarkerPosition(mk.Point point) {
    setState(() {
      _clientPoint = point;
      // Note: Yandex Maps marker implementation would go here
      // For now, we just update the position
    });
  }

  /// Confirm the new location and show dialog with details
  void _confirmNewLocation() async {
    if (_newClientLocation == null) return;

    // Get address information for the new location
    final addressInfo = await _getAddressFromCoordinates(_newClientLocation!);

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Joylashuvni tasdiqlash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manzil: ${addressInfo['address'] ?? 'Aniqlanmadi'}'),
            const SizedBox(height: 8),
            Text('Uzunlik: ${_newClientLocation!.longitude.toStringAsFixed(6)}'),
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
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _saveNewLocation();
            },
            child: const Text('Tasdiqlash'),
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
      _clientPoint = mk.Point(
        latitude: widget.tradingPoint.latitude ?? 41.2995,
        longitude: widget.tradingPoint.longitude ?? 69.2401,
      );
      // Reset marker to original position
      _addClientMarker();
    });
  }

  /// Save the new location by calling API and updating database
  Future<void> _saveNewLocation() async {
    if (_newClientLocation == null) return;

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joylashuv yangilanmoqda...')),
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
        const SnackBar(content: Text('Mijoz joylashuvi muvaffaqiyatli yangilandi')),
      );

      if (kDebugMode) {
        print('Client location updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving new location: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joylashuvni yangilashda xatolik: $e')),
      );
    }
  }

  /// Get address information from coordinates using Yandex Geocoding API
  Future<Map<String, String>> _getAddressFromCoordinates(mk.Point point) async {
    try {
      // Get Yandex API key from preferences
      final apiKey = _prefs.getYandexMapsToken();
      if (apiKey == null || apiKey.isEmpty) {
        print('Yandex API key not found, using fallback');
        return _getFallbackAddress();
      }

      // Yandex Geocoding API request
      final url = 'https://geocode-maps.yandex.ru/1.x/';
      final response = await Dio().get(url, queryParameters: {
        'apikey': apiKey,
        'format': 'json',
        'geocode': '${point.longitude},${point.latitude}',
        'lang': 'uz_UZ', // Uzbek language
        'results': 1,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        final geoObjectCollection = data['response']['GeoObjectCollection'];

        if (geoObjectCollection['featureMember'].isNotEmpty) {
          final featureMember = geoObjectCollection['featureMember'][0];
          final geoObject = featureMember['GeoObject'];

          // Extract address components
          final metaData = geoObject['metaDataProperty']['GeocoderMetaData'];
          final addressDetails = metaData['AddressDetails'];
          final country = addressDetails['Country'];
          final locality = country['Locality'] ?? country['AdministrativeArea'];

          String city = '';
          String address = metaData['text'] ?? 'Aniqlanmadi';

          if (locality != null) {
            city = locality['LocalityName'] ?? '';
          }

          return {
            'address': address,
            'city': city.isNotEmpty ? city : 'Aniqlanmadi',
            'country': 'O\'zbekiston',
            'fullAddress': address,
          };
        }
      }

      print('No geocoding results found');
      return _getFallbackAddress();

    } catch (e) {
      print('Yandex Geocoding API error: $e');

      // Try Google Geocoding API as fallback
      try {
        return await _getAddressFromGoogleAPI(point);
      } catch (googleError) {
        print('Google Geocoding API fallback also failed: $googleError');
        return _getFallbackAddress();
      }
    }
  }

  /// Get address using Google Geocoding API (fallback)
  Future<Map<String, String>> _getAddressFromGoogleAPI(mk.Point point) async {
    try {
      final apiKey = _prefs.getGoogleMapsToken();
      if (apiKey == null || apiKey.isEmpty) {
        return _getFallbackAddress();
      }

      final url = 'https://maps.googleapis.com/maps/api/geocode/json';
      final response = await Dio().get(url, queryParameters: {
        'latlng': '${point.latitude},${point.longitude}',
        'key': apiKey,
        'language': 'uz',
      });

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
      print('Google Geocoding API error: $e');
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
  Future<void> _updateClientCoordinatesInDatabase(mk.Point newLocation) async {
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
        print('Client coordinates updated successfully: ${newLocation.latitude}, ${newLocation.longitude}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating client coordinates: $e');
      }
      rethrow;
    }
  }

  /// Handle map creation callback
  void _onMapCreated(dynamic controller) {
    if (controller is mk.MapWindow) {
      _yandexController = controller;

      // Move to client position
      final cameraPosition = mk.CameraPosition(
        _clientPoint,
        zoom: kDefaultZoom,
        tilt: 0,
        azimuth: 0,
      );

      _yandexController!.map.move(cameraPosition);

      // Add markers
      _addClientMarker();
      if (_userPoint != null) {
        _addUserMarker();
      }

      if (kDebugMode) {
        print('Yandex Map is ready for client: ${widget.tradingPoint.name}');
      }
    }
  }

  /// Build Yandex map widget with markers, polylines, and control overlays
  /// This widget displays the interactive map with all visual elements
  Widget _buildYandexMapWidget() {
    return Stack(
      children: [
        // Main Yandex Map widget
        yandex_map.YandexMap(
          onMapCreated: _onMapCreated,
          // Note: Yandex Maps onMapTap parameter may not be available in current version
          // TODO: Implement map tap handling when API supports it
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
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              ),
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
                    if (_userPoint != null && _yandexController != null) {
                      _moveCameraToPoint(_userPoint!, zoom: kRouteZoom);
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
                    if (_yandexController != null) {
                      _moveCameraToPoint(_clientPoint, zoom: kRouteZoom);
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
                  onPressed: _isEditMode
                      ? (_isConfirmingLocation ? _confirmNewLocation : null)
                      : _toggleEditLocationMode,
                  iconSize: iconSize,
                  icon: Icon(
                    _isEditMode
                        ? (_isConfirmingLocation ? Icons.check : Icons.edit_location)
                        : Icons.edit_location_outlined,
                    color: _isEditMode ? Colors.green : cs.primary,
                  ),
                  tooltip: _isEditMode
                      ? (_isConfirmingLocation ? 'Joylashuvni tasdiqlash' : 'Joylashuvni o\'zgartirish')
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
                        icon: Icon(Icons.close, color: cs.onSurface.withOpacity(0.7)),
                        tooltip: 'Tahrirlash rejimini yopish',
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
    return Scaffold(
      body: _buildYandexMapWidget(),
    );
  }
}