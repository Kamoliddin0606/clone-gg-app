
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
  const OrderCard({super.key, required this.order, this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 8), this.onTap, this.onDoubleTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _InkReveal(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Card(
        margin: margin,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cs.surface, cs.surfaceContainerHigh],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.primary.withOpacity(0.2)),
                ),
                child: Icon(Icons.receipt_long_rounded, color: cs.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text('№ ${order.numOrder}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                  const SizedBox(width: 8),
                  StatusChip(status: order.mainStatus),
                ]),
                const SizedBox(height: 8),
                Text(order.clientName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Wrap(spacing: 12, runSpacing: 6, children: [
                  _IconText(icon: Icons.event, text: dateFormatShort.format(order.dateOrder)),
                  _IconText(icon: Icons.payments_rounded, text: uzsFormat.format(order.total)),
                ]),
              ])),
              const SizedBox(width: 12),
              Icon(Icons.keyboard_arrow_up_rounded, color: cs.outline, size: 22),
            ]),
          ),
        ),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  final IconData icon; final String text; const _IconText({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: cs.outline), const SizedBox(width: 6),
      Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
    ]);
  }
}

class _InkReveal extends StatefulWidget {
  final Widget child; final VoidCallback? onTap; final VoidCallback? onDoubleTap;
  const _InkReveal({required this.child, this.onTap, this.onDoubleTap});
  @override State<_InkReveal> createState() => _InkRevealState();
}
class _InkRevealState extends State<_InkReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
  late final Animation<double> _scale = Tween(begin: 1.0, end: 0.98).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
  @override void dispose(){ _ac.dispose(); super.dispose(); }
  void _tap() async { await _ac.forward(); await _ac.reverse(); widget.onTap?.call(); }
  @override Widget build(BuildContext context){ return GestureDetector(behavior: HitTestBehavior.opaque, onTap: _tap, onDoubleTap: widget.onDoubleTap, child: ScaleTransition(scale: _scale, child: widget.child)); }
}


