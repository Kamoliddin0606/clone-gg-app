import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/providers/locale_provider.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_key_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_settings.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/theme/theme_controller.dart';
import 'package:gloria_marketing_flutter/src/theme/theme_toggle.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Column(
        children: [
          // User Profile Section
          const UserProfileSection(),

          // Tab Bar
          Container(
            color: colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: colorScheme.primary,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              tabs: [
                Tab(text: l10n.prices),
                Tab(text: l10n.warehouses),
                Tab(text: l10n.businessRegions),
                Tab(text: l10n.permissions),
                Tab(text: l10n.maps),
                Tab(text: l10n.interfaceSettings),
              ],
            ),
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                 const PricesTab(),
                 const WarehousesTab(),
                 const BusinessRegionsTab(),
                 const PermissionsTab(),
                 const MapsTab(),
                 InterfaceSettingsTab(),
               ],
            ),
          ),
        ],
      ),
    );
  }
}

class UserProfileSection extends StatefulWidget {
  const UserProfileSection({super.key});

  @override
  State<UserProfileSection> createState() => _UserProfileSectionState();
}

class _UserProfileSectionState extends State<UserProfileSection> with TickerProviderStateMixin {
  bool _isEditing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: colorScheme.primary,
                child: const Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'John Doe', // Replace with actual user name
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Agent ID: 12345', // Replace with actual ID
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'john.doe@example.com', // Replace with actual email
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _toggleEdit,
                icon: Icon(
                  _isEditing ? Icons.check : Icons.edit,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isEditing
                ? FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Ism',
                              filled: true,
                              fillColor: colorScheme.surface.withOpacity(0.9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Email',
                              filled: true,
                              fillColor: colorScheme.surface.withOpacity(0.9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Telefon',
                              filled: true,
                              fillColor: colorScheme.surface.withOpacity(0.9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class PricesTab extends StatefulWidget {
  const PricesTab({super.key});

  @override
  State<PricesTab> createState() => _PricesTabState();
}

class _PricesTabState extends State<PricesTab> with TickerProviderStateMixin {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Today', 'Week', 'Month'];
  late AnimationController _chartAnimationController;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chartAnimationController, curve: Curves.easeInOut),
    );
    _chartAnimationController.forward();
  }

  @override
  void dispose() {
    _chartAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters
          Row(
            children: _filters.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFilter = filter);
                      _chartAnimationController.reset();
                      _chartAnimationController.forward();
                    }
                  },
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  selectedColor: colorScheme.primaryContainer,
                  checkmarkColor: colorScheme.onPrimaryContainer,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Price Chart
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Narxlar dinamikasi',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: AnimatedBuilder(
                      animation: _chartAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: PriceChartPainter(
                            animationValue: _chartAnimation.value,
                            colorScheme: colorScheme,
                          ),
                          size: const Size(double.infinity, 200),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Price List
          Text(
            'Narxlar ro\'yxati',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 10,
            itemBuilder: (context, index) {
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text('${index + 1}', style: TextStyle(color: colorScheme.onPrimaryContainer)),
                  ),
                  title: Text('Mahsulot ${index + 1}'),
                  subtitle: Text('Kategoriya ${index % 3 + 1}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(index + 1) * 10000} UZS',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        '+${(index + 1) * 500} UZS',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PriceChartPainter extends CustomPainter {
  final double animationValue;
  final ColorScheme colorScheme;

  PriceChartPainter({required this.animationValue, required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = colorScheme.primary.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final points = <Offset>[];
    for (int i = 0; i <= 10; i++) {
      final x = (size.width / 10) * i;
      final y = size.height - (size.height * 0.8 * (0.3 + 0.7 * (i / 10.0) + 0.2 * (i % 2))) * animationValue;
      points.add(Offset(x, y));
    }

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, size.height);
    fillPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
      fillPath.lineTo(points[i].dx, points[i].dy);
    }

    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WarehousesTab extends StatefulWidget {
  const WarehousesTab({super.key});

  @override
  State<WarehousesTab> createState() => _WarehousesTabState();
}

class _WarehousesTabState extends State<WarehousesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<Map<String, dynamic>> _warehouses = [
    {'name': 'Central Warehouse', 'location': 'Tashkent', 'stock': 1500, 'capacity': 2000, 'status': 'Active'},
    {'name': 'North Warehouse', 'location': 'Samarkand', 'stock': 800, 'capacity': 1500, 'status': 'Active'},
    {'name': 'South Warehouse', 'location': 'Bukhara', 'stock': 1200, 'capacity': 1800, 'status': 'Maintenance'},
    {'name': 'East Warehouse', 'location': 'Andijan', 'stock': 600, 'capacity': 1000, 'status': 'Active'},
    {'name': 'West Warehouse', 'location': 'Khiva', 'stock': 300, 'capacity': 800, 'status': 'Low Stock'},
  ];

  List<Map<String, dynamic>> get _filteredWarehouses {
    if (_searchQuery.isEmpty) return _warehouses;
    return _warehouses.where((warehouse) =>
        warehouse['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
        warehouse['location'].toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Skladlarni qidirish...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),

        // Map Placeholder
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      'Skladlar xaritasi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Warehouse List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredWarehouses.length,
            itemBuilder: (context, index) {
              final warehouse = _filteredWarehouses[index];
              final stockPercentage = warehouse['stock'] / warehouse['capacity'];
              final statusColor = _getStatusColor(warehouse['status'], colorScheme);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                  warehouse['name'],
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 16, color: colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Text(
                                      warehouse['location'],
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              warehouse['status'],
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Zaxira: ${warehouse['stock']} / ${warehouse['capacity']}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: stockPercentage,
                                  backgroundColor: colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    stockPercentage > 0.8 ? colorScheme.error :
                                    stockPercentage > 0.5 ? colorScheme.primary :
                                    colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${(stockPercentage * 100).toStringAsFixed(0)}%',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'Active':
        return colorScheme.primary;
      case 'Maintenance':
        return colorScheme.secondary;
      case 'Low Stock':
        return colorScheme.error;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }
}

class BusinessRegionsTab extends StatefulWidget {
  const BusinessRegionsTab({super.key});

  @override
  State<BusinessRegionsTab> createState() => _BusinessRegionsTabState();
}

class _BusinessRegionsTabState extends State<BusinessRegionsTab> {
  final List<Map<String, dynamic>> _regions = [
    {
      'name': 'Tashkent Region',
      'sales': 2500000,
      'growth': 12.5,
      'customers': 450,
      'trends': [0.8, 0.9, 1.0, 1.1, 1.2, 1.3],
      'isExpanded': false,
    },
    {
      'name': 'Samarkand Region',
      'sales': 1800000,
      'growth': 8.3,
      'customers': 320,
      'trends': [0.7, 0.8, 0.9, 0.95, 1.0, 1.05],
      'isExpanded': false,
    },
    {
      'name': 'Bukhara Region',
      'sales': 1200000,
      'growth': -2.1,
      'customers': 180,
      'trends': [1.0, 0.95, 0.9, 0.85, 0.8, 0.75],
      'isExpanded': false,
    },
    {
      'name': 'Andijan Region',
      'sales': 950000,
      'growth': 15.7,
      'customers': 290,
      'trends': [0.6, 0.7, 0.8, 0.9, 1.0, 1.15],
      'isExpanded': false,
    },
  ];

  void _toggleExpansion(int index) {
    setState(() {
      _regions[index]['isExpanded'] = !_regions[index]['isExpanded'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map Overview
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Viloyatlar xaritasi',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: colorScheme.surfaceContainerHighest,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_outlined, size: 48, color: colorScheme.primary),
                            const SizedBox(height: 8),
                            Text(
                              'O\'zbekiston viloyatlari',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Analytics Summary
          Row(
            children: [
              Expanded(
                child: _AnalyticsCard(
                  title: 'Jami savdo',
                  value: '6 450 000 UZS',
                  icon: Icons.trending_up,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AnalyticsCard(
                  title: 'O\'rtacha o\'sish',
                  value: '+8.6%',
                  icon: Icons.show_chart,
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Region Details
          Text(
            'Viloyat tafsilotlari',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _regions.length,
            itemBuilder: (context, index) {
              final region = _regions[index];
              final isExpanded = region['isExpanded'];
              final growthColor = region['growth'] >= 0 ? colorScheme.primary : colorScheme.error;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        region['name'],
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Text('${region['customers']} mijoz'),
                          const SizedBox(width: 16),
                          Text(
                            '${region['growth'] >= 0 ? '+' : ''}${region['growth']}%',
                            style: TextStyle(
                              color: growthColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(region['sales'] / 1000).toInt()}k UZS',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          IconButton(
                            icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                            onPressed: () => _toggleExpansion(index),
                          ),
                        ],
                      ),
                    ),
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Savdo tendensiyasi',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 60,
                              child: CustomPaint(
                                painter: TrendLinePainter(
                                  data: List<double>.from(region['trends']),
                                  color: growthColor,
                                ),
                                size: const Size(double.infinity, 60),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _DetailItem(
                                    label: 'Oy savdo',
                                    value: '${(region['sales'] / 12 / 1000).toInt()}k UZS',
                                  ),
                                ),
                                Expanded(
                                  child: _DetailItem(
                                    label: 'Mijozlar soni',
                                    value: '${region['customers']}',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class TrendLinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  TrendLinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    for (int i = 0; i < data.length; i++) {
      final x = (size.width / (data.length - 1)) * i;
      final y = size.height - ((data[i] - minValue) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = (size.width / (data.length - 1)) * i;
      final y = size.height - ((data[i] - minValue) / range) * size.height;
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PermissionsTab extends StatefulWidget {
  const PermissionsTab({super.key});

  @override
  State<PermissionsTab> createState() => _PermissionsTabState();
}

class _PermissionsTabState extends State<PermissionsTab> {
  SalesReqPermissions? _permissions;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get user code from shared preferences
      final prefs = context.read<SharedPreferencesService>();
      final userCode = prefs.getUserCode();
      print('__________Setting permisionsda User code: $userCode');
      if (userCode == null) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.userCodeNotFound;
          _isLoading = false;
        });
        return;
      }

      // Get permissions from data sync service
      final dataSyncService = context.read<DataSyncService>();
      final permissions = await dataSyncService.getCachedSalesReqPermissions(userCode);

      setState(() {
        _permissions = permissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '${AppLocalizations.of(context)!.errorLoadingPermissions}: $e';
        _isLoading = false;
      });
    }
  }

  String _getPermissionLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'skipTINduplicateCheck':
        return l10n.skipTINDuplicateCheck;
      case 'allowCreationWithoutTIN':
        return l10n.allowCreationWithoutTIN;
      case 'allowCreatingPointOfSale':
        return l10n.allowCreatingPointOfSale;
      case 'visit':
        return l10n.visit;
      case 'strictSequence':
        return l10n.strictSequence;
      case 'unplannedOrder':
        return l10n.unplannedOrder;
      case 'plannedRoute':
        return l10n.plannedRoute;
      case 'editClientCoordinates':
        return 'Mijoz koordinatalarini tahrirlash'; // Uzbek translation for "Edit Client Coordinates"
      default:
        return key;
    }
  }

  String _getPermissionCategory(String key, AppLocalizations l10n) {
    switch (key) {
      case 'skipTINduplicateCheck':
      case 'allowCreationWithoutTIN':
      case 'allowCreatingPointOfSale':
        return AppLocalizations.of(context)!.dataValidation;
      case 'visit':
      case 'strictSequence':
      case 'unplannedOrder':
      case 'plannedRoute':
      case 'editClientCoordinates':
        return AppLocalizations.of(context)!.visitManagement;
      default:
        return AppLocalizations.of(context)!.general;
    }
  }

  IconData _getPermissionIcon(String key) {
    switch (key) {
      case 'skipTINduplicateCheck':
        return Icons.check_circle_outline;
      case 'allowCreationWithoutTIN':
        return Icons.add_circle_outline;
      case 'allowCreatingPointOfSale':
        return Icons.store;
      case 'visit':
        return Icons.location_on;
      case 'strictSequence':
        return Icons.timeline;
      case 'unplannedOrder':
        return Icons.add_shopping_cart;
      case 'plannedRoute':
        return Icons.route;
      case 'editClientCoordinates':
        return Icons.edit_location;
      default:
        return Icons.settings;
    }
  }

  Color _getCategoryColor(String category, AppLocalizations l10n, ColorScheme colorScheme) {
    switch (category) {
      case 'dataValidation':
        return colorScheme.primary;
      case 'visitManagement':
        return colorScheme.secondary;
      default:
        return colorScheme.tertiary;
    }
  }

  Map<String, List<String>> get _groupedPermissions {
    if (_permissions == null) return {};

    final l10n = AppLocalizations.of(context)!;
    final grouped = <String, List<String>>{};

    // Add main permissions
    final mainPermissions = [
      'skipTINduplicateCheck',
      'allowCreationWithoutTIN',
      'allowCreatingPointOfSale',
      'visit',
      'strictSequence',
      'unplannedOrder',
      'plannedRoute',
      'editClientCoordinates',
    ];

    for (final key in mainPermissions) {
      final category = _getPermissionCategory(key, l10n);
      grouped.putIfAbsent(category, () => []).add(key);
    }

    return grouped;
  }

  bool _getPermissionValue(String key) {
    if (_permissions == null) return false;

    switch (key) {
      case 'skipTINduplicateCheck':
        return _permissions!.skipTINduplicateCheck;
      case 'allowCreationWithoutTIN':
        return _permissions!.allowCreationWithoutTIN;
      case 'allowCreatingPointOfSale':
        return _permissions!.allowCreatingPointOfSale;
      case 'visit':
        return _permissions!.visit;
      case 'strictSequence':
        return _permissions!.strictSequence;
      case 'unplannedOrder':
        return _permissions!.unplannedOrder;
      case 'plannedRoute':
        return _permissions!.plannedRoute;
      case 'editClientCoordinates':
        return _permissions!.plannedRoute;
      default:
        return false;
    }
  }

  // Visit Steps section
  Widget _buildVisitStepsSection(AppLocalizations l10n, ColorScheme colorScheme) {
    if (_permissions == null || _permissions!.visitSteps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.visitSteps,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._permissions!.visitSteps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${step.stepCode}',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
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
                          step.stepName,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          step.stepRequired ? AppLocalizations.of(context)!.mandatoryExecution : AppLocalizations.of(context)!.optional,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: step.stepRequired ? colorScheme.error : colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    step.stepRequired ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: step.stepRequired ? colorScheme.error : colorScheme.secondary,
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPermissions,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_permissions == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.permissionsDataNotAvailable,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Permissions Overview
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        l10n.agentPermissions,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.userPermissionsAndVisitSteps,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Permissions by Category
          Text(
            AppLocalizations.of(context)!.permissions,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ..._groupedPermissions.entries.map((entry) {
            final category = entry.key;
            final permissions = entry.value;
            final categoryColor = _getCategoryColor(category, l10n, colorScheme);

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.category,
                          color: categoryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: categoryColor,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: categoryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${permissions.where((p) => _getPermissionValue(p)).length}/${permissions.length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...permissions.map((permissionKey) {
                    final isEnabled = _getPermissionValue(permissionKey);
                    return ListTile(
                      title: Text(
                        _getPermissionLabel(permissionKey, l10n),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isEnabled ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      subtitle: isEnabled ? null : Text(
                        AppLocalizations.of(context)!.permissionDenied,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                      leading: Icon(
                        _getPermissionIcon(permissionKey),
                        color: isEnabled ? categoryColor : colorScheme.onSurfaceVariant,
                      ),
                      trailing: Icon(
                        isEnabled ? Icons.check_circle : Icons.cancel,
                        color: isEnabled ? colorScheme.primary : colorScheme.error,
                      ),
                    );
                  }),
                ],
              ),
            );
          }),

          // Visit Steps Section
          _buildVisitStepsSection(l10n, colorScheme),
        ],
      ),
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _SecurityBadge({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class InterfaceSettingsTab extends StatefulWidget {
  const InterfaceSettingsTab({super.key});

  @override
  State<InterfaceSettingsTab> createState() => _InterfaceSettingsTabState();
}

class _InterfaceSettingsTabState extends State<InterfaceSettingsTab> {
  String _selectedLanguage = 'uz'; // Default to Uzbek

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    try {
      final localeProvider = context.read<LocaleProvider>();
      setState(() {
        _selectedLanguage = localeProvider.currentLanguageCode;
      });
    } catch (e) {
      print('Error loading current language: $e');
      setState(() {
        _selectedLanguage = 'uz'; // Fallback
      });
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmLanguageChange),
        content: Text(l10n.languageChangeWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.apply),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Update locale through provider
        final localeProvider = context.read<LocaleProvider>();
        await localeProvider.setLocaleByCode(languageCode);

        setState(() {
          _selectedLanguage = languageCode;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.languageChanged),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        print('Error changing language: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.languageChangeError),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language Settings Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.language, color: colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        l10n.interfaceSettings,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Current Language Display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          l10n.currentLanguage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _getLanguageName(_selectedLanguage, l10n),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Available Languages
                  Text(
                    l10n.availableLanguages,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Language Options
                  _LanguageOption(
                    languageCode: 'uz',
                    languageName: l10n.uzbek,
                    isSelected: _selectedLanguage == 'uz',
                    onTap: () => _changeLanguage('uz'),
                  ),
                  const SizedBox(height: 8),
                  _LanguageOption(
                    languageCode: 'ru',
                    languageName: l10n.russian,
                    isSelected: _selectedLanguage == 'ru',
                    onTap: () => _changeLanguage('ru'),
                  ),
                  const SizedBox(height: 8),
                  _LanguageOption(
                    languageCode: 'en',
                    languageName: l10n.english,
                    isSelected: _selectedLanguage == 'en',
                    onTap: () => _changeLanguage('en'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Additional Interface Settings
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.appearance,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Theme Toggle
                  ListTile(
                    leading: Icon(Icons.palette, color: colorScheme.primary),
                    title: Text(l10n.theme),
                    subtitle: Text(ThemeController.I.mode.value == ThemeMode.dark ? l10n.dark : l10n.light),
                    trailing: SizedBox(
                      width: 80,
                      child: ThemeToggle(
                        mode: ThemeController.I.mode.value,
                        onChanged: ThemeController.I.set,
                      ),
                    ),
                    onTap: () => ThemeController.I.set(ThemeController.I.mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String languageCode, AppLocalizations l10n) {
    switch (languageCode) {
      case 'uz':
        return l10n.uzbek;
      case 'ru':
        return l10n.russian;
      case 'en':
        return l10n.english;
      default:
        return l10n.uzbek;
    }
  }
}

class MapsTab extends StatefulWidget {
  const MapsTab({super.key});

  @override
  State<MapsTab> createState() => _MapsTabState();
}

class _MapsTabState extends State<MapsTab> {
  MapProvider _selectedProvider = MapProvider.openStreetMap; // Default
  bool _isLoading = true;
  late ApiKeyService _apiKeyService;

  // API key input controllers
  final TextEditingController _googleApiKeyController = TextEditingController();
  final TextEditingController _yandexApiKeyController = TextEditingController();
  final TextEditingController _osmApiKeyController = TextEditingController();

  // API key visibility states
  bool _googleApiKeyVisible = false;
  bool _yandexApiKeyVisible = false;
  bool _osmApiKeyVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeApiKeyService();
    _loadCurrentMapSettings();
  }

  @override
  void dispose() {
    _googleApiKeyController.dispose();
    _yandexApiKeyController.dispose();
    _osmApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _initializeApiKeyService() async {
    try {
      await sl.isReady<ApiKeyService>();
      _apiKeyService = sl<ApiKeyService>();
      await _loadApiKeys();
    } catch (e) {
      print('Error initializing API key service: $e');
      // Fallback: try to get from context
      try {
        _apiKeyService = ApiKeyService.instance;
        await _apiKeyService.initialize(context.read<SharedPreferencesService>());
        await _loadApiKeys();
      } catch (fallbackError) {
        print('Fallback API key service initialization failed: $fallbackError');
      }
    }
  }

  Future<void> _loadApiKeys() async {
    try {
      final googleKey = await _apiKeyService.getApiKey(ApiKeyService.googleMapsApiKey);
      final yandexKey = await _apiKeyService.getApiKey(ApiKeyService.yandexMapsApiKey);
      final osmKey = await _apiKeyService.getApiKey(ApiKeyService.openStreetMapsApiKey);

      setState(() {
        _googleApiKeyController.text = googleKey ?? '';
        _yandexApiKeyController.text = yandexKey ?? '';
        _osmApiKeyController.text = osmKey ?? '';
      });
    } catch (e) {
      print('Error loading API keys: $e');
    }
  }

  Future<void> _loadCurrentMapSettings() async {
    try {
      final prefs = context.read<SharedPreferencesService>();
      final savedProvider = prefs.preferences.getString('default_map_provider');

      if (savedProvider != null) {
        setState(() {
          _selectedProvider = MapProvider.values.firstWhere(
            (provider) => provider.toString() == savedProvider,
            orElse: () => MapProvider.openStreetMap,
          );
        });
      }
    } catch (e) {
      print('Error loading map settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changeDefaultMap(MapProvider provider) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectDefaultMap),
        content: Text('${l10n.selectDefaultMap} ${provider.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.apply),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final prefs = context.read<SharedPreferencesService>();
        await prefs.preferences.setString('default_map_provider', provider.toString());

        setState(() {
          _selectedProvider = provider;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.defaultMapChanged),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        print('Error saving map settings: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.error}: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  String _getMapProviderName(MapProvider provider, AppLocalizations l10n) {
    switch (provider) {
      case MapProvider.google:
        return l10n.googleMaps;
      case MapProvider.yandex:
        return l10n.yandexMaps;
      case MapProvider.openStreetMap:
        return l10n.openStreetMap;
    }
  }

  Future<String> _getApiKeyStatus(MapProvider provider) async {
    try {
      switch (provider) {
        case MapProvider.google:
          final hasKey = await _apiKeyService.hasApiKey(ApiKeyService.googleMapsApiKey);
          print('hasKey: $hasKey');
          return hasKey ? 'sozlangan' : 'sozlanmagan';
        case MapProvider.yandex:
          final hasKey = await _apiKeyService.hasApiKey(ApiKeyService.yandexMapsApiKey);
          print('hasKey: $hasKey');
          return hasKey ? 'sozlangan' : 'sozlanmagan';
        case MapProvider.openStreetMap:
          return 'kalit_shart_emas'; // OSM doesn't require API key
      }
    } catch (e) {
      print('Error checking API key status: $e');
      return 'xatolik';
    }
  }

  Future<void> _saveApiKey(String keyType, String apiKey) async {
    try {
      final result = await _apiKeyService.storeAndValidateApiKey(keyType, apiKey);
      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('API kaliti muvaffaqiyatli saqlandi'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Xatolik: ${result.errorMessage}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showApiKeyDialog(MapProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    String keyType;
    TextEditingController controller;
    String title;
    String hint;

    switch (provider) {
      case MapProvider.google:
        keyType = ApiKeyService.googleMapsApiKey;
        controller = _googleApiKeyController;
        title = 'Google Maps API Kaliti';
        hint = 'AIza...';
        break;
      case MapProvider.yandex:
        keyType = ApiKeyService.yandexMapsApiKey;
        controller = _yandexApiKeyController;
        title = 'Yandex Maps API Kaliti';
        hint = 'sizning-yandex-api-kalitingiz';
        break;
      case MapProvider.openStreetMap:
        // OSM doesn't require API key, but we can store custom config
        keyType = ApiKeyService.openStreetMapsApiKey;
        controller = _osmApiKeyController;
        title = 'OpenStreetMap Konfiguratsiyasi';
        hint = 'ixtiyoriy-maxsus-konfiguratsiya';
        break;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          obscureText: true, // Hide API key by default
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final apiKey = controller.text.trim();
              if (apiKey.isNotEmpty) {
                Navigator.pop(context, apiKey);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _saveApiKey(keyType, result);
      setState(() {}); // Refresh UI to show updated status
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map Settings Header
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.map, color: colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        l10n.mapSettings,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.mapConfiguration,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Current Map Provider
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.currentMapProvider,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.map_outlined, color: colorScheme.onPrimaryContainer),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getMapProviderName(_selectedProvider, l10n),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.check_circle,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Available Maps
          Text(
            l10n.availableMaps,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...MapProvider.values.map((provider) => _buildMapProviderCard(provider, l10n, theme, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildMapProviderCard(MapProvider provider, AppLocalizations l10n, ThemeData theme, ColorScheme colorScheme) {
    final isSelected = provider == _selectedProvider;

    return FutureBuilder<String>(
      future: _getApiKeyStatus(provider),
      builder: (context, snapshot) {
        final apiKeyStatus = snapshot.data ?? 'xatolik';

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => _changeDefaultMap(provider),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Map Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.map,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getMapProviderName(provider, l10n),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'API Kaliti: ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              apiKeyStatus == 'kalit_shart_emas'
                                  ? 'Kalit shart emas'
                                  : apiKeyStatus == 'sozlangan'
                                      ? 'Sozlangan'
                                      : 'Sozlanmagan',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: apiKeyStatus == 'sozlangan' || apiKeyStatus == 'kalit_shart_emas'
                                    ? colorScheme.primary
                                    : colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () => _showApiKeyDialog(provider),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String languageCode;
  final String languageName;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.languageCode,
    required this.languageName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            // Language Flag/Icon (placeholder)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  languageCode.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                languageName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}