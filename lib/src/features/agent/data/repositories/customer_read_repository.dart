import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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

  CustomerReadRepository({
    Dio? dio,
    TokenService? tokenService,
  })  : _dio = dio ?? sl<Dio>(),
        _tokenService = tokenService ?? sl<TokenService>();

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
    return <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }
}
