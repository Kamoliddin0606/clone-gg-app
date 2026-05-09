import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_category.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_document_summary.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/repositories/knowledge_repository.dart';

class KnowledgeHomeState extends Equatable {
  final bool loading;
  final bool refreshing;
  final List<KnowledgeCategory> categories;
  final List<KnowledgeDocumentSummary> pinned;
  final String? error;

  const KnowledgeHomeState({
    this.loading = false,
    this.refreshing = false,
    this.categories = const [],
    this.pinned = const [],
    this.error,
  });

  KnowledgeHomeState copyWith({
    bool? loading,
    bool? refreshing,
    List<KnowledgeCategory>? categories,
    List<KnowledgeDocumentSummary>? pinned,
    String? error,
    bool clearError = false,
  }) {
    return KnowledgeHomeState(
      loading: loading ?? this.loading,
      refreshing: refreshing ?? this.refreshing,
      categories: categories ?? this.categories,
      pinned: pinned ?? this.pinned,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [loading, refreshing, categories, pinned, error];
}

class KnowledgeHomeCubit extends Cubit<KnowledgeHomeState> {
  final KnowledgeRepository _repo;
  final String currentLanguage;

  KnowledgeHomeCubit(this._repo, {required this.currentLanguage})
      : super(const KnowledgeHomeState(loading: true)) {
    load();
  }

  Future<void> load({bool forceRefresh = false}) async {
    emit(state.copyWith(
      loading: state.categories.isEmpty,
      refreshing: state.categories.isNotEmpty,
      clearError: true,
    ));
    try {
      final categories =
          await _repo.getCategories(forceRefresh: forceRefresh);
      final pinned =
          await _repo.getPinnedDocuments(language: currentLanguage);
      emit(state.copyWith(
        loading: false,
        refreshing: false,
        categories: categories,
        pinned: pinned,
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
}
