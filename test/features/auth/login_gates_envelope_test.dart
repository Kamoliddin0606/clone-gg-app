import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/login_gates_envelope.dart';

void main() {
  group('LoginGatesEnvelope', () {
    final fullJson = {
      'access': 'eyAccess',
      'refresh': 'eyRefresh',
      'gates': {
        'user_active_end': '2026-12-31T23:59:59Z',
        'license_valid_to': '2027-01-01T00:00:00Z',
        'organization_id': '11111111-1111-1111-1111-111111111111',
        'server_time': '2026-05-06T10:30:00Z',
        'bypass': false,
      },
    };

    test('fromJson parses all fields', () {
      final env = LoginGatesEnvelope.fromJson(fullJson);
      expect(env.accessToken, 'eyAccess');
      expect(env.refreshToken, 'eyRefresh');
      expect(env.userActiveEnd, DateTime.utc(2026, 12, 31, 23, 59, 59));
      expect(env.licenseValidTo, DateTime.utc(2027, 1, 1));
      expect(env.organizationId, '11111111-1111-1111-1111-111111111111');
      expect(env.serverTime, DateTime.utc(2026, 5, 6, 10, 30));
      expect(env.bypass, false);
    });

    test('toJson round-trips identically', () {
      final env = LoginGatesEnvelope.fromJson(fullJson);
      final round = LoginGatesEnvelope.fromJson(env.toJson());
      expect(round, env);
    });

    test('superuser bypass shape (license null + bypass true)', () {
      final env = LoginGatesEnvelope.fromJson({
        'access': 'a',
        'refresh': 'r',
        'gates': {
          'user_active_end': null,
          'license_valid_to': null,
          'organization_id': null,
          'server_time': '2026-05-06T10:30:00Z',
          'bypass': true,
        },
      });
      expect(env.bypass, true);
      expect(env.licenseValidTo, isNull);
      expect(env.organizationId, isNull);
    });

    test('tolerates missing optional gates fields', () {
      final env = LoginGatesEnvelope.fromJson({
        'access': 'a',
        'refresh': 'r',
        'gates': {'server_time': '2026-05-06T10:30:00Z'},
      });
      expect(env.bypass, false);
      expect(env.userActiveEnd, isNull);
      expect(env.licenseValidTo, isNull);
      expect(env.organizationId, isNull);
    });

    test('throws on missing required access/refresh', () {
      expect(
        () => LoginGatesEnvelope.fromJson({'access': '', 'refresh': 'r'}),
        throwsFormatException,
      );
      expect(
        () => LoginGatesEnvelope.fromJson({'refresh': 'r'}),
        throwsFormatException,
      );
    });

    test('encode → tryDecode round-trip', () {
      final env = LoginGatesEnvelope.fromJson(fullJson);
      final raw = env.encode();
      final back = LoginGatesEnvelope.tryDecode(raw);
      expect(back, env);
    });

    test('tryDecode returns null for empty / invalid input', () {
      expect(LoginGatesEnvelope.tryDecode(null), isNull);
      expect(LoginGatesEnvelope.tryDecode(''), isNull);
      expect(LoginGatesEnvelope.tryDecode('not json'), isNull);
    });

    test('equality works on all fields', () {
      final a = LoginGatesEnvelope.fromJson(fullJson);
      final b = LoginGatesEnvelope.fromJson(fullJson);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final c = a.copyWith(bypass: true);
      expect(c, isNot(equals(a)));
    });

    // ─── device-binding additions ─────────────────────────────────────
    test('fromJson parses the optional `device` block', () {
      final env = LoginGatesEnvelope.fromJson({
        ...fullJson,
        'device': {
          'binding_id': 'bind-1',
          'client_type': 'mobile',
          'session_id': 'sess-1',
        },
      });
      expect(env.device, isNotNull);
      expect(env.device!.bindingId, 'bind-1');
      expect(env.device!.clientType, 'mobile');
      expect(env.device!.sessionId, 'sess-1');
    });

    test('fromJson tolerates a missing `device` block (Stage 1 grace)', () {
      final env = LoginGatesEnvelope.fromJson(fullJson);
      expect(env.device, isNull);
    });

    test('toJson omits the `device` key when device is null', () {
      final env = LoginGatesEnvelope.fromJson(fullJson);
      expect(env.toJson().containsKey('device'), isFalse);
    });

    test('toJson serialises the `device` block at the same level as gates', () {
      final env = LoginGatesEnvelope.fromJson({
        ...fullJson,
        'device': {
          'binding_id': 'bind-1',
          'client_type': 'mobile',
          'session_id': 'sess-1',
        },
      });
      final json = env.toJson();
      expect(json.containsKey('device'), isTrue);
      expect(json.containsKey('gates'), isTrue);
      expect((json['device'] as Map)['binding_id'], 'bind-1');
    });

    test('equality differs when device differs', () {
      final without = LoginGatesEnvelope.fromJson(fullJson);
      final withDevice = LoginGatesEnvelope.fromJson({
        ...fullJson,
        'device': {
          'binding_id': 'bind-1',
          'client_type': 'mobile',
          'session_id': 'sess-1',
        },
      });
      expect(without, isNot(equals(withDevice)));
    });
  });
}
