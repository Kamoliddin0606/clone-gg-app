import 'package:dio/dio.dart';

import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_mapper_interceptor.dart';
import 'interceptors/project_header_interceptor.dart';
import 'interceptors/server_time_interceptor.dart';

/// Dio wrapper preconfigured for `/api/mobile/v2/`.
///
/// Two factories:
///   * [create] — the production client (auth + project header + server-time
///     capture + error mapping).
///   * [createAuthFree] — used by `ServerTimeService` for the auth-free
///     `/visits/server-time/` endpoint to avoid recursive token loads.
class RestV2Client {
  RestV2Client._(this.dio);

  /// Test-only bypass that lets callers inject a pre-configured [Dio]
  /// (mock adapters, capturing interceptors). Production code must always
  /// use [create] / [createAuthFree] so the real interceptor chain stays
  /// intact — do not invoke this constructor from non-test code.
  RestV2Client.testHook(this.dio);

  final Dio dio;

  factory RestV2Client.create({
    required String baseUrl,
    required Future<String?> Function() accessTokenLoader,
    required Future<String?> Function() projectIdLoader,
    required void Function(DateTime serverTime) onServerTime,
  }) {
    final dio = _baseDio(baseUrl);
    dio.interceptors.addAll([
      AuthInterceptor(accessTokenLoader: accessTokenLoader),
      ProjectHeaderInterceptor(projectIdLoader: projectIdLoader),
      ServerTimeInterceptor(onServerTime: onServerTime),
      ErrorMapperInterceptor(),
    ]);
    return RestV2Client._(dio);
  }

  factory RestV2Client.createAuthFree({
    required String baseUrl,
    required void Function(DateTime serverTime) onServerTime,
  }) {
    final dio = _baseDio(baseUrl);
    dio.interceptors.addAll([
      ServerTimeInterceptor(onServerTime: onServerTime),
      ErrorMapperInterceptor(),
    ]);
    return RestV2Client._(dio);
  }

  static Dio _baseDio(String baseUrl) => Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/vnd.gloria.v2+json',
          'Accept-Language': 'uz,ru;q=0.9,en;q=0.8',
        },
        validateStatus: (s) => s != null && s < 600,
      ));
}
