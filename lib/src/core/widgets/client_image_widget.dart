import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/agent_organization_context.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/image_cache_manager.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/image_target_type.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/new_backend_image_repository.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/unified_image.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';

/// Image size categories for adaptive URL selection.
///
/// Different UI contexts require different image sizes for optimal
/// performance and visual quality:
/// - [thumbnail]: 48-64px - compact list items, small indicators
/// - [small]: 80-120px - standard list view items
/// - [medium]: 150-200px - grid view items
/// - [large]: 300+px - detail views, full-screen displays
enum ClientImageSize {
  thumbnail,
  small,
  medium,
  large,
}

/// Adaptive client image widget with size-aware URL selection.
///
/// Reads images directly from the V2 backend's
/// `/api/mobile/v1/images/` endpoint via [NewBackendImageRepository].
/// The legacy media host is no longer consulted — uploads happen
/// through the web admin panel; the mobile app is a read-only
/// consumer.
class ClientImageWidget extends StatefulWidget {
  /// Client code to fetch image for (matches `target_id` for customers).
  final String clientCode;

  /// Organisation that owns this customer. Empty/`null` keeps the
  /// resolver on the legacy repo.
  final String? targetOrganizationId;

  /// Desired image size category.
  final ClientImageSize size;

  /// Widget width (optional).
  final double? width;

  /// Widget height (optional).
  final double? height;

  /// How to fit the image within bounds.
  final BoxFit fit;

  /// Border radius for image container.
  final BorderRadius? borderRadius;

  /// Optional hero tag for animations.
  final String? heroTag;

  /// Custom placeholder widget (fully replaces the built-in branch).
  final Widget? placeholder;

  /// Custom error widget (fully replaces the built-in branch).
  final Widget? errorWidget;

  /// Background color for container.
  final Color? backgroundColor;

  /// Whether to show shimmer animation during load. Ignored when a
  /// BlurHash placeholder is available.
  final bool showShimmer;

  /// Whether to load main image only (default `true`). Preserved for
  /// API compatibility — primary lookups still skip non-main rows.
  final bool mainImageOnly;

  const ClientImageWidget({
    super.key,
    required this.clientCode,
    this.targetOrganizationId,
    this.size = ClientImageSize.small,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.heroTag,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
    this.showShimmer = true,
    this.mainImageOnly = true,
  });

  @override
  State<ClientImageWidget> createState() => _ClientImageWidgetState();
}

class _ClientImageWidgetState extends State<ClientImageWidget>
    with SingleTickerProviderStateMixin {
  final NewBackendImageRepository _repo = sl<NewBackendImageRepository>();

  UnifiedImage? _image;
  bool _isLoading = true;
  bool _hasError = false;
  CancelToken? _cancelToken;

  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _setupShimmerAnimation();
    _loadImage();
  }

  @override
  void didUpdateWidget(ClientImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clientCode != widget.clientCode ||
        oldWidget.targetOrganizationId != widget.targetOrganizationId) {
      _loadImage();
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('ClientImageWidget disposed');
    _shimmerController.dispose();
    super.dispose();
  }

  void _setupShimmerAnimation() {
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    if (widget.showShimmer) {
      _shimmerController.repeat();
    }
  }

  Future<void> _loadImage() async {
    if (widget.clientCode.isEmpty) {
      if (kDebugMode) {
        debugPrint('ClientImageWidget: empty clientCode');
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    _cancelToken?.cancel('ClientImageWidget reloading');
    _cancelToken = CancelToken();

    try {
      UnifiedImage? image;
      if (widget.mainImageOnly) {
        image = await _repo.primaryForTarget(
          targetType: ImageTargetType.customer,
          targetCode1c: widget.clientCode,
          targetOrganizationId: _resolveOrgId(),
          cancelToken: _cancelToken,
        );
      } else {
        final page = await _repo.listForTarget(
          targetType: ImageTargetType.customer,
          targetCode1c: widget.clientCode,
          targetOrganizationId: _resolveOrgId(),
          cancelToken: _cancelToken,
        );
        image = page.images.isEmpty ? null : page.images.first;
      }

      if (!mounted) return;
      setState(() {
        _image = image;
        _isLoading = false;
        _hasError = image == null || !image.hasUrl;
      });
      if (!_isLoading) {
        _shimmerController.stop();
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return;
      }
      if (kDebugMode) {
        debugPrint('ClientImageWidget: error loading image: $e');
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      _shimmerController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderRadius = widget.borderRadius ?? BorderRadius.circular(8);

    Widget content;
    if (_isLoading) {
      content = _buildLoadingState(theme, effectiveBorderRadius);
    } else if (_hasError || _image == null) {
      content = _buildErrorState(theme, effectiveBorderRadius);
    } else {
      content = _buildImageState(theme, effectiveBorderRadius);
    }

    if (widget.heroTag != null) {
      return Hero(tag: widget.heroTag!, child: content);
    }
    return content;
  }

  Widget _buildLoadingState(ThemeData theme, BorderRadius borderRadius) {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    final image = _image;
    if (image != null && image.hasBlurhash) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: BlurHash(hash: image.blurhash),
        ),
      );
    }

    if (!widget.showShimmer) {
      return _buildContainer(
        theme,
        borderRadius,
        child: Icon(
          Icons.store_outlined,
          size: _getIconSize(),
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return _buildContainer(
          theme,
          borderRadius,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surfaceContainerHighest,
                theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                theme.colorScheme.surfaceContainerHighest,
              ],
              stops: [
                (_shimmerAnimation.value - 1).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(ThemeData theme, BorderRadius borderRadius) {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }
    return _buildContainer(
      theme,
      borderRadius,
      child: Icon(
        Icons.store_outlined,
        size: _getIconSize(),
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
      ),
    );
  }

  Widget _buildImageState(ThemeData theme, BorderRadius borderRadius) {
    final image = _image!;
    final imageUrl = image.urlForSize(_unifiedSize(widget.size));
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildErrorState(theme, borderRadius);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        cacheManager: ImageCacheManager.instance,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) =>
            _buildPlaceholderForCachedImage(theme, borderRadius, image),
        errorWidget: (context, url, error) =>
            _buildErrorState(theme, borderRadius),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
        memCacheWidth: _getMemCacheSize(),
        memCacheHeight: _getMemCacheSize(),
      ),
    );
  }

  Widget _buildPlaceholderForCachedImage(
    ThemeData theme,
    BorderRadius borderRadius,
    UnifiedImage image,
  ) {
    if (image.hasBlurhash) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: BlurHash(hash: image.blurhash),
      );
    }
    return _buildLoadingState(theme, borderRadius);
  }

  Widget _buildContainer(
    ThemeData theme,
    BorderRadius borderRadius, {
    Widget? child,
    BoxDecoration? decoration,
  }) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: decoration ??
          BoxDecoration(
            color: widget.backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
            borderRadius: borderRadius,
          ),
      child: child != null ? Center(child: child) : null,
    );
  }

  double _getIconSize() {
    final minDimension = (widget.width ?? 56).clamp(24.0, double.infinity);
    final heightDimension = widget.height ?? minDimension;
    final size = minDimension < heightDimension ? minDimension : heightDimension;
    if (size <= 48) return 20;
    if (size <= 80) return 28;
    if (size <= 120) return 36;
    if (size <= 200) return 48;
    return 64;
  }

  int? _getMemCacheSize() {
    switch (widget.size) {
      case ClientImageSize.thumbnail:
        return 150;
      case ClientImageSize.small:
        return 300;
      case ClientImageSize.medium:
        return 600;
      case ClientImageSize.large:
        return null;
    }
  }

  /// Picks the org id passed to the resolver. Explicit
  /// [ClientImageWidget.targetOrganizationId] always wins; otherwise
  /// we fall back to the agent's primary org so existing call sites
  /// can opt into the new backend without rewiring every screen.
  String _resolveOrgId() {
    final explicit = widget.targetOrganizationId;
    if (explicit != null && explicit.isNotEmpty) return explicit;
    if (sl.isRegistered<AgentOrganizationContext>()) {
      return sl<AgentOrganizationContext>().primaryOrganizationId ?? '';
    }
    return '';
  }
}

UnifiedImageSize _unifiedSize(ClientImageSize size) {
  switch (size) {
    case ClientImageSize.thumbnail:
      return UnifiedImageSize.thumbnail;
    case ClientImageSize.small:
      return UnifiedImageSize.small;
    case ClientImageSize.medium:
      return UnifiedImageSize.medium;
    case ClientImageSize.large:
      return UnifiedImageSize.large;
  }
}

