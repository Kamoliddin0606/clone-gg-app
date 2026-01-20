// =============================
// presentation/widgets/order_card_grid.dart
// =============================
import 'package:flutter/material.dart';
import '../shared/formatters.dart';
import '../shared/order_status_utils.dart';
import 'status_chip.dart';
import 'order_models.dart';

class OrderCardGrid extends StatelessWidget {
  final OrderModel order;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const OrderCardGrid({
    super.key,
    required this.order,
    this.margin = const EdgeInsets.all(8),
    this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final promoColor = order.promo ? Colors.amber.withOpacity(0.15) : null;

    return _InkReveal(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Card(
        margin: margin,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: order.promo
              ? BorderSide(color: Colors.amber.withOpacity(0.4), width: 1.5)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                promoColor ?? cs.surface,
                promoColor ?? cs.surfaceContainerHigh.withOpacity(0.8),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order date - top right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        dateFormatShort.format(order.dateOrder),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Order number - below date, left aligned
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '№ ${order.numOrder}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Client name - adaptive height based on content
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final textPainter = TextPainter(
                        text: TextSpan(
                          text: order.clientName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface,
                              ),
                        ),
                        maxLines: 2,
                        textDirection: TextDirection.ltr,
                      );
                      textPainter.layout(maxWidth: constraints.maxWidth);

                      return SizedBox(
                        height: textPainter.height,
                        child: Text(
                          order.clientName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface,
                              ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Items count - separate row, left aligned
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_rounded,
                        size: 16,
                        color: cs.onSurfaceVariant.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${order.items.length} ta mahsulot',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Total amount - separate row, left aligned
                  Row(
                    children: [
                      Icon(
                        Icons.payments_rounded,
                        size: 16,
                        color: cs.primary.withOpacity(0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        uzsFormat.format(order.total),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Status at bottom - adaptive width with scrolling
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SizedBox(
                        width: constraints.maxWidth,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: StatusChip(status: order.mainStatus),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InkReveal extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const _InkReveal({required this.child, this.onTap, this.onDoubleTap});

  @override
  State<_InkReveal> createState() => _InkRevealState();
}

class _InkRevealState extends State<_InkReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );
  late final Animation<double> _scale = Tween(
    begin: 1.0,
    end: 0.96,
  ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));

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
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
