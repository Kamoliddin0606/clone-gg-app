import 'dart:math';
import 'package:flutter/material.dart';
import '../models/map_marker.dart';
import '../models/map_point.dart';

/// Utility class for controlling marker rotation behavior on maps
/// Ensures markers remain fixed in orientation regardless of map rotation
class MarkerRotationUtils {
  /// Calculates the fixed rotation angle for a marker to maintain upright orientation
  /// when the map is rotated. This prevents markers from rotating with the map.
  ///
  /// [mapRotation] - Current map rotation angle in degrees (0 = North up)
  /// Returns the rotation angle that should be applied to the marker to keep it upright
  static double calculateFixedMarkerRotation(double mapRotation) {
    // To keep markers upright, we need to rotate them by the negative of map rotation
    // This cancels out the map's rotation effect on the marker
    return -mapRotation;
  }

  /// Creates a transformation matrix for marker positioning that accounts for map rotation
  /// This ensures markers stay at their geographic coordinates regardless of map orientation
  ///
  /// [markerPoint] - Geographic coordinates of the marker
  /// [mapCenter] - Current map center coordinates
  /// [mapRotation] - Current map rotation in degrees
  /// [zoom] - Current map zoom level
  /// [screenSize] - Size of the map widget on screen
  static Matrix4 createMarkerTransform({
    required MapPoint markerPoint,
    required MapPoint mapCenter,
    required double mapRotation,
    required double zoom,
    required Size screenSize,
  }) {
    // Convert geographic coordinates to screen coordinates
    final screenPosition = _geographicToScreen(
      markerPoint,
      mapCenter,
      zoom,
      screenSize,
    );

    // Create transformation matrix
    final transform = Matrix4.identity();

    // First, translate to marker position
    transform.translate(screenPosition.dx, screenPosition.dy);

    // Apply rotation to keep marker upright
    final rotationRadians = -mapRotation * pi / 180.0;
    transform.rotateZ(rotationRadians);

    // Translate back to origin for proper positioning
    transform.translate(-screenPosition.dx, -screenPosition.dy);

    return transform;
  }

  /// Converts geographic coordinates to screen pixel coordinates
  /// This is a simplified projection - in production, use proper map projection
  static Offset _geographicToScreen(
    MapPoint point,
    MapPoint center,
    double zoom,
    Size screenSize,
  ) {
    // Simplified Mercator-like projection for demonstration
    // In real implementation, use the map provider's projection system

    const double earthRadius = 6378137.0; // Earth's radius in meters
    const double originShift = 2.0 * pi * earthRadius / 2.0;

    // Convert to radians
    final latRad = point.latitude * pi / 180.0;
    final lngRad = point.longitude * pi / 180.0;
    final centerLatRad = center.latitude * pi / 180.0;
    final centerLngRad = center.longitude * pi / 180.0;

    // Calculate meters from center
    final mx = (lngRad - centerLngRad) * originShift / (2.0 * pi);
    final my = log(tan((pi / 4.0) + (latRad / 2.0))) * originShift / (2.0 * pi);

    // Apply zoom scaling
    final scale = pow(2.0, zoom).toDouble();
    final scaledX = mx * scale;
    final scaledY = my * scale;

    // Convert to screen coordinates (center of screen is map center)
    final screenX = screenSize.width / 2.0 + scaledX;
    final screenY = screenSize.height / 2.0 - scaledY; // Y is inverted in screen coordinates

    return Offset(screenX, screenY);
  }

  /// Determines if a marker should be visible based on map rotation and viewport
  /// Some markers might need to be hidden or repositioned at extreme rotations
  ///
  /// [marker] - The marker to check
  /// [mapRotation] - Current map rotation in degrees
  /// [viewportBounds] - Current map viewport bounds
  static bool shouldShowMarker(
    MapMarker marker,
    double mapRotation,
    dynamic viewportBounds,
  ) {
    // For most cases, markers should always be visible
    // But this can be extended for specific marker types or rotation thresholds

    // Example: Hide certain markers at extreme rotations (> 45 degrees)
    if (mapRotation.abs() > 45.0 && marker.type == MarkerType.cluster) {
      return false; // Hide cluster markers at extreme rotations to reduce clutter
    }

    // Check if marker is within viewport bounds
    return _isMarkerInViewport(marker, viewportBounds);
  }

  /// Checks if a marker is within the current map viewport
  static bool _isMarkerInViewport(MapMarker marker, dynamic viewportBounds) {
    // This would use the map provider's viewport calculation
    // For now, return true as a placeholder
    return true;
  }

  /// Applies rotation constraints to prevent markers from becoming unreadable
  /// at extreme map rotations
  ///
  /// [mapRotation] - Current map rotation in degrees
  /// Returns constrained rotation value
  static double constrainMarkerRotation(double mapRotation) {
    // Limit rotation to prevent markers from becoming upside down
    // Allow rotation between -90 and +90 degrees for readability
    const double maxRotation = 90.0;

    if (mapRotation > maxRotation) {
      return maxRotation;
    } else if (mapRotation < -maxRotation) {
      return -maxRotation;
    }

    return mapRotation;
  }

  /// Calculates the optimal marker anchor point based on rotation
  /// This ensures markers are properly positioned relative to their geographic location
  ///
  /// [marker] - The marker being positioned
  /// [mapRotation] - Current map rotation in degrees
  static Offset calculateMarkerAnchor(MapMarker marker, double mapRotation) {
    // Default anchor point (center-bottom for typical pin markers)
    Offset anchor = const Offset(0.5, 1.0);

    // Adjust anchor based on marker type and rotation
    switch (marker.type) {
      case MarkerType.user:
        // User location markers should be centered
        anchor = const Offset(0.5, 0.5);
        break;
      case MarkerType.cluster:
        // Cluster markers should be centered
        anchor = const Offset(0.5, 0.5);
        break;
      case MarkerType.visited:
      case MarkerType.today:
      case MarkerType.contract:
        // Business markers should point to location
        anchor = const Offset(0.5, 1.0);
        break;
      default:
        anchor = const Offset(0.5, 1.0);
    }

    // Fine-tune anchor based on rotation for better visual appearance
    if (mapRotation.abs() > 30.0) {
      // At higher rotations, adjust anchor slightly for better positioning
      anchor = Offset(anchor.dx, anchor.dy - 0.1);
    }

    return anchor;
  }

  /// Provides rotation animation curve for smooth marker transitions
  /// when map rotation changes
  static Curve getRotationTransitionCurve() {
    return Curves.easeOutCubic; // Smooth, natural animation
  }

  /// Calculates animation duration for marker rotation changes
  /// based on the magnitude of rotation change
  ///
  /// [rotationDelta] - Change in rotation angle in degrees
  static Duration calculateRotationAnimationDuration(double rotationDelta) {
    // Base duration for small rotations
    const baseDuration = Duration(milliseconds: 200);

    // Increase duration for larger rotation changes
    final magnitude = rotationDelta.abs();
    if (magnitude < 10.0) {
      return baseDuration;
    } else if (magnitude < 45.0) {
      return baseDuration * 1.5;
    } else {
      return baseDuration * 2.0;
    }
  }
}

/// Extension methods for MapMarker to support rotation utilities
extension MarkerRotationExtension on MapMarker {
  /// Checks if this marker type should maintain fixed orientation during map rotation
  bool get shouldMaintainUprightOrientation {
    // Most markers should stay upright, but some special types might rotate with map
    switch (type) {
      case MarkerType.user:
        return true; // User location should always be upright
      case MarkerType.cluster:
        return true; // Cluster markers should be readable
      default:
        return true; // Business markers should be upright for readability
    }
  }

  /// Gets the preferred rotation behavior for this marker
  MarkerRotationBehavior get rotationBehavior {
    switch (type) {
      case MarkerType.user:
        return MarkerRotationBehavior.fixedUpright;
      case MarkerType.cluster:
        return MarkerRotationBehavior.fixedUpright;
      case MarkerType.visited:
      case MarkerType.today:
      case MarkerType.contract:
        return MarkerRotationBehavior.fixedUpright;
      default:
        return MarkerRotationBehavior.fixedUpright;
    }
  }
}

/// Defines how markers should behave during map rotation
enum MarkerRotationBehavior {
  /// Marker rotates with the map (maintains geographic orientation)
  rotateWithMap,

  /// Marker stays upright regardless of map rotation (fixed orientation)
  fixedUpright,

  /// Marker uses custom rotation logic
  custom,
}

/// Configuration class for marker rotation behavior
class MarkerRotationConfig {
  final bool enableRotationCorrection;
  final double maxRotationAngle;
  final Duration animationDuration;
  final Curve animationCurve;
  final Map<MarkerType, MarkerRotationBehavior> typeSpecificBehavior;

  const MarkerRotationConfig({
    this.enableRotationCorrection = true,
    this.maxRotationAngle = 90.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOutCubic,
    this.typeSpecificBehavior = const {},
  });

  /// Gets the rotation behavior for a specific marker type
  MarkerRotationBehavior getBehaviorForType(MarkerType type) {
    return typeSpecificBehavior[type] ?? MarkerRotationBehavior.fixedUpright;
  }

  /// Creates a copy with modified properties
  MarkerRotationConfig copyWith({
    bool? enableRotationCorrection,
    double? maxRotationAngle,
    Duration? animationDuration,
    Curve? animationCurve,
    Map<MarkerType, MarkerRotationBehavior>? typeSpecificBehavior,
  }) {
    return MarkerRotationConfig(
      enableRotationCorrection: enableRotationCorrection ?? this.enableRotationCorrection,
      maxRotationAngle: maxRotationAngle ?? this.maxRotationAngle,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      typeSpecificBehavior: typeSpecificBehavior ?? this.typeSpecificBehavior,
    );
  }
}