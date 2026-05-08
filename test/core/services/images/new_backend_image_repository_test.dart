import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/image_target_type.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/new_backend_image_repository.dart';

void main() {
  group('NewBackendImageRepository.parseImageJson', () {
    test('parses a fully-populated row from the new backend', () {
      final json = <String, dynamic>{
        'id': '5b1f4e60-1234-4abc-8def-0123456789ab',
        'target': <String, dynamic>{
          'type': 'projectproduct',
          'id': '11111111-2222-3333-4444-555555555555',
          'code_1c': 'GLR0000123',
        },
        'small': 'https://api.selup.uz/media/img/s/abc.webp',
        'medium': 'https://api.selup.uz/media/img/m/abc.webp',
        'large': 'https://api.selup.uz/media/img/l/abc.webp',
        'width': 3000,
        'height': 2000,
        'blurhash': 'L6PZfSi_.AyE_3t7t7R**0o#DgR4',
        'alt': 'Front view',
        'order': 0,
        'is_primary': true,
        'status': 'ready',
        'created_at': '2026-05-06T12:34:56Z',
      };
      final image = NewBackendImageRepository.parseImageJson(json, 'org-A');
      expect(image, isNotNull);
      expect(image!.id, '5b1f4e60-1234-4abc-8def-0123456789ab');
      expect(image.targetType, ImageTargetType.product);
      // The Django ContentType `projectproduct` is normalised to the
      // canonical mobile key `product`.
      expect(image.targetId, '11111111-2222-3333-4444-555555555555');
      expect(image.targetCode1c, 'GLR0000123');
      expect(image.targetOrganizationId, 'org-A');
      expect(image.smallUrl, 'https://api.selup.uz/media/img/s/abc.webp');
      expect(image.mediumUrl, 'https://api.selup.uz/media/img/m/abc.webp');
      expect(image.largeUrl, 'https://api.selup.uz/media/img/l/abc.webp');
      expect(image.blurhash, 'L6PZfSi_.AyE_3t7t7R**0o#DgR4');
      expect(image.width, 3000);
      expect(image.height, 2000);
      expect(image.isPrimary, isTrue);
      expect(image.alt, 'Front view');
      expect(image.order, 0);
    });

    test('accepts the logical "product" target type as well', () {
      final image = NewBackendImageRepository.parseImageJson(
        <String, dynamic>{
          'id': 'id-1',
          'target': <String, dynamic>{
            'type': 'product',
            'id': 'p-uuid',
            'code_1c': 'P-1',
          },
          'small': 's',
        },
        'org',
      );
      expect(image?.targetType, ImageTargetType.product);
    });

    test('handles `customer` and `project` target types', () {
      final customer = NewBackendImageRepository.parseImageJson(
        <String, dynamic>{
          'id': 'id-1',
          'target': <String, dynamic>{
            'type': 'customer',
            'id': 'c-uuid',
            'code_1c': 'C-001',
          },
          'small': 's',
        },
        'org-B',
      );
      expect(customer?.targetType, ImageTargetType.customer);
      expect(customer?.targetCode1c, 'C-001');

      final project = NewBackendImageRepository.parseImageJson(
        <String, dynamic>{
          'id': 'id-2',
          'target': <String, dynamic>{
            'type': 'project',
            'id': 'p-uuid',
            'code_1c': 'PROJ-1',
          },
          'small': 's',
        },
        'org-B',
      );
      expect(project?.targetType, ImageTargetType.project);
      expect(project?.targetCode1c, 'PROJ-1');
    });

    test('returns null when id is missing or non-string', () {
      expect(
        NewBackendImageRepository.parseImageJson(
          <String, dynamic>{
            'target': <String, dynamic>{
              'type': 'product',
              'id': 'p',
              'code_1c': 'P-1',
            },
          },
          'org',
        ),
        isNull,
      );
      expect(
        NewBackendImageRepository.parseImageJson(
          <String, dynamic>{
            'id': 42,
            'target': <String, dynamic>{
              'type': 'product',
              'id': 'p',
              'code_1c': 'P-1',
            },
          },
          'org',
        ),
        isNull,
      );
    });

    test('returns null when target type is unknown', () {
      final image = NewBackendImageRepository.parseImageJson(
        <String, dynamic>{
          'id': 'id-1',
          'target': <String, dynamic>{
            'type': 'unicorn',
            'id': 'u-1',
            'code_1c': 'U-1',
          },
          'small': 's',
        },
        'org',
      );
      expect(image, isNull);
    });

    test('returns null when both target.id and target.code_1c are empty', () {
      final image = NewBackendImageRepository.parseImageJson(
        <String, dynamic>{
          'id': 'id-1',
          'target': <String, dynamic>{
            'type': 'product',
            'id': '',
            'code_1c': '',
          },
          'small': 's',
        },
        'org-A',
      );
      expect(image, isNull);
    });

    test('treats processing rows (null URLs) as having no variants', () {
      final image = NewBackendImageRepository.parseImageJson(
        <String, dynamic>{
          'id': 'id-1',
          'target': <String, dynamic>{
            'type': 'product',
            'id': 'p-1',
            'code_1c': 'P-1',
          },
          'small': null,
          'medium': null,
          'large': null,
          'blurhash': '',
          'is_primary': false,
        },
        'org',
      );
      expect(image, isNotNull);
      expect(image!.hasUrl, isFalse);
      expect(image.hasBlurhash, isFalse);
    });

    test('falls back to flat target_type / code_1c keys', () {
      final image = NewBackendImageRepository.parseImageJson(
        <String, dynamic>{
          'id': 'id-1',
          'target_type': 'product',
          'target_id': 'p-uuid',
          'code_1c': 'P-1',
          'small': 's',
        },
        'org',
      );
      expect(image, isNotNull);
      expect(image!.targetType, ImageTargetType.product);
      expect(image.targetId, 'p-uuid');
      expect(image.targetCode1c, 'P-1');
    });

    test('blurhash defaults to empty when missing', () {
      final image = NewBackendImageRepository.parseImageJson(
        <String, dynamic>{
          'id': 'id-1',
          'target': <String, dynamic>{
            'type': 'product',
            'id': 'p-1',
            'code_1c': 'P-1',
          },
          'small': 's',
        },
        'org',
      );
      expect(image?.blurhash, '');
    });

    test('order coerces num to int', () {
      final image = NewBackendImageRepository.parseImageJson(
        <String, dynamic>{
          'id': 'id-1',
          'target': <String, dynamic>{
            'type': 'product',
            'id': 'p-1',
            'code_1c': 'P-1',
          },
          'small': 's',
          'order': 5.0,
        },
        'org',
      );
      expect(image?.order, 5);
    });
  });
}
