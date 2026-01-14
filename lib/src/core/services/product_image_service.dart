import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_image.dart';

/// Image size categories for adaptive URL selection
/// 
/// Different UI contexts require different image sizes for optimal
/// performance and visual quality:
/// - [thumbnail]: 48-64px - compact list items, small indicators
/// - [small]: 80-120px - standard list view items
/// - [medium]: 150-200px - grid view items
/// - [large]: 300+px - detail views, full-screen displays
enum ProductImageSize {
  /// 48-64px - compact list items, small indicators
  thumbnail,
  
  /// 80-120px - standard list view items
  small,
  
  /// 150-200px - grid view items
  medium,
  
  /// 300+px - detail views, full-screen displays
  large,
}

/// Service for managing product images with caching and size-aware URL selection
/// 
/// This service provides:
/// - In-memory LRU cache for fast repeated access
/// - Size-aware URL selection for optimal network/quality balance
/// - Batch loading for efficient list rendering
/// - Cache invalidation on sync
/// 
/// Usage:
/// ```dart
/// final imageService = sl<ProductImageService>();
/// final image = await imageService.getMainImage('PRODUCT_CODE');
/// final url = imageService.selectImageUrl(image, ProductImageSize.small);
/// ```
class ProductImageService {
  final ApiDatabaseService _dbService;
  
  // LRU cache configuration
  static const int _maxCacheSize = 200;
  static const Duration _cacheValidDuration = Duration(hours: 1);
  
  // In-memory cache: productCode -> cached entry
  final Map<String, _CacheEntry<ProductImage?>> _mainImageCache = {};
  final Map<String, _CacheEntry<List<ProductImage>>> _allImagesCache = {};
  
  // Batch cache for list rendering (reserved for future use)
  Map<String, ProductImage>? _batchMainImageCache;
  
  ProductImageService({ApiDatabaseService? dbService})
      : _dbService = dbService ?? sl<ApiDatabaseService>();

  // =========================================================================
  // Main Image Retrieval
  // =========================================================================

  /// Get the main product image for a single product
  /// 
  /// Returns the main image (is_main=true) or the most recent image
  /// if no main image is set. Returns null if no image exists.
  /// 
  /// Uses in-memory cache for fast repeated access.
  Future<ProductImage?> getMainImage(String productCode) async {
    if (productCode.isEmpty) return null;

    // Check cache first
    final cached = _mainImageCache[productCode];
    if (cached != null && !cached.isExpired) {
      if (kDebugMode) {
        print('ProductImageService: Cache hit for $productCode');
      }
      return cached.value;
    }

    // Fetch from database
    if (kDebugMode) {
      print('ProductImageService: Fetching from DB for productCode: $productCode');
    }
    final image = await _dbService.getMainProductImage(productCode);
    
    if (kDebugMode) {
      print('ProductImageService: DB returned image: ${image != null ? "YES (${image.productCode})" : "NULL"}');
    }
    
    // Update cache
    _mainImageCache[productCode] = _CacheEntry(image);
    _evictOldEntries(_mainImageCache);

    return image;
  }

  /// Get all images for a single product
  /// 
  /// Returns all images ordered by is_main DESC, created_at DESC.
  Future<List<ProductImage>> getAllImages(String productCode) async {
    if (productCode.isEmpty) return [];

    // Check cache
    final cached = _allImagesCache[productCode];
    if (cached != null && !cached.isExpired) {
      return cached.value;
    }

    // Fetch from database
    final images = await _dbService.getProductImages(productCode);
    
    // Update cache
    _allImagesCache[productCode] = _CacheEntry(images);
    _evictOldEntries(_allImagesCache);

    return images;
  }

  // =========================================================================
  // Batch Loading (for lists)
  // =========================================================================

  /// Pre-load main images for multiple products
  /// 
  /// Optimized for list rendering - loads all images in a single
  /// database query and caches them for fast access.
  /// 
  /// Call this before rendering a product list to avoid N+1 queries.
  Future<void> preloadMainImages(List<String> productCodes) async {
    if (productCodes.isEmpty) return;

    // Filter out already cached codes
    final codesToLoad = productCodes
        .where((code) {
          final cached = _mainImageCache[code];
          return cached == null || cached.isExpired;
        })
        .toList();

    if (codesToLoad.isEmpty) return;

    // Batch load from database
    final images = await _dbService.getMainProductImagesBatch(codesToLoad);

    // Update cache
    for (final code in codesToLoad) {
      _mainImageCache[code] = _CacheEntry(images[code]);
    }
    _evictOldEntries(_mainImageCache);

    if (kDebugMode) {
      print('ProductImageService: Preloaded ${images.length} main images');
    }
  }

  /// Get main image from preloaded cache synchronously
  /// 
  /// Returns cached image or null. Use after calling preloadMainImages().
  ProductImage? getCachedMainImage(String productCode) {
    final cached = _mainImageCache[productCode];
    if (cached != null && !cached.isExpired) {
      return cached.value;
    }
    return null;
  }

  /// Check if a product has a cached main image
  bool hasMainImage(String productCode) {
    final cached = _mainImageCache[productCode];
    return cached != null && !cached.isExpired && cached.value != null;
  }

  // =========================================================================
  // Size-Aware URL Selection
  // =========================================================================

  /// Select the optimal image URL based on requested size
  /// 
  /// Automatically falls back to available sizes if the requested
  /// size is not available. Prioritizes smaller sizes for better
  /// performance when exact size is not critical.
  /// 
  /// Returns null if no valid URL is available.
  String? selectImageUrl(ProductImage? image, ProductImageSize size) {
    if (image == null) return null;

    switch (size) {
      case ProductImageSize.thumbnail:
        // Smallest available - prefer thumbnail, then small
        return image.imageThumbnailUrl ?? 
               image.imageSmUrl ?? 
               image.imageMdUrl ?? 
               image.imageUrl ?? 
               image.image;
               
      case ProductImageSize.small:
        // Small size - prefer sm, fall back to thumbnail or medium
        return image.imageSmUrl ?? 
               image.imageThumbnailUrl ?? 
               image.imageMdUrl ?? 
               image.imageUrl ?? 
               image.image;
               
      case ProductImageSize.medium:
        // Medium size - prefer md, fall back to sm or lg
        return image.imageMdUrl ?? 
               image.imageSmUrl ?? 
               image.imageLgUrl ?? 
               image.imageUrl ?? 
               image.image;
               
      case ProductImageSize.large:
        // Large size - prefer lg, fall back to original or md
        return image.imageLgUrl ?? 
               image.imageMdUrl ?? 
               image.imageUrl ?? 
               image.image ?? 
               image.imageSmUrl;
    }
  }

  /// Get image dimensions string for the selected size
  /// 
  /// Returns dimensions in format "WIDTHxHEIGHT" or null if not available.
  String? getImageDimensions(ProductImage? image, ProductImageSize size) {
    if (image == null) return null;

    switch (size) {
      case ProductImageSize.thumbnail:
        return image.imageThumbnailDimensions ?? image.imageSmDimensions;
      case ProductImageSize.small:
        return image.imageSmDimensions ?? image.imageThumbnailDimensions;
      case ProductImageSize.medium:
        return image.imageMdDimensions ?? image.imageSmDimensions;
      case ProductImageSize.large:
        return image.imageLgDimensions ?? image.imageMdDimensions ?? image.imageDimensions;
    }
  }

  // =========================================================================
  // Cache Management
  // =========================================================================

  /// Clear all cached images
  /// 
  /// Call this after sync operations to ensure fresh data is loaded.
  void clearCache() {
    _mainImageCache.clear();
    _allImagesCache.clear();
    _batchMainImageCache = null;
    
    if (kDebugMode) {
      print('ProductImageService: Cache cleared');
    }
  }

  /// Clear cache for specific product
  void clearCacheForProduct(String productCode) {
    _mainImageCache.remove(productCode);
    _allImagesCache.remove(productCode);
    _batchMainImageCache?.remove(productCode);
  }

  /// Evict oldest entries when cache exceeds max size
  void _evictOldEntries<T>(Map<String, _CacheEntry<T>> cache) {
    if (cache.length <= _maxCacheSize) return;

    // Remove expired entries first
    cache.removeWhere((_, entry) => entry.isExpired);

    // If still over limit, remove oldest entries
    if (cache.length > _maxCacheSize) {
      final entries = cache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
      
      final toRemove = entries.take(cache.length - _maxCacheSize);
      for (final entry in toRemove) {
        cache.remove(entry.key);
      }
    }
  }

  // =========================================================================
  // Utility Methods
  // =========================================================================

  /// Check if any image URL is available for a product image
  bool hasValidUrl(ProductImage? image) {
    if (image == null) return false;
    return image.imageUrl != null ||
           image.image != null ||
           image.imageThumbnailUrl != null ||
           image.imageSmUrl != null ||
           image.imageMdUrl != null ||
           image.imageLgUrl != null;
  }

  /// Get the best available URL regardless of size preference
  String? getBestAvailableUrl(ProductImage? image) {
    if (image == null) return null;
    return image.imageMdUrl ??
           image.imageSmUrl ??
           image.imageLgUrl ??
           image.imageUrl ??
           image.image ??
           image.imageThumbnailUrl;
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'mainImageCacheSize': _mainImageCache.length,
      'allImagesCacheSize': _allImagesCache.length,
      'maxCacheSize': _maxCacheSize,
      'cacheValidDuration': _cacheValidDuration.inMinutes,
    };
  }
}

/// Internal cache entry with timestamp for expiration
class _CacheEntry<T> {
  final T value;
  final DateTime timestamp;

  _CacheEntry(this.value) : timestamp = DateTime.now();

  bool get isExpired {
    return DateTime.now().difference(timestamp) > ProductImageService._cacheValidDuration;
  }
}
