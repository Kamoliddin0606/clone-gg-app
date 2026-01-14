import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gloria_marketing_flutter/src/core/services/product_image_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_image.dart';

/// Adaptive product image widget with size-aware URL selection
/// 
/// This widget automatically:
/// - Fetches product image from cache/database
/// - Selects optimal image size based on display requirements
/// - Shows shimmer loading placeholder
/// - Falls back to default icon on error or missing image
/// - Supports hero animations for detail views
/// 
/// Usage:
/// ```dart
/// ProductImageWidget(
///   productCode: 'PRODUCT_001',
///   size: ProductImageSize.small,
///   width: 56,
///   height: 56,
/// )
/// ```
class ProductImageWidget extends StatefulWidget {
  /// Product code to fetch image for
  final String productCode;
  
  /// Desired image size category
  final ProductImageSize size;
  
  /// Widget width (optional)
  final double? width;
  
  /// Widget height (optional)
  final double? height;
  
  /// How to fit the image within bounds
  final BoxFit fit;
  
  /// Border radius for image container
  final BorderRadius? borderRadius;
  
  /// Optional hero tag for animations
  final String? heroTag;
  
  /// Custom placeholder widget
  final Widget? placeholder;
  
  /// Custom error widget
  final Widget? errorWidget;
  
  /// Background color for container
  final Color? backgroundColor;
  
  /// Whether to show shimmer animation during load
  final bool showShimmer;

  const ProductImageWidget({
    super.key,
    required this.productCode,
    this.size = ProductImageSize.small,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.heroTag,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
    this.showShimmer = true,
  });

  @override
  State<ProductImageWidget> createState() => _ProductImageWidgetState();
}

class _ProductImageWidgetState extends State<ProductImageWidget>
    with SingleTickerProviderStateMixin {
  final ProductImageService _imageService = sl<ProductImageService>();
  
  ProductImage? _image;
  bool _isLoading = true;
  bool _hasError = false;
  
  // Shimmer animation
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _setupShimmerAnimation();
    _loadImage();
  }

  @override
  void didUpdateWidget(ProductImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productCode != widget.productCode) {
      _loadImage();
    }
  }

  @override
  void dispose() {
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
    if (widget.productCode.isEmpty) {
      if (kDebugMode) {
        print('ProductImageWidget: Empty productCode');
      }
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

    try {
      if (kDebugMode) {
        print('ProductImageWidget: Loading image for productCode: ${widget.productCode}');
      }
      final image = await _imageService.getMainImage(widget.productCode);
      if (kDebugMode) {
        print('ProductImageWidget: Got image: ${image != null ? "YES" : "NULL"}, hasValidUrl: ${image != null ? _imageService.hasValidUrl(image) : false}');
        if (image != null) {
          print('ProductImageWidget: Image URLs - thumbnail: ${image.imageThumbnailUrl}, sm: ${image.imageSmUrl}, md: ${image.imageMdUrl}, lg: ${image.imageLgUrl}');
        }
      }
      if (mounted) {
        setState(() {
          _image = image;
          _isLoading = false;
          _hasError = image == null || !_imageService.hasValidUrl(image);
        });
        if (!_isLoading) {
          _shimmerController.stop();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ProductImageWidget: Error loading image: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        _shimmerController.stop();
      }
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
    
    // Wrap with hero if tag provided
    if (widget.heroTag != null) {
      return Hero(
        tag: widget.heroTag!,
        child: content,
      );
    }
    
    return content;
  }

  Widget _buildLoadingState(ThemeData theme, BorderRadius borderRadius) {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    if (!widget.showShimmer) {
      return _buildContainer(
        theme,
        borderRadius,
        child: Icon(
          Icons.inventory_2_outlined,
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
        Icons.inventory_2_outlined,
        size: _getIconSize(),
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
      ),
    );
  }

  Widget _buildImageState(ThemeData theme, BorderRadius borderRadius) {
    final imageUrl = _imageService.selectImageUrl(_image, widget.size);
    
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildErrorState(theme, borderRadius);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) => _buildLoadingState(theme, borderRadius),
        errorWidget: (context, url, error) => _buildErrorState(theme, borderRadius),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
        memCacheWidth: _getMemCacheSize(),
        memCacheHeight: _getMemCacheSize(),
      ),
    );
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
      decoration: decoration ?? BoxDecoration(
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
    
    // Scale icon based on container size
    if (size <= 48) return 20;
    if (size <= 80) return 28;
    if (size <= 120) return 36;
    if (size <= 200) return 48;
    return 64;
  }

  int? _getMemCacheSize() {
    // Optimize memory cache based on size category
    switch (widget.size) {
      case ProductImageSize.thumbnail:
        return 150;
      case ProductImageSize.small:
        return 300;
      case ProductImageSize.medium:
        return 600;
      case ProductImageSize.large:
        return null; // Full resolution
    }
  }
}

/// Synchronous version that uses pre-loaded cache
/// 
/// Use this when you've already called preloadMainImages() and want
/// synchronous access without additional async operations.
class ProductImageWidgetSync extends StatelessWidget {
  final String productCode;
  final ProductImageSize size;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? heroTag;

  const ProductImageWidgetSync({
    super.key,
    required this.productCode,
    this.size = ProductImageSize.small,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final imageService = sl<ProductImageService>();
    final theme = Theme.of(context);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(8);
    
    // Get from cache synchronously
    final image = imageService.getCachedMainImage(productCode);
    final imageUrl = imageService.selectImageUrl(image, size);
    
    Widget content;
    
    if (imageUrl == null || imageUrl.isEmpty) {
      content = _buildDefaultIcon(theme, effectiveBorderRadius);
    } else {
      content = ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: fit,
          placeholder: (_, __) => _buildDefaultIcon(theme, effectiveBorderRadius),
          errorWidget: (_, __, ___) => _buildDefaultIcon(theme, effectiveBorderRadius),
          fadeInDuration: const Duration(milliseconds: 150),
        ),
      );
    }
    
    if (heroTag != null) {
      return Hero(tag: heroTag!, child: content);
    }
    
    return content;
  }

  Widget _buildDefaultIcon(ThemeData theme, BorderRadius borderRadius) {
    final iconSize = _getIconSize();
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: iconSize,
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
      ),
    );
  }

  double _getIconSize() {
    final minDimension = (width ?? 56).clamp(24.0, double.infinity);
    final heightDimension = height ?? minDimension;
    final size = minDimension < heightDimension ? minDimension : heightDimension;
    
    if (size <= 48) return 20;
    if (size <= 80) return 28;
    if (size <= 120) return 36;
    if (size <= 200) return 48;
    return 64;
  }
}
