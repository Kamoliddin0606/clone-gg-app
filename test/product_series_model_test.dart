import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_series.dart';

void main() {
  group('ProductSeries Model Tests', () {
    const testProductSeries = ProductSeries(
      name: 'Test Series',
      brandName: 'Test Brand',
    );

    test('ProductSeries fromMap creates correct instance', () {
      final map = {
        'name': 'Test Series',
        'brand_name': 'Test Brand',
        'created_at': '2023-01-01T00:00:00.000Z',
        'updated_at': '2023-01-01T00:00:00.000Z',
      };

      final result = ProductSeries.fromMap(map);

      expect(result.name, 'Test Series');
      expect(result.brandName, 'Test Brand');
      expect(result.createdAt, isNotNull);
      expect(result.updatedAt, isNotNull);
    });

    test('ProductSeries toMap returns correct map', () {
      final map = testProductSeries.toMap();

      expect(map['name'], 'Test Series');
      expect(map['brand_name'], 'Test Brand');
    });

    test('ProductSeries copyWith returns correct copy', () {
      final copy = testProductSeries.copyWith(
        name: 'Updated Series',
        brandName: 'Updated Brand',
      );

      expect(copy.name, 'Updated Series');
      expect(copy.brandName, 'Updated Brand');
    });

    test('ProductSeries equality works correctly', () {
      const series1 = ProductSeries(
        name: 'Test Series',
        brandName: 'Test Brand',
      );
      const series2 = ProductSeries(
        name: 'Test Series',
        brandName: 'Test Brand',
      );
      const series3 = ProductSeries(
        name: 'Different Series',
        brandName: 'Test Brand',
      );
      const series4 = ProductSeries(
        name: 'Test Series',
        brandName: 'Different Brand',
      );

      expect(series1 == series2, true);
      expect(series1 == series3, false);
      expect(series1 == series4, false);
      expect(series1.hashCode == series2.hashCode, true);
      expect(series1.hashCode == series3.hashCode, false);
    });

    test('ProductSeries toString returns correct string', () {
      final result = testProductSeries.toString();
      expect(result, contains('ProductSeries'));
      expect(result, contains('name: Test Series'));
      expect(result, contains('brandName: Test Brand'));
    });
  });
}