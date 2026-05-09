import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_document.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_media.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_tag.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/domain/enums/doc_status.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/domain/enums/doc_type.dart';

/// Lightweight projection used by listings (category page, search, pinned
/// carousel). Detail-only fields (sections, blocks, assignments) are
/// fetched lazily via [KnowledgeApiService.getDocumentDetail].
class KnowledgeDocumentSummary {
  final String id;
  final String organizationId;
  final String categoryId;
  final String? slug;
  final DocType docType;
  final DocStatus status;
  final bool isPinned;
  final KnowledgeMedia? coverMedia;
  final String? coverMediaId;
  final List<KnowledgeDocumentTranslation> translations;
  final List<KnowledgeTag> tags;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final DateTime updatedAt;

  const KnowledgeDocumentSummary({
    required this.id,
    required this.organizationId,
    required this.categoryId,
    this.slug,
    this.docType = DocType.unknown,
    this.status = DocStatus.unknown,
    this.isPinned = false,
    this.coverMedia,
    this.coverMediaId,
    this.translations = const [],
    this.tags = const [],
    this.publishedAt,
    this.expiresAt,
    required this.updatedAt,
  });

  factory KnowledgeDocumentSummary.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;

    final coverRaw = json['cover_media'];
    final cover = (coverRaw is Map<String, dynamic>)
        ? KnowledgeMedia.fromJson(coverRaw)
        : null;

    final translations = <KnowledgeDocumentTranslation>[];
    final transRaw = json['translations'];
    if (transRaw is List) {
      for (final t in transRaw) {
        if (t is Map<String, dynamic>) {
          translations.add(
            KnowledgeDocumentTranslation.fromJson(t, documentId: id),
          );
        }
      }
    }

    final tags = <KnowledgeTag>[];
    final tagsRaw = json['tags'];
    if (tagsRaw is List) {
      for (final t in tagsRaw) {
        if (t is Map<String, dynamic>) tags.add(KnowledgeTag.fromJson(t));
      }
    }

    return KnowledgeDocumentSummary(
      id: id,
      organizationId: (json['organization_id'] as String?) ?? '',
      categoryId: (json['category_id'] as String?) ?? '',
      slug: json['slug'] as String?,
      docType: DocTypeX.fromString(json['doc_type'] as String?),
      status: DocStatusX.fromString(json['status'] as String?),
      isPinned: (json['is_pinned'] as bool?) ?? false,
      coverMedia: cover,
      coverMediaId: cover?.id ?? json['cover_media_id'] as String?,
      translations: translations,
      tags: tags,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      updatedAt: DateTime.tryParse((json['updated_at'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  KnowledgeDocumentTranslation? translationFor(String lang) {
    if (translations.isEmpty) return null;
    for (final candidate in [lang, 'en', 'ru', 'uz']) {
      for (final t in translations) {
        if (t.language == candidate) return t;
      }
    }
    return translations.first;
  }

  String? titleFor(String lang) => translationFor(lang)?.title;
  String? summaryFor(String lang) => translationFor(lang)?.summary;
}

/// Generic paginated wrapper used by the listing endpoint.
class PaginatedResponse<T> {
  final List<T> results;
  final int count;
  final String? next;
  final String? previous;

  const PaginatedResponse({
    required this.results,
    this.count = 0,
    this.next,
    this.previous,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final results = <T>[];
    final raw = json['results'];
    if (raw is List) {
      for (final r in raw) {
        if (r is Map<String, dynamic>) results.add(itemFromJson(r));
      }
    }
    return PaginatedResponse(
      results: results,
      count: (json['count'] as int?) ?? results.length,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
    );
  }
}
