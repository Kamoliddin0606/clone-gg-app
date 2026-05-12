import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_config.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_orchestrator.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/client_balance_service.dart';
import 'package:gloria_marketing_flutter/src/core/utils/sync_helpers.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/backend_permissions_sync_card.dart';
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
  int _selectedMinutes = 360; // Default 6 hours in minutes
  final TextEditingController _customMinutesController =
      TextEditingController();
  bool _isCustomMinutes = false;

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
    
    // Load saved interval in minutes
    final customMinutes = prefs.getBgSyncCustomMinutes();
    final intervalHours = prefs.getBgSyncInterval();
    
    if (customMinutes != null && customMinutes >= 15) {
      _selectedMinutes = customMinutes;
      _isCustomMinutes = !_predefinedMinutes.contains(customMinutes);
      if (_isCustomMinutes) {
        _customMinutesController.text = customMinutes.toString();
      }
    } else {
      _selectedMinutes = intervalHours * 60;
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
            Text(AppLocalizations.of(context)?.clearCache ?? 'Keshni tozalash'),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)?.clearBalanceCacheConfirm ??
              'Barcha mijozlar balans ma\'lumotlari o\'chiriladi. Keyingi safar balans ko\'rilganda qayta yuklanadi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              AppLocalizations.of(context)?.clear ?? 'Tozalash',
              style: const TextStyle(color: Colors.white),
            ),
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
              content: Text(
                AppLocalizations.of(context)?.balanceCacheCleared ??
                    'Balans keshi tozalandi',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.errorOccurredPrefix ?? 'Xatolik'}: $e',
            ),
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
        content: Text(
          value
              ? (AppLocalizations.of(context)?.backgroundSyncEnabled ??
                    'Background sync enabled')
              : (AppLocalizations.of(context)?.backgroundSyncDisabled ??
                    'Background sync disabled'),
        ),
        backgroundColor: value ? Colors.green : Colors.grey,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Predefined interval options in minutes
  static const List<int> _predefinedMinutes = [15, 30, 60, 120, 240, 360, 720, 1440];
  
  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '$minutes daqiqa';
    } else if (minutes < 1440) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours soat';
      }
      return '$hours soat $remainingMinutes daqiqa';
    } else {
      final days = minutes ~/ 1440;
      return '$days kun';
    }
  }

  /// Update sync interval from predefined options
  Future<void> _onIntervalChanged(int? minutes) async {
    if (minutes == null) return;

    final prefs = sl<SharedPreferencesService>();
    await prefs.setBgSyncCustomMinutes(minutes);
    await prefs.setBgSyncInterval(minutes ~/ 60); // Also save in hours for backward compatibility

    if (_bgSyncEnabled) {
      final syncService = sl<DataSyncService>();
      await syncService.toggleBackgroundSync(true);
    }

    setState(() {
      _selectedMinutes = minutes;
      _isCustomMinutes = false;
      _customMinutesController.clear();
    });
    
    _showIntervalUpdatedSnackbar(minutes);
  }

  /// Update custom minutes from text field
  Future<void> _onCustomMinutesSubmitted(String value) async {
    final minutes = int.tryParse(value);
    if (minutes == null || minutes < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.minimumIntervalIs60 ??
                'Minimum interval 15 daqiqa',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final prefs = sl<SharedPreferencesService>();
    await prefs.setBgSyncCustomMinutes(minutes);
    await prefs.setBgSyncInterval(minutes ~/ 60);

    if (_bgSyncEnabled) {
      final syncService = sl<DataSyncService>();
      await syncService.toggleBackgroundSync(true);
    }

    setState(() {
      _selectedMinutes = minutes;
      _isCustomMinutes = true;
    });
    
    _showIntervalUpdatedSnackbar(minutes);
  }
  
  void _showIntervalUpdatedSnackbar(int minutes) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sinxronizatsiya intervali: ${_formatMinutes(minutes)}',
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)?.initializingSyncEngine ??
                      'Initializing sync engine...',
                ),
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
                              AppLocalizations.of(
                                    context,
                                  )?.dataSynchronization ??
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
                        AppLocalizations.of(context)?.tablesSynced(
                              overallStatus.syncedCount,
                              overallStatus.totalCount,
                            ) ??
                            '${overallStatus.syncedCount} of ${overallStatus.totalCount} tables synced',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      if (overallStatus.lastSyncTime != null) ...[
                        SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)?.lastSync(
                                _getRelativeTime(overallStatus.lastSyncTime!),
                              ) ??
                              'Last sync: ${_getRelativeTime(overallStatus.lastSyncTime!)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer.withOpacity(
                              0.8,
                            ),
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
                            _isSyncingAll
                                ? (AppLocalizations.of(context)?.syncing ??
                                      'Syncing...')
                                : (AppLocalizations.of(context)?.syncAllData ??
                                      'Sync All Data'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
                            color: colorScheme.onPrimaryContainer.withOpacity(
                              0.7,
                            ),
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(
                                    context,
                                  )?.syncAllTablesInOrder ??
                                  'This will sync all tables in dependency order',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onPrimaryContainer
                                    .withOpacity(0.7),
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
                      Icon(
                        Icons.folder_open,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)?.dataGroups ??
                            'Data Groups',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
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

              // Backend (V2) permissions sync — distinct item that
              // does not flow through the orchestrator (it syncs
              // implicitly on login / token refresh). Surfaces the
              // last sync time, granted count, and any failure event
              // so the user has a single place to confirm the
              // codename gate state.
              const SliverToBoxAdapter(
                child: BackendPermissionsSyncCard(),
              ),

              // Group cards list
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final group = groups[index];
                  return GroupSyncCard(
                    group: group,
                    initiallyExpanded:
                        index == 0, // Expand first group by default
                  );
                }, childCount: groups.length),
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
              SliverToBoxAdapter(child: SizedBox(height: 32)),
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
              Icon(
                Icons.account_balance_wallet_outlined,
                color: colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.clientBalanceCache ??
                          'Mijoz Balansi Keshi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(
                            context,
                          )?.clientBalancesCached(_balanceCacheCount) ??
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
            AppLocalizations.of(context)?.balanceCacheDescription ??
                'Mijozlar balans ma\'lumotlari lokal keshda saqlanadi. Agar ma\'lumotlar eskirgan bo\'lsa, keshni tozalashingiz mumkin.',
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
                _isClearingBalanceCache
                    ? (AppLocalizations.of(context)?.clearing ??
                          'Tozalanmoqda...')
                    : (AppLocalizations.of(context)?.clearCache ??
                          'Keshni tozalash'),
                style: TextStyle(
                  color: _isClearingBalanceCache ? null : Colors.red,
                ),
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

  Widget _buildBackgroundSyncSettings(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
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
                  AppLocalizations.of(context)?.backgroundAutoSync ??
                      'Avto Sinxronizatsiya',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch(value: _bgSyncEnabled, onChanged: _onToggleBgSync),
            ],
          ),
          SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.backgroundSyncDescription ??
                'Ilova yopiq bo\'lganda ham ma\'lumotlarni yangilab turadi. Internet talab qilinadi.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (_bgSyncEnabled) ...[
            Divider(height: 32),
            
            // Current interval display
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: colorScheme.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Joriy interval: ',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    _formatMinutes(_selectedMinutes),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            Text(
              'Taklif qilingan intervallar',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            // Predefined interval chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _predefinedMinutes.map((minutes) {
                final isSelected = _selectedMinutes == minutes && !_isCustomMinutes;
                return ChoiceChip(
                  label: Text(_formatMinutes(minutes)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      _onIntervalChanged(minutes);
                    }
                  },
                  selectedColor: colorScheme.primaryContainer,
                  backgroundColor: colorScheme.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            
            SizedBox(height: 20),
            Text(
              'Yoki qo\'lda kiriting (daqiqa)',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customMinutesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Masalan: 45, 90, 180...',
                      filled: true,
                      fillColor: colorScheme.surface,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.edit, size: 20),
                      suffixText: 'daq',
                    ),
                    onSubmitted: _onCustomMinutesSubmitted,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_customMinutesController.text.isNotEmpty) {
                      _onCustomMinutesSubmitted(_customMinutesController.text);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: Text('Saqlash'),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '* Minimum 15 daqiqa (Android WorkManager cheklovi)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (_isCustomMinutes) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Maxsus interval ishlatilmoqda: ${_formatMinutes(_selectedMinutes)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
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
