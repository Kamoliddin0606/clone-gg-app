
// =============================
// presentation/pages/orders_page.dart
// =============================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import '../widgets/order_card.dart';
import '../widgets/order_card_grid.dart';
import '../widgets/order_models.dart';
import '../widgets/order_detail_sections.dart';
import '../widgets/status_chip.dart';
import '../widgets/order_filters_panel.dart';
import '../shared/formatters.dart';
import '../shared/order_status_utils.dart';
import 'order_details_page.dart';
import '../../../../core/services/data_sync_service.dart';
import '../../../../core/services/shared_preferences_service.dart';
import '../../../agent/data/models/order.dart';
import '../../../agent/data/models/order_status.dart';

class OrdersPage extends StatefulWidget { const OrdersPage({super.key}); @override State<OrdersPage> createState()=>_OrdersPageState(); }

class _OrdersPageState extends State<OrdersPage> with TickerProviderStateMixin {
  final TextEditingController _search = TextEditingController();
  bool _showFilters = false;  // AppBar filter panel
  bool _showTuneRow = false;  // the count + list/grid row under search
  bool _isGrid = false;

  // Dynamic status data
  List<String> _statusTabs = ['Barchasi'];
  Map<String,int?> _statusMap = {'Barchasi': null};
  List<OrderStatus> _orderStatuses = [];

  int _currentTabIndex = 0;
  DateTimeRange? _pickedRange;
  final OrdersFilterState _filters = OrdersFilterState();

  late List<Order> _allOrders;      // original orders from server
  late List<OrderModel> _all;      // original presentation models
  late List<OrderModel> _filtered; // view

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search.addListener(_applyAllFilters);
    _loadOrderStatusesAndOrders();
  }
  @override void dispose(){ _search.dispose(); super.dispose(); }

  void _toggleFilters(){ setState(()=>_showFilters = !_showFilters); }
  void _toggleTune(){ setState(()=>_showTuneRow = !_showTuneRow); }
  void _switchToList(){ setState(()=>_isGrid=false); }
  void _switchToGrid(){ setState(()=>_isGrid=true); }

  void _onFiltersChanged(OrdersFilterState s){ setState(()=>{_filters.statuses = s.statuses, _filters.clients = s.clients, _filters.range = s.range}); _applyAllFilters(); }

  /// Load order statuses and orders with cache-first approach
  Future<void> _loadOrderStatusesAndOrders() async {
    try {
      setState(() => _isLoading = true);

      // Load order statuses first
      await _loadOrderStatuses();

      // Load orders with cache-first approach
      await _loadOrders();

    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Load order statuses from cache or server
  Future<void> _loadOrderStatuses() async {
    try {
      final dataSyncService = GetIt.I<DataSyncService>();
      final cachedStatuses = await dataSyncService.getCachedOrderStatuses();

      if (cachedStatuses.isNotEmpty) {
        _orderStatuses = cachedStatuses;
        _buildStatusTabsAndMap();
        return;
      }

      // If no cache, fetch from server
      final userCode = await _getUserCode();
      if (userCode != null) {
        final freshStatuses = await dataSyncService.syncOrderStatuses(userCode: userCode);
        _orderStatuses = freshStatuses;
        _buildStatusTabsAndMap();
      }
    } catch (e) {
      debugPrint('Error loading order statuses: $e');
      // Fallback to default statuses
      _buildDefaultStatusTabsAndMap();
    }
  }

  /// Load orders with cache-first approach
  Future<void> _loadOrders() async {
    try {
      final dataSyncService = GetIt.I<DataSyncService>();

      // Try to get cached orders first
      final cachedOrders = await dataSyncService.getCachedOrders();
      if (cachedOrders.isNotEmpty) {
        _allOrders = cachedOrders;
        _all = _convertOrdersToOrderModels(_allOrders);
        _filtered = List.from(_all);
        return;
      }

      // If no cache, fetch from server
      final userCode = await _getUserCode();
      if (userCode != null) {
        final freshOrders = await dataSyncService.syncOrders(userCode: userCode);
        _allOrders = freshOrders;
        _all = _convertOrdersToOrderModels(_allOrders);
        _filtered = List.from(_all);
      } else {
        // Fallback to demo data if no user code
        _all = _demoOrders();
        _filtered = List.from(_all);
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
      // Fallback to demo data
      _all = _demoOrders();
      _filtered = List.from(_all);
    }
  }

  /// Build status tabs and map from order statuses
  void _buildStatusTabsAndMap() {
    _statusTabs = ['Barchasi'];
    _statusMap = {'Barchasi': null};

    for (final status in _orderStatuses) {
      if (status.id != null) {
        _statusTabs.add(status.message);
        _statusMap[status.message] = status.id;
      }
    }
  }

  /// Build default status tabs and map (fallback)
  void _buildDefaultStatusTabsAndMap() {
    _statusTabs = ['Barchasi', 'Доставлено', 'В процессе', 'Возврат', 'Истек'];
    _statusMap = {
      'Barchasi': null,
      'Доставлено': 4,
      'В процессе': 2,
      'Возврат': 7,
      'Истек': 6
    };
  }

  /// Convert Order list to OrderModel list for presentation
  List<OrderModel> _convertOrdersToOrderModels(List<Order> orders) {
    return orders.map((order) => OrderModel(
      id: order.id,
      numOrder: order.numOrder,
      dateOrder: order.dateOrder,
      captionOrder: order.captionOrder,
      typePriceCode: order.typePriceCode,
      status: order.status,
      commentSupervisor: order.commentSupervisor,
      commentForwarder: order.commentForwarder,
      commentAgent: order.commentAgent,
      total: order.total,
      clientCode: order.clientCode,
      clientName: order.clientName,
      codeOrg: order.codeOrg,
      mainStatus: order.mainStatus,
      courierName: order.courierName,
      courierCar: order.courierCar,
      courierPlate: order.courierCar, // Assuming courierCar contains plate info
      items: const [], // Items will be loaded separately if needed
    )).toList();
  }

  /// Get user code from shared preferences
  Future<String?> _getUserCode() async {
    try {
      final prefs = GetIt.I<SharedPreferencesService>();
      return await prefs.getUserCode();
    } catch (e) {
      debugPrint('Error getting user code: $e');
      return null;
    }
  }

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
    final clients = _isLoading ? [] : _all.map((e)=>e.clientName).toSet().toList()..sort();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Buyurtmalar'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context)
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Buyurtmalar'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context)
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Xatolik yuz berdi: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrderStatusesAndOrders,
                child: const Text('Qayta urinib ko\'ring'),
              ),
            ],
          ),
        ),
      );
    }

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
            clients: clients.cast<String>(),
            onChange: _onFiltersChanged,
            onPickDateRange: _pickDateRange,
            onClearDateRange: () => _onFiltersChanged(OrdersFilterState(statuses: _filters.statuses, clients: _filters.clients, range: null)),
          ))
              : const SizedBox.shrink(),),
          const SizedBox(height: 6),
          // Content
          Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: _isGrid
              ? Padding(key: const ValueKey('grid'), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: _filtered.length,
            itemBuilder: (_, i){ final o = _filtered[i]; return OrderCardGrid(order: o, onTap: ()=>_openBottomSheet(context, o), onDoubleTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>OrderDetailsPage(order: o)))); },
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
