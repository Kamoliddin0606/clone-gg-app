import 'package:flutter/foundation.dart';
import 'package:yandex_maps_mapkit/mapkit.dart' as mk;
import 'package:yandex_maps_mapkit/image.dart' as yimg;

class MarkerIconLoader {
  const MarkerIconLoader();

  Future<dynamic> tryLoad(String assetPath) async {
    try {
      // Safe asset loading with proper error handling
      final provider = yimg.AnimatedImageProvider.fromAsset(assetPath);
      return provider;
    } catch (e) {
      debugPrint('MarkerIconLoader.tryLoad error: $e');
      return null;
    }
  }

  Future<void> applyToPlacemark(
    mk.PlacemarkMapObject placemark, {
    String? assetPath,
    String? fallbackAssetPath,
  }) async {
    dynamic provider;
    if (assetPath != null) {
      provider = await tryLoad(assetPath);
      if (provider == null && fallbackAssetPath != null) {
        provider = await tryLoad(fallbackAssetPath);
      }
    }

    if (provider != null) {
      final style = mk.IconStyle();
      try {
        final comp = placemark.useCompositeIcon();
        comp.setIcon(provider, style, name: 'marker');
        return;
      } catch (_) {
        // ignore
      }
      try {
        final icon = placemark.useIcon();
        icon.setImageWithStyle(provider, style);
        return;
      } catch (e) {
        debugPrint('applyToPlacemark simple icon failed: $e');
      }
    }

    // Default marker styling (Google/OSM-like)
    try {
      // Yandex Maps will use default marker appearance
      // Just ensure basic properties are set
      placemark.opacity = 1.0;
      placemark.zIndex = 10.0;
    } catch (e) {
      debugPrint('applyToPlacemark default style failed: $e');
    }
  }
}