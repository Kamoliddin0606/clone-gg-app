import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/services/thumbnail_image_service.dart';

void main() {
  group('ThumbnailImageService', () {
    test('should create ClientImage from map', () {
      // Arrange
      final map = {
        'id': 1,
        'server_id': 116,
        'client_code': 'test-client',
        'client_id': 31866,
        'image': 'http://example.com/original.jpg',
        'image_url': 'http://example.com/image.jpg',
        'is_main': 1,
        'status': null,
        'source': null,
        'created_at_server': '2025-12-17T13:55:24.203699+05:00',
        'created_at': '2023-01-01T00:00:00.000Z',
        'updated_at': '2023-01-01T00:00:00.000Z',
      };

      // Act
      final clientImage = ClientImage.fromMap(map);

      // Assert
      expect(clientImage.id, equals(1));
      expect(clientImage.serverId, equals(116));
      expect(clientImage.clientCode, equals('test-client'));
      expect(clientImage.clientId, equals(31866));
      expect(clientImage.image, equals('http://example.com/original.jpg'));
      expect(clientImage.imageUrl, equals('http://example.com/image.jpg'));
      expect(clientImage.isMain, isTrue);
      expect(clientImage.createdAtServer, equals('2025-12-17T13:55:24.203699+05:00'));
    });

    test('should convert ClientImage to map', () {
      // Arrange
      final clientImage = ClientImage(
        id: 1,
        serverId: 116,
        clientCode: 'test-client',
        clientId: 31866,
        image: 'http://example.com/original.jpg',
        imageUrl: 'http://example.com/image.jpg',
        isMain: true,
        status: null,
        source: null,
        createdAtServer: '2025-12-17T13:55:24.203699+05:00',
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
      );

      // Act
      final map = clientImage.toMap();

      // Assert
      expect(map['id'], equals(1));
      expect(map['server_id'], equals(116));
      expect(map['client_code'], equals('test-client'));
      expect(map['client_id'], equals(31866));
      expect(map['image'], equals('http://example.com/original.jpg'));
      expect(map['image_url'], equals('http://example.com/image.jpg'));
      expect(map['is_main'], equals(1));
      expect(map['created_at_server'], equals('2025-12-17T13:55:24.203699+05:00'));
    });

    test('should handle null values in ClientImage', () {
      // Arrange
      final map = {
        'id': null,
        'server_id': null,
        'client_code': 'test-client',
        'client_id': null,
        'image': null,
        'image_url': null,
        'is_main': 0,
        'status': null,
        'source': null,
        'created_at_server': null,
        'created_at': '2023-01-01T00:00:00.000Z',
        'updated_at': '2023-01-01T00:00:00.000Z',
      };

      // Act
      final clientImage = ClientImage.fromMap(map);

      // Assert
      expect(clientImage.id, isNull);
      expect(clientImage.serverId, isNull);
      expect(clientImage.clientCode, equals('test-client'));
      expect(clientImage.clientId, isNull);
      expect(clientImage.image, isNull);
      expect(clientImage.imageUrl, isNull);
      expect(clientImage.isMain, isFalse);
      expect(clientImage.createdAtServer, isNull);
    });

    test('should create ClientImage with minimal required fields', () {
      // Test with only required fields
      final minimalMap = {
        'client_code': 'test-client',
        'created_at_server': null,
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