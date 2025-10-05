import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_price.dart';

void main() {
  group('ProductPrice', () {
    test('should create ProductPrice with valid data', () {
      final productPrice = ProductPrice(
        productCode: 'P001',
        priceTypeCode: 'PT001',
        price: 100.0,
        currency: 'UZS',
        validFrom: '2024-01-01',
        validTo: '2024-12-31',
      );

      expect(productPrice.productCode, 'P001');
      expect(productPrice.priceTypeCode, 'PT001');
      expect(productPrice.price, 100.0);
      expect(productPrice.currency, 'UZS');
      expect(productPrice.validFrom, '2024-01-01');
      expect(productPrice.validTo, '2024-12-31');
    });

    test('should create ProductPrice from valid JSON', () {
      final json = {
        'productCode': 'P001',
        'priceTypeCode': 'PT001',
        'price': 100.0,
        'currency': 'UZS',
        'validFrom': '2024-01-01',
        'validTo': '2024-12-31',
      };

      final productPrice = ProductPrice.fromJson(json);

      expect(productPrice.productCode, 'P001');
      expect(productPrice.priceTypeCode, 'PT001');
      expect(productPrice.price, 100.0);
      expect(productPrice.currency, 'UZS');
      expect(productPrice.validFrom, '2024-01-01');
      expect(productPrice.validTo, '2024-12-31');
    });

    test('should throw ArgumentError when productCode is empty', () {
      final json = {
        'productCode': '',
        'priceTypeCode': 'PT001',
        'price': 100.0,
        'currency': 'UZS',
      };

      expect(() => ProductPrice.fromJson(json), throwsArgumentError);
    });

    test('should throw ArgumentError when priceTypeCode is empty', () {
      final json = {
        'productCode': 'P001',
        'priceTypeCode': '',
        'price': 100.0,
        'currency': 'UZS',
      };

      expect(() => ProductPrice.fromJson(json), throwsArgumentError);
    });

    test('should throw ArgumentError when price is negative', () {
      final json = {
        'productCode': 'P001',
        'priceTypeCode': 'PT001',
        'price': -100.0,
        'currency': 'UZS',
      };

      expect(() => ProductPrice.fromJson(json), throwsArgumentError);
    });

    test('should handle null values in JSON', () {
      final json = {
        'productCode': 'P001',
        'priceTypeCode': 'PT001',
        'price': 100.0,
        'currency': null,
        'validFrom': null,
        'validTo': null,
      };

      final productPrice = ProductPrice.fromJson(json);

      expect(productPrice.productCode, 'P001');
      expect(productPrice.priceTypeCode, 'PT001');
      expect(productPrice.price, 100.0);
      expect(productPrice.currency, 'UZS');
      expect(productPrice.validFrom, '');
      expect(productPrice.validTo, '');
    });

    test('should convert to JSON correctly', () {
      final productPrice = ProductPrice(
        productCode: 'P001',
        priceTypeCode: 'PT001',
        price: 100.0,
        currency: 'UZS',
        validFrom: '2024-01-01',
        validTo: '2024-12-31',
      );

      final json = productPrice.toJson();

      expect(json['productCode'], 'P001');
      expect(json['priceTypeCode'], 'PT001');
      expect(json['price'], 100.0);
      expect(json['currency'], 'UZS');
      expect(json['validFrom'], '2024-01-01');
      expect(json['validTo'], '2024-12-31');
    });

    test('should create copy with modified values', () {
      final original = ProductPrice(
        productCode: 'P001',
        priceTypeCode: 'PT001',
        price: 100.0,
        currency: 'UZS',
        validFrom: '2024-01-01',
        validTo: '2024-12-31',
      );

      final copy = original.copyWith(
        price: 150.0,
        currency: 'USD',
      );

      expect(copy.productCode, 'P001');
      expect(copy.priceTypeCode, 'PT001');
      expect(copy.price, 150.0);
      expect(copy.currency, 'USD');
      expect(copy.validFrom, '2024-01-01');
      expect(copy.validTo, '2024-12-31');
    });

    test('should compare equality correctly', () {
      final productPrice1 = ProductPrice(
        productCode: 'P001',
        priceTypeCode: 'PT001',
        price: 100.0,
        currency: 'UZS',
        validFrom: '2024-01-01',
        validTo: '2024-12-31',
      );

      final productPrice2 = ProductPrice(
        productCode: 'P001',
        priceTypeCode: 'PT001',
        price: 100.0,
        currency: 'UZS',
        validFrom: '2024-01-01',
        validTo: '2024-12-31',
      );

      final productPrice3 = ProductPrice(
        productCode: 'P002',
        priceTypeCode: 'PT001',
        price: 100.0,
        currency: 'UZS',
        validFrom: '2024-01-01',
        validTo: '2024-12-31',
      );

      expect(productPrice1 == productPrice2, true);
      expect(productPrice1 == productPrice3, false);
    });

    test('should generate correct hashCode', () {
      final productPrice1 = ProductPrice(
        productCode: 'P001',
        priceTypeCode: 'PT001',
        price: 100.0,
        currency: 'UZS',
        validFrom: '2024-01-01',
        validTo: '2024-12-31',
      );

      final productPrice2 = ProductPrice(
        productCode: 'P001',
        priceTypeCode: 'PT001',
        price: 100.0,
        currency: 'UZS',
        validFrom: '2024-01-01',
        validTo: '2024-12-31',
      );

      expect(productPrice1.hashCode == productPrice2.hashCode, true);
    });

    test('should generate correct toString', () {
      final productPrice = ProductPrice(
        productCode: 'P001',
        priceTypeCode: 'PT001',
        price: 100.0,
        currency: 'UZS',
        validFrom: '2024-01-01',
        validTo: '2024-12-31',
      );

      final string = productPrice.toString();
      expect(string.contains('P001'), true);
      expect(string.contains('PT001'), true);
      expect(string.contains('100.0'), true);
      expect(string.contains('UZS'), true);
      expect(string.contains('2024-01-01'), true);
      expect(string.contains('2024-12-31'), true);
    });
  });
}