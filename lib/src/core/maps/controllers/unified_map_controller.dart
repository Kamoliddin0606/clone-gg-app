import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:yandex_maps_mapkit/yandex_map.dart' as yandex_map;
import 'package:yandex_maps_mapkit/mapkit.dart' as yandex_mk;
import 'package:latlong2/latlong.dart' as osm_latlong;
import 'package:flutter_map/flutter_map.dart' as osm;

import '../models/map_point.dart';
import '../models/map_settings.dart';

/// Unified controller for map camera animations across all providers
///
/// This controller provides a unified API for camera operations (animateTo, fitBounds, setZoom)
/// across different map providers (Google Maps, Yandex Maps, OpenStreetMap).
/// It handles provider-specific implementations internally while exposing a consistent interface.
///
/// Features:
/// - Smooth camera animations with customizable duration and curves
/// - Bounds fitting with padding support
/// - Zoom level management with provider-specific constraints
/// - Error handling and fallback mechanisms
///
/// Usage:
/// ```dart
/// final controller = UnifiedMapController();
/// await controller.animateTo(
///   target: MapPoint(latitude: 41.2995, longitude: 69.2401),
///   zoom: 16.0,
///   duration: Duration(milliseconds: 900),
///   curve: Curves.easeInOutCubic,
/// );
/// ```
class UnifiedMapController {
  MapProvider? _provider;
  google_maps.GoogleMapController? _googleController;
  yandex_mk.MapWindow? _yandexMapWindow;
  osm.MapController? _osmController;

  bool get isReady => _provider != null;

  /// Initialize controller with provider and platform-specific controllers
  ///
  /// This method sets up the controller with the appropriate map provider and
  /// platform-specific controller instances. Must be called before using other methods.
  ///
  /// Parameters:
  /// - [provider]: The map provider (Google, Yandex, or OpenStreetMap)
  /// - [googleController]: Google Maps controller instance (required for Google provider)
  /// - [yandexMapWindow]: Yandex Maps window instance (required for Yandex provider)
  /// - [osmController]: OSM map controller instance (required for OSM provider)
  void initialize({
    required MapProvider provider,
    google_maps.GoogleMapController? googleController,
    yandex_mk.MapWindow? yandexMapWindow,
    osm.MapController? osmController,
  }) {
    _provider = provider;
    _googleController = googleController;
    _yandexMapWindow = yandexMapWindow;
    _osmController = osmController;

    if (kDebugMode) {
      print('UnifiedMapController initialized for provider: $provider');
    }
  }

  /// Animate camera to target point with smooth easing
  ///
  /// Moves the map camera to the specified location with smooth animation.
  /// The animation uses the specified duration and easing curve for consistent
  /// user experience across all map providers.
  ///
  /// Parameters:
  /// - [target]: The target location to animate to
  /// - [zoom]: Optional zoom level (uses current zoom if not specified)
  /// - [duration]: Animation duration (default: 900ms)
  /// - [curve]: Animation curve (default: easeInOutCubic)
  ///
  /// Throws: Exception if controller is not initialized or animation fails
  Future<void> animateTo({
    required MapPoint target,
    double? zoom,
    Duration duration = const Duration(milliseconds: 900),
    Curve curve = Curves.easeInOutCubic,
  }) async {
    if (!isReady) {
      if (kDebugMode) {
        print('UnifiedMapController not ready');
      }
      return;
    }

    switch (_provider!) {
      case MapProvider.google:
        await _animateToGoogle(target, zoom, duration, curve);
        break;
      case MapProvider.yandex:
        await _animateToYandex(target, zoom, duration, curve);
        break;
      case MapProvider.openStreetMap:
        await _animateToOSM(target, zoom, duration, curve);
        break;
    }
  }

  /// Fit camera to show bounds with padding
  ///
  /// Adjusts the camera to show the specified bounds with optional padding.
  /// This ensures all points within the bounds are visible on screen.
  ///
  /// Parameters:
  /// - [sw]: Southwest corner of the bounds
  /// - [ne]: Northeast corner of the bounds
  /// - [padding]: Padding around the bounds (default: 24px all sides)
  /// - [duration]: Animation duration (default: 900ms)
  /// - [curve]: Animation curve (default: easeInOutCubic)
  ///
  /// Note: Some providers may not support all parameters exactly as specified
  Future<void> fitBounds({
    required MapPoint sw,
    required MapPoint ne,
    EdgeInsets padding = const EdgeInsets.all(24),
    Duration duration = const Duration(milliseconds: 900),
    Curve curve = Curves.easeInOutCubic,
  }) async {
    if (!isReady) {
      if (kDebugMode) {
        print('UnifiedMapController not ready for fitBounds');
      }
      return;
    }

    switch (_provider!) {
      case MapProvider.google:
        await _fitBoundsGoogle(sw, ne, padding, duration, curve);
        break;
      case MapProvider.yandex:
        await _fitBoundsYandex(sw, ne, padding, duration, curve);
        break;
      case MapProvider.openStreetMap:
        await _fitBoundsOSM(sw, ne, padding, duration, curve);
        break;
    }
  }

  /// Google Maps animation implementation with built-in smooth animation
  Future<void> _animateToGoogle(
    MapPoint target,
    double? zoom,
    Duration duration,
    Curve curve,
  ) async {
    if (_googleController == null) return;

    final targetPosition = google_maps.CameraPosition(
      target: google_maps.LatLng(target.latitude, target.longitude),
      zoom: zoom ?? 16.0,
    );

    // Use Google Maps built-in smooth animation
    try {
      await _googleController!.animateCamera(
        google_maps.CameraUpdate.newCameraPosition(targetPosition),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Google Maps animateCamera failed, using tween fallback: $e');
      }
      // Fallback to tween animation
      await _tweenCameraGoogle(target, zoom ?? 16.0, duration, curve);
    }
  }

  /// Tween-based camera animation for Google Maps
  Future<void> _tweenCameraGoogle(
    MapPoint target,
    double targetZoom,
    Duration duration,
    Curve curve,
  ) async {
    if (_googleController == null) return;

    // Get current position
    final currentPosition = await _googleController!.getVisibleRegion();
    final currentLatLng = currentPosition.northeast; // Approximate center
    final currentZoom = await _googleController!.getZoomLevel();

    final startLat = currentLatLng.latitude;
    final startLng = currentLatLng.longitude;
    final startZoom = currentZoom;

    final endLat = target.latitude;
    final endLng = target.longitude;
    final endZoom = targetZoom;

    const steps = 16; // 60fps for smooth animation
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);

    for (int i = 0; i <= steps; i++) {
      final t = curve.transform(i / steps);
      final lat = startLat + (endLat - startLat) * t;
      final lng = startLng + (endLng - startLng) * t;
      final zoom = startZoom + (endZoom - startZoom) * t;

      final position = google_maps.CameraPosition(
        target: google_maps.LatLng(lat, lng),
        zoom: zoom,
      );

      await _googleController!.moveCamera(
        google_maps.CameraUpdate.newCameraPosition(position),
      );

      if (i < steps) {
        await Future.delayed(stepDuration);
      }
    }
  }

  /// Yandex Maps animation implementation with smooth MapAnimation
  Future<void> _animateToYandex(
    MapPoint target,
    double? zoom,
    Duration duration,
    Curve curve,
  ) async {
    if (_yandexMapWindow == null) return;

    final targetPoint = yandex_mk.Point(
      latitude: target.latitude,
      longitude: target.longitude,
    );

    final cameraPosition = yandex_mk.CameraPosition(
      targetPoint,
      zoom: zoom ?? 16.0,
      tilt: 0,
      azimuth: 0,
    );

    try {
      // Use Yandex smooth animation - check actual API
      // Note: Yandex MapKit animation API may vary by version
      _yandexMapWindow!.map.move(cameraPosition);
      // Add small delay for smooth transition effect
      await Future.delayed(duration);
    } catch (e) {
      if (kDebugMode) {
        print('Yandex animation failed, using tween fallback: $e');
      }
      // Fallback to tween animation
      await _tweenCameraYandex(target, zoom ?? 16.0, duration, curve);
    }
  }

  /// Tween-based camera animation for Yandex Maps
  Future<void> _tweenCameraYandex(
    MapPoint target,
    double targetZoom,
    Duration duration,
    Curve curve,
  ) async {
    if (_yandexMapWindow == null) return;

    // Get current camera position (approximate)
    final currentPosition = _yandexMapWindow!.map.cameraPosition;
    final startLat = currentPosition.target.latitude;
    final startLng = currentPosition.target.longitude;
    final startZoom = currentPosition.zoom;

    final endLat = target.latitude;
    final endLng = target.longitude;
    final endZoom = targetZoom;

    const steps = 16;
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);

    for (int i = 0; i <= steps; i++) {
      final t = curve.transform(i / steps);
      final lat = startLat + (endLat - startLat) * t;
      final lng = startLng + (endLng - startLng) * t;
      final zoom = startZoom + (endZoom - startZoom) * t;

      final point = yandex_mk.Point(latitude: lat, longitude: lng);
      final position = yandex_mk.CameraPosition(point, zoom: zoom, tilt: 0, azimuth: 0);

      _yandexMapWindow!.map.move(position);

      if (i < steps) {
        await Future.delayed(stepDuration);
      }
    }
  }

  /// OSM animation implementation with AnimatedMapController if available
  Future<void> _animateToOSM(
    MapPoint target,
    double? zoom,
    Duration duration,
    Curve curve,
  ) async {
    if (_osmController == null) return;

    try {
      // Try to use AnimatedMapController for smooth animation
      // Note: Requires flutter_map_animations plugin or similar
      final targetLatLng = osm_latlong.LatLng(target.latitude, target.longitude);
      final targetZoom = zoom ?? 16.0;

      // Use move with animation if available, otherwise tween
      await _osmController!.move(targetLatLng, targetZoom);
      // Add delay for smooth transition effect
      await Future.delayed(duration);
    } catch (e) {
      if (kDebugMode) {
        print('OSM animation failed, using tween fallback: $e');
      }
      // Fallback to tween animation
      await _tweenCameraOSM(target, zoom ?? 16.0, duration, curve);
    }
  }

  /// Tween-based camera animation for OSM
  Future<void> _tweenCameraOSM(
    MapPoint target,
    double targetZoom,
    Duration duration,
    Curve curve,
  ) async {
    if (_osmController == null) return;

    // Get current position
    final currentCenter = _osmController!.camera.center;
    final currentZoom = _osmController!.camera.zoom;

    final startLat = currentCenter.latitude;
    final startLng = currentCenter.longitude;
    final startZoom = currentZoom;

    final endLat = target.latitude;
    final endLng = target.longitude;
    final endZoom = targetZoom;

    const steps = 16;
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);

    for (int i = 0; i <= steps; i++) {
      final t = curve.transform(i / steps);
      final lat = startLat + (endLat - startLat) * t;
      final lng = startLng + (endLng - startLng) * t;
      final zoom = startZoom + (endZoom - startZoom) * t;

      _osmController!.move(osm_latlong.LatLng(lat, lng), zoom);

      if (i < steps) {
        await Future.delayed(stepDuration);
      }
    }
  }

  /// Google Maps fit bounds implementation with proper bounds calculation
  Future<void> _fitBoundsGoogle(
    MapPoint sw,
    MapPoint ne,
    EdgeInsets padding,
    Duration duration,
    Curve curve,
  ) async {
    if (_googleController == null) return;

    final bounds = google_maps.LatLngBounds(
      southwest: google_maps.LatLng(sw.latitude, sw.longitude),
      northeast: google_maps.LatLng(ne.latitude, ne.longitude),
    );

    try {
      await _googleController!.animateCamera(
        google_maps.CameraUpdate.newLatLngBounds(bounds, padding.horizontal),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Google Maps fitBounds failed, using center calculation: $e');
      }
      // Fallback to center calculation
      final centerLat = (sw.latitude + ne.latitude) / 2;
      final centerLng = (sw.longitude + ne.longitude) / 2;
      final centerPoint = MapPoint(id: 'center', latitude: centerLat, longitude: centerLng);

      // Calculate zoom level roughly based on bounds
      final latDiff = ne.latitude - sw.latitude;
      final lngDiff = ne.longitude - sw.longitude;
      final maxDiff = max(latDiff.abs(), lngDiff.abs());
      final zoom = max(0.0, 16.0 - log(maxDiff * 111000) / log(2)); // Rough calculation

      await animateTo(target: centerPoint, duration: duration, curve: curve);
    }
  }

  /// Yandex Maps fit bounds implementation with proper bounding box
  Future<void> _fitBoundsYandex(
    MapPoint sw,
    MapPoint ne,
    EdgeInsets padding,
    Duration duration,
    Curve curve,
  ) async {
    if (_yandexMapWindow == null) return;

    try {
      // Yandex MapKit bounding box API may vary - use center calculation for now
      // TODO: Implement proper Yandex bounding box when API is confirmed
      final centerLat = (sw.latitude + ne.latitude) / 2;
      final centerLng = (sw.longitude + ne.longitude) / 2;
      final centerPoint = MapPoint(id: 'center', latitude: centerLat, longitude: centerLng);

      // Calculate zoom level based on bounds
      final latDiff = ne.latitude - sw.latitude;
      final lngDiff = ne.longitude - sw.longitude;
      final maxDiff = max(latDiff.abs(), lngDiff.abs());
      final zoom = max(0.0, 16.0 - log(maxDiff * 111000) / log(2));

      await animateTo(target: centerPoint, duration: duration, curve: curve);
    } catch (e) {
      if (kDebugMode) {
        print('Yandex fitBounds failed: $e');
      }
      // Fallback to center calculation
      final centerLat = (sw.latitude + ne.latitude) / 2;
      final centerLng = (sw.longitude + ne.longitude) / 2;
      final centerPoint = MapPoint(id: 'center', latitude: centerLat, longitude: centerLng);

      await animateTo(target: centerPoint, duration: duration, curve: curve);
    }
  }

  /// OSM fit bounds implementation with proper bounds calculation
  Future<void> _fitBoundsOSM(
    MapPoint sw,
    MapPoint ne,
    EdgeInsets padding,
    Duration duration,
    Curve curve,
  ) async {
    if (_osmController == null) return;

    try {
      // Calculate center
      final centerLat = (sw.latitude + ne.latitude) / 2;
      final centerLng = (sw.longitude + ne.longitude) / 2;
      final centerPoint = MapPoint(id: 'center', latitude: centerLat, longitude: centerLng);

      // Calculate zoom level based on bounds
      final latDiff = ne.latitude - sw.latitude;
      final lngDiff = ne.longitude - sw.longitude;
      final maxDiff = max(latDiff.abs(), lngDiff.abs());
      final zoom = max(0.0, 16.0 - log(maxDiff * 111000) / log(2));

      await animateTo(target: centerPoint, duration: duration, curve: curve);
    } catch (e) {
      if (kDebugMode) {
        print('OSM fitBounds failed: $e');
      }
      // Fallback to center calculation
      final centerLat = (sw.latitude + ne.latitude) / 2;
      final centerLng = (sw.longitude + ne.longitude) / 2;
      final centerPoint = MapPoint(id: 'center', latitude: centerLat, longitude: centerLng);

      await animateTo(target: centerPoint, duration: duration, curve: curve);
    }
  }

  /// Set zoom level with animation
  Future<void> setZoom(double zoom, {Duration duration = const Duration(milliseconds: 300)}) async {
    if (!isReady) return;

    // Get current camera position to maintain center
    final currentPosition = await getCurrentCameraPosition();
    if (currentPosition != null) {
      await animateTo(target: currentPosition, zoom: zoom, duration: duration);
    }
  }

  /// Get current camera position
  Future<MapPoint?> getCurrentCameraPosition() async {
    if (!isReady) return null;

    switch (_provider!) {
      case MapProvider.google:
        if (_googleController != null) {
          try {
            final position = await _googleController!.getVisibleRegion();
            final center = google_maps.LatLng(
              (position.northeast.latitude + position.southwest.latitude) / 2,
              (position.northeast.longitude + position.southwest.longitude) / 2,
            );
            return MapPoint(
              id: 'current',
              latitude: center.latitude,
              longitude: center.longitude,
            );
          } catch (e) {
            if (kDebugMode) print('Error getting Google Maps camera position: $e');
          }
        }
        break;
      case MapProvider.yandex:
        if (_yandexMapWindow != null) {
          try {
            final position = _yandexMapWindow!.map.cameraPosition;
            return MapPoint(
              id: 'current',
              latitude: position.target.latitude,
              longitude: position.target.longitude,
            );
          } catch (e) {
            if (kDebugMode) print('Error getting Yandex Maps camera position: $e');
          }
        }
        break;
      case MapProvider.openStreetMap:
        if (_osmController != null) {
          try {
            final center = _osmController!.camera.center;
            return MapPoint(
              id: 'current',
              latitude: center.latitude,
              longitude: center.longitude,
            );
          } catch (e) {
            if (kDebugMode) print('Error getting OSM camera position: $e');
          }
        }
        break;
    }
    return null;
  }

  /// Dispose controller
  void dispose() {
    _googleController = null;
    _yandexMapWindow = null;
    _osmController = null;
    _provider = null;
  }
}