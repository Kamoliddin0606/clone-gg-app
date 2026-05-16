import 'package:flutter_test/flutter_test.dart';

import 'package:gloria_marketing_flutter/src/core/version/data/version_gate_response.dart';
import 'package:gloria_marketing_flutter/src/core/version/domain/version_gate_status.dart';

void main() {
  group('VersionGateStatus.fromString', () {
    test('maps each documented status correctly', () {
      expect(VersionGateStatus.fromString('ok'), VersionGateStatus.ok);
      expect(
        VersionGateStatus.fromString('soft_update'),
        VersionGateStatus.softUpdate,
      );
      expect(
        VersionGateStatus.fromString('force_update'),
        VersionGateStatus.forceUpdate,
      );
      expect(
        VersionGateStatus.fromString('blocked'),
        VersionGateStatus.blocked,
      );
      expect(
        VersionGateStatus.fromString('maintenance'),
        VersionGateStatus.maintenance,
      );
    });

    test('unknown / null fails open to ok (fail-open contract)', () {
      expect(VersionGateStatus.fromString(null), VersionGateStatus.ok);
      expect(VersionGateStatus.fromString(''), VersionGateStatus.ok);
      expect(
        VersionGateStatus.fromString('not_a_known_status'),
        VersionGateStatus.ok,
      );
    });

    test('blocksApp is true only for force/blocked/maintenance', () {
      expect(VersionGateStatus.ok.blocksApp, isFalse);
      expect(VersionGateStatus.softUpdate.blocksApp, isFalse);
      expect(VersionGateStatus.forceUpdate.blocksApp, isTrue);
      expect(VersionGateStatus.blocked.blocksApp, isTrue);
      expect(VersionGateStatus.maintenance.blocksApp, isTrue);
    });

    test('wireValue round-trips through fromString', () {
      for (final s in VersionGateStatus.values) {
        expect(VersionGateStatus.fromString(s.wireValue), s);
      }
    });
  });

  group('VersionGateResponse.fromJson', () {
    test('parses the full documented payload', () {
      final json = {
        'status': 'soft_update',
        'app': 'sales',
        'platform': 'android',
        'current_version': '1.4.2',
        'latest_version': '1.5.0',
        'min_supported_version': '1.3.0',
        'store_url': 'https://play.google.com/store/apps/details?id=uz.gloriya.sales',
        'release_notes': '• Bug fixes',
        'title': 'Yangilanish mavjud',
        'message': 'Yangi versiya chiqdi',
        'can_dismiss': true,
        'checked_at': '2026-05-16T07:00:00Z',
      };
      final r = VersionGateResponse.fromJson(json);
      expect(r.status, VersionGateStatus.softUpdate);
      expect(r.app, 'sales');
      expect(r.currentVersion, '1.4.2');
      expect(r.latestVersion, '1.5.0');
      expect(r.canDismiss, isTrue);
      expect(r.checkedAt.year, 2026);
      expect(r.checkedAt.isUtc, isTrue);
    });

    test('null string fields fall back to empty', () {
      final r = VersionGateResponse.fromJson({'status': 'ok'});
      expect(r.status, VersionGateStatus.ok);
      expect(r.app, '');
      expect(r.releaseNotes, '');
      expect(r.canDismiss, isFalse);
    });

    test('toJson round-trips', () {
      final original = VersionGateResponse(
        status: VersionGateStatus.forceUpdate,
        app: 'sales',
        platform: 'ios',
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        minSupportedVersion: '1.5.0',
        storeUrl: 'https://apps.apple.com/app/id123',
        releaseNotes: '• Required update',
        title: 'Update required',
        message: 'Please update',
        canDismiss: false,
        checkedAt: DateTime.utc(2026, 5, 16, 7, 0, 0),
      );
      final restored = VersionGateResponse.fromJson(original.toJson());
      expect(restored.status, original.status);
      expect(restored.app, original.app);
      expect(restored.platform, original.platform);
      expect(restored.currentVersion, original.currentVersion);
      expect(restored.latestVersion, original.latestVersion);
      expect(restored.minSupportedVersion, original.minSupportedVersion);
      expect(restored.storeUrl, original.storeUrl);
      expect(restored.releaseNotes, original.releaseNotes);
      expect(restored.title, original.title);
      expect(restored.message, original.message);
      expect(restored.canDismiss, original.canDismiss);
      expect(restored.checkedAt, original.checkedAt);
    });
  });
}
