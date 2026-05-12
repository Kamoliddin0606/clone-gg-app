import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/customer_photo_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/customer_photo_service.dart';

void main() {
  group('CustomerPhotoException hierarchy', () {
    test('base exception carries code, message, details, statusCode', () {
      const e = CustomerPhotoException(
        code: 'image_too_large',
        message: 'too big',
        details: <String, dynamic>{'limit': 15},
        statusCode: 400,
      );
      expect(e.code, 'image_too_large');
      expect(e.message, 'too big');
      expect(e.details, isNotNull);
      expect(e.details!['limit'], 15);
      expect(e.statusCode, 400);
      // toString should at least mention the code so error logs are
      // grep-able.
      expect(e.toString(), contains('image_too_large'));
    });

    test('CapExceeded exposes the cap envelope fields', () {
      const e = CustomerPhotoCapExceeded(
        max: 10,
        current: 10,
        available: 0,
        requested: 1,
        message: 'cap',
      );
      expect(e, isA<CustomerPhotoException>());
      expect(e.code, 'customer_photo_limit_exceeded');
      expect(e.statusCode, 409);
      expect(e.max, 10);
      expect(e.current, 10);
      expect(e.available, 0);
      expect(e.requested, 1);
    });

    test('ValidationFailed inherits code + message + details', () {
      const e = CustomerPhotoValidationFailed(
        code: 'image_invalid_format',
        message: 'nope',
        details: <String, dynamic>{'allowed': 'JPEG,PNG'},
      );
      expect(e, isA<CustomerPhotoException>());
      expect(e.code, 'image_invalid_format');
      expect(e.statusCode, 400);
      expect(e.details!['allowed'], 'JPEG,PNG');
    });

    test('ReprocessUnsupported has the right code + status', () {
      const e = CustomerPhotoReprocessUnsupported(
        message: 'no original kept',
      );
      expect(e, isA<CustomerPhotoException>());
      expect(e.code, 'image_reprocess_not_supported');
      expect(e.statusCode, 400);
    });
  });
}
