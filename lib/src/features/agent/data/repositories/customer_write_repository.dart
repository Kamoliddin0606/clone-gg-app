import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/auth/backend_permission_store.dart';
import '../../../../core/services/project_context.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/shared_preferences_service.dart';
import '../../../../core/services/token_service.dart';
import '../models/trading_point.dart';

/// Typed Dio client for the V2 customer-write endpoints under
/// `/api/mobile/v2/customers/`.
///
/// **Responsibilities**
/// - Three endpoints: create, update profile, update coordinates.
/// - Generate `client_uuid` + `idempotency_key` (UUID v4) for `create`
///   and persist the pair in SharedPreferences (24 h TTL) so a retry
///   after airplane-mode never duplicates the row.
/// - Serialise lat/lng as six-decimal strings (DRF `DecimalField`).
/// - Translate every Dio failure to a typed
///   [CustomerWriteException] carrying `code` / `message` / `details`
///   / `statusCode` so the cubit + UI never touch Dio internals.
class CustomerWriteRepository {
  static const String _basePath = '/api/mobile/v2/customers';

  // SharedPreferences key prefix for the create-action idempotency
  // key. PATCH endpoints are naturally idempotent so we do not persist
  // a key for them.
  static const String _idemPrefix = 'customer_write_idem_';

  /// Idempotency keys live for 24 h — long enough to survive an app
  /// restart on a flaky network, short enough that the backend
  /// guarantees the de-dup window.
  static const Duration _idemTtl = Duration(hours: 24);

  static const _uuid = Uuid();

  final Dio _dio;
  final TokenService _tokenService;
  final SharedPreferencesService _prefs;
  final ProjectContext _projectContext;

  CustomerWriteRepository({
    Dio? dio,
    TokenService? tokenService,
    SharedPreferencesService? prefs,
    ProjectContext? projectContext,
  })  : _dio = dio ?? sl<Dio>(),
        _tokenService = tokenService ?? sl<TokenService>(),
        _prefs = prefs ?? sl<SharedPreferencesService>(),
        _projectContext = projectContext ?? sl<ProjectContext>();

  // ---------------------------------------------------------------------------
  // Endpoints
  // ---------------------------------------------------------------------------

  /// `POST /api/mobile/v2/customers/`
  ///
  /// Backend-first creation: the backend stages a `pending_1c` row,
  /// synchronously calls 1C SOAP `setClient`, then either promotes
  /// the row to `status="active"` with `code_1c` populated (returns
  /// 201) or soft-deletes the row and returns a structured error.
  ///
  /// Mobile sends the full 22-field SOAP payload; the backend owns
  /// the 1C handoff. The response carries the backend-allocated
  /// `code` (e.g. `C-AB12CD34`) which becomes the mobile identifier
  /// going forward — `code_1c` is exposed separately because it now
  /// originates downstream and may briefly be empty.
  ///
  /// Reuses the persisted `(client_uuid, idempotency_key)` pair so a
  /// retry after app restart sends the same key — backend de-dups on
  /// 5xx / network / timeout. On 4xx the key is rotated immediately
  /// because the payload itself was rejected; the backend deletes the
  /// idempotency record on any 1C failure (422 / 502), so the same
  /// `(client_uuid, idempotency_key)` is free to be replayed after
  /// the user corrects the form.
  ///
  /// Gate: `customers.add_customer`.
  Future<TradingPoint> create({
    required String name,
    required String tradePointType,
    required String contactPersonPhone,
    required String address,
    required double latitude,
    required double longitude,
    required String codeUser,
    required String codeRegion,
    String signboard = '',
    String inn = '',
    String contactPerson = '',
    String addressDelivery = '',
    String referencePoint = '',
    String responsiblePersonPhone = '',
    String director = '',
    String mfo = '',
    String bankAccount = '',
    String salesChannel = '',
    String clientClass = '',
  }) async {
    final url = '${TokenService.v2BaseUrl}$_basePath/';
    final clientUuid = await _resolveCachedUuid(action: 'create_client_uuid');
    final idempotencyKey =
        await _resolveCachedUuid(action: 'create_idempotency');

    final body = <String, dynamic>{
      'name': name,
      'signboard': signboard,
      'inn': inn,
      'trade_point_type': tradePointType,
      'contact_person': contactPerson,
      'contact_person_phone': contactPersonPhone,
      'address': address,
      'address_delivery':
          addressDelivery.isEmpty ? address : addressDelivery,
      'reference_point': referencePoint,
      'responsible_person_phone': responsiblePersonPhone.isEmpty
          ? contactPersonPhone
          : responsiblePersonPhone,
      'latitude': _formatCoord(latitude),
      'longitude': _formatCoord(longitude),
      'code_user': codeUser,
      'code_region': codeRegion,
      'director': director,
      'mfo': mfo,
      'bank_account': bankAccount,
      'sales_channel': salesChannel,
      'client_class': clientClass,
      'client_uuid': clientUuid,
      'idempotency_key': idempotencyKey,
    };
    _logRequest('create', 'POST', url, body: body);

    try {
      final response = await _dio.post<dynamic>(
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
      _logResponse('create', response.statusCode, response.data);
      final parsed = _parseRow(response.data);
      if (parsed == null) {
        throw const CustomerWriteException(
          code: 'parse_error',
          message: 'Create response could not be parsed.',
        );
      }
      // Successful create — fresh keys on the next call.
      await _clearCachedUuid('create_client_uuid');
      await _clearCachedUuid('create_idempotency');
      return parsed;
    } on DioException catch (e) {
      final exception = _toException(e);
      _logError('create', e);
      final status = e.response?.statusCode;
      // 4xx → payload error, rotate the key on retry.
      // 5xx / network → keep the key so the server can de-dup.
      if (status != null && status >= 400 && status < 500) {
        await _clearCachedUuid('create_client_uuid');
        await _clearCachedUuid('create_idempotency');
      }
      throw exception;
    }
  }

  /// `PATCH /api/mobile/v2/customers/{customer_id}/`
  ///
  /// Sends only the keys the caller actually populated — backend
  /// treats absent keys as "do not touch". Including `latitude` /
  /// `longitude` here is silently dropped by the server (audit-trail
  /// + gate separation); use [updateCoordinates] instead.
  ///
  /// Gate: `customers.change_customer`.
  Future<TradingPoint> updateProfile({
    required String customerId,
    String? name,
    String? inn,
    String? phone,
    String? address,
  }) async {
    final url = '${TokenService.v2BaseUrl}$_basePath/$customerId/';
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (inn != null) 'inn': inn,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
    };
    _logRequest('updateProfile', 'PATCH', url, body: body);

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
      _logResponse('updateProfile', response.statusCode, response.data);
      final parsed = _parseRow(response.data);
      if (parsed == null) {
        throw const CustomerWriteException(
          code: 'parse_error',
          message: 'Update response could not be parsed.',
        );
      }
      return parsed;
    } on DioException catch (e) {
      _logError('updateProfile', e);
      throw _toException(e);
    }
  }

  /// `PATCH /api/mobile/v2/customers/{customer_id}/coordinates/`
  ///
  /// Sends `latitude` / `longitude` as six-decimal JSON strings —
  /// matches DRF `DecimalField` default and keeps PATCH replay byte-
  /// equal across retries.
  ///
  /// Gate: `customers.change_customer_coordinates`.
  Future<TradingPoint> updateCoordinates({
    required String customerId,
    required double latitude,
    required double longitude,
  }) async {
    final url =
        '${TokenService.v2BaseUrl}$_basePath/$customerId/coordinates/';
    final body = <String, dynamic>{
      'latitude': _formatCoord(latitude),
      'longitude': _formatCoord(longitude),
    };
    _logRequest('updateCoordinates', 'PATCH', url, body: body);

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
      _logResponse(
        'updateCoordinates',
        response.statusCode,
        response.data,
      );
      final parsed = _parseRow(response.data);
      if (parsed == null) {
        throw const CustomerWriteException(
          code: 'parse_error',
          message: 'Coordinates response could not be parsed.',
        );
      }
      return parsed;
    } on DioException catch (e) {
      _logError('updateCoordinates', e);
      throw _toException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Focused diagnostic logging
  // ---------------------------------------------------------------------------
  //
  // [CUSTOMER-DIAG] is the consistent tag the team greps for when
  // debugging mobile ↔ V2 mismatches. The general `[CUSTOMER]` tag
  // wired through `attachRestLogger` already prints the raw Dio
  // transcript; these helpers print a curated, action-named summary
  // so the customer profile / coordinates / photos triage is one
  // grep away in a long log.

  void _logRequest(
    String action,
    String method,
    String url, {
    Map<String, dynamic>? body,
  }) {
    if (!kDebugMode) return;
    final summary = body == null
        ? '(no body)'
        : body.entries
            .map((e) => '${e.key}=${_summarise(e.value)}')
            .join(' ');
    debugPrint(
      '[CUSTOMER-DIAG] → $action  $method $url\n'
      '  body: $summary',
    );
  }

  void _logResponse(String action, int? status, Object? data) {
    if (!kDebugMode) return;
    debugPrint(
      '[CUSTOMER-DIAG] ← $action  status=$status\n'
      '  payload: ${_summariseResponse(data)}',
    );
  }

  void _logError(String action, DioException e) {
    if (!kDebugMode) return;
    final status = e.response?.statusCode;
    final body = e.response?.data;
    debugPrint(
      '[CUSTOMER-DIAG] ✗ $action  status=$status type=${e.type}\n'
      '  error body: ${_summariseResponse(body)}\n'
      '  message: ${e.message}',
    );
  }

  /// Compact one-line preview of any JSON-ish value. Trims long
  /// strings so the log stays readable; keeps the full shape for
  /// short payloads.
  String _summarise(Object? value) {
    if (value == null) return 'null';
    final s = value.toString();
    if (s.length <= 60) return s;
    return '${s.substring(0, 60)}…(len=${s.length})';
  }

  /// Pretty-summarise a response payload. Picks the most useful
  /// identifying fields (`id`, `code`, `code_1c`, `name`,
  /// `coordinates_source`, etc.) instead of dumping the entire JSON
  /// — the rest stays in the `[CUSTOMER]` raw-trace log.
  ///
  /// When the response is Django's HTML debug page (a 500 / 404 from
  /// `DEBUG=True` returning text/html instead of the JSON error
  /// envelope), the HTML is much too long to dump and the useful
  /// signal is the exception type + value at the top of the page.
  /// We extract those with two simple regexes so the diagnostic log
  /// stays one-line readable.
  String _summariseResponse(Object? data) {
    if (data is String) {
      return _summariseDjangoDebugHtml(data) ?? _summarise(data);
    }
    if (data is! Map<String, dynamic>) {
      return _summarise(data);
    }
    final keys = <String>[
      'id',
      'code',
      'code_1c',
      'name',
      'inn',
      'phone',
      'address',
      'latitude',
      'longitude',
      'coordinates_updated_at',
      'coordinates_source',
      'is_active',
    ];
    final present = <String>[];
    for (final k in keys) {
      if (data.containsKey(k)) {
        present.add('$k=${_summarise(data[k])}');
      }
    }
    // Surface error envelopes too — backend uses
    // `{"error": {"code": ..., "message": ...}, "request_id": ...}`.
    if (data['error'] is Map<String, dynamic>) {
      final err = data['error'] as Map<String, dynamic>;
      present.add('error.code=${err['code']}');
      present.add('error.message=${_summarise(err['message'])}');
    }
    if (data['request_id'] != null) {
      present.add('request_id=${data['request_id']}');
    }
    return present.isEmpty
        ? _summarise(data)
        : present.join(' ');
  }

  /// Extract `Exception Type` and `Exception Value` from a Django
  /// `DEBUG=True` HTML error page. Returns `null` if the body is not
  /// recognisable Django debug HTML so the caller falls back to the
  /// truncated raw dump.
  ///
  /// The page format is stable across Django versions:
  /// ```html
  /// <h1>ValidationError at /api/...</h1>
  /// <pre class="exception_value">{'latitude': ['...']}</pre>
  /// ```
  String? _summariseDjangoDebugHtml(String body) {
    if (!body.contains('<title>') ||
        !body.contains('Django')) {
      // Cheap guard — only run the regex on bodies that look like
      // Django HTML at all.
      if (!body.contains('exception_value') &&
          !body.contains('Exception Type')) {
        return null;
      }
    }
    final exType = RegExp(
      r'<th[^>]*>\s*Exception Type:\s*</th>\s*<td>([^<]+)</td>',
    ).firstMatch(body)?.group(1)?.trim();
    final exValue = RegExp(
      r'<pre class="exception_value">([\s\S]*?)</pre>',
    ).firstMatch(body)?.group(1)?.trim();
    final atRoute = RegExp(
      r'<h1>([A-Za-z]+) at ([^<]+)</h1>',
    ).firstMatch(body);
    final route = atRoute?.group(2)?.trim();
    final hType = atRoute?.group(1)?.trim();
    if (exType == null && exValue == null && route == null) return null;
    return 'Django debug HTML — type=${exType ?? hType} '
        'route=$route '
        'value=${_summarise(exValue)}';
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<Map<String, String>> _authHeaders() async {
    final token = await _tokenService.ensureValidV2Token();
    final headers = <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
    // customer_scope=project tenants MUST send the active project id.
    // The header is omitted for organization-scope tenants; sending it
    // there returns 400 `customer_project_not_allowed`.
    if (_projectContext.requiresProjectHeader) {
      final projectHeader = _projectContext.activeProjectHeaderValue;
      if (projectHeader == null || projectHeader.isEmpty) {
        throw const CustomerWriteException(
          code: 'customer_project_required',
          message: 'Active project is not selected for project-scoped tenant.',
          statusCode: 400,
        );
      }
      headers['X-Project-Id'] = projectHeader;
    }
    return headers;
  }

  /// Format a `double` lat/lng as a six-decimal string. Matches the
  /// DRF `DecimalField(max_digits=9, decimal_places=6)` default the
  /// backend uses on the read side, so PATCH replays are byte-equal
  /// across retries.
  String _formatCoord(double value) => value.toStringAsFixed(6);

  /// Parse a single `MobileCustomer` row into a [TradingPoint].
  ///
  /// Backend-first inversion: the backend allocates a stable `code`
  /// (e.g. `C-AB12CD34`) and 1C's `code_1c` is now a downstream value
  /// that may briefly be empty during the `pending_1c` window before
  /// the SOAP promotion completes. `TradingPoint.id` therefore tracks
  /// `code` (backend identifier) and `code_1c` is exposed separately
  /// via [TradingPoint.code1c] for the success-dialog display and any
  /// legacy SOAP integrations.
  TradingPoint? _parseRow(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    final parsed = TradingPoint.fromBackendJson(raw);
    return parsed.id.isEmpty ? null : parsed;
  }

  // --- Idempotency / client UUID persistence -------------------------------

  Future<String> _resolveCachedUuid({required String action}) async {
    final prefs = _prefs.preferences;
    final storageKey = '$_idemPrefix${_idemPartition()}_$action';
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
            final age = DateTime.now().difference(
              DateTime.fromMillisecondsSinceEpoch(createdAtMs),
            );
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
    await _persistCachedUuid(prefs, storageKey, fresh);
    return fresh;
  }

  Future<void> _persistCachedUuid(
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

  Future<void> _clearCachedUuid(String action) async {
    final storageKey = '$_idemPrefix${_idemPartition()}_$action';
    await _prefs.preferences.remove(storageKey);
  }

  /// Partition label so idempotency keys do not leak across projects
  /// under `customer_scope=project`. Org-scope tenants share the `org`
  /// partition (unchanged behaviour).
  String _idemPartition() {
    final value = _projectContext.activeProjectHeaderValue;
    return (value == null || value.isEmpty) ? 'org' : value;
  }

  // --- Error envelope decoding ---------------------------------------------

  CustomerWriteException _toException(DioException e) {
    final response = e.response;
    if (response != null) {
      final status = response.statusCode;
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final error = data['error'];
        if (error is Map<String, dynamic>) {
          final code = error['code']?.toString() ?? 'unknown_error';
          final message = error['message']?.toString() ?? '';
          final details = error['details'] is Map<String, dynamic>
              ? error['details'] as Map<String, dynamic>
              : null;
          // A 403 `permission_denied` means mobile thought the user
          // held the codename but V2 RBAC disagrees — either mobile's
          // cache is stale (codename was revoked after this login),
          // or the optimistic-empty fallback fired. Either way the
          // fix is to refresh the V2 token: that round-trip pulls a
          // fresh `gates.permissions` block and the existing
          // `_syncBackendPermissions` hook re-populates the store.
          // Fire-and-forget: the user still sees this attempt's
          // error, but the next render reflects reality.
          if (status == 403 && code == 'permission_denied') {
            _handlePermissionDenied();
          }
          // `customer_project_not_allowed` (400) — the client sent a
          // project header to an organization-scope tenant. Refresh
          // gates so the next call doesn't repeat the mistake; the
          // ProjectContext will then return `requiresProjectHeader=false`.
          if (status == 400 && code == 'customer_project_not_allowed') {
            // ignore: discarded_futures
            _refreshV2GatesQuietly();
          }
          return CustomerWriteException(
            code: code,
            message: message,
            details: details,
            statusCode: status,
          );
        }
      }
      // Fallback for non-envelope bodies (HTML debug pages from
      // `DEBUG=True`, plain text, etc.). Extract a meaningful summary
      // so the caller can log it without dumping 30+KB of HTML.
      String? summary;
      if (data is String) {
        summary = _summariseDjangoDebugHtml(data);
      }
      // A 500 with Django HTML almost always means an uncaught
      // exception on the server side (typically a `ValidationError`
      // that DRF failed to convert to a 400 envelope). Surface as a
      // distinct code so the UI can show "server bug, contact dev"
      // instead of a generic HTTP status.
      if (status == 500) {
        return CustomerWriteException(
          code: 'server_error',
          message: summary ?? (e.message ?? 'HTTP 500'),
          statusCode: status,
        );
      }
      return CustomerWriteException(
        code: 'http_$status',
        message: summary ?? (e.message ?? 'HTTP $status'),
        statusCode: status,
      );
    }
    if (kDebugMode) {
      debugPrint(
        'CustomerWriteRepository: network error ${e.type} ${e.message}',
      );
    }
    return CustomerWriteException(
      code: 'network_error',
      message: e.message ?? 'Network error',
    );
  }

  /// Fire-and-forget refresh of the V2 access token after a 403
  /// `permission_denied`. The refresh response carries the latest
  /// `gates.permissions`, and `TokenService._syncBackendPermissions`
  /// pushes that into [BackendPermissionStore] — so the next time
  /// the user opens the affected screen, the codename gate matches
  /// the server's reality (the icon disappears if revoked).
  ///
  /// Also dumps the mobile's current grant set to the log so the
  /// gap between mobile and server is visible during diagnosis.
  void _handlePermissionDenied() {
    if (kDebugMode) {
      try {
        if (GetIt.I.isRegistered<BackendPermissionStore>()) {
          final store = GetIt.I<BackendPermissionStore>();
          debugPrint(
            '[CUSTOMER-DIAG] ⚠️  V2 returned permission_denied but '
            'mobile store thought the user held the codename. '
            'Triggering a token refresh to re-sync gates.\n'
            '  current mobile grant set = ${store.all}\n'
            '  optimistic-empty active  = '
            '${store.isOptimistic && store.all.isEmpty}',
          );
        }
      } catch (_) {
        // Telemetry path — never throw.
      }
    }
    // ignore: discarded_futures
    _refreshV2GatesQuietly();
  }

  Future<void> _refreshV2GatesQuietly() async {
    try {
      final newAccess = await _tokenService.refreshAccessV2();
      if (kDebugMode) {
        debugPrint(
          '[CUSTOMER-DIAG] ↻ V2 token refresh after permission_denied '
          '→ ${newAccess == null ? "FAILED" : "OK"} '
          '(BackendPermissionStore now reflects server state)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[CUSTOMER-DIAG] ↻ V2 token refresh threw after '
          'permission_denied: $e',
        );
      }
    }
  }
}

/// Typed exception carrying the backend's error envelope. Callers map
/// [code] to ARB; [message] is for diagnostics only — never shown to
/// the user directly.
class CustomerWriteException implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final int? statusCode;

  const CustomerWriteException({
    required this.code,
    required this.message,
    this.details,
    this.statusCode,
  });

  @override
  String toString() =>
      'CustomerWriteException(code=$code, status=$statusCode, message=$message)';
}
