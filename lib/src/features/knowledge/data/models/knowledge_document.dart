import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_assignment.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_media.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_section.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_tag.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/domain/enums/doc_status.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/domain/enums/doc_type.dart';

class KnowledgeDocumentTranslation {
  final String documentId;
  final String language;
  final String? title;
  final String? summary;

  const KnowledgeDocumentTranslation({
    required this.documentId,
    required this.language,
    this.title,
    this.summary,
  });

  factory KnowledgeDocumentTranslation.fromJson(
    Map<String, dynamic> json, {
    String documentId = '',
  }) {
    return KnowledgeDocumentTranslation(
      documentId: (json['document_id'] as String?) ?? documentId,
      language: (json['language'] as String?) ?? '',
      title: json['title'] as String?,
      summary: json['summary'] as String?,
    );
  }

  Map<String, dynamic> toDbMap() => {
        'document_id': documentId,
        'language': language,
        'title': title,
        'summary': summary,
      };

  factory KnowledgeDocumentTranslation.fromDbMap(Map<String, dynamic> row) {
    return KnowledgeDocumentTranslation(
      documentId: row['document_id'] as String,
      language: row['language'] as String,
      title: row['title'] as String?,
      summary: row['summary'] as String?,
    );
  }
}

class KnowledgeDocument {
  final String id;
  final String organizationId;
  final String categoryId;
  final String? slug;
  final DocType docType;
  final DocStatus status;
  final bool isPinned;
  final String? coverMediaId;
  final KnowledgeMedia? coverMedia;
  final List<KnowledgeDocumentTranslation> translations;
  final List<KnowledgeTag> tags;
  final List<KnowledgeSection> sections;
  final List<KnowledgeAssignment> assignments;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const KnowledgeDocument({
    required this.id,
    required this.organizationId,
    required this.categoryId,
    this.slug,
    this.docType = DocType.unknown,
    this.status = DocStatus.unknown,
    this.isPinned = false,
    this.coverMediaId,
    this.coverMedia,
    this.translations = const [],
    this.tags = const [],
    this.sections = const [],
    this.assignments = const [],
    this.publishedAt,
    this.expiresAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory KnowledgeDocument.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final orgId = (json['organization_id'] as String?) ?? '';

    final coverMediaJson = json['cover_media'];
    final cover = (coverMediaJson is Map<String, dynamic>)
        ? KnowledgeMedia.fromJson(coverMediaJson)
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

    final sections = <KnowledgeSection>[];
    final secRaw = json['sections'];
    if (secRaw is List) {
      for (final s in secRaw) {
        if (s is Map<String, dynamic>) {
          sections.add(KnowledgeSection.fromJson(
            s,
            organizationId: orgId,
            documentId: id,
          ));
        }
      }
    }
    sections.sort((a, b) => a.orderIdx.compareTo(b.orderIdx));

    final assignments = <KnowledgeAssignment>[];
    final assignRaw = json['assignments'];
    if (assignRaw is List) {
      for (final a in assignRaw) {
        if (a is Map<String, dynamic>) {
          assignments.add(KnowledgeAssignment.fromJson(a));
        }
      }
    }

    return KnowledgeDocument(
      id: id,
      organizationId: orgId,
      categoryId: (json['category_id'] as String?) ?? '',
      slug: json['slug'] as String?,
      docType: DocTypeX.fromString(json['doc_type'] as String?),
      status: DocStatusX.fromString(json['status'] as String?),
      isPinned: (json['is_pinned'] as bool?) ?? false,
      coverMediaId: cover?.id ?? json['cover_media_id'] as String?,
      coverMedia: cover,
      translations: translations,
      tags: tags,
      sections: sections,
      assignments: assignments,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      updatedAt: DateTime.tryParse((json['updated_at'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'organization_id': organizationId,
        'category_id': categoryId,
        'slug': slug,
        'doc_type': docType.wireValue,
        'status': status.wireValue,
        'is_pinned': isPinned ? 1 : 0,
        'cover_media_id': coverMediaId,
        'published_at': publishedAt?.millisecondsSinceEpoch,
        'expires_at': expiresAt?.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
      };

  factory KnowledgeDocument.fromDbMap(
    Map<String, dynamic> row, {
    KnowledgeMedia? coverMedia,
    List<KnowledgeDocumentTranslation> translations = const [],
    List<KnowledgeTag> tags = const [],
    List<KnowledgeSection> sections = const [],
    List<KnowledgeAssignment> assignments = const [],
  }) {
    return KnowledgeDocument(
      id: row['id'] as String,
      organizationId: (row['organization_id'] as String?) ?? '',
      categoryId: (row['category_id'] as String?) ?? '',
      slug: row['slug'] as String?,
      docType: DocTypeX.fromString(row['doc_type'] as String?),
      status: DocStatusX.fromString(row['status'] as String?),
      isPinned: (row['is_pinned'] as int? ?? 0) == 1,
      coverMediaId: row['cover_media_id'] as String?,
      coverMedia: coverMedia,
      translations: translations,
      tags: tags,
      sections: sections,
      assignments: assignments,
      publishedAt: row['published_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['published_at'] as int)
          : null,
      expiresAt: row['expires_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['expires_at'] as int)
          : null,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (row['updated_at'] as int?) ?? 0),
      deletedAt: row['deleted_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['deleted_at'] as int)
          : null,
    );
  }

  /// Resolve the best translation for a language. Falls back to:
  /// requested → 'en' → 'ru' → 'uz' → first available → empty.
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
