import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import '../../../../Utility/formatter.dart';
import '../../data/models/price_type.dart';
import '../../data/models/product_data.dart';
import '../../data/models/product_price.dart';

class PricesPage extends StatefulWidget {
  const PricesPage({super.key});

  @override
  State<PricesPage> createState() => _PricesPageState();
}

class _PricesPageState extends State<PricesPage> with TickerProviderStateMixin {
  // Controllers and state variables
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  bool _isFilterPanelVisible = false;
  PriceType? _selectedPriceType;
  List<String> _selectedWarehouses = [];
  List<PriceType> _priceTypes = [];
  List<String> _warehouses = [];
  List<ProductPrice> _productPrices = [];
  List<ProductData> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dbService = ApiDatabaseService();
      final priceTypes = await dbService.getPriceTypes();
      final products = await dbService.getProducts();
      final productPrices = await dbService.getProductPrices();

      // Extract unique warehouse codes
      final warehouses = products
          .map((p) => p.warehouseCode)
          .where((w) => w.isNotEmpty)
          .toSet()
          .toList();

      setState(() {
        _priceTypes = priceTypes;
        _products = products;
        _productPrices = productPrices;
        _warehouses = warehouses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

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

  void _onPriceTypeChanged(PriceType? priceType) {
    setState(() {
      _selectedPriceType = priceType;
      _updateFilteredData();
    });
  }

  void _onWarehousesChanged(List<String> warehouses) {
    setState(() {
      _selectedWarehouses = warehouses;
      _updateFilteredData();
    });
  }

  void _updateFilteredData() {
    // This will trigger a rebuild and the list will be filtered in build method
  }

  List<Map<String, dynamic>> _getFilteredProducts() {
    if (_selectedPriceType == null) {
      return [];
    }

    final filteredPrices = _productPrices
        .where((price) => price.priceTypeCode == _selectedPriceType!.code)
        .toList();

    final productsWithPrices = <Map<String, dynamic>>[];

    for (final price in filteredPrices) {
      final product = _products.firstWhere(
        (p) => p.code == price.productCode,
        orElse: () => ProductData(
          code: price.productCode,
          name: 'Unknown Product',
          unit: '',
          quantity: 0,
          reserved: 0,
          available: 0,
          category: '',
          barcode: '',
          have: 0,
          warehouseCode: '',
          weight: 0,
          capacity: 0,
          vendorCode: '',
          productBrand: '',
          productSeries: '',
          codeProject: '',
        ),
      );

      if (_selectedWarehouses.isNotEmpty &&
          !_selectedWarehouses.contains(product.warehouseCode)) {
        continue;
      }

      productsWithPrices.add({
        'product': product,
        'price': price,
      });
    }

    return productsWithPrices;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Narxlar'),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _toggleFilterPanel,
            tooltip: 'Filtr',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Qayta urinish'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Mahsulot nomini qidiring...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colorScheme.outline),
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                      ),

                      // Filter panel
                      SizeTransition(
                        sizeFactor: _filterAnimation,
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: colorScheme.surfaceContainerHighest,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Price type selection
                                DropdownButtonFormField<PriceType>(
                                  initialValue: _selectedPriceType,
                                  decoration: InputDecoration(
                                    labelText: 'Narx turi',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: colorScheme.outline),
                                    ),
                                    filled: true,
                                    fillColor: colorScheme.surface,
                                  ),
                                  items: _priceTypes.map((type) {
                                    return DropdownMenuItem(
                                      value: type,
                                      child: Text(type.name),
                                    );
                                  }).toList(),
                                  onChanged: _onPriceTypeChanged,
                                ),
                                const SizedBox(height: 16),

                                // Warehouse selection
                                Text(
                                  'Skladlar',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _warehouses.map((warehouse) {
                                    final isSelected = _selectedWarehouses.contains(warehouse);
                                    return FilterChip(
                                      label: Text(warehouse),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        final newSelection = List<String>.from(_selectedWarehouses);
                                        if (selected) {
                                          newSelection.add(warehouse);
                                        } else {
                                          newSelection.remove(warehouse);
                                        }
                                        _onWarehousesChanged(newSelection);
                                      },
                                      backgroundColor: colorScheme.surfaceContainerHighest,
                                      selectedColor: colorScheme.primaryContainer,
                                      checkmarkColor: colorScheme.onPrimaryContainer,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Content
                      Expanded(
                        child: _buildContent(),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filteredProducts = _getFilteredProducts();

    if (_selectedPriceType == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.price_change,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Narx turini tanlang',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Filtr panelidan narx turini tanlash uchun yuqoridagi filtr tugmasini bosing',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Mahsulotlar topilmadi',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tanlangan filtrlar bo\'yicha mahsulotlar mavjud emas',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedWarehouses.isEmpty) {
      // Show tabs for each warehouse
      final warehouseGroups = <String, List<Map<String, dynamic>>>{};
      for (final item in filteredProducts) {
        final warehouse = item['product'].warehouseCode;
        warehouseGroups.putIfAbsent(warehouse, () => []).add(item);
      }

      return DefaultTabController(
        length: warehouseGroups.length,
        child: Column(
          children: [
            Container(
              color: colorScheme.surface,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: colorScheme.primary,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                tabs: warehouseGroups.keys.map((warehouse) {
                  return Tab(text: warehouse.isEmpty ? 'Noma\'lum' : warehouse);
                }).toList(),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: warehouseGroups.values.map((products) {
                  return _buildProductList(products);
                }).toList(),
              ),
            ),
          ],
        ),
      );
    } else {
      // Show single list
      return _buildProductList(filteredProducts);
    }
  }

  Widget _buildProductList(List<Map<String, dynamic>> products) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final searchQuery = _searchController.text.trim();
    final filteredProducts = products.where((item) {
      final product = item['product'] as ProductData;
      final price = item['price'] as ProductPrice;
      final priceType = _selectedPriceType;

      // Search in product name, code, price type name, and price
      return matchesSearch(product.name, searchQuery) ||
             matchesSearch(product.code, searchQuery) ||
             (priceType != null && matchesSearch(priceType.name, searchQuery)) ||
             matchesSearch(price.price.toString(), searchQuery);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final item = filteredProducts[index];
        final product = item['product'] as ProductData;
        final price = item['price'] as ProductPrice;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: colorScheme.surface,
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {}, // Add tap functionality if needed
            borderRadius: BorderRadius.circular(16),
            splashColor: colorScheme.primary.withValues(alpha: 0.1),
            highlightColor: colorScheme.primary.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.tag_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 6),
                                Text(
                                  'Kod: ${product.code}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Narx turi: ${_selectedPriceType?.name ?? ''}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${price.price.toStringAsFixed(0)} ${price.currency}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (product.warehouseCode.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Sklad: ${product.warehouseCode}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
}