// =============================
// presentation/pages/order_details_page.dart
// =============================
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
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
      final cachedOrderDetail = await dataSyncService
          .getCachedOrderDetailByNumOrder(widget.order.numOrder);
      if (cachedOrderDetail != null) {
        debugPrint(
          'Loading order details from cache for order: ${widget.order.numOrder}',
        );
        // Convert OrderDetail to OrderModel with additional data
        _detailedOrder = _convertOrderDetailToOrderModel(
          cachedOrderDetail,
          widget.order,
        );
        setState(() => _isLoading = false);
        return;
      } else {
        debugPrint(
          'No cached order details found for order: ${widget.order.numOrder}',
        );
      }

      // If no cache, fetch from server
      final userCode = await _getUserCode();
      if (userCode != null) {
        debugPrint(
          'Fetching order details from server for order: ${widget.order.numOrder}',
        );
        final orderDate1 = widget.order.dateOrder.toIso8601String().split(
          'T',
        )[0];
        final orderDate2 = widget.order.dateOrder.toIso8601String().split(
          'T',
        )[0];

        final freshOrderDetail = await dataSyncService.syncOrderDetails(
          numberOrder: widget.order.numOrder,
          orderDate1: orderDate1,
          orderDate2: orderDate2,
          forceRefresh: true,
        );

        // Convert and merge with existing order data
        _detailedOrder = _convertOrderDetailToOrderModel(
          freshOrderDetail,
          widget.order,
        );
        setState(() => _isLoading = false);
      } else {
        debugPrint('No user code available, using original order data');
        // Fallback to original order if no user code
        _detailedOrder = widget.order;
        setState(() => _isLoading = false);
      }
    } catch (e, stackTrace) {
      debugPrint(
        'Error loading order details for ${widget.order.numOrder}: $e',
      );
      debugPrint('Stack trace: $stackTrace');

      // Enhanced error handling with user-friendly messages
      String errorMessage;
      if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage =
            'Internet bilan bog\'liq xatolik. Iltimos, internetingizni tekshiring.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Server javob bermayapti. Keyinroq urinib ko\'ring.';
      } else if (e.toString().contains('not found') ||
          e.toString().contains('404')) {
        errorMessage = 'Buyurtma tafsilotlari topilmadi.';
      } else {
        errorMessage = 'Buyurtma tafsilotlarini yuklashda xatolik yuz berdi.';
      }

      setState(() {
        _error = errorMessage;
        _isLoading = false;
        // Fallback to original order data
        _detailedOrder = widget.order;
      });
    }
  }

  /// Convert OrderDetail to OrderModel with merged data
  OrderModel _convertOrderDetailToOrderModel(
    OrderDetail orderDetail,
    OrderModel originalOrder,
  ) {
    try {
      // Validate order detail data
      if (orderDetail.productRows == null || orderDetail.productRows!.isEmpty) {
        debugPrint(
          'Warning: orderDetail.productRows is null or empty for order ${originalOrder.numOrder}',
        );
        return originalOrder.copyWith(items: []);
      }

      // Convert order detail products to order items with validation
      final items = <OrderItem>[];
      for (final product in orderDetail.productRows!) {
        if (product == null) continue;

        try {
          // Validate required fields
          final codeProduct = product.codeProduct?.trim();
          if (codeProduct == null || codeProduct.isEmpty) continue;

          final orderItem = OrderItem(
            productName: product.nameProduct?.trim().isNotEmpty == true
                ? product.nameProduct!.trim()
                : 'Noma\'lum mahsulot',
            article: codeProduct,
            quantity: (product.amount ?? 0).toDouble(),
            price: product.price ?? 0.0,
            priceType: originalOrder.typePriceCode,
          );
          items.add(orderItem);
        } catch (e) {
          debugPrint('Error converting product ${product.codeProduct}: $e');
          // Skip invalid products instead of adding error items
        }
      }

      debugPrint(
        'Successfully converted ${items.length} items for order ${originalOrder.numOrder}',
      );

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
    } catch (e) {
      debugPrint(
        'Error converting OrderDetail to OrderModel for order ${originalOrder.numOrder}: $e',
      );
      // Return original order with empty items as fallback
      return originalOrder.copyWith(items: []);
    }
  }

  /// Get user code from shared preferences
  Future<String?> _getUserCode() async {
    try {
      final prefs = GetIt.I<SharedPreferencesService>();
      final userCode = prefs.getUserCode();
      return userCode;
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
          title: Text(
            AppLocalizations.of(context)?.orderDetailsTitle ??
                'Buyurtma tafsilotlari',
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            AppLocalizations.of(context)?.orderDetailsTitle ??
                'Buyurtma tafsilotlari',
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Xatolik yuz berdi',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(
                        AppLocalizations.of(context)?.back ?? 'Orqaga',
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _loadOrderDetails,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        AppLocalizations.of(context)?.retry ??
                            'Qayta urinib ko\'ring',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final order = _detailedOrder ?? widget.order;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)?.orderDetailsTitle ??
              'Buyurtma tafsilotlari',
        ),
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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
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
            TabBar(
              tabs: [
                Tab(text: AppLocalizations.of(context)?.main ?? 'Asosiy'),
                Tab(text: AppLocalizations.of(context)?.contents ?? 'Tarkibi'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  OrderDetailsSection(
                    order: order,
                    controller: ScrollController(),
                  ),
                  OrderItemsSection(
                    order: order,
                    controller: ScrollController(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
