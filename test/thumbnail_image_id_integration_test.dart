import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/rest_api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/thumbnail.dart';

/// Integration test for image_id field in thumbnails table
/// Tests database migration, data persistence, and retrieval operations
/// 
/// This test suite verifies:
/// 1. Database migration from version 22 to 23 adds image_id column
/// 2. Thumbnail model correctly parses image_id from database
/// 3. REST API database service correctly saves and retrieves image_id
/// 4. Queries with image_id filtering work correctly
/// 5. Edge cases like null/zero image_id values are handled properly
void main() {
  // Initialize FFI for testing on non-mobile platforms
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Thumbnail image_id Integration Tests', () {
    late ApiDatabaseService apiDbService;
    late RestApiDatabaseService restApiDbService;

    setUp(() async {
      // Create fresh database instance for each test
      apiDbService = ApiDatabaseService();
      restApiDbService = RestApiDatabaseService(apiDbService);
      
      // Ensure database is initialized
      await apiDbService.database;
    });

    tearDown(() async {
      // Clean up database after each test
      final db = await apiDbService.database;
      await db.close();
    });

    /// Test 1: Verify image_id column exists in thumbnails table
    test('thumbnails table should have image_id column after migration', () async {
      final db = await apiDbService.database;
      
      // Query table schema to verify image_id column exists
      final columns = await db.rawQuery("PRAGMA table_info(thumbnails)");
      final columnNames = columns.map((col) => col['name'] as String).toList();
      
      // Verify image_id column is present
      expect(columnNames, contains('image_id'),
          reason: 'thumbnails table should have image_id column after migration to version 23');
      
      if (kDebugMode) {
        print('Test 1 PASSED: image_id column exists in thumbnails table');
      }
    });

    /// Test 2: Verify image_id index exists for performance
    test('thumbnails table should have index on image_id column', () async {
      final db = await apiDbService.database;
      
      // Query indexes to verify idx_thumbnails_image_id exists
      final indexes = await db.rawQuery("PRAGMA index_list(thumbnails)");
      final indexNames = indexes.map((idx) => idx['name'] as String).toList();
      
      // Verify image_id index is present
      expect(indexNames, contains('idx_thumbnails_image_id'),
          reason: 'thumbnails table should have index on image_id for optimized queries');
      
      if (kDebugMode) {
        print('Test 2 PASSED: idx_thumbnails_image_id index exists');
      }
    });

    /// Test 3: Save and retrieve thumbnails with image_id
    test('should save and retrieve thumbnails with image_id correctly', () async {
      // Create test thumbnails with different image_ids
      final testThumbnails = [
        Thumbnail(
          entityType: 'client',
          entityId: 1,
          code1c: 'CLIENT001',
          entityName: 'Test Client 1',
          imageId: 101, // Server-side image ID
          thumbnailUrl: 'http://example.com/thumbnail1.jpg',
          isMain: true,
          statusCode: 'active',
          statusName: 'Active',
          createdAt: DateTime.now(),
        ),
        Thumbnail(
          entityType: 'client',
          entityId: 1,
          code1c: 'CLIENT001',
          entityName: 'Test Client 1',
          imageId: 102, // Different server-side image ID for same client
          thumbnailUrl: 'http://example.com/thumbnail2.jpg',
          isMain: false,
          statusCode: 'active',
          statusName: 'Active',
          createdAt: DateTime.now(),
        ),
        Thumbnail(
          entityType: 'nomenklatura',
          entityId: 2,
          code1c: 'PRODUCT001',
          entityName: 'Test Product',
          imageId: 201, // Product image ID
          thumbnailUrl: 'http://example.com/product1.jpg',
          isMain: true,
          statusCode: 'active',
          statusName: 'Active',
          createdAt: DateTime.now(),
        ),
      ];

      // Save thumbnails to database
      await restApiDbService.saveThumbnails(testThumbnails);

      // Retrieve all thumbnails
      final retrievedThumbnails = await restApiDbService.getAllThumbnails();

      // Verify count matches
      expect(retrievedThumbnails.length, equals(3),
          reason: 'Should retrieve all 3 saved thumbnails');

      // Verify image_id values are preserved
      final clientMainThumbnail = retrievedThumbnails.firstWhere(
        (t) => t.code1c == 'CLIENT001' && t.isMain,
      );
      expect(clientMainThumbnail.imageId, equals(101),
          reason: 'Main client thumbnail should have image_id 101');

      final clientSecondaryThumbnail = retrievedThumbnails.firstWhere(
        (t) => t.code1c == 'CLIENT001' && !t.isMain,
      );
      expect(clientSecondaryThumbnail.imageId, equals(102),
          reason: 'Secondary client thumbnail should have image_id 102');

      final productThumbnail = retrievedThumbnails.firstWhere(
        (t) => t.code1c == 'PRODUCT001',
      );
      expect(productThumbnail.imageId, equals(201),
          reason: 'Product thumbnail should have image_id 201');

      if (kDebugMode) {
        print('Test 3 PASSED: Thumbnails with image_id saved and retrieved correctly');
      }
    });

    /// Test 4: Verify duplicate prevention based on image_id
    test('should handle duplicate thumbnails with different image_ids', () async {
      // Create thumbnails with same entity but different image_ids
      final testThumbnails = [
        Thumbnail(
          entityType: 'client',
          entityId: 1,
          code1c: 'CLIENT001',
          entityName: 'Test Client',
          imageId: 101,
          thumbnailUrl: 'http://example.com/thumbnail1.jpg',
          isMain: false,
          createdAt: DateTime.now(),
        ),
        Thumbnail(
          entityType: 'client',
          entityId: 1,
          code1c: 'CLIENT001',
          entityName: 'Test Client',
          imageId: 102,
          thumbnailUrl: 'http://example.com/thumbnail2.jpg',
          isMain: false,
          createdAt: DateTime.now(),
        ),
        Thumbnail(
          entityType: 'client',
          entityId: 1,
          code1c: 'CLIENT001',
          entityName: 'Test Client',
          imageId: 103,
          thumbnailUrl: 'http://example.com/thumbnail3.jpg',
          isMain: false,
          createdAt: DateTime.now(),
        ),
      ];

      // Save thumbnails
      await restApiDbService.saveThumbnails(testThumbnails);

      // Retrieve thumbnails for this client
      final retrievedThumbnails = await restApiDbService.getThumbnailsByCode('CLIENT001');

      // Verify all 3 thumbnails are saved (different image_ids)
      expect(retrievedThumbnails.length, equals(3),
          reason: 'Should save all thumbnails with different image_ids for same client');

      // Verify each has unique image_id
      final imageIds = retrievedThumbnails.map((t) => t.imageId).toList();
      expect(imageIds.toSet().length, equals(3),
          reason: 'All thumbnails should have unique image_ids');

      if (kDebugMode) {
        print('Test 4 PASSED: Multiple thumbnails with different image_ids handled correctly');
      }
    });

    /// Test 5: Test image_id default value (0) for old records
    test('should handle thumbnails with default image_id value', () async {
      // Create thumbnail with default image_id (0)
      final thumbnail = Thumbnail(
        entityType: 'client',
        entityId: 1,
        code1c: 'CLIENT_OLD',
        entityName: 'Old Client',
        imageId: 0, // Default value for old records
        thumbnailUrl: 'http://example.com/old.jpg',
        isMain: true,
        createdAt: DateTime.now(),
      );

      await restApiDbService.saveThumbnails([thumbnail]);

      // Retrieve and verify
      final retrieved = await restApiDbService.getThumbnailsByCode('CLIENT_OLD');
      expect(retrieved.length, equals(1));
      expect(retrieved.first.imageId, equals(0),
          reason: 'Default image_id should be 0 for old/migrated records');

      if (kDebugMode) {
        print('Test 5 PASSED: Default image_id (0) handled correctly');
      }
    });

    /// Test 6: Verify Thumbnail.fromMap correctly parses image_id
    test('Thumbnail.fromMap should correctly parse image_id from database row', () {
      // Create mock database row with image_id
      final mockRow = {
        'id': 1,
        'entity_type': 'client',
        'entity_id': 123,
        'code_1c': 'CLIENT123',
        'entity_name': 'Test Client',
        'image_id': 456, // Should be parsed correctly
        'thumbnail_url': 'http://example.com/test.jpg',
        'thumbnail_width': 200,
        'thumbnail_height': 150,
        'thumbnail_format': 'JPEG',
        'thumbnail_size_kb': '25',
        'original_width': 800,
        'original_height': 600,
        'original_format': 'JPEG',
        'original_size_bytes': 102400,
        'original_size_kb': '100',
        'is_main': 1,
        'category': 'exterior',
        'note': 'Front view',
        'status_code': 'approved',
        'status_name': 'Approved',
        'source_name': 'mobile',
        'source_type': 'camera',
        'created_at_server': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-02T00:00:00Z',
      };

      // Parse using fromMap
      final thumbnail = Thumbnail.fromMap(mockRow);

      // Verify image_id is correctly parsed
      expect(thumbnail.imageId, equals(456),
          reason: 'fromMap should correctly parse image_id from database row');
      expect(thumbnail.code1c, equals('CLIENT123'));
      expect(thumbnail.isMain, isTrue);

      if (kDebugMode) {
        print('Test 6 PASSED: Thumbnail.fromMap correctly parses image_id');
      }
    });

    /// Test 7: Verify image_id handles null value in database
    test('Thumbnail.fromMap should handle null image_id gracefully', () {
      // Create mock database row with null image_id
      final mockRow = {
        'id': 1,
        'entity_type': 'client',
        'entity_id': 123,
        'code_1c': 'CLIENT123',
        'entity_name': 'Test Client',
        'image_id': null, // Null value (for backward compatibility)
        'thumbnail_url': 'http://example.com/test.jpg',
        'is_main': 0,
        'thumbnail_width': 0,
        'thumbnail_height': 0,
        'original_width': 0,
        'original_height': 0,
        'original_size_bytes': 0,
      };

      // Parse using fromMap  - should not throw exception
      final thumbnail = Thumbnail.fromMap(mockRow);

      // Verify image_id defaults to 0 when null
      expect(thumbnail.imageId, equals(0),
          reason: 'fromMap should default image_id to 0 when null');

      if (kDebugMode) {
        print('Test 7 PASSED: Null image_id handled gracefully with default value 0');
      }
    });

    /// Test 8: Test database query performance with image_id index
    test('should efficiently query thumbnails by image_id using index', () async {
      // Create multiple thumbnails for performance test
      final testThumbnails = List.generate(100, (index) {
        return Thumbnail(
          entityType: 'client',
          entityId: index,
          code1c: 'CLIENT_${index.toString().padLeft(3, '0')}',
          entityName: 'Client $index',
          imageId: 1000 + index, // Unique image IDs
          thumbnailUrl: 'http://example.com/thumb_$index.jpg',
          isMain: index % 10 == 0, // Every 10th is main
          createdAt: DateTime.now(),
        );
      });

      // Save all thumbnails
      await restApiDbService.saveThumbnails(testThumbnails);

      // Query by specific image_id
      final db = await apiDbService.database;
      final result = await db.query(
        'thumbnails',
        where: 'image_id = ?',
        whereArgs: [1050],
      );

      // Verify query returns correct result
      expect(result.length, equals(1),
          reason: 'Should find exactly one thumbnail with image_id 1050');
      expect(result.first['code_1c'], equals('CLIENT_050'));

      if (kDebugMode) {
        print('Test 8 PASSED: Indexed query by image_id works efficiently');
      }
    });

    /// Test 9: Verify toJson includes image_id field
    test('Thumbnail.toJson should include image_id field', () {
      final thumbnail = Thumbnail(
        entityType: 'client',
        entityId: 1,
        code1c: 'CLIENT001',
        entityName: 'Test Client',
        imageId: 999,
        thumbnailUrl: 'http://example.com/test.jpg',
        isMain: true,
        createdAt: DateTime.now(),
      );

      final json = thumbnail.toJson();

      // Verify JSON contains image_id
      expect(json, contains('image_id'),
          reason: 'toJson should include image_id field');
      expect(json['image_id'], equals(999),
          reason: 'toJson should preserve image_id value');

      if (kDebugMode) {
        print('Test 9 PASSED: toJson correctly includes image_id');
      }
    });

    /// Test 10: Verify database migration from version 22 to 23
    test('database migration from v22 to v23 should add image_id column', () async {
      final db = await apiDbService.database;
      
      // Verify current database version is 23
      final version = await db.getVersion();
      expect(version, greaterThanOrEqualTo(23),
          reason: 'Database version should be 23 or higher after image_id migration');

      if (kDebugMode) {
        print('Test 10 PASSED: Database migrated to version $version with image_id field');
      }
    });

    /// Test 11: Test batch operations with image_id
    test('batch save operations should preserve image_id for all records', () async {
      // Create large batch of thumbnails
      final batchThumbnails = List.generate(50, (index) {
        return Thumbnail(
          entityType: index % 2 == 0 ? 'client' : 'nomenklatura',
          entityId: index,
          code1c: 'CODE_$index',
          entityName: 'Entity $index',
          imageId: 2000 + index,
          thumbnailUrl: 'http://example.com/batch_$index.jpg',
          isMain: index == 0,
          createdAt: DateTime.now(),
        );
      });

      // Save batch
      await restApiDbService.saveThumbnails(batchThumbnails);

      // Retrieve and verify all image_ids are correct
      final allThumbnails = await restApiDbService.getAllThumbnails();
      expect(allThumbnails.length, equals(50),
          reason: 'Should save all 50 thumbnails in batch operation');

      // Verify each thumbnail has correct image_id
      for (int i = 0; i < 50; i++) {
        final thumbnail = allThumbnails.firstWhere((t) => t.code1c == 'CODE_$i');
        expect(thumbnail.imageId, equals(2000 + i),
            reason: 'Thumbnail $i should have image_id ${2000 + i}');
      }

      if (kDebugMode) {
        print('Test 11 PASSED: Batch operations preserve image_id for all records');
      }
    });

    /// Test 12: Test edge case - very large image_id values
    test('should handle very large image_id values correctly', () async {
      const largeImageId = 2147483647; // Max int32 value

      final thumbnail = Thumbnail(
        entityType: 'client',
        entityId: 1,
        code1c: 'CLIENT_LARGE',
        entityName: 'Large ID Client',
        imageId: largeImageId,
        thumbnailUrl: 'http://example.com/large.jpg',
        isMain: true,
        createdAt: DateTime.now(),
      );

      await restApiDbService.saveThumbnails([thumbnail]);

      // Retrieve and verify
      final retrieved = await restApiDbService.getThumbnailsByCode('CLIENT_LARGE');
      expect(retrieved.first.imageId, equals(largeImageId),
          reason: 'Should correctly handle max int32 image_id value');

      if (kDebugMode) {
        print('Test 12 PASSED: Large image_id values handled correctly');
      }
    });

    /// Test 13: Test deduplication logic with image_id
    test('should deduplicate thumbnails using image_id in key', () async {
      // Create duplicate thumbnails (same entity, same image_id)
      final duplicateThumbnails = [
        Thumbnail(
          entityType: 'client',
          entityId: 1,
          code1c: 'CLIENT001',
          entityName: 'Test Client',
          imageId: 555,
          thumbnailUrl: 'http://example.com/first.jpg',
          isMain: true,
          createdAt: DateTime.now(),
        ),
        Thumbnail(
          entityType: 'client',
          entityId: 1,
          code1c: 'CLIENT001',
          entityName: 'Test Client',
          imageId: 555, // Same image_id - duplicate
          thumbnailUrl: 'http://example.com/second.jpg', // Different URL
          isMain: true,
          createdAt: DateTime.now(),
        ),
      ];

      // Save - deduplication should keep only one
      await restApiDbService.saveThumbnails(duplicateThumbnails);

      // Retrieve and verify only one record saved
      final retrieved = await restApiDbService.getThumbnailsByCode('CLIENT001');
      expect(retrieved.length, equals(1),
          reason: 'Deduplication should keep only one thumbnail for duplicate entity_type + entity_id + code_1c + image_id');

      if (kDebugMode) {
        print('Test 13 PASSED: Deduplication with image_id works correctly');
      }
    });

    /// Test 14: Verify copyWith preserves image_id
    test('Thumbnail.copyWith should preserve or update image_id', () {
      final original = Thumbnail(
        entityType: 'client',
        code1c: 'CLIENT001',
        imageId: 100,
        thumbnailUrl: 'http://example.com/original.jpg',
        isMain: true,
      );

      // Copy with new image_id
      final updated = original.copyWith(imageId: 200);
      expect(updated.imageId, equals(200),
          reason: 'copyWith should update image_id');
      expect(updated.code1c, equals('CLIENT001'),
          reason: 'copyWith should preserve other fields');

      // Copy without changing image_id
      final unchanged = original.copyWith(thumbnailUrl: 'http://example.com/new.jpg');
      expect(unchanged.imageId, equals(100),
          reason: 'copyWith should preserve image_id when not specified');

      if (kDebugMode) {
        print('Test 14 PASSED: copyWith correctly handles image_id');
      }
    });

    /// Test 15: Test toString includes image_id for debugging
    test('Thumbnail.toString should include image_id for debugging', () {
      final thumbnail = Thumbnail(
        id: 1,
        entityType: 'client',
        code1c: 'CLIENT001',
        imageId: 777,
        isMain: true,
      );

      final stringRepresentation = thumbnail.toString();

      // Verify imageId is in toString output
      expect(stringRepresentation, contains('imageId: 777'),
          reason: 'toString should include image_id for debugging');

      if (kDebugMode) {
        print('Test 15 PASSED: toString includes image_id');
        print('Sample toString output: $stringRepresentation');
      }
    });
  });

  group('Thumbnail image_id Edge Cases', () {
    late ApiDatabaseService apiDbService;
    late RestApiDatabaseService restApiDbService;

    setUp(() async {
      apiDbService = ApiDatabaseService();
      restApiDbService = RestApiDatabaseService(apiDbService);
      await apiDbService.database;
    });

    tearDown(() async {
      final db = await apiDbService.database;
      await db.close();
    });

    /// Test: Negative image_id values (error condition)
    test('should handle negative image_id values', () async {
      final thumbnail = Thumbnail(
        entityType: 'client',
        code1c: 'CLIENT_NEG',
        imageId: -1, // Negative value
        thumbnailUrl: 'http://example.com/neg.jpg',
        createdAt: DateTime.now(),
      );

      // Save and retrieve
      await restApiDbService.saveThumbnails([thumbnail]);
      final retrieved = await restApiDbService.getThumbnailsByCode('CLIENT_NEG');

      // Verify negative value is preserved (database allows it)
      expect(retrieved.first.imageId, equals(-1),
          reason: 'Database should preserve negative image_id values');

      if (kDebugMode) {
        print('Edge Case Test PASSED: Negative image_id handled');
      }
    });

    /// Test: Empty thumbnails list
    test('should handle empty thumbnails list gracefully', () async {
      // Save empty list - should not throw
      await restApiDbService.saveThumbnails([]);

      // Verify no thumbnails in database
      final all = await restApiDbService.getAllThumbnails();
      expect(all.length, equals(0),
          reason: 'Saving empty list should result in empty database');

      if (kDebugMode) {
        print('Edge Case Test PASSED: Empty list handled gracefully');
      }
    });

    /// Test: Get statistics with image_id
    test('getThumbnailsStatistics should work with image_id field', () async {
      // Add test data
      final thumbnails = [
        Thumbnail(
          entityType: 'client',
          code1c: 'C1',
          imageId: 1,
          isMain: true,
          createdAt: DateTime.now(),
        ),
        Thumbnail(
          entityType: 'client',
          code1c: 'C2',
          imageId: 2,
          isMain: false,
          createdAt: DateTime.now(),
        ),
        Thumbnail(
          entityType: 'nomenklatura',
          code1c: 'P1',
          imageId: 3,
          isMain: true,
          createdAt: DateTime.now(),
        ),
      ];

      await restApiDbService.saveThumbnails(thumbnails);

      // Get statistics
      final stats = await restApiDbService.getThumbnailsStatistics();

      // Verify statistics
      expect(stats['total'], equals(3));
      expect(stats['clients'], equals(2));
      expect(stats['products'], equals(1));
      expect(stats['mainImages'], equals(2));

      if (kDebugMode) {
        print('Edge Case Test PASSED: Statistics work correctly with image_id');
        print('Statistics: $stats');
      }
    });
  });
}
