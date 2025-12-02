import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/Utility/formatter.dart';

void main() {
  group('formatDistance', () {
    test('should return empty string for null distance', () {
      expect(formatDistance(null), '');
    });

    test('should format distances less than 1km in meters', () {
      expect(formatDistance(0.9), '900m');
      expect(formatDistance(0.5), '500m');
      expect(formatDistance(0.1), '100m');
      expect(formatDistance(0.05), '50m');
      expect(formatDistance(0.999), '999m');
    });

    test('should format distances greater than or equal to 1km in kilometers', () {
      expect(formatDistance(1.0), '1.0km');
      expect(formatDistance(1.5), '1.5km');
      expect(formatDistance(2.0), '2.0km');
      expect(formatDistance(10.0), '10.0km');
      expect(formatDistance(15.7), '15.7km');
    });

    test('should handle edge cases', () {
      expect(formatDistance(0.0), '0m');
      expect(formatDistance(0.001), '1m');
      expect(formatDistance(0.9999), '1000m'); // Rounds up
    });
  });
}