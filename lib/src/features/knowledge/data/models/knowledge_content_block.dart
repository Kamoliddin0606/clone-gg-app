import 'dart:convert';

import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_media.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/domain/enums/block_type.dart';

/// Polymorphic content block. The `data` map carries type-specific
/// fields verbatim from the backend; subclasses expose typed getters
/// over it. Forward-compat: unknown wire `block_type` values map to
/// [UnknownBlock], which the renderer treats as a no-op.
sealed class KnowledgeContentBlock {
  final String id;
  final String organizationId;
  final String sectionId;
  final int order;
  final BlockType blockType;
  final Map<String, dynamic> data;
  final KnowledgeMedia? media;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const KnowledgeContentBlock({
    required this.id,
    required this.organizationId,
    required this.sectionId,
    required this.order,
    required this.blockType,
    required this.data,
    this.media,
    required this.updatedAt,
    this.deletedAt,
  });

  factory KnowledgeContentBlock.fromJson(
    Map<String, dynamic> json, {
    String organizationId = '',
    String sectionId = '',
  }) {
    final type = BlockTypeX.fromString(json['block_type'] as String?);
    final id = json['id'] as String;
    final order = (json['order'] as int?) ?? 0;
    final data = (json['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final mediaJson = json['media'];
    final media = (mediaJson is Map<String, dynamic>)
        ? KnowledgeMedia.fromJson(mediaJson)
        : null;
    final orgId = (json['organization_id'] as String?) ?? organizationId;
    final secId = (json['section_id'] as String?) ?? sectionId;
    final updatedAt = DateTime.tryParse((json['updated_at'] as String?) ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final deletedAt = json['deleted_at'] != null
        ? DateTime.tryParse(json['deleted_at'] as String)
        : null;

    return _construct(
      type: type,
      id: id,
      organizationId: orgId,
      sectionId: secId,
      order: order,
      data: data,
      media: media,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  factory KnowledgeContentBlock.fromDbMap(
    Map<String, dynamic> row, {
    KnowledgeMedia? media,
  }) {
    final type = BlockTypeX.fromString(row['block_type'] as String?);
    final dataRaw = row['data_json'] as String?;
    final data = (dataRaw == null || dataRaw.isEmpty)
        ? <String, dynamic>{}
        : (jsonDecode(dataRaw) as Map).cast<String, dynamic>();

    return _construct(
      type: type,
      id: row['id'] as String,
      organizationId: (row['organization_id'] as String?) ?? '',
      sectionId: row['section_id'] as String,
      order: (row['order_idx'] as int?) ?? 0,
      data: data,
      media: media,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (row['updated_at'] as int?) ?? 0),
      deletedAt: row['deleted_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['deleted_at'] as int)
          : null,
    );
  }

  static KnowledgeContentBlock _construct({
    required BlockType type,
    required String id,
    required String organizationId,
    required String sectionId,
    required int order,
    required Map<String, dynamic> data,
    required KnowledgeMedia? media,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) {
    return switch (type) {
      BlockType.paragraph => ParagraphBlock(
          id: id,
          organizationId: organizationId,
          sectionId: sectionId,
          order: order,
          data: data,
          media: media,
          updatedAt: updatedAt,
          deletedAt: deletedAt,
        ),
      BlockType.heading => HeadingBlock(
          id: id,
          organizationId: organizationId,
          sectionId: sectionId,
          order: order,
          data: data,
          media: media,
          updatedAt: updatedAt,
          deletedAt: deletedAt,
        ),
      BlockType.list => ListBlock(
          id: id,
          organizationId: organizationId,
          sectionId: sectionId,
          order: order,
          data: data,
          media: media,
          updatedAt: updatedAt,
          deletedAt: deletedAt,
        ),
      BlockType.quote => QuoteBlock(
          id: id,
          organizationId: organizationId,
          sectionId: sectionId,
          order: order,
          data: data,
          media: media,
          updatedAt: updatedAt,
          deletedAt: deletedAt,
        ),
      BlockType.callout => CalloutBlock(
          id: id,
          organizationId: organizationId,
          sectionId: sectionId,
          order: order,
          data: data,
          media: media,
          updatedAt: updatedAt,
          deletedAt: deletedAt,
        ),
      BlockType.image => ImageBlock(
          id: id,
          organizationId: organizationId,
          sectionId: sectionId,
          order: order,
          data: data,
          media: media,
          updatedAt: updatedAt,
          deletedAt: deletedAt,
        ),
      BlockType.embed => EmbedBlock(
          id: id,
          organizationId: organizationId,
          sectionId: sectionId,
          order: order,
          data: data,
          media: media,
          updatedAt: updatedAt,
          deletedAt: deletedAt,
        ),
      BlockType.code => CodeBlock(
          id: id,
          organizationId: organizationId,
          sectionId: sectionId,
          order: order,
          data: data,
          media: media,
          updatedAt: updatedAt,
          deletedAt: deletedAt,
        ),
      BlockType.table => TableBlock(
          id: id,
          organizationId: organizationId,
          sectionId: sectionId,
          order: order,
          data: data,
          media: media,
          updatedAt: updatedAt,
          deletedAt: deletedAt,
        ),
      BlockType.divider => DividerBlock(
          id: id,
          organizationId: organizationId,
          sectionId: sectionId,
          order: order,
          data: data,
          media: media,
          updatedAt: updatedAt,
          deletedAt: deletedAt,
        ),
      BlockType.file => FileBlock(
          id: id,
          organizationId: organizationId,
          sectionId: sectionId,
          order: order,
          data: data,
          media: media,
          updatedAt: updatedAt,
          deletedAt: deletedAt,
        ),
      BlockType.unknown => UnknownBlock(
          id: id,
          organizationId: organizationId,
          sectionId: sectionId,
          order: order,
          data: data,
          media: media,
          updatedAt: updatedAt,
          deletedAt: deletedAt,
        ),
    };
  }

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'organization_id': organizationId,
        'section_id': sectionId,
        'order_idx': order,
        'block_type': blockType.wireValue,
        'data_json': jsonEncode(data),
        'media_id': media?.id,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
      };

  /// Localised markdown text — present on PARAGRAPH / QUOTE / CALLOUT
  /// blocks. Returns null when the requested language has no
  /// translation; callers should fall back to another available locale.
  String? markdownFor(String lang) {
    final m = data['markdown_i18n'] ?? data['text_i18n'];
    if (m is Map) {
      final v = m[lang];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  /// Localised caption — present on IMAGE / EMBED / FILE blocks.
  String? captionFor(String lang) {
    final m = data['caption_i18n'];
    if (m is Map) {
      final v = m[lang];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }
}

class ParagraphBlock extends KnowledgeContentBlock {
  const ParagraphBlock({
    required super.id,
    required super.organizationId,
    required super.sectionId,
    required super.order,
    required super.data,
    super.media,
    required super.updatedAt,
    super.deletedAt,
  }) : super(blockType: BlockType.paragraph);
}

class HeadingBlock extends KnowledgeContentBlock {
  const HeadingBlock({
    required super.id,
    required super.organizationId,
    required super.sectionId,
    required super.order,
    required super.data,
    super.media,
    required super.updatedAt,
    super.deletedAt,
  }) : super(blockType: BlockType.heading);

  /// Heading level 1..4. Defaults to 2 when the backend omits it.
  int get level {
    final raw = data['level'];
    if (raw is int) return raw.clamp(1, 4);
    if (raw is String) return (int.tryParse(raw) ?? 2).clamp(1, 4);
    return 2;
  }

  String? textFor(String lang) {
    final m = data['text_i18n'];
    if (m is Map) {
      final v = m[lang];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }
}

class ListBlock extends KnowledgeContentBlock {
  const ListBlock({
    required super.id,
    required super.organizationId,
    required super.sectionId,
    required super.order,
    required super.data,
    super.media,
    required super.updatedAt,
    super.deletedAt,
  }) : super(blockType: BlockType.list);

  /// `bullet` (default), `ordered`, or `check`.
  String get style {
    final v = data['style'];
    if (v is String && v.isNotEmpty) return v;
    return 'bullet';
  }

  List<String> itemsFor(String lang) {
    final all = data['items_i18n'];
    if (all is Map) {
      final list = all[lang];
      if (list is List) {
        return list.map((e) => e?.toString() ?? '').toList();
      }
    }
    return const [];
  }
}

class QuoteBlock extends KnowledgeContentBlock {
  const QuoteBlock({
    required super.id,
    required super.organizationId,
    required super.sectionId,
    required super.order,
    required super.data,
    super.media,
    required super.updatedAt,
    super.deletedAt,
  }) : super(blockType: BlockType.quote);

  String? citation() => data['citation'] as String?;
}

class CalloutBlock extends KnowledgeContentBlock {
  const CalloutBlock({
    required super.id,
    required super.organizationId,
    required super.sectionId,
    required super.order,
    required super.data,
    super.media,
    required super.updatedAt,
    super.deletedAt,
  }) : super(blockType: BlockType.callout);

  /// `info` (default), `warn`, `danger`, `success`.
  String get variant {
    final v = data['variant'];
    if (v is String && v.isNotEmpty) return v;
    return 'info';
  }
}

class ImageBlock extends KnowledgeContentBlock {
  const ImageBlock({
    required super.id,
    required super.organizationId,
    required super.sectionId,
    required super.order,
    required super.data,
    super.media,
    required super.updatedAt,
    super.deletedAt,
  }) : super(blockType: BlockType.image);

  /// `contain` (default) or `cover`.
  String get fit {
    final v = data['fit'];
    if (v is String && v.isNotEmpty) return v;
    return 'contain';
  }
}

class EmbedBlock extends KnowledgeContentBlock {
  const EmbedBlock({
    required super.id,
    required super.organizationId,
    required super.sectionId,
    required super.order,
    required super.data,
    super.media,
    required super.updatedAt,
    super.deletedAt,
  }) : super(blockType: BlockType.embed);

  String get provider => (data['provider'] as String?) ?? 'youtube';
  String get embedId => (data['embed_id'] as String?) ?? '';
  String? get url => data['url'] as String?;
}

class CodeBlock extends KnowledgeContentBlock {
  const CodeBlock({
    required super.id,
    required super.organizationId,
    required super.sectionId,
    required super.order,
    required super.data,
    super.media,
    required super.updatedAt,
    super.deletedAt,
  }) : super(blockType: BlockType.code);

  String? get language => data['language'] as String?;
  String get code => (data['code'] as String?) ?? '';
}

class TableBlock extends KnowledgeContentBlock {
  const TableBlock({
    required super.id,
    required super.organizationId,
    required super.sectionId,
    required super.order,
    required super.data,
    super.media,
    required super.updatedAt,
    super.deletedAt,
  }) : super(blockType: BlockType.table);

  List<String> headersFor(String lang) {
    final m = data['headers_i18n'];
    if (m is Map) {
      final list = m[lang];
      if (list is List) return list.map((e) => e?.toString() ?? '').toList();
    }
    return const [];
  }

  List<List<String>> rowsFor(String lang) {
    final m = data['rows_i18n'];
    if (m is Map) {
      final raw = m[lang];
      if (raw is List) {
        return raw.map<List<String>>((row) {
          if (row is List) return row.map((c) => c?.toString() ?? '').toList();
          return const [];
        }).toList();
      }
    }
    return const [];
  }
}

class DividerBlock extends KnowledgeContentBlock {
  const DividerBlock({
    required super.id,
    required super.organizationId,
    required super.sectionId,
    required super.order,
    required super.data,
    super.media,
    required super.updatedAt,
    super.deletedAt,
  }) : super(blockType: BlockType.divider);
}

class FileBlock extends KnowledgeContentBlock {
  const FileBlock({
    required super.id,
    required super.organizationId,
    required super.sectionId,
    required super.order,
    required super.data,
    super.media,
    required super.updatedAt,
    super.deletedAt,
  }) : super(blockType: BlockType.file);

  String? get filename => data['filename'] as String?;
}

class UnknownBlock extends KnowledgeContentBlock {
  const UnknownBlock({
    required super.id,
    required super.organizationId,
    required super.sectionId,
    required super.order,
    required super.data,
    super.media,
    required super.updatedAt,
    super.deletedAt,
  }) : super(blockType: BlockType.unknown);
}
