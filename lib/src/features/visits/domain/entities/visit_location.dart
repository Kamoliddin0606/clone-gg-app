import 'package:equatable/equatable.dart';

/// Point-in-time GPS fix attached to a visit's start/finish or a photo.
///
/// Mirrors the server `start_location` / `finish_location` JSONB shape so the
/// envelope builder can serialize without a translation step.
class VisitLocation extends Equatable {
  const VisitLocation({
    required this.lat,
    required this.lng,
    required this.accuracyM,
    required this.source,
    required this.mocked,
    required this.providerTs,
    this.altitudeM,
    this.headingDegrees,
    this.speedMps,
  });

  final double lat;
  final double lng;
  final double accuracyM;
  final double? altitudeM;
  final double? headingDegrees;
  final double? speedMps;

  /// `'gps'`, `'network'`, `'fused'`. The backend treats anything other than
  /// `'gps'` as untrusted for radius checks.
  final String source;

  /// `Geolocator.isMockLocation` on Android; always `false` on iOS where the
  /// platform doesn't expose mock state.
  final bool mocked;

  /// When the GPS provider produced the fix (not when we read it). Helps the
  /// backend reject stale cached fixes.
  final DateTime providerTs;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'accuracy_m': accuracyM,
        if (altitudeM != null) 'altitude_m': altitudeM,
        if (headingDegrees != null) 'heading_degrees': headingDegrees,
        if (speedMps != null) 'speed_mps': speedMps,
        'source': source,
        'mocked': mocked,
        'provider_ts': providerTs.toUtc().toIso8601String(),
      };

  factory VisitLocation.fromJson(Map<String, dynamic> json) => VisitLocation(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        accuracyM: (json['accuracy_m'] as num).toDouble(),
        altitudeM: (json['altitude_m'] as num?)?.toDouble(),
        headingDegrees: (json['heading_degrees'] as num?)?.toDouble(),
        speedMps: (json['speed_mps'] as num?)?.toDouble(),
        source: json['source'] as String,
        mocked: json['mocked'] as bool,
        providerTs: DateTime.parse(json['provider_ts'] as String),
      );

  @override
  List<Object?> get props => [
        lat,
        lng,
        accuracyM,
        altitudeM,
        headingDegrees,
        speedMps,
        source,
        mocked,
        providerTs,
      ];
}
