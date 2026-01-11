import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/create_order.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/order_details_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/order_models.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/visit_steps_page.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

/// Visit Completion Page - Shows completed visit steps with order details access
/// Displays all successfully completed steps and allows navigation to order details
class VisitCompletionPage extends StatefulWidget {
  final TradingPointWithPermissions tradingPoint;
  final SalesReqPermissions permissions;
  final List<VisitStepProgress> completedSteps;

  const VisitCompletionPage({
    super.key,
    required this.tradingPoint,
    required this.permissions,
    required this.completedSteps,
  });

  @override
  State<VisitCompletionPage> createState() => _VisitCompletionPageState();
}

class _VisitCompletionPageState extends State<VisitCompletionPage> {
  bool _isLoadingOrder = false;
  CreateOrder? _createdOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.visitCompletedTitle ?? 'Tashrif yakunlandi'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove back button
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: Text(
              l10n?.close ?? 'Yopish',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.08),
              theme.colorScheme.primaryContainer.withOpacity(0.06),
            ],
          ),
        ),
        child: Column(
          children: [
            // Success Header
            _buildSuccessHeader(context, theme),

            // Completed Steps List
            Expanded(
              child: _buildCompletedStepsList(context, theme, l10n),
            ),

            // Action Button
            _buildActionButton(context, theme, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 48,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.visitCompletedSuccessfully ?? 'Tashrif muvaffaqiyatli yakunlandi!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.stepsCompletedCount(widget.completedSteps.length) ?? '${widget.completedSteps.length} ta bosqich bajarildi',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedStepsList(BuildContext context, ThemeData theme, AppLocalizations? l10n) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.completedSteps.length,
      itemBuilder: (context, index) {
        final stepProgress = widget.completedSteps[index];
        final isOrderStep = stepProgress.step.stepName.toLowerCase().contains('заказ') ||
                           stepProgress.step.stepName.toLowerCase().contains('order');

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: isOrderStep ? () => _navigateToOrderDetails(context, stepProgress) : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Step Status Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Step Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stepProgress.step.stepName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (stepProgress.notes?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            stepProgress.notes!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (stepProgress.completedAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n?.completedAtLabel(_formatDateTime(stepProgress.completedAt!)) ?? 'Bajarilgan: ${_formatDateTime(stepProgress.completedAt!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Action Indicator for Order Steps
                  if (isOrderStep) ...[
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, ThemeData theme, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: FilledButton.icon(
        onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        icon: const Icon(Icons.home),
        label: Text(l10n?.returnToHome ?? 'Bosh sahifaga qaytish'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
      ),
    );
  }

  /// Navigate to order details when order step is tapped
  Future<void> _navigateToOrderDetails(BuildContext context, VisitStepProgress stepProgress) async {
    if (_isLoadingOrder) return;

    setState(() => _isLoadingOrder = true);

    try {
      // Try to find the created order from recent orders
      final order = await _findCreatedOrder();

      if (order != null && mounted) {
        // Convert CreateOrder to OrderModel for compatibility with OrderDetailsPage
        final orderModel = await _convertCreateOrderToOrderModel(order);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailsPage(order: orderModel),
          ),
        );
      } else {
        // Show message if order not found
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.orderDetailsNotFound ?? 'Buyurtma tafsilotlari topilmadi'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error navigating to order details: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n?.orderDetailsNavigationErrorPrefix ?? "Error occurred"}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingOrder = false);
      }
    }
  }

  /// Find the created order from recent orders
  /// This method attempts to locate the order that was just created during the visit
  Future<CreateOrder?> _findCreatedOrder() async {
    try {
      final dbService = GetIt.I<ApiDatabaseService>();

      // Get all create orders and find the one matching our client
      final allOrders = await dbService.getCreateOrders('', isSynced: null);
      final clientOrders = allOrders.where(
        (order) => order.codeClient == widget.tradingPoint.tradingPoint.id
      ).toList();

      // Return the most recent order
      if (clientOrders.isNotEmpty) {
        clientOrders.sort((a, b) => b.createDate.compareTo(a.createDate));
        return clientOrders.first;
      }

      return null;
    } catch (e) {
      debugPrint('Error finding created order: $e');
      return null;
    }
  }

  /// Convert CreateOrder to OrderModel for compatibility with OrderDetailsPage
  Future<OrderModel> _convertCreateOrderToOrderModel(CreateOrder createOrder) async {
    final l10n = AppLocalizations.of(context);
    final orderId = createOrder.id?.toString() ?? l10n?.statusNew ?? 'Yangi';
    return OrderModel(
      id: createOrder.id,
      numOrder: '', // Will be filled from server response
      dateOrder: createOrder.createDate,
      captionOrder: l10n?.orderCaption(orderId) ?? 'Buyurtma ${createOrder.id ?? 'Yangi'}',
      typePriceCode: createOrder.codePrice,
      status: 1, // Assume pending status
      commentSupervisor: createOrder.commentSupervisor,
      commentForwarder: createOrder.commentForwarder,
      commentAgent: createOrder.comment,
      total: createOrder.products.fold(0.0, (sum, product) => sum + product.total),
      clientCode: createOrder.codeClient,
      clientName: widget.tradingPoint.tradingPoint.name,
      codeOrg: createOrder.codeOrg,
      mainStatus: l10n?.statusNew ?? 'Yangi', // Default status
      courierName: null,
      courierCar: null,
      courierPlate: null,
      items: createOrder.products.map((product) => OrderItem(
        productName: '', // Would need to be fetched from product data
        article: product.codeProduct,
        quantity: product.amount.toDouble(),
        price: product.price,
        priceType: l10n?.retail ?? 'Retail',
      )).toList(),
    );
  }

  /// Get current user code
  Future<String?> _getUserCode() async {
    try {
      final prefs = GetIt.I<SharedPreferencesService>();
      return await prefs.getUserCode();
    } catch (e) {
      debugPrint('Error getting user code: $e');
      return null;
    }
  }

  /// Format DateTime for display
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.'
           '${dateTime.month.toString().padLeft(2, '0')}.'
           '${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}