import 'package:flutter/material.dart';

import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_category.dart';

class KnowledgeCategoryCard extends StatelessWidget {
  final KnowledgeCategory category;
  final int? documentCount;
  final VoidCallback onTap;

  const KnowledgeCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.documentCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _parseColor(category.color) ??
        theme.colorScheme.primaryContainer;
    final fg = _readableForeground(color);

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconFor(category.icon), color: fg, size: 28),
              const SizedBox(height: 12),
              Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (category.description != null &&
                  category.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  category.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: fg.withValues(alpha: 0.85),
                  ),
                ),
              ],
              if (documentCount != null) ...[
                const SizedBox(height: 8),
                Text(
                  '$documentCount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: fg.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String? raw) {
    switch (raw) {
      case 'rule':
        return Icons.gavel;
      case 'school':
        return Icons.school_outlined;
      case 'policy':
        return Icons.policy_outlined;
      case 'manual':
        return Icons.menu_book;
      case 'announcement':
        return Icons.campaign_outlined;
      case 'video':
        return Icons.play_circle_outline;
      default:
        return Icons.folder_outlined;
    }
  }

  Color? _parseColor(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    var hex = raw.trim();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final v = int.tryParse(hex, radix: 16);
    if (v == null) return null;
    return Color(v);
  }

  Color _readableForeground(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}
