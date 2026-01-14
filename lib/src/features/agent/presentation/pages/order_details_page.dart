// =============================
// presentation/pages/order_details_page.dart
// =============================
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import '../widgets/order_models.dart';
import '../widgets/order_detail_sections.dart';
import '../widgets/order_items_card_view.dart';
import '../widgets/status_chip.dart';
import '../../../../core/services/api_database_service.dart';
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
        _detailedOrder = await _convertOrderDetailToOrderModel(
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
        _detailedOrder = await _convertOrderDetailToOrderModel(
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
  Future<OrderModel> _convertOrderDetailToOrderModel(
    OrderDetail orderDetail,
    OrderModel originalOrder,
  ) {
    try {
      // Validate order detail data
      if (orderDetail.productRows == null || orderDetail.productRows!.isEmpty) {
        debugPrint(
          'Warning: orderDetail.productRows is null or empty for order ${originalOrder.numOrder}',
        );
        return Future.value(originalOrder.copyWith(items: []));
      }

      // Convert order detail products to order items with validation
      return _buildOrderItems(orderDetail, originalOrder).then((items) async {
        final shippingDate = DateTime.tryParse(orderDetail.shippingDate);

        String? organizationName;
        try {
          final db = GetIt.I<ApiDatabaseService>();
          final org = await db.getUserOrganizationByCode(originalOrder.codeOrg);
          organizationName = org?.name;
        } catch (e) {
          debugPrint('Error resolving organization name: $e');
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
          shippingDate: shippingDate,
          total: originalOrder.total,
          clientCode: originalOrder.clientCode,
          clientName: originalOrder.clientName,
          codeOrg: originalOrder.codeOrg,
          organizationName: organizationName,
          mainStatus: originalOrder.mainStatus,
          courierName: originalOrder.courierName,
          courierCar: originalOrder.courierCar,
          courierPlate: originalOrder.courierPlate,
          items: items,
        );
      });
    } catch (e) {
      debugPrint(
        'Error converting OrderDetail to OrderModel for order ${originalOrder.numOrder}: $e',
      );
      // Return original order with empty items as fallback
      return Future.value(originalOrder.copyWith(items: []));
    }
  }

  Future<List<OrderItem>> _buildOrderItems(
    OrderDetail orderDetail,
    OrderModel originalOrder,
  ) async {
    final items = <OrderItem>[];
    final db = GetIt.I<ApiDatabaseService>();
    final vendorCache = <String, String>{};

    for (final product in orderDetail.productRows!) {
      if (product == null) continue;

      try {
        final codeProduct = product.codeProduct.trim();
        if (codeProduct.isEmpty) continue;

        final cachedVendor = vendorCache[codeProduct];
        final vendorCode = cachedVendor ??
            (await db.getProductByCode(codeProduct))?.vendorCode.trim();

        if (vendorCode != null && vendorCode.isNotEmpty) {
          vendorCache[codeProduct] = vendorCode;
        }

        final article = (vendorCode != null && vendorCode.isNotEmpty)
            ? vendorCode
            : codeProduct;

        // Use price and price type from order_detail_products table (primary source)
        // Fall back to order's price type if product doesn't have one
        final productPriceType = product.priceTypeCode?.isNotEmpty == true
            ? product.priceTypeCode!
            : originalOrder.typePriceCode;
        
        items.add(
          OrderItem(
            productName: product.nameProduct.trim().isNotEmpty
                ? product.nameProduct.trim()
                : (AppLocalizations.of(context)?.unknownProduct ??
                    'Noma\'lum mahsulot'),
            article: article,
            quantity: product.amount.toDouble(),
            price: product.price,
            priceType: productPriceType,
            lineTotal: product.total,
          ),
        );
      } catch (e) {
        debugPrint('Error converting product ${product.codeProduct}: $e');
      }
    }

    return items;
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
    final cs = Theme.of(context).colorScheme;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: cs.surfaceContainerLowest,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: cs.surface,
          title: Text(
            AppLocalizations.of(context)?.orderDetailsTitle ??
                'Buyurtma tafsilotlari',
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)?.loading ?? 'Yuklanmoqda...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: cs.surfaceContainerLowest,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: cs.surface,
          title: Text(
            AppLocalizations.of(context)?.orderDetailsTitle ??
                'Buyurtma tafsilotlari',
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: cs.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)?.errorOccurredTitle ??
                      'Xatolik yuz berdi',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(
                        AppLocalizations.of(context)?.back ?? 'Orqaga',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: _loadOrderDetails,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        AppLocalizations.of(context)?.retry ??
                            'Qayta urinib ko\'ring',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: cs.surface,
        title: Text(
          AppLocalizations.of(context)?.orderDetailsTitle ??
              'Buyurtma tafsilotlari',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Modern header with Hero animation
            Hero(
              tag: 'order_${order.numOrder}',
              child: Material(
                color: cs.surface,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              color: cs.onPrimaryContainer,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.orderNumberLabel,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  order.numOrder,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: cs.onSurface,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusChip(status: order.mainStatus),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: cs.outlineVariant.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.store_rounded,
                              size: 20,
                              color: cs.primary,
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Modern TabBar
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  bottom: BorderSide(
                    color: cs.outlineVariant.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 3,
                labelStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(
                    icon: Icon(Icons.info_outline_rounded, size: 20),
                    text: AppLocalizations.of(context)?.main ?? 'Asosiy',
                  ),
                  Tab(
                    icon: Icon(Icons.inventory_2_outlined, size: 20),
                    text: AppLocalizations.of(context)?.contents ?? 'Tarkibi',
                  ),
                ],
              ),
            ),
            // Content with smooth transitions
            Expanded(
              child: TabBarView(
                children: [
                  OrderDetailsSection(
                    order: order,
                    controller: ScrollController(),
                  ),
                  OrderItemsCardView(
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
