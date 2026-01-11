import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/models/data_sync_group.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_config.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_orchestrator.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/utils/sync_helpers.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/table_sync_card.dart';

/// Card widget displaying a group of related tables with collective sync controls.
///
/// This widget shows:
/// - Group name, icon, and color
/// - Overall group sync status
/// - "Sync Group" button
/// - Expandable list of tables in the group (using TableSyncCard)
/// - Summary of synced vs total tables
///
/// Example usage:
/// ```dart
/// GroupSyncCard(
///   group: DataSyncConfig.getGroup('product_catalog')!,
/// )
/// ```
class GroupSyncCard extends StatefulWidget {
  /// The group configuration to display
  final DataSyncGroup group;

  /// Whether the group should be initially expanded
  final bool initiallyExpanded;

  const GroupSyncCard({
    super.key,
    required this.group,
    this.initiallyExpanded = false,
  });

  @override
  State<GroupSyncCard> createState() => _GroupSyncCardState();
}

class _GroupSyncCardState extends State<GroupSyncCard> {
  late final DataSyncOrchestrator _orchestrator;
  bool _isExpanded = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _orchestrator = sl<DataSyncOrchestrator>();
    _isExpanded = widget.initiallyExpanded;
  }

  /// Calculate group sync status based on all tables in group
  _GroupStatus _calculateGroupStatus() {
    final tables = DataSyncConfig.getTablesInGroup(widget.group.id);
    if (tables.isEmpty) {
      return _GroupStatus(
        syncedCount: 0,
        totalCount: 0,
        hasErrors: false,
        allSynced: false,
        lastSyncTime: null,
      );
    }

    var syncedCount = 0;
    var hasErrors = false;
    DateTime? latestSyncTime;

    for (final table in tables) {
      final metadata = _orchestrator.getTableMetadata(table.id);
      
      if (metadata != null) {
        if (metadata.lastSyncWasSuccessful) {
          syncedCount++;
        }
        if (metadata.hasError) {
          hasErrors = true;
        }
        if (metadata.lastSyncTime != null) {
          if (latestSyncTime == null || 
              metadata.lastSyncTime!.isAfter(latestSyncTime)) {
            latestSyncTime = metadata.lastSyncTime;
          }
        }
      }
    }

    return _GroupStatus(
      syncedCount: syncedCount,
      totalCount: tables.length,
      hasErrors: hasErrors,
      allSynced: syncedCount == tables.length,
      lastSyncTime: latestSyncTime,
    );
  }

  /// Sync entire group
  Future<void> _syncGroup() async {
    setState(() {
      _isSyncing = true;
    });

    try {
     final success = await syncGroupFromAnywhere(context, widget.group.id);
      
      if (success && mounted) {
        setState(() {});
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = _calculateGroupStatus();

    // Get group color or use primary
    final groupColor = widget.group.color ?? colorScheme.primary;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: groupColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.group.icon,
              color: groupColor,
              size: 28,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  widget.group.nameEn,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: groupColor,
                  ),
                ),
              ),
              // Status badge
              _buildStatusBadge(status, theme, groupColor),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(
                '${status.syncedCount} of ${status.totalCount} tables synced',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (status.lastSyncTime != null)
                Text(
                  _getRelativeTime(status.lastSyncTime!),
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
                  icon: Icon(Icons.sync),
                  color: groupColor,
                  onPressed: _syncGroup,
                  tooltip: 'Sync entire group',
                ),
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          children: [
            if (_isExpanded) _buildGroupContent(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  /// Build status badge showing sync status
  Widget _buildStatusBadge(_GroupStatus status, ThemeData theme, Color groupColor) {
    IconData icon;
    Color color;
    String text;

    if (status.hasErrors) {
      icon = Icons.error;
      color = Colors.red;
      text = 'Errors';
    } else if (status.allSynced) {
      icon = Icons.check_circle;
      color = Colors.green;
      text = 'Synced';
    } else if (status.syncedCount > 0) {
      icon = Icons.sync_problem;
      color = Colors.orange;
      text = 'Partial';
    } else {
      icon = Icons.sync_disabled;
      color = Colors.grey;
      text = 'Not synced';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build expanded content with table cards
  Widget _buildGroupContent(ThemeData theme, ColorScheme colorScheme) {
    final tables = DataSyncConfig.getTablesInGroup(widget.group.id);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Group description
          Text(
            'Tables in this group',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 12),

          // Table cards
          ...tables.map((table) => TableSyncCard(
                table: table,
                isCompact: true,
              )),

          SizedBox(height: 16),

          // Sync all button
          ElevatedButton.icon(
            icon: _isSyncing
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.sync),
            label: Text(AppLocalizations.of(context)?.syncEntireGroup ?? 'Sync Entire Group'),
            onPressed: _isSyncing ? null : _syncGroup,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.group.color,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Get relative time string
  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }
}

/// Internal class for group status calculation
class _GroupStatus {
  final int syncedCount;
  final int totalCount;
  final bool hasErrors;
  final bool allSynced;
  final DateTime? lastSyncTime;

  _GroupStatus({
    required this.syncedCount,
    required this.totalCount,
    required this.hasErrors,
    required this.allSynced,
    required this.lastSyncTime,
  });
}
