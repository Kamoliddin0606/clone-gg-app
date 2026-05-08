import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/agent_organization_context.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/image_cache_manager.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/image_target_type.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/new_backend_image_repository.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/unified_image.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';

/// Image size categories for [ProjectImageWidget]. Mirrors the
/// existing product/client size enums so a single screen can mix the
/// three widget types and pick consistent buckets.
enum ProjectImageSize { thumbnail, small, medium, large }

/// Adaptive widget that renders the primary image of a project.
///
/// Project images come from
/// `/api/mobile/v1/images/?target_type=project&external_code=<id_1c>&target_organization_id=<uuid>`.
/// The legacy media host never had project images, so this widget
/// renders an empty-state placeholder when the project has none yet.
class ProjectImageWidget extends StatefulWidget {
  /// Project's 1C code (`id_1c`). The backend's denorm exposes it as
  /// `target.code_1c` on every image row; mobile passes it through as
  /// `external_code`.
  final String projectId;

  /// Organisation that owns this project. Empty/`null` falls back to
  /// the agent's primary org via [AgentOrganizationContext]. When
  /// neither is available, the widget renders the empty state.
  final String? targetOrganizationId;

  /// Desired image size category.
  final ProjectImageSize size;

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

  /// Custom empty-state widget (replaces the built-in placeholder
  /// shown when no project images exist yet).
  final Widget? emptyWidget;

  /// Custom error widget (fully replaces the built-in branch).
  final Widget? errorWidget;

  /// Background color for container.
  final Color? backgroundColor;

  const ProjectImageWidget({
    super.key,
    required this.projectId,
    this.targetOrganizationId,
    this.size = ProjectImageSize.medium,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.heroTag,
    this.emptyWidget,
    this.errorWidget,
    this.backgroundColor,
  });

  @override
  State<ProjectImageWidget> createState() => _ProjectImageWidgetState();
}

class _ProjectImageWidgetState extends State<ProjectImageWidget> {
  final NewBackendImageRepository _repo = sl<NewBackendImageRepository>();

  UnifiedImage? _image;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isEmpty = false;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(ProjectImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId ||
        oldWidget.targetOrganizationId != widget.targetOrganizationId) {
      _loadImage();
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('ProjectImageWidget disposed');
    super.dispose();
  }

  Future<void> _loadImage() async {
    if (widget.projectId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = false;
        _isEmpty = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _isEmpty = false;
    });

    _cancelToken?.cancel('ProjectImageWidget reloading');
    _cancelToken = CancelToken();

    try {
      final image = await _repo.primaryForTarget(
        targetType: ImageTargetType.project,
        targetCode1c: widget.projectId,
        targetOrganizationId: _resolveOrgId(),
        cancelToken: _cancelToken,
      );

      if (!mounted) return;
      setState(() {
        _image = image;
        _isLoading = false;
        _isEmpty = image == null;
        _hasError = image != null && !image.hasUrl;
      });
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return;
      }
      if (kDebugMode) {
        debugPrint('ProjectImageWidget: error loading image: $e');
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _isEmpty = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderRadius = widget.borderRadius ?? BorderRadius.circular(8);

    Widget content;
    if (_isLoading) {
      content = _buildLoadingState(theme, effectiveBorderRadius);
    } else if (_hasError) {
      content = _buildErrorState(theme, effectiveBorderRadius);
    } else if (_isEmpty || _image == null) {
      content = _buildEmptyState(theme, effectiveBorderRadius);
    } else {
      content = _buildImageState(theme, effectiveBorderRadius);
    }

    if (widget.heroTag != null) {
      return Hero(tag: widget.heroTag!, child: content);
    }
    return content;
  }

  Widget _buildLoadingState(ThemeData theme, BorderRadius borderRadius) {
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
    return _buildContainer(
      theme,
      borderRadius,
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, BorderRadius borderRadius) {
    if (widget.errorWidget != null) return widget.errorWidget!;
    final l10n = AppLocalizations.of(context);
    return _buildContainer(
      theme,
      borderRadius,
      child: Tooltip(
        message: l10n?.imageLoadFailed ?? 'Could not load image',
        child: Icon(
          Icons.broken_image_outlined,
          size: _getIconSize(),
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, BorderRadius borderRadius) {
    if (widget.emptyWidget != null) return widget.emptyWidget!;
    final l10n = AppLocalizations.of(context);
    return _buildContainer(
      theme,
      borderRadius,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_outlined,
            size: _getIconSize(),
            color: theme.colorScheme.onSurfaceVariant,
          ),
          if ((widget.height ?? 80) >= 96) ...[
            const SizedBox(height: 8),
            Text(
              l10n?.projectImageEmpty ?? 'No images yet',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageState(ThemeData theme, BorderRadius borderRadius) {
    final image = _image!;
    final imageUrl = image.urlForSize(_unifiedSize(widget.size));
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildEmptyState(theme, borderRadius);
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
  }) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      child: child != null ? Center(child: child) : null,
    );
  }

  double _getIconSize() {
    final minDimension = (widget.width ?? 80).clamp(24.0, double.infinity);
    final heightDimension = widget.height ?? minDimension;
    final size = minDimension < heightDimension ? minDimension : heightDimension;
    if (size <= 48) return 20;
    if (size <= 80) return 28;
    if (size <= 120) return 36;
    if (size <= 200) return 48;
    return 64;
  }

  /// Explicit [ProjectImageWidget.targetOrganizationId] always wins;
  /// otherwise fall back to the agent's primary org so existing call
  /// sites can opt into the new backend transparently.
  String _resolveOrgId() {
    final explicit = widget.targetOrganizationId;
    if (explicit != null && explicit.isNotEmpty) return explicit;
    if (sl.isRegistered<AgentOrganizationContext>()) {
      return sl<AgentOrganizationContext>().primaryOrganizationId ?? '';
    }
    return '';
  }
}

UnifiedImageSize _unifiedSize(ProjectImageSize size) {
  switch (size) {
    case ProjectImageSize.thumbnail:
      return UnifiedImageSize.thumbnail;
    case ProjectImageSize.small:
      return UnifiedImageSize.small;
    case ProjectImageSize.medium:
      return UnifiedImageSize.medium;
    case ProjectImageSize.large:
      return UnifiedImageSize.large;
  }
}
