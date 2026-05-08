import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';
import '../../../../Utility/formatter.dart';
import '../../data/models/price_type.dart';
import '../../data/models/product_with_price.dart';
import '../../data/models/user_warehouse.dart';
import '../../data/models/product_brand.dart';
import '../../data/models/product_series.dart';
import '../../../../core/widgets/product_image_widget.dart';
import 'product_detail_page.dart';

enum _ViewMode { list, grid }

/// Format number with spaces as thousand separators
String formatNumber(num number) {
  final formatter = NumberFormat('#,###', 'en_US');
  return formatter.format(number).replaceAll(',', ' ');
}

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
  List<String> _selectedBrands = [];
  List<String> _selectedCategories = [];
  List<PriceType> _priceTypes = [];
  List<UserWarehouse> _warehouses = [];
  List<ProductBrand> _brands = [];
  List<ProductSeries> _categories = [];
  List<ProductWithPrice> _productsWithPrices = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showViewBar = false;
  bool _isBrandFilterExpanded = false;
  bool _isCategoryFilterExpanded = false;
  _ViewMode _viewMode = _ViewMode.list;

  @override
  void initState() {
    super.initState();
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
          _errorMessage =
              AppLocalizations.of(context)?.dataLoading ??
              'Ma\'lumotlar yuklanmoqda...';
        });

        try {
          await repository.syncAllData(
            userCode: userCode,
            password: prefs.getPassword() ?? '',
            codeProject: prefs.getCodeProject() ?? '',
            codeSklad: prefs.getWarehouseCode() ?? '',
          );

          // Reload all data after sync
          final syncedPriceTypes = await repository.getPriceTypes(
            userCode: userCode,
          );
          final syncedWarehouses = await repository.getCachedUserWarehouses();
          final syncedProducts = await repository.getProducts(
            codeProject: prefs.getCodeProject() ?? '',
            codeSklad: prefs.getWarehouseCode() ?? '',
          );
          final syncedProductPrices = await repository.getProductPrices(
            userCode: userCode,
          );
          final syncedProductBalances = await repository
              .getCachedProductBalances();

          // Update the variables with synced data
          priceTypes = syncedPriceTypes;
          warehouses = syncedWarehouses;
          products.clear();
          products.addAll(syncedProducts);
          productPrices.clear();
          productPrices.addAll(syncedProductPrices);
          productBalances.clear();
          productBalances.addAll(syncedProductBalances);

          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });
        } catch (e) {
          setState(() {
            _errorMessage = 'Ma\'lumotlar yuklanmadi: ${e.toString()}';
            _isLoading = false;
          });
          return;
        }
      }

      // Load brands and categories
      final brands = await repository.getCachedProductBrands();
      final categories = await repository.getCachedProductSeries();

      setState(() {
        _priceTypes = priceTypes;
        _warehouses = warehouses;
        _brands = brands;
        _categories = categories;
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
          warehouseCodes: _selectedWarehouses.isNotEmpty
              ? _selectedWarehouses
              : null,
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

  Future<void> _onBrandsChanged(List<String> brands) async {
    setState(() {
      _selectedBrands = brands;
      // Clear categories when brands change
      _selectedCategories = [];
      // Load categories for selected brands
      _loadCategoriesForBrands(brands);
    });

    // Reload data if price type is selected
    if (_selectedPriceType != null) {
      await _onPriceTypeChanged(_selectedPriceType);
    }
  }

  Future<void> _onCategoriesChanged(List<String> categories) async {
    setState(() {
      _selectedCategories = categories;
    });

    // Reload data if price type is selected
    if (_selectedPriceType != null) {
      await _onPriceTypeChanged(_selectedPriceType);
    }
  }

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

  void _toggleBrandFilter() {
    setState(() {
      _isBrandFilterExpanded = !_isBrandFilterExpanded;
    });
  }

  void _toggleCategoryFilter() {
    setState(() {
      _isCategoryFilterExpanded = !_isCategoryFilterExpanded;
    });
  }

  List<ProductWithPrice> _getFilteredProducts() {
    // Start with products filtered by price type and warehouses (from database)
    var filtered = _productsWithPrices;

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
            matchesSearch(item.priceTypeName, searchQuery) ||
            matchesSearch(item.price.toString(), searchQuery);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.prices ?? 'Narxlar',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _toggleFilterPanel,
            tooltip: AppLocalizations.of(context)?.filter ?? 'Filtr',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.08),
              colorScheme.primaryContainer.withValues(alpha: 0.06),
            ],
          ),
        ),
        child: Column(
          children: [
            // Search bar (M3 uslub, yumshoq soya)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _SearchField(
                controller: _searchController,
                onChanged: (value) => setState(() {}),
              ),
            ),
            // Filter panel
            SizeTransition(
              sizeFactor: _filterAnimation,
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: colorScheme.surfaceContainerHighest,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 50),
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
                                borderSide: BorderSide(
                                  color: colorScheme.outline,
                                ),
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
                          Builder(
                            builder: (context) {
                              final half = (_warehouses.length / 2).ceil();
                              final firstHalf = _warehouses.sublist(
                                0,
                                min(half, _warehouses.length),
                              );
                              final secondHalf = _warehouses.length > half
                                  ? _warehouses.sublist(half)
                                  : <UserWarehouse>[];
                              return Column(
                                children: [
                                  if (firstHalf.isNotEmpty)
                                    SizedBox(
                                      height: 40,
                                      child: ListView(
                                        scrollDirection: Axis.horizontal,
                                        children: firstHalf.map((warehouse) {
                                          final isSelected = _selectedWarehouses
                                              .contains(warehouse.code);
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            child: FilterChip(
                                              label: Text(warehouse.name),
                                              selected: isSelected,
                                              onSelected: (selected) {
                                                final newSelection =
                                                    List<String>.from(
                                                      _selectedWarehouses,
                                                    );
                                                if (selected) {
                                                  newSelection.add(
                                                    warehouse.code,
                                                  );
                                                } else {
                                                  newSelection.remove(
                                                    warehouse.code,
                                                  );
                                                }
                                                _onWarehousesChanged(
                                                  newSelection,
                                                );
                                              },
                                              backgroundColor: colorScheme
                                                  .surfaceContainerHighest,
                                              selectedColor:
                                                  colorScheme.primaryContainer,
                                              checkmarkColor: colorScheme
                                                  .onPrimaryContainer,
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
                                        children: secondHalf.map((warehouse) {
                                          final isSelected = _selectedWarehouses
                                              .contains(warehouse.code);
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            child: FilterChip(
                                              label: Text(warehouse.name),
                                              selected: isSelected,
                                              onSelected: (selected) {
                                                final newSelection =
                                                    List<String>.from(
                                                      _selectedWarehouses,
                                                    );
                                                if (selected) {
                                                  newSelection.add(
                                                    warehouse.code,
                                                  );
                                                } else {
                                                  newSelection.remove(
                                                    warehouse.code,
                                                  );
                                                }
                                                _onWarehousesChanged(
                                                  newSelection,
                                                );
                                              },
                                              backgroundColor: colorScheme
                                                  .surfaceContainerHighest,
                                              selectedColor:
                                                  colorScheme.primaryContainer,
                                              checkmarkColor: colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 16),

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
                                        final half = (_brands.length / 2)
                                            .ceil();
                                        final firstHalf = _brands.sublist(
                                          0,
                                          min(half, _brands.length),
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
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  children: firstHalf.map((
                                                    brand,
                                                  ) {
                                                    final isSelected =
                                                        _selectedBrands
                                                            .contains(
                                                              brand.name,
                                                            );
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 8,
                                                          ),
                                                      child: FilterChip(
                                                        label: Text(brand.name),
                                                        selected: isSelected,
                                                        onSelected: (selected) {
                                                          final newSelection =
                                                              List<String>.from(
                                                                _selectedBrands,
                                                              );
                                                          if (selected) {
                                                            newSelection.add(
                                                              brand.name,
                                                            );
                                                          } else {
                                                            newSelection.remove(
                                                              brand.name,
                                                            );
                                                          }
                                                          _onBrandsChanged(
                                                            newSelection,
                                                          );
                                                        },
                                                        backgroundColor: colorScheme
                                                            .surfaceContainerHighest,
                                                        selectedColor: colorScheme
                                                            .primaryContainer,
                                                        checkmarkColor: colorScheme
                                                            .onPrimaryContainer,
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            if (secondHalf.isNotEmpty)
                                              SizedBox(
                                                height: 40,
                                                child: ListView(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  children: secondHalf.map((
                                                    brand,
                                                  ) {
                                                    final isSelected =
                                                        _selectedBrands
                                                            .contains(
                                                              brand.name,
                                                            );
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 8,
                                                          ),
                                                      child: FilterChip(
                                                        label: Text(brand.name),
                                                        selected: isSelected,
                                                        onSelected: (selected) {
                                                          final newSelection =
                                                              List<String>.from(
                                                                _selectedBrands,
                                                              );
                                                          if (selected) {
                                                            newSelection.add(
                                                              brand.name,
                                                            );
                                                          } else {
                                                            newSelection.remove(
                                                              brand.name,
                                                            );
                                                          }
                                                          _onBrandsChanged(
                                                            newSelection,
                                                          );
                                                        },
                                                        backgroundColor: colorScheme
                                                            .surfaceContainerHighest,
                                                        selectedColor: colorScheme
                                                            .primaryContainer,
                                                        checkmarkColor: colorScheme
                                                            .onPrimaryContainer,
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
                                    AppLocalizations.of(context)?.categories ??
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
                            child:
                                _isCategoryFilterExpanded &&
                                    _categories.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Builder(
                                      builder: (context) {
                                        final half = (_categories.length / 2)
                                            .ceil();
                                        final firstHalf = _categories.sublist(
                                          0,
                                          min(half, _categories.length),
                                        );
                                        final secondHalf =
                                            _categories.length > half
                                            ? _categories.sublist(half)
                                            : <ProductSeries>[];
                                        return Column(
                                          children: [
                                            if (firstHalf.isNotEmpty)
                                              SizedBox(
                                                height: 40,
                                                child: ListView(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  children: firstHalf.map((
                                                    category,
                                                  ) {
                                                    final isSelected =
                                                        _selectedCategories
                                                            .contains(
                                                              category.name,
                                                            );
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 8,
                                                          ),
                                                      child: FilterChip(
                                                        label: Text(
                                                          category.name,
                                                        ),
                                                        selected: isSelected,
                                                        onSelected: (selected) {
                                                          final newSelection =
                                                              List<String>.from(
                                                                _selectedCategories,
                                                              );
                                                          if (selected) {
                                                            newSelection.add(
                                                              category.name,
                                                            );
                                                          } else {
                                                            newSelection.remove(
                                                              category.name,
                                                            );
                                                          }
                                                          _onCategoriesChanged(
                                                            newSelection,
                                                          );
                                                        },
                                                        backgroundColor: colorScheme
                                                            .surfaceContainerHighest,
                                                        selectedColor: colorScheme
                                                            .primaryContainer,
                                                        checkmarkColor: colorScheme
                                                            .onPrimaryContainer,
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            if (secondHalf.isNotEmpty)
                                              SizedBox(
                                                height: 40,
                                                child: ListView(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  children: secondHalf.map((
                                                    category,
                                                  ) {
                                                    final isSelected =
                                                        _selectedCategories
                                                            .contains(
                                                              category.name,
                                                            );
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 8,
                                                          ),
                                                      child: FilterChip(
                                                        label: Text(
                                                          category.name,
                                                        ),
                                                        selected: isSelected,
                                                        onSelected: (selected) {
                                                          final newSelection =
                                                              List<String>.from(
                                                                _selectedCategories,
                                                              );
                                                          if (selected) {
                                                            newSelection.add(
                                                              category.name,
                                                            );
                                                          } else {
                                                            newSelection.remove(
                                                              category.name,
                                                            );
                                                          }
                                                          _onCategoriesChanged(
                                                            newSelection,
                                                          );
                                                        },
                                                        backgroundColor: colorScheme
                                                            .surfaceContainerHighest,
                                                        selectedColor: colorScheme
                                                            .primaryContainer,
                                                        checkmarkColor: colorScheme
                                                            .onPrimaryContainer,
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
                                      AppLocalizations.of(
                                            context,
                                          )?.selectBrandFirst ??
                                          'Avval brand tanlang',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            fontStyle: FontStyle.italic,
                                          ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // === ADD: yashirin/ko'rinar panel (son + list/grid tugmalar) ===
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _showViewBar
                    ? _ViewToolbar(
                        count: _getFilteredProducts().length,
                        mode: _viewMode,
                        onModeChanged: (m) => setState(() => _viewMode = m),
                        onCollapse: () => setState(() => _showViewBar = false),
                      )
                    : Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          tooltip:
                              AppLocalizations.of(context)?.viewPanel ??
                              'Ko\'rinish paneli',
                          onPressed: () => setState(() => _showViewBar = true),
                          icon: const Icon(
                            Icons.tune,
                          ), // biriktirilgan namunadagi kabi "tune" tugma
                        ),
                      ),
              ),
            ),
            // Content
            Expanded(
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
                            child: Text(
                              AppLocalizations.of(context)?.retry ??
                                  'Qayta urinish',
                            ),
                          ),
                        ],
                      ),
                    )
                  : _selectedPriceType == null
                  ? Center(
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
                            AppLocalizations.of(context)?.selectPriceType ??
                                'Narx turini tanlang',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)?.selectPriceTypeHint ??
                                'Filtr panelidan narx turini tanlash uchun yuqoridagi filtr tugmasini bosing',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: _viewMode == _ViewMode.list
                          ? ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                              cacheExtent: 600,
                              addAutomaticKeepAlives: false,
                              itemCount: _getFilteredProducts().length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final product = _getFilteredProducts()[index];
                                return ProductCard(product: product);
                              },
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                              cacheExtent: 600,
                              addAutomaticKeepAlives: false,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 0.55,
                                  ),
                              itemCount: _getFilteredProducts().length,
                              itemBuilder: (context, index) {
                                final product = _getFilteredProducts()[index];
                                return ProductGridTile(product: product);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// M3 uslubdagi qidiruv
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: cs.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
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
}

/// Ko'rinish paneli (count + list/grid tugmalar + yopish ikon)
class _ViewToolbar extends StatelessWidget {
  final int count;
  final _ViewMode mode;
  final ValueChanged<_ViewMode> onModeChanged;
  final VoidCallback onCollapse;
  const _ViewToolbar({
    required this.count,
    required this.mode,
    required this.onModeChanged,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Color iconColor(bool active) =>
        active ? cs.primary : cs.onSurface.withValues(alpha: 0.45);

    return Row(
      children: [
        // Mahsulotlar soni
        Text(
          AppLocalizations.of(context)?.productsCount(count) ??
              'Mahsulotlar soni: $count',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),

        // List tugma
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onModeChanged(_ViewMode.list),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Icon(
              Icons.view_agenda_rounded, // list
              size: 22,
              color: iconColor(mode == _ViewMode.list),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Grid tugma
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onModeChanged(_ViewMode.grid),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Icon(
              Icons.grid_view_rounded, // grid
              size: 22,
              color: iconColor(mode == _ViewMode.grid),
            ),
          ),
        ),

        const SizedBox(width: 6),
        // Yopish
        IconButton(
          tooltip: AppLocalizations.of(context)?.close ?? 'Yopish',
          onPressed: onCollapse,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  final ProductWithPrice product;
  const ProductCard({super.key, required this.product});

  void _openProductDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(
          product: product,
          heroTag: 'product_list_${product.productCode}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openProductDetail(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image thumbnail
                Hero(
                  tag: 'product_list_${product.productCode}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
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
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Row(
                      //   children: [
                      //     Icon(Icons.tag_outlined, size: 16, color: cs.onSurfaceVariant),
                      //     const SizedBox(width: 6),
                      //     Expanded(
                      //       child: Text(
                      //         'Kod: ${product.productCode}',
                      //         style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      //         maxLines: 1,
                      //         overflow: TextOverflow.ellipsis,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 16,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Artikul: ${product.vendorCode.isNotEmpty ? product.vendorCode : 'Noma\'lum'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.warehouse_outlined,
                            size: 16,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Qoldiq: ${formatNumber(product.stock)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Narx turi: ${product.priceTypeName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${formatNumber(product.price)} ${product.currency}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            if (product.warehouseCode.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Sklad: ${product.warehouseName.isNotEmpty ? product.warehouseName : product.warehouseCode}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onPrimaryContainer,
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
  }
}

class ProductGridTile extends StatelessWidget {
  final ProductWithPrice product;
  const ProductGridTile({super.key, required this.product});

  void _openProductDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(
          product: product,
          heroTag: 'product_grid_${product.productCode}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openProductDetail(context),
        borderRadius: BorderRadius.circular(16),
        splashColor: cs.primary.withValues(alpha: 0.10),
        highlightColor: cs.primary.withValues(alpha: 0.10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TOP: product image
            SizedBox(
              height: 120,
              child: Hero(
                tag: 'product_grid_${product.productCode}',
                child: ProductImageWidget(
                  productCode: product.productCode,
                  size: ProductImageSize.medium,
                  fit: BoxFit.cover,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
            ),
            // BODY: details
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 4,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Text(
                  //   'Kod: ${product.productCode} ',
                  //   maxLines: 1,
                  //   overflow: TextOverflow.ellipsis,
                  //   style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  // ),
                  const SizedBox(height: 2),
                  // Text(
                  //   'Artikul: ${product.vendorCode.isNotEmpty ? product.vendorCode : 'Noma\'lum'}',
                  //   maxLines: 1,
                  //   overflow: TextOverflow.ellipsis,
                  //   style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  // ),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Artikul: ${product.vendorCode.isNotEmpty ? product.vendorCode : 'Noma\'lum'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  Row(
                    children: [
                      Icon(
                        Icons.warehouse_outlined,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Qoldiq: ${formatNumber(product.stock)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  Text(
                    'Narx: ${formatNumber(product.price)} ${product.currency}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
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
}
