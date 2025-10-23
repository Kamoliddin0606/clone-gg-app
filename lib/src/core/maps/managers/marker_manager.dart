import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/map_marker.dart';
import '../models/map_point.dart';
import '../models/map_settings.dart';

/// Advanced marker manager with clustering capabilities
class MarkerManager {
  final MarkerClusterConfig config;
  final MapProvider provider;

  MarkerManager({
    required this.config,
    required this.provider,
  });

  /// Process markers for display with clustering
  Future<List<MapMarker>> processMarkersForDisplay(
    List<MapMarker> markers,
    double zoom,
    MapPoint mapCenter,
    double viewportWidth,
    double viewportHeight,
  ) async {
    try {
      if (!config.enableClustering || zoom >= config.maxZoom) {
        // No clustering needed at high zoom levels
        return markers.where((m) => m.isVisible).toList();
      }

      if (markers.length <= config.minClusterSize) {
        return markers.where((m) => m.isVisible).toList();
      }

      // Apply clustering algorithm
      return await _clusterMarkers(markers, zoom, mapCenter, viewportWidth, viewportHeight);
    } catch (e) {
      if (kDebugMode) {
        print('Error processing markers for display: $e');
      }
      // Return unclustered markers as fallback
      return markers.where((m) => m.isVisible).toList();
    }
  }

  /// Cluster markers using grid-based algorithm
  Future<List<MapMarker>> _clusterMarkers(
    List<MapMarker> markers,
    double zoom,
    MapPoint mapCenter,
    double viewportWidth,
    double viewportHeight,
  ) async {
    final visibleMarkers = markers.where((m) => m.isVisible).toList();
    if (visibleMarkers.isEmpty) return [];

    // Calculate grid cell size based on zoom and viewport
    final cellSize = _calculateCellSize(zoom, viewportWidth, viewportHeight);

    // Group markers into grid cells
    final clusters = <String, List<MapMarker>>{};
    final unclustered = <MapMarker>[];

    for (final marker in visibleMarkers) {
      final cellKey = _getCellKey(marker.point, cellSize);

      if (clusters.containsKey(cellKey)) {
        clusters[cellKey]!.add(marker);
      } else {
        clusters[cellKey] = [marker];
      }
    }

    // Create cluster markers or keep individual markers
    final result = <MapMarker>[];

    for (final cluster in clusters.values) {
      if (cluster.length == 1) {
        // Single marker - keep as is
        result.add(cluster.first);
      } else if (cluster.length <= config.minClusterSize) {
        // Small cluster - keep individual markers
        result.addAll(cluster);
      } else {
        // Large cluster - create cluster marker
        final clusterMarker = _createClusterMarker(cluster);
        result.add(clusterMarker);
      }
    }

    return result;
  }

  /// Calculate grid cell size for clustering
  double _calculateCellSize(double zoom, double viewportWidth, double viewportHeight) {
    // Base cell size adjusted by zoom level
    final baseSize = config.gridSize;

    // Zoom factor (higher zoom = smaller cells)
    final zoomFactor = pow(2, config.maxZoom - zoom).toDouble();

    // Adjust for viewport size
    final viewportFactor = min(viewportWidth, viewportHeight) / 400.0;

    return baseSize * zoomFactor / viewportFactor;
  }

  /// Get grid cell key for a point
  String _getCellKey(MapPoint point, double cellSize) {
    final cellX = (point.longitude / cellSize).floor();
    final cellY = (point.latitude / cellSize).floor();
    return '${cellX}_${cellY}';
  }

  /// Create cluster marker from grouped markers
  MapMarker _createClusterMarker(List<MapMarker> markers) {
    // Calculate cluster center
    double totalLat = 0;
    double totalLng = 0;

    for (final marker in markers) {
      totalLat += marker.point.latitude;
      totalLng += marker.point.longitude;
    }

    final centerLat = totalLat / markers.length;
    final centerLng = totalLng / markers.length;

    final centerPoint = MapPoint(
      id: 'cluster_${DateTime.now().millisecondsSinceEpoch}',
      latitude: centerLat,
      longitude: centerLng,
      title: '${markers.length} ta nuqta',
      description: 'Klaster',
    );

    return MapMarker.cluster(
      id: centerPoint.id,
      point: centerPoint,
      count: markers.length,
    );
  }

  /// Expand cluster to show individual markers
  Future<List<MapMarker>> expandCluster(String clusterId, List<MapMarker> allMarkers) async {
    try {
      // Find all markers that were clustered together
      final clusterCenter = allMarkers.firstWhere(
        (m) => m.id == clusterId,
        orElse: () => throw ArgumentError('Cluster not found'),
      );

      if (!clusterCenter.isCluster) {
        return [clusterCenter];
      }

      // Find markers within cluster radius
      final clusterRadius = _calculateClusterRadius(clusterCenter.clusterCount);
      final nearbyMarkers = allMarkers.where((marker) {
        return marker.id != clusterId &&
               clusterCenter.point.distanceTo(marker.point) <= clusterRadius;
      }).toList();

      return nearbyMarkers;
    } catch (e) {
      if (kDebugMode) {
        print('Error expanding cluster: $e');
      }
      return [];
    }
  }

  /// Calculate cluster radius based on marker count
  double _calculateClusterRadius(int count) {
    // Larger clusters have larger effective radius
    return config.gridSize * sqrt(count).toDouble() / 10.0;
  }

  /// Filter markers by viewport
  Future<List<MapMarker>> filterMarkersByViewport(
    List<MapMarker> markers,
    MapPoint northEast,
    MapPoint southWest,
  ) async {
    try {
      return markers.where((marker) {
        final lat = marker.point.latitude;
        final lng = marker.point.longitude;

        return lat >= southWest.latitude &&
               lat <= northEast.latitude &&
               lng >= southWest.longitude &&
               lng <= northEast.longitude;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error filtering markers by viewport: $e');
      }
      return markers;
    }
  }

  /// Filter markers by distance from center
  Future<List<MapMarker>> filterMarkersByDistance(
    List<MapMarker> markers,
    MapPoint center,
    double maxDistanceKm,
  ) async {
    try {
      return markers.where((marker) {
        return center.distanceTo(marker.point) <= maxDistanceKm;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error filtering markers by distance: $e');
      }
      return markers;
    }
  }

  /// Sort markers by priority/distance
  Future<List<MapMarker>> sortMarkers(
    List<MapMarker> markers,
    MapPoint? userLocation,
    MarkerSortCriteria criteria,
  ) async {
    try {
      if (userLocation == null) return markers;

      switch (criteria) {
        case MarkerSortCriteria.distance:
          return markers.toList()
            ..sort((a, b) {
              final distA = userLocation.distanceTo(a.point);
              final distB = userLocation.distanceTo(b.point);
              return distA.compareTo(distB);
            });

        case MarkerSortCriteria.priority:
          return markers.toList()
            ..sort((a, b) {
              // Sort by marker type priority
              final priorityA = _getMarkerPriority(a.type);
              final priorityB = _getMarkerPriority(b.type);
              return priorityB.compareTo(priorityA); // Higher priority first
            });

        case MarkerSortCriteria.alphabetical:
          return markers.toList()
            ..sort((a, b) {
              final titleA = a.title ?? '';
              final titleB = b.title ?? '';
              return titleA.compareTo(titleB);
            });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sorting markers: $e');
      }
      return markers;
    }
  }

  /// Get marker priority for sorting
  int _getMarkerPriority(MarkerType type) {
    switch (type) {
      case MarkerType.visited:
        return 1;
      case MarkerType.today:
        return 2;
      case MarkerType.contract:
        return 3;
      case MarkerType.cluster:
        return 0; // Lowest priority
      default:
        return 1;
    }
  }

  /// Animate marker movement
  Future<void> animateMarker(
    String markerId,
    MapPoint from,
    MapPoint to,
    Duration duration,
    void Function(MapPoint) onPositionUpdate,
  ) async {
    try {
      const steps = 60; // 60 FPS animation
      final stepDuration = duration.inMilliseconds ~/ steps;

      for (int i = 0; i <= steps; i++) {
        final progress = i / steps;
        final currentLat = from.latitude + (to.latitude - from.latitude) * progress;
        final currentLng = from.longitude + (to.longitude - from.longitude) * progress;

        final currentPoint = MapPoint(
          id: markerId,
          latitude: currentLat,
          longitude: currentLng,
        );

        onPositionUpdate(currentPoint);
        await Future.delayed(Duration(milliseconds: stepDuration));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error animating marker: $e');
      }
    }
  }

  /// Get marker statistics
  Future<Map<String, dynamic>> getMarkerStatistics(List<MapMarker> markers) async {
    try {
      final stats = {
        'total': markers.length,
        'visible': markers.where((m) => m.isVisible).length,
        'clustered': markers.where((m) => m.isCluster).length,
        'byType': <String, int>{},
      };

      for (final marker in markers) {
        final typeKey = marker.type.toString();
        final byType = stats['byType'] as Map<String, int>;
        byType[typeKey] = (byType[typeKey] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating marker statistics: $e');
      }
      return {};
    }
  }

  /// Optimize marker rendering for performance
  Future<List<MapMarker>> optimizeForPerformance(
    List<MapMarker> markers,
    double zoom,
    MapPoint viewportCenter,
    double viewportRadiusKm,
  ) async {
    try {
      // Filter by distance first
      var optimized = await filterMarkersByDistance(markers, viewportCenter, viewportRadiusKm);

      // Apply clustering if too many markers
      if (optimized.length > 100) {
        optimized = await processMarkersForDisplay(
          optimized,
          zoom,
          viewportCenter,
          400, // Default viewport size
          600,
        );
      }

      // Limit maximum markers for performance
      if (optimized.length > 200) {
        optimized = optimized.sublist(0, 200);
      }

      return optimized;
    } catch (e) {
      if (kDebugMode) {
        print('Error optimizing markers for performance: $e');
      }
      return markers.take(100).toList(); // Return limited set as fallback
    }
  }
}

/// Marker sorting criteria
enum MarkerSortCriteria {
  distance,
  priority,
  alphabetical,
}

/// Marker clustering configuration
class MarkerClusterConfig {
  final int maxZoom;
  final int minClusterSize;
  final double gridSize;
  final bool averageCenter;
  final bool enableClustering;
  final Duration animationDuration;

  const MarkerClusterConfig({
    this.maxZoom = 15,
    this.minClusterSize = 2,
    this.gridSize = 60.0,
    this.averageCenter = false,
    this.enableClustering = true,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  MarkerClusterConfig copyWith({
    int? maxZoom,
    int? minClusterSize,
    double? gridSize,
    bool? averageCenter,
    bool? enableClustering,
    Duration? animationDuration,
  }) {
    return MarkerClusterConfig(
      maxZoom: maxZoom ?? this.maxZoom,
      minClusterSize: minClusterSize ?? this.minClusterSize,
      gridSize: gridSize ?? this.gridSize,
      averageCenter: averageCenter ?? this.averageCenter,
      enableClustering: enableClustering ?? this.enableClustering,
      animationDuration: animationDuration ?? this.animationDuration,
    );
  }
}

/// Advanced clustering algorithms
class ClusteringAlgorithms {
  /// K-means clustering for markers
  static Future<List<MapMarker>> kMeansClustering(
    List<MapMarker> markers,
    int k,
    int maxIterations,
  ) async {
    if (markers.length <= k) return markers;

    try {
      // Initialize centroids randomly
      final centroids = <MapPoint>[];
      final random = Random();

      for (int i = 0; i < k; i++) {
        final randomMarker = markers[random.nextInt(markers.length)];
        centroids.add(randomMarker.point);
      }

      List<List<MapMarker>> clusters = [];

      for (int iteration = 0; iteration < maxIterations; iteration++) {
        // Assign markers to nearest centroid
        clusters = List.generate(k, (_) => <MapMarker>[]);

        for (final marker in markers) {
          int nearestCentroid = 0;
          double minDistance = marker.point.distanceTo(centroids[0]);

          for (int i = 1; i < centroids.length; i++) {
            final distance = marker.point.distanceTo(centroids[i]);
            if (distance < minDistance) {
              minDistance = distance;
              nearestCentroid = i;
            }
          }

          clusters[nearestCentroid].add(marker);
        }

        // Update centroids
        bool centroidsChanged = false;
        for (int i = 0; i < k; i++) {
          if (clusters[i].isNotEmpty) {
            final newCentroid = _calculateCentroid(clusters[i]);
            if (newCentroid.distanceTo(centroids[i]) > 0.001) {
              centroids[i] = newCentroid;
              centroidsChanged = true;
            }
          }
        }

        if (!centroidsChanged) break;
      }

      // Create cluster markers
      final result = <MapMarker>[];
      for (final cluster in clusters) {
        if (cluster.length == 1) {
          result.add(cluster.first);
        } else if (cluster.isNotEmpty) {
          final clusterMarker = MapMarker.cluster(
            id: 'kmeans_cluster_${DateTime.now().millisecondsSinceEpoch}_${clusters.indexOf(cluster)}',
            point: _calculateCentroid(cluster),
            count: cluster.length,
          );
          result.add(clusterMarker);
        }
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error in K-means clustering: $e');
      }
      return markers;
    }
  }

  /// Calculate centroid of marker cluster
  static MapPoint _calculateCentroid(List<MapMarker> markers) {
    double totalLat = 0;
    double totalLng = 0;

    for (final marker in markers) {
      totalLat += marker.point.latitude;
      totalLng += marker.point.longitude;
    }

    return MapPoint(
      id: 'centroid_${DateTime.now().millisecondsSinceEpoch}',
      latitude: totalLat / markers.length,
      longitude: totalLng / markers.length,
    );
  }

  /// Hierarchical clustering
  static Future<List<MapMarker>> hierarchicalClustering(
    List<MapMarker> markers,
    double maxDistance,
  ) async {
    try {
      final clusters = markers.map((m) => [m]).toList();

      while (clusters.length > 1) {
        double minDistance = double.infinity;
        int mergeIndex1 = -1;
        int mergeIndex2 = -1;

        // Find closest clusters
        for (int i = 0; i < clusters.length; i++) {
          for (int j = i + 1; j < clusters.length; j++) {
            final distance = _clusterDistance(clusters[i], clusters[j]);
            if (distance < minDistance) {
              minDistance = distance;
              mergeIndex1 = i;
              mergeIndex2 = j;
            }
          }
        }

        if (minDistance > maxDistance) break;

        // Merge clusters
        clusters[mergeIndex1].addAll(clusters[mergeIndex2]);
        clusters.removeAt(mergeIndex2);
      }

      // Create cluster markers
      final result = <MapMarker>[];
      for (final cluster in clusters) {
        if (cluster.length == 1) {
          result.add(cluster.first);
        } else {
          final clusterMarker = MapMarker.cluster(
            id: 'hierarchical_cluster_${DateTime.now().millisecondsSinceEpoch}_${clusters.indexOf(cluster)}',
            point: _calculateCentroid(cluster),
            count: cluster.length,
          );
          result.add(clusterMarker);
        }
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error in hierarchical clustering: $e');
      }
      return markers;
    }
  }

  /// Calculate distance between two clusters
  static double _clusterDistance(List<MapMarker> cluster1, List<MapMarker> cluster2) {
    double minDistance = double.infinity;

    for (final m1 in cluster1) {
      for (final m2 in cluster2) {
        final distance = m1.point.distanceTo(m2.point);
        if (distance < minDistance) {
          minDistance = distance;
        }
      }
    }

    return minDistance;
  }
}