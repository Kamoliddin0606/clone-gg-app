import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/unified_image.dart';

UnifiedImage _make({
  String? small,
  String? medium,
  String? large,
  String blurhash = '',
}) {
  return UnifiedImage(
    id: 'id',
    targetType: 'product',
    targetId: 'target-uuid',
    targetOrganizationId: 'org',
    targetCode1c: 'P-1',
    smallUrl: small,
    mediumUrl: medium,
    largeUrl: large,
    blurhash: blurhash,
    width: null,
    height: null,
    isPrimary: true,
    alt: '',
    order: 0,
  );
}

void main() {
  group('UnifiedImage.urlForSize', () {
    test('thumbnail prefers small, then medium, then large', () {
      expect(
        _make(small: 's', medium: 'm', large: 'l')
            .urlForSize(UnifiedImageSize.thumbnail),
        's',
      );
      expect(
        _make(medium: 'm', large: 'l').urlForSize(UnifiedImageSize.thumbnail),
        'm',
      );
      expect(
        _make(large: 'l').urlForSize(UnifiedImageSize.thumbnail),
        'l',
      );
    });

    test('small follows the same chain as thumbnail', () {
      expect(
        _make(small: 's', medium: 'm', large: 'l')
            .urlForSize(UnifiedImageSize.small),
        's',
      );
      expect(
        _make(large: 'l').urlForSize(UnifiedImageSize.small),
        'l',
      );
    });

    test('medium prefers medium, then small, then large', () {
      expect(
        _make(small: 's', medium: 'm', large: 'l')
            .urlForSize(UnifiedImageSize.medium),
        'm',
      );
      expect(
        _make(small: 's', large: 'l').urlForSize(UnifiedImageSize.medium),
        's',
      );
      expect(
        _make(large: 'l').urlForSize(UnifiedImageSize.medium),
        'l',
      );
    });

    test('large prefers large, then medium, then small', () {
      expect(
        _make(small: 's', medium: 'm', large: 'l')
            .urlForSize(UnifiedImageSize.large),
        'l',
      );
      expect(
        _make(small: 's', medium: 'm').urlForSize(UnifiedImageSize.large),
        'm',
      );
      expect(
        _make(small: 's').urlForSize(UnifiedImageSize.large),
        's',
      );
    });

    test('returns null when no variant is available', () {
      expect(_make().urlForSize(UnifiedImageSize.small), isNull);
      expect(_make().urlForSize(UnifiedImageSize.large), isNull);
    });
  });

  group('UnifiedImage state flags', () {
    test('hasUrl is true if any variant is set', () {
      expect(_make(small: 's').hasUrl, isTrue);
      expect(_make(large: 'l').hasUrl, isTrue);
      expect(_make().hasUrl, isFalse);
    });

    test('hasBlurhash distinguishes empty vs populated', () {
      expect(_make().hasBlurhash, isFalse);
      expect(_make(blurhash: 'L6PZ').hasBlurhash, isTrue);
    });
  });
}
