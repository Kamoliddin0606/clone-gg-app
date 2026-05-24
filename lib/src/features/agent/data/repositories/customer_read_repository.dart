import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/project_context.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/token_service.dart';
import '../models/trading_point.dart';

/// Typed Dio client for `GET /api/mobile/v2/customers/`.
///
/// Backend-first inversion: customer reads come from the backend
/// instead of SOAP `getClients`. The endpoint is cursor-paginated
/// (`?cursor=...`) and accepts `?updated_since=ISO8601` for
/// incremental sync.
///
/// Gate: `customers.view_customer`.
class CustomerReadRepository {
  static const String _basePath = '/api/mobile/v2/customers';

  final Dio _dio;
  final TokenService _tokenService;
  final ProjectContext _projectContext;

  CustomerReadRepository({
    Dio? dio,
    TokenService? tokenService,
    ProjectContext? projectContext,
  })  : _dio = dio ?? sl<Dio>(),
        _tokenService = tokenService ?? sl<TokenService>(),
        _projectContext = projectContext ?? sl<ProjectContext>();

  /// Paginates through every active customer the caller can see and
  /// returns the flattened list. Loops `GET /customers/?cursor=…`
  /// until `next` is null.
  ///
  /// `updatedSince` enables incremental sync — only rows whose
  /// `updated_at` is newer than the given timestamp are returned.
  Future<List<TradingPoint>> listAll({
    DateTime? updatedSince,
    int pageSize = 200,
  }) async {
    final result = <TradingPoint>[];
    String? nextUrl;

    do {
      final url = nextUrl ??
          _buildInitialUrl(
            pageSize: pageSize,
            updatedSince: updatedSince,
          );
      final response = await _dio.get<dynamic>(
        url,
        options: Options(
          headers: <String, String>{
            ...await _authHeaders(),
          },
          validateStatus: (s) => s != null && s < 400,
        ),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        if (kDebugMode) {
          debugPrint(
            '[CUSTOMER-READ] unexpected payload shape: ${data.runtimeType}',
          );
        }
        break;
      }
      final rows = data['results'];
      if (rows is List) {
        for (final row in rows) {
          if (row is Map<String, dynamic>) {
            final tp = TradingPoint.fromBackendJson(row);
            if (tp.id.isNotEmpty) {
              result.add(tp);
            }
          }
        }
      }
      final next = data['next'];
      nextUrl = next is String && next.isNotEmpty ? next : null;
    } while (nextUrl != null);

    if (kDebugMode) {
      debugPrint(
        '[CUSTOMER-READ] listAll → ${result.length} rows '
        '(updatedSince=${updatedSince?.toUtc().toIso8601String() ?? 'null'})',
      );
    }
    return result;
  }

  /// Fetches a single customer by UUID from `/api/mobile/v2/customers/{uuid}/`.
  /// Returns null if the customer is not found or the response is malformed.
  Future<TradingPoint?> getOne(String uuid) async {
    if (uuid.isEmpty) return null;
    final url = '${TokenService.v2BaseUrl}$_basePath/$uuid/';
    try {
      final response = await _dio.get<dynamic>(
        url,
        options: Options(
          headers: await _authHeaders(),
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      if (response.statusCode == 404) return null;
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      final tp = TradingPoint.fromBackendJson(data);
      if (kDebugMode) {
        debugPrint('[CUSTOMER-READ] getOne($uuid) → ${tp.id}');
      }
      return tp.id.isNotEmpty ? tp : null;
    } catch (e) {
      if (kDebugMode) debugPrint('[CUSTOMER-READ] getOne($uuid) failed: $e');
      return null;
    }
  }

  String _buildInitialUrl({
    required int pageSize,
    DateTime? updatedSince,
  }) {
    final query = <String, String>{
      'limit': pageSize.toString(),
      if (updatedSince != null)
        'updated_since': updatedSince.toUtc().toIso8601String(),
    };
    final qs = query.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    final base = '${TokenService.v2BaseUrl}$_basePath/';
    return qs.isEmpty ? base : '$base?$qs';
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _tokenService.ensureValidV2Token();
    final headers = <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
    if (_projectContext.requiresProjectHeader) {
      final projectHeader = _projectContext.activeProjectHeaderValue;
      if (projectHeader == null || projectHeader.isEmpty) {
        // List endpoint should NEVER call without project context for
        // a project-scope tenant. The caller is expected to surface a
        // picker — short-circuit with a DioException-shaped throw so
        // standard error envelopes still flow through.
        throw DioException(
          requestOptions: RequestOptions(path: _basePath),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: _basePath),
            statusCode: 400,
            data: <String, dynamic>{
              'error': <String, dynamic>{
                'code': 'customer_project_required',
                'message': 'Active project is not selected.',
              },
            },
          ),
        );
      }
      headers['X-Project-Id'] = projectHeader;
    }
    return headers;
  }
}
