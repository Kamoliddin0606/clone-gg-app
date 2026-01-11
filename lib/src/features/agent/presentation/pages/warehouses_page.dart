import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_warehouse.dart';

enum _ViewMode { list, grid }

class WarehousesPage extends StatefulWidget {
  const WarehousesPage({super.key});

  @override
  State<WarehousesPage> createState() => _WarehousesPageState();
}

class _WarehousesPageState extends State<WarehousesPage> {
  final TextEditingController _searchController = TextEditingController();
  List<UserWarehouse> _allWarehouses = [];
  List<UserWarehouse> _filteredWarehouses = [];
  bool _isLoading = true;
  String userCode = "";
  String password = "";
  int? _expandedIndex;
  bool _showViewBar = false;
  _ViewMode _viewMode = _ViewMode.list;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();

      setState(() {
        userCode = prefs.getUserCode() ?? "";
        password = prefs.getPassword() ?? "";
      });

      if (userCode.isEmpty || password.isEmpty) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.userDataNotFound ??
                    'Foydalanuvchi ma\'lumotlari mavjud emas',
              ),
            ),
          );
        }
        return;
      }

      _loadWarehouses();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.errorOccurredPrefix ?? 'Xatolik'}: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadWarehouses() async {
    if (userCode.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final repository = sl<AgentRepository>();
      final warehouses = await repository.getCachedUserWarehouses();

      _allWarehouses = warehouses;
      _filteredWarehouses = List.from(_allWarehouses);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                    context,
                  )?.warehouseDataLoadError(e.toString()) ??
                  'Skladlar ma\'lumotlarini yuklashda xatolik: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterWarehouses(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredWarehouses = List.from(_allWarehouses);
      } else {
        final qLower = query.toLowerCase();
        _filteredWarehouses = _allWarehouses.where((warehouse) {
          return warehouse.name.toLowerCase().contains(qLower) ||
              warehouse.code.toLowerCase().contains(qLower) ||
              warehouse.organization.toLowerCase().contains(qLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Skladlar',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(.08),
              theme.colorScheme.primaryContainer.withOpacity(.06),
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
                onChanged: _filterWarehouses,
              ),
            ),
            // View toolbar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _showViewBar
                    ? _ViewToolbar(
                        count: _filteredWarehouses.length,
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
                          icon: const Icon(Icons.tune),
                        ),
                      ),
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredWarehouses.isEmpty
                  ? const _EmptyState()
                  : (_viewMode == _ViewMode.list
                        ? RefreshIndicator(
                            onRefresh: _loadUserData,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                              itemCount: _filteredWarehouses.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final warehouse = _filteredWarehouses[index];
                                return WarehouseCard(
                                  warehouse: warehouse,
                                  expanded: _expandedIndex == index,
                                  onExpand: (open) {
                                    setState(() {
                                      _expandedIndex = open ? index : null;
                                    });
                                  },
                                );
                              },
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadUserData,
                            child: GridView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 0.8,
                                  ),
                              itemCount: _filteredWarehouses.length,
                              itemBuilder: (context, index) {
                                final warehouse = _filteredWarehouses[index];
                                return WarehouseGridTile(warehouse: warehouse);
                              },
                            ),
                          )),
            ),
          ],
        ),
      ),
    );
  }
}

/// Search field
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
            color: cs.primary.withOpacity(.06),
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

/// Empty state
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warehouse_outlined, size: 48, color: theme.hintColor),
          const SizedBox(height: 8),
          Text(
            'Skladlar topilmadi',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// View toolbar
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
        active ? cs.primary : cs.onSurface.withOpacity(.45);

    return Row(
      children: [
        Text(
          'Skladlar soni: $count',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
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
        IconButton(
          tooltip: AppLocalizations.of(context)?.close ?? 'Yopish',
          onPressed: onCollapse,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

/// Warehouse card for list view
class WarehouseCard extends StatelessWidget {
  final UserWarehouse warehouse;
  final bool? expanded;
  final ValueChanged<bool>? onExpand;
  const WarehouseCard({
    super.key,
    required this.warehouse,
    this.expanded,
    this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surface,
      child: GestureDetector(
        onTap: () {
          final newExpanded = !(expanded ?? false);
          onExpand?.call(newExpanded);
        },
        child: ExpansionTile(
          key: ValueKey('warehouse_${warehouse.code}_${expanded == true}'),
          initiallyExpanded: expanded ?? false,
          onExpansionChanged: null,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: CircleAvatar(
            backgroundColor: cs.primaryContainer,
            child: const Icon(Icons.warehouse, color: Colors.white),
          ),
          title: Text(
            warehouse.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line(
                  context,
                  Icons.code,
                  'Kod: ${warehouse.code}',
                  soft: true,
                ),
                const SizedBox(height: 2),
                _line(context, Icons.business, warehouse.organization),
              ],
            ),
          ),
          children: [
            Row(
              children: [
                const Icon(Icons.business, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)?.organizationLabel ?? 'Tashkilot'}: ${warehouse.organization}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.code, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)?.codeLabel2 ?? 'Kod'}: ${warehouse.code}',
                  ),
                ),
              ],
            ),
            if (warehouse.createdAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Yaratilgan: ${warehouse.createdAt!.toLocal().toString().split(' ')[0]}',
                    ),
                  ),
                ],
              ),
            ],
            if (warehouse.updatedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.update, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Yangilangan: ${warehouse.updatedAt!.toLocal().toString().split(' ')[0]}',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _line(
    BuildContext context,
    IconData icon,
    String text, {
    bool soft = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: soft ? null : Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

/// Warehouse grid tile
class WarehouseGridTile extends StatelessWidget {
  final UserWarehouse warehouse;
  const WarehouseGridTile({super.key, required this.warehouse});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(.15),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Open detail page or bottom sheet
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: cs.primary.withOpacity(.10),
        highlightColor: cs.primary.withOpacity(.10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top icon
            SizedBox(
              height: 120,
              child: Container(
                color: cs.primaryContainer,
                child: const Center(
                  child: Icon(Icons.warehouse, size: 40, color: Colors.white),
                ),
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    warehouse.name,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kod: ${warehouse.code}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    warehouse.organization,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
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
