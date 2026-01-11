import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/create_order.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_brand.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_series.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_with_price.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/shared/formatters.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/step_pages/create_order_page.dart';
// Local copy of matchesSearch function for transliteration search
bool matchesSearch(String text, String query) {
  if (query.isEmpty) return true;
  final normalizedText = normalizeForSearch(text);
  final normalizedQuery = normalizeForSearch(query);
  final queries = normalizedQuery.split('|');
  return queries.any((q) => normalizedText.contains(q));
}

String normalizeForSearch(String text) {
  final lower = text.toLowerCase();
  final latin = transliterateToLatin(lower);
  final cyrillic = transliterateToCyrillic(lower);
  return '$lower|$latin|$cyrillic';
}

String transliterateToLatin(String text) {
  const cyrillicToLatin = {
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo',
    'ж': 'j', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm',
    'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
    'ф': 'f', 'х': 'x', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'shch',
    'ъ': '\'', 'ы': 'y', 'ь': '\'', 'э': 'e', 'ю': 'yu', 'я': 'ya',
    'А': 'A', 'Б': 'B', 'В': 'V', 'Г': 'G', 'Д': 'D', 'Е': 'E', 'Ё': 'Yo',
    'Ж': 'J', 'З': 'Z', 'И': 'I', 'Й': 'Y', 'К': 'K', 'Л': 'L', 'М': 'M',
    'Н': 'N', 'О': 'O', 'П': 'P', 'Р': 'R', 'С': 'S', 'Т': 'T', 'У': 'U',
    'Ф': 'F', 'Х': 'X', 'Ц': 'Ts', 'Ч': 'Ch', 'Ш': 'Sh', 'Щ': 'Shch',
    'Ъ': '\'', 'Ы': 'Y', 'Ь': '\'', 'Э': 'E', 'Ю': 'Yu', 'Я': 'Ya',
  };
  String result = text;
  cyrillicToLatin.forEach((cyr, lat) {
    result = result.replaceAll(cyr, lat);
  });
  return result;
}

String transliterateToCyrillic(String text) {
  const latinToCyrillic = {
    'a': 'а', 'b': 'б', 'v': 'в', 'g': 'г', 'd': 'д', 'e': 'е', 'yo': 'ё',
    'j': 'ж', 'z': 'з', 'i': 'и', 'y': 'й', 'k': 'к', 'l': 'л', 'm': 'м',
    'n': 'н', 'o': 'о', 'p': 'п', 'r': 'р', 's': 'с', 't': 'т', 'u': 'у',
    'f': 'ф', 'x': 'х', 'ts': 'ц', 'ch': 'ч', 'sh': 'ш', 'shch': 'щ',
    '\'': 'ъ', 'yu': 'ю', 'ya': 'я',
    'A': 'А', 'B': 'Б', 'V': 'В', 'G': 'Г', 'D': 'Д', 'E': 'Е', 'Yo': 'Ё',
    'J': 'Ж', 'Z': 'З', 'I': 'И', 'Y': 'Й', 'K': 'К', 'L': 'Л', 'M': 'М',
    'N': 'Н', 'O': 'О', 'P': 'П', 'R': 'Р', 'S': 'С', 'T': 'Т', 'U': 'У',
    'F': 'Ф', 'X': 'Х', 'Ts': 'Ц', 'Ch': 'Ч', 'Sh': 'Ш', 'Shch': 'Щ',
    'Yu': 'Ю', 'Ya': 'Я',
  };
  String result = text;
  // Sort by length descending to handle multi-char first
  final sortedKeys = latinToCyrillic.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
  for (final lat in sortedKeys) {
    result = result.replaceAll(lat, latinToCyrillic[lat]!);
  }
  return result;
}

/// Product selection page for order creation
///
/// This page allows users to select products and set quantities for order creation.
/// It displays all available products based on selected organization, warehouse, and price type.
/// Products with existing quantities in the order are pre-filled.
/// Products with price <= 0 cannot have their quantities increased.
///
/// Features:
/// - Display all available products with stock and price information
/// - Quantity controls with validation (cannot exceed stock, price check)
/// - Pre-filling of existing order quantities
/// - Bottom action button to confirm selection and return to order page
/// - Comprehensive error handling and logging
/// - Clean code principles with proper separation of concerns
class ProductSelectionPage extends StatefulWidget {
  final String selectedOrganization;
  final String selectedWarehouse;
  final String selectedPriceType;
  final List<ProductWithPrice> availableProducts;
  final List<CreateOrderProduct> selectedProducts;

  const ProductSelectionPage({
    super.key,
    required this.selectedOrganization,
    required this.selectedWarehouse,
    required this.selectedPriceType,
    required this.availableProducts,
    required this.selectedProducts,
  });

  @override
  State<ProductSelectionPage> createState() => _ProductSelectionPageState();
}

class _ProductSelectionPageState extends State<ProductSelectionPage> with TickerProviderStateMixin {
   /// Current product selections with quantities
   /// Key: productCode, Value: CreateOrderProduct
   late Map<String, CreateOrderProduct> _productSelections;

   /// Loading state for UI feedback
   bool _isLoading = false;

   /// Error message for user feedback
   String? _errorMessage;

   /// UI state for summary panel
   bool _isSummaryVisible = false;
   double _dragStartY = 0;
   late AnimationController _summaryAnimationController;
   late Animation<Offset> _summaryAnimation;

   /// UI state for view mode toggle
   bool _isViewModeToggleVisible = false;
   ViewMode _currentViewMode = ViewMode.list;
   late AnimationController _viewModeToggleAnimationController;
   late Animation<double> _viewModeToggleAnimation;

   /// UI state for full screen mode
   bool _isFullScreen = false;

   /// Search and filter state
   final TextEditingController _searchController = TextEditingController();
   late AnimationController _filterAnimationController;
   late Animation<double> _filterAnimation;
   bool _isFilterPanelVisible = false;
   List<String> _selectedBrands = [];
   List<String> _selectedCategories = [];
   List<ProductBrand> _brands = [];
   List<ProductSeries> _categories = [];
   bool _isBrandFilterExpanded = false;
   bool _isCategoryFilterExpanded = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
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

    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    ));

    _initializeProductSelections();
    _loadFilterData();
    debugPrint('ProductSelectionPage: Initialized with ${widget.availableProducts.length} available products and ${widget.selectedProducts.length} selected products');
  }

  @override
  void dispose() {
    _summaryAnimationController.dispose();
    _viewModeToggleAnimationController.dispose();
    _filterAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Initialize product selections map with existing selected products
  /// Pre-fills quantities for products that are already in the order
  void _initializeProductSelections() {
    try {
      _productSelections = {};

      // Add existing selected products with their quantities
      for (final selectedProduct in widget.selectedProducts) {
        _productSelections[selectedProduct.codeProduct] = selectedProduct;
        debugPrint('ProductSelectionPage: Pre-filled product ${selectedProduct.codeProduct} with quantity ${selectedProduct.amount}');
      }

      debugPrint('ProductSelectionPage: Initialized ${_productSelections.length} product selections');
    } catch (e, stackTrace) {
      debugPrint('ProductSelectionPage: Error initializing product selections: $e');
      debugPrint('ProductSelectionPage: Stack trace: $stackTrace');
      _errorMessage = 'Ma\'lumotlarni yuklashda xatolik yuz berdi';
    }
  }

  /// Load filter data (brands and categories) from repository
  Future<void> _loadFilterData() async {
    try {
      final repository = sl<AgentRepository>();
      final brands = await repository.getCachedProductBrands();
      setState(() {
        _brands = brands;
      });
      debugPrint('ProductSelectionPage: Loaded ${brands.length} brands');
    } catch (e, stackTrace) {
      debugPrint('ProductSelectionPage: Error loading filter data: $e');
      debugPrint('ProductSelectionPage: Stack trace: $stackTrace');
      // Don't set error message for filter data, as it's not critical
    }
  }

  /// Toggle filter panel visibility with animation
  void _toggleFilterPanel() {
    setState(() {
      _isFilterPanelVisible = !_isFilterPanelVisible;
      if (_isFilterPanelVisible) {
        _filterAnimationController.forward();
      } else {
        _filterAnimationController.reverse();
      }
    });
  }

  /// Handle brand selection changes
  Future<void> _onBrandsChanged(List<String> brands) async {
    setState(() {
      _selectedBrands = brands;
      // Clear categories when brands change
      _selectedCategories = [];
      // Load categories for selected brands
      _loadCategoriesForBrands(brands);
    });
  }

  /// Handle category selection changes
  Future<void> _onCategoriesChanged(List<String> categories) async {
    setState(() {
      _selectedCategories = categories;
    });
  }

  /// Load categories for selected brands
  Future<void> _loadCategoriesForBrands(List<String> brandNames) async {
    if (brandNames.isEmpty) {
      setState(() {
        _categories = [];
      });
      return;
    }

    try {
      final repository = sl<AgentRepository>();
      final allCategories = <ProductSeries>[];

      for (final brandName in brandNames) {
        final brandCategories = await repository.getCachedProductSeries(brandName: brandName);
        allCategories.addAll(brandCategories);
      }

      setState(() {
        _categories = allCategories;
      });
    } catch (e) {
      // Handle error silently for now
      setState(() {
        _categories = [];
      });
    }
  }

  /// Toggle brand filter expansion
  void _toggleBrandFilter() {
    setState(() {
      _isBrandFilterExpanded = !_isBrandFilterExpanded;
    });
  }

  /// Toggle category filter expansion
  void _toggleCategoryFilter() {
    setState(() {
      _isCategoryFilterExpanded = !_isCategoryFilterExpanded;
    });
  }

  /// Get filtered products based on search and filter criteria
  List<ProductWithPrice> _getFilteredProducts() {
    // Start with available products
    var filtered = widget.availableProducts;

    // Apply brand filtering
    if (_selectedBrands.isNotEmpty) {
      filtered = filtered.where((product) =>
        _selectedBrands.contains(product.productBrand)
      ).toList();
    }

    // Apply category (series) filtering
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered.where((product) =>
        _selectedCategories.contains(product.productSeries)
      ).toList();
    }

    // Apply search filtering
    final searchQuery = _searchController.text.trim();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return matchesSearch(item.productName, searchQuery) ||
               matchesSearch(item.productCode, searchQuery) ||
               matchesSearch(item.vendorCode, searchQuery) ||
               matchesSearch(item.stock.toString(), searchQuery) ||
               matchesSearch(item.price.toString(), searchQuery);
      }).toList();
    }

    return filtered;
  }

  /// Get the current quantity for a product
  /// Returns 0 if product is not selected
  int _getProductQuantity(String productCode) {
    return _productSelections[productCode]?.amount ?? 0;
  }

  /// Get product stock information
  /// Returns 0 if product not found in available products
  int _getProductStock(String productCode) {
    try {
      final product = widget.availableProducts.firstWhere(
        (p) => p.productCode == productCode,
        orElse: () => ProductWithPrice(
          productCode: productCode,
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
          price: 0,
          currency: '',
          validFrom: '',
          validTo: '',
          stock: 0,
        ),
      );
      return product.stock;
    } catch (e) {
      debugPrint('ProductSelectionPage: Error getting product stock for $productCode: $e');
      return 0;
    }
  }

  /// Get product price information
  /// Returns 0.0 if product not found
  double _getProductPrice(String productCode) {
    try {
      final product = widget.availableProducts.firstWhere(
        (p) => p.productCode == productCode,
        orElse: () => ProductWithPrice(
          productCode: productCode,
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
          price: 0,
          currency: '',
          validFrom: '',
          validTo: '',
          stock: 0,
        ),
      );
      return product.price ?? 0.0;
    } catch (e) {
      debugPrint('ProductSelectionPage: Error getting product price for $productCode: $e');
      return 0.0;
    }
  }

  /// Summary calculation getters
  /// Total number of items selected across all products
  int get _totalItems => _productSelections.values.fold(0, (sum, product) => sum + product.amount);

  /// Total value of all selected products
  double get _totalValue => _productSelections.values.fold(0.0, (sum, product) => sum + product.total);

  /// Total weight of all selected products
  double get _totalWeight => _productSelections.values.fold(0.0, (sum, product) => sum + (product.weight * product.amount));

  /// Total volume of all selected products
  double get _totalVolume => _productSelections.values.fold(0.0, (sum, product) => sum + (product.capacity * product.amount));


  /// Update product quantity with validation
  /// Handles adding/removing products from selection
  void _updateProductQuantity(String productCode, int newQuantity) {
    try {
      final stock = _getProductStock(productCode);
      final price = _getProductPrice(productCode);

      // Validate quantity
      if (newQuantity < 0) {
        debugPrint('ProductSelectionPage: Invalid quantity $newQuantity for product $productCode');
        return;
      }

      if (newQuantity > stock) {
        debugPrint('ProductSelectionPage: Quantity $newQuantity exceeds stock $stock for product $productCode');
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.maxQuantityMessage(stock)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      // Check price validation for adding products
      if (newQuantity > 0 && price <= 0) {
        debugPrint('ProductSelectionPage: Cannot add product $productCode with price $price');
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productPriceZeroError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      setState(() {
        if (newQuantity == 0) {
          // Remove product from selection
          _productSelections.remove(productCode);
          debugPrint('ProductSelectionPage: Removed product $productCode from selection');
        } else {
          // Update or add product to selection
          final existingProduct = _productSelections[productCode];
          if (existingProduct != null) {
            // Update existing product
            _productSelections[productCode] = existingProduct.copyWith(
              amount: newQuantity,
              total: newQuantity * price,
            );
            debugPrint('ProductSelectionPage: Updated product $productCode quantity to $newQuantity');
          } else {
            // Add new product
            final product = widget.availableProducts.firstWhere(
              (p) => p.productCode == productCode,
            );

            final orderProduct = CreateOrderProduct(
              codeSklad: widget.selectedWarehouse,
              codeProduct: product.productCode,
              vendorCode: product.vendorCode,
              amount: newQuantity,
              price: price,
              total: newQuantity * price,
              weight: product.weight,
              capacity: product.capacity,
              paymentType: 0,
              discountSum: 0.0,
              discountRate: 0.0,
              giftAmount: 0,
              promo: false,
            );

            _productSelections[productCode] = orderProduct;
            debugPrint('ProductSelectionPage: Added new product $productCode with quantity $newQuantity');
          }
        }
      });
    } catch (e, stackTrace) {
      debugPrint('ProductSelectionPage: Error updating product quantity: $e');
      debugPrint('ProductSelectionPage: Stack trace: $stackTrace');
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.quantityUpdateError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Handle add product action with stock validation
  void _handleAddProduct(String productCode) {
    final currentQuantity = _getProductQuantity(productCode);
    final stock = _getProductStock(productCode);

    if (currentQuantity + 1 <= stock) {
      _updateProductQuantity(productCode, currentQuantity + 1);
    } else {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.maxQuantityMessage(stock)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Formats the total value with millions abbreviation for large amounts
  /// If value >= 100,000, displays as X.X mln UZS, otherwise uses standard UZS format
  /// Handles edge cases like negative values or NaN
  String _formatTotalValue(double value) {
    try {
      // Handle invalid values
      if (value.isNaN || value.isInfinite) {
        return '0 UZS';
      }

      // For values >= 100,000, format as millions
      if (value >= 100000) {
        final millions = value / 1000000;
        // Round to 1 decimal place
        final roundedMillions = (millions * 10).round() / 10;
        return '${roundedMillions.toStringAsFixed(1)} mln UZS';
      } else {
        // Use standard currency formatting for smaller values
        return uzsFormat.format(value);
      }
    } catch (e) {
      debugPrint('ProductSelectionPage: Error formatting total value: $e');
      // Fallback to standard formatting
      return uzsFormat.format(value);
    }
  }

  /// Show quantity input dialog for manual quantity entry
  void _showQuantityInputDialog(String productCode) {
    final stock = _getProductStock(productCode);
    final currentQuantity = _getProductQuantity(productCode);
    final controller = TextEditingController(text: currentQuantity.toString());

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
                hintText: '0 dan $stock gacha',
                border: const OutlineInputBorder(),
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
                    child: Text(AppLocalizations.of(context)?.cancel ?? 'Bekor'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final value = int.tryParse(controller.text);
                      if (value != null && value >= 0 && value <= stock) {
                        _updateProductQuantity(productCode, value);
                        Navigator.pop(context);
                      } else {
                        final l10n = AppLocalizations.of(context)!;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.maxQuantityMessage(stock)),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    },
                    child: Text(AppLocalizations.of(context)?.save ?? 'Saqlash'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Show summary panel
  void _showSummary() {
    if (!_isSummaryVisible) {
      setState(() => _isSummaryVisible = true);
      _summaryAnimationController.forward();
    }
  }

  /// Hide summary panel
  void _hideSummary() {
    if (_isSummaryVisible) {
      setState(() => _isSummaryVisible = false);
      _summaryAnimationController.reverse();
    }
  }

  /// Show view mode toggle
  void _showViewModeToggle() {
    if (!_isViewModeToggleVisible) {
      setState(() => _isViewModeToggleVisible = true);
      _viewModeToggleAnimationController.forward();
    }
  }

  /// Hide view mode toggle
  void _hideViewModeToggle() {
    if (_isViewModeToggleVisible) {
      setState(() => _isViewModeToggleVisible = false);
      _viewModeToggleAnimationController.reverse();
    }
  }

  /// Toggle full screen mode
  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  /// Confirm selection and return to previous page
  void _confirmSelection() {
    try {
      setState(() => _isLoading = true);

      // Get all selected products (quantity > 0)
      final selectedProducts = _productSelections.values.where((p) => p.amount > 0).toList();

      debugPrint('ProductSelectionPage: Confirming selection with ${selectedProducts.length} products');

      // Return the selected products to the calling page
      Navigator.of(context).pop(selectedProducts);
    } catch (e, stackTrace) {
      debugPrint('ProductSelectionPage: Error confirming selection: $e');
      debugPrint('ProductSelectionPage: Stack trace: $stackTrace');

      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.confirmationError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Build bottom summary with drag gestures
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
                      _buildSummaryItem(theme, 'Jami qiymat', _totalValue),
                      _buildSummaryItem(theme, 'Og\'irlik', '${_totalWeight.toStringAsFixed(2)} kg'),
                      _buildSummaryItem(theme, 'Hajm', '${_totalVolume.toStringAsFixed(2)} m³'),
                    ],
                  ),
                ),
              ),
              if (_isSummaryVisible) const SizedBox(height: 16),

              // Confirm button
              FilledButton.icon(
                onPressed: _isLoading ? null : _confirmSelection,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(AppLocalizations.of(context)?.confirm ?? 'Tasdiqlash'),
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

  /// Build summary item with formatted display
  Widget _buildSummaryItem(ThemeData theme, String label, dynamic value) {
    String displayValue;
    String? tooltipMessage;

    if (label == 'Jami qiymat' && value is double) {
      displayValue = _formatTotalValue(value);
      tooltipMessage = uzsFormat.format(value);
    } else {
      displayValue = value.toString();
    }

    final column = Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          displayValue,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );

    if (tooltipMessage != null) {
      return Tooltip(
        message: tooltipMessage,
        preferBelow: false, // Show tooltip above the widget
        child: column,
      );
    } else {
      return column;
    }
  }

  /// Build view mode toggle with animation
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

  /// Get icon for view mode
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

  /// Build content area with view mode toggle and products
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
          child: _buildProductsList(theme),
        ),
      ],
    );
  }

  /// Build products display based on current view mode
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

  /// Build list view for products
  Widget _buildListView(ThemeData theme) {
    final filteredProducts = _getFilteredProducts();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildListProductCard(theme, product);
      },
    );
  }

  /// Build grid view for products
  Widget _buildGridView(ThemeData theme) {
    final filteredProducts = _getFilteredProducts();
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1, // Two columns for balanced layout
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75, // Adjusted for taller image with overlaid text
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildGridProductCard(theme, product);
      },
    );
  }

  /// Build large image view for products
  Widget _buildLargeImageView(ThemeData theme) {
    final filteredProducts = _getFilteredProducts();
    return PageView.builder(
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildLargeImageProductCard(theme, product);
      },
    );
  }

  /// Build detailed product card for list view
  Widget _buildListProductCard(ThemeData theme, ProductWithPrice product) {
    final quantity = _getProductQuantity(product.productCode);
    final stock = product.stock;
    final price = product.price ?? 0.0;
    final canAdd = price > 0 && quantity < stock;

    return Card(
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
                    product.productName,
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
              'Mavjud: $stock dona',
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
                  uzsFormat.format(price),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),

                // Quantity controls
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: quantity > 0 ? () => _updateProductQuantity(product.productCode, quantity - 1) : null,
                ),
                InkWell(
                  onTap: () => _showQuantityInputDialog(product.productCode),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$quantity',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    color: canAdd ? null : theme.disabledColor,
                  ),
                  onPressed: canAdd ? () => _handleAddProduct(product.productCode) : null,
                ),
              ],
            ),

            // Total (only show if quantity > 0)
            if (quantity > 0)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  uzsFormat.format(quantity * price),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build compact product card for grid view
  Widget _buildGridProductCard(ThemeData theme, ProductWithPrice product) {
    final quantity = _getProductQuantity(product.productCode);
    final stock = product.stock;
    final price = product.price ?? 0.0;
    final canAdd = price > 0 && quantity < stock;

    return Card(
      margin: EdgeInsets.zero, // GridView handles spacing
      child: InkWell(
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
                            product.productName,
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
                            'Mavjud: $stock dona',
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
                            uzsFormat.format(price),
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
                    onPressed: quantity > 0 ? () => _updateProductQuantity(product.productCode, quantity - 1) : null,
                  ),
                  InkWell(
                    onTap: () => _showQuantityInputDialog(product.productCode),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$quantity',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add,
                      size: 20,
                      color: canAdd ? null : theme.disabledColor,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: canAdd ? () => _handleAddProduct(product.productCode) : null,
                  ),
                ],
              ),

              // Total
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  uzsFormat.format(quantity * price),
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

  /// Build full-screen detailed product card for large image view
  Widget _buildLargeImageProductCard(ThemeData theme, ProductWithPrice product) {
    final quantity = _getProductQuantity(product.productCode);
    final stock = product.stock;
    final price = product.price ?? 0.0;
    final canAdd = price > 0 && quantity < stock;

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
            product.productName,
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
                  uzsFormat.format(price),
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
                    onPressed: quantity > 0 ? () => _updateProductQuantity(product.productCode, quantity - 1) : null,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => _showQuantityInputDialog(product.productCode),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$quantity',
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
                      color: canAdd ? Colors.white : Colors.grey,
                    ),
                    onPressed: canAdd ? () => _handleAddProduct(product.productCode) : null,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Total
              Text(
                'Jami: ${uzsFormat.format(quantity * price)}',
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
                'Art: ${product.vendorCode} • Mavjud: $stock dona',
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
            ],
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isFullScreen) {
      return WillPopScope(
        onWillPop: () async {
          _toggleFullScreen();
          return false;
        },
        child: Scaffold(
          body: Stack(
            children: [
              _buildLargeImageView(theme),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                  onPressed: _toggleFullScreen,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppLocalizations.of(context)?.back ?? 'Orqaga'),
                  ),
                ],
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.08),
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.06),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _buildSearchField(theme),
                  ),
                  // Filter panel
                  SizeTransition(
                    sizeFactor: _filterAnimation,
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: theme.colorScheme.surfaceContainerHighest,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 50),
                            child: _buildFilterPanel(theme),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Content area with view mode toggle and products
                  Expanded(
                    child: _buildContentArea(theme),
                  ),

                  // Bottom summary with drag gestures
                  _buildBottomSummary(theme),
                ],
              ),
            ),
    );
  }

  /// Build search field widget
  Widget _buildSearchField(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: colorScheme.primary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 6)),
        ],
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() {}),
        decoration: const InputDecoration(
          hintText: 'Qidirish...',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        ),
      ),
    );
  }

  /// Build filter panel widget
  Widget _buildFilterPanel(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand selection header
        InkWell(
          onTap: _toggleBrandFilter,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(
                  'Brandlar',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Icon(
                  _isBrandFilterExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),

        // Brand selection (expandable)
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isBrandFilterExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Builder(
                    builder: (context) {
                      final half = (_brands.length / 2).ceil();
                      final firstHalf = _brands.sublist(0, half < _brands.length ? half : _brands.length);
                      final secondHalf = _brands.length > half ? _brands.sublist(half) : <ProductBrand>[];
                      return Column(
                        children: [
                          if (firstHalf.isNotEmpty)
                            SizedBox(
                              height: 40,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: firstHalf.map((brand) {
                                  final isSelected = _selectedBrands.contains(brand.name);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(brand.name),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        final newSelection = List<String>.from(_selectedBrands);
                                        if (selected) {
                                          newSelection.add(brand.name);
                                        } else {
                                          newSelection.remove(brand.name);
                                        }
                                        _onBrandsChanged(newSelection);
                                      },
                                      backgroundColor: colorScheme.surfaceContainerHighest,
                                      selectedColor: colorScheme.primaryContainer,
                                      checkmarkColor: colorScheme.onPrimaryContainer,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          if (secondHalf.isNotEmpty)
                            SizedBox(
                              height: 40,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: secondHalf.map((brand) {
                                  final isSelected = _selectedBrands.contains(brand.name);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(brand.name),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        final newSelection = List<String>.from(_selectedBrands);
                                        if (selected) {
                                          newSelection.add(brand.name);
                                        } else {
                                          newSelection.remove(brand.name);
                                        }
                                        _onBrandsChanged(newSelection);
                                      },
                                      backgroundColor: colorScheme.surfaceContainerHighest,
                                      selectedColor: colorScheme.primaryContainer,
                                      checkmarkColor: colorScheme.onPrimaryContainer,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 16),

        // Category selection header
        InkWell(
          onTap: _toggleCategoryFilter,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(
                  'Kategoriyalar',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Icon(
                  _isCategoryFilterExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),

        // Category selection (expandable)
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isCategoryFilterExpanded && _categories.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Builder(
                    builder: (context) {
                      final half = (_categories.length / 2).ceil();
                      final firstHalf = _categories.sublist(0, half < _categories.length ? half : _categories.length);
                      final secondHalf = _categories.length > half ? _categories.sublist(half) : <ProductSeries>[];
                      return Column(
                        children: [
                          if (firstHalf.isNotEmpty)
                            SizedBox(
                              height: 40,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: firstHalf.map((category) {
                                  final isSelected = _selectedCategories.contains(category.name);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(category.name),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        final newSelection = List<String>.from(_selectedCategories);
                                        if (selected) {
                                          newSelection.add(category.name);
                                        } else {
                                          newSelection.remove(category.name);
                                        }
                                        _onCategoriesChanged(newSelection);
                                      },
                                      backgroundColor: colorScheme.surfaceContainerHighest,
                                      selectedColor: colorScheme.primaryContainer,
                                      checkmarkColor: colorScheme.onPrimaryContainer,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          if (secondHalf.isNotEmpty)
                            SizedBox(
                              height: 40,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: secondHalf.map((category) {
                                  final isSelected = _selectedCategories.contains(category.name);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(category.name),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        final newSelection = List<String>.from(_selectedCategories);
                                        if (selected) {
                                          newSelection.add(category.name);
                                        } else {
                                          newSelection.remove(category.name);
                                        }
                                        _onCategoriesChanged(newSelection);
                                      },
                                      backgroundColor: colorScheme.surfaceContainerHighest,
                                      selectedColor: colorScheme.primaryContainer,
                                      checkmarkColor: colorScheme.onPrimaryContainer,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                )
              : _isCategoryFilterExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Avval brand tanlang',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Build app bar with drag gestures for view mode toggle and filter button
  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    final hasActiveFilters = _selectedBrands.isNotEmpty || _selectedCategories.isNotEmpty;
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
        child: Text(AppLocalizations.of(context)?.productSelectionTitle ?? 'Mahsulot tanlash'),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
          onPressed: _toggleFullScreen,
          tooltip: _isFullScreen ? 'Chiqish' : 'To\'liq ekran',
        ),
        IconButton(
          icon: Icon(
            Icons.filter_list,
            color: hasActiveFilters ? theme.colorScheme.primary : null,
          ),
          onPressed: _toggleFilterPanel,
          tooltip: 'Filtr',
        ),
      ],
    );
  }
}