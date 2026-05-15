import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

import '../../../../core/services/images/image_cache_manager.dart';
import '../../../../core/services/images/unified_image.dart';
import '../../../../core/services/service_locator.dart';
import '../../services/customer_photo_change_notifier.dart';
import '../../services/customer_primary_photo_cache.dart';

/// Lightweight V2-backed thumbnail showing a customer's primary
/// photo. Replaces the legacy V1 `ClientImageWidget` at the
/// trading-point grid / list / avatar / detail-header surfaces so
/// every place an agent sees a customer photo reads from the same
/// `/api/mobile/v2/customers/{id}/photos/` source.
///
/// Backed by the singleton [CustomerPrimaryPhotoCache] so a 100-tile
/// list does not produce 100 cold HTTP calls. Subscribes to
/// [CustomerPhotoChangeNotifier] so the thumbnail refreshes
/// instantly when the user edits photos elsewhere in the app.
///
/// IMPORTANT: this widget intentionally does NOT use Hero —
/// reserve hero animations to the carousel → fullscreen flow in
/// [CustomerPhotoPreview] / [CustomerPhotoFullscreenPage]. Multiple
/// thumbnails of the same customer on screen would otherwise crash
/// during a route transition.
class CustomerPrimaryThumbnail extends StatefulWidget {
  /// Customer key the photo endpoint resolves against
  /// (`tradingPoint.id` — the backend `code` / `code_1c`).
  final String customerId;

  /// Variant requested from [UnifiedImage.urlForSize]. Pick
  /// `thumbnail` for 48-px avatars, `medium` for grid tiles,
  /// `large` for full-bleed headers.
  final UnifiedImageSize size;

  final BoxFit fit;

  /// Builder invoked whenever there is no resolvable image — either
  /// the customer has no photos, the cache lookup failed, or the
  /// resolved row has no variant URL yet (still processing).
  final Widget Function(BuildContext) errorBuilder;

  final BorderRadius? borderRadius;
  final double? width;
  final double? height;

  /// When false, the loading state shows a flat surface-coloured
  /// container instead of a spinner. Useful for compact avatars
  /// where a spinner would overflow.
  final bool showShimmer;

  const CustomerPrimaryThumbnail({
    super.key,
    required this.customerId,
    required this.size,
    required this.errorBuilder,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.width,
    this.height,
    this.showShimmer = true,
  });

  @override
  State<CustomerPrimaryThumbnail> createState() =>
      _CustomerPrimaryThumbnailState();
}

class _CustomerPrimaryThumbnailState extends State<CustomerPrimaryThumbnail> {
  late final CustomerPrimaryPhotoCache _cache;
  StreamSubscription<String>? _changeSub;

  UnifiedImage? _photo;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _cache = sl<CustomerPrimaryPhotoCache>();
    if (sl.isRegistered<CustomerPhotoChangeNotifier>()) {
      _changeSub = sl<CustomerPhotoChangeNotifier>()
          .stream
          .where((id) => id == widget.customerId)
          .listen((_) {
        _cache.invalidate(widget.customerId);
        _load();
      });
    }
    _load();
  }

  @override
  void didUpdateWidget(covariant CustomerPrimaryThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customerId != widget.customerId) {
      _changeSub?.cancel();
      if (sl.isRegistered<CustomerPhotoChangeNotifier>()) {
        _changeSub = sl<CustomerPhotoChangeNotifier>()
            .stream
            .where((id) => id == widget.customerId)
            .listen((_) {
          _cache.invalidate(widget.customerId);
          _load();
        });
      }
      _load();
    }
  }

  @override
  void dispose() {
    _changeSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final photo = await _cache.getPrimary(widget.customerId);
      if (!mounted) return;
      setState(() {
        _photo = photo;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _photo = null;
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.zero;

    Widget child;
    if (_isLoading && !_cache.hasResolved(widget.customerId)) {
      child = widget.showShimmer
          ? Container(
              color: cs.surfaceContainerHighest,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Container(color: cs.surfaceContainerHighest);
    } else if (_hasError || _photo == null) {
      child = widget.errorBuilder(context);
    } else {
      final url = _photo!.urlForSize(widget.size);
      if (url == null) {
        // Photo row exists but variants aren't ready — fall back to
        // blurhash if present, otherwise the error placeholder.
        child = _photo!.hasBlurhash
            ? BlurHash(hash: _photo!.blurhash)
            : widget.errorBuilder(context);
      } else {
        child = CachedNetworkImage(
          cacheManager: ImageCacheManager.instance,
          imageUrl: url,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          placeholder: (_, _) => _photo!.hasBlurhash
              ? BlurHash(hash: _photo!.blurhash)
              : Container(color: cs.surfaceContainerHighest),
          errorWidget: (_, _, _) => widget.errorBuilder(context),
        );
      }
    }

    if (radius == BorderRadius.zero) {
      return SizedBox(width: widget.width, height: widget.height, child: child);
    }
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: child,
      ),
    );
  }
}
