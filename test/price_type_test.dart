import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/price_type.dart';

void main() {
  group('PriceType', () {
    test('should create PriceType with valid data', () {
      final priceType = PriceType(
        code: 'PT001',
        name: 'Standard Price',
        description: 'Standard pricing type',
        isDefault: true,
      );

      expect(priceType.code, 'PT001');
      expect(priceType.name, 'Standard Price');
      expect(priceType.description, 'Standard pricing type');
      expect(priceType.isDefault, true);
    });

    test('should create PriceType from valid JSON', () {
      final json = {
        'code': 'PT001',
        'name': 'Standard Price',
        'description': 'Standard pricing type',
        'isDefault': true,
      };

      final priceType = PriceType.fromJson(json);

      expect(priceType.code, 'PT001');
      expect(priceType.name, 'Standard Price');
      expect(priceType.description, 'Standard pricing type');
      expect(priceType.isDefault, true);
    });

    test('should throw ArgumentError when code is empty', () {
      final json = {
        'code': '',
        'name': 'Standard Price',
        'description': 'Standard pricing type',
        'isDefault': true,
      };

      expect(() => PriceType.fromJson(json), throwsArgumentError);
    });

    test('should throw ArgumentError when name is empty', () {
      final json = {
        'code': 'PT001',
        'name': '',
        'description': 'Standard pricing type',
        'isDefault': true,
      };

      expect(() => PriceType.fromJson(json), throwsArgumentError);
    });

    test('should handle null values in JSON', () {
      final json = {
        'code': 'PT001',
        'name': 'Standard Price',
        'description': null,
        'isDefault': null,
      };

      final priceType = PriceType.fromJson(json);

      expect(priceType.code, 'PT001');
      expect(priceType.name, 'Standard Price');
      expect(priceType.description, '');
      expect(priceType.isDefault, false);
    });

    test('should convert to JSON correctly', () {
      final priceType = PriceType(
        code: 'PT001',
        name: 'Standard Price',
        description: 'Standard pricing type',
        isDefault: true,
      );

      final json = priceType.toJson();

      expect(json['code'], 'PT001');
      expect(json['name'], 'Standard Price');
      expect(json['description'], 'Standard pricing type');
      expect(json['isDefault'], true);
    });

    test('should create copy with modified values', () {
      final original = PriceType(
        code: 'PT001',
        name: 'Standard Price',
        description: 'Standard pricing type',
        isDefault: true,
      );

      final copy = original.copyWith(
        name: 'Modified Price',
        isDefault: false,
      );

      expect(copy.code, 'PT001');
      expect(copy.name, 'Modified Price');
      expect(copy.description, 'Standard pricing type');
      expect(copy.isDefault, false);
    });

    test('should compare equality correctly', () {
      final priceType1 = PriceType(
        code: 'PT001',
        name: 'Standard Price',
        description: 'Standard pricing type',
        isDefault: true,
      );

      final priceType2 = PriceType(
        code: 'PT001',
        name: 'Standard Price',
        description: 'Standard pricing type',
        isDefault: true,
      );

      final priceType3 = PriceType(
        code: 'PT002',
        name: 'Standard Price',
        description: 'Standard pricing type',
        isDefault: true,
      );

      expect(priceType1 == priceType2, true);
      expect(priceType1 == priceType3, false);
    });

    test('should generate correct hashCode', () {
      final priceType1 = PriceType(
        code: 'PT001',
        name: 'Standard Price',
        description: 'Standard pricing type',
        isDefault: true,
      );

      final priceType2 = PriceType(
        code: 'PT001',
        name: 'Standard Price',
        description: 'Standard pricing type',
        isDefault: true,
      );

      expect(priceType1.hashCode == priceType2.hashCode, true);
    });

    test('should generate correct toString', () {
      final priceType = PriceType(
        code: 'PT001',
        name: 'Standard Price',
        description: 'Standard pricing type',
        isDefault: true,
      );

      final string = priceType.toString();
      expect(string.contains('PT001'), true);
      expect(string.contains('Standard Price'), true);
      expect(string.contains('Standard pricing type'), true);
      expect(string.contains('true'), true);
    });
  });
}