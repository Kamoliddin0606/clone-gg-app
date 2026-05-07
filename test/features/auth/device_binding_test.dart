import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/device_binding.dart';

void main() {
  group('DeviceBinding', () {
    const fullJson = {
      'binding_id': 'b-123',
      'client_type': 'mobile',
      'session_id': 's-456',
    };

    test('fromJson parses every field', () {
      final binding = DeviceBinding.fromJson(fullJson);
      expect(binding.bindingId, 'b-123');
      expect(binding.clientType, 'mobile');
      expect(binding.sessionId, 's-456');
    });

    test('toJson round-trips identically', () {
      final binding = DeviceBinding.fromJson(fullJson);
      expect(binding.toJson(), fullJson);
    });

    test('encode then tryDecode yields the same instance', () {
      const original = DeviceBinding(
        bindingId: 'b-1',
        clientType: 'mobile',
        sessionId: 's-2',
      );
      final decoded = DeviceBinding.tryDecode(original.encode());
      expect(decoded, original);
    });

    test('tryDecode returns null for empty / corrupt input', () {
      expect(DeviceBinding.tryDecode(null), isNull);
      expect(DeviceBinding.tryDecode(''), isNull);
      expect(DeviceBinding.tryDecode('not json'), isNull);
      // Valid JSON but wrong shape → null.
      expect(DeviceBinding.tryDecode('[1,2,3]'), isNull);
    });

    test('fromJson tolerates missing fields by defaulting to empty strings', () {
      final binding = DeviceBinding.fromJson(<String, dynamic>{});
      expect(binding.bindingId, '');
      expect(binding.clientType, '');
      expect(binding.sessionId, '');
    });

    test('equality + hashCode work on every field', () {
      const a = DeviceBinding(bindingId: 'b', clientType: 'mobile', sessionId: 's');
      const b = DeviceBinding(bindingId: 'b', clientType: 'mobile', sessionId: 's');
      const c = DeviceBinding(bindingId: 'X', clientType: 'mobile', sessionId: 's');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('toString does NOT leak the full bindingId / sessionId', () {
      const binding = DeviceBinding(
        bindingId: '00000000-1111-2222-3333-444444444444',
        clientType: 'mobile',
        sessionId: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      );
      final s = binding.toString();
      // Truncated to 8 chars + ellipsis — never the full UUID.
      expect(s.contains('00000000'), isTrue);
      expect(s.contains('44444444'), isFalse);
      expect(s.contains('eeeeeeee'), isFalse);
    });
  });
}
