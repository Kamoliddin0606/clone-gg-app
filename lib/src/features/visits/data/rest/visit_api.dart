import 'dart:io';

import 'package:dio/dio.dart';

import '../../domain/entities/catalog_task.dart';
import '../../domain/entities/permissions.dart';
import '../../domain/entities/visit_read.dart';
import '../../domain/failures.dart';
import 'rest_v2_client.dart';

/// High-level wrapper over [RestV2Client]. Everything mobile knows about
/// `/api/mobile/v2/visits/` goes through here so the BLoC layer never
/// touches Dio.
///
/// Each method returns parsed Domain entities; transport failures arrive as
/// [Failure] subtypes courtesy of `ErrorMapperInterceptor`.
class VisitApi {
  VisitApi(this._client);

  final RestV2Client _client;

  Dio get _dio => _client.dio;

  /// Just refreshes the cached server time — body is empty.
  Future<void> syncServerTime() async {
    await _dio.get('/visits/server-time/');
  }

  Future<VisitsPermissions> fetchPermissions({String? etag}) async {
    final response = await _dio.get(
      '/visits/permissions/',
      options: Options(
        headers: etag == null ? null : {'If-None-Match': etag},
      ),
    );
    if (response.statusCode == 304) {
      throw const NotModifiedException();
    }
    final responseEtag = response.headers.value('etag') ?? etag ?? '';
    return VisitsPermissions.fromJson(
      (response.data as Map).cast<String, dynamic>(),
      etag: responseEtag,
    );
  }

  Future<VisitsCatalog> fetchCatalog({String? etag}) async {
    final response = await _dio.get(
      '/visits/catalog/',
      options: Options(
        headers: etag == null ? null : {'If-None-Match': etag},
      ),
    );
    if (response.statusCode == 304) {
      throw const NotModifiedException();
    }
    final responseEtag = response.headers.value('etag') ?? etag ?? '';
    return VisitsCatalog.fromJson(
      (response.data as Map).cast<String, dynamic>(),
      etag: responseEtag,
    );
  }

  /// Atomic visit submit. Returns the server response status (201 or 200 on
  /// idempotent replay) so the dispatcher can log it.
  Future<int> finishVisit({
    required Map<String, dynamic> envelopeJson,
  }) async {
    final response = await _dio.post(
      '/visits/finish/',
      data: envelopeJson,
    );
    return response.statusCode ?? 0;
  }

  Future<int> cancelVisit({
    required String visitId,
    required Map<String, dynamic> body,
  }) async {
    final response = await _dio.post(
      '/visits/$visitId/cancel/',
      data: body,
    );
    return response.statusCode ?? 0;
  }

  /// Polls `GET /visits/{visitId}/` for the server-side status. Used by
  /// the post-finish UX to surface "buyurtma 1C ga yetkazildi" once the
  /// Celery forwarder lands the SOAP `setOrder` call (changelog § 7).
  ///
  /// Returns the wire string (`draft` / `submitted` / `synced_1c` /
  /// `rejected` / `cancelled`) or `null` when the visit isn't reachable
  /// (offline, 404). Caller decides retry cadence — the recommended
  /// pattern lives in `VisitStatusPoller`.
  Future<String?> fetchVisitStatus(String visitId) async {
    try {
      final response = await _dio.get('/visits/$visitId/');
      final body = (response.data as Map?)?.cast<String, dynamic>();
      return body?['status'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Cursor-paginated visit history. Pass [cursor] from the previous
  /// response's `next` field to drill into the next page; the value is
  /// passed verbatim so the call survives base-URL changes.
  ///
  /// Filters mirror the backend OpenAPI:
  ///   * [since]      — ISO 8601, returns visits started at or after.
  ///   * [customerId] — UUID, single-customer filter.
  ///   * [limit]      — DRF default 50, max 200.
  Future<VisitReadPage> fetchVisits({
    String? cursor,
    DateTime? since,
    String? customerId,
    int? limit,
  }) async {
    final response = await _dio.get(
      '/visits/',
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        if (since != null) 'since': since.toUtc().toIso8601String(),
        if (customerId != null) 'customer_id': customerId,
        if (limit != null) 'limit': limit,
      },
    );
    final body = (response.data as Map).cast<String, dynamic>();
    return VisitReadPage.fromJson(body);
  }

  /// Single visit with expanded tasks + photo refs. The detail
  /// projection embeds `EntityImage` URLs alongside each task so mobile
  /// can render `RetentionAwarePhoto` without a per-asset round-trip.
  /// Returns `null` on 404 — visit was soft-deleted or never existed
  /// for the caller's scope.
  Future<VisitReadDetail?> fetchVisitDetail(String visitId) async {
    try {
      final response = await _dio.get('/visits/$visitId/');
      final body = (response.data as Map).cast<String, dynamic>();
      return VisitReadDetail.fromDetailJson(body);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Multipart photo upload. Returns the server-assigned asset id which the
  /// caller stamps onto `photo_uploads.remote_asset_id`.
  Future<String> uploadPhoto({
    required String visitId,
    required File file,
    required String clientUuid,
    required String idempotencyKey,
    required String taskCode,
    required DateTime capturedAt,
    required String sha256,
    double? lat,
    double? lng,
    double? accuracyM,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
      'client_uuid': clientUuid,
      'idempotency_key': idempotencyKey,
      'task_code': taskCode,
      'captured_at': capturedAt.toUtc().toIso8601String(),
      'sha256': sha256,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (accuracyM != null) 'accuracy_m': accuracyM,
    });
    final response = await _dio.post(
      '/visits/$visitId/photos/',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    final body = (response.data as Map).cast<String, dynamic>();
    return body['asset_id'] as String;
  }
}

/// Thrown for 304 responses so the repository layer can return its
/// cached snapshot without re-parsing. Public on purpose: repositories
/// catch it by type to keep the ETag fast-path explicit rather than
/// hiding behind a generic `Exception` (which would also swallow real
/// transport errors).
class NotModifiedException implements Exception {
  const NotModifiedException();
}
