import 'package:dio/dio.dart';

import 'package:gloria_marketing_flutter/src/core/version/data/version_app_info.dart';

/// Dio request interceptor that stamps every outgoing call with the six
/// `X-App-*` / `X-OS-*` / `X-Device-*` headers the backend uses to identify
/// the calling app, platform, and version.
///
/// Headers already set on the request are left untouched so a caller can
/// override a single value (e.g. unit tests).
class AppVersionInterceptor extends Interceptor {
  final VersionAppInfo Function() _appInfoProvider;

  AppVersionInterceptor(this._appInfoProvider);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final info = _appInfoProvider();
    _putIfAbsent(options, 'X-App-Identifier', info.packageName);
    _putIfAbsent(options, 'X-App-Platform', info.platform);
    _putIfAbsent(options, 'X-App-Version', info.appVersion);
    _putIfAbsent(options, 'X-App-Build', info.buildNumber);
    _putIfAbsent(options, 'X-OS-Version', info.osVersion);
    _putIfAbsent(options, 'X-Device-Model', info.deviceModel);
    handler.next(options);
  }

  static void _putIfAbsent(
    RequestOptions options,
    String header,
    String value,
  ) {
    if (value.isEmpty) return;
    if (options.headers.containsKey(header)) return;
    options.headers[header] = value;
  }
}
