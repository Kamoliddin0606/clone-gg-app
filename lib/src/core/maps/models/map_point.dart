import 'dart:math';
import 'package:equatable/equatable.dart';

/// Unified point representation for all map providers
class MapPoint extends Equatable {
  final String id;
  final double latitude;
  final double longitude;
  final String? title;
  final String? description;
  final String? address;
  final Map<String, dynamic>? metadata;

  const MapPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.title,
    this.description,
    this.address,
    this.metadata,
  });

  /// Create MapPoint from TradingPoint
  factory MapPoint.fromTradingPoint(dynamic tradingPoint) {
    return MapPoint(
      id: tradingPoint.id ?? tradingPoint.code ?? 'unknown',
      latitude: tradingPoint.latitude ?? 0.0,
      longitude: tradingPoint.longitude ?? 0.0,
      title: tradingPoint.name ?? '',
      description: tradingPoint.address ?? '',
      address: tradingPoint.address ?? '',
      metadata: {
        'inn': tradingPoint.inn,
        'phone': tradingPoint.phone,
        'contact_person': tradingPoint.contactPerson,
        'has_contract': tradingPoint.hasContract ?? false,
        'visit_today': tradingPoint.visitToday ?? false,
      },
    );
  }

  /// Convert to Google Maps LatLng
  dynamic toGoogleLatLng() {
    // This will be implemented when Google Maps service is created
    return {'lat': latitude, 'lng': longitude};
  }

  /// Convert to Yandex Maps Point
  dynamic toYandexPoint() {
    // This will be implemented when Yandex Maps service is created
    return {'lat': latitude, 'lon': longitude};
  }

  /// Convert to OpenStreet Maps LatLng
  dynamic toOsmLatLng() {
    // This will be implemented when OSM service is created
    return {'lat': latitude, 'lng': longitude};
  }

  /// Serialize to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'title': title,
      'description': description,
      'address': address,
      'metadata': metadata,
    };
  }

  /// Deserialize from map
  factory MapPoint.fromMap(Map<String, dynamic> map) {
    return MapPoint(
      id: map['id'] ?? '',
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      title: map['title'],
      description: map['description'],
      address: map['address'],
      metadata: map['metadata'],
    );
  }

  /// Calculate distance to another point using Haversine formula
  double distanceTo(MapPoint other) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(other.latitude - latitude);
    final double dLon = _degreesToRadians(other.longitude - longitude);

    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(latitude)) *
            cos(_degreesToRadians(other.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * pi / 180;

  @override
  List<Object?> get props => [id, latitude, longitude, title, description, address];

  @override
  String toString() {
    return 'MapPoint(id: $id, lat: $latitude, lng: $longitude, title: $title)';
  }
}

/// Distance calculation types
enum DistanceType {
  straightLine,
  driving,
  walking,
  transit,
}

/// Travel modes for routing
enum TravelMode {
  driving,
  walking,
  transit,
  cycling,
}

/// Distance units
enum DistanceUnit {
  meters,
  kilometers,
  miles,
}

/// Languages for map display
enum Language {
  uzbek,
  russian,
  english,
}