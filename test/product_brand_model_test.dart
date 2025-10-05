import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_brand.dart';

void main() {
  group('ProductBrand Model Tests', () {
    const testProductBrand = ProductBrand(
      name: 'Test Brand',
    );

    test('ProductBrand fromMap creates correct instance', () {
      final map = {
        'name': 'Test Brand',
        'created_at': '2023-01-01T00:00:00.000Z',
        'updated_at': '2023-01-01T00:00:00.000Z',
      };

      final result = ProductBrand.fromMap(map);

      expect(result.name, 'Test Brand');
      expect(result.createdAt, isNotNull);
      expect(result.updatedAt, isNotNull);
    });

    test('ProductBrand toMap returns correct map', () {
      final map = testProductBrand.toMap();

      expect(map['name'], 'Test Brand');
    });

    test('ProductBrand copyWith returns correct copy', () {
      final copy = testProductBrand.copyWith(
        name: 'Updated Brand',
      );

      expect(copy.name, 'Updated Brand');
    });

    test('ProductBrand equality works correctly', () {
      const brand1 = ProductBrand(name: 'Test Brand');
      const brand2 = ProductBrand(name: 'Test Brand');
      const brand3 = ProductBrand(name: 'Different Brand');

      expect(brand1 == brand2, true);
      expect(brand1 == brand3, false);
      expect(brand1.hashCode == brand2.hashCode, true);
      expect(brand1.hashCode == brand3.hashCode, false);
    });

    test('ProductBrand toString returns correct string', () {
      final result = testProductBrand.toString();
      expect(result, contains('ProductBrand'));
      expect(result, contains('name: Test Brand'));
    });
  });
}