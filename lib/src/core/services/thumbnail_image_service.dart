import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'api_database_service.dart';
import 'rest_api_service.dart';
import 'token_service.dart';

/// Model class for client images
class ClientImage {
  final int? id;
  final String clientCode;
  final String? imageUrl;
  final String? imageSmUrl;
  final String? imageMdUrl;
  final String? imageLgUrl;
  final String? imageThumbnailUrl;
  final String? imageDimensions;
  final String? imageSmDimensions;
  final String? imageMdDimensions;
  final String? imageLgDimensions;
  final String? imageThumbnailDimensions;
  final bool isMain;
  final String? category;
  final String? note;
  final String? statusCode;
  final String? statusName;
  final String? sourceName;
  final String? sourceType;
  final String? createdAtServer;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClientImage({
    this.id,
    required this.clientCode,
    this.imageUrl,
    this.imageSmUrl,
    this.imageMdUrl,
    this.imageLgUrl,
    this.imageThumbnailUrl,
    this.imageDimensions,
    this.imageSmDimensions,
    this.imageMdDimensions,
    this.imageLgDimensions,
    this.imageThumbnailDimensions,
    this.isMain = false,
    this.category,
    this.note,
    this.statusCode,
    this.statusName,
    this.sourceName,
    this.sourceType,
    this.createdAtServer,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_code': clientCode,
      'image_url': imageUrl,
      'image_sm_url': imageSmUrl,
      'image_md_url': imageMdUrl,
      'image_lg_url': imageLgUrl,
      'image_thumbnail_url': imageThumbnailUrl,
      'image_dimensions': imageDimensions,
      'image_sm_dimensions': imageSmDimensions,
      'image_md_dimensions': imageMdDimensions,
      'image_lg_dimensions': imageLgDimensions,
      'image_thumbnail_dimensions': imageThumbnailDimensions,
      'is_main': isMain ? 1 : 0,
      'category': category,
      'note': note,
      'status_code': statusCode,
      'status_name': statusName,
      'source_name': sourceName,
      'source_type': sourceType,
      'created_at_server': createdAtServer,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ClientImage.fromMap(Map<String, dynamic> map) {
    return ClientImage(
      id: map['id'] as int?,
      clientCode: map['client_code'] as String,
      imageUrl: map['image_url'] as String?,
      imageSmUrl: map['image_sm_url'] as String?,
      imageMdUrl: map['image_md_url'] as String?,
      imageLgUrl: map['image_lg_url'] as String?,
      imageThumbnailUrl: map['image_thumbnail_url'] as String?,
      imageDimensions: map['image_dimensions'] as String?,
      imageSmDimensions: map['image_sm_dimensions'] as String?,
      imageMdDimensions: map['image_md_dimensions'] as String?,
      imageLgDimensions: map['image_lg_dimensions'] as String?,
      imageThumbnailDimensions: map['image_thumbnail_dimensions'] as String?,
      isMain: (map['is_main'] as int?) == 1,
      category: map['category'] as String?,
      note: map['note'] as String?,
      statusCode: map['status_code'] as String?,
      statusName: map['status_name'] as String?,
      sourceName: map['source_name'] as String?,
      sourceType: map['source_type'] as String?,
      createdAtServer: map['created_at_server'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// Service class for managing thumbnail and image operations
class ThumbnailImageService {
  final ApiDatabaseService _databaseService;
  final RestApiService _apiService;
  final TokenService _tokenService;
  final Dio _dio;

  ThumbnailImageService({
    required ApiDatabaseService databaseService,
    required RestApiService apiService,
    required TokenService tokenService,
    required Dio dio,
  })  : _databaseService = databaseService,
        _apiService = apiService,
        _tokenService = tokenService,
        _dio = dio;

  /// Callback for progress updates
  Function(double progress, String message)? onProgressUpdate;

  /// Flag to check if operation is cancelled
  bool _isCancelled = false;

  /// Cancel current operation
  void cancel() {
    _isCancelled = true;
  }

  /// Reset cancel flag
  void reset() {
    _isCancelled = false;
  }

  /// Check if operation is cancelled and throw exception if so
  void _checkCancelled() {
    if (_isCancelled) {
      throw Exception('Operation cancelled by user');
    }
  }

  /// Fetch and update thumbnails for a single client from server
  /// This method gets thumbnails for one specific client and replaces existing ones
  Future<void> updateClientThumbnails(String clientCode) async {
    try {
      if (kDebugMode) {
        print('ThumbnailImageService: Updating thumbnails for client: $clientCode');
      }

      _checkCancelled();
      onProgressUpdate?.call(0.0, 'Starting client thumbnail update...');

      // Ensure we have a valid token
      final token = await _tokenService.getValidAccessToken();
      if (token == null) {
        throw Exception('No valid access token available');
      }

      onProgressUpdate?.call(25.0, 'Fetching thumbnails from server...');

      // Fetch thumbnails from API for this specific client
      final thumbnails = await _fetchThumbnailsFromApi(token, 'client', clientCode);

      onProgressUpdate?.call(75.0, 'Updating database...');

      if (thumbnails.isNotEmpty) {
        // Update thumbnails in database (always replace existing for single client)
        await _updateThumbnailsInDatabase('client', clientCode, thumbnails, true);
      }

      onProgressUpdate?.call(100.0, 'Client thumbnails updated successfully');

      if (kDebugMode) {
        print('ThumbnailImageService: Successfully updated ${thumbnails.length} thumbnails for client: $clientCode');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ThumbnailImageService: Error updating client thumbnails: $e');
      }
      onProgressUpdate?.call(0.0, 'Error: ${e.toString()}');
      rethrow;
    }
  }

  /// Fetch and update thumbnails for specific entities (Client/Product)
  /// entityType: 'client' or 'product' or 'nomenklatura'
  /// entityIds: List of entity codes to update thumbnails for
  Future<void> fetchAndUpdateThumbnails({
    required String entityType,
    required List<String> entityIds,
    bool replaceExisting = false,
  }) async {
    try {
      if (kDebugMode) {
        print('ThumbnailImageService: Starting thumbnail update for $entityType entities: $entityIds');
      }

      _checkCancelled();
      onProgressUpdate?.call(0.0, 'Starting thumbnail update for $entityType...');

      // Ensure we have a valid token
      final token = await _tokenService.getValidAccessToken();
      if (token == null) {
        throw Exception('No valid access token available');
      }

      final totalEntities = entityIds.length;
      var processedEntities = 0;

      for (final entityId in entityIds) {
        _checkCancelled();

        try {
          onProgressUpdate?.call(
            (processedEntities / totalEntities) * 100,
            'Processing $entityType: $entityId (${processedEntities + 1}/$totalEntities)',
          );

          // Fetch thumbnails from API
          final thumbnails = await _fetchThumbnailsFromApi(token, entityType, entityId);

          if (thumbnails.isNotEmpty) {
            // Update thumbnails in database
            await _updateThumbnailsInDatabase(entityType, entityId, thumbnails, replaceExisting);
          }

          processedEntities++;
        } catch (e) {
          if (kDebugMode) {
            print('ThumbnailImageService: Error processing $entityType $entityId: $e');
          }
          // Continue with next entity instead of failing completely
          processedEntities++;
        }
      }

      onProgressUpdate?.call(100.0, 'Thumbnail update completed successfully');

      if (kDebugMode) {
        print('ThumbnailImageService: Thumbnail update completed for $entityType');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ThumbnailImageService: Error in fetchAndUpdateThumbnails: $e');
      }
      onProgressUpdate?.call(0.0, 'Error: ${e.toString()}');
      rethrow;
    }
  }

  /// Fetch thumbnails from API for a specific entity
  Future<List<Map<String, dynamic>>> _fetchThumbnailsFromApi(String token, String entityType, String entityId) async {
    const String baseUrl = 'http://178.218.200.120:1596';
    final endpoint = '$baseUrl/api/v1/thumbnails/$entityType/$entityId/';
    final response = await _dio.get(
      endpoint,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('results')) {
        return List<Map<String, dynamic>>.from(data['results']);
      }
    }

    return [];
  }

  /// Update thumbnails in database
  Future<void> _updateThumbnailsInDatabase(
    String entityType,
    String entityId,
    List<Map<String, dynamic>> thumbnails,
    bool replaceExisting,
  ) async {
    final db = await _databaseService.database;
    final now = DateTime.now().toIso8601String();

    final batch = db.batch();

    if (replaceExisting) {
      // Delete existing thumbnails for this entity
      batch.delete(
        'thumbnails',
        where: 'code_1c = ? AND entity_type = ?',
        whereArgs: [entityId, entityType],
      );
    }

    // Insert new thumbnails
    for (final thumbnail in thumbnails) {
      batch.insert('thumbnails', {
        'entity_type': entityType,
        'entity_id': thumbnail['entity_id'],
        'code_1c': entityId,
        'entity_name': thumbnail['entity_name'],
        'thumbnail_url': thumbnail['thumbnail_url'],
        'thumbnail_width': thumbnail['thumbnail_width'],
        'thumbnail_height': thumbnail['thumbnail_height'],
        'thumbnail_format': thumbnail['thumbnail_format'],
        'thumbnail_size_kb': thumbnail['thumbnail_size_kb'],
        'original_width': thumbnail['original_width'],
        'original_height': thumbnail['original_height'],
        'original_format': thumbnail['original_format'],
        'original_size_bytes': thumbnail['original_size_bytes'],
        'original_size_kb': thumbnail['original_size_kb'],
        'is_main': thumbnail['is_main'] ?? 0,
        'category': thumbnail['category'],
        'note': thumbnail['note'],
        'status_code': thumbnail['status_code'],
        'status_name': thumbnail['status_name'],
        'source_name': thumbnail['source_name'],
        'source_type': thumbnail['source_type'],
        'created_at_server': thumbnail['created_at_server'],
        'created_at': now,
        'updated_at': now,
      });
    }

    await batch.commit(noResult: true);
  }

  /// Fetch all images for a specific client and save to client_images table
  Future<void> fetchAndSaveClientImages(String clientCode, {bool replaceExisting = false}) async {
    try {
      if (kDebugMode) {
        print('ThumbnailImageService: Starting client image fetch for client: $clientCode');
      }

      _checkCancelled();
      onProgressUpdate?.call(0.0, 'Starting client image fetch...');

      // Ensure we have a valid token
      final token = await _tokenService.getValidAccessToken();
      if (token == null) {
        throw Exception('No valid access token available');
      }

      onProgressUpdate?.call(25.0, 'Fetching images from server...');

      // Fetch client images from API
      final images = await _fetchClientImagesFromApi(token, clientCode);

      onProgressUpdate?.call(75.0, 'Saving images to database...');

      if (images.isNotEmpty) {
        // Save images to database
        await _saveClientImagesToDatabase(clientCode, images, replaceExisting);
      }

      onProgressUpdate?.call(100.0, 'Client images saved successfully');

      if (kDebugMode) {
        print('ThumbnailImageService: Client image fetch completed for client: $clientCode');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ThumbnailImageService: Error in fetchAndSaveClientImages: $e');
      }
      onProgressUpdate?.call(0.0, 'Error: ${e.toString()}');
      rethrow;
    }
  }

  /// Fetch client images from API
  Future<List<Map<String, dynamic>>> _fetchClientImagesFromApi(String token, String clientCode) async {
    const String baseUrl = 'http://178.218.200.120:1596';
    final endpoint = '$baseUrl/api/v1/client-image/?client_code=$clientCode';
    final response = await _dio.get(
      endpoint,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('results')) {
        return List<Map<String, dynamic>>.from(data['results']);
      }
    }

    return [];
  }

  /// Save client images to database
  Future<void> _saveClientImagesToDatabase(
    String clientCode,
    List<Map<String, dynamic>> images,
    bool replaceExisting,
  ) async {
    final db = await _databaseService.database;
    final now = DateTime.now().toIso8601String();

    final batch = db.batch();

    if (replaceExisting) {
      // Delete existing images for this client
      batch.delete(
        'client_images',
        where: 'client_code = ?',
        whereArgs: [clientCode],
      );
    }

    // Insert new images
    for (final image in images) {
      batch.insert('client_images', {
        'client_code': clientCode,
        'image_url': image['image_url'],
        'image_sm_url': image['image_sm_url'],
        'image_md_url': image['image_md_url'],
        'image_lg_url': image['image_lg_url'],
        'image_thumbnail_url': image['image_thumbnail_url'],
        'image_dimensions': image['image_dimensions'],
        'image_sm_dimensions': image['image_sm_dimensions'],
        'image_md_dimensions': image['image_md_dimensions'],
        'image_lg_dimensions': image['image_lg_dimensions'],
        'image_thumbnail_dimensions': image['image_thumbnail_dimensions'],
        'is_main': image['is_main'] ?? 0,
        'category': image['category'],
        'note': image['note'],
        'status_code': image['status_code'],
        'status_name': image['status_name'],
        'source_name': image['source_name'],
        'source_type': image['source_type'],
        'created_at_server': image['created_at_server'],
        'created_at': now,
        'updated_at': now,
      });
    }

    await batch.commit(noResult: true);
  }

  /// Get client images from database
  Future<List<ClientImage>> getClientImages(String clientCode) async {
    final db = await _databaseService.database;
    final result = await db.query(
      'client_images',
      where: 'client_code = ?',
      whereArgs: [clientCode],
      orderBy: 'is_main DESC, created_at DESC',
    );

    return result.map((row) => ClientImage.fromMap(row)).toList();
  }

  /// Get main client image
  Future<ClientImage?> getMainClientImage(String clientCode) async {
    final db = await _databaseService.database;
    final result = await db.query(
      'client_images',
      where: 'client_code = ? AND is_main = 1',
      whereArgs: [clientCode],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ClientImage.fromMap(result.first);
  }

  /// Delete client images
  Future<void> deleteClientImages(String clientCode) async {
    final db = await _databaseService.database;
    await db.delete(
      'client_images',
      where: 'client_code = ?',
      whereArgs: [clientCode],
    );
  }

  /// Get thumbnail statistics
  Future<Map<String, int>> getThumbnailStats() async {
    final db = await _databaseService.database;

    final clientThumbnails = await db.rawQuery('SELECT COUNT(*) as count FROM thumbnails WHERE entity_type = "client"');
    final productThumbnails = await db.rawQuery('SELECT COUNT(*) as count FROM thumbnails WHERE entity_type = "product" OR entity_type = "nomenklatura"');
    final clientImages = await db.rawQuery('SELECT COUNT(*) as count FROM client_images');

    return {
      'client_thumbnails': Sqflite.firstIntValue(clientThumbnails) ?? 0,
      'product_thumbnails': Sqflite.firstIntValue(productThumbnails) ?? 0,
      'client_images': Sqflite.firstIntValue(clientImages) ?? 0,
    };
  }
}