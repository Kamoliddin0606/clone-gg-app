import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_document.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/repositories/knowledge_repository.dart';

class KnowledgeDocumentState extends Equatable {
  final bool loading;
  final KnowledgeDocument? document;
  final bool stale;
  final String? error;
  final String? activeSectionId;

  const KnowledgeDocumentState({
    this.loading = false,
    this.document,
    this.stale = false,
    this.error,
    this.activeSectionId,
  });

  KnowledgeDocumentState copyWith({
    bool? loading,
    KnowledgeDocument? document,
    bool? stale,
    String? error,
    String? activeSectionId,
    bool clearError = false,
  }) {
    return KnowledgeDocumentState(
      loading: loading ?? this.loading,
      document: document ?? this.document,
      stale: stale ?? this.stale,
      error: clearError ? null : (error ?? this.error),
      activeSectionId: activeSectionId ?? this.activeSectionId,
    );
  }

  @override
  List<Object?> get props =>
      [loading, document, stale, error, activeSectionId];
}

class KnowledgeDocumentCubit extends Cubit<KnowledgeDocumentState> {
  final KnowledgeRepository _repo;
  final String documentId;

  KnowledgeDocumentCubit(this._repo, {required this.documentId})
      : super(const KnowledgeDocumentState(loading: true)) {
    load();
  }

  Future<void> load() async {
    emit(state.copyWith(loading: state.document == null, clearError: true));
    try {
      // Show cache immediately if present, then refresh in background.
      final cached = await _repo.getCachedDocumentDetail(documentId);
      if (cached != null) {
        emit(state.copyWith(
          loading: false,
          document: cached,
          stale: true,
        ));
      }
      final fresh = await _repo.getDocumentDetail(documentId);
      emit(state.copyWith(
        loading: false,
        document: fresh,
        stale: false,
      ));
    } catch (e) {
      // If we already have a cached copy, surface the error softly via
      // `stale` rather than overriding the rendered document.
      if (state.document != null) {
        emit(state.copyWith(loading: false, stale: true));
      } else {
        emit(state.copyWith(loading: false, error: e.toString()));
      }
    }
  }

  Future<void> refresh() => load();

  void setActiveSection(String? id) {
    if (state.activeSectionId == id) return;
    emit(state.copyWith(activeSectionId: id));
  }
}
