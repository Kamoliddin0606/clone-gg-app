import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gloria_marketing_flutter/src/core/version/data/version_check_cache.dart';
import 'package:gloria_marketing_flutter/src/core/version/data/version_gate_response.dart';
import 'package:gloria_marketing_flutter/src/core/version/domain/version_gate_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  VersionGateResponse buildResponse(VersionGateStatus status) =>
      VersionGateResponse(
        status: status,
        app: 'sales',
        platform: 'android',
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        minSupportedVersion: '0.9.0',
        storeUrl: 'https://play.google.com/store/apps/details?id=uz.gloriya.sales',
        releaseNotes: 'Notes',
        title: 'Title',
        message: 'Message',
        canDismiss: status == VersionGateStatus.softUpdate,
        checkedAt: DateTime.utc(2026, 5, 16),
      );

  test('read() returns null when nothing is cached', () async {
    final cache = VersionCheckCache();
    expect(await cache.read(), isNull);
    expect(await cache.lastCheckAt(), isNull);
    expect(await cache.dismissedSoftUntil(), isNull);
  });

  test('save() round-trips through read()', () async {
    final cache = VersionCheckCache();
    final response = buildResponse(VersionGateStatus.forceUpdate);
    await cache.save(response);
    final restored = await cache.read();
    expect(restored, isNotNull);
    expect(restored!.status, VersionGateStatus.forceUpdate);
    expect(restored.currentVersion, '1.0.0');
    expect(await cache.lastCheckAt(), isNotNull);
  });

  test('setDismissedSoftUntil() persists the timestamp', () async {
    final cache = VersionCheckCache();
    final until = DateTime.utc(2026, 5, 17, 12, 0, 0);
    await cache.setDismissedSoftUntil(until);
    final read = await cache.dismissedSoftUntil();
    expect(read, isNotNull);
    expect(read!.millisecondsSinceEpoch, until.millisecondsSinceEpoch);
  });

  test('clear() wipes all three keys', () async {
    final cache = VersionCheckCache();
    await cache.save(buildResponse(VersionGateStatus.softUpdate));
    await cache.setDismissedSoftUntil(DateTime.utc(2026, 5, 20));
    await cache.clear();
    expect(await cache.read(), isNull);
    expect(await cache.lastCheckAt(), isNull);
    expect(await cache.dismissedSoftUntil(), isNull);
  });
}
