import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_category.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/repositories/knowledge_repository.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/presentation/bloc/knowledge_home_cubit.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/presentation/widgets/knowledge_category_card.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/presentation/widgets/knowledge_document_card.dart';

class KnowledgeHomePage extends StatelessWidget {
  /// Optional category slug to deep-link into. Used by the legacy
  /// `/faq` route redirect — if a category with this slug exists, we
  /// push the category page on top of the home page on first frame.
  final String? initialCategorySlug;

  const KnowledgeHomePage({super.key, this.initialCategorySlug});

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return BlocProvider(
      create: (_) => KnowledgeHomeCubit(
        sl<KnowledgeRepository>(),
        currentLanguage: lang,
      ),
      child: _KnowledgeHomeView(
        currentLanguage: lang,
        initialCategorySlug: initialCategorySlug,
      ),
    );
  }
}

class _KnowledgeHomeView extends StatefulWidget {
  final String currentLanguage;
  final String? initialCategorySlug;
  const _KnowledgeHomeView({
    required this.currentLanguage,
    this.initialCategorySlug,
  });

  @override
  State<_KnowledgeHomeView> createState() => _KnowledgeHomeViewState();
}

class _KnowledgeHomeViewState extends State<_KnowledgeHomeView> {
  bool _redirectAttempted = false;

  void _maybeRedirect(List<KnowledgeCategory> categories) {
    if (_redirectAttempted) return;
    final slug = widget.initialCategorySlug;
    if (slug == null || slug.isEmpty) return;
    final match = categories
        .where((c) => c.slug == slug && c.deletedAt == null)
        .toList();
    if (match.isEmpty) return;
    _redirectAttempted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRouter.knowledgeCategoryRoute,
        arguments: {'id': match.first.id},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocConsumer<KnowledgeHomeCubit, KnowledgeHomeState>(
        listener: (ctx, state) {
          if (!state.loading && state.categories.isNotEmpty) {
            _maybeRedirect(state.categories);
          }
        },
        builder: (ctx, state) {
          return RefreshIndicator(
            onRefresh: () => ctx.read<KnowledgeHomeCubit>().refresh(),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 140,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(l10n?.knowledgeBaseTitle ?? 'Knowledge Base'),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primaryContainer,
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => Navigator.pushNamed(
                          context, AppRouter.knowledgeSearchRoute),
                    ),
                  ],
                ),
                if (state.loading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.error != null && state.categories.isEmpty)
                  SliverFillRemaining(
                    child: _ErrorView(
                      message: state.error!,
                      onRetry: () =>
                          ctx.read<KnowledgeHomeCubit>().refresh(),
                    ),
                  )
                else ...[
                  if (state.pinned.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          l10n?.knowledgePinnedSection ?? 'Pinned',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 132,
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: state.pinned.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, i) {
                            final doc = state.pinned[i];
                            return SizedBox(
                              width: 280,
                              child: KnowledgeDocumentCard(
                                document: doc,
                                currentLanguage: widget.currentLanguage,
                                compact: true,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRouter.knowledgeDocumentRoute,
                                  arguments: {'id': doc.id},
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        l10n?.knowledgeCategoriesSection ?? 'Categories',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (state.categories.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.all(32),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: Text(
                            l10n?.knowledgeNoDocumentsAssigned ??
                                'No documents available yet',
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      sliver: SliverMasonryGrid.count(
                        crossAxisCount:
                            MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childCount: state.categories
                            .where((c) => c.parentId == null)
                            .length,
                        itemBuilder: (_, i) {
                          final root = state.categories
                              .where((c) => c.parentId == null)
                              .toList()[i];
                          return KnowledgeCategoryCard(
                            category: root,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRouter.knowledgeCategoryRoute,
                              arguments: {'id': root.id},
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ],
            ),
          );
        },
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
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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
