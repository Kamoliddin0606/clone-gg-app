import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_section.dart';

/// Sidebar TOC for [KnowledgeDocumentPage].
///
/// Renders the section tree (parent_id grouping) with the active
/// section highlighted; tap fires [onJump] which scrolls the body
/// to the section via the parent's [GlobalKey] map.
class DocumentTocDrawer extends StatelessWidget {
  final List<KnowledgeSection> sections;
  final String currentLanguage;
  final String? activeSectionId;
  final void Function(KnowledgeSection section) onJump;

  const DocumentTocDrawer({
    super.key,
    required this.sections,
    required this.currentLanguage,
    required this.onJump,
    this.activeSectionId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final byParent = <String?, List<KnowledgeSection>>{};
    for (final s in sections) {
      byParent.putIfAbsent(s.parentId, () => []).add(s);
    }
    for (final list in byParent.values) {
      list.sort((a, b) => a.orderIdx.compareTo(b.orderIdx));
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Text(
                l10n?.knowledgeTocTitle ?? 'Table of contents',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _buildTree(context, byParent, null, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTree(
    BuildContext context,
    Map<String?, List<KnowledgeSection>> byParent,
    String? parentId,
    int depth,
  ) {
    final out = <Widget>[];
    final list = byParent[parentId] ?? const [];
    for (final s in list) {
      out.add(_TocTile(
        section: s,
        currentLanguage: currentLanguage,
        depth: depth,
        active: s.id == activeSectionId,
        onTap: () => onJump(s),
      ));
      out.addAll(_buildTree(context, byParent, s.id, depth + 1));
    }
    return out;
  }
}

class _TocTile extends StatelessWidget {
  final KnowledgeSection section;
  final String currentLanguage;
  final int depth;
  final bool active;
  final VoidCallback onTap;

  const _TocTile({
    required this.section,
    required this.currentLanguage,
    required this.depth,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = section.titleFor(currentLanguage) ??
        section.titleFor('en') ??
        section.titleFor('ru') ??
        section.titleFor('uz') ??
        '—';

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: active
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
              : null,
          border: Border(
            left: BorderSide(
              width: 3,
              color:
                  active ? theme.colorScheme.primary : Colors.transparent,
            ),
          ),
        ),
        padding: EdgeInsets.fromLTRB(16.0 + depth * 14, 10, 16, 10),
        child: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? theme.colorScheme.primary : null,
          ),
        ),
      ),
    );
  }
}
