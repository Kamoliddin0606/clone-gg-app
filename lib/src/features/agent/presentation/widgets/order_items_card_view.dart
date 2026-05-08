// =============================
// presentation/widgets/order_items_card_view.dart
// Modern, expandable order items view with price focus
// Localized for en/ru/uz languages
// =============================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import '../../../../core/services/api_database_service.dart';
import '../../../../core/widgets/product_image_widget.dart';
import '../../data/models/product_with_price.dart';
import '../pages/product_detail_page.dart';
import '../shared/formatters.dart';
import 'order_models.dart';

/// Modern card-based view for order items with expandable details
/// Prioritizes price information from order_detail_products table
/// UI: Clean, professional, user-friendly with expandable sections
class OrderItemsCardView extends StatefulWidget {
  final OrderModel order;
  final ScrollController? controller;
  
  const OrderItemsCardView({
    super.key,
    required this.order,
    this.controller,
  });

  @override
  State<OrderItemsCardView> createState() => _OrderItemsCardViewState();
}

class _OrderItemsCardViewState extends State<OrderItemsCardView> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Handle empty items case
    if (widget.order.items.isEmpty) {
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

    final totalItems = widget.order.items.fold<double>(0, (p, e) => p + e.quantity);
    final totalSum = widget.order.items.fold<double>(0, (p, e) => p + (e.lineTotal ?? e.calculatedTotal));
    final calculatedTotal = widget.order.items.fold<double>(0, (p, e) => p + e.calculatedTotal);
    final orderTotal = widget.order.total;
    final hasOrderTotalMismatch = (orderTotal - totalSum).abs() > 0.01;

    return Container(
      color: cs.surfaceContainerLowest,
      child: Column(
        children: [
          // Items list with expandable cards
          Expanded(
            child: ListView.separated(
              controller: widget.controller,
              padding: const EdgeInsets.all(16),
              cacheExtent: 600,
              addAutomaticKeepAlives: false,
              itemCount: widget.order.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final item = widget.order.items[i];
                return _ExpandableOrderItemCard(
                  item: item,
                  index: i,
                  isExpanded: false,
                  onTap: () {},
                  onDoubleTap: () => _openProductDetail(context, item),
                );
              },
            ),
          ),
          // Footer with purchase summary - focused on totals
          _buildPurchaseSummaryFooter(context, totalItems, orderTotal, calculatedTotal, hasOrderTotalMismatch),
        ],
      ),
    );
  }
  
  /// Purchase summary footer with clear price focus and order total validation
  Widget _buildPurchaseSummaryFooter(
    BuildContext context,
    double totalItems,
    double totalSum,
    double calculatedTotal,
    bool hasOrderTotalMismatch,
  ) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Order total mismatch warning
          if (hasOrderTotalMismatch)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.errorContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.error.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 20, color: cs.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.orderTotalMismatch,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${l10n.lineTotal}: ${uzsFormat.format(calculatedTotal)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Summary row with items count and total
          Row(
            children: [
              // Items count section
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: cs.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.products,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${NumberFormat('#,##0').format(totalItems.toInt())} ${l10n.items}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Total sum section - highlighted
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primary.withOpacity(0.1),
                        cs.primary.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.primary.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.payments_rounded,
                          color: cs.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.amountLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              uzsFormat.format(totalSum),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
      
      // Try to find product with full details including prices and stock
      final products = await db.getProductsWithPrices(
        searchQuery: item.article,
        priceTypeCode: item.priceTypeCode,
      );
      
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();
      
      // Find exact match by article code
      ProductWithPrice? productWithPrice;
      if (products.isNotEmpty) {
        try {
          productWithPrice = products.firstWhere(
            (p) => p.productCode == item.article || p.vendorCode == item.article,
          );
        } catch (e) {
          productWithPrice = products.first;
        }
      }
      
      if (productWithPrice != null && context.mounted) {
        // Navigate to full ProductDetailPage
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(
              product: productWithPrice!,
              heroTag: 'order_item_${item.article}',
            ),
          ),
        );
      } else if (context.mounted) {
        // Show error message if product not found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.noData ?? 'Mahsulot topilmadi'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog on error
      if (context.mounted) Navigator.of(context).pop();
      
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.error ?? "Xatolik"}: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// Expandable order item card with price focus
/// Shows basic info in collapsed state, detailed pricing when expanded
class _ExpandableOrderItemCard extends StatelessWidget {
  final OrderItem item;
  final int index;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  
  const _ExpandableOrderItemCard({
    required this.item,
    required this.index,
    required this.isExpanded,
    required this.onTap,
    required this.onDoubleTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return GestureDetector(
      onTap: onDoubleTap,
      onDoubleTap: onDoubleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded 
                ? cs.primary.withOpacity(0.4) 
                : cs.outlineVariant.withOpacity(0.3),
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(isExpanded ? 0.08 : 0.04),
              blurRadius: isExpanded ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main row - always visible
            Row(
              children: [
                // Product image
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
                      Text(
                        item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '${NumberFormat('#,##0.###').format(item.quantity)}x ${item.article}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              uzsFormat.format(item.calculatedTotal),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Expand indicator
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
            // Expanded details - price breakdown
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: isExpanded 
                  ? CrossFadeState.showSecond 
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Unit price row
                      _buildDetailRow(
                        context,
                        icon: Icons.sell_outlined,
                        label: l10n.priceLabel,
                        value: uzsFormat.format(item.price),
                      ),
                      const SizedBox(height: 8),
                      // Price type row - uses display name with fallback logic
                      _buildDetailRow(
                        context,
                        icon: Icons.category_outlined,
                        label: l10n.priceTypeLabel,
                        value: item.priceTypeDisplayName,
                      ),
                      const SizedBox(height: 8),
                      // Line total row - shows calculated total (price × quantity)
                      _buildDetailRow(
                        context,
                        icon: Icons.calculate_rounded,
                        label: l10n.lineTotal,
                        value: uzsFormat.format(item.calculatedTotal),
                        isHighlighted: true,
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
  
  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isHighlighted ? cs.primary : cs.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '$label:',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
              color: isHighlighted ? cs.primary : cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

