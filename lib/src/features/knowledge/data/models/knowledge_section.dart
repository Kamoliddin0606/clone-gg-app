import 'dart:convert';

import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_content_block.dart';

class KnowledgeSection {
  final String id;
  final String organizationId;
  final String documentId;
  final String? parentId;
  final String? anchor;
  final Map<String, String> titleI18n;
  final int orderIdx;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<KnowledgeContentBlock> blocks;

  const KnowledgeSection({
    required this.id,
    required this.organizationId,
    required this.documentId,
    this.parentId,
    this.anchor,
    this.titleI18n = const {},
    this.orderIdx = 0,
    required this.updatedAt,
    this.deletedAt,
    this.blocks = const [],
  });

  factory KnowledgeSection.fromJson(
    Map<String, dynamic> json, {
    String organizationId = '',
    String documentId = '',
  }) {
    final orgId = (json['organization_id'] as String?) ?? organizationId;
    final docId = (json['document_id'] as String?) ?? documentId;
    final id = json['id'] as String;

    final titleRaw = json['title_i18n'];
    final titleI18n = <String, String>{};
    if (titleRaw is Map) {
      titleRaw.forEach((k, v) {
        if (v is String) titleI18n[k.toString()] = v;
      });
    }

    final blocksRaw = json['blocks'];
    final blocks = <KnowledgeContentBlock>[];
    if (blocksRaw is List) {
      for (final b in blocksRaw) {
        if (b is Map<String, dynamic>) {
          blocks.add(KnowledgeContentBlock.fromJson(
            b,
            organizationId: orgId,
            sectionId: id,
          ));
        }
      }
    }
    blocks.sort((a, b) => a.order.compareTo(b.order));

    return KnowledgeSection(
      id: id,
      organizationId: orgId,
      documentId: docId,
      parentId: json['parent_id'] as String?,
      anchor: json['anchor'] as String?,
      titleI18n: titleI18n,
      orderIdx: (json['order'] as int?) ?? (json['order_idx'] as int?) ?? 0,
      updatedAt: DateTime.tryParse((json['updated_at'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'] as String)
          : null,
      blocks: blocks,
    );
  }

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'organization_id': organizationId,
        'document_id': documentId,
        'parent_id': parentId,
        'anchor': anchor,
        'title_i18n_json': jsonEncode(titleI18n),
        'order_idx': orderIdx,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
      };

  factory KnowledgeSection.fromDbMap(
    Map<String, dynamic> row, {
    List<KnowledgeContentBlock> blocks = const [],
  }) {
    final titleRaw = row['title_i18n_json'] as String?;
    final titleI18n = <String, String>{};
    if (titleRaw != null && titleRaw.isNotEmpty) {
      final decoded = jsonDecode(titleRaw);
      if (decoded is Map) {
        decoded.forEach((k, v) {
          if (v is String) titleI18n[k.toString()] = v;
        });
      }
    }

    return KnowledgeSection(
      id: row['id'] as String,
      organizationId: (row['organization_id'] as String?) ?? '',
      documentId: row['document_id'] as String,
      parentId: row['parent_id'] as String?,
      anchor: row['anchor'] as String?,
      titleI18n: titleI18n,
      orderIdx: (row['order_idx'] as int?) ?? 0,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (row['updated_at'] as int?) ?? 0),
      deletedAt: row['deleted_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['deleted_at'] as int)
          : null,
      blocks: blocks,
    );
  }

  String? titleFor(String lang) {
    final v = titleI18n[lang];
    if (v != null && v.isNotEmpty) return v;
    if (titleI18n.isEmpty) return null;
    return titleI18n.values.first;
  }

  KnowledgeSection copyWithBlocks(List<KnowledgeContentBlock> blocks) {
    return KnowledgeSection(
      id: id,
      organizationId: organizationId,
      documentId: documentId,
      parentId: parentId,
      anchor: anchor,
      titleI18n: titleI18n,
      orderIdx: orderIdx,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      blocks: blocks,
    );
  }
}
