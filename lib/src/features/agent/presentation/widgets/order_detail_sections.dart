
// =============================
// presentation/widgets/order_detail_sections.dart
// =============================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import '../shared/formatters.dart';
import 'order_models.dart';

class OrderDetailsSection extends StatelessWidget {
  final OrderModel order;
  final ScrollController? controller;
  
  const OrderDetailsSection({super.key, required this.order, this.controller});
  
  Widget _tile(BuildContext context, String title, String value, {IconData? icon}) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.2),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: cs.primary),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    
    final pairs = <Widget>[
      _tile(context, l10n.clientNameLabel, order.clientName.isNotEmpty ? order.clientName : order.clientCode, icon: Icons.store_rounded),
      _tile(context, l10n.orderNumberLabel, order.numOrder, icon: Icons.receipt_long_rounded),
      _tile(context, l10n.orderDateLabel, dateTimeFormat.format(order.dateOrder), icon: Icons.calendar_today_rounded),
      _tile(context, l10n.orderTotalLabel, uzsFormat.format(order.total), icon: Icons.payments_rounded),
      _tile(context, l10n.mainStatusLabel, order.mainStatus, icon: Icons.info_outline_rounded),
      _tile(context, l10n.statusCodeLabel, order.status.toString(), icon: Icons.tag_rounded),
      _tile(context, '${l10n.priceTypeLabel} (code)', order.typePriceCode, icon: Icons.sell_outlined),
      _tile(context, l10n.clientCodeLabel, order.clientCode, icon: Icons.qr_code_2_rounded),
      _tile(context, l10n.organizationCodeLabel, order.codeOrg, icon: Icons.business_rounded),
      if ((order.courierName ?? '').isNotEmpty)
        _tile(context, l10n.courierLabel, order.courierName!, icon: Icons.delivery_dining_rounded),
      if ((order.courierCar ?? '').isNotEmpty)
        _tile(context, l10n.vehicleLabel, order.courierCar!, icon: Icons.directions_car_rounded),
      if ((order.courierPlate ?? '').isNotEmpty)
        _tile(context, l10n.licensePlateLabel, order.courierPlate!, icon: Icons.pin_rounded),
      if ((order.commentSupervisor ?? '').isNotEmpty)
        _buildCommentCard(context, l10n.supervisorCommentLabel, order.commentSupervisor!, Icons.supervisor_account_rounded, cs.tertiary),
      if ((order.commentForwarder ?? '').isNotEmpty)
        _buildCommentCard(context, l10n.logistCommentLabel, order.commentForwarder!, Icons.local_shipping_rounded, cs.secondary),
      if ((order.commentAgent ?? '').isNotEmpty)
        _buildCommentCard(context, l10n.agentCommentLabel, order.commentAgent!, Icons.person_rounded, cs.primary),
    ];
    
    return Container(
      color: cs.surfaceContainerLowest,
      child: ListView.separated(
        controller: controller,
        padding: const EdgeInsets.all(16),
        itemCount: pairs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => AnimatedSlide(
          offset: Offset.zero,
          duration: Duration(milliseconds: 300 + (i * 50)),
          curve: Curves.easeOutCubic,
          child: pairs[i],
        ),
      ),
    );
  }
  
  Widget _buildCommentCard(BuildContext context, String title, String comment, IconData icon, Color accentColor) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              comment,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderItemsSection extends StatelessWidget {
  final OrderModel order;
  final ScrollController? controller;
  
  const OrderItemsSection({super.key, required this.order, this.controller});
  
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Handle empty items case
    if (order.items.isEmpty) {
      return Container(
        color: cs.surfaceContainerLowest,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                border: Border(
                  bottom: BorderSide(
                    color: cs.outlineVariant.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  _Head(l10n.productNameLabel, flex: 3),
                  _Head(l10n.articleLabel, flex: 2),
                  _Head(l10n.quantityLabel),
                  _Head(l10n.priceLabel),
                  _Head(l10n.amountLabel),
                  _Head(l10n.priceTypeLabel, flex: 2),
                ],
              ),
            ),
            // Empty state
            Expanded(
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
            ),
            // Footer
            _buildFooter(context, 0, 0.0),
          ],
        ),
      );
    }

    final totalItems = order.items.fold<double>(0, (p, e) => p + e.quantity);
    final totalSum = order.items.fold<double>(0, (p, e) => p + e.sum);

    return Container(
      color: cs.surfaceContainerLowest,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              border: Border(
                bottom: BorderSide(
                  color: cs.outlineVariant.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                _Head(l10n.productNameLabel, flex: 3),
                _Head(l10n.articleLabel, flex: 2),
                _Head(l10n.quantityLabel),
                _Head(l10n.priceLabel),
                _Head(l10n.amountLabel),
                _Head(l10n.priceTypeLabel, flex: 2),
              ],
            ),
          ),
          // Items list
          Expanded(
            child: ListView.separated(
              controller: controller,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: order.items.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 1,
                color: cs.outlineVariant.withOpacity(0.2),
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (_, i) {
                final it = order.items[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Cell(it.productName, flex: 3),
                      _Cell(it.article, flex: 2),
                      _Cell(
                        NumberFormat('#,##0.###').format(it.quantity),
                        align: TextAlign.right,
                      ),
                      _Cell(
                        uzsFormat.format(it.price),
                        align: TextAlign.right,
                      ),
                      _Cell(
                        uzsFormat.format(it.sum),
                        align: TextAlign.right,
                        isBold: true,
                      ),
                      _Cell(it.priceType, flex: 2),
                    ],
                  ),
                );
              },
            ),
          ),
          // Footer
          _buildFooter(context, totalItems, totalSum),
        ],
      ),
    );
  }
  
  Widget _buildFooter(BuildContext context, double totalItems, double totalSum) {
    final cs = Theme.of(context).colorScheme;
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.summarize_rounded,
              color: cs.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Badge(
                  label: l10n.totalProductsLabel,
                  value: NumberFormat('#,##0.###').format(totalItems),
                ),
                _Badge(
                  label: l10n.orderTotalLabel,
                  value: uzsFormat.format(totalSum),
                  isPrimary: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(l10n.close),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
class _Head extends StatelessWidget {
  final String t;
  final int flex;
  
  const _Head(this.t, {this.flex = 1});
  
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        t,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String t;
  final int flex;
  final TextAlign? align;
  final bool isBold;
  
  const _Cell(this.t, {this.flex = 1, this.align, this.isBold = false});
  
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        t,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final String value;
  final bool isPrimary;
  
  const _Badge({
    required this.label,
    required this.value,
    this.isPrimary = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isPrimary
            ? cs.primaryContainer
            : cs.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrimary
              ? cs.primary.withOpacity(0.3)
              : cs.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: isPrimary ? cs.primary : cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

