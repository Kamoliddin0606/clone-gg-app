import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/auth/backend_permission_store.dart';
import '../../../../core/services/service_locator.dart';
import 'backend_permission_labels.dart';
import 'permission_group_card.dart';

/// Section rendered inside the Permissions tab in Settings, showing
/// every codename the V2 backend ships in `gates.permissions`.
///
/// Visual style now matches the Data Sync tab's "GroupSyncCard"
/// pattern: each category collapses into a single rounded card with
/// a tinted leading icon, status badge, granted/total chip, and an
/// expandable list of permission rows.
///
/// Listens to [BackendPermissionStore] so a login / refresh that
/// brings a new permission set triggers a rebuild immediately.
class BackendPermissionsSection extends StatefulWidget {
  /// Index of the first expanded category. Pass -1 to keep all
  /// categories collapsed by default.
  final int initiallyExpandedIndex;

  const BackendPermissionsSection({
    super.key,
    this.initiallyExpandedIndex = 0,
  });

  @override
  State<BackendPermissionsSection> createState() =>
      _BackendPermissionsSectionState();
}

class _BackendPermissionsSectionState extends State<BackendPermissionsSection> {
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

  /// Color associated with each backend category. Pulled out so the
  /// header chip and the collapsible card stay in lock-step.
  Color _categoryColor(BackendPermissionCategory cat, ColorScheme cs) {
    switch (cat) {
      case BackendPermissionCategory.customers:
        return cs.primary;
      case BackendPermissionCategory.photos:
        return cs.tertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final labels = resolveBackendPermissionLabels(l10n);

    // Preserve insertion order so categories stay deterministic.
    final grouped = <BackendPermissionCategory, List<BackendPermissionLabel>>{};
    for (final label in labels) {
      grouped.putIfAbsent(label.category, () => <BackendPermissionLabel>[])
          .add(label);
    }

    final isOptimistic = _store.isOptimistic && _store.all.isEmpty;
    final categories = grouped.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.cloud_done_outlined,
          title: l10n.backendPermissions_sectionTitle,
          subtitle: l10n.backendPermissions_sectionSubtitle,
          color: cs.primary,
          trailingChip: _OptimisticBadge(visible: isOptimistic),
        ),
        for (var i = 0; i < categories.length; i++)
          PermissionGroupCard(
            title: categories[i].key.localised(l10n),
            icon: categories[i].key.icon,
            color: _categoryColor(categories[i].key, cs),
            granted: categories[i]
                .value
                .where((l) => _store.has(l.codename))
                .length,
            total: categories[i].value.length,
            isOptimistic: isOptimistic,
            initiallyExpanded: i == widget.initiallyExpandedIndex,
            children: [
              for (final label in categories[i].value)
                PermissionRow(
                  icon: label.icon,
                  title: label.title,
                  secondary: label.codename,
                  granted: _store.has(label.codename),
                  accent: _categoryColor(categories[i].key, cs),
                ),
            ],
          ),
      ],
    );
  }
}

/// Lightweight section header — a row with an icon, bold title and
/// optional subtitle. Used inline within a parent ListView, so it
/// stays flat (no card / shadow) to avoid competing with the hero.
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final Widget? trailingChip;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
    this.subtitle,
    this.trailingChip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailingChip != null) ...[
                const SizedBox(width: 8),
                Flexible(child: trailingChip!),
              ],
            ],
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptimisticBadge extends StatelessWidget {
  final bool visible;
  const _OptimisticBadge({required this.visible});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.tertiary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.tertiary.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_top_rounded, size: 14, color: cs.tertiary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              l10n.backendPermissions_optimisticBadge,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.tertiary,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
