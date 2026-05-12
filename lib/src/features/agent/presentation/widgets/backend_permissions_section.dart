import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/auth/backend_permission_store.dart';
import '../../../../core/services/service_locator.dart';
import 'backend_permission_labels.dart';

/// Section rendered at the top of the Permissions tab in Settings,
/// showing every codename the V2 backend ships in `gates.permissions`.
///
/// Visual conventions match the existing SOAP permissions cards:
/// - Card per category, header band tinted with `primaryContainer`
/// - `<granted>/<total>` chip on the right
/// - ListTile per codename with the icon on the left and a green
///   check / red cross on the right
///
/// Listens to [BackendPermissionStore] (a [ChangeNotifier]) so a
/// login / refresh that brings a new permission set triggers a
/// rebuild immediately — the user does not have to leave + reopen
/// the tab.
class BackendPermissionsSection extends StatefulWidget {
  const BackendPermissionsSection({super.key});

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final labels = resolveBackendPermissionLabels(l10n);
    final grouped = <BackendPermissionCategory, List<BackendPermissionLabel>>{};
    for (final label in labels) {
      grouped.putIfAbsent(label.category, () => <BackendPermissionLabel>[])
          .add(label);
    }

    final totalGranted =
        labels.where((l) => _store.has(l.codename)).length;
    final totalCount = labels.length;
    final isOptimistic = _store.isOptimistic && _store.all.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header card — mirrors the existing "agent permissions"
        // overview card for visual consistency.
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud_done_outlined,
                        color: cs.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.backendPermissions_sectionTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isOptimistic ? cs.tertiary : cs.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.backendPermissions_grantedBadge(
                          totalGranted,
                          totalCount,
                        ),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.backendPermissions_sectionSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (isOptimistic) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: cs.tertiary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.backendPermissions_optimisticBadge,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.tertiary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // One card per category, ordered to match enum definition.
        for (final entry in grouped.entries)
          _CategoryCard(
            category: entry.key,
            labels: entry.value,
            store: _store,
            isOptimistic: isOptimistic,
          ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final BackendPermissionCategory category;
  final List<BackendPermissionLabel> labels;
  final BackendPermissionStore store;
  final bool isOptimistic;

  const _CategoryCard({
    required this.category,
    required this.labels,
    required this.store,
    required this.isOptimistic,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final granted = labels.where((l) => store.has(l.codename)).length;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.4),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(category.icon, color: cs.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.localised(l10n),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$granted/${labels.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final label in labels)
            _PermissionRow(
              label: label,
              granted: store.has(label.codename),
            ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final BackendPermissionLabel label;
  final bool granted;

  const _PermissionRow({required this.label, required this.granted});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ListTile(
      leading: Icon(
        label.icon,
        color: granted ? cs.primary : cs.onSurfaceVariant,
      ),
      title: Text(
        label.title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: granted ? cs.onSurface : cs.onSurfaceVariant,
        ),
      ),
      subtitle: Text(
        label.codename,
        style: theme.textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontFamily: 'monospace',
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: granted
              ? cs.primary.withOpacity(0.12)
              : cs.error.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              granted ? Icons.check_circle : Icons.cancel,
              color: granted ? cs.primary : cs.error,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              granted
                  ? l10n.backendPermissions_granted
                  : l10n.backendPermissions_denied,
              style: theme.textTheme.labelSmall?.copyWith(
                color: granted ? cs.primary : cs.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
