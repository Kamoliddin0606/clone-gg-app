import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/login_device_payload.dart';

void main() {
  group('LoginDevicePayload', () {
    const sample = LoginDevicePayload(
      clientType: LoginDeviceClientTypes.mobile,
      appInstanceId: '5b1f4000-uuid-v4-here',
      platform: LoginDevicePlatforms.ios,
      deviceName: 'iPhone15,2',
      osVersion: 'iOS 26.3.1',
      appVersion: '1.4.7',
    );

    test('toJson uses snake_case keys per backend contract', () {
      expect(sample.toJson(), <String, dynamic>{
        'client_type': 'mobile',
        'app_instance_id': '5b1f4000-uuid-v4-here',
        'platform': 'ios',
        'device_name': 'iPhone15,2',
        'os_version': 'iOS 26.3.1',
        'app_version': '1.4.7',
      });
    });

    test('every required field is present in toJson output', () {
      const expected = <String>{
        'client_type',
        'app_instance_id',
        'platform',
        'device_name',
        'os_version',
        'app_version',
      };
      expect(sample.toJson().keys.toSet(), expected);
    });

    test('client type enum lives behind a constant, not a string literal', () {
      // Guard against accidental "moble" / "mibile" typos drifting in.
      expect(LoginDeviceClientTypes.mobile, 'mobile');
      expect(LoginDeviceClientTypes.web, 'web');
    });

    test('platform enum lives behind a constant, not a string literal', () {
      expect(LoginDevicePlatforms.android, 'android');
      expect(LoginDevicePlatforms.ios, 'ios');
    });

    test('copyWith replaces only the requested fields', () {
      final copy = sample.copyWith(deviceName: 'iPhone17,1');
      expect(copy.deviceName, 'iPhone17,1');
      expect(copy.appInstanceId, sample.appInstanceId);
      expect(copy.appVersion, sample.appVersion);
    });

    test('equality + hashCode cover every field', () {
      const dup = LoginDevicePayload(
        clientType: 'mobile',
        appInstanceId: '5b1f4000-uuid-v4-here',
        platform: 'ios',
        deviceName: 'iPhone15,2',
        osVersion: 'iOS 26.3.1',
        appVersion: '1.4.7',
      );
      expect(sample, equals(dup));
      expect(sample.hashCode, dup.hashCode);
    });

    test('toString redacts the appInstanceId', () {
      final s = sample.toString();
      expect(s.contains('appInstanceId=<redacted>'), isTrue);
      expect(s.contains('5b1f4000'), isFalse);
    });
  });
}
