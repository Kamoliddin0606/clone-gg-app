import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:gloria_marketing_flutter/src/core/services/images/agent_organization_context.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_assignment.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_category.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_content_block.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_document.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_document_summary.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_media.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_section.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/models/knowledge_tag.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/services/knowledge_sync_response.dart';

/// Aggregated payload returned by `GET /sync/`.
class KnowledgeSyncBundle {
  final KnowledgeSyncResource<KnowledgeCategory> categories;
  final KnowledgeSyncResource<KnowledgeDocumentSummary> documents;
  final KnowledgeSyncResource<KnowledgeDocumentTranslation> translations;
  final KnowledgeSyncResource<KnowledgeSection> sections;
  final KnowledgeSyncResource<KnowledgeContentBlock> contentBlocks;
  final KnowledgeSyncResource<KnowledgeMedia> media;
  final KnowledgeSyncResource<KnowledgeAssignment> assignments;
  final KnowledgeSyncResource<KnowledgeTag> tags;
  final List<Map<String, String>> documentTagLinks;
  final List<Map<String, String>> deletedDocumentTagLinks;
  final DateTime serverTime;

  const KnowledgeSyncBundle({
    required this.categories,
    required this.documents,
    required this.translations,
    required this.sections,
    required this.contentBlocks,
    required this.media,
    required this.assignments,
    required this.tags,
    required this.documentTagLinks,
    required this.deletedDocumentTagLinks,
    required this.serverTime,
  });

  factory KnowledgeSyncBundle.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? section(String key) {
      final raw = json[key];
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return raw.cast<String, dynamic>();
      return null;
    }

    List<Map<String, String>> parseLinks(dynamic raw) {
      if (raw is! List) return const [];
      final out = <Map<String, String>>[];
      for (final v in raw) {
        if (v is Map) {
          final docId = v['document_id']?.toString();
          final tagId = v['tag_id']?.toString();
          if (docId != null && tagId != null) {
            out.add({'document_id': docId, 'tag_id': tagId});
          }
        }
      }
      return out;
    }

    final tagLinkSection = section('document_tags');
    final addedLinks = <Map<String, String>>[
      ...parseLinks(tagLinkSection?['added']),
      ...parseLinks(tagLinkSection?['updated']),
    ];
    final deletedLinks = parseLinks(tagLinkSection?['deleted']);

    final serverTime = DateTime.tryParse((json['server_time'] as String?) ?? '') ??
        DateTime.now().toUtc();

    return KnowledgeSyncBundle(
      categories: KnowledgeSyncResource.fromJson(
        section('categories'),
        KnowledgeCategory.fromJson,
      ),
      documents: KnowledgeSyncResource.fromJson(
        section('documents'),
        KnowledgeDocumentSummary.fromJson,
      ),
      translations: KnowledgeSyncResource.fromJson(
        section('document_translations'),
        KnowledgeDocumentTranslation.fromJson,
      ),
      sections: KnowledgeSyncResource.fromJson(
        section('sections'),
        KnowledgeSection.fromJson,
      ),
      contentBlocks: KnowledgeSyncResource.fromJson(
        section('content_blocks'),
        KnowledgeContentBlock.fromJson,
      ),
      media: KnowledgeSyncResource.fromJson(
        section('media'),
        KnowledgeMedia.fromJson,
      ),
      assignments: KnowledgeSyncResource.fromJson(
        section('assignments'),
        KnowledgeAssignment.fromJson,
      ),
      tags: KnowledgeSyncResource.fromJson(
        section('tags'),
        KnowledgeTag.fromJson,
      ),
      documentTagLinks: addedLinks,
      deletedDocumentTagLinks: deletedLinks,
      serverTime: serverTime,
    );
  }
}

/// REST client for `/api/mobile/v2/knowledge/`. Carries the V2 access
/// token and `X-Organization-Id` on every request — both pulled fresh
/// per call so token refresh + org switching surface immediately.
class KnowledgeApiService {
  final Dio _dio;
  final TokenService _tokenService;
  final AgentOrganizationContext _orgContext;

  KnowledgeApiService(
    this._tokenService,
    this._orgContext, {
    Dio? dio,
  }) : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: '${TokenService.v2BaseUrl}/api/mobile/v2/knowledge',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
            )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Re-resolve token + org id every call. `ensureValidV2Token`
        // refreshes silently when the cached one is near expiry; org id
        // can change after multi-tenant agents switch primary org.
        try {
          final token = await _tokenService.ensureValidV2Token();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          if (kDebugMode) {
            print('KnowledgeApiService: token refresh failed: $e');
          }
        }
        final orgId = _orgContext.primaryOrganizationId;
        if (orgId != null && orgId.isNotEmpty) {
          options.headers['X-Organization-Id'] = orgId;
        }
        return handler.next(options);
      },
      onError: (err, handler) {
        if (kDebugMode) {
          print(
              'KnowledgeApiService: ${err.requestOptions.method} ${err.requestOptions.path} → ${err.response?.statusCode} ${err.message}');
        }
        return handler.next(err);
      },
    ));
  }

  /// Resolves the org id to inject into responses that omit it.
  ///
  /// Mobile endpoints scope by `X-Organization-Id` header rather than
  /// echoing the column on every row, so we attach it client-side
  /// before parsing — otherwise rows land in cache with
  /// `organization_id = ''` and DAO queries (which filter by the
  /// agent's real org id) match nothing.
  String _currentOrgId() => _orgContext.primaryOrganizationId ?? '';

  /// Recursively walks a decoded JSON tree and fills in
  /// `organization_id` on any map that lacks it. Mutates in place.
  void _injectOrgId(Object? node, String orgId) {
    if (orgId.isEmpty) return;
    if (node is Map) {
      final existing = node['organization_id'];
      if (existing == null || (existing is String && existing.isEmpty)) {
        node['organization_id'] = orgId;
      }
      for (final v in node.values.toList()) {
        _injectOrgId(v, orgId);
      }
    } else if (node is List) {
      for (final v in node) {
        _injectOrgId(v, orgId);
      }
    }
  }

  /// Categories tree, filtered by assignment + published documents
  /// server-side. Returns the flat list — the home page builds the
  /// `parent_id` tree client-side.
  Future<List<KnowledgeCategory>> getCategories() async {
    final r = await _dio.get('/categories/');
    final data = r.data;
    final orgId = _currentOrgId();
    _injectOrgId(data, orgId);
    final raw = (data is List)
        ? data
        : (data is Map && data['results'] is List)
            ? data['results'] as List
            : const [];
    if (kDebugMode) {
      print(
          'KnowledgeApiService.getCategories: orgId=$orgId, count=${raw.length}');
    }
    return raw
        .whereType<Map>()
        .map((j) => KnowledgeCategory.fromJson(j.cast<String, dynamic>()))
        .toList();
  }

  Future<PaginatedResponse<KnowledgeDocumentSummary>> getDocuments({
    String? category,
    String? type,
    String? search,
    bool? pinned,
    String? tag,
    int page = 1,
    int pageSize = 20,
  }) async {
    final r = await _dio.get(
      '/documents/',
      queryParameters: {
        if (category != null) 'category': category,
        if (type != null) 'type': type,
        if (search != null && search.isNotEmpty) 'search': search,
        if (pinned != null) 'pinned': pinned,
        if (tag != null) 'tag': tag,
        'page': page,
        'page_size': pageSize,
      },
    );
    final data = r.data;
    final orgId = _currentOrgId();
    _injectOrgId(data, orgId);
    if (data is Map<String, dynamic>) {
      return PaginatedResponse.fromJson(
        data,
        KnowledgeDocumentSummary.fromJson,
      );
    }
    if (data is List) {
      return PaginatedResponse(
        results: data
            .whereType<Map>()
            .map((j) =>
                KnowledgeDocumentSummary.fromJson(j.cast<String, dynamic>()))
            .toList(),
      );
    }
    return const PaginatedResponse(results: []);
  }

  Future<KnowledgeDocument> getDocumentDetail(String id) async {
    final r = await _dio.get('/documents/$id/');
    final data = r.data;
    _injectOrgId(data, _currentOrgId());
    return KnowledgeDocument.fromJson(
      (data as Map).cast<String, dynamic>(),
    );
  }

  Future<KnowledgeSyncBundle> sync({DateTime? since}) async {
    final r = await _dio.get(
      '/sync/',
      queryParameters: {
        if (since != null) 'since': since.toUtc().toIso8601String(),
      },
    );
    final data = r.data;
    final orgId = _currentOrgId();
    _injectOrgId(data, orgId);
    if (kDebugMode) {
      final m = (data is Map) ? data : <String, dynamic>{};
      final cats = (m['categories'] is Map)
          ? (((m['categories'] as Map)['added'] as List?)?.length ?? 0) +
              (((m['categories'] as Map)['updated'] as List?)?.length ?? 0)
          : 0;
      final docs = (m['documents'] is Map)
          ? (((m['documents'] as Map)['added'] as List?)?.length ?? 0) +
              (((m['documents'] as Map)['updated'] as List?)?.length ?? 0)
          : 0;
      print(
          'KnowledgeApiService.sync: orgId=$orgId, since=$since, categories+=$cats, documents+=$docs');
    }
    return KnowledgeSyncBundle.fromJson(
      (data as Map).cast<String, dynamic>(),
    );
  }

  Future<List<KnowledgeTag>> getTags() async {
    final r = await _dio.get('/tags/');
    final data = r.data;
    _injectOrgId(data, _currentOrgId());
    final raw = (data is List)
        ? data
        : (data is Map && data['results'] is List)
            ? data['results'] as List
            : const [];
    return raw
        .whereType<Map>()
        .map((j) => KnowledgeTag.fromJson(j.cast<String, dynamic>()))
        .toList();
  }
}
