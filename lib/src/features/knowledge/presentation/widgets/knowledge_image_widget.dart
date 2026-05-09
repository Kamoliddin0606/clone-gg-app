import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_media.dart';

/// Display sizes a knowledge image widget may request.
enum KnowledgeImageSize { thumbnail, small, medium, large }

/// Renders a [KnowledgeMedia] inline, using the BlurHash placeholder
/// while the network image loads.
///
/// Differs from `ProductImageWidget` in that the URL ladder
/// (small/medium/large) is already attached to the media model — there
/// is no separate `/api/mobile/v1/images/` round-trip. This is because
/// knowledge documents inline their cover/block media in the document
/// detail payload itself.
class KnowledgeImageWidget extends StatelessWidget {
  final KnowledgeMedia? media;
  final KnowledgeImageSize size;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? heroTag;
  final Widget? placeholder;
  final Widget? errorWidget;

  const KnowledgeImageWidget({
    super.key,
    required this.media,
    this.size = KnowledgeImageSize.medium,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.heroTag,
    this.placeholder,
    this.errorWidget,
  });

  String? _urlFor(KnowledgeMedia m) {
    switch (size) {
      case KnowledgeImageSize.thumbnail:
      case KnowledgeImageSize.small:
        return m.bestUrlFor(preferred: 'small');
      case KnowledgeImageSize.large:
        return m.bestUrlFor(preferred: 'large');
      case KnowledgeImageSize.medium:
        return m.bestUrlFor(preferred: 'medium');
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = media;
    if (m == null) {
      return _wrap(_emptyPlaceholder(context));
    }
    final url = _urlFor(m);
    if (url == null || url.isEmpty) {
      return _wrap(_emptyPlaceholder(context));
    }

    Widget image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, _) => _placeholder(context, m),
      errorWidget: (_, _, _) => errorWidget ?? _emptyPlaceholder(context),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    if (heroTag != null) {
      image = Hero(tag: heroTag!, child: image);
    }
    return _wrap(image);
  }

  Widget _wrap(Widget child) {
    return SizedBox(width: width, height: height, child: child);
  }

  Widget _placeholder(BuildContext context, KnowledgeMedia m) {
    final hash = m.blurhash;
    if (hash != null && hash.isNotEmpty) {
      try {
        return BlurHash(hash: hash);
      } catch (_) {
        // BlurHash decode can fail on malformed strings; fall back.
      }
    }
    return placeholder ??
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        );
  }

  Widget _emptyPlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.image_not_supported_outlined,
          color: cs.onSurfaceVariant, size: 28),
    );
  }
}
