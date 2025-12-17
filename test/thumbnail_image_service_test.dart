import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/services/thumbnail_image_service.dart';

void main() {
  group('ThumbnailImageService', () {
    test('should create ClientImage from map', () {
      // Arrange
      final map = {
        'id': 1,
        'client_code': 'test-client',
        'image_url': 'http://example.com/image.jpg',
        'is_main': 1,
        'created_at': '2023-01-01T00:00:00.000Z',
        'updated_at': '2023-01-01T00:00:00.000Z',
      };

      // Act
      final clientImage = ClientImage.fromMap(map);

      // Assert
      expect(clientImage.id, equals(1));
      expect(clientImage.clientCode, equals('test-client'));
      expect(clientImage.imageUrl, equals('http://example.com/image.jpg'));
      expect(clientImage.isMain, isTrue);
    });

    test('should convert ClientImage to map', () {
      // Arrange
      final clientImage = ClientImage(
        id: 1,
        clientCode: 'test-client',
        imageUrl: 'http://example.com/image.jpg',
        isMain: true,
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
      );

      // Act
      final map = clientImage.toMap();

      // Assert
      expect(map['id'], equals(1));
      expect(map['client_code'], equals('test-client'));
      expect(map['image_url'], equals('http://example.com/image.jpg'));
      expect(map['is_main'], equals(1));
    });

    test('should handle null values in ClientImage', () {
      // Arrange
      final map = {
        'id': null,
        'client_code': 'test-client',
        'image_url': null,
        'is_main': 0,
        'created_at': '2023-01-01T00:00:00.000Z',
        'updated_at': '2023-01-01T00:00:00.000Z',
      };

      // Act
      final clientImage = ClientImage.fromMap(map);

      // Assert
      expect(clientImage.id, isNull);
      expect(clientImage.clientCode, equals('test-client'));
      expect(clientImage.imageUrl, isNull);
      expect(clientImage.isMain, isFalse);
    });

    test('should create ClientImage with minimal required fields', () {
      // Test with only required fields
      final minimalMap = {
        'client_code': 'test-client',
        'created_at': '2023-01-01T00:00:00.000Z',
        'updated_at': '2023-01-01T00:00:00.000Z',
      };

      final clientImage = ClientImage.fromMap(minimalMap);
      expect(clientImage.clientCode, equals('test-client'));
      expect(clientImage.isMain, isFalse); // Default value
      expect(clientImage.imageUrl, isNull);
      expect(clientImage.id, isNull);
    });
  });
}