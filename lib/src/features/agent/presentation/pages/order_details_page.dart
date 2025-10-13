
// =============================
// presentation/pages/order_details_page.dart
// =============================
import 'package:flutter/material.dart';
import '../widgets/order_models.dart';
import '../widgets/order_detail_sections.dart';
import '../widgets/status_chip.dart';

class OrderDetailsPage extends StatelessWidget {
  final OrderModel order; const OrderDetailsPage({super.key, required this.order});
  @override Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Buyurtma tafsilotlari')),
      body: DefaultTabController(length: 2, child: Column(children:[
        Padding(padding: const EdgeInsets.fromLTRB(16,16,16,0), child: Row(children:[
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            Text(order.numOrder, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
          ])),
          StatusChip(status: order.status),
        ])),
        const SizedBox(height: 12),
        const TabBar(tabs: [Tab(text:'Asosiy'), Tab(text:'Tarkibi')]),
        Expanded(child: TabBarView(children:[
          OrderDetailsSection(order: order, controller: ScrollController()),
          OrderItemsSection(order: order, controller: ScrollController()),
        ]))
      ])),
    );
  }
}

