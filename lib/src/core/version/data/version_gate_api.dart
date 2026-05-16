import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/core/version/data/version_app_info.dart';
import 'package:gloria_marketing_flutter/src/core/version/data/version_gate_response.dart';

/// Thin Dio wrapper around `GET /api/mobile/v2/app/version-check/`.
///
/// Owns a dedicated Dio instance so the global REST interceptors (auth, 426
/// gate, app-version headers) never leak in here:
///   - this endpoint is anonymous (login'gacha chaqiriladi),
///   - 426 handling must be inline (calling the response interceptor would
///     loop forever on a single failing version-check call).
///
/// The request itself carries the same `X-App-*` headers the rest of the app
/// emits — backend identifies the app + platform + current version from them.
class VersionGateApi {
  static const _endpoint = '/api/mobile/v2/app/version-check/';

  final Dio _dio;
  final VersionAppInfo Function() _appInfoProvider;

  VersionGateApi({
    Dio? dio,
    required VersionAppInfo Function() appInfoProvider,
  })  : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: TokenService.v2BaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 10),
              // Treat the documented 4xx (`400 app_version_invalid_request`,
              // `404 app_version_unknown_app`) as non-throwing — the caller
              // logs them and falls back to cache without showing a gate.
              validateStatus: (status) => status != null && status < 500,
            )),
        _appInfoProvider = appInfoProvider;

  /// Issue the version-check request. Returns null on:
  ///   - network failure (offline / DNS)
  ///   - server 4xx (handled by caller: log + fall back to cache)
  ///   - malformed body
  Future<VersionGateResponse?> check({String locale = 'uz'}) async {
    final info = _appInfoProvider();
    final headers = <String, dynamic>{
      if (info.packageName.isNotEmpty) 'X-App-Identifier': info.packageName,
      if (info.platform.isNotEmpty) 'X-App-Platform': info.platform,
      if (info.appVersion.isNotEmpty) 'X-App-Version': info.appVersion,
      if (info.buildNumber.isNotEmpty) 'X-App-Build': info.buildNumber,
      if (info.osVersion.isNotEmpty) 'X-OS-Version': info.osVersion,
      if (info.deviceModel.isNotEmpty) 'X-Device-Model': info.deviceModel,
      'Accept-Language': locale,
    };

    try {
      final response = await _dio.get<dynamic>(
        _endpoint,
        options: Options(headers: headers),
      );
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        if (kDebugMode) {
          debugPrint(
            '[VersionGateApi] HTTP $status — body=${response.data}',
          );
        }
        return null;
      }
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return VersionGateResponse.fromJson(data);
      }
      if (data is Map) {
        return VersionGateResponse.fromJson(
          Map<String, dynamic>.from(data),
        );
      }
      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[VersionGateApi] dio error: ${e.type} ${e.message}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[VersionGateApi] unexpected error: $e');
      }
      return null;
    }
  }
}
