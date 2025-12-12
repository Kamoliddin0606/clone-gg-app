import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';
import 'package:gloria_marketing_flutter/src/core/services/rest_api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/thumbnail.dart';

// Mock classes
class MockApiDatabaseService extends Mock implements ApiDatabaseService {}

void main() {
  late RestApiDatabaseService restApiDatabaseService;
  late MockApiDatabaseService mockApiDatabaseService;

  setUp(() {
    mockApiDatabaseService = MockApiDatabaseService();
    restApiDatabaseService = RestApiDatabaseService(mockApiDatabaseService);
  });

  group('RestApiDatabaseService Tests', () {
    group('saveThumbnails', () {
      test('successfully saves thumbnails to database', () async {
        // Arrange
        final thumbnails = [
          Thumbnail(
            entityType: 'nomenklatura',
            entityId: 843,
            code1c: '00-00001559',
            entityName: 'Test Product',
            imageId: 35,
            thumbnailUrl: 'http://example.com/image.jpg',
            thumbnailDimensions: '{"width": 150, "height": 150}',
            originalDimensions: '{"width": 432, "height": 376}',
            isMain: true,
            category: null,
            note: null,
            statusCode: 'product_main',
            statusName: 'Main Product Image',
            sourceName: 'Admin',
            sourceType: 'admin',
            createdAt: '2025-12-05T11:09:29.544560+05:00',
          ),
          Thumbnail(
            entityType: 'client',
            entityId: 123,
            code1c: 'CLIENT001',
            entityName: 'Test Client',
            imageId: 36,
            thumbnailUrl: 'http://example.com/client.jpg',
            thumbnailDimensions: '{"width": 150, "height": 150}',
            originalDimensions: '{"width": 300, "height": 300}',
            isMain: true,
            category: null,
            note: null,
            statusCode: 'client_main',
            statusName: 'Main Client Image',
            sourceName: 'Admin',
            sourceType: 'admin',
            createdAt: '2025-12-05T12:00:00.000000+05:00',
          ),
        ];

        when(mockDatabase.transaction(any))
            .thenAnswer((invocation) async {
          final transactionFunction = invocation.positionalArguments[0] as Function;
          final transaction = MockDatabase();
          when(transaction.insert(any, any, conflictAlgorithm: anyNamed('conflictAlgorithm')))
              .thenAnswer((_) async => 1);
          return await transactionFunction(transaction);
        });

        // Act
        await restApiDatabaseService.saveThumbnails(thumbnails);

        // Assert
        verify(mockDatabase.transaction(any)).called(1);
      });

      test('handles empty thumbnail list', () async {
        // Arrange
        final thumbnails = <Thumbnail>[];

        // Act
        await restApiDatabaseService.saveThumbnails(thumbnails);

        // Assert
        verifyNever(mockDatabase.transaction(any));
      });

      test('handles database errors gracefully', () async {
        // Arrange
        final thumbnails = [
          Thumbnail(
            entityType: 'nomenklatura',
            entityId: 843,
            code1c: '00-00001559',
            entityName: 'Test Product',
            imageId: 35,
            thumbnailUrl: 'http://example.com/image.jpg',
            thumbnailDimensions: '{"width": 150, "height": 150}',
            originalDimensions: '{"width": 432, "height": 376}',
            isMain: true,
            category: null,
            note: null,
            statusCode: 'product_main',
            statusName: 'Main Product Image',
            sourceName: 'Admin',
            sourceType: 'admin',
            createdAt: '2025-12-05T11:09:29.544560+05:00',
          ),
        ];

        when(mockDatabase.transaction(any))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => restApiDatabaseService.saveThumbnails(thumbnails),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('convertThumbnailToMap', () {
      test('converts thumbnail to database map correctly', () {
        // Arrange
        final thumbnail = Thumbnail(
          entityType: 'nomenklatura',
          entityId: 843,
          code1c: '00-00001559',
          entityName: 'Test Product',
          imageId: 35,
          thumbnailUrl: 'http://example.com/image.jpg',
          thumbnailDimensions: '{"width": 150, "height": 150}',
          originalDimensions: '{"width": 432, "height": 376}',
          isMain: true,
          category: 'Test Category',
          note: 'Test Note',
          statusCode: 'product_main',
          statusName: 'Main Product Image',
          sourceName: 'Admin',
          sourceType: 'admin',
          createdAt: '2025-12-05T11:09:29.544560+05:00',
        );

        // Act
        final result = restApiDatabaseService.convertThumbnailToMap(thumbnail);

        // Assert
        expect(result['entity_type'], 'nomenklatura');
        expect(result['entity_id'], 843);
        expect(result['code_1c'], '00-00001559');
        expect(result['entity_name'], 'Test Product');
        expect(result['image_id'], 35);
        expect(result['thumbnail_url'], 'http://example.com/image.jpg');
        expect(result['thumbnail_dimensions'], '{"width": 150, "height": 150}');
        expect(result['original_dimensions'], '{"width": 432, "height": 376}');
        expect(result['is_main'], 1);
        expect(result['category'], 'Test Category');
        expect(result['note'], 'Test Note');
        expect(result['status_code'], 'product_main');
        expect(result['status_name'], 'Main Product Image');
        expect(result['source_name'], 'Admin');
        expect(result['source_type'], 'admin');
        expect(result['created_at'], '2025-12-05T11:09:29.544560+05:00');
        expect(result.containsKey('updated_at'), isTrue);
      });

      test('handles null values correctly', () {
        // Arrange
        final thumbnail = Thumbnail(
          entityType: 'client',
          entityId: 123,
          code1c: 'CLIENT001',
          entityName: 'Test Client',
          imageId: null,
          thumbnailUrl: null,
          thumbnailDimensions: null,
          originalDimensions: null,
          isMain: false,
          category: null,
          note: null,
          statusCode: null,
          statusName: null,
          sourceName: null,
          sourceType: null,
          createdAt: null,
        );

        // Act
        final result = restApiDatabaseService.convertThumbnailToMap(thumbnail);

        // Assert
        expect(result['entity_type'], 'client');
        expect(result['entity_id'], 123);
        expect(result['code_1c'], 'CLIENT001');
        expect(result['entity_name'], 'Test Client');
        expect(result['image_id'], isNull);
        expect(result['thumbnail_url'], isNull);
        expect(result['thumbnail_dimensions'], isNull);
        expect(result['original_dimensions'], isNull);
        expect(result['is_main'], 0);
        expect(result['category'], isNull);
        expect(result['note'], isNull);
        expect(result['status_code'], isNull);
        expect(result['status_name'], isNull);
        expect(result['source_name'], isNull);
        expect(result['source_type'], isNull);
        expect(result['created_at'], isNull);
        expect(result.containsKey('updated_at'), isTrue);
      });
    });
  });
}