
// =============================
// presentation/widgets/order_detail_sections.dart
// =============================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import '../shared/formatters.dart';
import 'order_models.dart';

class OrderDetailsSection extends StatelessWidget {
  final OrderModel order; final ScrollController? controller; const OrderDetailsSection({super.key, required this.order, this.controller});
  Widget _tile(BuildContext context, String title, String value, {IconData? icon}){
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(14), border: Border.all(color: cs.outlineVariant.withOpacity(0.5))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children:[
        if(icon!=null)...[Icon(icon, size: 18, color: cs.outline), const SizedBox(width: 10)],
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)), const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
        ]))
      ]),
    );
  }
  @override Widget build(BuildContext context){
    final l10n = AppLocalizations.of(context)!;
    final pairs = <Widget>[
      _tile(context, l10n.clientNameLabel, order.clientName.isNotEmpty ? order.clientName : order.clientCode, icon: Icons.badge_rounded),
      _tile(context, l10n.orderNumberLabel, order.numOrder, icon: Icons.confirmation_number_outlined),
      _tile(context, l10n.orderDateLabel, dateTimeFormat.format(order.dateOrder), icon: Icons.event),
      _tile(context, l10n.orderTotalLabel, uzsFormat.format(order.total), icon: Icons.payments_rounded),
      _tile(context, l10n.mainStatusLabel, order.mainStatus, icon: Icons.info_outline_rounded),
      _tile(context, l10n.statusCodeLabel, order.status.toString(), icon: Icons.numbers_rounded),
      _tile(context, '${l10n.priceTypeLabel} (code)', order.typePriceCode, icon: Icons.sell_outlined),
      _tile(context, 'Mijoz kodi', order.clientCode, icon: Icons.qr_code_2_rounded),
      _tile(context, 'Tashkilot kodi', order.codeOrg, icon: Icons.apartment_rounded),
      if((order.courierName??'').isNotEmpty) _tile(context, 'Eltuvchi', order.courierName!, icon: Icons.delivery_dining_rounded),
      if((order.courierCar??'').isNotEmpty) _tile(context, 'Mashina', order.courierCar!, icon: Icons.directions_car_rounded),
      if((order.courierPlate??'').isNotEmpty) _tile(context, 'Davlat raqami', order.courierPlate!, icon: Icons.numbers_outlined),
      if((order.commentSupervisor??'').isNotEmpty) _tile(context, 'Supervisor izohi', order.commentSupervisor!),
      if((order.commentForwarder??'').isNotEmpty) _tile(context, 'Logist izohi', order.commentForwarder!),
      if((order.commentAgent??'').isNotEmpty) _tile(context, 'Agent izohi', order.commentAgent!),
    ];
    return Padding(padding: const EdgeInsets.fromLTRB(16,8,16,16), child: ListView.separated(controller: controller, itemCount: pairs.length, separatorBuilder: (_, __)=>const SizedBox(height:12), itemBuilder: (_, i)=>pairs[i]));
  }
}

class OrderItemsSection extends StatelessWidget {
  final OrderModel order; final ScrollController? controller; const OrderItemsSection({super.key, required this.order, this.controller});
  @override Widget build(BuildContext context){
    final cs = Theme.of(context).colorScheme;

    // Handle empty items case
    final l10n = AppLocalizations.of(context)!;
    if (order.items.isEmpty) {
      return Column(children:[
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: cs.surfaceContainerLow, border: Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.6)))), child: Row(children: [
          _Head(l10n.productNameLabel, flex: 3), _Head(l10n.articleLabel, flex: 2), _Head(l10n.quantityLabel), _Head(l10n.priceLabel), _Head(l10n.amountLabel), _Head(l10n.priceTypeLabel, flex: 2),
        ])),
        Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: cs.outline),
          const SizedBox(height: 16),
          Text(l10n.noProductsInOrder, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(l10n.productListEmpty, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline)),
        ]))),
        Container(padding: const EdgeInsets.fromLTRB(16,12,16,16), decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0,-4))]), child: Row(children:[
          const Icon(Icons.summarize_rounded), const SizedBox(width: 10), Expanded(child: Wrap(spacing: 16, runSpacing: 8, children:[
            _Badge(label: l10n.totalProductsLabel, value: '0'), _Badge(label: l10n.orderTotalLabel, value: uzsFormat.format(0.0)),
          ])), FilledButton.icon(onPressed: ()=>Navigator.of(context).maybePop(), icon: const Icon(Icons.check_circle_outline), label: Text(l10n.close)),
        ])),
      ]);
    }

    final totalItems = order.items.fold<double>(0, (p, e) => p + e.quantity);
    final totalSum = order.items.fold<double>(0, (p, e) => p + e.sum);

    return Column(children:[
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: cs.surfaceContainerLow, border: Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.6)))), child: Row(children: [
        _Head(l10n.productNameLabel, flex: 3), _Head(l10n.articleLabel, flex: 2), _Head(l10n.quantityLabel), _Head(l10n.priceLabel), _Head(l10n.amountLabel), _Head(l10n.priceTypeLabel, flex: 2),
      ])),
      Expanded(child: ListView.separated(controller: controller, itemCount: order.items.length, separatorBuilder: (_, __)=>Divider(height: 1, color: cs.outlineVariant.withOpacity(0.4)), itemBuilder: (_, i){
        final it = order.items[i];
        return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children:[
          _Cell(it.productName, flex: 3), _Cell(it.article, flex: 2), _Cell(NumberFormat('#,##0.###').format(it.quantity), align: TextAlign.right), _Cell(uzsFormat.format(it.price), align: TextAlign.right), _Cell(uzsFormat.format(it.sum), align: TextAlign.right), _Cell(it.priceType, flex: 2),
        ]));
      })),
      Container(padding: const EdgeInsets.fromLTRB(16,12,16,16), decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0,-4))]), child: Row(children:[
        const Icon(Icons.summarize_rounded), const SizedBox(width: 10), Expanded(child: Wrap(spacing: 16, runSpacing: 8, children:[
          _Badge(label: l10n.totalProductsLabel, value: NumberFormat('#,##0.###').format(totalItems)), _Badge(label: l10n.orderTotalLabel, value: uzsFormat.format(totalSum)),
        ])), FilledButton.icon(onPressed: ()=>Navigator.of(context).maybePop(), icon: const Icon(Icons.check_circle_outline), label: Text(l10n.close)),
      ])),
    ]);
  }
}
class _Head extends StatelessWidget { final String t; final int flex; const _Head(this.t, {this.flex = 1}); @override Widget build(BuildContext context)=>Expanded(flex: flex, child: Text(t, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700))); }
class _Cell extends StatelessWidget { final String t; final int flex; final TextAlign? align; const _Cell(this.t, {this.flex = 1, this.align}); @override Widget build(BuildContext context)=>Expanded(flex: flex, child: Text(t, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: align, style: Theme.of(context).textTheme.bodyMedium)); }
class _Badge extends StatelessWidget { final String label; final String value; const _Badge({required this.label, required this.value}); @override Widget build(BuildContext context){ final cs = Theme.of(context).colorScheme; return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: cs.primary.withOpacity(0.06), border: Border.all(color: cs.primary.withOpacity(0.3)), borderRadius: BorderRadius.circular(999)), child: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children:[ Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)), Text(value, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)) ])); }
}

