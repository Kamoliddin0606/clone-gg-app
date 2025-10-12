// lib/widgets/order_card_widget.dart
// Drop-in UI for an Orders page: elegant Card + BottomSheet (2 tabs)
// Requirements covered:
// 1) Card shows: order number, client name, date, total (UZS), status
// 2) Tap opens a modal bottom sheet with two tabs:
//    - Details: all main fields incl. courier name, car name, license plate, comments
//    - Items: product breakdown (name, article, qty, price, sum, price type) + summary
// 3) Responsive, minimalistic, modern effects & animations. Handles long text safely.
// 4) Null-safety and production-ready structure.
//
// Notes:
// - Add dependency:  intl: ^0.19.0  (for currency/date formatting)
// - Designed to work with Material 3 (useTheme: true). Falls back gracefully on M2.
// - You can customize colors via ThemeData.colorScheme.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ---- MODELS -----------------------------------------------------------------
class OrderItem {
  final String productName;
  final String article;
  final double quantity;
  final double price; // unit price (UZS)
  final String priceType; // e.g., "Retail", "Wholesale"

  const OrderItem({
    required this.productName,
    required this.article,
    required this.quantity,
    required this.price,
    required this.priceType,
  });

  double get sum => quantity * price;
}

class OrderModel {
  final int? id;
  final String numOrder;
  final DateTime dateOrder;
  final String captionOrder; // description/title
  final String typePriceCode;
  final int status; // use status mapper below
  final String? commentSupervisor;
  final String? commentForwarder;
  final String? commentAgent;
  final double total;
  final String clientCode;
  final String clientName;
  final String codeOrg;
  final String mainStatus;

  // Extra courier fields requested
  final String? courierName; // Eltuvchi ismi
  final String? courierCar; // Mashina nomi/modeli
  final String? courierPlate; // Davlat raqami

  final List<OrderItem> items;

  const OrderModel({
    required this.id,
    required this.numOrder,
    required this.dateOrder,
    required this.captionOrder,
    required this.typePriceCode,
    required this.status,
    this.commentSupervisor,
    this.commentForwarder,
    this.commentAgent,
    required this.total,
    required this.clientCode,
    required this.clientName,
    required this.codeOrg,
    required this.mainStatus,
    this.courierName,
    this.courierCar,
    this.courierPlate,
    this.items = const [],
  });
}

/// ---- UTILS ------------------------------------------------------------------
final _uzsFormat = NumberFormat.currency(locale: 'uz_UZ', symbol: 'UZS', decimalDigits: 0);
final _dateFormat = DateFormat('dd.MM.yyyy');

Color _statusColor(BuildContext context, int status) {
  final cs = Theme.of(context).colorScheme;
  switch (status) {
    case 0: // New / Created
      return cs.primary;
    case 1: // Confirmed
      return cs.tertiary; // nice accent
    case 2: // In progress / Picking
      return cs.secondary;
    case 3: // Shipped / Out for delivery
      return cs.inversePrimary;
    case 4: // Delivered
      return Colors.teal;
    case 5: // Partially paid
      return Colors.orange;
    case 6: // Overdue / expired
      return cs.error;
    default:
      return cs.outline;
  }
}

String _statusText(int status) {
  switch (status) {
    case 0:
      return 'Yangi';
    case 1:
      return 'Tasdiqlangan';
    case 2:
      return 'Yig‘ilmoqda';
    case 3:
      return 'Yo‘lda';
    case 4:
      return 'Yetkazildi';
    case 5:
      return 'Qisman to‘langan';
    case 6:
      return 'Muddat o‘tgan';
    default:
      return 'Noma’lum';
  }
}

/// A compact status chip with dynamic color.
class _StatusChip extends StatelessWidget {
  final int status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            _statusText(status),
            style: TextStyle(fontSize: 12, color: onColor.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }
}

/// ---- ORDER CARD --------------------------------------------------------------
class OrderCard extends StatelessWidget {
  final OrderModel order;
  final EdgeInsetsGeometry margin;

  const OrderCard({super.key, required this.order, this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 8)});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _InkReveal(
      onTap: () => _showOrderBottomSheet(context, order),
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
              colors: [
                cs.surface, cs.surfaceContainerHigh,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: leading mono icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.primary.withOpacity(0.2)),
                  ),
                  child: Icon(Icons.receipt_long_rounded, color: cs.primary, size: 22),
                ),
                const SizedBox(width: 12),
                // Middle: main info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '№ ${order.numOrder}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _IconText(icon: Icons.event, text: _dateFormat.format(order.dateOrder)),
                          _IconText(icon: Icons.payments_rounded, text: _uzsFormat.format(order.total)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.keyboard_arrow_up_rounded, color: cs.outline, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: cs.outline),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}

/// Subtle ripple + scale effect wrapper
class _InkReveal extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _InkReveal({required this.child, this.onTap});

  @override
  State<_InkReveal> createState() => _InkRevealState();
}

class _InkRevealState extends State<_InkReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
  late final Animation<double> _scale = Tween(begin: 1.0, end: 0.98).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  void _handleTap() async {
    await _ac.forward();
    await _ac.reverse();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// ---- BOTTOM SHEET (2 TABS) --------------------------------------------------
Future<void> _showOrderBottomSheet(BuildContext context, OrderModel order) async {
  final cs = Theme.of(context).colorScheme;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(999)),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Buyurtma № ${order.numOrder}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      _StatusChip(status: order.status),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TabBar(
                  labelColor: cs.primary,
                  indicatorColor: cs.primary,
                  tabs: const [
                    Tab(text: 'Asosiy'),
                    Tab(text: 'Tarkibi'),
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: TabBarView(
                    children: [
                      _OrderDetailsTab(order: order, controller: controller),
                      _OrderItemsTab(order: order, controller: controller),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _OrderDetailsTab extends StatelessWidget {
  final OrderModel order;
  final ScrollController controller;
  const _OrderDetailsTab({required this.order, required this.controller});

  Widget _tile(BuildContext context, String title, String value, {IconData? icon}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: cs.outline),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 6),
                Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pairs = <Widget>[
      _tile(context, 'Mijoz nomi', order.clientName, icon: Icons.badge_rounded),
      _tile(context, 'Buyurtma raqami', order.numOrder, icon: Icons.confirmation_number_outlined),
      _tile(context, 'Buyurtma sanasi', _dateFormat.format(order.dateOrder), icon: Icons.event),
      _tile(context, 'Buyurtma summasi', _uzsFormat.format(order.total), icon: Icons.payments_rounded),
      _tile(context, 'Asosiy status', order.mainStatus, icon: Icons.info_outline_rounded),
      _tile(context, 'Status kodi', order.status.toString(), icon: Icons.numbers_rounded),
      _tile(context, 'Narx turi (code)', order.typePriceCode, icon: Icons.sell_outlined),
      _tile(context, 'Mijoz kodi', order.clientCode, icon: Icons.qr_code_2_rounded),
      _tile(context, 'Tashkilot kodi', order.codeOrg, icon: Icons.apartment_rounded),
      if (order.courierName != null && order.courierName!.isNotEmpty)
        _tile(context, 'Eltuvchi', order.courierName!, icon: Icons.delivery_dining_rounded),
      if (order.courierCar != null && order.courierCar!.isNotEmpty)
        _tile(context, 'Mashina', order.courierCar!, icon: Icons.directions_car_rounded),
      if (order.courierPlate != null && order.courierPlate!.isNotEmpty)
        _tile(context, 'Davlat raqami', order.courierPlate!, icon: Icons.numbers_outlined),
      if ((order.commentSupervisor ?? '').isNotEmpty)
        _tile(context, 'Supervisor izohi', order.commentSupervisor!),
      if ((order.commentForwarder ?? '').isNotEmpty)
        _tile(context, 'Logist izohi', order.commentForwarder!),
      if ((order.commentAgent ?? '').isNotEmpty)
        _tile(context, 'Agent izohi', order.commentAgent!),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: ListView.separated(
        controller: controller,
        itemCount: pairs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => pairs[i],
      ),
    );
  }
}

class _OrderItemsTab extends StatelessWidget {
  final OrderModel order;
  final ScrollController controller;
  const _OrderItemsTab({required this.order, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final totalItems = order.items.fold<double>(0, (p, e) => p + e.quantity);
    final totalSum = order.items.fold<double>(0, (p, e) => p + e.sum);

    return Column(
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            border: Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.6))),
          ),
          child: Row(
            children: const [
              _CellHeader('Tovar nomi', flex: 3),
              _CellHeader('Artikul', flex: 2),
              _CellHeader('Soni'),
              _CellHeader('Narx'),
              _CellHeader('Summa'),
              _CellHeader('Narx turi', flex: 2),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: controller,
            itemCount: order.items.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: cs.outlineVariant.withOpacity(0.4)),
            itemBuilder: (_, i) {
              final it = order.items[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CellText(it.productName, flex: 3),
                    _CellText(it.article, flex: 2),
                    _CellText(NumberFormat('#,##0.###').format(it.quantity), textAlign: TextAlign.right),
                    _CellText(_uzsFormat.format(it.price), textAlign: TextAlign.right),
                    _CellText(_uzsFormat.format(it.sum), textAlign: TextAlign.right),
                    _CellText(it.priceType, flex: 2),
                  ],
                ),
              );
            },
          ),
        ),
        // Summary
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4)),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.summarize_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _Badge(label: 'Jami tovarlar', value: NumberFormat('#,##0.###').format(totalItems)),
                    _Badge(label: 'Buyurtma summasi', value: _uzsFormat.format(totalSum)),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Yopish'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CellHeader extends StatelessWidget {
  final String text;
  final int flex;
  const _CellHeader(this.text, {this.flex = 1});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CellText extends StatelessWidget {
  final String text;
  final int flex;
  final TextAlign? textAlign;
  const _CellText(this.text, {this.flex = 1, this.textAlign});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final String value;
  const _Badge({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.06),
        border: Border.all(color: cs.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
          Text(value, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// ---- SAMPLE USAGE (put in your ListView.builder) ----------------------------
/*
ListView.builder(
  itemCount: orders.length,
  itemBuilder: (_, i) => OrderCard(order: orders[i]),
);
*/

/// ---- QUICK DEMO PAGE (optional) ---------------------------------------------
/// You can use this page to test the widget quickly.
class OrdersDemoPage extends StatelessWidget {
  const OrdersDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sample = OrderModel(
      id: 1,
      numOrder: '000123',
      dateOrder: DateTime.now(),
      captionOrder: 'Namuna buyurtma',
      typePriceCode: 'R',
      status: 2,
      total: 1_234_000,
      clientCode: 'C001',
      clientName: 'ALMO TRADING LLC',
      codeOrg: 'ORG-01',
      mainStatus: 'Yig‘ilmoqda',
      courierName: 'Elyor Eshonov',
      courierCar: 'Malibu 2 Premier',
      courierPlate: '01 A777 AA',
      commentAgent: 'Mijoz: ertalab yetkazish so‘radi.',
      items: const [
        OrderItem(productName: 'Shampoo X', article: 'SHX-250', quantity: 10, price: 25000, priceType: 'Retail'),
        OrderItem(productName: 'Soap Y', article: 'SPY-100', quantity: 24, price: 9000, priceType: 'Retail'),
        OrderItem(productName: 'Cream Z', article: 'CRM-Z', quantity: 5.5, price: 120000, priceType: 'Wholesale'),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Orders Demo')),
      body: ListView(
        children: [OrderCard(order: sample)],
      ),
    );
  }
}



//
// # pubspec.yaml additions (merge into your file)
// #
// # dependencies:
// #   flutter:
// #     sdk: flutter
// #   intl: ^0.19.0
// #
// # flutter:
// #   uses-material-design: true
