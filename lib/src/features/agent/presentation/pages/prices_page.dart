import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';
import '../../../../Utility/formatter.dart';
import '../../data/models/price_type.dart';
import '../../data/models/product_with_price.dart';

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
  List<ProductWithPrice> _productsWithPrices = [];
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
      // Get user code from shared preferences
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();
      final userCode = prefs.getUserCode();

      if (userCode == null || userCode.isEmpty) {
        throw Exception('User code not found. Please login again.');
      }

      final repository = sl<AgentRepository>();

      // Load price types and warehouses
      var priceTypes = await repository.getPriceTypes(userCode: userCode);
      var warehouses = await repository.getCachedUserWarehouses();

      // Check if we need to sync data from API
      bool needsSync = false;

      // Check warehouses
      if (warehouses.isEmpty) {
        needsSync = true;
      }

      // Load products to check if they exist
      var products = await repository.getProducts(
        codeProject: prefs.getCodeProject() ?? '',
        codeSklad: prefs.getWarehouseCode() ?? '',
      );
      if (products.isEmpty) {
        needsSync = true;
      }

      // Load product prices to check if they exist
      var productPrices = await repository.getProductPrices(userCode: userCode);
      if (productPrices.isEmpty) {
        needsSync = true;
      }

      // Load product balances to check if they exist
      var productBalances = await repository.getCachedProductBalances();
      if (productBalances.isEmpty) {
        needsSync = true;
      }

      // If any table is empty, sync all data from API
      if (needsSync) {
        setState(() {
          _isLoading = true;
          _errorMessage = 'Ma\'lumotlar yuklanmoqda...';
        });

        try {
          await repository.syncAllData(
            userCode: userCode,
            password: prefs.getPassword() ?? '',
            codeProject: prefs.getCodeProject() ?? '',
            codeSklad: prefs.getWarehouseCode() ?? '',
          );

          // Reload all data after sync
          final syncedPriceTypes = await repository.getPriceTypes(userCode: userCode);
          final syncedWarehouses = await repository.getCachedUserWarehouses();
          final syncedProducts = await repository.getProducts(
            codeProject: prefs.getCodeProject() ?? '',
            codeSklad: prefs.getWarehouseCode() ?? '',
          );
          final syncedProductPrices = await repository.getProductPrices(userCode: userCode);
          final syncedProductBalances = await repository.getCachedProductBalances();

          // Update the variables with synced data
          priceTypes = syncedPriceTypes;
          warehouses = syncedWarehouses;
          products.clear();
          products.addAll(syncedProducts);
          productPrices.clear();
          productPrices.addAll(syncedProductPrices);
          productBalances.clear();
          productBalances.addAll(syncedProductBalances);
        } catch (e) {
          setState(() {
            _errorMessage = 'Ma\'lumotlar yuklanmadi: ${e.toString()}';
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _priceTypes = priceTypes;
        _warehouses = warehouses.map((w) => w.code).toList();
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

  Future<void> _onPriceTypeChanged(PriceType? priceType) async {
    setState(() {
      _selectedPriceType = priceType;
      _productsWithPrices = []; // Clear previous data
    });

    if (priceType != null) {
      try {
        await sl.isReady<SharedPreferencesService>();
        final prefs = sl<SharedPreferencesService>();
        final codeProject = prefs.getCodeProject();

        final repository = sl<AgentRepository>();
        final productsWithPrices = await repository.getProductsWithPrices(
          priceTypeCode: priceType.code,
          warehouseCodes: _selectedWarehouses.isNotEmpty ? _selectedWarehouses : null,
          codeProject: codeProject,
        );

        setState(() {
          _productsWithPrices = productsWithPrices;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to load products: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _onWarehousesChanged(List<String> warehouses) async {
    setState(() {
      _selectedWarehouses = warehouses;
    });

    // Reload data if price type is selected
    if (_selectedPriceType != null) {
      await _onPriceTypeChanged(_selectedPriceType);
    }
  }

  List<ProductWithPrice> _getFilteredProducts() {
    final searchQuery = _searchController.text.trim();

    if (searchQuery.isEmpty) {
      return _productsWithPrices;
    }

    // Client-side search filtering (database already filtered by price type and warehouses)
    final filtered = _productsWithPrices.where((item) {
      return matchesSearch(item.productName, searchQuery) ||
             matchesSearch(item.productCode, searchQuery) ||
             matchesSearch(item.vendorCode, searchQuery) ||
             matchesSearch(item.priceTypeName, searchQuery) ||
             matchesSearch(item.price.toString(), searchQuery);
    }).toList();

    return filtered;
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
                            hintText: 'Mahsulot nomi, kodi yoki artikulini qidiring...',
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
      final warehouseGroups = <String, List<ProductWithPrice>>{};
      for (final item in filteredProducts) {
        final warehouse = item.warehouseCode;
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
                tabs: warehouseGroups.keys.map((warehouseCode) {
                  // Find warehouse name from the first product in this group
                  final firstProduct = warehouseGroups[warehouseCode]?.first;
                  final warehouseName = firstProduct?.warehouseName.isNotEmpty == true
                      ? firstProduct!.warehouseName
                      : (warehouseCode.isEmpty ? 'Noma\'lum' : warehouseCode);
                  return Tab(text: warehouseName);
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

  Widget _buildProductList(List<ProductWithPrice> products) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (products.isEmpty) {
      return const Center(child: Text('Mahsulotlar yo\'q'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final item = products[index];

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
                              item.productName,
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
                                  'Kod: ${item.productCode}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 6),
                                Text(
                                  'Artikul: ${item.vendorCode.isNotEmpty ? item.vendorCode : 'Noma\'lum'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.warehouse_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 6),
                                Text(
                                  'Qoldiq: ${item.stock}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Narx turi: ${item.priceTypeName}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${item.price.toStringAsFixed(0)} ${item.currency}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (item.warehouseCode.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Sklad: ${item.warehouseName.isNotEmpty ? item.warehouseName : item.warehouseCode}',
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