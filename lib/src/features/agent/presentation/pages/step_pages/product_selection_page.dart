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
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/product_detail_page.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/agent_organization_context.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/image_target_type.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/new_backend_image_repository.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/unified_image.dart';
import 'package:gloria_marketing_flutter/src/core/widgets/product_image_widget.dart';

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
    'а': 'a',
    'б': 'b',
    'в': 'v',
    'г': 'g',
    'д': 'd',
    'е': 'e',
    'ё': 'yo',
    'ж': 'j',
    'з': 'z',
    'и': 'i',
    'й': 'y',
    'к': 'k',
    'л': 'l',
    'м': 'm',
    'н': 'n',
    'о': 'o',
    'п': 'p',
    'р': 'r',
    'с': 's',
    'т': 't',
    'у': 'u',
    'ф': 'f',
    'х': 'x',
    'ц': 'ts',
    'ч': 'ch',
    'ш': 'sh',
    'щ': 'shch',
    'ъ': '\'',
    'ы': 'y',
    'ь': '\'',
    'э': 'e',
    'ю': 'yu',
    'я': 'ya',
    'А': 'A',
    'Б': 'B',
    'В': 'V',
    'Г': 'G',
    'Д': 'D',
    'Е': 'E',
    'Ё': 'Yo',
    'Ж': 'J',
    'З': 'Z',
    'И': 'I',
    'Й': 'Y',
    'К': 'K',
    'Л': 'L',
    'М': 'M',
    'Н': 'N',
    'О': 'O',
    'П': 'P',
    'Р': 'R',
    'С': 'S',
    'Т': 'T',
    'У': 'U',
    'Ф': 'F',
    'Х': 'X',
    'Ц': 'Ts',
    'Ч': 'Ch',
    'Ш': 'Sh',
    'Щ': 'Shch',
    'Ъ': '\'',
    'Ы': 'Y',
    'Ь': '\'',
    'Э': 'E',
    'Ю': 'Yu',
    'Я': 'Ya',
  };
  String result = text;
  cyrillicToLatin.forEach((cyr, lat) {
    result = result.replaceAll(cyr, lat);
  });
  return result;
}

String transliterateToCyrillic(String text) {
  const latinToCyrillic = {
    'a': 'а',
    'b': 'б',
    'v': 'в',
    'g': 'г',
    'd': 'д',
    'e': 'е',
    'yo': 'ё',
    'j': 'ж',
    'z': 'з',
    'i': 'и',
    'y': 'й',
    'k': 'к',
    'l': 'л',
    'm': 'м',
    'n': 'н',
    'o': 'о',
    'p': 'п',
    'r': 'р',
    's': 'с',
    't': 'т',
    'u': 'у',
    'f': 'ф',
    'x': 'х',
    'ts': 'ц',
    'ch': 'ч',
    'sh': 'ш',
    'shch': 'щ',
    '\'': 'ъ',
    'yu': 'ю',
    'ya': 'я',
    'A': 'А',
    'B': 'Б',
    'V': 'В',
    'G': 'Г',
    'D': 'Д',
    'E': 'Е',
    'Yo': 'Ё',
    'J': 'Ж',
    'Z': 'З',
    'I': 'И',
    'Y': 'Й',
    'K': 'К',
    'L': 'Л',
    'M': 'М',
    'N': 'Н',
    'O': 'О',
    'P': 'П',
    'R': 'Р',
    'S': 'С',
    'T': 'Т',
    'U': 'У',
    'F': 'Ф',
    'X': 'Х',
    'Ts': 'Ц',
    'Ch': 'Ч',
    'Sh': 'Ш',
    'Shch': 'Щ',
    'Yu': 'Ю',
    'Ya': 'Я',
  };
  String result = text;
  // Sort by length descending to handle multi-char first
  final sortedKeys = latinToCyrillic.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
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

class _ProductSelectionPageState extends State<ProductSelectionPage>
    with TickerProviderStateMixin {
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
  int _currentFullScreenIndex = 0;
  late PageController _fullScreenPageController;

  /// Image carousel state for fullscreen view.
  /// Caches loaded images per product to avoid repeated API calls.
  final Map<String, List<UnifiedImage>> _productImagesCache = {};
  
  /// Tracks current image index for each product in carousel
  final Map<String, int> _productImageIndices = {};
  
  /// Tracks loading state per product
  final Set<String> _loadingProductImages = {};

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
    _summaryAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _summaryAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    _viewModeToggleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _viewModeToggleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _viewModeToggleAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _filterAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _fullScreenPageController = PageController();

    _initializeProductSelections();
    _loadFilterData();
    debugPrint(
      'ProductSelectionPage: Initialized with ${widget.availableProducts.length} available products and ${widget.selectedProducts.length} selected products',
    );
  }

  @override
  void dispose() {
    _summaryAnimationController.dispose();
    _viewModeToggleAnimationController.dispose();
    _filterAnimationController.dispose();
    _searchController.dispose();
    _fullScreenPageController.dispose();
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
        debugPrint(
          'ProductSelectionPage: Pre-filled product ${selectedProduct.codeProduct} with quantity ${selectedProduct.amount}',
        );
      }

      debugPrint(
        'ProductSelectionPage: Initialized ${_productSelections.length} product selections',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'ProductSelectionPage: Error initializing product selections: $e',
      );
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

  // ===========================================================================
  // Image Carousel Methods
  // ===========================================================================

  /// Load all images for a product (used in fullscreen carousel)
  /// Uses caching to avoid repeated API calls for same product
  Future<void> _loadProductImages(String productCode) async {
    // Skip if already cached or currently loading
    if (_productImagesCache.containsKey(productCode) ||
        _loadingProductImages.contains(productCode)) {
      return;
    }

    _loadingProductImages.add(productCode);

    try {
      final repo = sl<NewBackendImageRepository>();
      final orgId = sl.isRegistered<AgentOrganizationContext>()
          ? sl<AgentOrganizationContext>().primaryOrganizationId ?? ''
          : '';
      final page = await repo.listForTarget(
        targetType: ImageTargetType.product,
        targetCode1c: productCode,
        targetOrganizationId: orgId,
      );
      debugPrint(
        'ProductSelectionPage: Loaded ${page.images.length} images for $productCode',
      );

      if (mounted) {
        setState(() {
          // Server orders the page; we re-sort only to bring the
          // primary cover to the front.
          _productImagesCache[productCode] = _sortImagesPrimaryFirst(page.images);
          _productImageIndices[productCode] = 0;
          _loadingProductImages.remove(productCode);
        });
      }
    } catch (e) {
      _loadingProductImages.remove(productCode);
      debugPrint('ProductSelectionPage: Error loading images for $productCode: $e');
    }
  }

  /// Stable sort that brings the cover image to the front. The server
  /// already orders rows by `order ASC` then `created_at`; we only
  /// touch the primary placement.
  List<UnifiedImage> _sortImagesPrimaryFirst(List<UnifiedImage> images) {
    if (images.isEmpty) return images;
    final sorted = List<UnifiedImage>.from(images);
    sorted.sort((a, b) {
      if (a.isPrimary && !b.isPrimary) return -1;
      if (!a.isPrimary && b.isPrimary) return 1;
      return a.order.compareTo(b.order);
    });
    return sorted;
  }

  /// Get current image index for a product
  int _getProductImageIndex(String productCode) {
    return _productImageIndices[productCode] ?? 0;
  }

  /// Set current image index for a product
  void _setProductImageIndex(String productCode, int index) {
    setState(() {
      _productImageIndices[productCode] = index;
    });
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
        final brandCategories = await repository.getCachedProductSeries(
          brandName: brandName,
        );
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
      filtered = filtered
          .where((product) => _selectedBrands.contains(product.productBrand))
          .toList();
    }

    // Apply category (series) filtering
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered
          .where(
            (product) => _selectedCategories.contains(product.productSeries),
          )
          .toList();
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
      debugPrint(
        'ProductSelectionPage: Error getting product stock for $productCode: $e',
      );
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
      debugPrint(
        'ProductSelectionPage: Error getting product price for $productCode: $e',
      );
      return 0.0;
    }
  }

  /// Summary calculation getters
  /// Total number of items selected across all products
  int get _totalItems =>
      _productSelections.values.fold(0, (sum, product) => sum + product.amount);

  /// Total value of all selected products
  double get _totalValue => _productSelections.values.fold(
    0.0,
    (sum, product) => sum + product.total,
  );

  /// Total weight of all selected products
  double get _totalWeight => _productSelections.values.fold(
    0.0,
    (sum, product) => sum + (product.weight * product.amount),
  );

  /// Total volume of all selected products
  double get _totalVolume => _productSelections.values.fold(
    0.0,
    (sum, product) => sum + (product.capacity * product.amount),
  );

  /// Update product quantity with validation
  /// Handles adding/removing products from selection
  void _updateProductQuantity(String productCode, int newQuantity) {
    try {
      final stock = _getProductStock(productCode);
      final price = _getProductPrice(productCode);

      // Validate quantity
      if (newQuantity < 0) {
        debugPrint(
          'ProductSelectionPage: Invalid quantity $newQuantity for product $productCode',
        );
        return;
      }

      if (newQuantity > stock) {
        debugPrint(
          'ProductSelectionPage: Quantity $newQuantity exceeds stock $stock for product $productCode',
        );
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
        debugPrint(
          'ProductSelectionPage: Cannot add product $productCode with price $price',
        );
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
          debugPrint(
            'ProductSelectionPage: Removed product $productCode from selection',
          );
        } else {
          // Update or add product to selection
          final existingProduct = _productSelections[productCode];
          if (existingProduct != null) {
            // Update existing product
            _productSelections[productCode] = existingProduct.copyWith(
              amount: newQuantity,
              total: newQuantity * price,
            );
            debugPrint(
              'ProductSelectionPage: Updated product $productCode quantity to $newQuantity',
            );
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
            debugPrint(
              'ProductSelectionPage: Added new product $productCode with quantity $newQuantity',
            );
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
              AppLocalizations.of(context)?.enterQuantity ??
                  'Miqdorni kiriting',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.quantity ?? 'Miqdor',
                hintText:
                    AppLocalizations.of(context)?.quantityHint(stock) ??
                    '0 dan $stock gacha',
                border: const OutlineInputBorder(),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)?.maxAvailable(stock) ??
                  'Maksimal mavjud: $stock dona',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      AppLocalizations.of(context)?.cancel ?? 'Bekor',
                    ),
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
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                        );
                      }
                    },
                    child: Text(
                      AppLocalizations.of(context)?.save ?? 'Saqlash',
                    ),
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
      final selectedProducts = _productSelections.values
          .where((p) => p.amount > 0)
          .toList();

      debugPrint(
        'ProductSelectionPage: Confirming selection with ${selectedProducts.length} products',
      );

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
        if (velocity < -300) {
          // dragging up
          _showSummary();
        } else if (velocity > 300) {
          // dragging down
          _hideSummary();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.dividerColor)),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPrimarySummaryItem(
                        theme,
                        AppLocalizations.of(context)?.totalValueLabel ??
                            'Jami qiymat',
                        _totalValue,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem(
                            theme,
                            AppLocalizations.of(context)?.productsLabel ??
                                'Mahsulotlar',
                            '$_totalItems ta',
                          ),
                          _buildSummaryItem(
                            theme,
                            AppLocalizations.of(context)?.weight ?? 'Og\'irlik',
                            '${_totalWeight.toStringAsFixed(2)} kg',
                          ),
                          _buildSummaryItem(
                            theme,
                            AppLocalizations.of(context)?.volume ?? 'Hajm',
                            '${_totalVolume.toStringAsFixed(2)} m³',
                          ),
                        ],
                      ),
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
                label: Text(
                  AppLocalizations.of(context)?.confirm ?? 'Tasdiqlash',
                ),
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
          value.toString(),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// Build the primary (emphasized) summary item — used for the order total.
  /// Renders the label and value larger and bolder than the secondary metrics
  /// below it, so the order sum stands out at a glance. The value uses the
  /// full grouped UZS format (no millions abbreviation) and is wrapped in a
  /// FittedBox so very large amounts scale down to fit the available width.
  Widget _buildPrimarySummaryItem(ThemeData theme, String label, double value) {
    final formatted = uzsFormat.format(value);
    return Tooltip(
      message: formatted,
      preferBelow: false,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                formatted,
                maxLines: 1,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getViewModeIcon(mode),
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
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
              child: _isViewModeToggleVisible
                  ? _buildViewModeToggle(theme)
                  : const SizedBox.shrink(),
            );
          },
        ),

        // Products list/grid
        Expanded(child: _buildProductsList(theme)),
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
      cacheExtent: 600,
      addAutomaticKeepAlives: false,
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
      cacheExtent: 600,
      addAutomaticKeepAlives: false,
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
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 72,
                child: ProductImageWidget(
                  productCode: product.productCode,
                  size: ProductImageSize.small,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tooltip(
                    message: product.productName,
                    waitDuration: const Duration(milliseconds: 500),
                    triggerMode: TooltipTriggerMode.longPress,
                    child: Text(
                      product.productName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Art: ${product.vendorCode}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Stock display
                  Text(
                    'Mavjud: $stock dona',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Price and quantity controls
                  Row(
                    children: [
                      // Price
                      Text(
                        uzsFormat.format(price),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // Quantity controls
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: quantity > 0
                            ? () => _updateProductQuantity(
                                product.productCode,
                                quantity - 1,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _showQuantityInputDialog(product.productCode),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.dividerColor),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('$quantity', style: theme.textTheme.bodyMedium),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.add,
                          size: 20,
                          color: canAdd ? null : theme.disabledColor,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: canAdd
                            ? () => _handleAddProduct(product.productCode)
                            : null,
                      ),
                    ],
                  ),
                  // Total (only show if quantity > 0)
                  if (quantity > 0)
                    Text(
                      'Jami: ${uzsFormat.format(quantity * price)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
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
              // Double-tap opens fullscreen image viewer
              Expanded(
                child: GestureDetector(
                  onDoubleTap: () => _openProductImageFullScreen(product.productCode),
                  child: Stack(
                    children: [
                      // Background image - uses ProductImageWidget for dynamic loading
                      SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: ProductImageWidget(
                          productCode: product.productCode,
                          size: ProductImageSize.medium,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(8),
                          heroTag: 'product_selection_grid_${product.productCode}',
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
              ),

              // Quantity controls - simplified for grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: quantity > 0
                        ? () => _updateProductQuantity(
                            product.productCode,
                            quantity - 1,
                          )
                        : null,
                  ),
                  InkWell(
                    onTap: () => _showQuantityInputDialog(product.productCode),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
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
                    onPressed: canAdd
                        ? () => _handleAddProduct(product.productCode)
                        : null,
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
  Widget _buildLargeImageProductCard(
    ThemeData theme,
    ProductWithPrice product,
  ) {
    final quantity = _getProductQuantity(product.productCode);
    final stock = product.stock;
    final price = product.price ?? 0.0;
    final canAdd = price > 0 && quantity < stock;

    return GestureDetector(
      onDoubleTap: () => _openProductImageFullScreen(product.productCode),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image - uses ProductImageWidget for dynamic loading
          ProductImageWidget(
            productCode: product.productCode,
            size: ProductImageSize.large,
            fit: BoxFit.cover,
            heroTag: 'product_selection_large_${product.productCode}',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
                    icon: const Icon(
                      Icons.remove,
                      size: 22,
                      color: Colors.white,
                    ),
                    onPressed: quantity > 0
                        ? () => _updateProductQuantity(
                            product.productCode,
                            quantity - 1,
                          )
                        : null,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
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
                    onPressed: canAdd
                        ? () => _handleAddProduct(product.productCode)
                        : null,
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
      ),
    );
  }

  /// Build improved fullscreen view with better UX
  Widget _buildFullScreenView(ThemeData theme) {
    final filteredProducts = _getFilteredProducts();
    final colorScheme = theme.colorScheme;

    if (filteredProducts.isEmpty) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              Text(
                'Mahsulot topilmadi',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              _buildFullScreenExitButton(theme),
            ],
          ),
        ),
      );
    }

    // Get current product images for arrow navigation
    final currentProduct = filteredProducts[_currentFullScreenIndex];
    final currentImages = _productImagesCache[currentProduct.productCode] ?? [];
    final currentImageIndex = _getProductImageIndex(currentProduct.productCode);
    final hasMultipleImages = currentImages.length > 1;

    return Stack(
      children: [
        // Main product PageView - swipe navigates between products
        PageView.builder(
          controller: _fullScreenPageController,
          physics: const ClampingScrollPhysics(),
          itemCount: filteredProducts.length,
          onPageChanged: (index) {
            setState(() {
              _currentFullScreenIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            return _buildFullScreenProductCard(theme, product);
          },
        ),

        // Top gradient overlay for better visibility of controls
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Exit button - top left with semi-transparent background
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          child: _buildFullScreenExitButton(theme),
        ),

        // Product counter indicator - top center
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentFullScreenIndex + 1} / ${filteredProducts.length}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),

        // Top right area - product detail button and cart badge
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          right: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product detail button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final product = filteredProducts[_currentFullScreenIndex];
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProductDetailPage(
                          product: product,
                          heroTag: 'fullscreen_${product.productCode}',
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  splashColor: Colors.white.withValues(alpha: 0.3),
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 22,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
              // Cart badge (if items selected)
              if (_productSelections.isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 16,
                        color: colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_totalItems',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Page indicator dots - bottom
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 0,
          right: 0,
          child: _buildPageIndicator(filteredProducts.length, theme),
        ),

        // Image navigation arrows (only if product has multiple images)
        if (hasMultipleImages) ...[
          // Left arrow - previous image
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: currentImageIndex > 0
                  ? _buildNavigationArrow(
                      icon: Icons.chevron_left,
                      onTap: () {
                        _setProductImageIndex(
                          currentProduct.productCode,
                          currentImageIndex - 1,
                        );
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          // Right arrow - next image
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: currentImageIndex < currentImages.length - 1
                  ? _buildNavigationArrow(
                      icon: Icons.chevron_right,
                      onTap: () {
                        _setProductImageIndex(
                          currentProduct.productCode,
                          currentImageIndex + 1,
                        );
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ],
    );
  }

  /// Build semi-transparent exit button for fullscreen mode
  Widget _buildFullScreenExitButton(ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleFullScreen,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'Chiqish',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build navigation arrow button for fullscreen
  Widget _buildNavigationArrow({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.8),
            size: 28,
          ),
        ),
      ),
    );
  }

  /// Build page indicator dots
  Widget _buildPageIndicator(int count, ThemeData theme) {
    // Limit displayed dots for large collections
    const maxDots = 7;
    final showDots = count <= maxDots;

    if (showDots) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final isActive = index == _currentFullScreenIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      );
    } else {
      // For large lists, show a progress bar style indicator
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: count > 1
                ? _currentFullScreenIndex / (count - 1)
                : 1.0,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 4,
          ),
        ),
      );
    }
  }

  /// Build image carousel for fullscreen view
  /// Navigation via arrows only (swipe reserved for product navigation)
  Widget _buildImageCarousel({
    required List<UnifiedImage> images,
    required String productCode,
    required int currentIndex,
  }) {
    // Show the image at currentIndex directly (no PageView needed since no swipe)
    final image = images[currentIndex];
    final imageUrl =
        image.largeUrl ?? image.mediumUrl ?? image.smallUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Image with loading and error handling
        if (imageUrl != null && imageUrl.isNotEmpty)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Image.network(
              imageUrl,
              key: ValueKey(imageUrl),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => _buildImagePlaceholder(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImagePlaceholder(),
                    Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        else
          _buildImagePlaceholder(),

        // Main image badge
        if (image.isPrimary)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Asosiy',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Build placeholder for missing/loading images
  Widget _buildImagePlaceholder() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 64,
          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  /// Open fullscreen image viewer for a product
  /// Loads images if not cached, then opens zoom-capable viewer
  void _openProductImageFullScreen(String productCode, [int initialIndex = 0]) {
    // Load images first if not cached
    _loadProductImages(productCode);
    
    final images = _productImagesCache[productCode] ?? [];
    
    if (images.isEmpty) {
      // Show snackbar if no images available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rasm yuklanmoqda...'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _ProductImageFullScreenViewer(
            images: images,
            initialIndex: initialIndex,
            productCode: productCode,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// Build carousel indicator dots for image navigation
  Widget _buildImageCarouselIndicator({
    required int count,
    required int currentIndex,
    required ThemeData theme,
  }) {
    // Use dots for small number of images, otherwise show counter
    if (count <= 5) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final isActive = index == currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.primary
                  : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          );
        }),
      );
    } else {
      // Show counter for many images
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '${currentIndex + 1} / $count',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
  }

  /// Build fullscreen product card with improved layout
  /// Supports image carousel when product has multiple images
  Widget _buildFullScreenProductCard(
    ThemeData theme,
    ProductWithPrice product,
  ) {
    final quantity = _getProductQuantity(product.productCode);
    final stock = product.stock;
    final price = product.price ?? 0.0;
    final canAdd = price > 0 && quantity < stock;
    final colorScheme = theme.colorScheme;
    final productCode = product.productCode;

    // Load images for this product if not cached
    _loadProductImages(productCode);

    // Get cached images
    final images = _productImagesCache[productCode] ?? [];
    final currentImageIndex = _getProductImageIndex(productCode);
    final hasMultipleImages = images.length > 1;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Image area - carousel or single image
        if (images.isNotEmpty)
          _buildImageCarousel(
            images: images,
            productCode: productCode,
            currentIndex: currentImageIndex,
          )
        else
          // Fallback to ProductImageWidget while loading
          ProductImageWidget(
            productCode: productCode,
            size: ProductImageSize.large,
            fit: BoxFit.cover,
            heroTag: 'product_fullscreen_$productCode',
          ),

        // Image carousel indicators (only if multiple images)
        if (hasMultipleImages)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 0,
            right: 0,
            child: _buildImageCarouselIndicator(
              count: images.length,
              currentIndex: currentImageIndex,
              theme: theme,
            ),
          ),

        // Gradient overlay for better text readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.3, 0.6, 1.0],
              colors: [
                Colors.black.withValues(alpha: 0.4),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.75),
              ],
            ),
          ),
        ),

        // Product info at bottom
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 50,
          left: 20,
          right: 20,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              // Product name
              Text(
                product.productName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Article and stock info badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Art: ${product.vendorCode} • Mavjud: $stock dona',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Price display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  uzsFormat.format(price),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Quantity controls - modern pill style
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Decrease button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: quantity > 0
                            ? () => _updateProductQuantity(
                                product.productCode,
                                quantity - 1,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: quantity > 0
                                ? colorScheme.errorContainer
                                : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.remove,
                            color: quantity > 0
                                ? colorScheme.onErrorContainer
                                : Colors.grey,
                            size: 24,
                          ),
                        ),
                      ),
                    ),

                    // Quantity display (tappable)
                    GestureDetector(
                      onTap: () => _showQuantityInputDialog(product.productCode),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 80),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Text(
                          '$quantity',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // Increase button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: canAdd
                            ? () => _handleAddProduct(product.productCode)
                            : null,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: canAdd
                                ? colorScheme.primaryContainer
                                : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: canAdd
                                ? colorScheme.onPrimaryContainer
                                : Colors.grey,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Total for this product
              if (quantity > 0)
                Text(
                  'Jami: ${uzsFormat.format(quantity * price)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
            ],
            ),
          ),
        ),

        // Stock warning badge (if low stock)
        if (stock <= 10 && stock > 0)
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Kam qoldi!',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Out of stock overlay
        if (stock == 0)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Mavjud emas',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isFullScreen) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _toggleFullScreen();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: _buildFullScreenView(theme),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: theme.colorScheme.surfaceContainerHighest,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                  Expanded(child: _buildContentArea(theme)),

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
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() {}),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)?.searchHint ?? 'Qidirish...',
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 14,
          ),
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
                      final firstHalf = _brands.sublist(
                        0,
                        half < _brands.length ? half : _brands.length,
                      );
                      final secondHalf = _brands.length > half
                          ? _brands.sublist(half)
                          : <ProductBrand>[];
                      return Column(
                        children: [
                          if (firstHalf.isNotEmpty)
                            SizedBox(
                              height: 40,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: firstHalf.map((brand) {
                                  final isSelected = _selectedBrands.contains(
                                    brand.name,
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(brand.name),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        final newSelection = List<String>.from(
                                          _selectedBrands,
                                        );
                                        if (selected) {
                                          newSelection.add(brand.name);
                                        } else {
                                          newSelection.remove(brand.name);
                                        }
                                        _onBrandsChanged(newSelection);
                                      },
                                      backgroundColor:
                                          colorScheme.surfaceContainerHighest,
                                      selectedColor:
                                          colorScheme.primaryContainer,
                                      checkmarkColor:
                                          colorScheme.onPrimaryContainer,
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
                                  final isSelected = _selectedBrands.contains(
                                    brand.name,
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(brand.name),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        final newSelection = List<String>.from(
                                          _selectedBrands,
                                        );
                                        if (selected) {
                                          newSelection.add(brand.name);
                                        } else {
                                          newSelection.remove(brand.name);
                                        }
                                        _onBrandsChanged(newSelection);
                                      },
                                      backgroundColor:
                                          colorScheme.surfaceContainerHighest,
                                      selectedColor:
                                          colorScheme.primaryContainer,
                                      checkmarkColor:
                                          colorScheme.onPrimaryContainer,
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
                  AppLocalizations.of(context)?.categories ?? 'Kategoriyalar',
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
                      final firstHalf = _categories.sublist(
                        0,
                        half < _categories.length ? half : _categories.length,
                      );
                      final secondHalf = _categories.length > half
                          ? _categories.sublist(half)
                          : <ProductSeries>[];
                      return Column(
                        children: [
                          if (firstHalf.isNotEmpty)
                            SizedBox(
                              height: 40,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: firstHalf.map((category) {
                                  final isSelected = _selectedCategories
                                      .contains(category.name);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(category.name),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        final newSelection = List<String>.from(
                                          _selectedCategories,
                                        );
                                        if (selected) {
                                          newSelection.add(category.name);
                                        } else {
                                          newSelection.remove(category.name);
                                        }
                                        _onCategoriesChanged(newSelection);
                                      },
                                      backgroundColor:
                                          colorScheme.surfaceContainerHighest,
                                      selectedColor:
                                          colorScheme.primaryContainer,
                                      checkmarkColor:
                                          colorScheme.onPrimaryContainer,
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
                                  final isSelected = _selectedCategories
                                      .contains(category.name);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(category.name),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        final newSelection = List<String>.from(
                                          _selectedCategories,
                                        );
                                        if (selected) {
                                          newSelection.add(category.name);
                                        } else {
                                          newSelection.remove(category.name);
                                        }
                                        _onCategoriesChanged(newSelection);
                                      },
                                      backgroundColor:
                                          colorScheme.surfaceContainerHighest,
                                      selectedColor:
                                          colorScheme.primaryContainer,
                                      checkmarkColor:
                                          colorScheme.onPrimaryContainer,
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
                    AppLocalizations.of(context)?.selectBrandFirst ??
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
    final hasActiveFilters =
        _selectedBrands.isNotEmpty || _selectedCategories.isNotEmpty;
    return AppBar(
      title: GestureDetector(
        onVerticalDragEnd: (details) {
          final velocity = details.velocity.pixelsPerSecond.dy;
          if (velocity < -100) {
            // dragging up on title
            _hideViewModeToggle();
          } else if (velocity > 100) {
            // dragging down on title
            _showViewModeToggle();
          }
        },
        child: Text(
          AppLocalizations.of(context)?.productSelectionTitle ??
              'Mahsulot tanlash',
        ),
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
          tooltip: AppLocalizations.of(context)?.filter ?? 'Filtr',
        ),
      ],
    );
  }
}

// =============================================================================
// Full Screen Image Viewer Widget
// =============================================================================

/// Fullscreen image viewer with zoom and swipe capabilities
/// Used for viewing product images in detail from grid views
class _ProductImageFullScreenViewer extends StatefulWidget {
  final List<UnifiedImage> images;
  final int initialIndex;
  final String productCode;

  const _ProductImageFullScreenViewer({
    required this.images,
    required this.initialIndex,
    required this.productCode,
  });

  @override
  State<_ProductImageFullScreenViewer> createState() =>
      _ProductImageFullScreenViewerState();
}

class _ProductImageFullScreenViewerState
    extends State<_ProductImageFullScreenViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image viewer with zoom
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                _resetZoom();
              },
              itemBuilder: (context, index) {
                final image = widget.images[index];
                final imageUrl =
                    image.largeUrl ?? image.mediumUrl ?? image.smallUrl;

                return InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stack) => const Icon(
                              Icons.broken_image_outlined,
                              size: 64,
                              color: Colors.white54,
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              );
                            },
                          )
                        : const Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.white54,
                          ),
                  ),
                );
              },
            ),

            // Top bar with close button
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close button
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.black38),
                    ),
                    // Image counter
                    if (widget.images.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    // Placeholder for symmetry
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            // Bottom indicators
            if (widget.images.length > 1)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.images.length,
                    (index) => GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _currentIndex ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: index == _currentIndex
                              ? Colors.white
                              : Colors.white38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Zoom hint
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pinch_outlined, size: 16, color: Colors.white70),
                      SizedBox(width: 6),
                      Text(
                        'Kattalashtirish uchun qisib torting',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
