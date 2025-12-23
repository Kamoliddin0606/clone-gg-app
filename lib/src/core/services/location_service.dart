import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user location tracking and storage
class LocationService {
  static const String _userLocationKey = 'user_location';
  static const String _lastLocationUpdateKey = 'last_location_update';

  final SharedPreferences _prefs;
  Timer? _locationTimer;
  StreamSubscription<Position>? _positionStream;

  LocationService(this._prefs);

  /// Initialize location service with background tracking
  Future<void> initialize() async {
    try {
      // Check and ensure location permission before starting tracking
      final hasPermission = await ensureLocationPermission();
      if (!hasPermission) {
        if (kDebugMode) {
          print('Location permission not granted, cannot start location service');
        }
        return;
      }

      // Start background location tracking
      await _startLocationTracking();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing location service: $e');
      }
    }
  }

  /// Ensure location permission is granted using the proper geolocator flow
  Future<bool> ensureLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print('Location services are disabled');
        }
        return false;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      if (kDebugMode) {
        print('Current location permission: $permission');
      }

      if (permission == LocationPermission.denied) {
        // Request permission (Android 12+ will show approximate/precise dialog)
        permission = await Geolocator.requestPermission();
        if (kDebugMode) {
          print('Permission after request: $permission');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // User denied forever - redirect to app settings
        if (kDebugMode) {
          print('Location permission denied forever, opening app settings');
        }
        await Geolocator.openAppSettings();
        return false;
      }

      // Check if we have adequate permission
      final hasPermission = permission == LocationPermission.always ||
                           permission == LocationPermission.whileInUse;

      if (kDebugMode) {
        print('Location permission result: $hasPermission (permission: $permission)');
      }

      return hasPermission;
    } catch (e) {
      if (kDebugMode) {
        print('Error ensuring location permission: $e');
      }
      return false;
    }
  }

  /// Start location tracking with periodic updates
  Future<void> _startLocationTracking() async {
    try {
      // Get initial location
      await _updateLocation();

      // Set up periodic updates every 10 seconds
      _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
        await _updateLocation();
      });

      // Set up position stream for more accurate tracking
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update when moved 10 meters
        ),
      ).listen((Position position) async {
        await _storeLocation(position);
      });

      if (kDebugMode) {
        print('Location tracking started successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting location tracking: $e');
      }
    }
  }

  /// Update current location and store it
  Future<void> _updateLocation() async {
    try {
      final position = await getCurrentLocation();
      if (position != null) {
        await _storeLocation(position);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating location: $e');
      }
      // Don't rethrow - location updates should be non-blocking
    }
  }

  /// Public method to manually refresh location (for UI triggered updates)
  Future<void> refreshLocation() async {
    await _updateLocation();
  }

  /// Get current fresh location from Geolocator
  Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current location: $e');
      }
      return null;
    }
  }

  /// Store location data in shared preferences
  Future<void> _storeLocation(Position position) async {
    try {
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'speedAccuracy': position.speedAccuracy,
        'heading': position.heading,
        'timestamp': position.timestamp?.toIso8601String(),
      };

      await _prefs.setString(_userLocationKey, jsonEncode(locationData));
      await _prefs.setString(_lastLocationUpdateKey, DateTime.now().toIso8601String());

      if (kDebugMode) {
        print('Location updated: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error storing location: $e');
      }
      // Don't rethrow - location storage should be non-blocking
    }
  }

  /// Get stored user location
  Map<String, dynamic>? getStoredLocation() {
    try {
      final locationString = _prefs.getString(_userLocationKey);
      if (kDebugMode) {
        print('Location string: $locationString');
      }
      if (locationString != null) {
        return jsonDecode(locationString);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting stored location: $e');
      }
    }
    return null;
  }

  /// Get last location update timestamp
  DateTime? getLastLocationUpdate() {
    try {
      final timestampString = _prefs.getString(_lastLocationUpdateKey);
      if (timestampString != null) {
        return DateTime.parse(timestampString);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting last location update: $e');
      }
    }
    return null;
  }

  /// Check if location is recent (within last 30 seconds)
  bool isLocationRecent() {
    final lastUpdate = getLastLocationUpdate();
    if (lastUpdate == null) return false;

    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    return difference.inSeconds <= 30;
  }

  /// Calculate distance between two points using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    if (kDebugMode) {
      print('Calculating distance: $lat1, $lon1, $lat2, $lon2');
    }

    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadius * c;

    if (kDebugMode) {
      print('Calculated distance: ${distance.toStringAsFixed(2)} km');
    }

    return distance; // Distance in kilometers
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Get distance to a trading point from current user location
  double? getDistanceToTradingPoint(double clientLat, double clientLon) {
    if (kDebugMode) {
      print('Getting distance to trading point: $clientLat, $clientLon');
    }

    final userLocation = getStoredLocation();
    if (kDebugMode) {
      print('User location: $userLocation');
    }
    if (userLocation == null) return null;

    final userLat = userLocation['latitude'] as double?;
    final userLon = userLocation['longitude'] as double?;

    if (userLat == null || userLon == null) return null;

    return calculateDistance(userLat, userLon, clientLat, clientLon);
  }

  /// Format distance for display
  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      // Convert to meters for distances less than 1km
      final meters = (distanceKm * 1000).round();
      return '${meters}m';
    } else if (distanceKm < 10) {
      // Show one decimal for distances under 10km
      return '${distanceKm.toStringAsFixed(1)}km';
    } else {
      // Show whole number for larger distances
      return '${distanceKm.round()}km';
    }
  }

  /// Ensure location tracking is started if permission is granted
  Future<void> ensureTrackingStarted() async {
    if (_locationTimer == null || !_locationTimer!.isActive) {
      final hasPermission = await ensureLocationPermission();
      if (hasPermission) {
        await _startLocationTracking();
      }
    }
  }

  /// Dispose of resources
  void dispose() {
    _locationTimer?.cancel();
    _positionStream?.cancel();
  }
}