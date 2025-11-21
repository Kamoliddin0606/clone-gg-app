import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/visit_step_data_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/create_order.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_with_price.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/price_type.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_warehouse.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_organization.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/shared/formatters.dart';

/// View modes for product display in the order creation interface
enum ViewMode {
  /// List view - compact vertical list of products
  list,

  /// Grid view - grid layout for products
  grid,

  /// Large image view - focus on product images
  largeImage
}

/// Buyurtma yaratish sahifasi - Create order page
///
/// This page allows agents to create orders by:
/// - Selecting organization, warehouse, and price type from settings
/// - Browsing available products with prices
/// - Adding products to cart with quantity controls
/// - Managing order items with swipe gestures
/// - Completing the order with summary information
///
/// Features:
/// - Animated settings panel with organization/warehouse/price type selection
/// - Multiple view modes (list, grid, large image)
/// - Swipe gestures for product management (clear, image view)
/// - Real-time order summary (items, value, weight, volume)
/// - Integration with existing data sync services
/// - Comprehensive error handling and logging
///
/// Supports read-only mode for completed steps
class CreateOrderPage extends StatefulWidget {
  final TradingPointWithPermissions tradingPoint;
  final String visitId;
  final int stepCode;
  final String stepName;
  final bool readOnly;

  const CreateOrderPage({
    super.key,
    required this.tradingPoint,
    required this.visitId,
    required this.stepCode,
    required this.stepName,
    this.readOnly = false,
  });

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> with TickerProviderStateMixin {
  final VisitStepDataService _dataService = sl<VisitStepDataService>();
  final DataSyncService _syncService = sl<DataSyncService>();
  final ApiDatabaseService _dbService = sl<ApiDatabaseService>();
  final SharedPreferencesService _prefs = sl<SharedPreferencesService>();
  final TextEditingController _notesController = TextEditingController();

  // UI state
  bool _isSettingsPanelVisible = false;
  bool _isSummaryVisible = false;
  bool _isViewModeToggleVisible = false;
  double _dragStartY = 0;
  late AnimationController _settingsAnimationController;
  late Animation<double> _settingsAnimation;
  late AnimationController _summaryAnimationController;
  late Animation<Offset> _summaryAnimation;
  late AnimationController _viewModeToggleAnimationController;
  late Animation<double> _viewModeToggleAnimation;

  // View modes
  ViewMode _currentViewMode = ViewMode.list;

  // Settings data
  List<UserOrganization> _organizations = [];
  List<UserWarehouse> _warehouses = [];
  List<PriceType> _priceTypes = [];

  String? _selectedOrganization;
  String? _selectedWarehouse;
  String? _selectedPriceType;

  // Products data
  List<ProductWithPrice> _availableProducts = [];
  List<CreateOrderProduct> _selectedProducts = [];
  bool _isLoadingProducts = false;

  // Quantity control state
  Set<String> _disabledAddProducts = {};

  // Summary data
  int get _totalItems => _selectedProducts.fold(0, (sum, product) => sum + product.amount);
  double get _totalValue => _selectedProducts.fold(0.0, (sum, product) => sum + product.total);
  double get _totalWeight => _selectedProducts.fold(0.0, (sum, product) => sum + (product.weight * product.amount));
  double get _totalVolume => _selectedProducts.fold(0.0, (sum, product) => sum + (product.capacity * product.amount));

  @override
  void initState() {
    super.initState();
    _settingsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _settingsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _settingsAnimationController, curve: Curves.easeInOut),
    );
    _summaryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _summaryAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _summaryAnimationController,
      curve: Curves.easeInOut,
    ));
    _viewModeToggleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _viewModeToggleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _viewModeToggleAnimationController, curve: Curves.easeInOut),
    );
    _loadInitialData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _settingsAnimationController.dispose();
    _summaryAnimationController.dispose();
    _viewModeToggleAnimationController.dispose();
    super.dispose();
  }

  void _showSummary() {
    if (!_isSummaryVisible) {
      setState(() => _isSummaryVisible = true);
      _summaryAnimationController.forward();
    }
  }

  void _hideSummary() {
    if (_isSummaryVisible) {
      setState(() => _isSummaryVisible = false);
      _summaryAnimationController.reverse();
    }
  }

  void _showViewModeToggle() {
    if (!_isViewModeToggleVisible) {
      setState(() => _isViewModeToggleVisible = true);
      _viewModeToggleAnimationController.forward();
    }
  }

  void _hideViewModeToggle() {
    if (_isViewModeToggleVisible) {
      setState(() => _isViewModeToggleVisible = false);
      _viewModeToggleAnimationController.reverse();
    }
  }

  /// Initial data loading - loads organizations, warehouses, price types and products
  /// This method is called when the widget is first created
  Future<void> _loadInitialData() async {
    try {
      debugPrint('CreateOrderPage: Loading initial data...');

      // Load settings data concurrently for better performance
      await Future.wait([
        _loadOrganizations(),
        _loadWarehouses(),
        _loadPriceTypes(),
      ]);

      // Set default selections based on loaded data
      if (_organizations.isNotEmpty) {
        _selectedOrganization = _organizations.first.code;
        debugPrint('CreateOrderPage: Default organization set to: $_selectedOrganization');
      }
      if (_warehouses.isNotEmpty) {
        _selectedWarehouse = _warehouses.first.code;
        debugPrint('CreateOrderPage: Default warehouse set to: $_selectedWarehouse');
      }
      if (_priceTypes.isNotEmpty) {
        _selectedPriceType = _priceTypes.first.code;
        debugPrint('CreateOrderPage: Default price type set to: $_selectedPriceType');
      }

      // Load products if we have required data
      if (_selectedPriceType != null && _selectedWarehouse != null) {
        await _loadProducts();
      }

      debugPrint('CreateOrderPage: Initial data loading completed successfully');
    } catch (e, stackTrace) {
      debugPrint('CreateOrderPage: Error loading initial data: $e');
      debugPrint('CreateOrderPage: Stack trace: $stackTrace');

      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ma\'lumotlarni yuklashda xatolik yuz berdi: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Load user organizations from cache or database
  /// If data is not in cache, loads from database and caches it
  Future<void> _loadOrganizations() async {
    try {
      debugPrint('CreateOrderPage: Loading organizations...');

      // Get current user code from preferences
      final userCode = _prefs.getUserCode();
      if (userCode == null) {
        debugPrint('CreateOrderPage: No user code found, cannot load organizations');
        _organizations = [];
        if (mounted) setState(() {});
        return;
      }

      // Load organizations using sync service (cache-first approach)
      _organizations = await _syncService.syncUserOrganizations(userCode: userCode);
      debugPrint('CreateOrderPage: Loaded ${_organizations.length} organizations');
      if (mounted) setState(() {});
    } catch (e, stackTrace) {
      debugPrint('CreateOrderPage: Error loading organizations: $e');
      debugPrint('CreateOrderPage: Stack trace: $stackTrace');
      // Continue with empty list - user can still use the app
      _organizations = [];
      if (mounted) setState(() {});
    }
  }

  /// Load user warehouses from cache
  Future<void> _loadWarehouses() async {
    try {
      debugPrint('CreateOrderPage: Loading warehouses...');
      _warehouses = await _syncService.getCachedUserWarehouses();
      debugPrint('CreateOrderPage: Loaded ${_warehouses.length} warehouses');
      if (mounted) setState(() {});
    } catch (e, stackTrace) {
      debugPrint('CreateOrderPage: Error loading warehouses: $e');
      debugPrint('CreateOrderPage: Stack trace: $stackTrace');
      // Continue with empty list - user can still use the app
      _warehouses = [];
      if (mounted) setState(() {});
    }
  }

  /// Load price types from cache
  Future<void> _loadPriceTypes() async {
    try {
      debugPrint('CreateOrderPage: Loading price types...');
      _priceTypes = await _syncService.getCachedPriceTypes();
      debugPrint('CreateOrderPage: Loaded ${_priceTypes.length} price types');
      if (mounted) setState(() {});
    } catch (e, stackTrace) {
      debugPrint('CreateOrderPage: Error loading price types: $e');
      debugPrint('CreateOrderPage: Stack trace: $stackTrace');
      // Continue with empty list - user can still use the app
      _priceTypes = [];
      if (mounted) setState(() {});
    }
  }

  /// Load products with prices based on selected price type and warehouse
  Future<void> _loadProducts() async {
    if (_selectedPriceType == null || _selectedWarehouse == null) {
      debugPrint('CreateOrderPage: Cannot load products - missing price type or warehouse');
      return;
    }

    if (mounted) setState(() => _isLoadingProducts = true);
    try {
      debugPrint('CreateOrderPage: Loading products for price type: $_selectedPriceType, warehouse: $_selectedWarehouse');
      final products = await _syncService.getCachedProductsWithPrices(
        priceTypeCode: _selectedPriceType!,
        warehouseCodes: [_selectedWarehouse!],
      );
      _availableProducts = products;
      debugPrint('CreateOrderPage: Loaded ${_availableProducts.length} products');
    } catch (e, stackTrace) {
      debugPrint('CreateOrderPage: Error loading products: $e');
      debugPrint('CreateOrderPage: Stack trace: $stackTrace');
      _availableProducts = []; // Clear products on error

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mahsulotlarni yuklashda xatolik: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  void _toggleSettingsPanel() {
    setState(() {
      _isSettingsPanelVisible = !_isSettingsPanelVisible;
      if (_isSettingsPanelVisible) {
        _settingsAnimationController.forward();
      } else {
        _settingsAnimationController.reverse();
      }
    });
  }

  /// Handles settings changes - reloads products and updates selected products' prices
  /// When price type changes, all selected products' prices and totals are recalculated
  /// If any product has zero or null price, its quantity is set to zero
  void _onSettingsChanged() async {
    try {
      debugPrint('CreateOrderPage: Settings changed, reloading products...');
      await _loadProducts();
      _updateSelectedProductsPrices();
      debugPrint('CreateOrderPage: Selected products prices updated successfully');
    } catch (e, stackTrace) {
      debugPrint('CreateOrderPage: Error updating settings: $e');
      debugPrint('CreateOrderPage: Stack trace: $stackTrace');

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sozlamalarni yangilashda xatolik: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Updates prices and totals for all selected products based on current available products
  /// If a product's price is zero or null, sets its quantity to zero
  /// This ensures all data is synchronized when price type changes
  void _updateSelectedProductsPrices() {
    try {
      debugPrint('CreateOrderPage: Updating selected products prices...');

      for (int i = 0; i < _selectedProducts.length; i++) {
        final selectedProduct = _selectedProducts[i];
        final availableProduct = _availableProducts.firstWhere(
          (p) => p.productCode == selectedProduct.codeProduct,
          orElse: () => ProductWithPrice(
            productCode: selectedProduct.codeProduct,
            productName: '',
            unit: '',
            quantity: 0,
            reserved: 0,
            available: 0,
            category: '',
            barcode: '',
            have: 0,
            warehouseCode: '',
            warehouseName: '',
            weight: 0,
            capacity: 0,
            vendorCode: '',
            productBrand: '',
            productSeries: '',
            codeProject: '',
            priceTypeCode: '',
            priceTypeName: '',
            price: 0, // Default to 0 if not found
            currency: '',
            validFrom: '',
            validTo: '',
            stock: 0,
          ),
        );

        final newPrice = availableProduct.price ?? 0.0;

        // If price is zero or null, set quantity to zero
        if (newPrice <= 0) {
          debugPrint('CreateOrderPage: Product ${selectedProduct.codeProduct} has zero price, setting quantity to 0');
          _selectedProducts[i] = selectedProduct.copyWith(
            price: newPrice,
            amount: 0,
            total: 0.0,
          );
        } else {
          // Update price and recalculate total
          final newTotal = selectedProduct.amount * newPrice;
          _selectedProducts[i] = selectedProduct.copyWith(
            price: newPrice,
            total: newTotal,
          );
          debugPrint('CreateOrderPage: Updated product ${selectedProduct.codeProduct} price to $newPrice, total: $newTotal');
        }
      }

      // Trigger UI update
      if (mounted) setState(() {});

      debugPrint('CreateOrderPage: Selected products prices updated successfully');
    } catch (e, stackTrace) {
      debugPrint('CreateOrderPage: Error updating selected products prices: $e');
      debugPrint('CreateOrderPage: Stack trace: $stackTrace');

      // Continue with existing data - don't crash the app
    }
  }

  void _addProductToOrder(ProductWithPrice product) {
    final existingIndex = _selectedProducts.indexWhere(
      (p) => p.codeProduct == product.productCode,
    );

    if (existingIndex >= 0) {
      // Update quantity
      final existing = _selectedProducts[existingIndex];
      final newAmount = existing.amount + 1;
      final newTotal = newAmount * existing.price;

      _selectedProducts[existingIndex] = existing.copyWith(
        amount: newAmount,
        total: newTotal,
      );
    } else {
      // Add new product
      final orderProduct = CreateOrderProduct(
        codeSklad: _selectedWarehouse ?? '',
        codeProduct: product.productCode,
        vendorCode: product.vendorCode,
        amount: 1,
        price: product.price,
        total: product.price,
        weight: product.weight,
        capacity: product.capacity,
        paymentType: 0,
        discountSum: 0.0,
        discountRate: 0.0,
        giftAmount: 0,
        promo: false,
      );
      _selectedProducts.add(orderProduct);
    }
    setState(() {});
  }

  void _updateProductQuantity(String codeProduct, int newAmount) {
    final index = _selectedProducts.indexWhere((p) => p.codeProduct == codeProduct);
    if (index >= 0) {
      if (newAmount <= 0) {
        _selectedProducts.removeAt(index);
        // Remove from disabled set if product is removed
        _disabledAddProducts.remove(codeProduct);
      } else {
        final product = _selectedProducts[index];
        _selectedProducts[index] = product.copyWith(
          amount: newAmount,
          total: newAmount * product.price,
        );
      }
      setState(() {});
      // Update disabled states after quantity change
      _updateAddButtonStates();
    }
  }

  /// Handles adding product quantity with stock validation
  /// Only increments if sufficient stock is available, otherwise disables add button and shows message
  void _handleAddProduct(String codeProduct, int currentAmount) {
    final stock = _getProductStock(codeProduct);
    if (currentAmount + 1 <= stock) {
      _updateProductQuantity(codeProduct, currentAmount + 1);
    } else {
      if (!_disabledAddProducts.contains(codeProduct)) {
        setState(() => _disabledAddProducts.add(codeProduct));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maksimal miqdor: $stock dona'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Updates the disabled state of add buttons based on current quantities and stock
  /// Should be called after any quantity change to ensure UI consistency
  void _updateAddButtonStates() {
    final toEnable = <String>{};
    final toDisable = <String>{};

    for (final product in _selectedProducts) {
      final stock = _getProductStock(product.codeProduct);
      final isAtMax = product.amount >= stock;
      final isDisabled = _disabledAddProducts.contains(product.codeProduct);

      if (isAtMax && !isDisabled) {
        toDisable.add(product.codeProduct);
      } else if (!isAtMax && isDisabled) {
        toEnable.add(product.codeProduct);
      }
    }

    if (toEnable.isNotEmpty || toDisable.isNotEmpty) {
      setState(() {
        _disabledAddProducts.addAll(toDisable);
        _disabledAddProducts.removeAll(toEnable);
      });
    }
  }

  void _removeProduct(String codeProduct) {
    _selectedProducts.removeWhere((p) => p.codeProduct == codeProduct);
    setState(() {});
  }

  String _getProductName(String codeProduct) {
    final product = _availableProducts.firstWhere(
      (p) => p.productCode == codeProduct,
      orElse: () => ProductWithPrice(
        productCode: codeProduct,
        productName: codeProduct, // Fallback to code if name not found
        unit: '',
        quantity: 0,
        reserved: 0,
        available: 0,
        category: '',
        barcode: '',
        have: 0,
        warehouseCode: '',
        warehouseName: '',
        weight: 0,
        capacity: 0,
        vendorCode: '',
        productBrand: '',
        productSeries: '',
        codeProject: '',
        priceTypeCode: '',
        priceTypeName: '',
        price: 0,
        currency: '',
        validFrom: '',
        validTo: '',
        stock: 0,
      ),
    );
    return product.productName;
  }

  int _getProductStock(String codeProduct) {
    final product = _availableProducts.firstWhere(
      (p) => p.productCode == codeProduct,
      orElse: () => ProductWithPrice(
        productCode: codeProduct,
        productName: codeProduct,
        unit: '',
        quantity: 0,
        reserved: 0,
        available: 0,
        category: '',
        barcode: '',
        have: 0,
        warehouseCode: '',
        warehouseName: '',
        weight: 0,
        capacity: 0,
        vendorCode: '',
        productBrand: '',
        productSeries: '',
        codeProject: '',
        priceTypeCode: '',
        priceTypeName: '',
        price: 0,
        currency: '',
        validFrom: '',
        validTo: '',
        stock: 0,
      ),
    );
    return product.stock;
  }

  void _showQuantityInputDialog(String codeProduct, int currentAmount) {
    final stock = _getProductStock(codeProduct);
    final controller = TextEditingController(text: currentAmount.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Miqdorni kiriting',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Miqdor',
                hintText: '0 dan ${stock} gacha',
                border: OutlineInputBorder(),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Maksimal mavjud: $stock dona',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Bekor'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final value = int.tryParse(controller.text);
                      if (value != null && value > 0 && value <= stock) {
                        _updateProductQuantity(codeProduct, value);
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Miqdor 1 dan $stock gacha bo\'lishi kerak'),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    },
                    child: Text('Saqlash'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  void _showFullScreenImage(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: Image.asset(imagePath),
        ),
      ),
    );
  }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: _buildAppBar(theme, l10n),
      body: Stack(
        children: [
          Column(
            children: [
              // Settings panel (animated)
              AnimatedBuilder(
                animation: _settingsAnimation,
                builder: (context, child) {
                  return SizeTransition(
                    sizeFactor: _settingsAnimation,
                    axisAlignment: -1.0,
                    child: _buildSettingsPanel(theme),
                  );
                },
              ),

              // Content area
              Expanded(
                child: _buildContentArea(theme),
              ),

              // Bottom summary
              _buildBottomSummary(theme),
            ],
          ),


          // Floating Action Button
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              onPressed: _showProductSelectionDialog,
              child: const Icon(Icons.add),
              tooltip: 'Mahsulot qo\'shish',
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, AppLocalizations? l10n) {
    return AppBar(
      title: GestureDetector(
        onVerticalDragEnd: (details) {
          final velocity = details.velocity.pixelsPerSecond.dy;
          if (velocity < -100) { // dragging up on title
            _hideViewModeToggle();
          } else if (velocity > 100) { // dragging down on title
            _showViewModeToggle();
          }
        },
        child: Text(widget.stepName),
      ),
      centerTitle: true,
      actions: [
        // Clear order data icon
        if (!widget.readOnly)
          IconButton(
            icon: const Icon(Icons.delete),
            color: Colors.red,
            onPressed: _selectedProducts.isEmpty ? null : _showClearConfirmationDialog,
            tooltip: 'Buyurtmani tozalash',
          ),
        // Suggested order icon
        IconButton(
          icon: const Icon(Icons.lightbulb_outline),
          onPressed: () {
            // TODO: Show suggested orders
          },
          tooltip: 'Taklif qilingan buyurtmalar',
        ),

        // Settings icon with visual indicator
        IconButton(
          icon: Icon(
            Icons.settings,
            color: _isSettingsPanelVisible ? theme.colorScheme.primary : null,
          ),
          onPressed: _toggleSettingsPanel,
          tooltip: 'Sozlamalar',
        ),



        if (widget.readOnly) ...[
          const Icon(Icons.visibility, color: Colors.grey),
          const SizedBox(width: 8),
          const Text(
            'Faqat ko\'rish',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(width: 16),
        ],
      ],
    );
  }

  Widget _buildSettingsPanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sozlamalar',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              // Organization dropdown - disabled when products are selected
              DropdownButtonFormField<String>(
                value: _selectedOrganization,
                decoration: InputDecoration(
                  labelText: 'Tashkilot',
                  border: const OutlineInputBorder(),
                  // Visual indication when disabled
                  filled: _selectedProducts.isNotEmpty,
                  fillColor: _selectedProducts.isNotEmpty
                      ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)
                      : null,
                ),
                items: _organizations.map((org) {
                  return DropdownMenuItem(
                    value: org.code,
                    child: Text(org.name),
                  );
                }).toList(),
                onChanged: _selectedProducts.isNotEmpty
                    ? null // Disable when products are selected
                    : (value) {
                        setState(() => _selectedOrganization = value);
                        _onSettingsChanged();
                      },
              ),
              const SizedBox(height: 16),

              // Warehouse dropdown - disabled when products are selected
              DropdownButtonFormField<String>(
                value: _selectedWarehouse,
                decoration: InputDecoration(
                  labelText: 'Ombor',
                  border: const OutlineInputBorder(),
                  // Visual indication when disabled
                  filled: _selectedProducts.isNotEmpty,
                  fillColor: _selectedProducts.isNotEmpty
                      ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)
                      : null,
                ),
                items: _warehouses.map((warehouse) {
                  return DropdownMenuItem(
                    value: warehouse.code,
                    child: Text(warehouse.name),
                  );
                }).toList(),
                onChanged: _selectedProducts.isNotEmpty
                    ? null // Disable when products are selected
                    : (value) {
                        setState(() => _selectedWarehouse = value);
                        _onSettingsChanged();
                      },
              ),
              const SizedBox(height: 16),

              // Price type dropdown
              DropdownButtonFormField<String>(
                value: _selectedPriceType,
                decoration: const InputDecoration(
                  labelText: 'Narx turi',
                  border: OutlineInputBorder(),
                ),
                items: _priceTypes.map((priceType) {
                  return DropdownMenuItem(
                    value: priceType.code,
                    child: Text(priceType.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPriceType = value);
                  _onSettingsChanged();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea(ThemeData theme) {
    return Column(
      children: [
        // View mode toggle with animation
        AnimatedBuilder(
          animation: _viewModeToggleAnimation,
          builder: (context, child) {
            return SizeTransition(
              sizeFactor: _viewModeToggleAnimation,
              axisAlignment: -1.0,
              child: _isViewModeToggleVisible ? _buildViewModeToggle(theme) : const SizedBox.shrink(),
            );
          },
        ),

        // Products list/grid
        Expanded(
          child: _isLoadingProducts
              ? const Center(child: CircularProgressIndicator())
              : _selectedProducts.isEmpty
                  ? _buildEmptyState(theme)
                  : _buildProductsList(theme),
        ),
      ],
    );
  }


  Widget _buildViewModeToggle(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ViewMode.values.map((mode) {
          final isSelected = _currentViewMode == mode;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _currentViewMode = mode),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getViewModeIcon(mode),
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getViewModeIcon(ViewMode mode) {
    switch (mode) {
      case ViewMode.list:
        return Icons.list;
      case ViewMode.grid:
        return Icons.grid_view;
      case ViewMode.largeImage:
        return Icons.image;
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Mahsulotlar tanlanmagan',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mahsulot qo\'shish uchun + tugmasini bosing',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds the products display based on the current view mode
  /// Switches between list, grid, and large image views for optimal user experience
  Widget _buildProductsList(ThemeData theme) {
    switch (_currentViewMode) {
      case ViewMode.list:
        return _buildListView(theme);
      case ViewMode.grid:
        return _buildGridView(theme);
      case ViewMode.largeImage:
        return _buildLargeImageView(theme);
    }
  }

  /// Builds the list view for products - detailed vertical layout
  /// Provides comprehensive product information in a scrollable list
  Widget _buildListView(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _selectedProducts.length,
      itemBuilder: (context, index) {
        final product = _selectedProducts[index];
        return _buildListProductCard(theme, product);
      },
    );
  }

  /// Builds the grid view for products - compact horizontal layout
  /// Optimizes space usage for quick product overview and selection
  Widget _buildGridView(ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1, // Two columns for balanced layout
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75, // Adjusted for taller image with overlaid text
      ),
      itemCount: _selectedProducts.length,
      itemBuilder: (context, index) {
        final product = _selectedProducts[index];
        return _buildGridProductCard(theme, product);
      },
    );
  }

  /// Builds the large image view for products - full-screen detailed layout
  /// Focuses on individual product details with immersive presentation
  Widget _buildLargeImageView(ThemeData theme) {
    return PageView.builder(
      itemCount: _selectedProducts.length,
      itemBuilder: (context, index) {
        final product = _selectedProducts[index];
        return _buildLargeImageProductCard(theme, product);
      },
    );
  }

  /// Builds a detailed product card for list view
  /// Displays comprehensive product information including name, stock, price, and quantity controls
  Widget _buildListProductCard(ThemeData theme, CreateOrderProduct product) {
    return Dismissible(
      key: Key(product.codeProduct),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.image,
          color: theme.colorScheme.primary,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete,
          color: theme.colorScheme.error,
        ),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _removeProduct(product.codeProduct);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${product.codeProduct} o\'chirildi')),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product name and article
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _getProductName(product.codeProduct),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'Art: ${product.vendorCode}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Stock display
              Text(
                'Mavjud: ${_getProductStock(product.codeProduct)} dona',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),

              // Price and quantity controls
              Row(
                children: [
                  // Price
                  Text(
                    uzsFormat.format(product.price),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),

                  // Quantity controls
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () => _updateProductQuantity(product.codeProduct, product.amount - 1),
                  ),
                  InkWell(
                    onTap: () => _showQuantityInputDialog(product.codeProduct, product.amount),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${product.amount}',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add,
                      color: _disabledAddProducts.contains(product.codeProduct)
                          ? theme.disabledColor
                          : null,
                    ),
                    onPressed: _disabledAddProducts.contains(product.codeProduct)
                        ? null
                        : () => _handleAddProduct(product.codeProduct, product.amount),
                  ),
                ],
              ),

              // Total
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  uzsFormat.format(product.total),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a compact product card for grid view
  /// Optimized for space efficiency with essential information and controls
  Widget _buildGridProductCard(ThemeData theme, CreateOrderProduct product) {
    return Card(
      margin: EdgeInsets.zero, // GridView handles spacing
      child: InkWell(
        //onTap: () => _showQuantityInputDialog(product.codeProduct, product.amount),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image with overlaid text - fills remaining space
              Expanded(
                child: Stack(
                  children: [
                    // Background image
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/pruduct/default_product.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    // Overlaid text at bottom
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product name
                          Text(
                            _getProductName(product.codeProduct),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          // Article number
                          Text(
                            'Art: ${product.vendorCode}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontSize: 12,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Mavjud: ${_getProductStock(product.codeProduct)} dona',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontSize: 12,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Price
                          Text(
                            uzsFormat.format(product.price),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Quantity controls - simplified for grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _updateProductQuantity(product.codeProduct, product.amount - 1),
                  ),
                  // Text(
                  //   '${product.amount}',
                  //   style: theme.textTheme.bodyLarge?.copyWith(
                  //     fontWeight: FontWeight.w500,
                  //   ),
                  // ),
                  InkWell(
                    onTap: () => _showQuantityInputDialog(product.codeProduct, product.amount),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${product.amount}',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add,
                      size: 20,
                      color: _disabledAddProducts.contains(product.codeProduct)
                          ? theme.disabledColor
                          : null,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _disabledAddProducts.contains(product.codeProduct)
                        ? null
                        : () => _handleAddProduct(product.codeProduct, product.amount),
                  ),
                ],
              ),

              // Total
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  uzsFormat.format(product.total),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a full-screen detailed product card for large image view
  /// Provides immersive product details with enhanced visual hierarchy
  Widget _buildLargeImageProductCard(ThemeData theme, CreateOrderProduct product) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image covering the entire container
        Image.asset(
          'assets/images/pruduct/default_product.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.image_outlined,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
        ),
        // Gradient overlay for better text readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.6),
              ],
            ),
          ),
        ),
        // Product name at top
        Positioned(
          top: 20,
          left: 24,
          right: 24,
          child: Text(
            _getProductName(product.codeProduct),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 3,
                  color: Colors.black.withOpacity(0.7),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Bottom section with details
        Positioned(
          bottom: 10,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Article and stock info

              const SizedBox(height: 8),
              // Price display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  uzsFormat.format(product.price),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Quantity controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 22, color: Colors.white),
                    onPressed: () => _updateProductQuantity(product.codeProduct, product.amount - 1),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => _showQuantityInputDialog(product.codeProduct, product.amount),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${product.amount}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      Icons.add,
                      size: 22,
                      color: _disabledAddProducts.contains(product.codeProduct)
                          ? Colors.grey
                          : Colors.white,
                    ),
                    onPressed: _disabledAddProducts.contains(product.codeProduct)
                        ? null
                        : () => _handleAddProduct(product.codeProduct, product.amount),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // // Tap hint
              // Text(
              //   'Miqdorni o\'zgartirish uchun raqamga bosing',
              //   style: theme.textTheme.bodyMedium?.copyWith(
              //     color: Colors.white,
              //     shadows: [
              //       Shadow(
              //         offset: Offset(1, 1),
              //         blurRadius: 2,
              //         color: Colors.black.withOpacity(0.7),
              //       ),
              //     ],
              //   ),
              //   textAlign: TextAlign.center,
              // ),
              const SizedBox(height: 8),
              // Total
              Text(
                'Jami: ${uzsFormat.format(product.total)}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Art: ${product.vendorCode} • Mavjud: ${_getProductStock(product.codeProduct)} dona',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              // // Swipe hint
              // Text(
              //   'Chapga/o\'nga suring - keyingi mahsulot',
              //   style: theme.textTheme.bodySmall?.copyWith(
              //     color: Colors.white.withOpacity(0.8),
              //     shadows: [
              //       Shadow(
              //         offset: Offset(1, 1),
              //         blurRadius: 2,
              //         color: Colors.black.withOpacity(0.7),
              //       ),
              //     ],
              //   ),
              //   textAlign: TextAlign.center,
              // ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSummary(ThemeData theme) {
    return GestureDetector(
      onVerticalDragStart: (details) {
        _dragStartY = details.globalPosition.dy;
      },
      onVerticalDragEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond.dy;
        if (velocity < -300) { // dragging up
          _showSummary();
        } else if (velocity > 300) { // dragging down
          _hideSummary();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.dividerColor),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Summary info
              Visibility(
                visible: _isSummaryVisible,
                child: SlideTransition(
                  position: _summaryAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(theme, 'Mahsulotlar', '$_totalItems ta'),
                      _buildSummaryItem(theme, 'Jami qiymat', uzsFormat.format(_totalValue)),
                      _buildSummaryItem(theme, 'Og\'irlik', '${_totalWeight.toStringAsFixed(2)} kg'),
                      _buildSummaryItem(theme, 'Hajm', '${_totalVolume.toStringAsFixed(2)} m³'),
                    ],
                  ),
                ),
              ),
              if (_isSummaryVisible) const SizedBox(height: 16),

              // Complete button
              if (!widget.readOnly)
                FilledButton.icon(
                  onPressed: _selectedProducts.isEmpty ? null : () => _showCompleteDialog(context),
                  icon: const Icon(Icons.check),
                  label: Text(AppLocalizations.of(context)?.completeStep ?? 'Complete Step'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(ThemeData theme, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  void _showProductSelectionDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mahsulot tanlash'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _availableProducts.isEmpty
              ? const Center(child: Text('Mahsulotlar mavjud emas'))
              : ListView.builder(
                  itemCount: _availableProducts.length,
                  itemBuilder: (context, index) {
                    final product = _availableProducts[index];
                    final isSelected = _selectedProducts.any((p) => p.codeProduct == product.productCode);

                    return ListTile(
                      title: Text(product.productName),
                      subtitle: Text(
                        'Art: ${product.vendorCode} • Mavjud: ${product.stock} • ${uzsFormat.format(product.price)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Colors.green)
                          : const Icon(Icons.add),
                      onTap: () {
                        if (!isSelected) {
                          _addProductToOrder(product);
                          // Navigator.of(context).pop();
                        }
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Bekor qilish'),
          ),
        ],
      ),
    );
  }

  /// Clears all selected products and related order data while preserving settings selections
  /// Shows confirmation dialog before clearing
  void _showClearConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buyurtmani tozalash'),
        content: const Text(
          'Tanlangan barcha mahsulotlar va ular bilan bog\'liq ma\'lumotlar o\'chiriladi. '
          'Sozlamalar tanlovlari saqlanib qolinadi. Davom etishni xohlaysizmi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearOrderData();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Tozalash'),
          ),
        ],
      ),
    );
  }

  /// Clears selected products and resets UI state while keeping settings
  void _clearOrderData() {
    try {
      debugPrint('CreateOrderPage: Clearing order data...');

      // Clear selected products and related data
      setState(() {
        _selectedProducts = [];
        _disabledAddProducts = {};
        _notesController.clear();

        // Reset UI states
        _isSettingsPanelVisible = false;
        _isSummaryVisible = false;
        _isViewModeToggleVisible = false;
        _currentViewMode = ViewMode.list;

        // Hide animations if visible
        if (_settingsAnimationController.isCompleted) {
          _settingsAnimationController.reverse();
        }
        if (_summaryAnimationController.isCompleted) {
          _summaryAnimationController.reverse();
        }
        if (_viewModeToggleAnimationController.isCompleted) {
          _viewModeToggleAnimationController.reverse();
        }
      });

      debugPrint('CreateOrderPage: Order data cleared successfully');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Buyurtma ma\'lumotlari tozalandi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('CreateOrderPage: Error clearing order data: $e');
      debugPrint('CreateOrderPage: Stack trace: $stackTrace');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ma\'lumotlarni tozalashda xatolik: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showCompleteDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.stepName} ${l10n?.completed?.toLowerCase() ?? 'completed'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jami mahsulotlar: $_totalItems ta'),
            Text('Jami qiymat: ${uzsFormat.format(_totalValue)}'),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Izohlar',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n?.cancelCompletion ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop({
                'completed': true,
                'notes': _notesController.text.trim(),
                'order': CreateOrder(
                  codeAgent: '', // TODO: Get from user data
                  codeClient: widget.tradingPoint.tradingPoint.id,
                  codePrice: _selectedPriceType ?? '',
                  payment: 'cash', // TODO: Make configurable
                  shippingDate: DateTime.now().add(const Duration(days: 1)),
                  createDate: DateTime.now(),
                  longitude: 0.0, // TODO: Get location
                  latitude: 0.0,
                  weight: _totalWeight,
                  capacity: _totalVolume,
                  credit: false,
                  codeProject: '', // TODO: Get from settings
                  orderType: 0,
                  codeOrg: _selectedOrganization ?? '',
                  codeSklad: _selectedWarehouse ?? '',
                  hasPromo: false,
                  products: _selectedProducts,
                ),
              });
            },
            child: Text(l10n?.confirmCompletion ?? 'Confirm'),
          ),
        ],
      ),
    );
  }
}