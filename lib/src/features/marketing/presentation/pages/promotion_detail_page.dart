import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/features/marketing/data/models/promotion_model.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                                  'Aksiya haqida',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${widget.promotion.type} turidagi aksiya',
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
                                    'Aksiyada qatnashuvchi mahsulotlar soni: ${widget.promotion.productList.length} ta SKU',
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
                                    'Bonus sifatida berilishi mumkin bo\'lgan mahsulotlar: ${widget.promotion.bonusList.length} ta SKU',
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
                              'Aksiya shartlari',
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
                                    'Minimal mahsulot soni: ${widget.promotion.minPromoProductCount}',
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
                                    'Bonus soni: ${widget.promotion.bonusCount}',
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
                              'Boshlanish: ${_formatDate(widget.promotion.dateStart)}',
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
                              'Tugash: ${_formatDate(widget.promotion.dateEnd)}',
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
                              widget.promotion.isActive ? 'Faol' : 'Faol emas',
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
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.inventory),
                        text: 'Mahsulotlar',
                      ),
                      Tab(
                        icon: Icon(Icons.card_giftcard),
                        text: 'Bonuslar',
                      ),
                      Tab(
                        icon: Icon(Icons.category),
                        text: 'Sinf',
                      ),
                    ],
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    indicatorColor: colorScheme.primary,
                  ),
                  // Enhanced collapsible search bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: _isSearchVisible ? 80 : 56,
                    child: Container(
                      color: colorScheme.surface,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isSearchVisible = !_isSearchVisible;
                            if (!_isSearchVisible) {
                              _searchController.clear();
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.2),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: _isSearchVisible
                                ? _buildExpandedSearchBar(colorScheme)
                                : _buildCollapsedSearchBar(colorScheme),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              isSearchVisible: _isSearchVisible,
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
      return _buildEmptyState(query.isEmpty ? 'Mahsulotlar topilmadi' : 'Qidiruv natijasi topilmadi');
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 64, left: 16, right: 16, bottom: 16),
      itemCount: productsToShow.length,
      itemBuilder: (context, index) {
        final product = productsToShow[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                product.code.substring(0, 2),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(product.productName),
            subtitle: Text('Kod: ${product.code}'),
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
      return _buildEmptyState(query.isEmpty ? 'Bonuslar topilmadi' : 'Qidiruv natijasi topilmadi');
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 64, left: 16, right: 16, bottom: 16),
      itemCount: bonusesToShow.length,
      itemBuilder: (context, index) {
        final bonus = bonusesToShow[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.1),
              child: const Icon(
                Icons.card_giftcard,
                color: Colors.green,
              ),
            ),
            title: Text(bonus.productName),
            subtitle: Text('Kod: ${bonus.code}'),
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
      return _buildEmptyState(query.isEmpty ? 'Sinf ma\'lumotlari topilmadi' : 'Qidiruv natijasi topilmadi');
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
            subtitle: Text('Kod: ${classItem.code}'),
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

  Widget _buildCollapsedSearchBar(ColorScheme colorScheme) {
    return Container(
      key: const ValueKey('collapsed'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mahsulotlarni qidirish',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedSearchBar(ColorScheme colorScheme) {
    return Container(
      key: const ValueKey('expanded'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
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
              Icon(
                Icons.search,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Qidiruv',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isSearchVisible = false;
                    _searchController.clear();
                  });
                },
                icon: Icon(
                  Icons.close,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                tooltip: 'Qidiruvni yopish',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Mahsulot nomini yoki kodini kiriting...',
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                      },
                      tooltip: 'Tozalash',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outline.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outline.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.1),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

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
