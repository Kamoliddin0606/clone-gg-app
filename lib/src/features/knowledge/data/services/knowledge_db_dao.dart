import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_assignment.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_category.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_content_block.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_document.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_document_summary.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_media.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_section.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_tag.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/domain/enums/doc_status.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/domain/enums/doc_type.dart';

/// SQLite CRUD for the Knowledge Base feature.
///
/// All upserts use `ConflictAlgorithm.replace`, which matches the
/// sync model: the backend is authoritative, `since=` deltas overwrite
/// local rows wholesale, and tombstones are applied via [deleteByIds].
class KnowledgeDbDao {
  final ApiDatabaseService _db;

  KnowledgeDbDao(this._db);

  // ---------------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------------

  Future<void> upsertCategories(List<KnowledgeCategory> rows) async {
    if (rows.isEmpty) return;
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final c in rows) {
        await txn.insert(
          'knowledge_categories',
          c.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<KnowledgeCategory>> getCategoryTree(String organizationId) async {
    final db = await _db.database;
    final rows = await db.query(
      'knowledge_categories',
      where: 'organization_id = ? AND deleted_at IS NULL AND is_active = 1',
      whereArgs: [organizationId],
      orderBy: 'parent_id IS NULL DESC, parent_id, order_idx, name',
    );
    return rows.map(KnowledgeCategory.fromDbMap).toList();
  }

  Future<KnowledgeCategory?> getCategoryById(String id) async {
    final db = await _db.database;
    final rows = await db.query(
      'knowledge_categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return KnowledgeCategory.fromDbMap(rows.first);
  }

  // ---------------------------------------------------------------------------
  // Documents (summaries + detail)
  // ---------------------------------------------------------------------------

  Future<void> upsertDocumentRows(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final r in rows) {
        await txn.insert(
          'knowledge_documents',
          r,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Upserts a document summary (used by the listing endpoint and by
  /// the sync feed). Translations and tags are persisted alongside.
  Future<void> upsertDocumentSummaries(
      List<KnowledgeDocumentSummary> docs) async {
    if (docs.isEmpty) return;
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final doc in docs) {
        await txn.insert(
          'knowledge_documents',
          {
            'id': doc.id,
            'organization_id': doc.organizationId,
            'category_id': doc.categoryId,
            'slug': doc.slug,
            'doc_type': doc.docType.wireValue,
            'status': doc.status.wireValue,
            'is_pinned': doc.isPinned ? 1 : 0,
            'cover_media_id': doc.coverMediaId,
            'published_at': doc.publishedAt?.millisecondsSinceEpoch,
            'expires_at': doc.expiresAt?.millisecondsSinceEpoch,
            'updated_at': doc.updatedAt.millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (doc.coverMedia != null) {
          await txn.insert(
            'knowledge_media',
            doc.coverMedia!.toDbMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        for (final t in doc.translations) {
          await txn.insert(
            'knowledge_document_translations',
            t.toDbMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Reset tag links for this doc, then re-insert
        await txn.delete(
          'knowledge_document_tags',
          where: 'document_id = ?',
          whereArgs: [doc.id],
        );
        for (final tag in doc.tags) {
          await txn.insert(
            'knowledge_tags',
            tag.toDbMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await txn.insert(
            'knowledge_document_tags',
            {'document_id': doc.id, 'tag_id': tag.id},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  /// Persist a fully hydrated document — sections, blocks, media, tags,
  /// translations, assignments. Atomic so a half-written detail does
  /// not surface in the UI.
  Future<void> upsertDocumentDetail(KnowledgeDocument doc) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      // Document row
      await txn.insert(
        'knowledge_documents',
        doc.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Cover media (if inlined)
      if (doc.coverMedia != null) {
        await txn.insert(
          'knowledge_media',
          doc.coverMedia!.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Translations
      await txn.delete(
        'knowledge_document_translations',
        where: 'document_id = ?',
        whereArgs: [doc.id],
      );
      for (final t in doc.translations) {
        await txn.insert(
          'knowledge_document_translations',
          t.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Tag links
      await txn.delete(
        'knowledge_document_tags',
        where: 'document_id = ?',
        whereArgs: [doc.id],
      );
      for (final tag in doc.tags) {
        await txn.insert(
          'knowledge_tags',
          tag.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await txn.insert(
          'knowledge_document_tags',
          {'document_id': doc.id, 'tag_id': tag.id},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Sections + blocks: replace wholesale for this doc to drop
      // anything the backend removed.
      final secIds = await txn.query(
        'knowledge_sections',
        columns: ['id'],
        where: 'document_id = ?',
        whereArgs: [doc.id],
      );
      for (final r in secIds) {
        final sid = r['id'] as String;
        await txn.delete(
          'knowledge_content_blocks',
          where: 'section_id = ?',
          whereArgs: [sid],
        );
      }
      await txn.delete(
        'knowledge_sections',
        where: 'document_id = ?',
        whereArgs: [doc.id],
      );

      for (final s in doc.sections) {
        await txn.insert(
          'knowledge_sections',
          s.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        for (final b in s.blocks) {
          if (b.media != null) {
            await txn.insert(
              'knowledge_media',
              b.media!.toDbMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await txn.insert(
            'knowledge_content_blocks',
            b.toDbMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // Assignments
      await txn.delete(
        'knowledge_assignments',
        where: 'document_id = ?',
        whereArgs: [doc.id],
      );
      for (final a in doc.assignments) {
        await txn.insert(
          'knowledge_assignments',
          a.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// List documents matching the supplied filters. The default sort
  /// surfaces pinned, recently-published documents first.
  Future<List<KnowledgeDocumentSummary>> getDocuments({
    required String organizationId,
    String? categoryId,
    DocType? docType,
    String? search,
    bool pinnedOnly = false,
    String? language,
    int limit = 200,
  }) async {
    final db = await _db.database;
    final where = <String>[
      'organization_id = ?',
      'deleted_at IS NULL',
      "(status = 'PUBLISHED' OR status IS NULL)",
    ];
    final args = <Object?>[organizationId];

    if (categoryId != null) {
      where.add('category_id = ?');
      args.add(categoryId);
    }
    if (docType != null) {
      where.add('doc_type = ?');
      args.add(docType.wireValue);
    }
    if (pinnedOnly) {
      where.add('is_pinned = 1');
    }

    final rows = await db.query(
      'knowledge_documents',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'is_pinned DESC, COALESCE(published_at, updated_at) DESC',
      limit: limit,
    );

    final docIds = rows.map((r) => r['id'] as String).toList();
    if (docIds.isEmpty) return [];

    final translations = await _readTranslations(db, docIds);
    final tagsByDoc = await _readTagsForDocuments(db, docIds);
    final mandatoryIds = await _readMandatoryDocIds(db, docIds);
    final mediaIds = rows
        .map((r) => r['cover_media_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final media = await _readMedia(db, mediaIds);

    var summaries = rows.map((row) {
      final id = row['id'] as String;
      return KnowledgeDocumentSummary(
        id: id,
        organizationId: (row['organization_id'] as String?) ?? '',
        categoryId: (row['category_id'] as String?) ?? '',
        slug: row['slug'] as String?,
        docType: DocTypeX.fromString(row['doc_type'] as String?),
        status: DocStatusX.fromString(row['status'] as String?),
        isPinned: (row['is_pinned'] as int? ?? 0) == 1,
        mandatory: mandatoryIds.contains(id),
        coverMedia: (row['cover_media_id'] as String?) != null
            ? media[row['cover_media_id'] as String]
            : null,
        coverMediaId: row['cover_media_id'] as String?,
        translations: translations[id] ?? const [],
        tags: tagsByDoc[id] ?? const [],
        publishedAt: row['published_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(row['published_at'] as int)
            : null,
        expiresAt: row['expires_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(row['expires_at'] as int)
            : null,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
            (row['updated_at'] as int?) ?? 0),
      );
    }).toList();

    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      summaries = summaries.where((s) {
        for (final t in s.translations) {
          if ((t.title ?? '').toLowerCase().contains(q)) return true;
          if ((t.summary ?? '').toLowerCase().contains(q)) return true;
        }
        for (final tag in s.tags) {
          if ((tag.name ?? '').toLowerCase().contains(q)) return true;
        }
        return false;
      }).toList();
    }

    if (language != null) {
      // Stable secondary sort: documents with a translation in the
      // requested language first.
      summaries.sort((a, b) {
        final at = a.translationFor(language) != null ? 0 : 1;
        final bt = b.translationFor(language) != null ? 0 : 1;
        if (at != bt) return at.compareTo(bt);
        final ap = a.publishedAt?.millisecondsSinceEpoch ?? 0;
        final bp = b.publishedAt?.millisecondsSinceEpoch ?? 0;
        return bp.compareTo(ap);
      });
    }

    return summaries;
  }

  /// Reconstruct a fully-hydrated document from local cache. Returns
  /// `null` if the document row is missing — callers should fall back
  /// to an API fetch in that case.
  Future<KnowledgeDocument?> getDocumentWithDetail(String id) async {
    final db = await _db.database;
    final docRows = await db.query(
      'knowledge_documents',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (docRows.isEmpty) return null;
    final docRow = docRows.first;

    final translations = (await _readTranslations(db, [id]))[id] ?? const [];
    final tags = (await _readTagsForDocuments(db, [id]))[id] ?? const [];

    final coverMediaId = docRow['cover_media_id'] as String?;
    final coverMedia = coverMediaId != null
        ? (await _readMedia(db, [coverMediaId]))[coverMediaId]
        : null;

    final sectionRows = await db.query(
      'knowledge_sections',
      where: 'document_id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      orderBy: 'parent_id IS NULL DESC, parent_id, order_idx',
    );
    final sectionIds = sectionRows.map((r) => r['id'] as String).toList();

    final blockRows = sectionIds.isEmpty
        ? const <Map<String, Object?>>[]
        : await db.query(
            'knowledge_content_blocks',
            where:
                "section_id IN (${List.filled(sectionIds.length, '?').join(',')}) AND deleted_at IS NULL",
            whereArgs: sectionIds,
            orderBy: 'section_id, order_idx',
          );

    final blockMediaIds = blockRows
        .map((r) => r['media_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final blockMedia = await _readMedia(db, blockMediaIds);

    final blocksBySection = <String, List<KnowledgeContentBlock>>{};
    for (final r in blockRows) {
      final secId = r['section_id'] as String;
      final mediaId = r['media_id'] as String?;
      final block = KnowledgeContentBlock.fromDbMap(
        r,
        media: mediaId != null ? blockMedia[mediaId] : null,
      );
      blocksBySection.putIfAbsent(secId, () => []).add(block);
    }

    final sections = sectionRows.map((r) {
      final secId = r['id'] as String;
      return KnowledgeSection.fromDbMap(
        r,
        blocks: blocksBySection[secId] ?? const [],
      );
    }).toList();

    final assignmentRows = await db.query(
      'knowledge_assignments',
      where: 'document_id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    final assignments =
        assignmentRows.map(KnowledgeAssignment.fromDbMap).toList();

    return KnowledgeDocument.fromDbMap(
      docRow,
      coverMedia: coverMedia,
      translations: translations,
      tags: tags,
      sections: sections,
      assignments: assignments,
    );
  }

  // ---------------------------------------------------------------------------
  // Single-resource upserts (sync feed)
  // ---------------------------------------------------------------------------

  Future<void> upsertSections(List<KnowledgeSection> rows) async {
    if (rows.isEmpty) return;
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final s in rows) {
        await txn.insert(
          'knowledge_sections',
          s.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> upsertContentBlocks(List<KnowledgeContentBlock> rows) async {
    if (rows.isEmpty) return;
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final b in rows) {
        if (b.media != null) {
          await txn.insert(
            'knowledge_media',
            b.media!.toDbMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await txn.insert(
          'knowledge_content_blocks',
          b.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> upsertAssignments(List<KnowledgeAssignment> rows) async {
    if (rows.isEmpty) return;
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final a in rows) {
        await txn.insert(
          'knowledge_assignments',
          a.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> upsertTags(List<KnowledgeTag> rows) async {
    if (rows.isEmpty) return;
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final t in rows) {
        await txn.insert(
          'knowledge_tags',
          t.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> upsertDocumentTagLinks(
      List<Map<String, String>> links) async {
    if (links.isEmpty) return;
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final l in links) {
        await txn.insert(
          'knowledge_document_tags',
          l,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> upsertTranslations(
      List<KnowledgeDocumentTranslation> rows) async {
    if (rows.isEmpty) return;
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final t in rows) {
        await txn.insert(
          'knowledge_document_translations',
          t.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> upsertMedia(List<KnowledgeMedia> rows) async {
    if (rows.isEmpty) return;
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final m in rows) {
        await txn.insert(
          'knowledge_media',
          m.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Tombstones
  // ---------------------------------------------------------------------------

  Future<void> deleteByIds(String table, List<String> ids,
      {String column = 'id'}) async {
    if (ids.isEmpty) return;
    final db = await _db.database;
    await db.transaction((txn) async {
      // Use chunks to stay under SQLITE_MAX_VARIABLE_NUMBER (~999).
      const chunkSize = 500;
      for (var i = 0; i < ids.length; i += chunkSize) {
        final chunk = ids.sublist(i, (i + chunkSize).clamp(0, ids.length));
        final placeholders = List.filled(chunk.length, '?').join(',');
        await txn.delete(
          table,
          where: '$column IN ($placeholders)',
          whereArgs: chunk,
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Sync state
  // ---------------------------------------------------------------------------

  Future<DateTime?> getLastSyncedAt(String resource) async {
    final db = await _db.database;
    final rows = await db.query(
      'knowledge_sync_state',
      where: 'resource_name = ?',
      whereArgs: [resource],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['last_synced_at'] as int?;
    if (raw == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }

  Future<void> setLastSyncedAt(String resource, DateTime ts) async {
    final db = await _db.database;
    await db.insert(
      'knowledge_sync_state',
      {
        'resource_name': resource,
        'last_synced_at': ts.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<Map<String, List<KnowledgeDocumentTranslation>>> _readTranslations(
    Database db,
    List<String> docIds,
  ) async {
    if (docIds.isEmpty) return const {};
    final rows = await db.query(
      'knowledge_document_translations',
      where:
          'document_id IN (${List.filled(docIds.length, '?').join(',')})',
      whereArgs: docIds,
    );
    final out = <String, List<KnowledgeDocumentTranslation>>{};
    for (final r in rows) {
      final docId = r['document_id'] as String;
      out
          .putIfAbsent(docId, () => [])
          .add(KnowledgeDocumentTranslation.fromDbMap(r));
    }
    return out;
  }

  Future<Map<String, List<KnowledgeTag>>> _readTagsForDocuments(
    Database db,
    List<String> docIds,
  ) async {
    if (docIds.isEmpty) return const {};
    final placeholders = List.filled(docIds.length, '?').join(',');
    final links = await db.rawQuery(
      'SELECT dt.document_id, t.id, t.organization_id, t.slug, t.name, t.updated_at, t.deleted_at '
      'FROM knowledge_document_tags dt '
      'JOIN knowledge_tags t ON t.id = dt.tag_id '
      'WHERE dt.document_id IN ($placeholders) AND t.deleted_at IS NULL',
      docIds,
    );
    final out = <String, List<KnowledgeTag>>{};
    for (final r in links) {
      final docId = r['document_id'] as String;
      out.putIfAbsent(docId, () => []).add(KnowledgeTag.fromDbMap(r));
    }
    return out;
  }

  /// Returns the subset of [docIds] that have at least one
  /// non-deleted assignment row with `mandatory = 1`. Used by
  /// listings to surface the "Majburiy" badge — the actual
  /// visibility filter (which user/staff/role sees what) is enforced
  /// server-side, so the doc being in the list at all already means
  /// the agent has access to it.
  Future<Set<String>> _readMandatoryDocIds(
    Database db,
    List<String> docIds,
  ) async {
    if (docIds.isEmpty) return const <String>{};
    final out = <String>{};
    const chunkSize = 500;
    for (var i = 0; i < docIds.length; i += chunkSize) {
      final chunk =
          docIds.sublist(i, (i + chunkSize).clamp(0, docIds.length));
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await db.rawQuery(
        'SELECT DISTINCT document_id FROM knowledge_assignments '
        'WHERE document_id IN ($placeholders) AND mandatory = 1 '
        'AND deleted_at IS NULL',
        chunk,
      );
      for (final r in rows) {
        final id = r['document_id'];
        if (id is String) out.add(id);
      }
    }
    return out;
  }

  Future<Map<String, KnowledgeMedia>> _readMedia(
    Database db,
    List<String> mediaIds,
  ) async {
    if (mediaIds.isEmpty) return const {};
    final out = <String, KnowledgeMedia>{};
    const chunkSize = 500;
    for (var i = 0; i < mediaIds.length; i += chunkSize) {
      final chunk =
          mediaIds.sublist(i, (i + chunkSize).clamp(0, mediaIds.length));
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await db.query(
        'knowledge_media',
        where: 'id IN ($placeholders)',
        whereArgs: chunk,
      );
      for (final r in rows) {
        final m = KnowledgeMedia.fromDbMap(r);
        out[m.id] = m;
      }
    }
    return out;
  }

  Future<int> countDocuments(String organizationId) async {
    final db = await _db.database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM knowledge_documents WHERE organization_id = ? AND deleted_at IS NULL',
      [organizationId],
    );
    final c = res.first['c'];
    if (c is int) return c;
    return int.tryParse('${c ?? 0}') ?? 0;
  }

  /// Diagnostic — prints row counts for each knowledge table. Used
  /// from the dev DB Viewer page.
  Future<Map<String, int>> debugCounts() async {
    final db = await _db.database;
    const tables = [
      'knowledge_categories',
      'knowledge_documents',
      'knowledge_document_translations',
      'knowledge_sections',
      'knowledge_content_blocks',
      'knowledge_media',
      'knowledge_assignments',
      'knowledge_tags',
      'knowledge_document_tags',
    ];
    final out = <String, int>{};
    for (final t in tables) {
      try {
        final res = await db.rawQuery('SELECT COUNT(*) AS c FROM $t');
        final c = res.first['c'];
        out[t] = c is int ? c : int.tryParse('${c ?? 0}') ?? 0;
      } catch (e) {
        if (kDebugMode) print('KnowledgeDbDao.debugCounts: $t failed: $e');
        out[t] = -1;
      }
    }
    return out;
  }
}
