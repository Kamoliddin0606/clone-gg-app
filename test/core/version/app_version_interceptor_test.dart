import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gloria_marketing_flutter/src/core/version/data/app_version_interceptor.dart';
import 'package:gloria_marketing_flutter/src/core/version/data/version_app_info.dart';

void main() {
  group('AppVersionInterceptor', () {
    test('stamps all six X-App-* headers from VersionAppInfo', () async {
      final info = VersionAppInfo(
        packageName: 'uz.gloriya.sales',
        platform: 'android',
        appVersion: '1.4.2',
        buildNumber: '142',
        osVersion: '14',
        deviceModel: 'Pixel 7',
      );
      final interceptor = AppVersionInterceptor(() => info);
      final options = RequestOptions(path: '/api/mobile/v2/customers/');
      final handler = _CapturingHandler();
      interceptor.onRequest(options, handler);
      expect(handler.options?.headers['X-App-Identifier'], 'uz.gloriya.sales');
      expect(handler.options?.headers['X-App-Platform'], 'android');
      expect(handler.options?.headers['X-App-Version'], '1.4.2');
      expect(handler.options?.headers['X-App-Build'], '142');
      expect(handler.options?.headers['X-OS-Version'], '14');
      expect(handler.options?.headers['X-Device-Model'], 'Pixel 7');
    });

    test('does not overwrite headers set explicitly by the caller', () async {
      final info = VersionAppInfo(
        packageName: 'uz.gloriya.sales',
        platform: 'android',
        appVersion: '1.4.2',
        buildNumber: '',
        osVersion: '',
        deviceModel: '',
      );
      final interceptor = AppVersionInterceptor(() => info);
      final options = RequestOptions(
        path: '/x',
        headers: {'X-App-Identifier': 'override.bundle.id'},
      );
      final handler = _CapturingHandler();
      interceptor.onRequest(options, handler);
      expect(handler.options?.headers['X-App-Identifier'], 'override.bundle.id');
    });

    test('skips empty fields gracefully (empty sentinel = no headers)', () async {
      final interceptor = AppVersionInterceptor(() => VersionAppInfo.empty);
      final options = RequestOptions(path: '/x');
      final handler = _CapturingHandler();
      interceptor.onRequest(options, handler);
      expect(handler.options?.headers.containsKey('X-App-Identifier'), isFalse);
      expect(handler.options?.headers.containsKey('X-App-Version'), isFalse);
    });
  });
}

class _CapturingHandler extends RequestInterceptorHandler {
  RequestOptions? options;

  @override
  void next(RequestOptions requestOptions) {
    options = requestOptions;
  }
}
