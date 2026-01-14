// =============================
// presentation/widgets/order_items_card_view.dart
// =============================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import '../../../../core/services/api_database_service.dart';
import '../../../../core/widgets/product_image_widget.dart';
import '../../../../core/services/product_image_service.dart';
import '../../data/models/product_with_price.dart';
import '../pages/product_detail_page.dart';
import '../shared/formatters.dart';
import 'order_models.dart';

/// Modern card-based view for order items matching the design
class OrderItemsCardView extends StatelessWidget {
  final OrderModel order;
  final ScrollController? controller;
  
  const OrderItemsCardView({
    super.key,
    required this.order,
    this.controller,
  });
  
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Handle empty items case
    if (order.items.isEmpty) {
      return Container(
        color: cs.surfaceContainerLowest,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: cs.outline,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.noProductsInOrder,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.productListEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final totalItems = order.items.fold<double>(0, (p, e) => p + e.quantity);
    final totalSum = order.items.fold<double>(0, (p, e) => p + e.sum);

    return Container(
      color: cs.surfaceContainerLowest,
      child: Column(
        children: [
          // Items list
          Expanded(
            child: ListView.separated(
              controller: controller,
              padding: const EdgeInsets.all(16),
              itemCount: order.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final item = order.items[i];
                return _OrderItemCard(
                  item: item,
                  index: i,
                  onDoubleTap: () => _openProductDetail(context, item),
                );
              },
            ),
          ),
          // Footer with totals
          _buildFooter(context, totalItems, totalSum),
        ],
      ),
    );
  }
  
  Widget _buildFooter(BuildContext context, double totalItems, double totalSum) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${NumberFormat('#,##0').format(totalItems.toInt())} ${l10n.items}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  uzsFormat.format(totalSum),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Navigate to product detail page with full product info lookup
  Future<void> _openProductDetail(BuildContext context, OrderItem item) async {
    HapticFeedback.lightImpact();
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final db = GetIt.I<ApiDatabaseService>();
      
      // Try to find product by article code
      final product = await db.getProductByCode(item.article);
      
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();
      
      if (product != null && context.mounted) {
        // Create ProductWithPrice from database product and order item data
        final productWithPrice = ProductWithPrice(
          productCode: product.code,
          productName: product.name,
          vendorCode: product.vendorCode,
          unit: product.unit,
          quantity: item.quantity,
          reserved: 0,
          available: 0,
          category: product.category,
          barcode: product.barcode,
          have: 0,
          warehouseCode: '',
          warehouseName: '',
          weight: product.weight,
          capacity: product.capacity,
          productBrand: product.productBrand,
          productSeries: product.productSeries,
          codeProject: '',
          priceTypeCode: item.priceType,
          priceTypeName: item.priceType,
          price: item.price,
          currency: 'UZS',
          validFrom: '',
          validTo: '',
          stock: 0,
        );
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(
              product: productWithPrice,
              heroTag: 'order_item_${item.article}',
            ),
          ),
        );
      } else if (context.mounted) {
        // Fallback to bottom sheet if product not found in database
        _showItemDetailsBottomSheet(context, item);
      }
    } catch (e) {
      // Close loading dialog on error
      if (context.mounted) Navigator.of(context).pop();
      // Fallback to bottom sheet
      if (context.mounted) _showItemDetailsBottomSheet(context, item);
    }
  }

  void _showItemDetailsBottomSheet(BuildContext context, OrderItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductDetailBottomSheet(item: item),
    );
  }
}

/// Individual order item card
class _OrderItemCard extends StatelessWidget {
  final OrderItem item;
  final int index;
  final VoidCallback onDoubleTap;
  
  const _OrderItemCard({
    required this.item,
    required this.index,
    required this.onDoubleTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    
    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.outlineVariant.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product image with fallback to number
            Hero(
              tag: 'order_item_${item.article}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: ProductImageWidget(
                    productCode: item.article,
                    size: ProductImageSize.thumbnail,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 44,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: IntrinsicWidth(
                        child: Text(
                          item.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${NumberFormat('#,##0.###').format(item.quantity)}x ${item.article}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        uzsFormat.format(item.sum),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet with detailed product information
class _ProductDetailBottomSheet extends StatelessWidget {
  final OrderItem item;
  
  const _ProductDetailBottomSheet({required this.item});
  
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: cs.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.productDetails,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.productName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: cs.outlineVariant.withOpacity(0.3)),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    _DetailRow(
                      label: l10n.articleLabel,
                      value: item.article,
                      icon: Icons.qr_code_2_rounded,
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: l10n.quantityLabel,
                      value: NumberFormat('#,##0.###').format(item.quantity),
                      icon: Icons.shopping_cart_rounded,
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: l10n.priceLabel,
                      value: uzsFormat.format(item.price),
                      icon: Icons.payments_rounded,
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: l10n.amountLabel,
                      value: uzsFormat.format(item.sum),
                      icon: Icons.calculate_rounded,
                      isHighlighted: true,
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: l10n.priceTypeLabel,
                      value: item.priceType,
                      icon: Icons.sell_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Detail row in bottom sheet
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isHighlighted;
  
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isHighlighted = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? cs.primaryContainer.withOpacity(0.5)
            : cs.surfaceContainerHigh.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? cs.primary.withOpacity(0.3)
              : cs.outlineVariant.withOpacity(0.2),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? cs.primary.withOpacity(0.15)
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isHighlighted ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w700,
                    color: isHighlighted ? cs.primary : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
