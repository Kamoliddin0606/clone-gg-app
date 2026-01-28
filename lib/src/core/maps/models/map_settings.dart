import 'package:equatable/equatable.dart';
import 'map_point.dart';

/// Map provider types
enum MapProvider {
  google,
  yandex,
  openStreetMap,
}

/// Map types for different views
enum MapType {
  normal,
  satellite,
  terrain,
  hybrid,
}

/// Map settings configuration
class MapSettings extends Equatable {
  final MapProvider provider;
  final MapType mapType;
  final bool showTraffic;
  final bool showUserLocation;
  final bool enableClustering;
  final bool enableRotation;
  final bool enableTilt;
  final bool showCompass;
  final bool showScale;
  final bool showZoomControls;
  final bool enableMyLocationButton;
  final int minZoom;
  final int maxZoom;
  final double defaultZoom;
  final MapPoint? defaultCenter;
  final Language language;
  final DistanceUnit distanceUnit;
  final bool enableOfflineMode;
  final String? apiKey;

  const MapSettings({
    this.provider = MapProvider.openStreetMap,
    this.mapType = MapType.normal,
    this.showTraffic = true,
    this.showUserLocation = true,
    this.enableClustering = true,
    this.enableRotation = true,
    this.enableTilt = true,
    this.showCompass = true,
    this.showScale = true,
    this.showZoomControls = true,
    this.enableMyLocationButton = true,
    this.minZoom = 1,
    this.maxZoom = 20,
    this.defaultZoom = 15.0,
    this.defaultCenter,
    this.language = Language.uzbek,
    this.distanceUnit = DistanceUnit.kilometers,
    this.enableOfflineMode = false,
    this.apiKey,
  });

  /// Default settings for trading points view
  factory MapSettings.defaultTradingPoints() {
    return const MapSettings(
      provider: MapProvider.openStreetMap,
      mapType: MapType.normal,
      showTraffic: true,
      showUserLocation: true,
      enableClustering: true,
      defaultZoom: 12.0,
      language: Language.uzbek,
    );
  }

  /// Default settings for route planning view
  factory MapSettings.defaultRoutePlanning() {
    return const MapSettings(
      provider: MapProvider.openStreetMap,
      mapType: MapType.normal,
      showTraffic: true,
      showUserLocation: true,
      enableClustering: false,
      defaultZoom: 14.0,
      language: Language.uzbek,
    );
  }

  /// Default settings for single point view
  factory MapSettings.defaultSinglePoint() {
    return const MapSettings(
      provider: MapProvider.openStreetMap,
      mapType: MapType.normal,
      showTraffic: false,
      showUserLocation: true,
      enableClustering: false,
      defaultZoom: 16.0,
      language: Language.uzbek,
    );
  }

  /// Settings optimized for performance with many markers
  factory MapSettings.performanceOptimized() {
    return const MapSettings(
      provider: MapProvider.openStreetMap,
      mapType: MapType.normal,
      showTraffic: false,
      showUserLocation: false,
      enableClustering: true,
      enableRotation: false,
      enableTilt: false,
      showCompass: false,
      showScale: false,
      showZoomControls: false,
      enableMyLocationButton: false,
      minZoom: 8,
      maxZoom: 16,
      defaultZoom: 12.0,
      language: Language.uzbek,
    );
  }

  /// Copy with new values
  MapSettings copyWith({
    MapProvider? provider,
    MapType? mapType,
    bool? showTraffic,
    bool? showUserLocation,
    bool? enableClustering,
    bool? enableRotation,
    bool? enableTilt,
    bool? showCompass,
    bool? showScale,
    bool? showZoomControls,
    bool? enableMyLocationButton,
    int? minZoom,
    int? maxZoom,
    double? defaultZoom,
    MapPoint? defaultCenter,
    Language? language,
    DistanceUnit? distanceUnit,
    bool? enableOfflineMode,
    String? apiKey,
  }) {
    return MapSettings(
      provider: provider ?? this.provider,
      mapType: mapType ?? this.mapType,
      showTraffic: showTraffic ?? this.showTraffic,
      showUserLocation: showUserLocation ?? this.showUserLocation,
      enableClustering: enableClustering ?? this.enableClustering,
      enableRotation: enableRotation ?? this.enableRotation,
      enableTilt: enableTilt ?? this.enableTilt,
      showCompass: showCompass ?? this.showCompass,
      showScale: showScale ?? this.showScale,
      showZoomControls: showZoomControls ?? this.showZoomControls,
      enableMyLocationButton: enableMyLocationButton ?? this.enableMyLocationButton,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      defaultZoom: defaultZoom ?? this.defaultZoom,
      defaultCenter: defaultCenter ?? this.defaultCenter,
      language: language ?? this.language,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      enableOfflineMode: enableOfflineMode ?? this.enableOfflineMode,
      apiKey: apiKey ?? this.apiKey,
    );
  }

  /// Convert to map for storage/serialization
  Map<String, dynamic> toMap() {
    return {
      'provider': provider.toString(),
      'mapType': mapType.toString(),
      'showTraffic': showTraffic,
      'showUserLocation': showUserLocation,
      'enableClustering': enableClustering,
      'enableRotation': enableRotation,
      'enableTilt': enableTilt,
      'showCompass': showCompass,
      'showScale': showScale,
      'showZoomControls': showZoomControls,
      'enableMyLocationButton': enableMyLocationButton,
      'minZoom': minZoom,
      'maxZoom': maxZoom,
      'defaultZoom': defaultZoom,
      'defaultCenter': defaultCenter?.toMap(),
      'language': language.toString(),
      'distanceUnit': distanceUnit.toString(),
      'enableOfflineMode': enableOfflineMode,
      'apiKey': apiKey,
    };
  }

  /// Create from map (deserialization)
  factory MapSettings.fromMap(Map<String, dynamic> map) {
    return MapSettings(
      provider: MapProvider.values.firstWhere(
        (e) => e.toString() == map['provider'],
        orElse: () => MapProvider.openStreetMap,
      ),
      mapType: MapType.values.firstWhere(
        (e) => e.toString() == map['mapType'],
        orElse: () => MapType.normal,
      ),
      showTraffic: map['showTraffic'] ?? true,
      showUserLocation: map['showUserLocation'] ?? true,
      enableClustering: map['enableClustering'] ?? true,
      enableRotation: map['enableRotation'] ?? true,
      enableTilt: map['enableTilt'] ?? true,
      showCompass: map['showCompass'] ?? true,
      showScale: map['showScale'] ?? true,
      showZoomControls: map['showZoomControls'] ?? true,
      enableMyLocationButton: map['enableMyLocationButton'] ?? true,
      minZoom: map['minZoom'] ?? 1,
      maxZoom: map['maxZoom'] ?? 20,
      defaultZoom: map['defaultZoom'] ?? 15.0,
      defaultCenter: map['defaultCenter'] != null
          ? MapPoint.fromMap(map['defaultCenter'])
          : null,
      language: Language.values.firstWhere(
        (e) => e.toString() == map['language'],
        orElse: () => Language.uzbek,
      ),
      distanceUnit: DistanceUnit.values.firstWhere(
        (e) => e.toString() == map['distanceUnit'],
        orElse: () => DistanceUnit.kilometers,
      ),
      enableOfflineMode: map['enableOfflineMode'] ?? false,
      apiKey: map['apiKey'],
    );
  }

  @override
  List<Object?> get props => [
        provider,
        mapType,
        showTraffic,
        showUserLocation,
        enableClustering,
        enableRotation,
        enableTilt,
        showCompass,
        showScale,
        showZoomControls,
        enableMyLocationButton,
        minZoom,
        maxZoom,
        defaultZoom,
        defaultCenter,
        language,
        distanceUnit,
        enableOfflineMode,
        apiKey,
      ];

  @override
  String toString() {
    return 'MapSettings(provider: $provider, mapType: $mapType, zoom: $defaultZoom)';
  }
}
