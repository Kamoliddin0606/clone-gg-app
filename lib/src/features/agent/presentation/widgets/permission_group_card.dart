import 'package:flutter/material.dart';

import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

/// Collapsible "group" card for the Permissions tab.
///
/// Visual + interaction parity with `GroupSyncCard` from the Data
/// Sync tab: tinted leading icon, title in the group color, status
/// badge + `granted/total` subtitle, and an [ExpansionTile] body
/// that holds the per-row widgets.
///
/// The card is presentation-only — the caller decides what a row
/// looks like and feeds it via [children]. That keeps this widget
/// reusable for both V2 backend codename rows and the legacy SOAP
/// permission rows.
class PermissionGroupCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int granted;
  final int total;
  final bool isOptimistic;
  final bool initiallyExpanded;
  final List<Widget> children;

  const PermissionGroupCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.granted,
    required this.total,
    required this.children,
    this.isOptimistic = false,
    this.initiallyExpanded = false,
  });

  @override
  State<PermissionGroupCard> createState() => _PermissionGroupCardState();
}

class _PermissionGroupCardState extends State<PermissionGroupCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _isExpanded
              ? widget.color.withOpacity(0.4)
              : cs.outlineVariant.withOpacity(0.5),
          width: _isExpanded ? 1.2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // Remove the default ExpansionTile divider lines so the card
        // edge stays clean when collapsed.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding: EdgeInsets.zero,
          initiallyExpanded: widget.initiallyExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
          },
          leading: _buildLeadingIcon(),
          title: Text(
            widget.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: widget.color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                _StatusBadge(
                  granted: widget.granted,
                  total: widget.total,
                  isOptimistic: widget.isOptimistic,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)?.tablesOfTotalSynced(
                          widget.granted,
                          widget.total,
                        ) ??
                        '${widget.granted} of ${widget.total}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          trailing: _CountChip(
            granted: widget.granted,
            total: widget.total,
            color: widget.color,
          ),
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.25),
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withOpacity(0.4),
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(widget.icon, color: widget.color, size: 24),
    );
  }
}

/// Compact pill showing `granted/total` in the group color.
class _CountChip extends StatelessWidget {
  final int granted;
  final int total;
  final Color color;

  const _CountChip({
    required this.granted,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        '$granted/$total',
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Status badge mirroring `_buildStatusBadge` in `GroupSyncCard`:
/// All granted → green, partial → orange, none → red, no data → grey.
class _StatusBadge extends StatelessWidget {
  final int granted;
  final int total;
  final bool isOptimistic;

  const _StatusBadge({
    required this.granted,
    required this.total,
    required this.isOptimistic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    late final IconData icon;
    late final Color color;
    late final String text;

    if (isOptimistic) {
      icon = Icons.hourglass_top_rounded;
      color = Colors.blueGrey;
      text = l10n?.syncStatusNotSynced ?? 'Pending';
    } else if (total == 0) {
      icon = Icons.remove_circle_outline;
      color = Colors.grey;
      text = '—';
    } else if (granted == total) {
      icon = Icons.check_circle;
      color = Colors.green;
      text = l10n?.syncStatusSynced ?? 'Active';
    } else if (granted == 0) {
      icon = Icons.cancel;
      color = Colors.red;
      text = l10n?.syncStatusErrors ?? 'Denied';
    } else {
      icon = Icons.adjust;
      color = Colors.orange;
      text = l10n?.syncStatusPartial ?? 'Partial';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact row used inside a [PermissionGroupCard].
///
/// Two-line layout: icon + title + status pill on the right, optional
/// secondary line for the raw codename / hint.
///
/// When [overriddenBy] is non-null the row is rendered as visually
/// "crossed out" — strikethrough title, dimmed colors, and a small
/// "→ <overriddenBy>" badge under the title. Use this for legacy
/// SOAP permissions that are superseded by a V2 backend codename,
/// so the user can see the SOAP value at a glance while still
/// understanding that the backend gate is the real source of truth.
class PermissionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? secondary;
  final bool granted;
  final Color? accent;
  final String? overriddenBy;

  const PermissionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.granted,
    this.secondary,
    this.accent,
    this.overriddenBy,
  });

  bool get _isOverridden =>
      overriddenBy != null && overriddenBy!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = granted ? (accent ?? cs.primary) : cs.error;

    // When the row is overridden by a backend codename the SOAP value
    // is no longer authoritative; mute every color and put a line
    // through the title so the user immediately reads it as "see the
    // backend section above".
    final titleColor = _isOverridden
        ? cs.onSurfaceVariant.withOpacity(0.7)
        : (granted ? cs.onSurface : cs.onSurfaceVariant);
    final iconColor = _isOverridden
        ? cs.onSurfaceVariant.withOpacity(0.6)
        : (granted ? (accent ?? cs.primary) : cs.onSurfaceVariant);
    final iconBgColor = _isOverridden
        ? cs.onSurfaceVariant.withOpacity(0.08)
        : (granted ? (accent ?? cs.primary) : cs.onSurfaceVariant)
            .withOpacity(0.10);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w500,
                    decoration: _isOverridden
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: cs.onSurfaceVariant,
                    decorationThickness: 2,
                  ),
                ),
                if (_isOverridden) ...[
                  const SizedBox(height: 4),
                  _OverrideBadge(label: overriddenBy!),
                ] else if (secondary != null && secondary!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    secondary!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Opacity(
            opacity: _isOverridden ? 0.55 : 1.0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                granted ? Icons.check_rounded : Icons.close_rounded,
                color: color,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small inline chip that reads `→ label` — used by [PermissionRow]
/// to communicate "this SOAP entry is superseded by a backend
/// codename". Visually muted so it doesn't compete with the row's
/// real title.
class _OverrideBadge extends StatelessWidget {
  final String label;

  const _OverrideBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.tertiary.withOpacity(0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.subdirectory_arrow_right_rounded,
            size: 13,
            color: cs.onTertiaryContainer,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onTertiaryContainer,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
