import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/map_point.dart';
import '../models/map_route.dart';
import '../models/map_marker.dart';
import '../models/map_settings.dart';

/// Map cache service for offline support
class MapCacheService {
  static const String _cacheDirectory = 'map_cache';
  static const String _tilesDirectory = 'tiles';
  static const String _routesDirectory = 'routes';
  static const String _markersDirectory = 'markers';
  static const String _metadataFile = 'cache_metadata.json';

  static const Duration _defaultCacheDuration = Duration(days: 30);
  static const int _maxCacheSizeMB = 500; // 500MB limit

  late final Directory _cacheDir;
  bool _initialized = false;

  /// Initialize cache service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory(path.join(appDir.path, _cacheDirectory));

      if (!await _cacheDir.exists()) {
        await _cacheDir.create(recursive: true);
      }

      // Create subdirectories
      await _createSubdirectories();

      // Clean up expired cache
      await _cleanupExpiredCache();

      _initialized = true;

      if (kDebugMode) {
        print('Map cache service initialized at: ${_cacheDir.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing map cache service: $e');
      }
      rethrow;
    }
  }

  /// Create cache subdirectories
  Future<void> _createSubdirectories() async {
    final subdirs = [_tilesDirectory, _routesDirectory, _markersDirectory];

    for (final subdir in subdirs) {
      final dir = Directory(path.join(_cacheDir.path, subdir));
      if (!await dir.exists()) {
        await dir.create();
      }
    }
  }

  /// Cache map tiles for offline use
  Future<void> cacheTiles({
    required MapPoint center,
    required double radiusKm,
    required int minZoom,
    required int maxZoom,
    MapProvider provider = MapProvider.openStreetMap,
  }) async {
    await _ensureInitialized();

    try {
      final tiles = _calculateTilesToCache(center, radiusKm, minZoom, maxZoom);
      final cacheKey = _generateTileCacheKey(center, radiusKm, minZoom, maxZoom, provider);

      if (kDebugMode) {
        print('Caching ${tiles.length} tiles for area around ${center.title}');
      }

      // Download and cache tiles
      for (final tile in tiles) {
        await _downloadAndCacheTile(tile, provider, cacheKey);
        // Small delay to avoid overwhelming the server
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Update cache metadata
      await _updateCacheMetadata(cacheKey, {
        'type': 'tiles',
        'center': center.toMap(),
        'radius': radiusKm,
        'minZoom': minZoom,
        'maxZoom': maxZoom,
        'provider': provider.toString(),
        'tileCount': tiles.length,
        'createdAt': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      if (kDebugMode) {
        print('Error caching tiles: $e');
      }
      rethrow;
    }
  }

  /// Calculate which tiles need to be cached
  List<Map<String, dynamic>> _calculateTilesToCache(
    MapPoint center,
    double radiusKm,
    int minZoom,
    int maxZoom,
  ) {
    final tiles = <Map<String, dynamic>>[];

    for (int zoom = minZoom; zoom <= maxZoom; zoom++) {
      final tileRange = _calculateTileRange(center, radiusKm, zoom);

      for (int x = tileRange['minX']!; x <= tileRange['maxX']!; x++) {
        for (int y = tileRange['minY']!; y <= tileRange['maxY']!; y++) {
          tiles.add({
            'x': x,
            'y': y,
            'z': zoom,
          });
        }
      }
    }

    return tiles;
  }

  /// Calculate tile range for given area
  Map<String, int> _calculateTileRange(MapPoint center, double radiusKm, int zoom) {
    final tileSize = _getTileSizeAtZoom(zoom);
    final centerTile = _latLngToTile(center.latitude, center.longitude, zoom);

    // Calculate how many tiles radius covers
    final radiusTiles = (radiusKm * 1000) / tileSize;

    return {
      'minX': (centerTile['x']! - radiusTiles).round().clamp(0, _getMaxTileX(zoom)),
      'maxX': (centerTile['x']! + radiusTiles).round().clamp(0, _getMaxTileX(zoom)),
      'minY': (centerTile['y']! - radiusTiles).round().clamp(0, _getMaxTileY(zoom)),
      'maxY': (centerTile['y']! + radiusTiles).round().clamp(0, _getMaxTileY(zoom)),
    };
  }

  /// Convert lat/lng to tile coordinates
  Map<String, double> _latLngToTile(double lat, double lng, int zoom) {
    final n = pow(2, zoom);
    final x = ((lng + 180) / 360) * n;
    final latRad = lat * pi / 180;
    final y = (1 - (log(tan(latRad) + 1 / cos(latRad)) / pi)) / 2 * n;

    return {'x': x, 'y': y};
  }

  /// Get tile size in meters at given zoom level
  double _getTileSizeAtZoom(int zoom) {
    // Approximate tile size calculation
    const earthCircumference = 40075016.686; // meters
    return earthCircumference * cos(0) / pow(2, zoom + 8); // Rough approximation
  }

  /// Get maximum tile X coordinate for zoom level
  int _getMaxTileX(int zoom) => (1 << zoom) - 1;

  /// Get maximum tile Y coordinate for zoom level
  int _getMaxTileY(int zoom) => (1 << zoom) - 1;

  /// Download and cache individual tile
  Future<void> _downloadAndCacheTile(
    Map<String, dynamic> tile,
    MapProvider provider,
    String cacheKey,
  ) async {
    final tilePath = _getTileCachePath(tile, provider, cacheKey);
    final tileFile = File(tilePath);

    if (await tileFile.exists()) {
      return; // Already cached
    }

    final tileUrl = _getTileUrl(tile, provider);

    try {
      // TODO: Implement actual HTTP download
      // For now, create placeholder
      await tileFile.writeAsBytes([0]); // Placeholder byte

      if (kDebugMode) {
        print('Cached tile: ${tile['z']}/${tile['x']}/${tile['y']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading tile ${tile['z']}/${tile['x']}/${tile['y']}: $e');
      }
    }
  }

  /// Get tile URL for provider
  String _getTileUrl(Map<String, dynamic> tile, MapProvider provider) {
    final z = tile['z'];
    final x = tile['x'];
    final y = tile['y'];

    switch (provider) {
      case MapProvider.google:
        // Note: Google tiles require API key and may have usage restrictions
        return 'https://mt.google.com/vt/lyrs=m&x=$x&y=$y&z=$z';
      case MapProvider.yandex:
        return 'https://core-renderer-tiles.maps.yandex.net/tiles?l=map&x=$x&y=$y&z=$z&scale=1&lang=ru_RU';
      case MapProvider.openStreetMap:
      default:
        return 'https://tile.openstreetmap.org/$z/$x/$y.png';
    }
  }

  /// Get tile cache path
  String _getTileCachePath(Map<String, dynamic> tile, MapProvider provider, String cacheKey) {
    final tilesDir = Directory(path.join(_cacheDir.path, _tilesDirectory, cacheKey));
    if (!tilesDir.existsSync()) {
      tilesDir.createSync(recursive: true);
    }

    final z = tile['z'];
    final x = tile['x'];
    final y = tile['y'];

    return path.join(tilesDir.path, '$z', '$x', '$y.png');
  }

  /// Generate cache key for tiles
  String _generateTileCacheKey(MapPoint center, double radius, int minZoom, int maxZoom, MapProvider provider) {
    return '${provider.toString()}_${center.id}_${radius}_${minZoom}_${maxZoom}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Cache route data for offline use
  Future<void> cacheRoute(MapRoute route) async {
    await _ensureInitialized();

    try {
      final routeKey = 'route_${route.id}';
      final routeFile = File(path.join(_cacheDir.path, _routesDirectory, '$routeKey.json'));

      final routeData = {
        'route': route.toMap(),
        'cachedAt': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now().add(_defaultCacheDuration).toIso8601String(),
      };

      await routeFile.writeAsString(jsonEncode(routeData));

      await _updateCacheMetadata(routeKey, {
        'type': 'route',
        'routeId': route.id,
        'distance': route.distance,
        'waypoints': route.points.length,
        'cachedAt': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('Cached route: ${route.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error caching route: $e');
      }
      rethrow;
    }
  }

  /// Get cached route
  Future<MapRoute?> getCachedRoute(String routeId) async {
    await _ensureInitialized();

    try {
      final routeFile = File(path.join(_cacheDir.path, _routesDirectory, 'route_$routeId.json'));

      if (!await routeFile.exists()) {
        return null;
      }

      final routeData = jsonDecode(await routeFile.readAsString());

      // Check if expired
      final expiresAt = DateTime.parse(routeData['expiresAt']);
      if (DateTime.now().isAfter(expiresAt)) {
        await routeFile.delete();
        return null;
      }

      return MapRouteSerialization.fromMap(routeData['route']);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cached route: $e');
      }
      return null;
    }
  }

  /// Cache markers for offline use
  Future<void> cacheMarkers(List<MapMarker> markers, String areaId) async {
    await _ensureInitialized();

    try {
      final markersFile = File(path.join(_cacheDir.path, _markersDirectory, '$areaId.json'));

      final markersData = {
        'areaId': areaId,
        'markers': markers.map((m) => m.toMap()).toList(),
        'cachedAt': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now().add(_defaultCacheDuration).toIso8601String(),
      };

      await markersFile.writeAsString(jsonEncode(markersData));

      await _updateCacheMetadata(areaId, {
        'type': 'markers',
        'areaId': areaId,
        'markerCount': markers.length,
        'cachedAt': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('Cached ${markers.length} markers for area: $areaId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error caching markers: $e');
      }
      rethrow;
    }
  }

  /// Get cached markers
  Future<List<MapMarker>?> getCachedMarkers(String areaId) async {
    await _ensureInitialized();

    try {
      final markersFile = File(path.join(_cacheDir.path, _markersDirectory, '$areaId.json'));

      if (!await markersFile.exists()) {
        return null;
      }

      final markersData = jsonDecode(await markersFile.readAsString());

      // Check if expired
      final expiresAt = DateTime.parse(markersData['expiresAt']);
      if (DateTime.now().isAfter(expiresAt)) {
        await markersFile.delete();
        return null;
      }

      return (markersData['markers'] as List)
          .map((m) => MapMarkerSerialization.fromMap(m))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cached markers: $e');
      }
      return null;
    }
  }

  /// Check if area is cached
  Future<bool> isAreaCached(MapPoint center, double radius) async {
    await _ensureInitialized();

    try {
      final metadata = await _loadCacheMetadata();

      for (final entry in metadata.values) {
        if (entry['type'] == 'tiles') {
          final cachedCenter = MapPoint.fromMap(entry['center']);
          final cachedRadius = entry['radius'] as double;

          if (_isPointInRadius(center, cachedCenter, cachedRadius) &&
              radius <= cachedRadius) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking cached area: $e');
      }
      return false;
    }
  }

  /// Check if point is within radius of center
  bool _isPointInRadius(MapPoint point, MapPoint center, double radius) {
    return point.distanceTo(center) <= radius;
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _ensureInitialized();

    try {
      await _cacheDir.delete(recursive: true);
      await _cacheDir.create(recursive: true);
      await _createSubdirectories();

      if (kDebugMode) {
        print('Cleared all map cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing cache: $e');
      }
      rethrow;
    }
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    await _ensureInitialized();

    try {
      return await _calculateDirectorySize(_cacheDir);
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating cache size: $e');
      }
      return 0;
    }
  }

  /// Calculate directory size recursively
  Future<int> _calculateDirectorySize(Directory dir) async {
    int size = 0;

    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          size += await entity.length();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating directory size: $e');
      }
    }

    return size;
  }

  /// Clean up expired cache entries
  Future<void> _cleanupExpiredCache() async {
    try {
      final metadata = await _loadCacheMetadata();
      final now = DateTime.now();
      final toRemove = <String>[];

      for (final entry in metadata.entries) {
        final expiresAt = DateTime.parse(entry.value['expiresAt'] ?? now.add(_defaultCacheDuration).toIso8601String());
        if (now.isAfter(expiresAt)) {
          toRemove.add(entry.key);
        }
      }

      for (final key in toRemove) {
        await _removeCacheEntry(key);
        metadata.remove(key);
      }

      if (toRemove.isNotEmpty) {
        await _saveCacheMetadata(metadata);
        if (kDebugMode) {
          print('Cleaned up ${toRemove.length} expired cache entries');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up expired cache: $e');
      }
    }
  }

  /// Remove cache entry
  Future<void> _removeCacheEntry(String key) async {
    try {
      final metadata = await _loadCacheMetadata();
      final entry = metadata[key];
      if (entry == null) return;

      switch (entry['type']) {
        case 'tiles':
          final tilesDir = Directory(path.join(_cacheDir.path, _tilesDirectory, key));
          if (await tilesDir.exists()) {
            await tilesDir.delete(recursive: true);
          }
          break;
        case 'route':
          final routeFile = File(path.join(_cacheDir.path, _routesDirectory, 'route_$key.json'));
          if (await routeFile.exists()) {
            await routeFile.delete();
          }
          break;
        case 'markers':
          final markersFile = File(path.join(_cacheDir.path, _markersDirectory, '$key.json'));
          if (await markersFile.exists()) {
            await markersFile.delete();
          }
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error removing cache entry $key: $e');
      }
    }
  }

  /// Update cache metadata
  Future<void> _updateCacheMetadata(String key, Map<String, dynamic> data) async {
    final metadata = await _loadCacheMetadata();
    metadata[key] = {
      ...data,
      'expiresAt': DateTime.now().add(_defaultCacheDuration).toIso8601String(),
    };
    await _saveCacheMetadata(metadata);
  }

  /// Load cache metadata
  Future<Map<String, dynamic>> _loadCacheMetadata() async {
    try {
      final metadataFile = File(path.join(_cacheDir.path, _metadataFile));
      if (!await metadataFile.exists()) {
        return {};
      }

      final content = await metadataFile.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cache metadata: $e');
      }
      return {};
    }
  }

  /// Save cache metadata
  Future<void> _saveCacheMetadata(Map<String, dynamic> metadata) async {
    try {
      final metadataFile = File(path.join(_cacheDir.path, _metadataFile));
      await metadataFile.writeAsString(jsonEncode(metadata));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving cache metadata: $e');
      }
    }
  }

  /// Ensure service is initialized
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    await _ensureInitialized();

    try {
      final metadata = await _loadCacheMetadata();
      final cacheSize = await getCacheSize();

      int tileAreas = 0;
      int routes = 0;
      int markerAreas = 0;

      for (final entry in metadata.values) {
        switch (entry['type']) {
          case 'tiles':
            tileAreas++;
            break;
          case 'route':
            routes++;
            break;
          case 'markers':
            markerAreas++;
            break;
        }
      }

      return {
        'totalSize': cacheSize,
        'totalSizeMB': (cacheSize / (1024 * 1024)).round(),
        'tileAreas': tileAreas,
        'routes': routes,
        'markerAreas': markerAreas,
        'maxSizeMB': _maxCacheSizeMB,
        'cachePath': _cacheDir.path,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cache stats: $e');
      }
      return {};
    }
  }
}

/// Extension methods for model serialization
extension MapRouteSerialization on MapRoute {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'points': points.map((p) => p.toMap()).toList(),
      'coordinates': coordinates,
      'distance': distance,
      'estimatedTime': estimatedTime.inMilliseconds,
      'travelMode': travelMode.toString(),
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static MapRoute fromMap(Map<String, dynamic> map) {
    return MapRoute(
      id: map['id'],
      points: (map['points'] as List).map((p) => MapPoint.fromMap(p)).toList(),
      coordinates: (map['coordinates'] as List).cast<List<double>>(),
      distance: map['distance'],
      estimatedTime: Duration(milliseconds: map['estimatedTime']),
      travelMode: TravelMode.values.firstWhere(
        (e) => e.toString() == map['travelMode'],
        orElse: () => TravelMode.driving,
      ),
      metadata: map['metadata'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

extension MapMarkerSerialization on MapMarker {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'point': point.toMap(),
      'type': type.toString(),
      'icon': icon.toString(),
      'title': title,
      'snippet': snippet,
      'isDraggable': isDraggable,
      'isVisible': isVisible,
      'zIndex': zIndex,
      'metadata': metadata,
    };
  }

  static MapMarker fromMap(Map<String, dynamic> map) {
    return MapMarker(
      id: map['id'],
      point: MapPoint.fromMap(map['point']),
      type: MarkerType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => MarkerType.default_,
      ),
      icon: MarkerIcon.values.firstWhere(
        (e) => e.toString() == map['icon'],
        orElse: () => MarkerIcon.default_,
      ),
      title: map['title'],
      snippet: map['snippet'],
      isDraggable: map['isDraggable'] ?? false,
      isVisible: map['isVisible'] ?? true,
      zIndex: map['zIndex'] ?? 0.0,
      metadata: map['metadata'],
    );
  }
}