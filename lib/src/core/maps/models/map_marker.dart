import 'package:equatable/equatable.dart';
import 'map_point.dart';

/// Enhanced marker model for map display
class MapMarker extends Equatable {
  final String id;
  final MapPoint point;
  final MarkerType type;
  final MarkerIcon icon;
  final String? title;
  final String? snippet;
  final bool isDraggable;
  final bool isVisible;
  final double zIndex;
  final Map<String, dynamic>? metadata;

  const MapMarker({
    required this.id,
    required this.point,
    this.type = MarkerType.default_,
    this.icon = MarkerIcon.default_,
    this.title,
    this.snippet,
    this.isDraggable = false,
    this.isVisible = true,
    this.zIndex = 0.0,
    this.metadata,
  });

  /// Create marker from TradingPoint
  factory MapMarker.fromTradingPoint(dynamic tradingPoint) {
    final point = MapPoint.fromTradingPoint(tradingPoint);

    // Determine marker type based on trading point properties
    MarkerType markerType = MarkerType.default_;
    if (tradingPoint.isVisited == true) {
      markerType = MarkerType.visited;
    } else if (tradingPoint.visitToday == true) {
      markerType = MarkerType.today;
    } else if (tradingPoint.hasContract == true) {
      markerType = MarkerType.contract;
    }

    return MapMarker(
      id: point.id,
      point: point,
      type: markerType,
      title: point.title,
      snippet: point.description,
      metadata: point.metadata,
    );
  }

  /// Create cluster marker
  factory MapMarker.cluster({
    required String id,
    required MapPoint point,
    required int count,
  }) {
    return MapMarker(
      id: id,
      point: point,
      type: MarkerType.cluster,
      title: '$count ta nuqta',
      snippet: 'Klaster',
      metadata: {'count': count},
    );
  }

  /// Create user location marker
  factory MapMarker.userLocation(MapPoint point) {
    return MapMarker(
      id: 'user_location',
      point: point,
      type: MarkerType.user,
      title: 'Sizning joylashganingiz',
      icon: MarkerIcon.user,
    );
  }

  /// Check if marker represents a cluster
  bool get isCluster => type == MarkerType.cluster;

  /// Get cluster count if this is a cluster marker
  int get clusterCount => metadata?['count'] as int? ?? 0;

  /// Copy with new properties
  MapMarker copyWith({
    String? id,
    MapPoint? point,
    MarkerType? type,
    MarkerIcon? icon,
    String? title,
    String? snippet,
    bool? isDraggable,
    bool? isVisible,
    double? zIndex,
    Map<String, dynamic>? metadata,
  }) {
    return MapMarker(
      id: id ?? this.id,
      point: point ?? this.point,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      title: title ?? this.title,
      snippet: snippet ?? this.snippet,
      isDraggable: isDraggable ?? this.isDraggable,
      isVisible: isVisible ?? this.isVisible,
      zIndex: zIndex ?? this.zIndex,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [id, point, type, icon, title, snippet, isDraggable, isVisible, zIndex];

  @override
  String toString() {
    return 'MapMarker(id: $id, type: $type, point: $point, title: $title)';
  }
}

/// Marker types for different point categories
enum MarkerType {
  default_,
  visited,
  today,
  contract,
  cluster,
  user,
  destination,
  waypoint,
}

/// Marker icons for visual differentiation
enum MarkerIcon {
  default_,
  user,
  store,
  warehouse,
  home,
  flag,
  pin,
  circle,
  square,
}

/// Marker clustering configuration
class MarkerClusterConfig {
  final int maxZoom;
  final int minClusterSize;
  final double gridSize;
  final bool averageCenter;
  final bool enableClustering;

  const MarkerClusterConfig({
    this.maxZoom = 15,
    this.minClusterSize = 2,
    this.gridSize = 60.0,
    this.averageCenter = false,
    this.enableClustering = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'maxZoom': maxZoom,
      'minClusterSize': minClusterSize,
      'gridSize': gridSize,
      'averageCenter': averageCenter,
      'enableClustering': enableClustering,
    };
  }
}

/// Marker animation types
enum MarkerAnimation {
  none,
  drop,
  bounce,
  fade,
}

/// Marker info window configuration
class MarkerInfoConfig {
  final bool showTitle;
  final bool showSnippet;
  final bool showCustomView;
  final double maxWidth;

  const MarkerInfoConfig({
    this.showTitle = true,
    this.showSnippet = true,
    this.showCustomView = false,
    this.maxWidth = 300.0,
  });
}