import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_service.dart';
import '../../../core/network/customer_endpoint_headers.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/telemetry_v2/rest_logging.dart';
import 'order_balance_gate.dart';

/// Emits a `customer.balance.blocked` analytics event whenever the user
/// is shown the [DebtBlockedDialog] (Passport §7).
///
/// Two channels:
///   * **Debug mode:** structured JSON line via [restLog] so the event
///     is visible during local development.
///   * **Production:** best-effort POST to
///     `/api/mobile/v2/analytics/balance-gate/`. Failure is swallowed —
///     analytics MUST NEVER block the UI. The endpoint is **not yet
///     deployed** (backend TODO); until it is, the POST returns 404 and
///     we silently drop. Adding the endpoint is a backend-only change
///     and requires no further mobile work.
///
/// Single-call surface so [DebtBlockedDialog] and the visit-step tile
/// share one event format.
class BalanceGateEventLogger {
  static const String _logTag = 'BalanceGate';
  static const String _endpoint = '/api/mobile/v2/analytics/balance-gate/';

  /// Emit one event. Caller passes the [BalanceGateResult] that triggered
  /// the dialog plus the customer identifiers — everything else is
  /// derived from the result.
  ///
  /// Set [trigger] to disambiguate where the event fired:
  ///   * `'visit_step'` — visit-step tile tap
  ///   * `'pre_submit'` — pre-submit recheck during flush
  ///   * `'detail_sheet'` — surfaced from a customer detail surface
  Future<void> logBlocked({
    required BalanceGateResult result,
    required String code1c,
    required String projectCode,
    required String trigger,
  }) async {
    if (!result.blocked) return;

    final payload = <String, dynamic>{
      'event': 'customer.balance.blocked',
      'code_1c': code1c,
      'project_code': projectCode,
      'balance': result.balance,
      'limit': result.limit,
      'currency': result.currency,
      'source': result.source,
      'reason': result.reason,
      'is_offline': result.isOffline,
      'is_stale': result.isStale,
      'trigger': trigger,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };

    // Debug visibility regardless of whether the backend endpoint exists.
    restLog(_logTag, 'blocked event: ${jsonEncode(payload)}');

    // Best-effort POST. Wrapped in try/catch — analytics must never
    // surface to the user.
    try {
      if (!sl.isRegistered<ApiService>()) return;
      final api = sl<ApiService>();
      Options? options;
      try {
        options = CustomerEndpointHeaders.optionsForRequest(
          requestPath: _endpoint,
        );
      } on DioException catch (_) {
        // No active project on a project-scope tenant — skip the event,
        // the user is about to be redirected to the picker anyway.
        return;
      }
      await api.post(_endpoint, data: payload, options: options);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[$_logTag] event POST failed (ignored): $e');
      }
    }
  }
}
