import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/repositories/knowledge_repository.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/presentation/bloc/knowledge_search_cubit.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/presentation/widgets/knowledge_document_card.dart';

class KnowledgeSearchPage extends StatelessWidget {
  const KnowledgeSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return BlocProvider(
      create: (_) => KnowledgeSearchCubit(
        sl<KnowledgeRepository>(),
        currentLanguage: lang,
      ),
      child: _SearchView(currentLanguage: lang),
    );
  }
}

class _SearchView extends StatefulWidget {
  final String currentLanguage;
  const _SearchView({required this.currentLanguage});

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<KnowledgeSearchCubit>();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n?.knowledgeSearchPlaceholder ?? 'Search documents…',
            border: InputBorder.none,
          ),
          onChanged: cubit.onQueryChanged,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _controller.clear();
              cubit.onQueryChanged('');
            },
          ),
        ],
      ),
      body: BlocBuilder<KnowledgeSearchCubit, KnowledgeSearchState>(
        builder: (ctx, state) {
          if (state.searching) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.query.isEmpty) {
            return Center(
              child: Text(
                l10n?.knowledgeSearchPlaceholder ?? 'Search documents…',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          if (state.results.isEmpty) {
            return Center(
              child: Text(l10n?.knowledgeSearchEmpty ??
                  'Nothing matched your query'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: state.results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final doc = state.results[i];
              return KnowledgeDocumentCard(
                document: doc,
                currentLanguage: widget.currentLanguage,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRouter.knowledgeDocumentRoute,
                  arguments: {'id': doc.id},
                ),
              );
            },
          );
        },
      ),
    );
  }
}
