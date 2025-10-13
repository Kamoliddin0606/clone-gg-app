
// =============================
// presentation/pages/orders_page.dart
// =============================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/order_card.dart';
import '../widgets/order_models.dart';
import '../widgets/order_detail_sections.dart';
import '../widgets/status_chip.dart';
import '../widgets/order_filters_panel.dart';
import '../shared/formatters.dart';
import '../shared/order_status_utils.dart';
import 'order_details_page.dart';

class OrdersPage extends StatefulWidget { const OrdersPage({super.key}); @override State<OrdersPage> createState()=>_OrdersPageState(); }

class _OrdersPageState extends State<OrdersPage> with TickerProviderStateMixin {
  final TextEditingController _search = TextEditingController();
  bool _showFilters = false;  // AppBar filter panel
  bool _showTuneRow = false;  // the count + list/grid row under search
  bool _isGrid = false;

  // Static for now (future: fetch from DB)
  final List<String> _statusTabs = const ['Barchasi','Доставлено','В процессе','Возврат','Истек'];
  final Map<String,int?> _statusMap = const {'Barchasi': null,'Доставлено': 4,'В процессе': 2,'Возврат': 7,'Истек': 6};

  int _currentTabIndex = 0;
  DateTimeRange? _pickedRange;
  final OrdersFilterState _filters = OrdersFilterState();

  late List<OrderModel> _all;      // original
  late List<OrderModel> _filtered; // view

  @override void initState(){ super.initState(); _all = _demoOrders(); _filtered = _all; _search.addListener(_applyAllFilters); }
  @override void dispose(){ _search.dispose(); super.dispose(); }

  void _toggleFilters(){ setState(()=>_showFilters = !_showFilters); }
  void _toggleTune(){ setState(()=>_showTuneRow = !_showTuneRow); }
  void _switchToList(){ setState(()=>_isGrid=false); }
  void _switchToGrid(){ setState(()=>_isGrid=true); }

  void _onFiltersChanged(OrdersFilterState s){ setState(()=>{_filters.statuses = s.statuses, _filters.clients = s.clients, _filters.range = s.range}); _applyAllFilters(); }

  void _applyAllFilters(){
    final String q = _normalize(_search.text);
    final int? tabStatus = _statusMap[_statusTabs[_currentTabIndex]];

    setState((){
      _filtered = _all.where((o){
        final matchTab = (tabStatus==null) ? true : o.status == tabStatus;
        final matchStatusMulti = _filters.statuses.isEmpty ? true : _filters.statuses.contains(o.status);
        final matchDate = _filters.range==null ? true : (o.dateOrder.isAfter(_filters.range!.start.subtract(const Duration(seconds:1))) && o.dateOrder.isBefore(_filters.range!.end.add(const Duration(seconds:1))));
        final matchClient = _filters.clients.isEmpty ? true : _filters.clients.contains(o.clientName);
        final text = _normalize([
          o.numOrder, o.clientName, o.captionOrder, o.clientCode, o.codeOrg, statusText(o.status),
          NumberFormat('#,##0').format(o.total)
        ].join(' '));
        final matchSearch = q.isEmpty ? true : text.contains(q);
        return matchTab && matchStatusMulti && matchDate && matchClient && matchSearch;
      }).toList();
    });
  }

  String _normalize(String s){ return s.toLowerCase().replaceAll(RegExp(r"\s+"), " ").trim(); /* TODO: add cyr/latin transliteration */ }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initial = _filters.range ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year-2),
      lastDate: DateTime(now.year+2),
      initialDateRange: initial,
      helpText: 'Sana oralig‘ini tanlang',
    );
    if(picked!=null){ _onFiltersChanged(OrdersFilterState(statuses: _filters.statuses, clients: _filters.clients, range: picked)); }
  }

  @override
  Widget build(BuildContext context){
    final cs = Theme.of(context).colorScheme;
    final tabs = _statusTabs.map((t)=>Tab(text: t)).toList();
    final clients = _all.map((e)=>e.clientName).toSet().toList()..sort();

    return DefaultTabController(
      initialIndex: _currentTabIndex,
      length: _statusTabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buyurtmalar'), centerTitle: true,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=>Navigator.maybePop(context)),
          actions: [IconButton(icon: const Icon(Icons.filter_alt_rounded), onPressed: _toggleFilters)],
        ),
        body: Column(children:[
          // Tabs
          Material(color: Colors.transparent, child: TabBar(isScrollable: true, tabs: tabs, onTap: (i){ _currentTabIndex = i; _applyAllFilters(); })),
          // Search + tune icon
          Padding(padding: const EdgeInsets.fromLTRB(16,8,16,8), child: Row(children:[
            Expanded(child: TextField(controller: _search, decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Qidirish...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true))),
            const SizedBox(width: 12), IconButton(onPressed: _toggleTune, icon: const Icon(Icons.tune))
          ])),
          // Tune row
          AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: _showTuneRow
              ? Padding(key: const ValueKey('tune'), padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children:[
            Text('Buyurtmalar soni: ${_filtered.length}', style: Theme.of(context).textTheme.titleMedium), const Spacer(),
            IconButton(tooltip: 'List', onPressed: _switchToList, icon: Icon(Icons.view_agenda_rounded, color: _isGrid? cs.outline : cs.primary)),
            IconButton(tooltip: 'Grid', onPressed: _switchToGrid, icon: Icon(Icons.grid_view_rounded, color: _isGrid? cs.primary : cs.outline)),
            IconButton(onPressed: _toggleTune, icon: const Icon(Icons.close))
          ]))
              : const SizedBox.shrink(),),
          // Filters panel
          AnimatedSize(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, child: _showFilters
              ? Padding(padding: const EdgeInsets.fromLTRB(16,8,16,8), child: OrdersFiltersPanel(
            state: _filters,
            statusMap: _statusMap.entries.toList(),
            clients: clients,
            onChange: _onFiltersChanged,
            onPickDateRange: _pickDateRange,
            onClearDateRange: () => _onFiltersChanged(OrdersFilterState(statuses: _filters.statuses, clients: _filters.clients, range: null)),
          ))
              : const SizedBox.shrink(),),
          const SizedBox(height: 6),
          // Content
          Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: _isGrid
              ? Padding(key: const ValueKey('grid'), padding: const EdgeInsets.symmetric(horizontal: 8), child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.95),
            itemCount: _filtered.length,
            itemBuilder: (_, i){ final o = _filtered[i]; return OrderCard(order: o, margin: const EdgeInsets.all(8), onTap: ()=>_openBottomSheet(context, o), onDoubleTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>OrderDetailsPage(order: o)))); },
          ))
              : ListView.builder(key: const ValueKey('list'), itemCount: _filtered.length, itemBuilder: (_, i){ final o = _filtered[i]; return OrderCard(order: o, onTap: ()=>_openBottomSheet(context, o), onDoubleTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>OrderDetailsPage(order: o)))); }),
          )),
        ]),
      ),
    );
  }

  Future<void> _openBottomSheet(BuildContext context, OrderModel order) async {
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return DefaultTabController(length: 2, child: Column(children:[
              const SizedBox(height: 8),
              Container(width: 38, height: 4, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(999))),
              const SizedBox(height: 12),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children:[
                Icon(Icons.receipt_long_rounded, color: cs.primary), const SizedBox(width: 8),
                Expanded(child: Text('Buyurtma № ${order.numOrder}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                StatusChip(status: order.status),
              ])),
              const SizedBox(height: 12),
              const TabBar(tabs: [Tab(text: 'Asosiy'), Tab(text: 'Tarkibi')]),
              const SizedBox(height: 4),
              Expanded(child: TabBarView(children:[
                OrderDetailsSection(order: order, controller: controller),
                OrderItemsSection(order: order, controller: controller),
              ])),
            ]));
          },
        );
      },
    );
  }

  // ------- demo data ---------------------------------------------------------
  List<OrderModel> _demoOrders(){
    final now = DateTime.now();
    final list = <OrderModel>[];
    final clients = ['MAYRAM - ONAXON YATT','LAYLO FAYZ BARAKA','KYUT SAMARA OOO','ALMO TRADING LLC','BARAKA OPT','FERGANA OIL'];
    for(int i=0;i<20;i++){
      final st = [1,2,2,4,6,5][i%6];
      list.add(OrderModel(
        id: i+1,
        numOrder: 'GL00-${160000+i}',
        dateOrder: now.subtract(Duration(minutes: i*17)),
        captionOrder: 'Zakaz ${i+1}',
        typePriceCode: 'R',
        status: st,
        total: (150000 + i*12000).toDouble(),
        clientCode: '00-000${5000+i}',
        clientName: clients[i%clients.length],
        codeOrg: '00000000001',
        mainStatus: statusText(st),
        items: const [
          OrderItem(productName: 'Shampoo X', article: 'SHX-250', quantity: 10, price: 25000, priceType: 'Retail'),
          OrderItem(productName: 'Soap Y', article: 'SPY-100', quantity: 24, price: 9000, priceType: 'Retail'),
        ],
      ));
    }
    return list;
  }
}
