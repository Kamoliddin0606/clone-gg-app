// =============================
// presentation/pages/orders_page.dart
// =============================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../widgets/order_card.dart';
import '../widgets/order_card_grid.dart';
import '../widgets/order_models.dart';
import '../widgets/order_detail_sections.dart';
import '../widgets/order_items_card_view.dart';
import '../widgets/status_chip.dart';
import '../widgets/order_filters_panel.dart';
import '../shared/order_status_utils.dart';
import 'order_details_page.dart';
import '../../../../core/services/data_sync_service.dart';
import '../../../../core/services/shared_preferences_service.dart';
import '../../../agent/data/models/order.dart';
import '../../../agent/data/models/order_status.dart';
import '../../../agent/data/models/order_detail.dart';

class OrdersPage extends StatefulWidget {
  final String? initialClientFilter;
  final String? initialClientName;

  const OrdersPage({
    super.key,
    this.initialClientFilter,
    this.initialClientName,
  });

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with TickerProviderStateMixin {
  final TextEditingController _search = TextEditingController();
  bool _showFilters = false; // AppBar filter panel
  bool _showTuneRow = false; // the count + list/grid row under search
  bool _isGrid = false;
  bool _showStatusFilter = true; // Status filter row collapse/expand state

  // Dynamic status data
  List<String> _statusTabs = ['Barchasi'];
  Map<String, int?> _statusMap = {'Barchasi': null};
  List<OrderStatus> _orderStatuses = [];

  final OrdersFilterState _filters = OrdersFilterState();

  late List<Order> _allOrders; // original orders from server
  late List<OrderModel> _all; // original presentation models
  late List<OrderModel> _filtered; // view

  bool _isLoading = true;
  String? _error;

  // Connectivity and refresh state
  late Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  bool _isRefreshing = false;
  String? _refreshStatus;

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _search.addListener(_applyAllFilters);
    _scrollController.addListener(() {
      if (_showFilters) {
        setState(() => _showFilters = false);
      }
    });
    _initConnectivity();
    _loadOrderStatusesAndOrders();
  }

  @override
  void dispose() {
    _search.dispose();
    _scrollController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Initialize connectivity monitoring
  Future<void> _initConnectivity() async {
    _connectivity = Connectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    final result = await _connectivity.checkConnectivity();
    _isOnline = result.isNotEmpty && result.first != ConnectivityResult.none;
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.isNotEmpty && results.first != ConnectivityResult.none;
    
    if (mounted && wasOnline != _isOnline) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(_isOnline 
                ? (l10n?.connectionRestored ?? 'Connection restored')
                : (l10n?.youAreOffline ?? 'You are offline')),
            ],
          ),
          backgroundColor: _isOnline 
            ? Colors.green.shade600 
            : Colors.orange.shade700,
          duration: Duration(seconds: _isOnline ? 2 : 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  /// Handle pull-to-refresh with multi-tier loading
  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isRefreshing = true;
      _refreshStatus = l10n?.checkingCache ?? 'Checking cache...';
    });

    try {
      final dataSyncService = GetIt.I<DataSyncService>();
      
      // Tier 1: Try cache first
      final cachedOrders = await dataSyncService.getCachedOrders();
      if (cachedOrders.isNotEmpty) {
        _allOrders = cachedOrders;
        _all = _convertOrdersToOrderModels(_allOrders);
        _filtered = List.from(_all);
        _applyAllFilters();
        
        if (mounted) {
          setState(() {
            _isRefreshing = false;
            _refreshStatus = null;
          });
          _showFeedback(
            l10n?.dataLoadedFromCache ?? 'Data loaded from cache',
            Icons.cached_rounded,
            Colors.blue,
          );
        }
        return;
      }

      // Tier 2: Try database
      setState(() => _refreshStatus = l10n?.loadingFromDatabase ?? 'Loading from database...');
      
      final dbOrders = await dataSyncService.getCachedOrders();
      if (dbOrders.isNotEmpty) {
        _allOrders = dbOrders;
        _all = _convertOrdersToOrderModels(_allOrders);
        _filtered = List.from(_all);
        _applyAllFilters();
        
        if (mounted) {
          setState(() {
            _isRefreshing = false;
            _refreshStatus = null;
          });
          _showFeedback(
            l10n?.dataLoadedFromDatabase ?? 'Data loaded from database',
            Icons.storage_rounded,
            Colors.teal,
          );
        }
        return;
      }

      // Tier 3: Database is empty - prompt for server sync
      setState(() {
        _isRefreshing = false;
        _refreshStatus = null;
      });
      
      await _showSyncPromptSheet();
      
    } catch (e) {
      debugPrint('Error in refresh: $e');
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _refreshStatus = null;
        });
        _showFeedback(
          l10n?.syncFailed ?? 'Sync failed. Please try again.',
          Icons.error_outline_rounded,
          Colors.red,
        );
      }
    }
  }

  /// Show sync prompt bottom sheet when database is empty
  Future<void> _showSyncPromptSheet() async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    final shouldSync = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isOnline 
                  ? cs.primaryContainer.withOpacity(0.5)
                  : cs.errorContainer.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isOnline ? Icons.cloud_download_rounded : Icons.cloud_off_rounded,
                size: 48,
                color: _isOnline ? cs.primary : cs.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isOnline 
                ? (l10n?.databaseEmpty ?? 'No orders found locally')
                : (l10n?.noInternetForSync ?? 'No internet connection'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isOnline 
                ? (l10n?.databaseEmptyDescription ?? 'Would you like to sync orders from the server?')
                : (l10n?.noInternetForSync ?? 'Please check your network.'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(l10n?.cancel ?? 'Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _isOnline ? () => Navigator.pop(ctx, true) : null,
                    icon: Icon(_isOnline ? Icons.sync_rounded : Icons.wifi_off_rounded),
                    label: Text(
                      _isOnline 
                        ? (l10n?.syncFromServer ?? 'Sync from Server')
                        : (l10n?.retrySync ?? 'Retry'),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );

    if (shouldSync == true && mounted) {
      await _syncFromServer();
    }
  }

  /// Sync orders from server
  Future<void> _syncFromServer() async {
    final l10n = AppLocalizations.of(context);
    
    setState(() {
      _isRefreshing = true;
      _refreshStatus = l10n?.syncingFromServer ?? 'Syncing from server...';
    });

    try {
      final dataSyncService = GetIt.I<DataSyncService>();
      final userCode = await _getUserCode();
      
      if (userCode == null) {
        throw Exception('User code not found');
      }

      // Sync order statuses first
      await dataSyncService.syncOrderStatuses(userCode: userCode, forceRefresh: true);
      await _loadOrderStatuses();

      // Sync orders
      final freshOrders = await dataSyncService.syncOrders(
        userCode: userCode,
        forceRefresh: true,
      );
      
      _allOrders = freshOrders;
      _all = _convertOrdersToOrderModels(_allOrders);
      _filtered = List.from(_all);
      _applyAllFilters();

      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _refreshStatus = null;
        });
        _showFeedback(
          l10n?.dataSyncedFromServer ?? 'Orders synced successfully',
          Icons.cloud_done_rounded,
          Colors.green,
        );
      }
    } catch (e) {
      debugPrint('Error syncing from server: $e');
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _refreshStatus = null;
        });
        _showFeedback(
          l10n?.syncFailed ?? 'Sync failed. Please try again.',
          Icons.error_outline_rounded,
          Colors.red,
        );
      }
    }
  }

  /// Show feedback snackbar
  void _showFeedback(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleFilters() {
    setState(() => _showFilters = !_showFilters);
  }

  void _toggleTune() {
    setState(() => _showTuneRow = !_showTuneRow);
  }

  void _toggleStatusFilter() {
    setState(() => _showStatusFilter = !_showStatusFilter);
  }

  void _switchToList() {
    setState(() => _isGrid = false);
  }

  void _switchToGrid() {
    setState(() => _isGrid = true);
  }

  void _onFiltersChanged(OrdersFilterState s) {
    setState(() {
      _filters.statuses = s.statuses;
      _filters.clients = s.clients;
      _filters.range = s.range;
    });
    _applyAllFilters();
  }

  /// Load order statuses and orders with cache-first approach
  Future<void> _loadOrderStatusesAndOrders() async {
    try {
      setState(() => _isLoading = true);

      // Load order statuses first
      await _loadOrderStatuses();

      // Load orders with cache-first approach
      await _loadOrders();

      // Ma'lumotlar yuklangandan keyin initial filter qo'llash
      if (widget.initialClientFilter != null &&
          widget.initialClientName != null) {
        _applyInitialClientFilter();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Load order statuses from cache or server
  Future<void> _loadOrderStatuses() async {
    try {
      final dataSyncService = GetIt.I<DataSyncService>();
      final cachedStatuses = await dataSyncService.getCachedOrderStatuses();

      if (cachedStatuses.isNotEmpty) {
        _orderStatuses = cachedStatuses;
        _buildStatusTabsAndMap();
        return;
      }

      // If no cache, fetch from server
      final userCode = await _getUserCode();
      if (userCode != null) {
        final freshStatuses = await dataSyncService.syncOrderStatuses(
          userCode: userCode,
        );
        _orderStatuses = freshStatuses;
        _buildStatusTabsAndMap();
      }
    } catch (e) {
      debugPrint('Error loading order statuses: $e');
      // Fallback to default statuses
      _buildDefaultStatusTabsAndMap();
    }
  }

  /// Load orders with cache-first approach
  Future<void> _loadOrders() async {
    try {
      final dataSyncService = GetIt.I<DataSyncService>();

      // Try to get cached orders first
      final cachedOrders = await dataSyncService.getCachedOrders();
      if (cachedOrders.isNotEmpty) {
        _allOrders = cachedOrders;
        _all = _convertOrdersToOrderModels(_allOrders);
        _filtered = List.from(_all);
        return;
      }

      // If no cache, fetch from server
      final userCode = await _getUserCode();
      if (userCode != null) {
        final freshOrders = await dataSyncService.syncOrders(
          userCode: userCode,
        );
        _allOrders = freshOrders;
        _all = _convertOrdersToOrderModels(_allOrders);
        _filtered = List.from(_all);
      } else {
        // Fallback to demo data if no user code
        _all = _demoOrders();
        _filtered = List.from(_all);
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
      // Fallback to demo data
      _all = _demoOrders();
      _filtered = List.from(_all);
    }
  }

  /// Build status tabs and map from order statuses
  void _buildStatusTabsAndMap() {
    _statusTabs = ['Barchasi'];
    _statusMap = {'Barchasi': null};

    for (final status in _orderStatuses) {
      if (status.id != null) {
        _statusTabs.add(status.message);
        _statusMap[status.message] = status.id;
      }
    }
  }

  /// Build default status tabs and map (fallback)
  void _buildDefaultStatusTabsAndMap() {
    final l10n = AppLocalizations.of(context);
    _statusTabs = [
      l10n?.all ?? 'Barchasi',
      l10n?.orderStatusDelivered ?? 'Доставлено',
      l10n?.orderStatusInProcess ?? 'В процессе',
      l10n?.orderStatusReturn ?? 'Возврат',
      l10n?.orderStatusExpired ?? 'Истек',
    ];
    _statusMap = {
      l10n?.all ?? 'Barchasi': null,
      l10n?.orderStatusDelivered ?? 'Доставлено': 4,
      l10n?.orderStatusInProcess ?? 'В процессе': 2,
      l10n?.orderStatusReturn ?? 'Возврат': 7,
      l10n?.orderStatusExpired ?? 'Истек': 6,
    };
  }

  /// Convert Order list to OrderModel list for presentation
  List<OrderModel> _convertOrdersToOrderModels(List<Order> orders) {
    return orders
        .map(
          (order) => OrderModel(
            id: order.id,
            numOrder: order.numOrder,
            dateOrder: order.dateOrder,
            captionOrder: order.captionOrder,
            typePriceCode: order.typePriceCode,
            status: order.status,
            commentSupervisor: order.commentSupervisor,
            commentForwarder: order.commentForwarder,
            commentAgent: order.commentAgent,
            total: order.total,
            clientCode: order.clientCode,
            clientName: order.clientName,
            codeOrg: order.codeOrg,
            mainStatus: order.mainStatus,
            courierName: order.courierName,
            courierCar: order.courierCar,
            courierPlate:
                order.courierCar, // Assuming courierCar contains plate info
            items: const [], // Items will be loaded separately if needed
          ),
        )
        .toList();
  }

  /// Get user code from shared preferences
  Future<String?> _getUserCode() async {
    try {
      final prefs = GetIt.I<SharedPreferencesService>();
      return prefs.getUserCode();
    } catch (e) {
      debugPrint('Error getting user code: $e');
      return null;
    }
  }

  /// Apply initial client filter when navigating from Trading Points page
  void _applyInitialClientFilter() {
    try {
      if (widget.initialClientName == null) return;

      setState(() {
        _filters.clients = {widget.initialClientName!};
        _showFilters = false; // Filter panelini yopish (faqat avtomatik filter)
      });

      // Endi ma'lumotlar yuklangan, filter qo'llash mumkin
      _applyAllFilters();

      // Foydalanuvchiga bildirish
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                    context,
                  )?.clientOrders(widget.initialClientName ?? '') ??
                  '${widget.initialClientName} mijozining buyurtmalari',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      if (kDebugMode) {
        print('Applied initial client filter: ${widget.initialClientName}');
        print(
          'Filter state: clients=${_filters.clients}, filtered count: ${_filtered.length}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error applying initial client filter: $e');
      }
      // Agar xatolik yuz bersa, filter qo'llanmasdan davom etish
    }
  }

  void _applyAllFilters() {
    final String q = _normalize(_search.text);

    setState(() {
      _filtered = _all.where((o) {
        final matchStatusMulti = _filters.statuses.isEmpty
            ? true
            : _filters.statuses.contains(_statusMap[o.mainStatus]);
        final matchDate = _filters.range == null
            ? true
            : (o.dateOrder.isAfter(
                    _filters.range!.start.subtract(const Duration(seconds: 1)),
                  ) &&
                  o.dateOrder.isBefore(
                    _filters.range!.end.add(const Duration(seconds: 1)),
                  ));
        final matchClient = _filters.clients.isEmpty
            ? true
            : _filters.clients.contains(o.clientName);
        if (kDebugMode) print('order main status : ${o.mainStatus}');
        final text = _normalize(
          [
            o.numOrder,
            o.clientName,
            o.captionOrder,
            o.clientCode,
            o.codeOrg,
            statusText(o.mainStatus, context),
            NumberFormat('#,##0').format(o.total),
          ].join(' '),
        );
        final matchSearch = q.isEmpty ? true : text.contains(q);

        return matchStatusMulti && matchDate && matchClient && matchSearch;
      }).toList();
    });
  }

  void _toggleStatus(int? statusId) {
    // statusId == null means "All".
    if (statusId == null) {
      _onFiltersChanged(
        OrdersFilterState(
          statuses: {},
          clients: _filters.clients,
          range: _filters.range,
        ),
      );
      return;
    }

    final ns = {..._filters.statuses};
    if (ns.contains(statusId)) {
      ns.remove(statusId);
    } else {
      ns.add(statusId);
    }
    _onFiltersChanged(
      OrdersFilterState(statuses: ns, clients: _filters.clients, range: _filters.range),
    );
  }

  Future<void> _pickClients(List<String> clients) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final selected = {..._filters.clients};
    final search = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final q = search.text.trim().toLowerCase();
            final filtered = q.isEmpty
                ? clients
                : clients.where((c) => c.toLowerCase().contains(q)).toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.85,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.labelClients,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() => selected.clear());
                          },
                          child: Text(l10n.clear),
                        ),
                        const SizedBox(width: 6),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                          },
                          child: Text(l10n.ok),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: search,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintText: l10n.searchHint,
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withOpacity(0.6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filtered.length + 1,
                      separatorBuilder: (_, __) => Divider(height: 1, color: cs.outlineVariant.withOpacity(0.25)),
                      itemBuilder: (ctx, i) {
                        if (i == 0) {
                          final allSelected = selected.isEmpty;
                          return CheckboxListTile(
                            value: allSelected,
                            onChanged: (_) {
                              setModalState(() => selected.clear());
                            },
                            title: Text(l10n.all),
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        }

                        final name = filtered[i - 1];
                        final isChecked = selected.contains(name);
                        return CheckboxListTile(
                          value: isChecked,
                          onChanged: (v) {
                            setModalState(() {
                              if (v == true) {
                                selected.add(name);
                              } else {
                                selected.remove(name);
                              }
                            });
                          },
                          title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    _onFiltersChanged(
      OrdersFilterState(statuses: _filters.statuses, clients: selected, range: _filters.range),
    );
  }

  String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r"\s+"), " ")
        .trim(); /* TODO: add cyr/latin transliteration */
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initial =
        _filters.range ??
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: initial,
      helpText:
          AppLocalizations.of(context)?.selectDateRange ??
          'Sana oralig\'ini tanlang',
    );
    if (picked != null) {
      _onFiltersChanged(
        OrdersFilterState(
          statuses: _filters.statuses,
          clients: _filters.clients,
          range: picked,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final clients =
        _isLoading ? [] : _all.map((e) => e.clientName).toSet().toList()
          ..sort();

    if (_isLoading) {
      return Scaffold(
        backgroundColor: cs.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)?.orders ?? 'Orders',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: cs.surface,
          leading: (ModalRoute.of(context)?.canPop ?? false)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.maybePop(context),
                )
              : null,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)?.loading ?? 'Yuklanmoqda...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: cs.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)?.orders ?? 'Orders',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: cs.surface,
          leading: (ModalRoute.of(context)?.canPop ?? false)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.maybePop(context),
                )
              : null,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: cs.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)?.errorOccurredTitle ??
                      'Xatolik yuz berdi',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _loadOrderStatusesAndOrders,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    AppLocalizations.of(context)?.retry ??
                        'Qayta urinib ko\'ring',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
        backgroundColor: cs.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)?.orders ?? 'Orders',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: cs.surface,
          leading: (ModalRoute.of(context)?.canPop ?? false)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.maybePop(context),
                )
              : null,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _showFilters
                    ? cs.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.filter_alt_rounded,
                  color: _showFilters ? cs.primary : cs.onSurface,
                ),
                onPressed: _toggleFilters,
                tooltip: AppLocalizations.of(context)?.filterTooltip ?? 'Filter',
              ),
            ),
          ],
        ),
        body: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            final theme = Theme.of(context);
            
            return Column(
              children: [
                // Status multi-select chips (collapsible)
                ClipRect(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: _showStatusFilter ? null : 0,
                    color: cs.surface,
                    child: _showStatusFilter
                        ? Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l10n.status,
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.keyboard_arrow_up_rounded,
                                      color: cs.onSurfaceVariant,
                                      size: 20,
                                    ),
                                    onPressed: _toggleStatusFilter,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  FilterChip(
                                    label: Text(l10n.all),
                                    selected: _filters.statuses.isEmpty,
                                    onSelected: (_) => _toggleStatus(null),
                                  ),
                                  for (final s in _orderStatuses)
                                    if (s.id != null)
                                      FilterChip(
                                        label: Text(statusText(s.message, context)),
                                        selected: _filters.statuses.contains(s.id),
                                        onSelected: (_) => _toggleStatus(s.id),
                                      ),
                                ],
                              ),
                            ),
                          ],
                        )
                        : null,
                  ),
                ),
                // Collapsed state indicator
                if (!_showStatusFilter)
                  InkWell(
                    onTap: _toggleStatusFilter,
                    child: Container(
                      color: cs.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_alt_rounded,
                            size: 16,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.status,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_filters.statuses.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_filters.statuses.length}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: cs.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
            // Modern Search + tune icon
            Container(
              color: cs.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded, color: cs.primary),
                        hintText:
                            AppLocalizations.of(context)?.searchHint ??
                            'Qidirish...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: cs.outlineVariant.withOpacity(0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: cs.outlineVariant.withOpacity(0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: cs.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: _showTuneRow
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      onPressed: _toggleTune,
                      icon: Icon(
                        Icons.tune_rounded,
                        color: _showTuneRow ? cs.primary : cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Modern Tune row
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _showTuneRow
                  ? Container(
                      color: cs.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  size: 18,
                                  color: cs.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_filtered.length}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: cs.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'List',
                                  onPressed: _switchToList,
                                  icon: Icon(
                                    Icons.view_agenda_rounded,
                                    color: !_isGrid ? cs.primary : cs.outline,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Grid',
                                  onPressed: _switchToGrid,
                                  icon: Icon(
                                    Icons.grid_view_rounded,
                                    color: _isGrid ? cs.primary : cs.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _toggleTune,
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // Filters panel
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _showFilters
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: OrdersFiltersPanel(
                        state: _filters,
                        onChange: _onFiltersChanged,
                        onPickDateRange: _pickDateRange,
                        onClearDateRange: () => _onFiltersChanged(
                          OrdersFilterState(
                            statuses: _filters.statuses,
                            clients: _filters.clients,
                            range: null,
                          ),
                        ),
                        onPickClients: () => _pickClients(clients.cast<String>()),
                        onClearClients: () => _onFiltersChanged(
                          OrdersFilterState(
                            statuses: _filters.statuses,
                            clients: {},
                            range: _filters.range,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // Refresh status indicator
            if (_isRefreshing && _refreshStatus != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: cs.primaryContainer.withOpacity(0.3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _refreshStatus!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            // Content with pull-to-refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: cs.primary,
                backgroundColor: cs.surface,
                strokeWidth: 3,
                displacement: 40,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.02),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _isGrid
                      ? Padding(
                          key: const ValueKey('grid'),
                          padding: const EdgeInsets.all(8),
                          child: GridView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.7,
                                ),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final o = _filtered[i];
                              return OrderCardGrid(
                                order: o,
                                onTap: () => _openBottomSheet(context, o),
                                onDoubleTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OrderDetailsPage(order: o),
                                  ),
                                ).then((_) {
                                  // Refresh list after returning from details
                                  setState(() {});
                                }),
                              );
                            },
                          ),
                        )
                      : ListView.builder(
                          key: const ValueKey('list'),
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final o = _filtered[i];
                            return OrderCard(
                              order: o,
                              onTap: () => _openBottomSheet(context, o),
                              onDoubleTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OrderDetailsPage(order: o),
                                ),
                              ).then((_) {
                                // Refresh list after returning from details
                                setState(() {});
                              }),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
          );
        },
      ),
    );
  }

  Future<void> _openBottomSheet(BuildContext context, OrderModel order) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) => _OrderBottomSheet(order: order),
    );
  }

  // ------- demo data ---------------------------------------------------------
  List<OrderModel> _demoOrders() {
    final now = DateTime.now();
    final list = <OrderModel>[];
    final clients = [
      'MAYRAM - ONAXON YATT',
      'LAYLO FAYZ BARAKA',
      'KYUT SAMARA OOO',
      'ALMO TRADING LLC',
      'BARAKA OPT',
      'FERGANA OIL',
    ];
    for (int i = 0; i < 20; i++) {
      final st = [1, 2, 2, 4, 6, 5][i % 6];
      list.add(
        OrderModel(
          id: i + 1,
          numOrder: 'GL00-${160000 + i}',
          dateOrder: now.subtract(Duration(minutes: i * 17)),
          captionOrder: 'Zakaz ${i + 1}',
          typePriceCode: 'R',
          status: st,
          total: (150000 + i * 12000).toDouble(),
          clientCode: '00-000${5000 + i}',
          clientName: clients[i % clients.length],
          codeOrg: '00000000001',
          mainStatus: statusText(st.toString()),
          items: const [
            OrderItem(
              productName: 'Shampoo X',
              article: 'SHX-250',
              quantity: 10,
              price: 25000,
              priceType: 'Retail',
            ),
            OrderItem(
              productName: 'Soap Y',
              article: 'SPY-100',
              quantity: 24,
              price: 9000,
              priceType: 'Retail',
            ),
          ],
        ),
      );
    }
    return list;
  }
}

/// Bottom sheet widget for order details with data loading
class _OrderBottomSheet extends StatefulWidget {
  final OrderModel order;
  
  const _OrderBottomSheet({required this.order});
  
  @override
  State<_OrderBottomSheet> createState() => _OrderBottomSheetState();
}

class _OrderBottomSheetState extends State<_OrderBottomSheet> {
  bool _isLoading = false;
  OrderModel? _detailedOrder;
  
  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }
  
  Future<void> _loadOrderDetails() async {
    setState(() => _isLoading = true);
    
    try {
      final dataSyncService = GetIt.I<DataSyncService>();
      final prefs = GetIt.I<SharedPreferencesService>();
      
      // Try cache first
      final cachedOrderDetail = await dataSyncService
          .getCachedOrderDetailByNumOrder(widget.order.numOrder);
      
      if (cachedOrderDetail != null) {
        _detailedOrder = _convertOrderDetailToOrderModel(
          cachedOrderDetail,
          widget.order,
        );
        setState(() => _isLoading = false);
        return;
      }
      
      // Load from server
      final userCode = prefs.getUserCode();
      if (userCode != null) {
        final orderDate = widget.order.dateOrder.toIso8601String().split('T')[0];
        final freshOrderDetail = await dataSyncService.syncOrderDetails(
          numberOrder: widget.order.numOrder,
          orderDate1: orderDate,
          orderDate2: orderDate,
          forceRefresh: false,
        );
        
        _detailedOrder = _convertOrderDetailToOrderModel(
          freshOrderDetail,
          widget.order,
        );
      } else {
        _detailedOrder = widget.order;
      }
    } catch (e) {
      debugPrint('Error loading order details in bottom sheet: $e');
      _detailedOrder = widget.order;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  OrderModel _convertOrderDetailToOrderModel(
    OrderDetail orderDetail,
    OrderModel originalOrder,
  ) {
    try {
      if (orderDetail.productRows.isEmpty) {
        return originalOrder.copyWith(items: []);
      }
      
      final items = <OrderItem>[];
      for (final product in orderDetail.productRows) {
        final codeProduct = product.codeProduct.trim();
        if (codeProduct.isEmpty) continue;
        
        try {
          final orderItem = OrderItem(
            productName: product.nameProduct.trim().isNotEmpty
                ? product.nameProduct.trim()
                : 'Noma\'lum mahsulot',
            article: codeProduct,
            quantity: product.amount.toDouble(),
            price: product.price,
            priceType: originalOrder.typePriceCode,
          );
          items.add(orderItem);
        } catch (e) {
          debugPrint('Error converting product: $e');
        }
      }
      
      return OrderModel(
        id: originalOrder.id,
        numOrder: originalOrder.numOrder,
        dateOrder: originalOrder.dateOrder,
        captionOrder: originalOrder.captionOrder,
        typePriceCode: originalOrder.typePriceCode,
        status: originalOrder.status,
        commentSupervisor: orderDetail.commentSupervisor,
        commentForwarder: orderDetail.commentForwarder,
        commentAgent: orderDetail.commentAgent,
        total: originalOrder.total,
        clientCode: originalOrder.clientCode,
        clientName: originalOrder.clientName,
        codeOrg: originalOrder.codeOrg,
        mainStatus: originalOrder.mainStatus,
        courierName: originalOrder.courierName,
        courierCar: originalOrder.courierCar,
        courierPlate: originalOrder.courierPlate,
        items: items,
      );
    } catch (e) {
      debugPrint('Error converting OrderDetail: $e');
      return originalOrder.copyWith(items: []);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final order = _detailedOrder ?? widget.order;
    
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: cs.outlineVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: cs.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)?.orderNumberLabel ??
                                'Buyurtma raqami',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.numOrder,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isLoading)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      StatusChip(status: order.mainStatus),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: cs.outlineVariant.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  indicatorWeight: 3,
                  labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: [
                    Tab(
                      icon: Icon(Icons.info_outline_rounded, size: 18),
                      text: AppLocalizations.of(context)?.main ?? 'Asosiy',
                    ),
                    Tab(
                      icon: Icon(Icons.inventory_2_outlined, size: 18),
                      text: AppLocalizations.of(context)?.contents ?? 'Tarkibi',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    OrderDetailsSection(
                      order: order,
                      controller: controller,
                    ),
                    OrderItemsCardView(order: order, controller: controller),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
