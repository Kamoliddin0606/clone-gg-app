import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/images/unified_image.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/shared_preferences_service.dart';
import '../../../../core/services/token_service.dart';

/// Typed Dio client for the V2 customer-photo CRUD set under
/// `/api/mobile/v2/customers/{customer_id}/photos/`.
///
/// **Responsibilities**
/// - Issue the 8 endpoints (list / retrieve / upload / bulk / patch /
///   replace / delete / reprocess) with the JWT bearer attached.
/// - Generate `client_uuid` + `idempotency_key` on every create /
///   bulk-create / replace and persist the latter in SharedPreferences
///   so retries after an app restart re-use the same key (24 h TTL).
/// - Honour ETag on `list()` and `retrieve()` so polling stays cheap.
/// - Translate every backend error envelope into a typed
///   [CustomerPhotoException] so callers never inspect Dio internals.
///
/// The repository deliberately does NOT swallow 4xx silently — unlike
/// the read-only [`NewBackendImageRepository`], every mutation here
/// has user-visible failure modes (cap exceeded, validation, etc.) and
/// the UI needs the typed exception to map to ARB.
class CustomerPhotoRepository {
  static const String _basePath = '/api/mobile/v2/customers';

  // SharedPreferences key prefix for idempotency persistence. One row
  // per (customer, action) pair; opaque JSON value (key + createdAt).
  static const String _idemPrefix = 'customer_photo_idem_';

  /// Idempotency keys live for 24 h — long enough to survive an app
  /// restart on a flaky-network upload, short enough that the backend
  /// guarantees the de-dup window.
  static const Duration _idemTtl = Duration(hours: 24);

  static const _uuid = Uuid();

  final Dio _dio;
  final TokenService _tokenService;
  final SharedPreferencesService _prefs;

  /// In-memory ETag cache: key is the canonical request URL (incl.
  /// query params for list); value is the last-seen ETag header.
  final Map<String, String> _etagByUrl = <String, String>{};

  /// In-memory cache of the last successful list / retrieve response,
  /// keyed identically to [_etagByUrl]. Used to short-circuit a 304.
  final Map<String, dynamic> _bodyByUrl = <String, dynamic>{};

  CustomerPhotoRepository({
    Dio? dio,
    TokenService? tokenService,
    SharedPreferencesService? prefs,
  })  : _dio = dio ?? sl<Dio>(),
        _tokenService = tokenService ?? sl<TokenService>(),
        _prefs = prefs ?? sl<SharedPreferencesService>();

  // ---------------------------------------------------------------------------
  // Endpoints
  // ---------------------------------------------------------------------------

  /// `GET /api/mobile/v2/customers/{customer_id}/photos/`
  Future<List<UnifiedImage>> list(
    String customerId, {
    String? status,
    bool? isPrimary,
    String? ordering,
  }) async {
    final query = <String, dynamic>{
      if (status != null) 'status': status,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (ordering != null) 'ordering': ordering,
    };
    final url = '${TokenService.v2BaseUrl}$_basePath/$customerId/photos/';
    final cacheKey = _cacheKey(url, query);
    final headers = await _authHeaders();
    final etag = _etagByUrl[cacheKey];
    if (etag != null) {
      headers['If-None-Match'] = etag;
    }
    if (kDebugMode) {
      debugPrint(
        '[PHOTO-DIAG] → list  GET $url\n'
        '  customerId (sent as code_1c) = "$customerId"\n'
        '  query = $query\n'
        '  has-etag = ${etag != null}',
      );
    }

    try {
      final response = await _dio.get<dynamic>(
        url,
        queryParameters: query.isEmpty ? null : query,
        options: Options(
          headers: headers,
          // Accept 304 so we can hit the in-memory cache.
          validateStatus: (s) => s != null && (s == 304 || s < 400),
        ),
      );

      if (response.statusCode == 304) {
        final cached = _bodyByUrl[cacheKey];
        if (kDebugMode) {
          debugPrint(
            '[PHOTO-DIAG] ← list  status=304 (etag hit) '
            'cached-count=${cached is List ? cached.length : -1}',
          );
        }
        if (cached is List) {
          return cached.cast<UnifiedImage>();
        }
        // Cache miss after 304 — fall through to a fresh request.
        _etagByUrl.remove(cacheKey);
        return list(
          customerId,
          status: status,
          isPrimary: isPrimary,
          ordering: ordering,
        );
      }

      final newEtag = response.headers.value('etag');
      if (newEtag != null && newEtag.isNotEmpty) {
        _etagByUrl[cacheKey] = newEtag;
      }

      final results = _parseList(response.data, customerId);
      _bodyByUrl[cacheKey] = results;
      if (kDebugMode) {
        final rawCount = response.data is Map<String, dynamic>
            ? (response.data['results'] is List
                ? (response.data['results'] as List).length
                : -1)
            : (response.data is List
                ? (response.data as List).length
                : -1);
        debugPrint(
          '[PHOTO-DIAG] ← list  status=${response.statusCode}\n'
          '  raw rows in payload = $rawCount\n'
          '  parsed UnifiedImage count = ${results.length}\n'
          '  first ids = ${results.take(3).map((r) => r.id).toList()}',
        );
      }
      return results;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[PHOTO-DIAG] ✗ list  status=${e.response?.statusCode} '
          'type=${e.type}\n'
          '  error body = ${e.response?.data}\n'
          '  message = ${e.message}',
        );
      }
      throw _toException(e);
    }
  }

  /// `GET /api/mobile/v2/customers/{customer_id}/photos/{photo_id}/`
  Future<UnifiedImage> retrieve(String customerId, String photoId) async {
    final url =
        '${TokenService.v2BaseUrl}$_basePath/$customerId/photos/$photoId/';
    final cacheKey = _cacheKey(url, const <String, dynamic>{});
    final headers = await _authHeaders();
    final etag = _etagByUrl[cacheKey];
    if (etag != null) {
      headers['If-None-Match'] = etag;
    }

    try {
      final response = await _dio.get<dynamic>(
        url,
        options: Options(
          headers: headers,
          validateStatus: (s) => s != null && (s == 304 || s < 400),
        ),
      );

      if (response.statusCode == 304) {
        final cached = _bodyByUrl[cacheKey];
        if (cached is UnifiedImage) return cached;
        _etagByUrl.remove(cacheKey);
        return retrieve(customerId, photoId);
      }

      final newEtag = response.headers.value('etag');
      if (newEtag != null && newEtag.isNotEmpty) {
        _etagByUrl[cacheKey] = newEtag;
      }

      final image = _parseRow(response.data, customerId);
      if (image == null) {
        throw const CustomerPhotoException(
          code: 'parse_error',
          message: 'Could not parse photo row.',
        );
      }
      _bodyByUrl[cacheKey] = image;
      return image;
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  /// `POST /api/mobile/v2/customers/{customer_id}/photos/` (single).
  Future<UnifiedImage> uploadOne({
    required String customerId,
    required File image,
    String alt = '',
    int order = 0,
    bool isPrimary = false,
  }) async {
    final url = '${TokenService.v2BaseUrl}$_basePath/$customerId/photos/';
    final clientUuid = _uuid.v4();
    final idempotencyKey = await _resolveIdempotencyKey(
      customerId: customerId,
      action: 'upload_one',
    );

    final form = FormData.fromMap(<String, dynamic>{
      'image': await MultipartFile.fromFile(image.path),
      if (alt.isNotEmpty) 'alt': alt,
      'order': order,
      'is_primary': isPrimary,
      'client_uuid': clientUuid,
      'idempotency_key': idempotencyKey,
    });

    try {
      final response = await _dio.post<dynamic>(
        url,
        data: form,
        options: Options(
          headers: await _authHeaders(),
          validateStatus: (s) => s != null && s < 400,
        ),
      );
      final parsed = _parseRow(response.data, customerId);
      if (parsed == null) {
        throw const CustomerPhotoException(
          code: 'parse_error',
          message: 'Upload response could not be parsed.',
        );
      }
      // Successful upload — list ETag is now stale.
      _invalidateListCache(customerId);
      // Idempotency key consumed; clear so the next upload generates a
      // fresh one rather than (incorrectly) collapsing to the same row.
      await _clearIdempotencyKey(customerId, 'upload_one');
      return parsed;
    } on DioException catch (e) {
      final exception = _toException(e);
      // 4xx validation errors → fresh key on retry; 5xx / network →
      // re-use the persisted key so the server can de-dup.
      final status = e.response?.statusCode;
      if (status != null && status >= 400 && status < 500) {
        await _clearIdempotencyKey(customerId, 'upload_one');
      }
      throw exception;
    }
  }

  /// `POST /api/mobile/v2/customers/{customer_id}/photos/bulk-upload/`
  Future<List<UnifiedImage>> uploadBulk({
    required String customerId,
    required List<File> images,
  }) async {
    if (images.isEmpty) return const <UnifiedImage>[];
    final url =
        '${TokenService.v2BaseUrl}$_basePath/$customerId/photos/bulk-upload/';
    final clientUuid = _uuid.v4();
    final idempotencyKey = await _resolveIdempotencyKey(
      customerId: customerId,
      action: 'upload_bulk',
    );

    final files = <MapEntry<String, MultipartFile>>[];
    for (final file in images) {
      files.add(
        MapEntry('images', await MultipartFile.fromFile(file.path)),
      );
    }
    final form = FormData()
      ..files.addAll(files)
      ..fields.addAll(<MapEntry<String, String>>[
        MapEntry('client_uuid', clientUuid),
        MapEntry('idempotency_key', idempotencyKey),
      ]);

    try {
      final response = await _dio.post<dynamic>(
        url,
        data: form,
        options: Options(
          headers: await _authHeaders(),
          validateStatus: (s) => s != null && s < 400,
        ),
      );
      final body = response.data;
      // Backend may return either a bare list or a paginated envelope.
      final parsed = _parseList(body, customerId);
      _invalidateListCache(customerId);
      await _clearIdempotencyKey(customerId, 'upload_bulk');
      return parsed;
    } on DioException catch (e) {
      final exception = _toException(e);
      final status = e.response?.statusCode;
      if (status != null && status >= 400 && status < 500) {
        await _clearIdempotencyKey(customerId, 'upload_bulk');
      }
      throw exception;
    }
  }

  /// `PATCH /api/mobile/v2/customers/{customer_id}/photos/{photo_id}/`
  Future<UnifiedImage> patchMetadata({
    required String customerId,
    required String photoId,
    String? alt,
    int? order,
    bool? isPrimary,
  }) async {
    final url =
        '${TokenService.v2BaseUrl}$_basePath/$customerId/photos/$photoId/';
    final body = <String, dynamic>{
      if (alt != null) 'alt': alt,
      if (order != null) 'order': order,
      if (isPrimary != null) 'is_primary': isPrimary,
    };

    try {
      final response = await _dio.patch<dynamic>(
        url,
        data: body,
        options: Options(
          headers: <String, String>{
            ...await _authHeaders(),
            'Content-Type': 'application/json',
          },
          validateStatus: (s) => s != null && s < 400,
        ),
      );
      final parsed = _parseRow(response.data, customerId);
      if (parsed == null) {
        throw const CustomerPhotoException(
          code: 'parse_error',
          message: 'Patch response could not be parsed.',
        );
      }
      _invalidateListCache(customerId);
      _invalidateRowCache(customerId, photoId);
      return parsed;
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  /// `PUT /api/mobile/v2/customers/{customer_id}/photos/{photo_id}/file/`
  Future<UnifiedImage> replaceFile({
    required String customerId,
    required String photoId,
    required File image,
  }) async {
    final url =
        '${TokenService.v2BaseUrl}$_basePath/$customerId/photos/$photoId/file/';
    final clientUuid = _uuid.v4();
    final idempotencyKey = await _resolveIdempotencyKey(
      customerId: customerId,
      action: 'replace_$photoId',
    );

    final form = FormData.fromMap(<String, dynamic>{
      'image': await MultipartFile.fromFile(image.path),
      'client_uuid': clientUuid,
      'idempotency_key': idempotencyKey,
    });

    try {
      final response = await _dio.put<dynamic>(
        url,
        data: form,
        options: Options(
          headers: await _authHeaders(),
          validateStatus: (s) => s != null && s < 400,
        ),
      );
      final parsed = _parseRow(response.data, customerId);
      if (parsed == null) {
        throw const CustomerPhotoException(
          code: 'parse_error',
          message: 'Replace response could not be parsed.',
        );
      }
      _invalidateListCache(customerId);
      _invalidateRowCache(customerId, photoId);
      await _clearIdempotencyKey(customerId, 'replace_$photoId');
      return parsed;
    } on DioException catch (e) {
      final exception = _toException(e);
      final status = e.response?.statusCode;
      if (status != null && status >= 400 && status < 500) {
        await _clearIdempotencyKey(customerId, 'replace_$photoId');
      }
      throw exception;
    }
  }

  /// `DELETE /api/mobile/v2/customers/{customer_id}/photos/{photo_id}/`
  Future<void> delete({
    required String customerId,
    required String photoId,
  }) async {
    final url =
        '${TokenService.v2BaseUrl}$_basePath/$customerId/photos/$photoId/';
    try {
      await _dio.delete<dynamic>(
        url,
        options: Options(
          headers: await _authHeaders(),
          validateStatus: (s) => s != null && s < 400,
        ),
      );
      _invalidateListCache(customerId);
      _invalidateRowCache(customerId, photoId);
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  /// `POST /api/mobile/v2/customers/{customer_id}/photos/{photo_id}/reprocess/`
  ///
  /// Currently the backend always returns `image_reprocess_not_supported`.
  /// Wired through anyway so the UI can surface that message.
  Future<void> reprocess({
    required String customerId,
    required String photoId,
  }) async {
    final url =
        '${TokenService.v2BaseUrl}$_basePath/$customerId/photos/$photoId/reprocess/';
    try {
      await _dio.post<dynamic>(
        url,
        options: Options(
          headers: await _authHeaders(),
          validateStatus: (s) => s != null && s < 400,
        ),
      );
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<Map<String, String>> _authHeaders() async {
    final token = await _tokenService.ensureValidV2Token();
    return <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  String _cacheKey(String url, Map<String, dynamic> query) {
    if (query.isEmpty) return url;
    final entries = query.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final qs = entries
        .map((e) => '${e.key}=${Uri.encodeComponent('${e.value}')}')
        .join('&');
    return '$url?$qs';
  }

  void _invalidateListCache(String customerId) {
    final prefix = '${TokenService.v2BaseUrl}$_basePath/$customerId/photos/';
    _etagByUrl.removeWhere((k, _) => k.startsWith(prefix) && _isListKey(k));
    _bodyByUrl.removeWhere((k, _) => k.startsWith(prefix) && _isListKey(k));
  }

  bool _isListKey(String key) {
    // A list key has no trailing `{photo_id}/` segment — i.e. ends with
    // `/photos/` (optionally followed by `?...`).
    final qIdx = key.indexOf('?');
    final path = qIdx >= 0 ? key.substring(0, qIdx) : key;
    return path.endsWith('/photos/');
  }

  void _invalidateRowCache(String customerId, String photoId) {
    final url =
        '${TokenService.v2BaseUrl}$_basePath/$customerId/photos/$photoId/';
    _etagByUrl.remove(url);
    _bodyByUrl.remove(url);
  }

  /// Parse either a DRF cursor-paginated envelope (`{results: []}`) or
  /// a bare list. Returns the canonical [UnifiedImage] list.
  List<UnifiedImage> _parseList(dynamic body, String customerId) {
    final List<dynamic>? rows;
    if (body is Map<String, dynamic>) {
      final results = body['results'];
      rows = results is List ? results : null;
    } else if (body is List) {
      rows = body;
    } else {
      rows = null;
    }
    if (rows == null) return const <UnifiedImage>[];
    final out = <UnifiedImage>[];
    for (final row in rows) {
      if (row is Map<String, dynamic>) {
        final parsed = _parseRow(row, customerId);
        if (parsed != null) out.add(parsed);
      }
    }
    return out;
  }

  /// Parse a single v2 customer-photo row into [UnifiedImage].
  ///
  /// The v2 photo shape only carries the photo's own fields (`id`,
  /// variant URLs, `blurhash`, `alt`, `order`, `is_primary`,
  /// `status`, ...). The owning customer's id and org are NOT in the
  /// row, so we synthesise them from the request context — caller
  /// passes [customerId]; org id is read from the cached gates so the
  /// existing `ClientImageWidget` infrastructure stays happy.
  UnifiedImage? _parseRow(dynamic raw, String customerId) {
    if (raw is! Map<String, dynamic>) return null;
    final id = raw['id'];
    if (id is! String || id.isEmpty) return null;

    final orgId =
        _tokenService.getCachedGates()?.organizationId ?? '';

    String? readUrl(String key) {
      final value = raw[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    int? readInt(String key) {
      final value = raw[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }

    return UnifiedImage(
      id: id,
      targetType: 'customer',
      targetId: customerId,
      targetOrganizationId: orgId,
      // The mobile catalog matches customers by 1C code; the v2 photo
      // row does not include it, so leave empty — the widget reads from
      // the explicit [smallUrl]/[mediumUrl]/[largeUrl] we already pass.
      targetCode1c: '',
      smallUrl: readUrl('small'),
      mediumUrl: readUrl('medium'),
      largeUrl: readUrl('large'),
      blurhash: (raw['blurhash'] as String?) ?? '',
      width: readInt('width'),
      height: readInt('height'),
      isPrimary: raw['is_primary'] == true,
      alt: (raw['alt'] as String?) ?? '',
      order: readInt('order') ?? 0,
    );
  }

  // --- Idempotency persistence ---------------------------------------------

  Future<String> _resolveIdempotencyKey({
    required String customerId,
    required String action,
  }) async {
    final prefs = _prefs.preferences;
    final storageKey = '$_idemPrefix${customerId}_$action';
    final raw = prefs.getString(storageKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final keyValue = decoded['key'];
          final createdAtMs = decoded['createdAt'];
          if (keyValue is String &&
              keyValue.isNotEmpty &&
              createdAtMs is int) {
            final age = DateTime.now()
                .difference(DateTime.fromMillisecondsSinceEpoch(createdAtMs));
            if (age <= _idemTtl) {
              return keyValue;
            }
          }
        }
      } catch (_) {
        // Corrupt entry — fall through and re-roll.
      }
    }
    final fresh = _uuid.v4();
    await _persistIdempotencyKey(prefs, storageKey, fresh);
    return fresh;
  }

  Future<void> _persistIdempotencyKey(
    SharedPreferences prefs,
    String storageKey,
    String key,
  ) async {
    final payload = jsonEncode(<String, dynamic>{
      'key': key,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    await prefs.setString(storageKey, payload);
  }

  Future<void> _clearIdempotencyKey(String customerId, String action) async {
    final storageKey = '$_idemPrefix${customerId}_$action';
    await _prefs.preferences.remove(storageKey);
  }

  // --- Error envelope decoding ---------------------------------------------

  CustomerPhotoException _toException(DioException e) {
    final response = e.response;
    if (response != null) {
      final status = response.statusCode;
      final data = response.data;
      // 404 with an HTML body means Django could not resolve the URL
      // pattern at all (the photo endpoints have not been registered
      // on the backend yet). The runbook's customer-photo CRUD
      // contract lists 8 URLs under `customers/{pk}/photos/...`;
      // only `customers/{pk}/coordinates/` is currently live on the
      // server we observed. Surface a distinct code so the UI can
      // explain the gap to the user instead of showing a generic
      // "not found".
      final contentType =
          response.headers.map['content-type']?.join(',') ?? '';
      if (status == 404 && contentType.contains('text/html')) {
        return const CustomerPhotoException(
          code: 'endpoint_not_implemented',
          message:
              'Customer photo endpoints are not registered on the '
              'backend yet (HTTP 404 returned a Django URL-pattern '
              'page). The runbook describes the contract; backend '
              'side still needs to ship the photo views.',
          statusCode: 404,
        );
      }
      if (data is Map<String, dynamic>) {
        final error = data['error'];
        if (error is Map<String, dynamic>) {
          final code = error['code']?.toString() ?? 'unknown_error';
          final message = error['message']?.toString() ?? '';
          final details = error['details'] is Map<String, dynamic>
              ? error['details'] as Map<String, dynamic>
              : null;
          return CustomerPhotoException(
            code: code,
            message: message,
            details: details,
            statusCode: status,
          );
        }
      }
      return CustomerPhotoException(
        code: 'http_$status',
        message: e.message ?? 'HTTP $status',
        statusCode: status,
      );
    }
    if (kDebugMode) {
      debugPrint('CustomerPhotoRepository: network error ${e.type} ${e.message}');
    }
    return CustomerPhotoException(
      code: 'network_error',
      message: e.message ?? 'Network error',
    );
  }
}

/// Typed exception carrying the backend's error envelope. Callers map
/// [code] to ARB; [message] is for diagnostics only — never shown to
/// the user directly.
class CustomerPhotoException implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final int? statusCode;

  const CustomerPhotoException({
    required this.code,
    required this.message,
    this.details,
    this.statusCode,
  });

  @override
  String toString() =>
      'CustomerPhotoException(code=$code, status=$statusCode, message=$message)';
}
