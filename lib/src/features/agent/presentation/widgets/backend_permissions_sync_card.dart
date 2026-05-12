import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/auth/backend_permission_store.dart';
import '../../../../core/services/service_locator.dart';
import 'backend_permission_labels.dart';

/// "Backend ruxsatlari" item in the Data Sync tab.
///
/// Reads from [BackendPermissionStore]:
/// - `<granted> / <total>` count
/// - Last sync timestamp
/// - Last event (success / failed + code)
///
/// Listens to the store ([ChangeNotifier]) so a login / refresh that
/// re-syncs the codenames refreshes the card without the user
/// reopening the tab. The visual language matches the existing
/// `GroupSyncCard` (rounded card, status icon, two-line layout).
class BackendPermissionsSyncCard extends StatefulWidget {
  const BackendPermissionsSyncCard({super.key});

  @override
  State<BackendPermissionsSyncCard> createState() =>
      _BackendPermissionsSyncCardState();
}

class _BackendPermissionsSyncCardState
    extends State<BackendPermissionsSyncCard> {
  late final BackendPermissionStore _store;

  @override
  void initState() {
    super.initState();
    _store = sl<BackendPermissionStore>();
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final granted =
        BackendPermissionStore.ownedCodenames.where(_store.has).length;
    final total = BackendPermissionStore.ownedCodenames.length;
    final event = _store.lastEvent;

    final (Color accent, IconData icon, String statusLine) = switch (
        event.status) {
      BackendPermissionSyncStatus.ok => (
          cs.primary,
          Icons.check_circle,
          l10n.backendPermissionsSync_status_ok,
        ),
      BackendPermissionSyncStatus.failed => (
          cs.error,
          Icons.error_outline,
          l10n.backendPermissionsSync_status_failed,
        ),
      BackendPermissionSyncStatus.idle => (
          cs.onSurfaceVariant,
          Icons.cloud_off_outlined,
          l10n.backendPermissionsSync_neverSynced,
        ),
    };

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: cs.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.backendPermissionsSync_title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.backendPermissionsSync_subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: accent, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$granted/$total',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Detail rows: count + last-sync time + status line + error.
          _DetailRow(
            icon: Icons.format_list_numbered,
            text: l10n.backendPermissionsSync_countLine(granted, total),
            colorScheme: cs,
          ),
          if (event.timestamp != null) ...[
            const SizedBox(height: 6),
            _DetailRow(
              icon: Icons.schedule,
              text: l10n.backendPermissionsSync_lastSync(
                _formatRelativeTime(event.timestamp!, l10n),
              ),
              colorScheme: cs,
            ),
          ],
          const SizedBox(height: 6),
          _DetailRow(
            icon: icon,
            text: statusLine,
            color: accent,
            colorScheme: cs,
          ),
          if (event.status == BackendPermissionSyncStatus.failed &&
              (event.detail ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            _DetailRow(
              icon: Icons.bug_report_outlined,
              text: l10n.backendPermissionsSync_errorLine(event.detail!),
              color: cs.error,
              colorScheme: cs,
            ),
          ],
          if (event.status == BackendPermissionSyncStatus.ok) ...[
            const SizedBox(height: 12),
            // Quick visual: tick-row per category so the user can
            // confirm at a glance which areas have access right now.
            _CategoryCheckRow(store: _store),
          ],
        ],
      ),
    );
  }

  /// Lightweight relative-time formatter — keeps the card readable
  /// without pulling in `intl`. Falls back to absolute date for older
  /// timestamps so a stale store does not look freshly synced.
  String _formatRelativeTime(DateTime then, AppLocalizations _) {
    final diff = DateTime.now().difference(then);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${then.year}-${then.month.toString().padLeft(2, '0')}-'
        '${then.day.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final ColorScheme colorScheme;

  const _DetailRow({
    required this.icon,
    required this.text,
    required this.colorScheme,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: tint),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: tint),
          ),
        ),
      ],
    );
  }
}

class _CategoryCheckRow extends StatelessWidget {
  final BackendPermissionStore store;
  const _CategoryCheckRow({required this.store});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final labels = resolveBackendPermissionLabels(l10n);
    final byCategory =
        <BackendPermissionCategory, List<BackendPermissionLabel>>{};
    for (final label in labels) {
      byCategory
          .putIfAbsent(label.category, () => <BackendPermissionLabel>[])
          .add(label);
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in byCategory.entries)
          _categoryChip(theme, cs, l10n, entry.key, entry.value),
      ],
    );
  }

  Widget _categoryChip(
    ThemeData theme,
    ColorScheme cs,
    AppLocalizations l10n,
    BackendPermissionCategory category,
    List<BackendPermissionLabel> labels,
  ) {
    final granted = labels.where((l) => store.has(l.codename)).length;
    final ok = granted == labels.length;
    final any = granted > 0;
    final color = ok ? cs.primary : (any ? cs.tertiary : cs.error);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '${category.localised(l10n)}  $granted/${labels.length}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
