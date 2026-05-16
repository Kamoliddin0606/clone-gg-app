import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:gloria_marketing_flutter/src/core/version/data/version_gate_response.dart';
import 'package:gloria_marketing_flutter/src/core/version/data/version_check_cache.dart';
import 'package:gloria_marketing_flutter/src/core/version/presentation/version_gate_screen.dart';

/// Dio response interceptor that intercepts the backend's
/// `426 Upgrade Required` middleware response and routes the user to the
/// full-screen [VersionGateScreen].
///
/// Routing is intentionally one-shot:
///   1. Drop the in-flight Dio error so the caller sees a clean "request was
///      handled" outcome (a synthetic [DioException] of type `cancel`).
///   2. Persist the payload so a cold-start still has the cached decision.
///   3. Replace the entire nav stack — back button must not bypass the gate.
///
/// Multiple concurrent 426s are de-duplicated via [_navigating] so we never
/// push the block screen twice on top of itself.
class VersionGateResponseInterceptor extends Interceptor {
  final GlobalKey<NavigatorState> _navigatorKey;
  final VersionCheckCache _cache;
  bool _navigating = false;

  VersionGateResponseInterceptor({
    required GlobalKey<NavigatorState> navigatorKey,
    required VersionCheckCache cache,
  })  : _navigatorKey = navigatorKey,
        _cache = cache;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode != 426) {
      handler.next(err);
      return;
    }
    final body = err.response?.data;
    Map<String, dynamic>? payload;
    if (body is Map<String, dynamic>) {
      payload = body;
    } else if (body is Map) {
      payload = Map<String, dynamic>.from(body);
    }
    if (payload == null) {
      handler.next(err);
      return;
    }
    final response = VersionGateResponse.fromJson(payload);
    // Persist in background — best-effort, don't block routing.
    unawaitedSafe(_cache.save(response));
    _routeToGate(response);
    // Swallow the error so the caller's `try/catch` does not surface a
    // "spurious" 426 to the user — the screen is already on top.
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        type: DioExceptionType.cancel,
        message: 'Request gated by version policy',
      ),
    );
  }

  void _routeToGate(VersionGateResponse response) {
    if (_navigating) return;
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      if (kDebugMode) {
        debugPrint(
          '[VersionGateResponseInterceptor] navigator unavailable, '
          'gate skipped (status=${response.status})',
        );
      }
      return;
    }
    _navigating = true;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => VersionGateScreen(payload: response),
        settings: const RouteSettings(name: '/version-gate'),
      ),
      (route) => false,
    );
    Future<void>.delayed(const Duration(seconds: 1), () {
      _navigating = false;
    });
  }
}

/// Top-level helper so we don't need to import `dart:async` everywhere.
void unawaitedSafe(Future<void> future) {
  future.then<void>(
    (_) {},
    onError: (Object _) {},
  );
}
