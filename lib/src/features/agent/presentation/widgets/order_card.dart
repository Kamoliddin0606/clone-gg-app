
// =============================
// presentation/widgets/order_card.dart
// =============================
import 'package:flutter/material.dart';
import '../shared/formatters.dart';
import '../shared/order_status_utils.dart';
import 'status_chip.dart';
import 'order_models.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  const OrderCard({super.key, required this.order, this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6), this.onTap, this.onDoubleTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    
    return Hero(
      tag: 'order_${order.numOrder}',
      child: _InkReveal(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        child: Container(
          margin: margin,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                onDoubleTap: onDoubleTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Order number and status
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.receipt_long_rounded, color: cs.onPrimaryContainer, size: 16),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      order.numOrder,
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: cs.onPrimaryContainer,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusChip(status: order.mainStatus),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: cs.outline.withOpacity(0.5),
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Client name
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.store_rounded,
                              color: cs.onSecondaryContainer,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              order.clientName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Date and amount
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _InfoChip(
                                icon: Icons.calendar_today_rounded,
                                label: dateFormatShort.format(order.dateOrder),
                                color: cs.tertiary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _InfoChip(
                                icon: Icons.payments_rounded,
                                label: uzsFormat.format(order.total),
                                color: cs.primary,
                                isBold: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isBold;
  
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    this.isBold = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _InkReveal extends StatefulWidget {
  final Widget child; final VoidCallback? onTap; final VoidCallback? onDoubleTap;
  const _InkReveal({required this.child, this.onTap, this.onDoubleTap});
  @override State<_InkReveal> createState() => _InkRevealState();
}
class _InkRevealState extends State<_InkReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );
  late final Animation<double> _scale = Tween(begin: 1.0, end: 0.97).animate(
    CurvedAnimation(parent: _ac, curve: Curves.easeInOut),
  );
  
  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }
  
  void _tap() async {
    await _ac.forward();
    await _ac.reverse();
    widget.onTap?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tap,
      onDoubleTap: widget.onDoubleTap,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}


