import 'package:flutter/foundation.dart';

import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_document.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/services/knowledge_api_service.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/services/knowledge_db_dao.dart';

/// Drives the Knowledge Base offline cache.
///
/// The primary entry point is [syncIncremental] — `since=` cursor +
/// per-resource added/updated/deleted application. Per-resource methods
/// (used by the orchestrator's table-level sync) all funnel through
/// the same incremental call so a manual "sync categories" still
/// honours the cursor and keeps tombstones consistent.
///
/// `forceRefresh=true` resets the cursor before syncing — a heavy-handed
/// "redownload everything" path used by the Settings → Data tab when
/// the user explicitly asks for it.
class KnowledgeSyncService {
  final KnowledgeApiService _api;
  final KnowledgeDbDao _dao;

  /// Per-resource throttle window. Repeated `forceRefresh=false` calls
  /// inside this window short-circuit to avoid hammering `/sync/` on
  /// rapid UI re-entry (pull-to-refresh, page revisits).
  static const Duration _softRefreshTtl = Duration(minutes: 30);

  static const String _resourceKey = 'knowledge';

  KnowledgeSyncService(this._api, this._dao);

  Future<void> syncIncremental({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await _dao.setLastSyncedAt(_resourceKey,
          DateTime.fromMillisecondsSinceEpoch(0));
    }

    final since = await _dao.getLastSyncedAt(_resourceKey);
    if (kDebugMode) {
      print('KnowledgeSyncService.syncIncremental: since=$since');
    }

    final bundle = await _api.sync(since: since);

    // Apply in dependency order: media first (referenced by docs +
    // blocks), then categories, documents (with their inlined
    // translations + tags), translations, sections, blocks, tag
    // links, assignments, and finally per-resource tag rows.
    await _dao.upsertMedia(bundle.media.addedAndUpdated);
    await _dao.deleteByIds('knowledge_media', bundle.media.deleted);

    await _dao.upsertCategories(bundle.categories.addedAndUpdated);
    await _dao.deleteByIds('knowledge_categories', bundle.categories.deleted);

    await _dao.upsertDocumentSummaries(bundle.documents.addedAndUpdated);
    await _dao.deleteByIds('knowledge_documents', bundle.documents.deleted);

    await _dao.upsertTranslations(bundle.translations.addedAndUpdated);
    // Translations don't carry their own ids — `deleted` lists are
    // applied by document_id when the doc itself is removed via the
    // `deleted_at` cascade. Nothing to do here.

    await _dao.upsertSections(bundle.sections.addedAndUpdated);
    await _dao.deleteByIds('knowledge_sections', bundle.sections.deleted);

    await _dao.upsertContentBlocks(bundle.contentBlocks.addedAndUpdated);
    await _dao.deleteByIds(
        'knowledge_content_blocks', bundle.contentBlocks.deleted);

    await _dao.upsertTags(bundle.tags.addedAndUpdated);
    await _dao.deleteByIds('knowledge_tags', bundle.tags.deleted);

    await _dao.upsertDocumentTagLinks(bundle.documentTagLinks);
    // Deleted tag links arrive as {document_id, tag_id} pairs — handled
    // implicitly when either side is deleted, plus we already wipe and
    // re-insert links per-document on detail upsert.

    await _dao.upsertAssignments(bundle.assignments.addedAndUpdated);
    await _dao.deleteByIds(
        'knowledge_assignments', bundle.assignments.deleted);

    await _dao.setLastSyncedAt(_resourceKey, bundle.serverTime);
  }

  /// Per-resource entry points used by `DataSyncOrchestrator` table
  /// rows. They all share the same incremental sync — the orchestrator
  /// just needs *something* to await per row, and running multiple
  /// `/sync/` calls in parallel would just waste bandwidth.
  ///
  /// `forceRefresh=true` (orchestrator manual sync) bypasses the
  /// throttle. Without it, repeat calls inside [_softRefreshTtl] are
  /// no-ops.
  Future<void> syncCategories({bool forceRefresh = false}) =>
      _runOnceOrShared(forceRefresh: forceRefresh);
  Future<void> syncDocuments({bool forceRefresh = false}) =>
      _runOnceOrShared(forceRefresh: forceRefresh);
  Future<void> syncDocumentTranslations({bool forceRefresh = false}) =>
      _runOnceOrShared(forceRefresh: forceRefresh);
  Future<void> syncSections({bool forceRefresh = false}) =>
      _runOnceOrShared(forceRefresh: forceRefresh);
  Future<void> syncContentBlocks({bool forceRefresh = false}) =>
      _runOnceOrShared(forceRefresh: forceRefresh);
  Future<void> syncAssignments({bool forceRefresh = false}) =>
      _runOnceOrShared(forceRefresh: forceRefresh);
  Future<void> syncTags({bool forceRefresh = false}) =>
      _runOnceOrShared(forceRefresh: forceRefresh);

  /// Detail fetch — bypasses `/sync/` entirely. Hits `/documents/<id>/`
  /// and atomically replaces the local detail rows.
  Future<KnowledgeDocument> fetchDocumentDetail(String id) async {
    final fresh = await _api.getDocumentDetail(id);
    await _dao.upsertDocumentDetail(fresh);
    return fresh;
  }

  Future<KnowledgeDocument?> readCachedDocumentDetail(String id) =>
      _dao.getDocumentWithDetail(id);

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void>? _inFlight;

  Future<void> _runOnceOrShared({required bool forceRefresh}) async {
    // Coalesce concurrent callers — orchestrator may invoke us from
    // multiple table rows in parallel, but `/sync/` is one envelope
    // for the entire feature.
    final existing = _inFlight;
    if (existing != null) return existing;

    final last = await _dao.getLastSyncedAt(_resourceKey);
    if (!forceRefresh && last != null) {
      final elapsed = DateTime.now().difference(last);
      if (elapsed < _softRefreshTtl) {
        if (kDebugMode) {
          print(
              'KnowledgeSyncService: throttled (last=$last, elapsed=${elapsed.inMinutes}m)');
        }
        return;
      }
    }

    final future = syncIncremental(forceRefresh: forceRefresh);
    _inFlight = future;
    try {
      await future;
    } finally {
      _inFlight = null;
    }
  }
}
