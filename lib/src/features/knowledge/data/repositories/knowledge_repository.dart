import 'package:flutter/foundation.dart';

import 'package:gloria_marketing_flutter/src/core/services/images/agent_organization_context.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_category.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_document.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_document_summary.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/services/knowledge_db_dao.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/services/knowledge_sync_service.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/domain/enums/doc_type.dart';

/// Offline-first facade over the cache + sync. UI layers call into
/// this one class for everything; the throttle / network-error
/// handling lives here so cubits stay simple.
///
/// All read methods return cached rows even when sync fails — knowing
/// the cache is mostly fresh (within [_softRefreshTtl]) is good enough
/// for the listings; the detail page does an explicit background
/// refresh when it has a cached copy.
class KnowledgeRepository {
  final KnowledgeSyncService _sync;
  final KnowledgeDbDao _dao;
  final AgentOrganizationContext _orgContext;

  KnowledgeRepository(this._sync, this._dao, this._orgContext);

  String get _orgId => _orgContext.primaryOrganizationId ?? '';

  Future<List<KnowledgeCategory>> getCategories({bool forceRefresh = false}) async {
    try {
      await _sync.syncIncremental(forceRefresh: forceRefresh);
    } catch (e) {
      if (kDebugMode) {
        print('KnowledgeRepository.getCategories sync failed: $e');
      }
    }
    final cats = await _dao.getCategoryTree(_orgId);
    if (kDebugMode) {
      print(
          'KnowledgeRepository.getCategories: orgId=$_orgId returned ${cats.length} rows');
    }
    return cats;
  }

  Future<List<KnowledgeDocumentSummary>> getDocuments({
    String? categoryId,
    DocType? docType,
    String? search,
    bool pinnedOnly = false,
    String? language,
    bool forceRefresh = false,
  }) async {
    try {
      await _sync.syncIncremental(forceRefresh: forceRefresh);
    } catch (e) {
      if (kDebugMode) {
        print('KnowledgeRepository.getDocuments sync failed: $e');
      }
    }
    return _dao.getDocuments(
      organizationId: _orgId,
      categoryId: categoryId,
      docType: docType,
      search: search,
      pinnedOnly: pinnedOnly,
      language: language,
    );
  }

  Future<List<KnowledgeDocumentSummary>> getPinnedDocuments({
    String? language,
  }) async {
    try {
      await _sync.syncIncremental();
    } catch (_) {}
    return _dao.getDocuments(
      organizationId: _orgId,
      pinnedOnly: true,
      language: language,
    );
  }

  /// Detail with stale-while-revalidate: when a cached copy exists we
  /// return it immediately and refresh in the background; first-time
  /// loads block on the network call.
  Future<KnowledgeDocument> getDocumentDetail(String id) async {
    final cached = await _sync.readCachedDocumentDetail(id);
    if (cached != null) {
      // Background refresh — fire and forget, errors swallowed.
      _sync.fetchDocumentDetail(id).catchError((Object e) {
        if (kDebugMode) {
          print('KnowledgeRepository: bg refresh of $id failed: $e');
        }
        return cached;
      });
      return cached;
    }
    return _sync.fetchDocumentDetail(id);
  }

  Future<KnowledgeDocument?> getCachedDocumentDetail(String id) =>
      _sync.readCachedDocumentDetail(id);

  Future<KnowledgeCategory?> getCategoryById(String id) =>
      _dao.getCategoryById(id);

  Future<int> cachedDocumentCount() => _dao.countDocuments(_orgId);
}
