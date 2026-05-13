import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/models/app_notification.dart';

/// Typed Dio client for the V2 notification center.
///
/// Mirrors the contract in `docs/notifications/passport-mobile.md` §8:
///   * GET    /api/mobile/v2/notifications/                — list
///   * GET    /api/mobile/v2/notifications/{id}/            — detail
///   * GET    /api/mobile/v2/notifications/unread-count/    — badge
///   * POST   /api/mobile/v2/notifications/{id}/read/       — mark one
///   * POST   /api/mobile/v2/notifications/bulk-read/       — flush queue
///   * POST   /api/mobile/v2/notifications/devices/         — register
///   * DELETE /api/mobile/v2/notifications/devices/{id}/    — revoke
class NotificationApiService {
  static const String _basePath = '/api/mobile/v2/notifications';
  static const _uuid = Uuid();

  final Dio _dio;
  final TokenService _tokenService;

  NotificationApiService({
    required Dio dio,
    required TokenService tokenService,
  })  : _dio = dio,
        _tokenService = tokenService;

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  /// `GET /notifications/?since=...&unread_only=...&limit=...&cursor=...`.
  /// Returns `(items, nextCursor)`. Cursor is opaque — pass it back
  /// untouched on the next call.
  Future<NotificationListPage> list({
    DateTime? since,
    bool? unreadOnly,
    int limit = 50,
    String? cursor,
  }) async {
    final url = '${TokenService.v2BaseUrl}$_basePath/';
    final query = <String, dynamic>{
      'limit': limit,
      if (since != null) 'since': since.toUtc().toIso8601String(),
      if (unreadOnly != null) 'unread_only': unreadOnly,
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    };

    try {
      final response = await _dio.get<dynamic>(
        url,
        queryParameters: query,
        options: Options(
          headers: await _authHeaders(),
          validateStatus: (s) => s != null && s < 400,
        ),
      );
      return _parsePage(response.data);
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  /// `GET /notifications/{id}/` — full notification.
  Future<AppNotification> detail(String id) async {
    final url = '${TokenService.v2BaseUrl}$_basePath/$id/';
    try {
      final response = await _dio.get<dynamic>(
        url,
        options: Options(
          headers: await _authHeaders(),
          validateStatus: (s) => s != null && s < 400,
        ),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return AppNotification.fromJson(data);
      }
      throw const NotificationApiException(
        code: 'parse_error',
        message: 'Notification detail response is not a JSON object.',
      );
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  /// `GET /notifications/unread-count/` — single integer.
  /// Per `passport-mobile.md` §10 the badge is normally derived from
  /// the local DB; this is a backstop, e.g. after a fresh install.
  Future<int> unreadCount() async {
    final url = '${TokenService.v2BaseUrl}$_basePath/unread-count/';
    try {
      final response = await _dio.get<dynamic>(
        url,
        options: Options(
          headers: await _authHeaders(),
          validateStatus: (s) => s != null && s < 400,
        ),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final count = data['count'];
        if (count is int) return count;
        if (count is num) return count.toInt();
      }
      return 0;
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  /// `POST /notifications/{id}/read/`. Returns the server-side `read_at`.
  /// Throws on network/server failures so the caller can stash the id
  /// in the offline queue.
  Future<DateTime> markRead(String id) async {
    final url = '${TokenService.v2BaseUrl}$_basePath/$id/read/';
    try {
      final response = await _dio.post<dynamic>(
        url,
        options: Options(
          headers: <String, String>{
            ...await _authHeaders(),
            'Content-Type': 'application/json',
          },
          validateStatus: (s) => s != null && s < 400,
        ),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final readAt = data['read_at'];
        if (readAt is String && readAt.isNotEmpty) {
          return DateTime.tryParse(readAt) ?? DateTime.now().toUtc();
        }
      }
      return DateTime.now().toUtc();
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  /// `POST /notifications/bulk-read/` — flushes the offline queue. The
  /// `idempotency_key` lets us safely retry across app restarts.
  Future<int> bulkMarkRead({
    required List<String> ids,
    required String clientUuid,
    required String idempotencyKey,
  }) async {
    if (ids.isEmpty) return 0;
    final url = '${TokenService.v2BaseUrl}$_basePath/bulk-read/';
    try {
      final response = await _dio.post<dynamic>(
        url,
        data: <String, dynamic>{
          'ids': ids,
          'client_uuid': clientUuid,
          'idempotency_key': idempotencyKey,
        },
        options: Options(
          headers: <String, String>{
            ...await _authHeaders(),
            'Content-Type': 'application/json',
          },
          validateStatus: (s) => s != null && s < 400,
        ),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final marked = data['marked_count'];
        if (marked is int) return marked;
        if (marked is num) return marked.toInt();
      }
      return ids.length;
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Device tokens
  // ---------------------------------------------------------------------------

  /// `POST /notifications/devices/` — register or rotate the FCM token.
  /// Returns the persisted `UserDeviceToken` row (the `id` is needed to
  /// revoke on logout).
  Future<DeviceTokenRow> registerDevice({
    required String fcmToken,
    required String platform,
    required String deviceId,
    required String appVersion,
    required String clientUuid,
    String? idempotencyKey,
  }) async {
    final url = '${TokenService.v2BaseUrl}$_basePath/devices/';
    final body = <String, dynamic>{
      'fcm_token': fcmToken,
      'platform': platform,
      'device_id': deviceId,
      'app_version': appVersion,
      'client_uuid': clientUuid,
      'idempotency_key': idempotencyKey ?? _uuid.v4(),
    };
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
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return DeviceTokenRow.fromJson(data);
      }
      throw const NotificationApiException(
        code: 'parse_error',
        message: 'Device register response is not a JSON object.',
      );
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  /// `DELETE /notifications/devices/{id}/`. Best-effort — server returns
  /// 204 on success; 404 means the row was already revoked elsewhere.
  Future<void> revokeDevice(String id) async {
    final url = '${TokenService.v2BaseUrl}$_basePath/devices/$id/';
    try {
      await _dio.delete<dynamic>(
        url,
        options: Options(
          headers: await _authHeaders(),
          validateStatus: (s) => s != null && (s < 400 || s == 404),
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

  NotificationListPage _parsePage(dynamic body) {
    if (body is List) {
      // Some endpoints return a bare list (no pagination envelope).
      return NotificationListPage(
        items: body
            .whereType<Map<String, dynamic>>()
            .map(AppNotification.fromJson)
            .toList(),
        nextCursor: null,
      );
    }
    if (body is Map<String, dynamic>) {
      final results = body['results'];
      final next = body['next'];
      String? nextCursor;
      if (next is String && next.isNotEmpty) {
        // Server may return either a plain cursor or a full URL with
        // `?cursor=...`. Extract the cursor either way.
        final uri = Uri.tryParse(next);
        nextCursor = uri?.queryParameters['cursor'] ?? next;
      }
      final items = (results is List)
          ? results
              .whereType<Map<String, dynamic>>()
              .map(AppNotification.fromJson)
              .toList()
          : <AppNotification>[];
      return NotificationListPage(items: items, nextCursor: nextCursor);
    }
    return const NotificationListPage(items: [], nextCursor: null);
  }

  NotificationApiException _toException(DioException e) {
    final response = e.response;
    final status = response?.statusCode;
    final data = response?.data;
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        return NotificationApiException(
          code: error['code']?.toString() ?? 'unknown_error',
          message: error['message']?.toString() ?? '',
          statusCode: status,
        );
      }
    }
    if (status != null) {
      return NotificationApiException(
        code: 'http_$status',
        message: e.message ?? 'HTTP $status',
        statusCode: status,
      );
    }
    if (kDebugMode) {
      debugPrint('NotificationApiService: ${e.type} ${e.message}');
    }
    return NotificationApiException(
      code: 'network_error',
      message: e.message ?? 'Network error',
    );
  }
}

/// One page of `GET /notifications/`. Cursor is opaque.
class NotificationListPage {
  final List<AppNotification> items;
  final String? nextCursor;

  const NotificationListPage({required this.items, required this.nextCursor});
}

/// Server-returned `UserDeviceToken` row.
class DeviceTokenRow {
  final String id;
  final String fcmToken;
  final String platform;

  const DeviceTokenRow({
    required this.id,
    required this.fcmToken,
    required this.platform,
  });

  factory DeviceTokenRow.fromJson(Map<String, dynamic> json) {
    return DeviceTokenRow(
      id: (json['id'] ?? '').toString(),
      fcmToken: (json['fcm_token'] ?? '') as String,
      platform: (json['platform'] ?? '') as String,
    );
  }
}

class NotificationApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  const NotificationApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  bool get isNotFound => statusCode == 404 || code == 'notification_not_found';
  bool get isExpired => statusCode == 410 || code == 'notification_expired';
  bool get isAuth => statusCode == 401 || code == 'not_authenticated';

  @override
  String toString() =>
      'NotificationApiException(code=$code, status=$statusCode, message=$message)';
}
