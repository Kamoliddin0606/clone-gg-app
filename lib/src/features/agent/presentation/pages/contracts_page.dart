import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';
import '../../../../Utility/formatter.dart';
import '../../data/models/client_contract.dart';
import '../../data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_contract.dart';
import '../widgets/contract_models.dart';
import '../widgets/contracts_filters_panel.dart';
import 'contract_detail_page.dart';

enum _ViewMode { list, grid }

/// Format number with spaces as thousand separators
String formatNumber(num number) {
  final formatter = NumberFormat('#,###', 'en_US');
  return formatter.format(number).replaceAll(',', ' ');
}

class ContractsPage extends StatefulWidget {
  final String? initialClientFilter;
  final String? initialClientName;

  const ContractsPage({
    super.key,
    this.initialClientFilter,
    this.initialClientName,
  });

  @override
  State<ContractsPage> createState() => _ContractsPageState();
}

class _ContractsPageState extends State<ContractsPage> with TickerProviderStateMixin {
  // Controllers and state variables
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  bool _isFilterPanelVisible = false;
  // Removed unused fields - now using _filters
  List<ClientContractWithName> _contracts = [];
  List<TradingPoint> _tradingPoints = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showViewBar = false;
  _ViewMode _viewMode = _ViewMode.list;
  final ContractsFilterState _filters = ContractsFilterState();

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
      var contracts = await repository.getCachedClientContractsWithNames();
      if (contracts.isEmpty) {
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

          // Reload contracts after sync
          contracts = await repository.getCachedClientContractsWithNames();
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
        _contracts = contracts;
        _isLoading = false;
      });

      // Load trading points for filter
      await _loadTradingPoints();

      // Apply initial client filter after data is loaded
      if (widget.initialClientFilter != null && widget.initialClientName != null) {
        _applyInitialClientFilter();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in _loadData: $e');
      }
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

  void _onFiltersChanged(ContractsFilterState state) {
    setState(() {
      _filters.tradingPointCodes.clear();
      _filters.tradingPointCodes.addAll(state.tradingPointCodes);
      _filters.dateRange = state.dateRange;
      _filters.status = state.status;
    });
  }

  /// Apply initial client filter when navigating from Trading Points page
  void _applyInitialClientFilter() {
    try {
      if (widget.initialClientName == null || widget.initialClientName!.isEmpty) {
        return;
      }

      if (kDebugMode) {
        print('Applying initial client filter: ${widget.initialClientName}');
      }

      setState(() {
        _filters.tradingPointCodes = {widget.initialClientName!};
        _isFilterPanelVisible = false; // Hide filter panel for cleaner UX
      });

      // Apply filters immediately
      _onFiltersChanged(_filters);

      // Show user feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.initialClientName} mijozining shartnomalari'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      if (kDebugMode) {
        print('Applied initial client filter successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error applying initial client filter: $e');
      }
      // Don't rethrow - allow the page to continue loading without the filter
    }
  }

  List<ClientContractWithName> _getFilteredContracts() {
    var filtered = _contracts;

    // Apply trading points filter
    if (_filters.tradingPointCodes.isNotEmpty) {
      filtered = filtered.where((contract) {
        return _filters.tradingPointCodes.contains(contract.codeClient);
      }).toList();
    }

    // Apply date range filter
    if (_filters.dateRange != null) {
      filtered = filtered.where((contract) {
        if (contract.dateOfContract == null) return false;
        return contract.dateOfContract!.isAfter(_filters.dateRange!.start.subtract(const Duration(days: 1))) &&
               contract.dateOfContract!.isBefore(_filters.dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Apply status filter
    if (_filters.status != null && _filters.status != ContractStatus.all) {
      filtered = filtered.where((contract) {
        switch (_filters.status) {
          case ContractStatus.active:
            return contract.active && contract.status == 'Действует';
          case ContractStatus.inactive:
            return !contract.active;
          case ContractStatus.expired:
            return contract.status == 'Истек';
          case ContractStatus.pending:
            return contract.status == 'Не согласован';
          default:
            return true;
        }
      }).toList();
    }

    // Apply search filtering
    final searchQuery = _searchController.text.trim();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((contract) {
        return matchesSearch(contract.codeContract, searchQuery) ||
                matchesSearch(contract.codeClient, searchQuery) ||
                matchesSearch(contract.status, searchQuery) ||
                matchesSearch(contract.sumOfContract.toString(), searchQuery);
      }).toList();
    }

    return filtered;
  }

  List<ClientContractWithName> _getContractsForTab(int tabIndex) {
    final allFiltered = _getFilteredContracts();

    switch (tabIndex) {
      case 0: // Все
        return allFiltered;
      case 1: // Действует
        return allFiltered.where((c) => c.status == 'Действует' && c.active).toList();
      case 2: // Истек
        return allFiltered.where((c) => c.status == 'Истек').toList();
      case 3: // Приостановлен
        return allFiltered.where((c) => !c.active).toList();
      case 4: // Не согласован
        return allFiltered.where((c) => c.status == 'Не согласован').toList();
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
        title: Text('Shartnomalar', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
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
            Tab(text: 'Действует'),
            Tab(text: 'Истек'),
            Tab(text: 'Приостановлен'),
            Tab(text: 'Не согласован'),
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
                      child: ContractsFiltersPanel(
                        state: _filters,
                        availableTradingPoints: _tradingPoints,
                        onChange: _onFiltersChanged,
                        onPickDateRange: _pickDateRange,
                        onClearDateRange: () => _onFiltersChanged(_filters.copyWith(dateRange: null)),
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
                  count: _getContractsForTab(_tabController.index).length,
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
                  final tabContracts = _getContractsForTab(index);
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
                          : tabContracts.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.description,
                                        size: 64,
                                        color: colorScheme.outline,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Shartnomalar topilmadi',
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
                      itemCount: tabContracts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final contract = tabContracts[index];
                        return ContractCard(
                          contract: contract,
                          onTap: () => _navigateToContractDetail(contract),
                          onDoubleTap: () => _navigateToContractDetail(contract),
                        );
                      },
                    )
                        : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: tabContracts.length,
                      itemBuilder: (context, index) {
                        final contract = tabContracts[index];
                        return ContractGridTile(
                          contract: contract,
                          onTap: () => _navigateToContractDetail(contract),
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

  Future<void> _loadTradingPoints() async {
    try {
      // Get user credentials
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();
      final userCode = prefs.getUserCode();

      if (userCode == null || userCode.isEmpty) {
        return;
      }

      final repository = sl<AgentRepository>();
      final allTradingPoints = await repository.getClients(
        userCode: userCode,
        password: prefs.getPassword() ?? '',
        forceRefresh: false,
      );

      // Filter trading points that have contracts
      final contractClientCodes = _contracts.map((c) => c.codeClient).toSet();
      final filteredTradingPoints = allTradingPoints
          .where((tp) => contractClientCodes.contains(tp.id))
          .toList();

      setState(() {
        _tradingPoints = filteredTradingPoints;
      });
    } catch (e) {
      // Log error but don't fail the entire page load
      if (kDebugMode) {
        print('Error loading trading points: $e');
      }
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initial = _filters.dateRange ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: initial,
      helpText: 'Sana oralig\'ini tanlang',
    );
    if (picked != null) {
      _onFiltersChanged(_filters.copyWith(dateRange: picked));
    }
  }


  void _navigateToContractDetail(ClientContractWithName contract) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractDetailPage(contract: contract),
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
        // Shartnomalar soni
        Text(
          'Shartnomalar soni: $count',
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

class ContractCard extends StatefulWidget {
  final ClientContractWithName contract;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const ContractCard({
    super.key,
    required this.contract,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  State<ContractCard> createState() => _ContractCardState();
}

class _ContractCardState extends State<ContractCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surface,
      child: InkWell(
        onTap: () {
          if (widget.onTap != null) {
            widget.onTap!();
          } else {
            setState(() => _isExpanded = !_isExpanded);
          }
        },
        onDoubleTap: widget.onDoubleTap,
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
                          widget.contract.codeContract,
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
                                'Mijoz: ${widget.contract.clientName ?? widget.contract.codeClient}',
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
                              'Boshlanish: ${widget.contract.dateOfContract != null ? DateFormat('dd.MM.yyyy').format(widget.contract.dateOfContract!) : 'Noma\'lum'}',
                              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.event_busy, size: 16, color: cs.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text(
                              'Tugash: ${widget.contract.termOfContract != null ? DateFormat('dd.MM.yyyy').format(widget.contract.termOfContract!) : 'Noma\'lum'}',
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
                        '${formatNumber(widget.contract.sumOfContract)} UZS',
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
                          color: widget.contract.active ? cs.primaryContainer : cs.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.contract.active ? 'Faol' : 'Faol emas',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: widget.contract.active ? cs.onPrimaryContainer : cs.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.contract.status, cs),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.contract.status,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getStatusTextColor(widget.contract.status, cs),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_isExpanded && widget.onTap == null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Qoshimcha ma\'lumotlar:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cheklangan sertifikat: ${widget.contract.certificateUnlimited == 1 ? 'Ha' : 'Yo\'q'}',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status, ColorScheme cs) {
    switch (status) {
      case 'Действует':
        return cs.primaryContainer;
      case 'Истек':
        return cs.errorContainer;
      case 'Не согласован':
        return cs.secondaryContainer;
      default:
        return cs.surfaceContainerHighest;
    }
  }

  Color _getStatusTextColor(String status, ColorScheme cs) {
    switch (status) {
      case 'Действует':
        return cs.onPrimaryContainer;
      case 'Истек':
        return cs.onErrorContainer;
      case 'Не согласован':
        return cs.onSecondaryContainer;
      default:
        return cs.onSurfaceVariant;
    }
  }
}

class ContractGridTile extends StatelessWidget {
  final ClientContractWithName contract;
  final VoidCallback? onTap;

  const ContractGridTile({
    super.key,
    required this.contract,
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
            // TOP: contract icon
            SizedBox(
              height: 100,
              child: Container(
                color: cs.primaryContainer,
                child: const Center(child: Icon(Icons.description, size: 40)),
              ),
            ),
            // BODY: details
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contract.codeContract,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mijoz: ${contract.clientName ?? contract.codeClient}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Summa: ${formatNumber(contract.sumOfContract)} UZS',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: contract.active ? cs.primaryContainer : cs.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          contract.active ? 'Faol' : 'Faol emas',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: contract.active ? cs.onPrimaryContainer : cs.onErrorContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(contract.status, cs),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            contract.status,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _getStatusTextColor(contract.status, cs),
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
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
    switch (status) {
      case 'Действует':
        return cs.primaryContainer;
      case 'Истек':
        return cs.errorContainer;
      case 'Не согласован':
        return cs.secondaryContainer;
      default:
        return cs.surfaceContainerHighest;
    }
  }

  Color _getStatusTextColor(String status, ColorScheme cs) {
    switch (status) {
      case 'Действует':
        return cs.onPrimaryContainer;
      case 'Истек':
        return cs.onErrorContainer;
      case 'Не согласован':
        return cs.onSecondaryContainer;
      default:
        return cs.onSurfaceVariant;
    }
  }
}