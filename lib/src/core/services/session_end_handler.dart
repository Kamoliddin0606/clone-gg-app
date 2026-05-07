// =============================================================================
// SessionEndHandler
// =============================================================================
//
// Single-responsibility cleanup helper for "the backend says this session
// is no longer valid" scenarios. Three call sites today, more later:
//
//   1. AuthBloc logout — explicit user action.
//   2. AppStartGuard refresh-denial — backend rejected the cached refresh
//      token at cold start.
//   3. (Stage 4, follow-up PR) Dio interceptor catching HTTP 401 with
//      `device_binding_invalid` / `session_revoked` on V2 endpoints.
//
// Every path needs identical behaviour: clear V2 tokens + cached gates +
// cached device binding atomically, then route the user to the login
// screen with a localized banner explaining why.
//
// The local UUID (`local_device_uuid`) is INTENTIONALLY preserved so the
// same physical handset re-binds to the same row once admin releases the
// binding from the React panel.
// =============================================================================

import 'package:flutter/foundation.dart';

import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/auth_failure.dart';

/// Atomic teardown of every cache that the V2 auth flow populates.
///
/// The [reason] is a typed [AuthFailure] (e.g. [SessionRevokedFailure]).
/// Its [AuthFailure.messageKey] is forwarded to the login route as a
/// `String` argument so [LoginPage] can render the matching localized
/// message via its `_localizeMessageKey` helper.
///
/// Safe to call from any thread / context — every step is wrapped in a
/// try/catch so a failing cache write never escapes the handler.
///
// TODO(stage-4): wire this from a Dio interceptor that intercepts HTTP
// 401 with `device_binding_invalid` / `session_revoked` on the V2 stack.
// The interceptor must extract the AuthFailure via
// `AuthFailure.fromErrorEnvelope(response.data, 401)` and pass it here.
Future<void> handleSessionEnded(AuthFailure reason) async {
  if (kDebugMode) {
    print('[SessionEnd] reason=${reason.runtimeType} '
        '(messageKey=${reason.messageKey})');
  }

  final prefs = sl<SharedPreferencesService>();
  final tokens = sl<TokenService>();

  try {
    await tokens.clearV2Tokens();
  } catch (e) {
    if (kDebugMode) print('[SessionEnd] clearV2Tokens error: $e');
  }
  try {
    await prefs.clearCachedGates();
  } catch (e) {
    if (kDebugMode) print('[SessionEnd] clearCachedGates error: $e');
  }
  try {
    await prefs.clearCachedDeviceBinding();
  } catch (e) {
    if (kDebugMode) print('[SessionEnd] clearCachedDeviceBinding error: $e');
  }

  // Route the user back to the login screen, passing the message key as
  // an argument so the page can show the banner. `pushNamedAndRemoveUntil`
  // wipes the stack so the cleared session can't be navigated back to.
  AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
    AppRouter.loginRoute,
    (_) => false,
    arguments: reason.messageKey,
  );
}
