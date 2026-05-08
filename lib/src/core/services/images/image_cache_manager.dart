import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Singleton [CacheManager] dedicated to entity (product / customer /
/// project) images.
///
/// Kept separate from [DefaultCacheManager] so this manager's eviction
/// policy doesn't fight app-wide image caching (avatars, banner art,
/// etc.). Numbers below are picked for sales agents' phones, which
/// tend to be space-constrained:
///
/// * `stalePeriod = 30 days` — honours the backend's
///   `Cache-Control: public, max-age=31536000, immutable` header but
///   caps storage at 30 days so unused variants can age out.
/// * `maxNrOfCacheObjects = 2000` — roughly 500 MB of WebP variants
///   on typical product photos.
class ImageCacheManager {
  ImageCacheManager._();

  static const String _key = 'selupEntityImages';

  static final CacheManager instance = CacheManager(
    Config(
      _key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 2000,
    ),
  );
}
