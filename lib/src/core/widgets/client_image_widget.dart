import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gloria_marketing_flutter/src/core/services/thumbnail_image_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';

/// Image size categories for adaptive URL selection
/// 
/// Different UI contexts require different image sizes for optimal
/// performance and visual quality:
/// - [thumbnail]: 48-64px - compact list items, small indicators
/// - [small]: 80-120px - standard list view items
/// - [medium]: 150-200px - grid view items
/// - [large]: 300+px - detail views, full-screen displays
enum ClientImageSize {
  /// 48-64px - compact list items, small indicators
  thumbnail,
  
  /// 80-120px - standard list view items
  small,
  
  /// 150-200px - grid view items
  medium,
  
  /// 300+px - detail views, full-screen displays
  large,
}

/// Adaptive client image widget with size-aware URL selection and on-demand loading
/// 
/// This widget automatically:
/// - Fetches client image metadata from cache/database
/// - Selects optimal image size based on display requirements
/// - Loads images on-demand using CachedNetworkImage
/// - Shows shimmer loading placeholder
/// - Falls back to default icon on error or missing image
/// - Supports hero animations for detail views
/// 
/// Usage:
/// ```dart
/// ClientImageWidget(
///   clientCode: 'C-001',
///   size: ClientImageSize.small,
///   width: 56,
///   height: 56,
/// )
/// ```
class ClientImageWidget extends StatefulWidget {
  /// Client code to fetch image for
  final String clientCode;
  
  /// Desired image size category
  final ClientImageSize size;
  
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
  
  /// Whether to load main image only (default: true)
  final bool mainImageOnly;

  const ClientImageWidget({
    super.key,
    required this.clientCode,
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
  final ClientImagesService _imageService = sl<ClientImagesService>();
  
  ClientImage? _image;
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
  void didUpdateWidget(ClientImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clientCode != widget.clientCode) {
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
    if (widget.clientCode.isEmpty) {
      if (kDebugMode) {
        print('ClientImageWidget: Empty clientCode');
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
        print('ClientImageWidget: Loading image for clientCode: ${widget.clientCode}');
      }
      
      final image = widget.mainImageOnly
          ? await _imageService.getMainClientImage(widget.clientCode)
          : (await _imageService.getClientImages(widget.clientCode)).firstOrNull;
      
      if (kDebugMode) {
        print('ClientImageWidget: Got image: ${image != null ? "YES" : "NULL"}');
        if (image != null) {
          print('ClientImageWidget: Image URLs - thumbnail: ${image.imageThumbnailUrl}, sm: ${image.imageSmUrl}, md: ${image.imageMdUrl}, lg: ${image.imageLgUrl}');
        }
      }
      
      if (mounted) {
        setState(() {
          _image = image;
          _isLoading = false;
          _hasError = image == null || !_hasValidUrl(image);
        });
        if (!_isLoading) {
          _shimmerController.stop();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ClientImageWidget: Error loading image: $e');
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

  /// Check if any image URL is available
  bool _hasValidUrl(ClientImage? image) {
    if (image == null) return false;
    return image.imageUrl != null ||
           image.image != null ||
           image.imageThumbnailUrl != null ||
           image.imageSmUrl != null ||
           image.imageMdUrl != null ||
           image.imageLgUrl != null;
  }

  /// Select the optimal image URL based on requested size
  /// 
  /// Automatically falls back to available sizes if the requested
  /// size is not available. Prioritizes smaller sizes for better
  /// performance when exact size is not critical.
  String? _selectImageUrl(ClientImage? image, ClientImageSize size) {
    if (image == null) return null;

    switch (size) {
      case ClientImageSize.thumbnail:
        // Smallest available - prefer thumbnail, then small
        return image.imageThumbnailUrl ?? 
               image.imageSmUrl ?? 
               image.imageMdUrl ?? 
               image.imageUrl ?? 
               image.image;
               
      case ClientImageSize.small:
        // Small size - prefer sm, fall back to thumbnail or medium
        return image.imageSmUrl ?? 
               image.imageThumbnailUrl ?? 
               image.imageMdUrl ?? 
               image.imageUrl ?? 
               image.image;
               
      case ClientImageSize.medium:
        // Medium size - prefer md, fall back to sm or lg
        return image.imageMdUrl ?? 
               image.imageSmUrl ?? 
               image.imageLgUrl ?? 
               image.imageUrl ?? 
               image.image;
               
      case ClientImageSize.large:
        // Large size - prefer lg, fall back to original or md
        return image.imageLgUrl ?? 
               image.imageMdUrl ?? 
               image.imageUrl ?? 
               image.image ?? 
               image.imageSmUrl;
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
    final imageUrl = _selectImageUrl(_image, widget.size);
    
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
      case ClientImageSize.thumbnail:
        return 150;
      case ClientImageSize.small:
        return 300;
      case ClientImageSize.medium:
        return 600;
      case ClientImageSize.large:
        return null; // Full resolution
    }
  }
}

/// Helper function to select image URL based on size
/// 
/// Can be used standalone without widget for custom implementations
String? selectClientImageUrl(ClientImage? image, ClientImageSize size) {
  if (image == null) return null;

  switch (size) {
    case ClientImageSize.thumbnail:
      return image.imageThumbnailUrl ?? 
             image.imageSmUrl ?? 
             image.imageMdUrl ?? 
             image.imageUrl ?? 
             image.image;
             
    case ClientImageSize.small:
      return image.imageSmUrl ?? 
             image.imageThumbnailUrl ?? 
             image.imageMdUrl ?? 
             image.imageUrl ?? 
             image.image;
             
    case ClientImageSize.medium:
      return image.imageMdUrl ?? 
             image.imageSmUrl ?? 
             image.imageLgUrl ?? 
             image.imageUrl ?? 
             image.image;
             
    case ClientImageSize.large:
      return image.imageLgUrl ?? 
             image.imageMdUrl ?? 
             image.imageUrl ?? 
             image.image ?? 
             image.imageSmUrl;
  }
}
