import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/widgets/product_image_widget.dart';
import 'package:gloria_marketing_flutter/src/core/services/product_image_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_with_price.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_image.dart';
import 'package:intl/intl.dart';

/// Product detail page displaying comprehensive product information
/// 
/// Features:
/// - Hero animation for smooth transition from list/grid views
/// - Expandable sections to reduce visual clutter
/// - Full localization support (EN/RU/UZ)
/// - Modern Material Design 3 UI
/// - Extensible architecture for future enhancements
class ProductDetailPage extends StatefulWidget {
  final ProductWithPrice product;
  final String? heroTag;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.heroTag,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  // Animation controller for staggered animations
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Expandable section states
  final Map<_DetailSection, bool> _expandedSections = {
    _DetailSection.basicInfo: true,
    _DetailSection.pricing: true,
    _DetailSection.stock: false,
    _DetailSection.additional: false,
  };

  // Product images
  List<ProductImage> _productImages = [];
  int _currentImageIndex = 0;

  // Number formatter
  final NumberFormat _numberFormat = NumberFormat('#,##0.##', 'uz_UZ');

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadProductImages();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  Future<void> _loadProductImages() async {
    try {
      final imageService = sl<ProductImageService>();
      final images = await imageService.getAllImages(widget.product.productCode);
      if (mounted) {
        setState(() {
          // Sort images: main image first, then by created date
          _productImages = _sortImagesMainFirst(images);
        });
      }
    } catch (e) {
      // Image loading failed, will show default image
    }
  }

  /// Sort images with main image first
  List<ProductImage> _sortImagesMainFirst(List<ProductImage> images) {
    if (images.isEmpty) return images;
    
    final sorted = List<ProductImage>.from(images);
    sorted.sort((a, b) {
      // Main image comes first
      if (a.isMain && !b.isMain) return -1;
      if (!a.isMain && b.isMain) return 1;
      // Then sort by created date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }

  /// Open full screen image viewer with zoom capability
  void _openFullScreenViewer(int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenImageViewer(
            images: _productImages,
            initialIndex: initialIndex,
            productCode: widget.product.productCode,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Collapsible App Bar with product image
          _buildSliverAppBar(theme, cs, l10n),
          
          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product title and price header
                      _buildProductHeader(theme, cs, l10n),
                      
                      const SizedBox(height: 16),
                      
                      // Quick info chips
                      _buildQuickInfoChips(theme, cs, l10n),
                      
                      const SizedBox(height: 20),
                      
                      // Expandable sections
                      _buildExpandableSection(
                        section: _DetailSection.basicInfo,
                        title: l10n?.productBasicInfo ?? 'Asosiy ma\'lumotlar',
                        icon: Icons.info_outline_rounded,
                        theme: theme,
                        cs: cs,
                        child: _buildBasicInfoContent(theme, cs, l10n),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildExpandableSection(
                        section: _DetailSection.pricing,
                        title: l10n?.productPricingInfo ?? 'Narx ma\'lumotlari',
                        icon: Icons.payments_outlined,
                        theme: theme,
                        cs: cs,
                        child: _buildPricingContent(theme, cs, l10n),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildExpandableSection(
                        section: _DetailSection.stock,
                        title: l10n?.productStockInfo ?? 'Ombor ma\'lumotlari',
                        icon: Icons.warehouse_outlined,
                        theme: theme,
                        cs: cs,
                        child: _buildStockContent(theme, cs, l10n),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildExpandableSection(
                        section: _DetailSection.additional,
                        title: l10n?.productAdditionalInfo ?? 'Qo\'shimcha ma\'lumotlar',
                        icon: Icons.more_horiz_rounded,
                        theme: theme,
                        cs: cs,
                        child: _buildAdditionalContent(theme, cs, l10n),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // App Bar with Image Gallery
  // ===========================================================================

  Widget _buildSliverAppBar(ThemeData theme, ColorScheme cs, AppLocalizations? l10n) {
    final heroTag = widget.heroTag ?? 'product_${widget.product.productCode}';
    
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      leading: _buildBackButton(cs),
      actions: [
        _buildShareButton(cs),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image with Hero animation and double-tap for full screen
            GestureDetector(
              onDoubleTap: () {
                if (_productImages.isNotEmpty) {
                  _openFullScreenViewer(_currentImageIndex);
                }
              },
              child: Hero(
                tag: heroTag,
                child: _productImages.isNotEmpty
                    ? PageView.builder(
                        itemCount: _productImages.length,
                        onPageChanged: (index) {
                          setState(() => _currentImageIndex = index);
                        },
                        itemBuilder: (context, index) {
                          final image = _productImages[index];
                          return _buildCarouselImage(image, index);
                        },
                      )
                    : ProductImageWidget(
                        productCode: widget.product.productCode,
                        size: ProductImageSize.large,
                        fit: BoxFit.contain,
                      ),
              ),
            ),
            
            // Gradient overlay for better readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      cs.surface.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
            
            // Image indicators
            if (_productImages.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _productImages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: index == _currentImageIndex ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: index == _currentImageIndex
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: cs.surface.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: cs.surface.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: _shareProduct,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(Icons.share_rounded, color: cs.onSurface),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Product Header
  // ===========================================================================

  Widget _buildProductHeader(ThemeData theme, ColorScheme cs, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product name
        Text(
          widget.product.productName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            height: 1.2,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Price
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatPrice(widget.product.price),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                widget.product.currency,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.primary.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // Quick Info Chips
  // ===========================================================================

  Widget _buildQuickInfoChips(ThemeData theme, ColorScheme cs, AppLocalizations? l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Stock status chip
        _buildInfoChip(
          icon: Icons.inventory_2_outlined,
          label: '${l10n?.productStock ?? 'Qoldiq'}: ${_numberFormat.format(widget.product.stock)}',
          color: widget.product.stock > 0 ? cs.tertiary : cs.error,
          theme: theme,
        ),
        
        // Unit chip
        if (widget.product.unit.isNotEmpty)
          _buildInfoChip(
            icon: Icons.straighten_outlined,
            label: widget.product.unit,
            color: cs.secondary,
            theme: theme,
          ),
        
        // Brand chip
        if (widget.product.productBrand.isNotEmpty)
          _buildInfoChip(
            icon: Icons.business_outlined,
            label: widget.product.productBrand,
            color: cs.primary,
            theme: theme,
          ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Expandable Section Builder
  // ===========================================================================

  Widget _buildExpandableSection({
    required _DetailSection section,
    required String title,
    required IconData icon,
    required ThemeData theme,
    required ColorScheme cs,
    required Widget child,
  }) {
    final isExpanded = _expandedSections[section] ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded 
              ? cs.primary.withValues(alpha: 0.3) 
              : cs.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          // Header (always visible)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _expandedSections[section] = !isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 20, color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Content (animated)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
            crossFadeState: isExpanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Section Contents
  // ===========================================================================

  Widget _buildBasicInfoContent(ThemeData theme, ColorScheme cs, AppLocalizations? l10n) {
    return Column(
      children: [
        _buildInfoRow(
          label: l10n?.productCode ?? 'Mahsulot kodi',
          value: widget.product.productCode,
          icon: Icons.qr_code_rounded,
          theme: theme,
          cs: cs,
          copyable: true,
        ),
        _buildInfoRow(
          label: l10n?.productVendorCode ?? 'Artikul',
          value: widget.product.vendorCode.isNotEmpty 
              ? widget.product.vendorCode 
              : '-',
          icon: Icons.tag_rounded,
          theme: theme,
          cs: cs,
          copyable: true,
        ),
        _buildInfoRow(
          label: l10n?.productBarcode ?? 'Shtrix kod',
          value: widget.product.barcode.isNotEmpty 
              ? widget.product.barcode 
              : '-',
          icon: Icons.view_week_rounded,
          theme: theme,
          cs: cs,
          copyable: true,
        ),
        _buildInfoRow(
          label: l10n?.productCategory ?? 'Kategoriya',
          value: widget.product.category.isNotEmpty 
              ? widget.product.category 
              : '-',
          icon: Icons.category_rounded,
          theme: theme,
          cs: cs,
        ),
        _buildInfoRow(
          label: l10n?.productSeries ?? 'Seriya',
          value: widget.product.productSeries.isNotEmpty 
              ? widget.product.productSeries 
              : '-',
          icon: Icons.layers_rounded,
          theme: theme,
          cs: cs,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildPricingContent(ThemeData theme, ColorScheme cs, AppLocalizations? l10n) {
    return Column(
      children: [
        _buildInfoRow(
          label: l10n?.productPriceType ?? 'Narx turi',
          value: widget.product.priceTypeName,
          icon: Icons.sell_rounded,
          theme: theme,
          cs: cs,
        ),
        _buildInfoRow(
          label: l10n?.productPrice ?? 'Narx',
          value: '${_formatPrice(widget.product.price)} ${widget.product.currency}',
          icon: Icons.payments_rounded,
          theme: theme,
          cs: cs,
          valueStyle: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.primary,
          ),
        ),
        if (widget.product.validFrom.isNotEmpty)
          _buildInfoRow(
            label: l10n?.productPriceValidFrom ?? 'Amal qilish sanasi',
            value: _formatDate(widget.product.validFrom),
            icon: Icons.event_rounded,
            theme: theme,
            cs: cs,
          ),
        if (widget.product.validTo.isNotEmpty)
          _buildInfoRow(
            label: l10n?.productPriceValidTo ?? 'Tugash sanasi',
            value: _formatDate(widget.product.validTo),
            icon: Icons.event_busy_rounded,
            theme: theme,
            cs: cs,
            isLast: true,
          ),
      ],
    );
  }

  Widget _buildStockContent(ThemeData theme, ColorScheme cs, AppLocalizations? l10n) {
    return Column(
      children: [
        _buildInfoRow(
          label: l10n?.productWarehouse ?? 'Ombor',
          value: widget.product.warehouseName.isNotEmpty 
              ? widget.product.warehouseName 
              : widget.product.warehouseCode.isNotEmpty 
                  ? widget.product.warehouseCode 
                  : '-',
          icon: Icons.warehouse_rounded,
          theme: theme,
          cs: cs,
        ),
        _buildInfoRow(
          label: l10n?.productStock ?? 'Qoldiq',
          value: _numberFormat.format(widget.product.stock),
          icon: Icons.inventory_rounded,
          theme: theme,
          cs: cs,
          valueStyle: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: widget.product.stock > 0 ? cs.tertiary : cs.error,
          ),
        ),
        _buildInfoRow(
          label: l10n?.productQuantity ?? 'Umumiy miqdor',
          value: _numberFormat.format(widget.product.quantity),
          icon: Icons.all_inbox_rounded,
          theme: theme,
          cs: cs,
        ),
        _buildInfoRow(
          label: l10n?.productReserved ?? 'Band qilingan',
          value: _numberFormat.format(widget.product.reserved),
          icon: Icons.lock_outline_rounded,
          theme: theme,
          cs: cs,
        ),
        _buildInfoRow(
          label: l10n?.productAvailable ?? 'Mavjud',
          value: _numberFormat.format(widget.product.available),
          icon: Icons.check_circle_outline_rounded,
          theme: theme,
          cs: cs,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildAdditionalContent(ThemeData theme, ColorScheme cs, AppLocalizations? l10n) {
    return Column(
      children: [
        _buildInfoRow(
          label: l10n?.productUnit ?? 'O\'lchov birligi',
          value: widget.product.unit.isNotEmpty ? widget.product.unit : '-',
          icon: Icons.straighten_rounded,
          theme: theme,
          cs: cs,
        ),
        _buildInfoRow(
          label: l10n?.productWeight ?? 'Og\'irlik',
          value: widget.product.weight > 0 
              ? '${_numberFormat.format(widget.product.weight)} kg' 
              : '-',
          icon: Icons.scale_rounded,
          theme: theme,
          cs: cs,
        ),
        _buildInfoRow(
          label: l10n?.productCapacity ?? 'Sig\'im',
          value: widget.product.capacity > 0 
              ? _numberFormat.format(widget.product.capacity) 
              : '-',
          icon: Icons.water_drop_outlined,
          theme: theme,
          cs: cs,
        ),
        _buildInfoRow(
          label: l10n?.productBrand ?? 'Brend',
          value: widget.product.productBrand.isNotEmpty 
              ? widget.product.productBrand 
              : '-',
          icon: Icons.business_rounded,
          theme: theme,
          cs: cs,
        ),
        _buildInfoRow(
          label: l10n?.productProject ?? 'Loyiha kodi',
          value: widget.product.codeProject.isNotEmpty 
              ? widget.product.codeProject 
              : '-',
          icon: Icons.folder_outlined,
          theme: theme,
          cs: cs,
          isLast: true,
        ),
      ],
    );
  }

  // ===========================================================================
  // Info Row Builder
  // ===========================================================================

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    required ThemeData theme,
    required ColorScheme cs,
    TextStyle? valueStyle,
    bool copyable = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: valueStyle ?? theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (copyable && value.isNotEmpty && value != '-')
                IconButton(
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: () => _copyToClipboard(value),
                  tooltip: AppLocalizations.of(context)?.copy ?? 'Nusxalash',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: cs.outline.withValues(alpha: 0.1),
          ),
      ],
    );
  }

  // ===========================================================================
  // Helper Methods
  // ===========================================================================

  String _formatPrice(double price) {
    return _numberFormat.format(price);
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n?.copiedToClipboard ?? 'Nusxalandi'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _shareProduct() {
    HapticFeedback.lightImpact();
    final product = widget.product;
    final shareText = '''
${product.productName}
${AppLocalizations.of(context)?.productPrice ?? 'Narx'}: ${_formatPrice(product.price)} ${product.currency}
${AppLocalizations.of(context)?.productStock ?? 'Qoldiq'}: ${_numberFormat.format(product.stock)}
${AppLocalizations.of(context)?.productCode ?? 'Kod'}: ${product.productCode}
''';
    
    Clipboard.setData(ClipboardData(text: shareText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)?.productInfoCopied ?? 
              'Mahsulot ma\'lumotlari nusxalandi',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Build carousel image with main badge indicator
  Widget _buildCarouselImage(ProductImage image, int index) {
    final cs = Theme.of(context).colorScheme;
    final imageUrl = image.imageMdUrl ?? image.imageSmUrl ?? image.imageUrl ?? image.imageThumbnailUrl;
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        if (imageUrl != null && imageUrl.isNotEmpty)
          Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => _buildPlaceholder(cs),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          )
        else
          _buildPlaceholder(cs),
        
        // Main image badge
        if (image.isMain)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 14, color: cs.onPrimary),
                  const SizedBox(width: 4),
                  Text(
                    'Asosiy',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Double-tap hint (shows only on first image)
        if (index == 0 && _productImages.isNotEmpty)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_outlined, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '2x tap',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 64,
          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

// ===========================================================================
// Detail Section Enum
// ===========================================================================

enum _DetailSection {
  basicInfo,
  pricing,
  stock,
  additional,
}

// ===========================================================================
// Full Screen Image Viewer with Zoom
// ===========================================================================

class _FullScreenImageViewer extends StatefulWidget {
  final List<ProductImage> images;
  final int initialIndex;
  final String productCode;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
    required this.productCode,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformationController = TransformationController();
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image viewer with zoom
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                _resetZoom();
              },
              itemBuilder: (context, index) {
                final image = widget.images[index];
                final imageUrl = image.imageLgUrl ?? image.imageMdUrl ?? image.imageUrl;
                
                return InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stack) => Icon(
                              Icons.broken_image_outlined,
                              size: 64,
                              color: Colors.white54,
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / 
                                      loadingProgress.expectedTotalBytes!
                                    : null,
                              );
                            },
                          )
                        : Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.white54,
                          ),
                  ),
                );
              },
            ),
            
            // Top bar with close button
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close button
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black38,
                      ),
                    ),
                    // Image counter
                    if (widget.images.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    // Placeholder for symmetry
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            
            // Bottom indicators
            if (widget.images.length > 1)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.images.length,
                    (index) => GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _currentIndex ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: index == _currentIndex
                              ? Colors.white
                              : Colors.white38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            
            // Zoom hint
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pinch_outlined, size: 16, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        'Kattalashtirish uchun qisib torting',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
