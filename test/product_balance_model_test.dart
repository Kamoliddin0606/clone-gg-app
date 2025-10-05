import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_balance.dart';

void main() {
  group('ProductBalance Model Tests', () {
    const testProductBalance = ProductBalance(
      codeSklad: 'WH001',
      codeProduct: 'P001',
      nameProduct: 'Test Product',
      have: 100,
      reserved: 10,
      available: 90,
      weight: 1.5,
      capacity: 2.0,
      codeProject: 'PRJ001',
      vendorCode: 'V001',
      productBrand: 'Test Brand',
      productSeries: 'Test Series',
    );

    test('ProductBalance fromMap creates correct instance', () {
      final map = {
        'code_sklad': 'WH001',
        'code_product': 'P001',
        'name_product': 'Test Product',
        'have': 100,
        'reserved': 10,
        'available': 90,
        'weight': 1.5,
        'capacity': 2.0,
        'code_project': 'PRJ001',
        'vendor_code': 'V001',
        'product_brand': 'Test Brand',
        'product_series': 'Test Series',
        'created_at': '2023-01-01T00:00:00.000Z',
        'updated_at': '2023-01-01T00:00:00.000Z',
      };

      final result = ProductBalance.fromMap(map);

      expect(result.codeSklad, 'WH001');
      expect(result.codeProduct, 'P001');
      expect(result.nameProduct, 'Test Product');
      expect(result.have, 100);
      expect(result.reserved, 10);
      expect(result.available, 90);
      expect(result.weight, 1.5);
      expect(result.capacity, 2.0);
      expect(result.codeProject, 'PRJ001');
      expect(result.vendorCode, 'V001');
      expect(result.productBrand, 'Test Brand');
      expect(result.productSeries, 'Test Series');
      expect(result.createdAt, isNotNull);
      expect(result.updatedAt, isNotNull);
    });

    test('ProductBalance toMap returns correct map', () {
      final map = testProductBalance.toMap();

      expect(map['code_sklad'], 'WH001');
      expect(map['code_product'], 'P001');
      expect(map['name_product'], 'Test Product');
      expect(map['have'], 100);
      expect(map['reserved'], 10);
      expect(map['available'], 90);
      expect(map['weight'], 1.5);
      expect(map['capacity'], 2.0);
      expect(map['code_project'], 'PRJ001');
      expect(map['vendor_code'], 'V001');
      expect(map['product_brand'], 'Test Brand');
      expect(map['product_series'], 'Test Series');
    });

    test('ProductBalance copyWith returns correct copy', () {
      final copy = testProductBalance.copyWith(
        have: 200,
        nameProduct: 'Updated Product',
      );

      expect(copy.codeSklad, 'WH001'); // unchanged
      expect(copy.have, 200); // changed
      expect(copy.nameProduct, 'Updated Product'); // changed
      expect(copy.reserved, 10); // unchanged
    });

    test('ProductBalance equality works correctly', () {
      const balance1 = ProductBalance(
        codeSklad: 'WH001',
        codeProduct: 'P001',
        nameProduct: 'Test Product',
        have: 100,
        reserved: 10,
        available: 90,
        weight: 1.5,
        capacity: 2.0,
        codeProject: 'PRJ001',
        vendorCode: 'V001',
        productBrand: 'Test Brand',
        productSeries: 'Test Series',
      );

      const balance2 = ProductBalance(
        codeSklad: 'WH001',
        codeProduct: 'P001',
        nameProduct: 'Test Product',
        have: 100,
        reserved: 10,
        available: 90,
        weight: 1.5,
        capacity: 2.0,
        codeProject: 'PRJ001',
        vendorCode: 'V001',
        productBrand: 'Test Brand',
        productSeries: 'Test Series',
      );

      const balance3 = ProductBalance(
        codeSklad: 'WH002',
        codeProduct: 'P001',
        nameProduct: 'Test Product',
        have: 100,
        reserved: 10,
        available: 90,
        weight: 1.5,
        capacity: 2.0,
        codeProject: 'PRJ001',
        vendorCode: 'V001',
        productBrand: 'Test Brand',
        productSeries: 'Test Series',
      );

      expect(balance1 == balance2, true);
      expect(balance1 == balance3, false);
      expect(balance1.hashCode == balance2.hashCode, true);
      expect(balance1.hashCode == balance3.hashCode, false);
    });

    test('ProductBalance toString returns correct string', () {
      final result = testProductBalance.toString();
      expect(result, contains('ProductBalance'));
      expect(result, contains('codeSklad: WH001'));
      expect(result, contains('codeProduct: P001'));
      expect(result, contains('nameProduct: Test Product'));
    });
  });
}