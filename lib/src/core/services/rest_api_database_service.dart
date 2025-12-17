import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/thumbnail.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';

/// REST API Database Service for handling thumbnail database operations
/// This service manages all database operations related to thumbnail data
/// including saving, retrieving, updating, and deleting thumbnail records
class RestApiDatabaseService {
  final ApiDatabaseService _apiDatabaseService;

  RestApiDatabaseService(this._apiDatabaseService);

  /// Helper method to convert database row to Thumbnail object
  /// Safely handles nullable fields that can now be null in the database
  Thumbnail _rowToThumbnail(Map<String, dynamic> row) {
    return Thumbnail(
      id: row['id'] as int?,
      entityType: row['entity_type'] as String? ?? 'unknown',
      entityId: _parseInt(row['entity_id']),
      code1c: row['code_1c'] as String? ?? '',
      entityName: row['entity_name'] as String? ?? '',
      imageId: 0, // Not stored in database, set to default
      thumbnailUrl: row['thumbnail_url'] as String? ?? '',
      thumbnailDimensions: _parseThumbnailDimensions(row),
      originalDimensions: _parseOriginalDimensions(row),
      isMain: _parseBool(row['is_main']),
      category: row['category'] as String?,
      note: row['note'] as String?,
      statusCode: row['status_code'] as String? ?? '',
      statusName: row['status_name'] as String? ?? '',
      sourceName: row['source_name'] as String? ?? '',
      sourceType: row['source_type'] as String? ?? '',
      createdAt: _parseDateTime(row['created_at_server']),
      updatedAt: row['updated_at'] != null ? _parseDateTime(row['updated_at']) : null,
      clientId: null, // Not stored in database
      productId: null, // Not stored in database
    );
  }

  // Safe parsing helpers for nullable database fields
  static int _parseInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static bool _parseBool(dynamic value, [bool defaultValue = false]) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return defaultValue;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null || (value.toString().isEmpty)) {
      return DateTime.now();
    }
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  static Map<String, dynamic> _parseThumbnailDimensions(Map<String, dynamic> map) {
    return {
      'width': _parseInt(map['thumbnail_width']),
      'height': _parseInt(map['thumbnail_height']),
      'format': map['thumbnail_format'] as String? ?? 'unknown',
      'size': map['thumbnail_size_kb'] as String? ?? '0',
    };
  }

  static Map<String, dynamic> _parseOriginalDimensions(Map<String, dynamic> map) {
    return {
      'width': _parseInt(map['original_width']),
      'height': _parseInt(map['original_height']),
      'format': map['original_format'] as String? ?? 'unknown',
      'size_bytes': _parseInt(map['original_size_bytes']),
      'size': map['original_size_kb'] as String? ?? '0',
    };
  }

  /// Get database instance from ApiDatabaseService
  Future<Database> get _database => _apiDatabaseService.database;

  /// Save thumbnails to database
  /// This method saves thumbnail data to the thumbnails table
  /// It replaces existing data with new data (full sync approach)
  ///
  /// @param thumbnails List of thumbnail objects to save
  /// @return Future<void>
  /// @throws Exception if database operation fails
  Future<void> saveThumbnails(List<Thumbnail> thumbnails) async {
    try {
      if (kDebugMode) {
        print('RestApiDatabaseService: Saving ${thumbnails.length} thumbnails to database');
      }

      // Validate input data
      if (thumbnails.isEmpty) {
        if (kDebugMode) {
          print('RestApiDatabaseService: No thumbnails to save');
        }
        return;
      }

      final db = await _database;
      final now = DateTime.now().toIso8601String();

      // Use batch operations for much better performance
      final batch = db.batch();

      // Delete all existing thumbnails (full sync approach)
      batch.delete('thumbnails');

      // Separate main and non-main thumbnails before deduplication
      final mainThumbnails = thumbnails.where((t) => t.isMain).toList();
      final nonMainThumbnails = thumbnails.where((t) => !t.isMain).toList();

      // Deduplicate  thumbnails by (entity_type, entity_id, code_1c, imageid)
      final uniqueThumbnails = <String, Thumbnail>{};
      for (final thumbnail in thumbnails) {
        final key = '${thumbnail.entityType}_${thumbnail.entityId}_${thumbnail.code1c}_${thumbnail.imageId}';
        uniqueThumbnails[key] = thumbnail;
      }

      // Deduplicate main thumbnails by (entity_type, entity_id, code_1c)
      final uniqueMainThumbnails = <String, Thumbnail>{};
      for (final thumbnail in mainThumbnails) {
        final key = '${thumbnail.entityType}_${thumbnail.entityId}_${thumbnail.code1c}_${thumbnail.imageId}';
        uniqueMainThumbnails[key] = thumbnail;
      }

      // Deduplicate non-main thumbnails by (entity_type, entity_id, code_1c)
      final uniqueNonMainThumbnails = <String, Thumbnail>{};
      for (final thumbnail in nonMainThumbnails) {
        final key = '${thumbnail.entityType}_${thumbnail.entityId}_${thumbnail.code1c}';
        uniqueNonMainThumbnails[key] = thumbnail;
      }

      // Combine: main thumbnails first, then non-main in insertion order
      final sortedUniqueThumbnails = [
        // ...uniqueMainThumbnails.values,
        // ...uniqueNonMainThumbnails.values,
        ...uniqueThumbnails.values,
      ];

      if (kDebugMode) {
        print('RestApiDatabaseService: After deduplication: ${sortedUniqueThumbnails.length} unique thumbnails (${uniqueThumbnails.length} main)');
      }

      // Add all inserts to batch
      for (final thumbnail in sortedUniqueThumbnails) {
        batch.insert('thumbnails', {
          'entity_type': thumbnail.entityType,
          'entity_id': thumbnail.entityId,
          'code_1c': thumbnail.code1c,
          'entity_name': thumbnail.entityName,
          'thumbnail_url': thumbnail.thumbnailUrl,
          'thumbnail_width': thumbnail.thumbnailDimensions?['width'] ?? 0,
          'thumbnail_height': thumbnail.thumbnailDimensions?['height'] ?? 0,
          'thumbnail_format': thumbnail.thumbnailDimensions?['format'] ?? '',
          'thumbnail_size_kb': thumbnail.thumbnailDimensions?['size'] ?? '',
          'original_width': thumbnail.originalDimensions?['width'] ?? 0,
          'original_height': thumbnail.originalDimensions?['height'] ?? 0,
          'original_format': thumbnail.originalDimensions?['format'] ?? '',
          'original_size_bytes': thumbnail.originalDimensions?['size_bytes'] ?? 0,
          'original_size_kb': thumbnail.originalDimensions?['size'] ?? '',
          'is_main': thumbnail.isMain ? 1 : 0,
          'category': thumbnail.category,
          'note': thumbnail.note,
          'status_code': thumbnail.statusCode,
          'status_name': thumbnail.statusName,
          'source_name': thumbnail.sourceName,
          'source_type': thumbnail.sourceType,
          'created_at_server': thumbnail.createdAt?.toIso8601String(),
          'created_at': now,
          'updated_at': now,
        });

        if (kDebugMode && sortedUniqueThumbnails.indexOf(thumbnail) < 3) {
          print('RestApiDatabaseService: Sample insert - Entity: ${thumbnail.entityType}, Code: ${thumbnail.code1c}, Main: ${thumbnail.isMain}');
        }
      }

      // Execute batch operation
      await batch.commit(noResult: true);

      if (kDebugMode) {
        print('RestApiDatabaseService: Successfully saved ${sortedUniqueThumbnails.length} thumbnails');

        // Log summary statistics
        final clientThumbnails = sortedUniqueThumbnails.where((t) => t.entityType == 'client').length;
        final productThumbnails = sortedUniqueThumbnails.where((t) => t.entityType == 'nomenklatura').length;
        final mainThumbnails = sortedUniqueThumbnails.where((t) => t.isMain).length;

        print('RestApiDatabaseService: Summary - Clients: $clientThumbnails, Products: $productThumbnails, Main images: $mainThumbnails');
      }

    } catch (e) {
      if (kDebugMode) {
        print('RestApiDatabaseService: Error saving thumbnails: $e');
      }
      throw Exception('Thumbnails ma\'lumotlarini saqlashda xatolik: $e');
    }
  }

  /// Get all thumbnails from database
  /// Retrieves all thumbnail records from the database
  ///
  /// @return Future<List<Thumbnail>> List of all thumbnail objects
  Future<List<Thumbnail>> getAllThumbnails() async {
    try {
      final db = await _database;
      final result = await db.query('thumbnails', orderBy: 'created_at DESC');

      if (kDebugMode) {
        print('RestApiDatabaseService: Retrieved ${result.length} thumbnails from database');
      }

      return result.map((row) => _rowToThumbnail(row)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('RestApiDatabaseService: Error retrieving thumbnails: $e');
      }
      throw Exception('Thumbnails ma\'lumotlarini olishda xatolik: $e');
    }
  }

  /// Get thumbnails by entity type
  /// Retrieves thumbnails filtered by entity type (client or nomenklatura)
  ///
  /// @param entityType The entity type to filter by ('client' or 'nomenklatura')
  /// @return Future<List<Thumbnail>> List of thumbnail objects for the specified entity type
  Future<List<Thumbnail>> getThumbnailsByEntityType(String entityType) async {
    try {
      if (entityType.isEmpty) {
        throw ArgumentError('Entity type cannot be empty');
      }

      final db = await _database;
      final result = await db.query(
        'thumbnails',
        where: 'entity_type = ?',
        whereArgs: [entityType],
        orderBy: 'entity_name ASC',
      );

      if (kDebugMode) {
        print('RestApiDatabaseService: Retrieved ${result.length} thumbnails for entity type: $entityType');
      }

      return result.map((row) => _rowToThumbnail(row)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('RestApiDatabaseService: Error retrieving thumbnails by entity type: $e');
      }
      throw Exception('Entity turi bo\'yicha thumbnails olishda xatolik: $e');
    }
  }

  /// Get thumbnails by code (1C code)
  /// Retrieves thumbnails for a specific entity identified by its 1C code
  ///
  /// @param code1c The 1C code to search for
  /// @return Future<List<Thumbnail>> List of thumbnail objects for the specified code
  Future<List<Thumbnail>> getThumbnailsByCode(String code1c) async {
    try {
      if (code1c.isEmpty) {
        throw ArgumentError('Code 1C cannot be empty');
      }

      final db = await _database;
      final result = await db.query(
        'thumbnails',
        where: 'code_1c = ?',
        whereArgs: [code1c],
        orderBy: 'is_main DESC, created_at_server DESC', // Main images first, then by creation date
      );

      if (kDebugMode) {
        print('RestApiDatabaseService: Retrieved ${result.length} thumbnails for code: $code1c');
      }

      return result.map((row) => _rowToThumbnail(row)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('RestApiDatabaseService: Error retrieving thumbnails by code: $e');
      }
      throw Exception('Kod bo\'yicha thumbnails olishda xatolik: $e');
    }
  }

  /// Get main thumbnail for entity
  /// Retrieves the main (primary) thumbnail for a specific entity
  ///
  /// @param code1c The 1C code of the entity
  /// @return Future<Thumbnail?> The main thumbnail object or null if not found
  Future<Thumbnail?> getMainThumbnail(String code1c) async {
    try {
      if (code1c.isEmpty) {
        throw ArgumentError('Code 1C cannot be empty');
      }

      final db = await _database;
      final result = await db.query(
        'thumbnails',
        where: 'code_1c = ? AND is_main = 1',
        whereArgs: [code1c],
        limit: 1,
      );

      if (result.isEmpty) {
        if (kDebugMode) {
          print('RestApiDatabaseService: No main thumbnail found for code: $code1c');
        }
        return null;
      }

      return _rowToThumbnail(result.first);
    } catch (e) {
      if (kDebugMode) {
        print('RestApiDatabaseService: Error retrieving main thumbnail: $e');
      }
      throw Exception('Asosiy thumbnail olishda xatolik: $e');
    }
  }

  /// Get thumbnails count
  /// Returns the total number of thumbnails in the database
  ///
  /// @return Future<int> Total count of thumbnails
  Future<int> getThumbnailsCount() async {
    try {
      final db = await _database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM thumbnails');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('RestApiDatabaseService: Error getting thumbnails count: $e');
      }
      throw Exception('Thumbnails sonini olishda xatolik: $e');
    }
  }

  /// Get thumbnails statistics
  /// Returns comprehensive statistics about thumbnails in the database
  ///
  /// @return Future<Map<String, dynamic>> Statistics map containing counts and breakdowns
  Future<Map<String, dynamic>> getThumbnailsStatistics() async {
    try {
      final db = await _database;

      // Get total count
      final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM thumbnails');
      final totalCount = Sqflite.firstIntValue(totalResult) ?? 0;

      // Get count by entity type
      final clientResult = await db.rawQuery('SELECT COUNT(*) as count FROM thumbnails WHERE entity_type = "client"');
      final clientCount = Sqflite.firstIntValue(clientResult) ?? 0;

      final productResult = await db.rawQuery('SELECT COUNT(*) as count FROM thumbnails WHERE entity_type = "nomenklatura"');
      final productCount = Sqflite.firstIntValue(productResult) ?? 0;

      // Get count of main images
      final mainResult = await db.rawQuery('SELECT COUNT(*) as count FROM thumbnails WHERE is_main = 1');
      final mainCount = Sqflite.firstIntValue(mainResult) ?? 0;

      // Get unique entities count
      final uniqueEntitiesResult = await db.rawQuery('SELECT COUNT(DISTINCT code_1c) as count FROM thumbnails');
      final uniqueEntitiesCount = Sqflite.firstIntValue(uniqueEntitiesResult) ?? 0;

      // Get most recent update
      final recentResult = await db.rawQuery('SELECT MAX(updated_at) as recent FROM thumbnails');
      final mostRecentUpdate = recentResult.first['recent'] as String?;

      final stats = {
        'total': totalCount,
        'clients': clientCount,
        'products': productCount,
        'mainImages': mainCount,
        'uniqueEntities': uniqueEntitiesCount,
        'mostRecentUpdate': mostRecentUpdate,
        'lastSync': DateTime.now().toIso8601String(),
      };

      if (kDebugMode) {
        print('RestApiDatabaseService: Thumbnails statistics: $stats');
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        print('RestApiDatabaseService: Error getting thumbnails statistics: $e');
      }
      throw Exception('Thumbnails statistikasini olishda xatolik: $e');
    }
  }

  /// Delete thumbnails by entity code
  /// Removes all thumbnails associated with a specific entity code
  ///
  /// @param code1c The 1C code of the entity to delete thumbnails for
  /// @return Future<int> Number of deleted records
  Future<int> deleteThumbnailsByCode(String code1c) async {
    try {
      if (code1c.isEmpty) {
        throw ArgumentError('Code 1C cannot be empty');
      }

      final db = await _database;
      final deletedCount = await db.delete(
        'thumbnails',
        where: 'code_1c = ?',
        whereArgs: [code1c],
      );

      if (kDebugMode) {
        print('RestApiDatabaseService: Deleted $deletedCount thumbnails for code: $code1c');
      }

      return deletedCount;
    } catch (e) {
      if (kDebugMode) {
        print('RestApiDatabaseService: Error deleting thumbnails by code: $e');
      }
      throw Exception('Kod bo\'yicha thumbnails o\'chirishda xatolik: $e');
    }
  }

  /// Delete all thumbnails
  /// Removes all thumbnail records from the database
  ///
  /// @return Future<int> Number of deleted records
  Future<int> deleteAllThumbnails() async {
    try {
      final db = await _database;
      final deletedCount = await db.delete('thumbnails');

      if (kDebugMode) {
        print('RestApiDatabaseService: Deleted all $deletedCount thumbnails');
      }

      return deletedCount;
    } catch (e) {
      if (kDebugMode) {
        print('RestApiDatabaseService: Error deleting all thumbnails: $e');
      }
      throw Exception('Barcha thumbnails o\'chirishda xatolik: $e');
    }
  }

  /// Check if thumbnails exist for entity
  /// Checks if there are any thumbnails for a specific entity code
  ///
  /// @param code1c The 1C code to check
  /// @return Future<bool> True if thumbnails exist, false otherwise
  Future<bool> hasThumbnailsForEntity(String code1c) async {
    try {
      if (code1c.isEmpty) {
        return false;
      }

      final db = await _database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM thumbnails WHERE code_1c = ?',
        [code1c],
      );

      final count = Sqflite.firstIntValue(result) ?? 0;
      return count > 0;
    } catch (e) {
      if (kDebugMode) {
        print('RestApiDatabaseService: Error checking thumbnails existence: $e');
      }
      return false;
    }
  }

  /// Get thumbnail URLs for entity
  /// Returns a list of thumbnail URLs for a specific entity
  /// Useful for displaying multiple images for an entity
  ///
  /// @param code1c The 1C code of the entity
  /// @param includeMainOnly If true, returns only main images
  /// @return Future<List<String>> List of thumbnail URLs
  Future<List<String>> getThumbnailUrls(String code1c, {bool includeMainOnly = false}) async {
    try {
      if (code1c.isEmpty) {
        return [];
      }

      final db = await _database;
      String whereClause = 'code_1c = ?';
      List<dynamic> whereArgs = [code1c];

      if (includeMainOnly) {
        whereClause += ' AND is_main = 1';
      }

      final result = await db.query(
        'thumbnails',
        columns: ['thumbnail_url'],
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'is_main DESC, created_at_server DESC',
      );

      final urls = result.map((row) => row['thumbnail_url'] as String).toList();

      if (kDebugMode) {
        print('RestApiDatabaseService: Retrieved ${urls.length} thumbnail URLs for code: $code1c');
      }

      return urls;
    } catch (e) {
      if (kDebugMode) {
        print('RestApiDatabaseService: Error getting thumbnail URLs: $e');
      }
      throw Exception('Thumbnail URLlarini olishda xatolik: $e');
    }
  }
}