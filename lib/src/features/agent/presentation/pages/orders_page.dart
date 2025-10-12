import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';
import '../../../../Utility/formatter.dart';
import '../../data/models/order.dart';

enum _ViewMode { list, grid }
enum OrderStatusFilter { all, delivered, pending, cancelled, expired }

/// Format number with spaces as thousand separators
String formatNumber(num number) {
  final formatter = NumberFormat('#,###', 'en_US');
  return formatter.format(number).replaceAll(',', ' ');
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with TickerProviderStateMixin {
  // Controllers and state variables
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  bool _isFilterPanelVisible = false;
  OrderStatusFilter _selectedStatusFilter = OrderStatusFilter.all;
  DateTimeRange? _selectedDateRange;
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showViewBar = false;
  _ViewMode _viewMode = _ViewMode.list;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
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
    _tabController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
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

      // Check if we need to sync data from API
      var orders = await repository.getCachedOrders();
      if (orders.isEmpty) {
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

          // Reload orders after sync
          orders = await repository.getCachedOrders();
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

      setState(() {
        _orders = orders;
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

  void _onStatusFilterChanged(OrderStatusFilter? status) {
    setState(() {
      _selectedStatusFilter = status ?? OrderStatusFilter.all;
    });
  }

  void _onDateRangeChanged(DateTimeRange? range) {
    setState(() {
      _selectedDateRange = range;
    });
  }

  List<Order> _getFilteredOrders() {
    var filtered = _orders;

    // Apply status filter
    if (_selectedStatusFilter != OrderStatusFilter.all) {
      filtered = filtered.where((order) {
        switch (_selectedStatusFilter) {
          case OrderStatusFilter.delivered:
            return order.mainStatus.contains('Доставлено');
          case OrderStatusFilter.pending:
            return order.mainStatus.contains('Оператор') || order.mainStatus.contains('комплектации');
          case OrderStatusFilter.cancelled:
            return order.mainStatus.contains('возврат');
          case OrderStatusFilter.expired:
            return order.mainStatus.contains('истёк');
          default:
            return true;
        }
      }).toList();
    }

    // Apply date range filter
    if (_selectedDateRange != null) {
      filtered = filtered.where((order) {
        return order.dateOrder.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
               order.dateOrder.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Apply search filtering
    final searchQuery = _searchController.text.trim();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((order) {
        return matchesSearch(order.numOrder, searchQuery) ||
               matchesSearch(order.clientCode, searchQuery) ||
               matchesSearch(order.clientName, searchQuery) ||
               matchesSearch(order.mainStatus, searchQuery) ||
               matchesSearch(order.total.toString(), searchQuery);
      }).toList();
    }

    return filtered;
  }

  List<Order> _getOrdersForTab(int tabIndex) {
    final allFiltered = _getFilteredOrders();

    switch (tabIndex) {
      case 0: // Все
        return allFiltered;
      case 1: // Доставлено
        return allFiltered.where((o) => o.mainStatus.contains('Доставлено')).toList();
      case 2: // В процессе
        return allFiltered.where((o) => o.mainStatus.contains('Оператор') || o.mainStatus.contains('комплектации')).toList();
      case 3: // Возврат
        return allFiltered.where((o) => o.mainStatus.contains('возврат')).toList();
      case 4: // Истек
        return allFiltered.where((o) => o.mainStatus.contains('истёк')).toList();
      default:
        return allFiltered;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Buyurtmalar', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _toggleFilterPanel,
            tooltip: 'Filtr',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Все'),
            Tab(text: 'Доставлено'),
            Tab(text: 'В процессе'),
            Tab(text: 'Возврат'),
            Tab(text: 'Истек'),
          ],
        ),
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
            // Search bar
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          // Status filter
                          Text(
                            'Status',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<OrderStatusFilter>(
                            value: _selectedStatusFilter,
                            decoration: InputDecoration(
                              labelText: 'Status tanlang',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colorScheme.outline),
                              ),
                              filled: true,
                              fillColor: colorScheme.surface,
                            ),
                            items: OrderStatusFilter.values.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(_getStatusFilterText(status)),
                              );
                            }).toList(),
                            onChanged: _onStatusFilterChanged,
                          ),
                          const SizedBox(height: 16),

                          // Date range filter
                          Text(
                            'Sana oralig\'i',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                                initialDateRange: _selectedDateRange,
                              );
                              if (picked != null) {
                                _onDateRangeChanged(picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Sana oralig\'ini tanlang',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colorScheme.outline),
                                ),
                                filled: true,
                                fillColor: colorScheme.surface,
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _selectedDateRange != null
                                    ? '${DateFormat('dd.MM.yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd.MM.yyyy').format(_selectedDateRange!.end)}'
                                    : 'Barcha sanalar',
                              ),
                            ),
                          ),
                          if (_selectedDateRange != null) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => _onDateRangeChanged(null),
                              child: const Text('Tozalash'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // View toolbar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _showViewBar
                    ? _ViewToolbar(
                  count: _getOrdersForTab(_tabController.index).length,
                  mode: _viewMode,
                  onModeChanged: (m) => setState(() => _viewMode = m),
                  onCollapse: () => setState(() => _showViewBar = false),
                )
                    : Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Ko\'rinish paneli',
                    onPressed: () => setState(() => _showViewBar = true),
                    icon: const Icon(Icons.tune),
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: List.generate(5, (index) {
                  final tabOrders = _getOrdersForTab(index);
                  return _isLoading
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
                          : tabOrders.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_cart,
                                        size: 64,
                                        color: colorScheme.outline,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Buyurtmalar topilmadi',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
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
                      itemCount: tabOrders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final order = tabOrders[index];
                        return OrderCard(
                          order: order,
                          onTap: () => _navigateToOrderDetail(order),
                        );
                      },
                    )
                        : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: tabOrders.length,
                      itemBuilder: (context, index) {
                        final order = tabOrders[index];
                        return OrderGridTile(
                          order: order,
                          onTap: () => _navigateToOrderDetail(order),
                        );
                      },
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusFilterText(OrderStatusFilter status) {
    switch (status) {
      case OrderStatusFilter.all:
        return 'Barcha';
      case OrderStatusFilter.delivered:
        return 'Доставлено';
      case OrderStatusFilter.pending:
        return 'В процессе';
      case OrderStatusFilter.cancelled:
        return 'Возврат';
      case OrderStatusFilter.expired:
        return 'Истек';
    }
  }

  void _navigateToOrderDetail(Order order) {
    // TODO: Navigate to order detail page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Buyurtma: ${order.numOrder}')),
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
          BoxShadow(color: cs.primary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 6)),
        ],
        border: Border.all(color: cs.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: 'Qidirish...',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 14),
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
        // Buyurtmalar soni
        Text(
          'Buyurtmalar soni: $count',
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
              Icons.view_agenda_rounded,
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
              Icons.grid_view_rounded,
              size: 22,
              color: iconColor(mode == _ViewMode.grid),
            ),
          ),
        ),

        const SizedBox(width: 6),
        // Yopish
        IconButton(
          tooltip: 'Yopish',
          onPressed: onCollapse,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                          order.numOrder,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.business, size: 16, color: cs.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Mijoz: ${order.clientName}',
                                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: cs.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text(
                              'Sana: ${DateFormat('dd.MM.yyyy HH:mm').format(order.dateOrder)}',
                              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${formatNumber(order.total)} UZS',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.mainStatus, cs),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          order.mainStatus,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getStatusTextColor(order.mainStatus, cs),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status, ColorScheme cs) {
    if (status.contains('Доставлено')) {
      return cs.primaryContainer;
    } else if (status.contains('возврат')) {
      return cs.errorContainer;
    } else if (status.contains('Оператор') || status.contains('комплектации')) {
      return cs.secondaryContainer;
    } else if (status.contains('истёк')) {
      return cs.tertiaryContainer;
    }
    return cs.surfaceContainerHighest;
  }

  Color _getStatusTextColor(String status, ColorScheme cs) {
    if (status.contains('Доставлено')) {
      return cs.onPrimaryContainer;
    } else if (status.contains('возврат')) {
      return cs.onErrorContainer;
    } else if (status.contains('Оператор') || status.contains('комплектации')) {
      return cs.onSecondaryContainer;
    } else if (status.contains('истёк')) {
      return cs.onTertiaryContainer;
    }
    return cs.onSurfaceVariant;
  }
}

class OrderGridTile extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderGridTile({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: cs.primary.withValues(alpha: 0.10),
        highlightColor: cs.primary.withValues(alpha: 0.10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TOP: order icon
            SizedBox(
              height: 100,
              child: Container(
                color: cs.primaryContainer,
                child: const Center(child: Icon(Icons.shopping_cart, size: 40)),
              ),
            ),
            // BODY: details
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.numOrder,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.clientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Summa: ${formatNumber(order.total)} UZS',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.mainStatus, cs),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.mainStatus,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getStatusTextColor(order.mainStatus, cs),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  Color _getStatusColor(String status, ColorScheme cs) {
    if (status.contains('Доставлено')) {
      return cs.primaryContainer;
    } else if (status.contains('возврат')) {
      return cs.errorContainer;
    } else if (status.contains('Оператор') || status.contains('комплектации')) {
      return cs.secondaryContainer;
    } else if (status.contains('истёк')) {
      return cs.tertiaryContainer;
    }
    return cs.surfaceContainerHighest;
  }

  Color _getStatusTextColor(String status, ColorScheme cs) {
    if (status.contains('Доставлено')) {
      return cs.onPrimaryContainer;
    } else if (status.contains('возврат')) {
      return cs.onErrorContainer;
    } else if (status.contains('Оператор') || status.contains('комплектации')) {
      return cs.onSecondaryContainer;
    } else if (status.contains('истёк')) {
      return cs.onTertiaryContainer;
    }
    return cs.onSurfaceVariant;
  }
}