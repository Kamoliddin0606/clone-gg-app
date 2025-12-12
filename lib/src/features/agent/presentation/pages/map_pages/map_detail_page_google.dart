import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;
import 'package:gloria_marketing_flutter/src/theme/theme_controller.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_key_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/network/server_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/permission_manager.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:dio/dio.dart';

// Constants for map configuration
const double kDefaultZoom = 15.0;
const double kRouteZoom = 16.0;

/// Google Maps full-screen map detail page
/// This page displays the client's location on Google Maps in full-screen mode
/// with state preservation and proper UI design matching the app theme
class MapDetailPageGoogle extends StatefulWidget {
  final model.TradingPoint tradingPoint;

  const MapDetailPageGoogle({
    super.key,
    required this.tradingPoint,
  });

  @override
  State<MapDetailPageGoogle> createState() => _MapDetailPageGoogleState();
}

class _MapDetailPageGoogleState extends State<MapDetailPageGoogle> {
  // Google Maps controller
  google_maps.GoogleMapController? _googleController;

  // Camera state management
  double? _lastZoom;

  // Map data
  late google_maps.LatLng _clientPoint;
  google_maps.LatLng? _userPoint;
  List<google_maps.LatLng>? _currentRoute;
  Set<google_maps.Marker> _markers = {};
  Set<google_maps.Polyline> _polylines = {};

  // UI state
  bool _locationPermissionGranted = false;
  bool _isRouteVisible = false;
  bool _isEditMode = false;
  bool _isConfirmingLocation = false;
  bool _isPreciseMode = false; // Long press bilan aniq joylashuv tanlash rejimi
  google_maps.LatLng? _newClientLocation;
  google_maps.LatLng? _previewLocation;
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
    _clientPoint = google_maps.LatLng(
      widget.tradingPoint.latitude ?? 41.2995, // Default to Tashkent if no coordinates
      widget.tradingPoint.longitude ?? 69.2401,
    );

    // Create client marker
    final clientMarker = google_maps.Marker(
      markerId: const google_maps.MarkerId('client'),
      position: _clientPoint,
      icon: google_maps.BitmapDescriptor.defaultMarkerWithHue(google_maps.BitmapDescriptor.hueRed),
      infoWindow: google_maps.InfoWindow(
        title: widget.tradingPoint.name,
        snippet: widget.tradingPoint.address,
      ),
    );
    _markers = {clientMarker};
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
        _userPoint = google_maps.LatLng(position.latitude, position.longitude);
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

    final userMarker = google_maps.Marker(
      markerId: const google_maps.MarkerId('user'),
      position: _userPoint!,
      icon: google_maps.BitmapDescriptor.defaultMarkerWithHue(google_maps.BitmapDescriptor.hueBlue),
      infoWindow: const google_maps.InfoWindow(
        title: 'Sizning joylashuvingiz',
      ),
    );

    setState(() {
      // Remove existing user marker if any
      _markers.removeWhere((marker) => marker.markerId.value == 'user');
      // Add new user marker
      _markers.add(userMarker);
    });

    if (kDebugMode) {
      print('User marker updated at: ${_userPoint!.latitude}, ${_userPoint!.longitude}');
    }
  }

  /// Calculate and display route using Google Directions API
  /// Note: For full routing functionality, integrate with Google Directions API
  Future<void> _calculateRoute() async {
    try {
      if (kDebugMode) {
        print('Creating route from user to client: ${widget.tradingPoint.name}');
      }

      if (_userPoint == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foydalanuvchi joylashuvi aniqlanmadi')),
        );
        return;
      }

      // For now, create simple straight line route (Google Maps will handle actual routing)
      final routePoints = [_userPoint!, _clientPoint];

      // Create polyline for route visualization
      final polyline = google_maps.Polyline(
        polylineId: const google_maps.PolylineId('route'),
        points: routePoints,
        color: Colors.blue,
        width: 5,
      );

      setState(() {
        _currentRoute = routePoints;
        _polylines = {polyline};
        _isRouteVisible = true;
      });

      // Fit camera to show the route
      _fitRouteBounds();

      // Calculate approximate distance and time
      final distance = _calculateDistance(_userPoint!, _clientPoint);
      final estimatedTime = _estimateTravelTime(distance);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marshrut: ${distance.toStringAsFixed(1)} km, taxminiy ${estimatedTime}')),
      );

      if (kDebugMode) {
        print('Route created successfully');
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
    if (_currentRoute == null || _currentRoute!.isEmpty || _googleController == null) return;

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

      final bounds = google_maps.LatLngBounds(
        southwest: google_maps.LatLng(minLat, minLng),
        northeast: google_maps.LatLng(maxLat, maxLng),
      );

      // Animate camera to fit bounds
      await _googleController!.animateCamera(
        google_maps.CameraUpdate.newLatLngBounds(bounds, 50.0),
      );

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
  double _calculateDistance(google_maps.LatLng point1, google_maps.LatLng point2) {
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
      _polylines.clear();
      _isRouteVisible = false;
    });

    if (kDebugMode) {
      print('Route cleared');
    }
  }

  /// Move camera to specific point with proper controller usage
  void _moveCameraToPoint(google_maps.LatLng point, {double? zoom}) {
    try {
      final targetZoom = zoom ?? _lastZoom ?? kDefaultZoom;
      final targetPosition = point;

      _googleController?.animateCamera(
        google_maps.CameraUpdate.newCameraPosition(
          google_maps.CameraPosition(
            target: targetPosition,
            zoom: targetZoom,
          ),
        ),
      );

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
  /// When activated, marker stays at screen center and moves with camera
  /// Checks user permissions before allowing location editing
  Future<void> _toggleEditLocationMode() async {
    try {
      // Check user permissions for editing client coordinates
      final userCode = _prefs.getUserCode();
      if (userCode == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foydalanuvchi ma\'lumotlari topilmadi')),
        );
        return;
      }

      // Get user permissions from data sync service
      final permissions = await _dataSyncService.getCachedSalesReqPermissions(userCode);
      if (permissions == null || !permissions.editClientCoordinates) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sizda mijoz joylashuvini o\'zgartirish uchun ruxsat yo\'q'),
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
          _previewLocation = null;
        } else {
          // Enter edit mode - center camera on current client location
          _moveCameraToPoint(_clientPoint, zoom: kRouteZoom);
          // Set preview location to current client point
          _previewLocation = _clientPoint;
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
        SnackBar(content: Text('Ruxsatlarni tekshirishda xatolik: $e')),
      );
    }
  }

  /// Handle map tap in edit mode to move client marker
  void _onMapTap(google_maps.LatLng point) {
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

  /// Handle camera move in edit mode - update preview location to camera center
  void _onCameraMove(google_maps.CameraPosition position) {
    if (!_isEditMode || _isPreciseMode) return; // Aniqlik rejimida kamera harakatini ignore qilish

    // Update preview location to camera center
    final centerPoint = position.target;
    setState(() {
      _previewLocation = centerPoint;
      _newClientLocation = centerPoint;
    });

    // Update marker position to follow camera center
    _updateClientMarkerPosition(centerPoint);

    if (kDebugMode) {
      print('Camera moved, marker updated to center: ${centerPoint.latitude}, ${centerPoint.longitude}');
    }
  }

  /// Handle long press on map for precise location selection
  void _onMapLongPress(google_maps.LatLng point) {
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
  void _showTapFeedbackAnimation(google_maps.LatLng point) {
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
  void _updateClientMarkerPosition(google_maps.LatLng point) {
    setState(() {
      _clientPoint = point;
      // Update markers list
      _markers = {
        google_maps.Marker(
          markerId: const google_maps.MarkerId('client'),
          position: point,
          icon: google_maps.BitmapDescriptor.defaultMarkerWithHue(google_maps.BitmapDescriptor.hueRed),
          infoWindow: google_maps.InfoWindow(
            title: widget.tradingPoint.name,
            snippet: widget.tradingPoint.address,
          ),
        ),
      };
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
      _clientPoint = google_maps.LatLng(
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
        const SnackBar(content: Text('Joylashuv yangilanmoqda...')),
      );

      // Update local database and call API
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

  /// Get address information from coordinates using Google Geocoding API
  Future<Map<String, String>> _getAddressFromCoordinates(google_maps.LatLng point) async {
    try {
      // Get Google API key from preferences
      final apiKey = _prefs.getGoogleMapsToken();
      if (apiKey == null || apiKey.isEmpty) {
        print('Google API key not found, using fallback');
        return _getFallbackAddress();
      }

      // Google Geocoding API request
      final url = 'https://maps.googleapis.com/maps/api/geocode/json';
      final response = await Dio().get(url, queryParameters: {
        'latlng': '${point.latitude},${point.longitude}',
        'key': apiKey,
        'language': 'uz',
      });
      debugPrint("Kordinatalar asosida manzil aniqlash so'rovi natijasi_______________:");
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

      print('No geocoding results found');
      return _getFallbackAddress();

    } catch (e) {
      print('Google Geocoding API error: $e');

      // Try Yandex Geocoding API as fallback
      try {
        return await _getAddressFromYandexAPI(point);
      } catch (yandexError) {
        print('Yandex Geocoding API fallback also failed: $yandexError');
        return _getFallbackAddress();
      }
    }
  }

  /// Get address using Yandex Geocoding API (fallback)
  Future<Map<String, String>> _getAddressFromYandexAPI(google_maps.LatLng point) async {
    try {
      final apiKey = _prefs.getYandexMapsToken();
      if (apiKey == null || apiKey.isEmpty) {
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

      return _getFallbackAddress();

    } catch (e) {
      print('Yandex Geocoding API error: $e');
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
  Future<void> _updateClientCoordinatesInDatabase(google_maps.LatLng newLocation) async {
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

  /// Build Google Maps widget with markers, polylines, and control overlays
  /// This widget displays the interactive map with all visual elements
  Widget _buildGoogleMapWidget() {
    return Stack(
      children: [
        // Main Google Map widget
        google_maps.GoogleMap(
          initialCameraPosition: google_maps.CameraPosition(
            target: _clientPoint,
            zoom: kDefaultZoom,
          ),
          markers: _markers,
          polylines: _polylines,
          onMapCreated: (controller) {
            _googleController = controller;
            if (kDebugMode) {
              print('Google Map is ready for client: ${widget.tradingPoint.name}');
            }
          },
          onTap: _isEditMode ? _onMapTap : null,
          onLongPress: _isEditMode ? _onMapLongPress : null,
          myLocationEnabled: _locationPermissionGranted,
          myLocationButtonEnabled: false, // We'll use custom controls
          zoomControlsEnabled: false, // We'll use custom controls
          mapType: google_maps.MapType.normal,
          onCameraMove: _onCameraMove,
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
                    if (_userPoint != null && _googleController != null) {
                      _googleController!.animateCamera(
                        google_maps.CameraUpdate.newCameraPosition(
                          google_maps.CameraPosition(
                            target: _userPoint!,
                            zoom: kRouteZoom,
                          ),
                        ),
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
                    if (_googleController != null) {
                      _googleController!.animateCamera(
                        google_maps.CameraUpdate.newCameraPosition(
                          google_maps.CameraPosition(
                            target: _clientPoint,
                            zoom: kRouteZoom,
                          ),
                        ),
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
      body: _buildGoogleMapWidget(),
    );
  }
}