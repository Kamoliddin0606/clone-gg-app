import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_document.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_section.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/repositories/knowledge_repository.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/presentation/bloc/knowledge_document_cubit.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/presentation/widgets/content_block_renderer.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/presentation/widgets/document_toc_drawer.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/presentation/widgets/knowledge_image_widget.dart';

class KnowledgeDocumentPage extends StatelessWidget {
  final String documentId;
  const KnowledgeDocumentPage({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => KnowledgeDocumentCubit(
        sl<KnowledgeRepository>(),
        documentId: documentId,
      ),
      child: const _DocumentView(),
    );
  }
}

class _DocumentView extends StatefulWidget {
  const _DocumentView();

  @override
  State<_DocumentView> createState() => _DocumentViewState();
}

class _DocumentViewState extends State<_DocumentView> {
  final _scrollController = ScrollController();
  final _sectionKeys = <String, GlobalKey>{};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(String sectionId) =>
      _sectionKeys.putIfAbsent(sectionId, () => GlobalKey());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    return BlocBuilder<KnowledgeDocumentCubit, KnowledgeDocumentState>(
      builder: (ctx, state) {
        final doc = state.document;
        return Scaffold(
          drawer: doc != null && doc.sections.isNotEmpty
              ? DocumentTocDrawer(
                  sections: doc.sections,
                  currentLanguage: lang,
                  activeSectionId: state.activeSectionId,
                  onJump: (s) => _jumpTo(context, s),
                )
              : null,
          body: state.loading && doc == null
              ? const _LoadingView()
              : state.error != null && doc == null
                  ? _ErrorView(
                      message: state.error!,
                      onRetry: () =>
                          ctx.read<KnowledgeDocumentCubit>().refresh(),
                    )
                  : doc == null
                      ? Center(
                          child: Text(l10n?.knowledgeDocumentNotFound ??
                              'Document not found'),
                        )
                      : _DocumentBody(
                          doc: doc,
                          currentLanguage: lang,
                          scrollController: _scrollController,
                          keyFor: _keyFor,
                          onSectionVisible: (id) =>
                              ctx.read<KnowledgeDocumentCubit>()
                                  .setActiveSection(id),
                          stale: state.stale,
                        ),
        );
      },
    );
  }

  Future<void> _jumpTo(BuildContext context, KnowledgeSection s) async {
    Navigator.maybePop(context); // close drawer
    final key = _keyFor(s.id);
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      alignment: 0.05,
      curve: Curves.easeOut,
    );
  }
}

class _DocumentBody extends StatelessWidget {
  final KnowledgeDocument doc;
  final String currentLanguage;
  final ScrollController scrollController;
  final GlobalKey Function(String) keyFor;
  final void Function(String id) onSectionVisible;
  final bool stale;

  const _DocumentBody({
    required this.doc,
    required this.currentLanguage,
    required this.scrollController,
    required this.keyFor,
    required this.onSectionVisible,
    required this.stale,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final title = doc.titleFor(currentLanguage) ??
        doc.titleFor('en') ??
        doc.titleFor('ru') ??
        doc.titleFor('uz') ??
        '—';
    final summary = doc.summaryFor(currentLanguage) ??
        doc.summaryFor('en') ??
        doc.summaryFor('ru') ??
        doc.summaryFor('uz');

    final byParent = <String?, List<KnowledgeSection>>{};
    for (final s in doc.sections) {
      byParent.putIfAbsent(s.parentId, () => []).add(s);
    }
    for (final list in byParent.values) {
      list.sort((a, b) => a.orderIdx.compareTo(b.orderIdx));
    }

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverAppBar(
          expandedHeight: doc.coverMedia != null ? 220 : 120,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
            background: doc.coverMedia != null
                ? KnowledgeImageWidget(
                    media: doc.coverMedia,
                    size: KnowledgeImageSize.large,
                    fit: BoxFit.cover,
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primaryContainer,
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        if (stale)
          SliverToBoxAdapter(
            child: Container(
              color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n?.knowledgeOfflineNotice ??
                          "You're offline. Showing cached content.",
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (summary != null && summary.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                summary,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList.list(
            children: _buildSections(byParent, null, 0),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSections(
    Map<String?, List<KnowledgeSection>> byParent,
    String? parentId,
    int depth,
  ) {
    final out = <Widget>[];
    final list = byParent[parentId] ?? const [];
    for (final s in list) {
      out.add(_SectionWidget(
        section: s,
        currentLanguage: currentLanguage,
        depth: depth,
        sectionKey: keyFor(s.id),
        onVisible: () => onSectionVisible(s.id),
      ));
      out.addAll(_buildSections(byParent, s.id, depth + 1));
    }
    return out;
  }
}

class _SectionWidget extends StatelessWidget {
  final KnowledgeSection section;
  final String currentLanguage;
  final int depth;
  final GlobalKey sectionKey;
  final VoidCallback onVisible;

  const _SectionWidget({
    required this.section,
    required this.currentLanguage,
    required this.depth,
    required this.sectionKey,
    required this.onVisible,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = section.titleFor(currentLanguage) ??
        section.titleFor('en') ??
        section.titleFor('ru') ??
        section.titleFor('uz') ??
        '';

    final headingStyle = depth == 0
        ? theme.textTheme.headlineSmall
        : theme.textTheme.titleLarge;

    return VisibilityDetector(
      key: Key('kn-vis-${section.id}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.4) onVisible();
      },
      child: Padding(
        key: sectionKey,
        padding: EdgeInsets.fromLTRB(depth * 8.0, 16, 0, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                style: headingStyle?.copyWith(fontWeight: FontWeight.w700),
              ),
            const SizedBox(height: 4),
            for (final block in section.blocks)
              ContentBlockRenderer(
                block: block,
                currentLanguage: currentLanguage,
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(l10n?.knowledgeDocumentLoading ?? 'Loading document…'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(l10n?.knowledgeRetry ?? 'Retry'),
          ),
        ],
      ),
    );
  }
}
