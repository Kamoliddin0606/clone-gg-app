import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/utils/version_utils.dart';

void main() {
  group('VersionUtils.toThreeDigitFormat', () {
    group('Standard versions (single digit components)', () {
      test('converts 1.0.1 to 101', () {
        expect(VersionUtils.toThreeDigitFormat('1.0.1'), '101');
      });

      test('converts 2.5.3 to 253', () {
        expect(VersionUtils.toThreeDigitFormat('2.5.3'), '253');
      });

      test('converts 9.9.9 to 999', () {
        expect(VersionUtils.toThreeDigitFormat('9.9.9'), '999');
      });

      test('converts 0.0.0 to 000', () {
        expect(VersionUtils.toThreeDigitFormat('0.0.0'), '000');
      });
    });

    group('Versions with build numbers', () {
      test('ignores build number in 1.0.0+2', () {
        expect(VersionUtils.toThreeDigitFormat('1.0.0+2'), '100');
      });

      test('ignores build number in 2.3.4+15', () {
        expect(VersionUtils.toThreeDigitFormat('2.3.4+15'), '234');
      });
    });

    group('Double-digit version components', () {
      test('takes first digit from 10.2.5 → 125', () {
        expect(VersionUtils.toThreeDigitFormat('10.2.5'), '125');
      });

      test('takes first digit from 2.15.3 → 213', () {
        expect(VersionUtils.toThreeDigitFormat('2.15.3'), '213');
      });

      test('takes first digit from 123.456.789 → 147', () {
        expect(VersionUtils.toThreeDigitFormat('123.456.789'), '147');
      });

      test('handles 10.0.0 → 100', () {
        expect(VersionUtils.toThreeDigitFormat('10.0.0'), '100');
      });
    });

    group('Incomplete versions (padding with zeros)', () {
      test('pads 1.0 with zero → 100', () {
        expect(VersionUtils.toThreeDigitFormat('1.0'), '100');
      });

      test('pads 2 with zeros → 200', () {
        expect(VersionUtils.toThreeDigitFormat('2'), '200');
      });

      test('pads 3.5 with zero → 350', () {
        expect(VersionUtils.toThreeDigitFormat('3.5'), '350');
      });
    });

    group('Invalid formats', () {
      test('throws FormatException for empty string', () {
        expect(
          () => VersionUtils.toThreeDigitFormat(''),
          throwsFormatException,
        );
      });

      test('throws FormatException for non-numeric version', () {
        expect(
          () => VersionUtils.toThreeDigitFormat('abc'),
          throwsFormatException,
        );
      });

      test('throws FormatException for version with letters', () {
        expect(
          () => VersionUtils.toThreeDigitFormat('1.a.2'),
          throwsFormatException,
        );
      });

      test('throws FormatException for negative numbers', () {
        expect(
          () => VersionUtils.toThreeDigitFormat('-1.0.0'),
          throwsFormatException,
        );
      });
    });

    group('Edge cases', () {
      test('handles version with trailing dot', () {
        expect(VersionUtils.toThreeDigitFormat('1.0.'), '100');
      });

      test('handles version with multiple dots', () {
        // Only takes first 3 components
        expect(VersionUtils.toThreeDigitFormat('1.2.3.4.5'), '123');
      });
    });
  });

  group('VersionUtils.isValidVersion', () {
    test('returns true for valid versions', () {
      expect(VersionUtils.isValidVersion('1.0.1'), isTrue);
      expect(VersionUtils.isValidVersion('10.2.5'), isTrue);
      expect(VersionUtils.isValidVersion('1.0.0+2'), isTrue);
    });

    test('returns false for invalid versions', () {
      expect(VersionUtils.isValidVersion(''), isFalse);
      expect(VersionUtils.isValidVersion('abc'), isFalse);
      expect(VersionUtils.isValidVersion('1.a.2'), isFalse);
      expect(VersionUtils.isValidVersion('-1.0.0'), isFalse);
    });
  });
}
