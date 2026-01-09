import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_config.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_orchestrator.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/client_balance_service.dart';
import 'package:gloria_marketing_flutter/src/core/utils/sync_helpers.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/group_sync_card.dart';

/// Tab page for data synchronization in Settings.
///
/// This page displays all sync groups with their tables and provides:
/// - "Sync All" button at the top
/// - ListView of GroupSyncCard widgets
/// - Pull-to-refresh to reload metadata
/// - Last global sync time
///
/// Usage:
/// ```dart
/// TabBarView(
///   children: [
///     PermissionsTab(),
///     MapsTab(),
///     DataSyncTab(), // NEW
///     InterfaceSettingsTab(),
///   ],
/// )
/// ```
class DataSyncTab extends StatefulWidget {
  const DataSyncTab({super.key});

  @override
  State<DataSyncTab> createState() => _DataSyncTabState();
}

class _DataSyncTabState extends State<DataSyncTab>
    with AutomaticKeepAliveClientMixin {
  late final DataSyncOrchestrator _orchestrator;
  late final ScrollController _scrollController;
  bool _isSyncingAll = false;
  bool _isRefreshingCounts = false;
  double _lastScrollPosition = 0.0;
  DateTime? _lastRefreshTime;
  
  // Background Sync Settings state
  bool _bgSyncEnabled = false;
  int _bgSyncInterval = 6;
  int? _bgSyncCustomMinutes;
  final TextEditingController _customMinutesController = TextEditingController();
  
  // Client Balance Cache state
  int _balanceCacheCount = 0;
  bool _isClearingBalanceCache = false;

  @override
  void initState() {
    super.initState();
    _orchestrator = sl<DataSyncOrchestrator>();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    // Auto-refresh metadata on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshMetadata();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _customMinutesController.dispose();
    super.dispose();
  }

  /// Handle scroll events to refresh record counts when scrolling down
  void _onScroll() {
    if (!mounted || _isRefreshingCounts || _isSyncingAll) return;

    final currentPosition = _scrollController.position.pixels;
    final isScrollingDown = currentPosition > _lastScrollPosition;
    _lastScrollPosition = currentPosition;

    // Only refresh when scrolling down and not refreshed recently
    if (isScrollingDown && _shouldRefreshCounts()) {
      _refreshRecordCountsOnly();
    }
  }

  /// Check if enough time has passed since last refresh (debounce)
  bool _shouldRefreshCounts() {
    if (_lastRefreshTime == null) return true;
    
    final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
    return timeSinceLastRefresh.inSeconds >= 3; // Refresh every 3 seconds max
  }

  /// Refresh only record counts without full metadata reload
  Future<void> _refreshRecordCountsOnly() async {
    if (_isRefreshingCounts) return;

    setState(() {
      _isRefreshingCounts = true;
      _lastRefreshTime = DateTime.now();
    });

    try {
      await _orchestrator.refreshRecordCounts();
      if (mounted) {
        setState(() {});
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingCounts = false;
        });
      }
    }
  }

  /// Refresh metadata from orchestrator
  Future<void> _refreshMetadata() async {
    // Both load from preferences and refresh row counts from DB
    await Future.wait([
      _orchestrator.loadMetadata(),
      _orchestrator.refreshRecordCounts(),
    ]);
    
    // Load background sync settings
    final prefs = sl<SharedPreferencesService>();
    _bgSyncEnabled = prefs.isBgSyncEnabled();
    _bgSyncInterval = prefs.getBgSyncInterval();
    _bgSyncCustomMinutes = prefs.getBgSyncCustomMinutes();
    
    if (_bgSyncCustomMinutes != null) {
      _customMinutesController.text = _bgSyncCustomMinutes.toString();
    }
    
    // Load balance cache count
    if (sl.isRegistered<ClientBalanceService>()) {
      _balanceCacheCount = await sl<ClientBalanceService>().getBalanceCount();
    }

    if (mounted) {
      setState(() {});
    }
  }
  
  /// Clear all client balance cache
  Future<void> _clearBalanceCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Balans keshini tozalash'),
          ],
        ),
        content: Text(
          'Barcha mijozlar balans ma\'lumotlari o\'chiriladi. '
          'Keyingi safar balans ko\'rilganda qayta yuklanadi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Tozalash', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isClearingBalanceCache = true);
    
    try {
      if (sl.isRegistered<ClientBalanceService>()) {
        await sl<ClientBalanceService>().clearAllBalances();
        _balanceCacheCount = 0;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Balans keshi tozalandi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClearingBalanceCache = false);
      }
    }
  }

  /// Toggle background sync
  Future<void> _onToggleBgSync(bool value) async {
    final prefs = sl<SharedPreferencesService>();
    await prefs.setBgSyncEnabled(value);
    
    final syncService = sl<DataSyncService>();
    await syncService.toggleBackgroundSync(value);
    
    setState(() {
      _bgSyncEnabled = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Background sync enabled' : 'Background sync disabled'),
        backgroundColor: value ? Colors.green : Colors.grey,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Update sync interval
  Future<void> _onIntervalChanged(int? value) async {
    if (value == null) return;
    
    final prefs = sl<SharedPreferencesService>();
    await prefs.setBgSyncInterval(value);
    
    if (_bgSyncEnabled) {
      final syncService = sl<DataSyncService>();
      await syncService.toggleBackgroundSync(true); // Re-register with new interval
    }
    
    setState(() {
      _bgSyncInterval = value;
    });
  }

  /// Update custom minutes
  Future<void> _onCustomMinutesSubmitted(String value) async {
    final minutes = int.tryParse(value);
    if (minutes != null && minutes < 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Minimum interval is 60 minutes'), backgroundColor: Colors.orange),
      );
      return;
    }

    final prefs = sl<SharedPreferencesService>();
    await prefs.setBgSyncCustomMinutes(minutes);
    
    if (_bgSyncEnabled) {
      final syncService = sl<DataSyncService>();
      await syncService.toggleBackgroundSync(true); // Re-register
    }
    
    setState(() {
      _bgSyncCustomMinutes = minutes;
    });
  }

  /// Sync all data
  Future<void> _syncAll() async {
    setState(() {
      _isSyncingAll = true;
    });

    try {
      await syncAllDataFromAnywhere(context);
      if (mounted) {
        setState(() {});
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncingAll = false;
        });
      }
    }
  }

  /// Calculate overall sync status
  _OverallStatus _calculateOverallStatus() {
    final allTables = DataSyncConfig.getAllTables();
    var syncedCount = 0;
    DateTime? latestSyncTime;

    for (final table in allTables) {
      final metadata = _orchestrator.getTableMetadata(table.id);
      if (metadata != null && metadata.lastSyncWasSuccessful) {
        syncedCount++;
        if (metadata.lastSyncTime != null) {
          if (latestSyncTime == null ||
              metadata.lastSyncTime!.isAfter(latestSyncTime)) {
            latestSyncTime = metadata.lastSyncTime;
          }
        }
      }
    }

    return _OverallStatus(
      syncedCount: syncedCount,
      totalCount: allTables.length,
      lastSyncTime: latestSyncTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<void>(
      future: _orchestrator.initialized,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing sync engine...'),
              ],
            ),
          );
        }

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final groups = DataSyncConfig.getAllGroups();
        final overallStatus = _calculateOverallStatus();

        return RefreshIndicator(
          onRefresh: _refreshMetadata,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Header with Sync All button
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.primaryContainer.withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Row(
                        children: [
                          Icon(
                            Icons.sync,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Data Synchronization',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

                      // Status info
                      Text(
                        '${overallStatus.syncedCount} of ${overallStatus.totalCount} tables synced',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      if (overallStatus.lastSyncTime != null) ...[
                        SizedBox(height: 4),
                        Text(
                          'Last sync: ${_getRelativeTime(overallStatus.lastSyncTime!)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                      ],

                      SizedBox(height: 16),

                      // Sync All button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: _isSyncingAll
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(Icons.sync, size: 20),
                          label: Text(
                            _isSyncingAll ? 'Syncing...' : 'Sync All Data',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isSyncingAll ? null : _syncAll,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 8),

                      // Info text
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'This will sync all tables in dependency order',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Groups section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.folder_open, color: colorScheme.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Data Groups',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${groups.length}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Group cards list
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final group = groups[index];
                    return GroupSyncCard(
                      group: group,
                      initiallyExpanded: index == 0, // Expand first group by default
                    );
                  },
                  childCount: groups.length,
                ),
              ),

              // Background sync settings
              SliverToBoxAdapter(
                child: _buildBackgroundSyncSettings(theme, colorScheme),
              ),

              // Balance cache management
              SliverToBoxAdapter(
                child: _buildBalanceCacheSettings(theme, colorScheme),
              ),

              // Bottom padding
              SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build balance cache management section
  Widget _buildBalanceCacheSettings(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: colorScheme.primary, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mijoz Balansi Keshi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$_balanceCacheCount ta mijoz balansi saqlangan',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Mijozlar balans ma\'lumotlari lokal keshda saqlanadi. '
            'Agar ma\'lumotlar eskirgan bo\'lsa, keshni tozalashingiz mumkin.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isClearingBalanceCache ? null : _clearBalanceCache,
              icon: _isClearingBalanceCache
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.delete_outline, color: Colors.red),
              label: Text(
                _isClearingBalanceCache ? 'Tozalanmoqda...' : 'Keshni tozalash',
                style: TextStyle(color: _isClearingBalanceCache ? null : Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.withOpacity(0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundSyncSettings(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_mode, color: colorScheme.primary, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Background Auto-Sync',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch(
                value: _bgSyncEnabled,
                onChanged: _onToggleBgSync,
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Keep your data fresh even when the app is closed. Requires internet connection.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (_bgSyncEnabled) ...[
            Divider(height: 32),
            Text(
              'Sync Interval',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _bgSyncInterval,
              decoration: InputDecoration(
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: [
                DropdownMenuItem(value: 1, child: Text('Every 1 hour')),
                DropdownMenuItem(value: 4, child: Text('Every 4 hours')),
                DropdownMenuItem(value: 6, child: Text('Every 6 hours')),
                DropdownMenuItem(value: 12, child: Text('Every 12 hours')),
                DropdownMenuItem(value: 24, child: Text('Daily (24h)')),
                DropdownMenuItem(value: 168, child: Text('Weekly (1 week)')),
              ],
              onChanged: _onIntervalChanged,
            ),
            SizedBox(height: 16),
            Text(
              'Custom Interval (Minutes)',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _customMinutesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Minimum 60 minutes',
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixText: 'min',
              ),
              onSubmitted: _onCustomMinutesSubmitted,
            ),
            SizedBox(height: 4),
            Text(
              '* Custom interval takes priority if set to 60 or more',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }


  /// Get relative time string
  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }

  @override
  bool get wantKeepAlive => true;
}

/// Overall sync status
class _OverallStatus {
  final int syncedCount;
  final int totalCount;
  final DateTime? lastSyncTime;

  _OverallStatus({
    required this.syncedCount,
    required this.totalCount,
    required this.lastSyncTime,
  });
}
