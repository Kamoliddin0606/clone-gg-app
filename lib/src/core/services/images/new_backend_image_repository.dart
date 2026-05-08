import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../service_locator.dart';
import '../token_service.dart';
import 'image_target_type.dart';
import 'unified_image.dart';
import 'unified_image_page.dart';

/// Reads images from the V2 backend at `GET /api/mobile/v1/images/`.
///
/// The mobile-facing endpoint is read-only and only ever exposes rows
/// in `status="ready"`. Pagination uses DRF cursor pagination — the
/// repository returns the `next` URL verbatim as
/// [UnifiedImagePage.nextCursor] and the consumer passes it back into
/// [listForTarget] to fetch the following page.
///
/// **Error policy.** Image errors are almost always data issues (a
/// missing `code_1c`, an ambiguous denorm, a permission gap). Agents
/// can't fix any of them, so 4xx responses surface as empty pages
/// rather than thrown exceptions — the widget renders a placeholder
/// and life goes on. 5xx and network errors propagate, since those
/// are infrastructure problems worth surfacing to logs.
class NewBackendImageRepository {
  /// Mobile read endpoint. Admin endpoints (`/api/admin/v1/...`) are
  /// intentionally not used here — the mobile bearer is not
  /// authorised for them.
  static const String _listEndpoint = '/api/mobile/v1/images/';

  /// Backend wire vocabulary for `target.type` values. Django emits
  /// `projectproduct` (the ContentType model name) for products; the
  /// canonical mobile key stays `product` so call sites don't have to
  /// know about the historical naming. Both values are accepted on the
  /// way IN; only `product` (the canonical key) is used outbound — the
  /// backend's resolver accepts either.
  static const Map<String, String> _targetTypeOnReceive = <String, String>{
    'product': ImageTargetType.product,
    ImageTargetType.productWireAlias: ImageTargetType.product,
    'customer': ImageTargetType.customer,
    'project': ImageTargetType.project,
  };

  static const Map<String, String> _targetTypeOnSend = <String, String>{
    ImageTargetType.product: 'product',
    ImageTargetType.customer: 'customer',
    ImageTargetType.project: 'project',
  };

  // Wire-level query params (no magic strings sprinkled through the
  // method bodies).
  static const String _qpTargetType = 'target_type';
  static const String _qpExternalCode = 'external_code';
  static const String _qpTargetOrganizationId = 'target_organization_id';
  static const String _qpStatus = 'status';
  static const String _qpIsPrimary = 'is_primary';
  static const String _qpPageSize = 'page_size';

  final Dio _dio;
  final TokenService _tokenService;

  NewBackendImageRepository({
    Dio? dio,
    TokenService? tokenService,
  })  : _dio = dio ?? sl<Dio>(),
        _tokenService = tokenService ?? sl<TokenService>();

  /// List images for a single target.
  ///
  /// [targetCode1c] is the 1C code the mobile catalog already stores
  /// (`product.code` / `client.code` / `project.id_1c`).
  /// [targetOrganizationId] is REQUIRED — the backend silently
  /// returns `[]` without it, but we fail closed before issuing the
  /// request so we never hit the wire with an ambiguous query.
  ///
  /// [cursor] is the opaque cursor returned by a previous page (the
  /// full `next` URL, used verbatim).
  ///
  /// [primaryOnly] adds `is_primary=true` to the filter — useful when
  /// a widget only needs the cover image.
  Future<UnifiedImagePage> listForTarget({
    required String targetType,
    required String targetCode1c,
    required String targetOrganizationId,
    String? cursor,
    int limit = 50,
    bool primaryOnly = false,
    CancelToken? cancelToken,
  }) async {
    final wireType = _targetTypeOnSend[targetType];
    if (wireType == null) return UnifiedImagePage.empty;
    if (cursor == null) {
      // First-page guards — we only reach the wire when we have a
      // resolvable code + org pair.
      if (targetCode1c.isEmpty || targetOrganizationId.isEmpty) {
        return UnifiedImagePage.empty;
      }
    }

    final token = await _tokenService.ensureValidV2Token();
    if (token == null || token.isEmpty) {
      // No bearer — same fail-closed strategy as 4xx. The auth flow
      // will surface the missing-credentials state through its own
      // channel; image rendering stays silent.
      return UnifiedImagePage.empty;
    }

    // When `cursor` is non-null the backend returned a fully-qualified
    // `next` URL with the original filter trio embedded. Issue it
    // verbatim so the server's pagination contract is the source of
    // truth.
    final String url = cursor ?? '${TokenService.v2BaseUrl}$_listEndpoint';
    final Map<String, dynamic>? query = cursor == null
        ? <String, dynamic>{
            _qpTargetType: wireType,
            _qpExternalCode: targetCode1c,
            _qpTargetOrganizationId: targetOrganizationId,
            _qpStatus: 'ready',
            _qpPageSize: limit,
            if (primaryOnly) _qpIsPrimary: 'true',
          }
        : null;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        url,
        queryParameters: query,
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          // Let Dio throw on 4xx/5xx; we catch below and convert 4xx
          // to an empty page (data error → no UI noise).
          validateStatus: (status) => status != null && status < 400,
        ),
        cancelToken: cancelToken,
      );

      final body = response.data ?? const <String, dynamic>{};
      final results = body['results'];
      final List<UnifiedImage> images = <UnifiedImage>[];
      if (results is List) {
        for (final entry in results) {
          if (entry is Map<String, dynamic>) {
            final image = parseImageJson(entry, targetOrganizationId);
            if (image != null) images.add(image);
          }
        }
      }

      final next = body['next'];
      final nextCursor = (next is String && next.isNotEmpty) ? next : null;
      return UnifiedImagePage(images: images, nextCursor: nextCursor);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      final status = e.response?.statusCode;
      if (status != null && status >= 400 && status < 500) {
        // Data / permission / auth-refresh problem — surface a
        // breadcrumb so ops can spot data corruption, but don't
        // crash the UI. Treat as "no images found".
        if (kDebugMode) {
          debugPrint(
            'NewBackendImageRepository: 4xx on '
            '$targetType code_1c=$targetCode1c '
            'org=$targetOrganizationId status=$status — '
            'returning empty page.',
          );
        }
        return UnifiedImagePage.empty;
      }
      rethrow;
    }
  }

  /// Convenience wrapper around [listForTarget] that returns the
  /// primary (cover) image, or `null` when none exists / is ready.
  Future<UnifiedImage?> primaryForTarget({
    required String targetType,
    required String targetCode1c,
    required String targetOrganizationId,
    CancelToken? cancelToken,
  }) async {
    final page = await listForTarget(
      targetType: targetType,
      targetCode1c: targetCode1c,
      targetOrganizationId: targetOrganizationId,
      primaryOnly: true,
      limit: 1,
      cancelToken: cancelToken,
    );
    if (page.images.isEmpty) return null;
    final primary = page.images.firstWhere(
      (img) => img.isPrimary,
      orElse: () => page.images.first,
    );
    return primary;
  }

  /// Parses one row from the backend's `results` envelope. Returns
  /// `null` when the row is malformed so the caller can keep going
  /// rather than aborting the whole page. Exposed for unit tests.
  @visibleForTesting
  static UnifiedImage? parseImageJson(
    Map<String, dynamic> json,
    String targetOrganizationId,
  ) {
    try {
      final id = json['id'];
      if (id is! String || id.isEmpty) return null;

      final target = json['target'];
      String wireType;
      String parsedTargetId;
      String parsedCode1c;
      if (target is Map<String, dynamic>) {
        wireType = (target['type'] as String?) ?? '';
        parsedTargetId = (target['id'] as String?) ?? '';
        parsedCode1c = (target['code_1c'] as String?) ?? '';
      } else {
        wireType = (json['target_type'] as String?) ?? '';
        parsedTargetId = (json['target_id'] as String?) ?? '';
        parsedCode1c = (json['code_1c'] as String?) ?? '';
      }
      if (wireType.isEmpty) return null;

      final canonicalType = _targetTypeOnReceive[wireType];
      if (canonicalType == null) return null;

      // Need at least one of {targetId, code_1c} to be useful — but
      // we keep both. `code_1c` is what mobile matches against; the
      // UUID stays as an opaque tag for diagnostics.
      if (parsedTargetId.isEmpty && parsedCode1c.isEmpty) return null;

      String? readUrl(String key) {
        final value = json[key];
        return value is String && value.isNotEmpty ? value : null;
      }

      int? readInt(String key) {
        final value = json[key];
        if (value is int) return value;
        if (value is num) return value.toInt();
        return null;
      }

      return UnifiedImage(
        id: id,
        targetType: canonicalType,
        targetId: parsedTargetId,
        targetOrganizationId: targetOrganizationId,
        targetCode1c: parsedCode1c,
        smallUrl: readUrl('small'),
        mediumUrl: readUrl('medium'),
        largeUrl: readUrl('large'),
        blurhash: (json['blurhash'] as String?) ?? '',
        width: readInt('width'),
        height: readInt('height'),
        isPrimary: json['is_primary'] == true,
        alt: (json['alt'] as String?) ?? '',
        order: readInt('order') ?? 0,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NewBackendImageRepository: failed to parse row: $e');
      }
      return null;
    }
  }
}
