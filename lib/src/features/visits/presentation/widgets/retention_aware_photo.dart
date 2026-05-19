import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

import '../../domain/entities/entity_image_ref.dart';

/// Displays a visit photo with a built-in fallback chain for the
/// backend's 30/90-day retention policy.
///
/// Order ([thumbnail]==`true`):
///   1. `smallUrl` — present in days 0-30
///   2. `mediumUrl` — present in days 0-90
///   3. `blurhash` — present until hard-delete at day 90
///   4. A neutral placeholder icon
///
/// Order ([thumbnail]==`false`, full-screen):
///   1. `largeUrl`
///   2. `mediumUrl`
///   3. `blurhash`
///   4. Placeholder
///
/// We rely on [CachedNetworkImage]'s `errorWidget` to walk to the next
/// step — a 404 on `small`/`large` (retention purge) cleanly drops to
/// `medium` without an extra HEAD probe. The blurhash is rendered
/// inline rather than at the same DPR as the missing variant because
/// it's an approximation, not a placeholder for an in-flight load.
class RetentionAwarePhoto extends StatelessWidget {
  const RetentionAwarePhoto({
    super.key,
    required this.image,
    this.thumbnail = true,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final EntityImageRef image;
  final bool thumbnail;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final primary = thumbnail ? image.smallUrl : image.largeUrl;
    final secondary = image.mediumUrl;

    if (primary != null) {
      return _cached(
        primary,
        onError: () => _secondaryOrPlaceholder(secondary),
      );
    }
    if (secondary != null) {
      return _cached(secondary, onError: _blurhashOrPlaceholder);
    }
    return _blurhashOrPlaceholder();
  }

  Widget _cached(String url, {required Widget Function() onError}) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, _) => _blurhashOrPlaceholder(),
      errorWidget: (context, _, _) => onError(),
    );
  }

  Widget _secondaryOrPlaceholder(String? secondary) {
    if (secondary != null) {
      return _cached(secondary, onError: _blurhashOrPlaceholder);
    }
    return _blurhashOrPlaceholder();
  }

  Widget _blurhashOrPlaceholder() {
    final hash = image.blurhash;
    if (hash != null && hash.isNotEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: BlurHash(hash: hash, imageFit: fit),
      );
    }
    return _Placeholder(width: width, height: height);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.width, this.height});
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.photo_outlined,
        color: theme.colorScheme.outline,
      ),
    );
  }
}
