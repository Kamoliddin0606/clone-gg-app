import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/services/thumbnail_image_service.dart';

void main() {
  group('ThumbnailImageService Edge Cases and Integration Tests', () {

    test('should handle ClientImage model edge cases', () {
      // Test with null values
      final clientImage = ClientImage(
        clientCode: 'test-client',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        // All other fields null
      );

      // Act
      final map = clientImage.toMap();
      final reconstructed = ClientImage.fromMap(map);

      // Assert
      expect(reconstructed.clientCode, equals('test-client'));
      expect(reconstructed.imageUrl, isNull);
      expect(reconstructed.isMain, isFalse);
    });

    test('should handle ClientImage with all fields populated', () {
      // Arrange
      final now = DateTime.now();
      final clientImage = ClientImage(
        id: 1,
        clientCode: 'test-client',
        imageUrl: 'http://example.com/image.jpg',
        imageSmUrl: 'http://example.com/image_sm.jpg',
        imageMdUrl: 'http://example.com/image_md.jpg',
        imageLgUrl: 'http://example.com/image_lg.jpg',
        imageThumbnailUrl: 'http://example.com/thumbnail.jpg',
        imageDimensions: '1920x1080',
        imageSmDimensions: '800x600',
        imageMdDimensions: '1200x900',
        imageLgDimensions: '2400x1800',
        imageThumbnailDimensions: '200x150',
        isMain: true,
        category: 'product',
        note: 'Test note',
        statusCode: 'active',
        statusName: 'Active',
        sourceName: 'upload',
        sourceType: 'manual',
        createdAtServer: '2023-01-01T00:00:00Z',
        createdAt: now,
        updatedAt: now,
      );

      // Act
      final map = clientImage.toMap();
      final reconstructed = ClientImage.fromMap(map);

      // Assert
      expect(reconstructed.id, equals(1));
      expect(reconstructed.clientCode, equals('test-client'));
      expect(reconstructed.imageUrl, equals('http://example.com/image.jpg'));
      expect(reconstructed.isMain, isTrue);
      expect(reconstructed.category, equals('product'));
      expect(reconstructed.statusCode, equals('active'));
    });

    test('should handle malformed map data gracefully', () {
      // Arrange - Map with missing required fields
      final incompleteMap = {
        'client_code': 'test-client',
        // Missing created_at and updated_at
      };

      // Act & Assert - Should throw due to missing required fields
      expect(
        () => ClientImage.fromMap(incompleteMap),
        throwsA(isA<TypeError>()),
      );
    });

    test('should handle empty string values', () {
      // Arrange
      final mapWithEmptyStrings = {
        'id': 1,
        'client_code': 'test-client',
        'image_url': '',
        'is_main': 0,
        'created_at': '2023-01-01T00:00:00.000Z',
        'updated_at': '2023-01-01T00:00:00.000Z',
      };

      // Act
      final clientImage = ClientImage.fromMap(mapWithEmptyStrings);

      // Assert
      expect(clientImage.imageUrl, equals(''));
      expect(clientImage.isMain, isFalse);
    });

    test('should handle boolean conversion correctly', () {
      // Test true case
      final mapTrue = {
        'id': 1,
        'client_code': 'test-client',
        'is_main': 1,
        'created_at': '2023-01-01T00:00:00.000Z',
        'updated_at': '2023-01-01T00:00:00.000Z',
      };

      final clientImageTrue = ClientImage.fromMap(mapTrue);
      expect(clientImageTrue.isMain, isTrue);

      // Test false case
      final mapFalse = {
        'id': 1,
        'client_code': 'test-client',
        'is_main': 0,
        'created_at': '2023-01-01T00:00:00.000Z',
        'updated_at': '2023-01-01T00:00:00.000Z',
      };

      final clientImageFalse = ClientImage.fromMap(mapFalse);
      expect(clientImageFalse.isMain, isFalse);
    });
  });
}