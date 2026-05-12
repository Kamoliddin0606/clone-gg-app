import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/login_gates_envelope.dart';

void main() {
  group('LoginGatesEnvelope.permissions', () {
    test('parses a populated permissions array', () {
      final json = {
        'access': 'a' * 16,
        'refresh': 'r' * 16,
        'gates': {
          'server_time': '2026-05-09T08:00:00Z',
          'permissions': [
            'customers.add_customer_photo',
            'customers.change_customer_photo',
          ],
        },
      };
      final envelope = LoginGatesEnvelope.fromJson(json);
      expect(envelope.permissions, hasLength(2));
      expect(envelope.permissions, contains('customers.add_customer_photo'));
      expect(envelope.permissions, contains('customers.change_customer_photo'));
    });

    test('defaults to an empty list when the field is absent', () {
      final json = {
        'access': 'a' * 16,
        'refresh': 'r' * 16,
        'gates': {
          'server_time': '2026-05-09T08:00:00Z',
        },
      };
      final envelope = LoginGatesEnvelope.fromJson(json);
      expect(envelope.permissions, isEmpty);
    });

    test('skips non-string entries silently', () {
      final json = {
        'access': 'a' * 16,
        'refresh': 'r' * 16,
        'gates': {
          'server_time': '2026-05-09T08:00:00Z',
          'permissions': [
            'customers.add_customer_photo',
            42, // garbage
            null, // garbage
            'customers.delete_customer_photo',
          ],
        },
      };
      final envelope = LoginGatesEnvelope.fromJson(json);
      expect(envelope.permissions, hasLength(2));
      expect(envelope.permissions, contains('customers.add_customer_photo'));
      expect(envelope.permissions,
          contains('customers.delete_customer_photo'));
    });

    test('encode preserves permissions across reload', () {
      final envelope = LoginGatesEnvelope(
        accessToken: 'access',
        refreshToken: 'refresh',
        userActiveEnd: null,
        licenseValidTo: null,
        organizationId: 'org-1',
        serverTime: DateTime.utc(2026, 5, 9, 8),
        bypass: false,
        permissions: const ['customers.add_customer_photo'],
      );
      final encoded = envelope.encode();
      final decoded = LoginGatesEnvelope.tryDecode(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.permissions, ['customers.add_customer_photo']);
    });

    test('copyWith overrides permissions', () {
      final base = LoginGatesEnvelope(
        accessToken: 'a',
        refreshToken: 'r',
        userActiveEnd: null,
        licenseValidTo: null,
        organizationId: null,
        serverTime: DateTime.utc(2026, 5, 9),
        bypass: true,
        permissions: const <String>[],
      );
      final next = base.copyWith(permissions: const ['x']);
      expect(next.permissions, const ['x']);
      expect(base.permissions, isEmpty); // immutability
    });
  });
}
