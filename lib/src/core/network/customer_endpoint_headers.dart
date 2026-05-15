import 'package:dio/dio.dart';

import '../services/project_context.dart';
import '../services/service_locator.dart';

/// Builds the header map every `/api/mobile/v2/customers/...` REST call
/// must attach. Centralised here so the four call sites that hit those
/// endpoints (`CustomerReadRepository`, `CustomerWriteRepository`,
/// `CustomerPhotoRepository`, `ClientBalanceService`) share a single
/// implementation of the `X-Project-Id` rule.
///
/// Rule (per `customer_scope=project` rollout):
///   * Org-scope tenants → header omitted, headers map carries only
///     [Accept] and (caller-supplied) auth.
///   * Project-scope tenants → header set from
///     [ProjectContext.activeProjectHeaderValue]. Missing value throws a
///     `customer_project_required` [DioException] so the caller gets the
///     same envelope the backend would return on the bare endpoint.
///
/// Authorisation header is OUT of scope here — `ApiService._dio` already
/// attaches the Bearer token via the global token interceptor, so we
/// only emit the project header. Callers using their own Dio (the three
/// repositories above) merge the auth header themselves.
class CustomerEndpointHeaders {
  CustomerEndpointHeaders._();

  /// Returns the `Options` argument to pass to `Dio.post` / `Dio.get`
  /// for `/api/mobile/v2/customers/...` endpoints. Throws on missing
  /// project header in project-scope mode.
  static Options optionsForRequest({
    String requestPath = '/api/mobile/v2/customers/',
    ProjectContext? projectContext,
  }) {
    final ctx = projectContext ?? sl<ProjectContext>();
    final headers = <String, String>{};
    if (ctx.requiresProjectHeader) {
      final value = ctx.activeProjectHeaderValue;
      if (value == null || value.isEmpty) {
        throw DioException(
          requestOptions: RequestOptions(path: requestPath),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: requestPath),
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
      headers['X-Project-Id'] = value;
    }
    return Options(headers: headers);
  }

  /// Same as [optionsForRequest] but returns just the headers map for
  /// callers that build their own `Options` (e.g. when they also need to
  /// set `Accept`, custom timeouts, etc.).
  static Map<String, String> headersForRequest({
    String requestPath = '/api/mobile/v2/customers/',
    ProjectContext? projectContext,
  }) {
    final ctx = projectContext ?? sl<ProjectContext>();
    final headers = <String, String>{};
    if (ctx.requiresProjectHeader) {
      final value = ctx.activeProjectHeaderValue;
      if (value == null || value.isEmpty) {
        throw DioException(
          requestOptions: RequestOptions(path: requestPath),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: requestPath),
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
      headers['X-Project-Id'] = value;
    }
    return headers;
  }
}
