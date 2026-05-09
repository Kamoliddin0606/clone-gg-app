import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_document_summary.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/repositories/knowledge_repository.dart';

class KnowledgeSearchState extends Equatable {
  final String query;
  final bool searching;
  final List<KnowledgeDocumentSummary> results;
  final String? error;

  const KnowledgeSearchState({
    this.query = '',
    this.searching = false,
    this.results = const [],
    this.error,
  });

  KnowledgeSearchState copyWith({
    String? query,
    bool? searching,
    List<KnowledgeDocumentSummary>? results,
    String? error,
    bool clearError = false,
  }) {
    return KnowledgeSearchState(
      query: query ?? this.query,
      searching: searching ?? this.searching,
      results: results ?? this.results,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [query, searching, results, error];
}

class KnowledgeSearchCubit extends Cubit<KnowledgeSearchState> {
  final KnowledgeRepository _repo;
  final String currentLanguage;

  Timer? _debounce;

  KnowledgeSearchCubit(this._repo, {required this.currentLanguage})
      : super(const KnowledgeSearchState());

  void onQueryChanged(String q) {
    final trimmed = q.trim();
    emit(state.copyWith(query: trimmed));
    _debounce?.cancel();
    if (trimmed.isEmpty) {
      emit(state.copyWith(results: const [], searching: false, clearError: true));
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _run(trimmed));
  }

  Future<void> _run(String query) async {
    emit(state.copyWith(searching: true, clearError: true));
    try {
      final results = await _repo.getDocuments(
        search: query,
        language: currentLanguage,
      );
      // Drop stale results if the user kept typing.
      if (state.query != query) return;
      emit(state.copyWith(searching: false, results: results));
    } catch (e) {
      if (state.query != query) return;
      emit(state.copyWith(searching: false, error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
