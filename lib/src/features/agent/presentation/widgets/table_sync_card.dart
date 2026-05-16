import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/models/data_sync_table.dart';
import 'package:gloria_marketing_flutter/src/core/models/sync_table_metadata.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_orchestrator.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/utils/sync_helpers.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/shared/active_project_guard.dart';

/// Card widget displaying sync status and controls for a single table.
///
/// This widget shows:
/// - Table name and icon
/// - Last sync time
/// - Record count
/// - Sync status (success/error/syncing)
/// - Refresh button with dropdown menu for sync modes
/// - (Optional) Expandable dependency list
///
/// Example usage:
/// ```dart
/// TableSyncCard(
///   table: DataSyncConfig.getTable('products')!,
///   onSyncComplete: () => refreshParentState(),
/// )
/// ```
class TableSyncCard extends StatefulWidget {
  /// The table configuration to display
  final DataSyncTable table;

  /// Whether to show dependency information
  final bool showDependencies;

  /// Whether this card is compact (used inside group card)
  final bool isCompact;

  /// Callback invoked when sync completes (success or failure)
  /// Used to notify parent widgets to refresh their state
  final VoidCallback? onSyncComplete;

  const TableSyncCard({
    super.key,
    required this.table,
    this.showDependencies = false,
    this.isCompact = false,
    this.onSyncComplete,
  });

  @override
  State<TableSyncCard> createState() => _TableSyncCardState();
}

class _TableSyncCardState extends State<TableSyncCard> {
  late final DataSyncOrchestrator _orchestrator;
  SyncTableMetadata? _metadata;
  bool _isExpanded = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _orchestrator = sl<DataSyncOrchestrator>();
    _loadMetadata();
  }

  /// Load metadata from orchestrator cache
  void _loadMetadata() {
    if (!mounted) return;
    setState(() {
      _metadata = _orchestrator.getTableMetadata(widget.table.id);
    });
  }

  /// Refresh metadata from orchestrator (async reload)
  Future<void> _refreshMetadata() async {
    await _orchestrator.loadMetadata();
    await _orchestrator.refreshRecordCounts();
    _loadMetadata();
  }

  /// Show sync mode selection menu
  Future<void> _showSyncModeMenu(BuildContext context) async {
    final mode = await showMenu<SyncMode>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 200,
        100,
        20,
        0,
      ),
      items: [
        PopupMenuItem(
          value: SyncMode.withCascade,
          child: ListTile(
            leading: Icon(Icons.sync, size: 20),
            title: Builder(
              builder: (ctx) => Text(AppLocalizations.of(ctx)?.syncWithDependencies ?? 'Sync with dependencies'),
            ),
            subtitle: Builder(
              builder: (ctx) => Text(AppLocalizations.of(ctx)?.recommended ?? 'Recommended', style: TextStyle(fontSize: 11)),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: SyncMode.tableOnly,
          child: ListTile(
            leading: Icon(Icons.sync_disabled, size: 20),
            title: Builder(
              builder: (ctx) => Text(AppLocalizations.of(ctx)?.syncTableOnly ?? 'Sync table only'),
            ),
            subtitle: Builder(
              builder: (ctx) => Text(AppLocalizations.of(ctx)?.syncWarning ?? 'May fail if dependencies not synced',
                  style: TextStyle(fontSize: 11)),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );

    if (mode != null && mounted) {
      await _performSync(mode);
    }
  }

  /// Perform sync with selected mode.
  /// 
  /// This method:
  /// 1. Sets syncing state to show loading indicator
  /// 2. Calls syncTableFromAnywhere with forceResync=true
  /// 3. Always refreshes metadata after sync
  /// 4. Updates UI state regardless of success or failure
  /// 5. Notifies parent via callback if provided
  Future<void> _performSync(SyncMode mode) async {
    if (_isSyncing) return; // Prevent double sync

    // Guard rail: per-table sync still goes through the orchestrator
    // and dependencies, all of which need an active project in
    // project-scope tenants. Block at the entry point and let the
    // shared helper surface the "pick a project" snackbar.
    if (!await ensureActiveProject(context)) return;
    if (!mounted) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      // Force resync is enabled by default in syncTableFromAnywhere
      // This ensures tables are re-synced even if previously successful
      if (!mounted) return;
      await syncTableFromAnywhere(
        context,
        widget.table.id,
        withCascade: mode == SyncMode.withCascade,
        withDependencies: mode != SyncMode.tableOnly,
        forceResync: true,
      );
    } finally {
      // Always refresh metadata and UI state after sync attempt
      // This ensures UI shows current state even if sync failed
      if (mounted) {
        await _refreshMetadata();
        
        setState(() {
          _isSyncing = false;
        });
        
        // Notify parent widget to refresh its state
        widget.onSyncComplete?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine status color
    Color statusColor;
    IconData statusIcon;
    switch (_metadata?.status) {
      case SyncStatus.success:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case SyncStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case SyncStatus.syncing:
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case SyncStatus.idle:
      case null:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        break;
    }

    return Card(
      margin: widget.isCompact
          ? EdgeInsets.symmetric(vertical: 4)
          : EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.table.icon,
              color: colorScheme.primary,
              size: widget.isCompact ? 20 : 24,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  widget.table.nameEn,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                statusIcon,
                color: statusColor,
                size: 20,
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              if (_metadata?.recordsCount != null && _metadata!.recordsCount > 0) ...[
                Text(
                  _metadata?.hasBeenSynced == true
                      ? AppLocalizations.of(context)?.lastSyncLabel(_metadata!.getRelativeTime()) ?? 'Last sync: ${_metadata!.getRelativeTime()}'
                      : AppLocalizations.of(context)?.neverSynced ?? 'Never synced',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)?.recordsCount(_metadata!.recordsCount) ?? '${_metadata!.recordsCount} records',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else if (_metadata?.hasBeenSynced == true)
                Text(
                  AppLocalizations.of(context)?.tableEmpty ?? 'Table is empty',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  AppLocalizations.of(context)?.neverSynced ?? 'Never synced',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          trailing: _isSyncing
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _orchestrator.isSyncing(widget.table.id)
                      ? null
                      : () => _showSyncModeMenu(context),
                  tooltip: AppLocalizations.of(context)?.syncTable ?? 'Sync table',
                ),
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          children: [
            if (_isExpanded) _buildExpandedContent(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  /// Build expanded content showing dependencies and error info
  Widget _buildExpandedContent(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error message
          if (_metadata?.hasError == true) ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _metadata!.errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],

          // Dependencies
          if (widget.table.hasDependencies) ...[
            Text(
              AppLocalizations.of(context)?.dependencies ?? 'Dependencies',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ...widget.table.dependsOn.map((depId) {
              final depMetadata = _orchestrator.getTableMetadata(depId);
              final isSynced = depMetadata?.lastSyncWasSuccessful ?? false;
              
              return Padding(
                padding: EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      isSynced ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: isSynced ? Colors.green : Colors.grey,
                    ),
                    SizedBox(width: 8),
                    Text(
                      depId,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }).toList(),
            SizedBox(height: 8),
          ],

          // Cascade targets
          if (widget.table.hasCascadeTargets) ...[
            Text(
              AppLocalizations.of(context)?.willCascadeTo ?? 'Will cascade to',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ...widget.table.cascadeTo.map((cascadeId) {
              return Padding(
                padding: EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      cascadeId,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],

          // Sync buttons
          SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                icon: Icon(Icons.sync_disabled, size: 18),
                label: Text(AppLocalizations.of(context)?.tableOnly ?? 'Table only'),
                onPressed: () => _performSync(SyncMode.tableOnly),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.sync, size: 18),
                label: Text(AppLocalizations.of(context)?.withDependencies ?? 'With dependencies'),
                onPressed: () => _performSync(SyncMode.withCascade),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sync mode selection
enum SyncMode {
  tableOnly,
  withCascade,
}
