import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/visits/presentation/widgets/generic_schema_form/schema_validator.dart';

/// Schema validator is mobile's first line of defence — server-side
/// `jsonschema` is the canonical check. These cases cover the schemas
/// the catalog actually publishes today (surveys, audits, NPS).
void main() {
  group('SchemaValidator', () {
    test('passes a complete object', () {
      final errors = SchemaValidator.validate(
        {'product_code': 'P-1', 'facings': 4},
        {
          'type': 'object',
          'required': ['product_code'],
          'properties': {
            'product_code': {'type': 'string'},
            'facings': {'type': 'integer', 'minimum': 0},
          },
        },
      );
      expect(errors, isEmpty);
    });

    test('flags missing required field', () {
      final errors = SchemaValidator.validate(
        const {'facings': 4},
        {
          'type': 'object',
          'required': ['product_code'],
          'properties': {
            'product_code': {'type': 'string'},
          },
        },
      );
      expect(errors, containsPair('product_code', 'Majburiy maydon'));
    });

    test('flags out-of-range integer', () {
      final errors = SchemaValidator.validate(
        {'score': 11},
        {
          'type': 'object',
          'properties': {
            'score': {'type': 'integer', 'minimum': 1, 'maximum': 10},
          },
        },
      );
      expect(errors['score'], contains('Maksimum'));
    });

    test('flags string longer than maxLength', () {
      final errors = SchemaValidator.validate(
        {'note': 'a' * 300},
        {
          'type': 'object',
          'properties': {
            'note': {'type': 'string', 'maxLength': 200},
          },
        },
      );
      expect(errors['note'], contains('200 belgi'));
    });

    test('flags array shorter than minItems', () {
      final errors = SchemaValidator.validate(
        {
          'photo_asset_ids': ['a']
        },
        {
          'type': 'object',
          'properties': {
            'photo_asset_ids': {
              'type': 'array',
              'minItems': 2,
              'items': {'type': 'string'},
            },
          },
        },
      );
      expect(errors['photo_asset_ids'], contains('Kamida 2'));
    });

    test('flags enum mismatch', () {
      final errors = SchemaValidator.validate(
        {'payment_type': 'cheque'},
        {
          'type': 'object',
          'properties': {
            'payment_type': {
              'enum': ['cash', 'card'],
            },
          },
        },
      );
      expect(errors['payment_type'], isNotNull);
    });

    test('walks into array items', () {
      final errors = SchemaValidator.validate(
        {
          'rows': [
            {'amount': -3}
          ],
        },
        {
          'type': 'object',
          'properties': {
            'rows': {
              'type': 'array',
              'items': {
                'type': 'object',
                'required': ['amount'],
                'properties': {
                  'amount': {'type': 'integer', 'minimum': 0},
                },
              },
            },
          },
        },
      );
      expect(errors['rows[0].amount'], contains('Minimum'));
    });
  });
}
