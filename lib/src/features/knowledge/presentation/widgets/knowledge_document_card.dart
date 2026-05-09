import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_document_summary.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/domain/enums/doc_type.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/presentation/widgets/knowledge_image_widget.dart';

class KnowledgeDocumentCard extends StatelessWidget {
  final KnowledgeDocumentSummary document;
  final String currentLanguage;
  final VoidCallback onTap;
  final bool compact;

  const KnowledgeDocumentCard({
    super.key,
    required this.document,
    required this.currentLanguage,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final title = document.titleFor(currentLanguage) ??
        document.titleFor('en') ??
        document.titleFor('ru') ??
        document.titleFor('uz') ??
        '—';
    final summary = document.summaryFor(currentLanguage) ??
        document.summaryFor('en') ??
        document.summaryFor('ru') ??
        document.summaryFor('uz');

    final cover = document.coverMedia;

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cover != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: KnowledgeImageWidget(
                    media: cover,
                    size: KnowledgeImageSize.small,
                    width: compact ? 64 : 88,
                    height: compact ? 64 : 88,
                  ),
                )
              else
                Container(
                  width: compact ? 64 : 88,
                  height: compact ? 64 : 88,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(_typeIcon(document.docType),
                      size: 32, color: theme.colorScheme.onSurfaceVariant),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (document.mandatory)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Tooltip(
                              message:
                                  l10n?.knowledgeMandatoryBadge ?? 'Mandatory',
                              child: Icon(Icons.priority_high,
                                  size: 16, color: Colors.red.shade700),
                            ),
                          ),
                        if (document.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Tooltip(
                              message: l10n?.knowledgePinnedBadge ?? 'Pinned',
                              child: Icon(Icons.push_pin,
                                  size: 16,
                                  color: theme.colorScheme.primary),
                            ),
                          ),
                      ],
                    ),
                    if (summary != null && summary.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        summary,
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (document.docType != DocType.unknown)
                          _Chip(label: _typeLabel(document.docType)),
                        for (final tag in document.tags.take(3))
                          if (tag.name != null && tag.name!.isNotEmpty)
                            _Chip(label: tag.name!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(DocType t) => switch (t) {
        DocType.regulation => Icons.gavel,
        DocType.manual => Icons.menu_book,
        DocType.training => Icons.school_outlined,
        DocType.policy => Icons.policy_outlined,
        DocType.faq => Icons.help_outline,
        DocType.announcement => Icons.campaign_outlined,
        DocType.other => Icons.article_outlined,
        DocType.unknown => Icons.article_outlined,
      };

  String _typeLabel(DocType t) => switch (t) {
        DocType.regulation => 'REG',
        DocType.manual => 'GUIDE',
        DocType.training => 'TRAINING',
        DocType.policy => 'POLICY',
        DocType.faq => 'FAQ',
        DocType.announcement => 'NEWS',
        DocType.other => 'DOC',
        DocType.unknown => 'DOC',
      };
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
