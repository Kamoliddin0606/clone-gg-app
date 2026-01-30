import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/features/marketing/data/models/promotion_model.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_image.dart';

/// Transliterate Cyrillic characters to Latin (Uzbek standard)
String transliterateToLatin(String text) {
  const cyrillicToLatin = {
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo',
    'ж': 'j', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm',
    'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
    'ф': 'f', 'х': 'x', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'shch',
    'ъ': "'", 'ы': 'y', 'ь': "'", 'э': 'e', 'ю': 'yu', 'я': 'ya',
    'А': 'A', 'Б': 'B', 'В': 'V', 'Г': 'G', 'Д': 'D', 'Е': 'E', 'Ё': 'Yo',
    'Ж': 'J', 'З': 'Z', 'И': 'I', 'Й': 'Y', 'К': 'K', 'Л': 'L', 'М': 'M',
    'Н': 'N', 'О': 'O', 'П': 'P', 'Р': 'R', 'С': 'S', 'Т': 'T', 'У': 'U',
    'Ф': 'F', 'Х': 'X', 'Ц': 'Ts', 'Ч': 'Ch', 'Ш': 'Sh', 'Щ': 'Shch',
    'Ъ': "'", 'Ы': 'Y', 'Ь': "'", 'Э': 'E', 'Ю': 'Yu', 'Я': 'Ya',
  };

  return text.split('').map((char) => cyrillicToLatin[char] ?? char).join('');
}

class PromotionDetailPage extends StatefulWidget {
  final PromotionModel promotion;

  const PromotionDetailPage({
    super.key,
    required this.promotion,
  });

  @override
  State<PromotionDetailPage> createState() => _PromotionDetailPageState();
}

class _PromotionDetailPageState extends State<PromotionDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  /// Show product details dialog fetching data from products table
  Future<void> _showProductDetails(String productCode) async {
    final dbService = sl<ApiDatabaseService>();
    
    // Fetch product data and image in parallel
    final results = await Future.wait([
      dbService.getProductByCode(productCode),
      dbService.getMainProductImage(productCode),
    ]);
    
    final product = results[0] as ProductData?;
    final productImage = results[1] as ProductImage?;

    if (!mounted) return;

    if (product == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.productNotFoundMessage(productCode)),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _showProductDetailsDialog(product, productImage: productImage);
  }

  /// Display product details in a bottom sheet dialog
  void _showProductDetailsDialog(ProductData product, {ProductImage? productImage}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imageUrl = productImage?.thumbnailOrBestUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header with product image
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Show product image if available, otherwise show code avatar
                    imageUrl != null && imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 56,
                                  height: 56,
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => CircleAvatar(
                                radius: 28,
                                backgroundColor: colorScheme.primaryContainer,
                                child: Text(
                                  product.code.length >= 2 ? product.code.substring(0, 2) : product.code,
                                  style: TextStyle(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : CircleAvatar(
                            radius: 28,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              product.code.length >= 2 ? product.code.substring(0, 2) : product.code,
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)?.codeLabel(product.code) ?? 'Kod: ${product.code}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Product details
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildDetailRow(AppLocalizations.of(context)?.unitOfMeasure ?? 'O\'lchov birligi', product.unit, Icons.straighten),
                    _buildDetailRow(AppLocalizations.of(context)?.category ?? 'Kategoriya', product.category, Icons.category),
                    _buildDetailRow(AppLocalizations.of(context)?.brand ?? 'Brend', product.productBrand, Icons.branding_watermark),
                    _buildDetailRow(AppLocalizations.of(context)?.series ?? 'Seriya', product.productSeries, Icons.layers),
                    _buildDetailRow(AppLocalizations.of(context)?.barcode ?? 'Shtrix kod', product.barcode, Icons.qr_code),
                    _buildDetailRow(AppLocalizations.of(context)?.vendorCode ?? 'Vendor kod', product.vendorCode, Icons.tag),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)?.warehouseInformation ?? 'Ombor ma\'lumotlari',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(AppLocalizations.of(context)?.quantity ?? 'Miqdori', '${product.quantity}', Icons.inventory_2),
                    _buildDetailRow(AppLocalizations.of(context)?.available ?? 'Mavjud', '${product.available}', Icons.check_circle_outline),
                    _buildDetailRow(AppLocalizations.of(context)?.reserved ?? 'Band qilingan', '${product.reserved}', Icons.lock_outline),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)?.physicalProperties ?? 'Fizik xususiyatlar',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(AppLocalizations.of(context)?.weight ?? 'Og\'irligi', '${product.weight} kg', Icons.scale),
                    _buildDetailRow(AppLocalizations.of(context)?.volume ?? 'Hajmi', '${product.capacity} L', Icons.water_drop),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a single detail row for product info
  Widget _buildDetailRow(String label, String value, IconData icon) {
    if (value.isEmpty || value == '0.0' || value == '0') {
      return const SizedBox.shrink();
    }
    
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero banner
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.promotion.name,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primaryContainer,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.local_offer,
                    size: 80,
                    color: colorScheme.onPrimary.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),

          // Promotion details card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Code and Type
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.promotion.code,
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: widget.promotion.isActive
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.promotion.type,
                              style: TextStyle(
                                color: widget.promotion.isActive
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.aboutPromotion,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.promotionOfType(widget.promotion.type),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.inventory,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.participatingProductsCount(widget.promotion.productList.length),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.card_giftcard,
                                  size: 18,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.bonusProductsCount(widget.promotion.bonusList.length),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Promotion requirements
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)?.promotionConditions ?? 'Aksiya shartlari',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.shopping_cart,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)?.minimalProductCount(widget.promotion.minPromoProductCount) ?? 'Minimal mahsulot soni: ${widget.promotion.minPromoProductCount}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.card_giftcard,
                                  size: 20,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)?.bonusCount(widget.promotion.bonusCount) ?? 'Bonus soni: ${widget.promotion.bonusCount}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dates
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.startDateLabel(_formatDate(widget.promotion.dateStart)),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.endDateLabel(_formatDate(widget.promotion.dateEnd)),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: widget.promotion.isActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.promotion.isActive
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 20,
                              color: widget.promotion.isActive
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.promotion.isActive ? l10n.active : l10n.inactive,
                              style: TextStyle(
                                color: widget.promotion.isActive
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w500,
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
          ),

          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.inventory),
                        text: l10n.products,
                      ),
                      Tab(
                        icon: const Icon(Icons.card_giftcard),
                        text: l10n.bonuses,
                      ),
                      Tab(
                        icon: const Icon(Icons.category),
                        text: l10n.productClass,
                      ),
                    ],
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    indicatorColor: colorScheme.primary,
                  ),

                ],
              ),
              // isSearchVisible: _isSearchVisible,
            ),
          ),

          // Tab content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductList(),
                _buildBonusList(),
                _buildClassList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    final query = _searchController.text.toLowerCase();
    final productsToShow = query.isEmpty
        ? widget.promotion.productList
        : widget.promotion.productList.where((product) {
            final nameLatin = transliterateToLatin(product.productName).toLowerCase();
            final codeLatin = transliterateToLatin(product.code).toLowerCase();
            final queryLatin = transliterateToLatin(query);
            return nameLatin.contains(queryLatin) || codeLatin.contains(queryLatin);
          }).toList();

    if (productsToShow.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return _buildEmptyState(query.isEmpty ? (l10n.productsNotFound) : (l10n.searchResultsNotFound));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 64, left: 16, right: 16, bottom: 16),
      itemCount: productsToShow.length,
      itemBuilder: (context, index) {
        final product = productsToShow[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: () => _showProductDetails(product.code),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                product.code.length >= 2 ? product.code.substring(0, 2) : product.code,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(product.productName),
            subtitle: Text(AppLocalizations.of(context)?.codeLabel(product.code) ?? 'Kod: ${product.code}'),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBonusList() {
    final query = _searchController.text.toLowerCase();
    final bonusesToShow = query.isEmpty
        ? widget.promotion.bonusList
        : widget.promotion.bonusList.where((bonus) {
            final nameLatin = transliterateToLatin(bonus.productName).toLowerCase();
            final codeLatin = transliterateToLatin(bonus.code).toLowerCase();
            final queryLatin = transliterateToLatin(query);
            return nameLatin.contains(queryLatin) || codeLatin.contains(queryLatin);
          }).toList();

    if (bonusesToShow.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return _buildEmptyState(query.isEmpty ? (l10n.bonusesNotFound) : (l10n.searchResultsNotFound));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 64, left: 16, right: 16, bottom: 16),
      itemCount: bonusesToShow.length,
      itemBuilder: (context, index) {
        final bonus = bonusesToShow[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: () => _showProductDetails(bonus.code),
            leading: CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.1),
              child: const Icon(
                Icons.card_giftcard,
                color: Colors.green,
              ),
            ),
            title: Text(bonus.productName),
            subtitle: Text(AppLocalizations.of(context)?.codeLabel(bonus.code) ?? 'Kod: ${bonus.code}'),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }

  Widget _buildClassList() {
    final query = _searchController.text.toLowerCase();
    final classesToShow = query.isEmpty
        ? widget.promotion.classList
        : widget.promotion.classList.where((classItem) {
            final nameLatin = transliterateToLatin(classItem.productName).toLowerCase();
            final codeLatin = transliterateToLatin(classItem.code).toLowerCase();
            final queryLatin = transliterateToLatin(query);
            return nameLatin.contains(queryLatin) || codeLatin.contains(queryLatin);
          }).toList();

    if (classesToShow.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return _buildEmptyState(query.isEmpty ? (l10n.classInformationNotFound) : (l10n.searchResultsNotFound));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 64, left: 16, right: 16, bottom: 16),
      itemCount: classesToShow.length,
      itemBuilder: (context, index) {
        final classItem = classesToShow[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: const Icon(
                Icons.category,
                color: Colors.blue,
              ),
            ),
            title: Text(classItem.productName),
            subtitle: Text(AppLocalizations.of(context)?.codeLabel(classItem.code) ?? 'Kod: ${classItem.code}'),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // Widget _buildCollapsedSearchBar(ColorScheme colorScheme) {
  //   return Container(
  //     key: const ValueKey('collapsed'),
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     decoration: BoxDecoration(
  //       color: colorScheme.surfaceContainerHighest.withOpacity(0.1),
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(
  //         color: colorScheme.outline.withOpacity(0.2),
  //         width: 1,
  //       ),
  //     ),
  //     child: Row(
  //       children: [
  //         Icon(
  //           Icons.search,
  //           color: colorScheme.onSurfaceVariant,
  //           size: 20,
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: Text(
  //             'Mahsulotlarni qidirish',
  //             style: TextStyle(
  //               color: colorScheme.onSurfaceVariant,
  //               fontSize: 16,
  //               fontWeight: FontWeight.w500,
  //             ),
  //           ),
  //         ),
  //         Icon(
  //           Icons.keyboard_arrow_down,
  //           color: colorScheme.onSurfaceVariant,
  //           size: 20,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildExpandedSearchBar(ColorScheme colorScheme) {
  //   return Container(
  //     key: const ValueKey('expanded'),
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: colorScheme.surface,
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(
  //         color: colorScheme.outline.withOpacity(0.3),
  //         width: 1,
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: colorScheme.shadow.withOpacity(0.1),
  //           blurRadius: 8,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(
  //               Icons.search,
  //               color: colorScheme.primary,
  //               size: 20,
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: Text(
  //                 'Qidiruv',
  //                 style: TextStyle(
  //                   color: colorScheme.primary,
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //             ),
  //             IconButton(
  //               onPressed: () {
  //                 setState(() {
  //                   _isSearchVisible = false;
  //                   _searchController.clear();
  //                 });
  //               },
  //               icon: Icon(
  //                 Icons.close,
  //                 color: colorScheme.onSurfaceVariant,
  //                 size: 20,
  //               ),
  //               tooltip: 'Qidiruvni yopish',
  //               padding: EdgeInsets.zero,
  //               constraints: const BoxConstraints(),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 12),
  //         TextField(
  //           controller: _searchController,
  //           autofocus: true,
  //           decoration: InputDecoration(
  //             hintText: 'Mahsulot nomini yoki kodini kiriting...',
  //             hintStyle: TextStyle(
  //               color: colorScheme.onSurfaceVariant.withOpacity(0.7),
  //             ),
  //             prefixIcon: Icon(
  //               Icons.search,
  //               color: colorScheme.onSurfaceVariant,
  //               size: 20,
  //             ),
  //             suffixIcon: _searchController.text.isNotEmpty
  //                 ? IconButton(
  //                     icon: Icon(
  //                       Icons.clear,
  //                       color: colorScheme.onSurfaceVariant,
  //                       size: 20,
  //                     ),
  //                     onPressed: () {
  //                       _searchController.clear();
  //                     },
  //                     tooltip: 'Tozalash',
  //                     padding: EdgeInsets.zero,
  //                     constraints: const BoxConstraints(),
  //                   )
  //                 : null,
  //             border: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(12),
  //               borderSide: BorderSide(
  //                 color: colorScheme.outline.withOpacity(0.3),
  //               ),
  //             ),
  //             enabledBorder: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(12),
  //               borderSide: BorderSide(
  //                 color: colorScheme.outline.withOpacity(0.3),
  //               ),
  //             ),
  //             focusedBorder: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(12),
  //               borderSide: BorderSide(
  //                 color: colorScheme.primary,
  //                 width: 2,
  //               ),
  //             ),
  //             filled: true,
  //             fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.1),
  //             contentPadding: const EdgeInsets.symmetric(
  //               horizontal: 16,
  //               vertical: 12,
  //             ),
  //           ),
  //           style: TextStyle(
  //             color: colorScheme.onSurface,
  //             fontSize: 16,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final bool isSearchVisible;

  _SliverAppBarDelegate(this.child, {this.isSearchVisible = false});

  @override
  double get minExtent => _calculateHeight();

  @override
  double get maxExtent => _calculateHeight();

  double _calculateHeight() {
    if (child is TabBar) {
      return (child as TabBar).preferredSize.height;
    } else if (child is Column) {
      // Calculate height for Column with TabBar and search bar
      double height = 0;
      for (final widget in (child as Column).children) {
        if (widget is TabBar) {
          height += widget.preferredSize.height;
        } else if (widget is AnimatedContainer) {
          // Height for animated search container
          height += isSearchVisible ? 80 : 56;
        }
      }
      return height;
    }
    return 48; // Default height
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return isSearchVisible != oldDelegate.isSearchVisible;
  }
}
