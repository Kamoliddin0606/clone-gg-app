import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gloria_marketing_flutter/src/core/version/data/version_check_cache.dart';
import 'package:gloria_marketing_flutter/src/core/version/data/version_gate_api.dart';
import 'package:gloria_marketing_flutter/src/core/version/data/version_gate_response.dart';
import 'package:gloria_marketing_flutter/src/core/version/data/version_app_info.dart';
import 'package:gloria_marketing_flutter/src/core/version/domain/version_gate_service.dart';
import 'package:gloria_marketing_flutter/src/core/version/domain/version_gate_status.dart';

class _FakeApi implements VersionGateApi {
  _FakeApi({this.response, this.shouldThrow = false});

  VersionGateResponse? response;
  bool shouldThrow;
  int callCount = 0;

  @override
  Future<VersionGateResponse?> check({String locale = 'uz'}) async {
    callCount += 1;
    if (shouldThrow) {
      throw Exception('forced network failure');
    }
    return response;
  }
}

VersionGateResponse buildResponse({
  VersionGateStatus status = VersionGateStatus.ok,
}) {
  return VersionGateResponse(
    status: status,
    app: 'sales',
    platform: 'android',
    currentVersion: '1.0.0',
    latestVersion: '1.0.0',
    minSupportedVersion: '0.9.0',
    storeUrl: 'https://store.example/app',
    releaseNotes: '',
    title: '',
    message: '',
    canDismiss: status == VersionGateStatus.softUpdate,
    checkedAt: DateTime.utc(2026, 5, 16),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('VersionGateService.checkOnStartup', () {
    test('saves fresh response to cache and returns it', () async {
      final api = _FakeApi(response: buildResponse(status: VersionGateStatus.softUpdate));
      final cache = VersionCheckCache();
      final service = VersionGateService(api: api, cache: cache);
      final result = await service.checkOnStartup();
      expect(result, isNotNull);
      expect(result!.status, VersionGateStatus.softUpdate);
      // Cache populated for offline use.
      expect((await cache.read())?.status, VersionGateStatus.softUpdate);
    });

    test('falls back to cached response when API returns null', () async {
      final api = _FakeApi(response: null);
      final cache = VersionCheckCache();
      await cache.save(buildResponse(status: VersionGateStatus.forceUpdate));
      final service = VersionGateService(api: api, cache: cache);
      final result = await service.checkOnStartup();
      expect(result, isNotNull);
      expect(result!.status, VersionGateStatus.forceUpdate);
    });

    test('falls back to cached response when API throws', () async {
      final api = _FakeApi(shouldThrow: true);
      final cache = VersionCheckCache();
      await cache.save(buildResponse(status: VersionGateStatus.blocked));
      final service = VersionGateService(api: api, cache: cache);
      final result = await service.checkOnStartup();
      expect(result, isNotNull);
      expect(result!.status, VersionGateStatus.blocked);
    });

    test('returns null when offline AND no cache (fail-open)', () async {
      final api = _FakeApi(response: null);
      final service = VersionGateService(
        api: api,
        cache: VersionCheckCache(),
      );
      expect(await service.checkOnStartup(), isNull);
    });
  });

  group('VersionGateService.checkOnResume', () {
    test('skips network when last check is < 1 hour ago', () async {
      final api = _FakeApi(response: buildResponse());
      final cache = VersionCheckCache();
      await cache.save(buildResponse(status: VersionGateStatus.softUpdate));
      final service = VersionGateService(
        api: api,
        cache: cache,
        clock: () => DateTime.now().toUtc().add(const Duration(minutes: 30)),
      );
      final result = await service.checkOnResume();
      expect(api.callCount, 0);
      expect(result?.status, VersionGateStatus.softUpdate);
    });

    test('re-checks network when last check is > 1 hour ago', () async {
      final api = _FakeApi(response: buildResponse(status: VersionGateStatus.forceUpdate));
      final cache = VersionCheckCache();
      await cache.save(buildResponse(status: VersionGateStatus.ok));
      final service = VersionGateService(
        api: api,
        cache: cache,
        clock: () => DateTime.now().toUtc().add(const Duration(hours: 2)),
      );
      final result = await service.checkOnResume();
      expect(api.callCount, 1);
      expect(result?.status, VersionGateStatus.forceUpdate);
    });
  });

  group('VersionGateService.dismissSoftUpdate', () {
    test('persists a 24h window and clears after expiry', () async {
      final cache = VersionCheckCache();
      var now = DateTime.utc(2026, 5, 16, 12, 0, 0);
      final service = VersionGateService(
        api: _FakeApi(),
        cache: cache,
        clock: () => now,
      );

      expect(await service.isSoftUpdateDismissed(), isFalse);

      await service.dismissSoftUpdate();
      expect(await service.isSoftUpdateDismissed(), isTrue);

      // Advance 23h — still suppressed.
      now = now.add(const Duration(hours: 23));
      expect(await service.isSoftUpdateDismissed(), isTrue);

      // Advance past 24h — suppression elapsed.
      now = now.add(const Duration(hours: 2));
      expect(await service.isSoftUpdateDismissed(), isFalse);
    });
  });

  test('shouldBlock helper matches blocksApp', () {
    expect(VersionGateService.shouldBlock(null), isFalse);
    expect(
      VersionGateService.shouldBlock(buildResponse(status: VersionGateStatus.ok)),
      isFalse,
    );
    expect(
      VersionGateService.shouldBlock(buildResponse(status: VersionGateStatus.softUpdate)),
      isFalse,
    );
    expect(
      VersionGateService.shouldBlock(buildResponse(status: VersionGateStatus.forceUpdate)),
      isTrue,
    );
    expect(
      VersionGateService.shouldBlock(buildResponse(status: VersionGateStatus.blocked)),
      isTrue,
    );
    expect(
      VersionGateService.shouldBlock(buildResponse(status: VersionGateStatus.maintenance)),
      isTrue,
    );
  });

  test('VersionAppInfo.empty is safe to use as sentinel', () {
    expect(VersionAppInfo.empty.packageName, isEmpty);
    expect(VersionAppInfo.empty.platform, isEmpty);
    expect(VersionAppInfo.empty.appVersion, isEmpty);
  });
}
