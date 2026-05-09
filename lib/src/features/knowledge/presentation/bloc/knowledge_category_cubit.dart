import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_category.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_document_summary.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/repositories/knowledge_repository.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/domain/enums/doc_type.dart';

class KnowledgeCategoryState extends Equatable {
  final bool loading;
  final bool refreshing;
  final KnowledgeCategory? category;
  final List<KnowledgeDocumentSummary> documents;
  final DocType? typeFilter;
  final String? error;

  const KnowledgeCategoryState({
    this.loading = false,
    this.refreshing = false,
    this.category,
    this.documents = const [],
    this.typeFilter,
    this.error,
  });

  KnowledgeCategoryState copyWith({
    bool? loading,
    bool? refreshing,
    KnowledgeCategory? category,
    List<KnowledgeDocumentSummary>? documents,
    DocType? typeFilter,
    bool clearTypeFilter = false,
    String? error,
    bool clearError = false,
  }) {
    return KnowledgeCategoryState(
      loading: loading ?? this.loading,
      refreshing: refreshing ?? this.refreshing,
      category: category ?? this.category,
      documents: documents ?? this.documents,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [loading, refreshing, category, documents, typeFilter, error];
}

class KnowledgeCategoryCubit extends Cubit<KnowledgeCategoryState> {
  final KnowledgeRepository _repo;
  final String categoryId;
  final String currentLanguage;

  KnowledgeCategoryCubit(
    this._repo, {
    required this.categoryId,
    required this.currentLanguage,
  }) : super(const KnowledgeCategoryState(loading: true)) {
    load();
  }

  Future<void> load({bool forceRefresh = false}) async {
    emit(state.copyWith(
      loading: state.documents.isEmpty,
      refreshing: state.documents.isNotEmpty,
      clearError: true,
    ));
    try {
      final category = await _repo.getCategoryById(categoryId);
      final docs = await _repo.getDocuments(
        categoryId: categoryId,
        docType: state.typeFilter,
        language: currentLanguage,
        forceRefresh: forceRefresh,
      );
      emit(state.copyWith(
        loading: false,
        refreshing: false,
        category: category,
        documents: docs,
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        refreshing: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> refresh() => load(forceRefresh: true);

  Future<void> setTypeFilter(DocType? t) async {
    emit(state.copyWith(typeFilter: t, clearTypeFilter: t == null));
    await load();
  }
}
