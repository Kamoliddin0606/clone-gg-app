
// =============================
// presentation/pages/order_details_page.dart
// =============================
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../widgets/order_models.dart';
import '../widgets/order_detail_sections.dart';
import '../widgets/status_chip.dart';
import '../../../../core/services/data_sync_service.dart';
import '../../../../core/services/shared_preferences_service.dart';
import '../../../agent/data/models/order_detail.dart';

class OrderDetailsPage extends StatefulWidget {
  final OrderModel order;
  const OrderDetailsPage({super.key, required this.order});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  bool _isLoading = true;
  String? _error;
  OrderModel? _detailedOrder;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  /// Load order details from cache or server
  Future<void> _loadOrderDetails() async {
    try {
      setState(() => _isLoading = true);

      final dataSyncService = GetIt.I<DataSyncService>();

      // Try to get cached order details first
      final cachedOrderDetail = await dataSyncService.getCachedOrderDetailByNumOrder(widget.order.numOrder);
      if (cachedOrderDetail != null) {
        // Convert OrderDetail to OrderModel with additional data
        _detailedOrder = _convertOrderDetailToOrderModel(cachedOrderDetail, widget.order);
        setState(() => _isLoading = false);
        return;
      }

      // If no cache, fetch from server
      final userCode = await _getUserCode();
      if (userCode != null) {
        final orderDate1 = widget.order.dateOrder.toIso8601String().split('T')[0];
        final orderDate2 = widget.order.dateOrder.toIso8601String().split('T')[0];

        final freshOrderDetail = await dataSyncService.syncOrderDetails(
          numberOrder: widget.order.numOrder,
          orderDate1: orderDate1,
          orderDate2: orderDate2,
        );

        // Convert and merge with existing order data
        _detailedOrder = _convertOrderDetailToOrderModel(freshOrderDetail, widget.order);
        setState(() => _isLoading = false);
      } else {
        // Fallback to original order if no user code
        _detailedOrder = widget.order;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading order details: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Convert OrderDetail to OrderModel with merged data
  OrderModel _convertOrderDetailToOrderModel(OrderDetail orderDetail, OrderModel originalOrder) {
    // Convert order detail products to order items
    final items = orderDetail.productRows?.map((product) => OrderItem(
      productName: product.nameProduct ?? '',
      article: product.codeProduct ?? '',
      quantity: (product.amount ?? 0).toDouble(),
      price: product.price ?? 0.0,
      priceType: originalOrder.typePriceCode,
    )).toList() ?? [];

    return OrderModel(
      id: originalOrder.id,
      numOrder: originalOrder.numOrder,
      dateOrder: originalOrder.dateOrder,
      captionOrder: originalOrder.captionOrder,
      typePriceCode: originalOrder.typePriceCode,
      status: originalOrder.status,
      commentSupervisor: orderDetail.commentSupervisor,
      commentForwarder: orderDetail.commentForwarder,
      commentAgent: orderDetail.commentAgent,
      total: originalOrder.total,
      clientCode: originalOrder.clientCode,
      clientName: originalOrder.clientName,
      codeOrg: originalOrder.codeOrg,
      mainStatus: originalOrder.mainStatus,
      courierName: originalOrder.courierName,
      courierCar: originalOrder.courierCar,
      courierPlate: originalOrder.courierPlate,
      items: items,
    );
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Buyurtma tafsilotlari'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
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
          centerTitle: true,
          title: const Text('Buyurtma tafsilotlari'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
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
                onPressed: _loadOrderDetails,
                child: const Text('Qayta urinib ko\'ring'),
              ),
            ],
          ),
        ),
      );
    }

    final order = _detailedOrder ?? widget.order;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Buyurtma tafsilotlari'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.numOrder,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  StatusChip(status: order.mainStatus),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const TabBar(tabs: [Tab(text: 'Asosiy'), Tab(text: 'Tarkibi')]),
            Expanded(
              child: TabBarView(
                children: [
                  OrderDetailsSection(order: order, controller: ScrollController()),
                  OrderItemsSection(order: order, controller: ScrollController()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

