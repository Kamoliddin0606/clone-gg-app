import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/repositories/knowledge_repository.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/domain/enums/doc_type.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/presentation/bloc/knowledge_category_cubit.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/presentation/widgets/knowledge_document_card.dart';

class KnowledgeCategoryPage extends StatelessWidget {
  final String categoryId;
  const KnowledgeCategoryPage({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return BlocProvider(
      create: (_) => KnowledgeCategoryCubit(
        sl<KnowledgeRepository>(),
        categoryId: categoryId,
        currentLanguage: lang,
      ),
      child: _CategoryView(currentLanguage: lang),
    );
  }
}

class _CategoryView extends StatelessWidget {
  final String currentLanguage;
  const _CategoryView({required this.currentLanguage});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<KnowledgeCategoryCubit, KnowledgeCategoryState>(
      builder: (ctx, state) {
        final cubit = ctx.read<KnowledgeCategoryCubit>();
        return Scaffold(
          appBar: AppBar(
            title: Text(state.category?.name ??
                l10n?.knowledgeBaseTitle ??
                'Knowledge Base'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => Navigator.pushNamed(
                    context, AppRouter.knowledgeSearchRoute),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _FilterChip(
                      label: l10n?.knowledgeFilterAll ?? 'All',
                      selected: state.typeFilter == null,
                      onSelected: () => cubit.setTypeFilter(null),
                    ),
                    for (final t in DocType.values
                        .where((t) => t != DocType.unknown))
                      _FilterChip(
                        label: _label(t),
                        selected: state.typeFilter == t,
                        onSelected: () => cubit.setTypeFilter(t),
                      ),
                  ],
                ),
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: cubit.refresh,
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.documents.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Text(l10n?.knowledgeCategoryEmpty ??
                                  'No documents in this category'),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: state.documents.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final doc = state.documents[i];
                          return KnowledgeDocumentCard(
                            document: doc,
                            currentLanguage: currentLanguage,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRouter.knowledgeDocumentRoute,
                              arguments: {'id': doc.id},
                            ),
                          );
                        },
                      ),
          ),
        );
      },
    );
  }

  String _label(DocType t) => switch (t) {
        DocType.regulation => 'Reglament',
        DocType.manual => 'Manual',
        DocType.training => 'Training',
        DocType.policy => 'Policy',
        DocType.faq => 'FAQ',
        DocType.announcement => 'News',
        DocType.other => 'Other',
        DocType.unknown => '-',
      };
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
