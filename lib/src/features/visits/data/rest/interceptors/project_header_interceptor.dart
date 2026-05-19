import 'package:dio/dio.dart';

/// Attaches `X-Project-Id` for organisations whose `customer_scope='project'`.
///
/// The loader returns `null` for org-scoped tenants — in which case we omit
/// the header so the backend doesn't 400 us (it refuses the header when the
/// org has `customer_scope='organization'`).
class ProjectHeaderInterceptor extends Interceptor {
  ProjectHeaderInterceptor({required Future<String?> Function() projectIdLoader})
      : _loader = projectIdLoader;

  final Future<String?> Function() _loader;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final id = await _loader();
    if (id != null && id.isNotEmpty) {
      options.headers['X-Project-Id'] = id;
    }
    handler.next(options);
  }
}
