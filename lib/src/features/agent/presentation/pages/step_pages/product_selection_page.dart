import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/create_order.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_with_price.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/shared/formatters.dart';

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

class _ProductSelectionPageState extends State<ProductSelectionPage> {
  /// Current product selections with quantities
  /// Key: productCode, Value: CreateOrderProduct
  late Map<String, CreateOrderProduct> _productSelections;

  /// Loading state for UI feedback
  bool _isLoading = false;

  /// Error message for user feedback
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeProductSelections();
    debugPrint('ProductSelectionPage: Initialized with ${widget.availableProducts.length} available products and ${widget.selectedProducts.length} selected products');
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maksimal miqdor: $stock dona'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      // Check price validation for adding products
      if (newQuantity > 0 && price <= 0) {
        debugPrint('ProductSelectionPage: Cannot add product $productCode with price $price');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Narxi 0 yoki undan kichik bo\'lgan mahsulot qo\'shib bo\'lmaydi'),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Miqdorni yangilashda xatolik yuz berdi'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maksimal miqdor: $stock dona'),
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
                    child: const Text('Bekor'),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Miqdor 0 dan $stock gacha bo\'lishi kerak'),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    },
                    child: const Text('Saqlash'),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tanlovni tasdiqlashda xatolik yuz berdi'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Build product list item
  Widget _buildProductListItem(ProductWithPrice product) {
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Art: ${product.vendorCode}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Stock display
            Text(
              'Mavjud: $stock dona',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),

            // Price and quantity controls
            Row(
              children: [
                // Price
                Text(
                  uzsFormat.format(price),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
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
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$quantity',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    color: canAdd ? null : Theme.of(context).disabledColor,
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mahsulot tanlash'),
        centerTitle: true,
      ),
      body: _errorMessage != null
          ? Center(
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
                    _errorMessage!,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Orqaga'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Products list
                Expanded(
                  child: widget.availableProducts.isEmpty
                      ? const Center(child: Text('Mahsulotlar mavjud emas'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: widget.availableProducts.length,
                          itemBuilder: (context, index) {
                            final product = widget.availableProducts[index];
                            return _buildProductListItem(product);
                          },
                        ),
                ),

                // Bottom action button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _confirmSelection,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Tasdiqlash'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}