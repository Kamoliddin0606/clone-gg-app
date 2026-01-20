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
  final int? serverId;
  final String clientCode;
  final int? clientId;
  final String? image;
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
  final String? status;
  final String? source;
  final String? statusCode;
  final String? statusName;
  final String? sourceName;
  final String? sourceType;
  final String? createdAtServer;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClientImage({
    this.id,
    this.serverId,
    required this.clientCode,
    this.clientId,
    this.image,
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
    this.status,
    this.source,
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
      'server_id': serverId,
      'client_code': clientCode,
      'client_id': clientId,
      'image': image,
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
      'status': status,
      'source': source,
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
      serverId: map['server_id'] as int?,
      clientCode: map['client_code'] as String,
      clientId: map['client_id'] as int?,
      image: map['image'] as String?,
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
      status: map['status'] as String?,
      source: map['source'] as String?,
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

/// Service class for managing client image operations
class ClientImagesService {
  final ApiDatabaseService _databaseService;
  final RestApiService _apiService;
  final TokenService _tokenService;
  final Dio _dio;

  ClientImagesService({
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

  /// Fetch client images metadata from server and save to database
  /// 
  /// This method only fetches and stores image metadata (URLs, dimensions, etc.)
  /// without downloading actual image files. Images are loaded on-demand by UI.
  /// 
  /// Flow:
  /// 1. Get valid authentication token
  /// 2. Fetch metadata from server API
  /// 3. Save metadata to local database
  /// 4. UI loads images on-demand using CachedNetworkImage
  Future<void> fetchAndSaveClientImages(String? clientCode, {bool? replaceExisting = false}) async {
    try {
      if (clientCode == null || clientCode.trim().isEmpty) {
        return;
      }

      if (kDebugMode) {
        print('ClientImagesService: Fetching metadata for client: $clientCode');
        print('ClientImagesService: Client code length: ${clientCode.length}');
        print('ClientImagesService: Client code bytes: ${clientCode.codeUnits}');
      }

      _checkCancelled();
      onProgressUpdate?.call(0.0, 'Starting metadata fetch...');

      // Ensure we have a valid token using the full authentication flow:
      // 1. Check access token validity
      // 2. Refresh if expired
      // 3. Re-authenticate if refresh fails
      final token = await _tokenService.ensureValidToken();
      if (token == null || token.trim().isEmpty) {
        if (kDebugMode) {
          print('ClientImagesService: Failed to obtain valid token');
        }
        throw Exception('Autentifikatsiya muddati tugadi. Iltimos, qayta kiring.');
      }

      onProgressUpdate?.call(30.0, 'Fetching metadata from server...');

      // Fetch client images metadata from API (filtered by client)
      final images = await _apiService.getClientImages(
        authToken: token,
        clientCode: clientCode,
      );

      onProgressUpdate?.call(70.0, 'Saving metadata to database...');

      if (images.isNotEmpty) {
        // Save only metadata to database (no image downloads)
        await _saveClientImagesToDatabase(clientCode, images, replaceExisting == true);
      }

      onProgressUpdate?.call(100.0, 'Metadata saved successfully');

      if (kDebugMode) {
        print('ClientImagesService: Saved ${images.length} image metadata records for client: $clientCode');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ClientImagesService: Error in fetchAndSaveClientImages: $e');
      }
      onProgressUpdate?.call(0.0, 'Error: ${e.toString()}');
      rethrow;
    }
  }

  /// Fetch client images from API
  Future<List<Map<String, dynamic>>> _fetchClientImagesFromApi(String token, String clientCode) async {
    const String baseUrl = 'http://178.218.200.120:1596';
    final endpoint = '$baseUrl/api/v1/client-image/';
    final response = await _dio.get(
      endpoint,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
      queryParameters: {
        'client_code_1c': clientCode,
      },
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

  /// Save client images metadata to database
  /// 
  /// Stores only metadata (URLs, dimensions, flags) without downloading images.
  /// Actual images are loaded on-demand by UI components.
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

    String? normalizeJson(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      try {
        return jsonEncode(value);
      } catch (_) {
        return value.toString();
      }
    }

    int normalizeIsMain(dynamic value) {
      if (value is bool) return value ? 1 : 0;
      if (value is num) return value.toInt() == 1 ? 1 : 0;
      if (value is String) {
        final lower = value.toLowerCase();
        if (lower == 'true' || lower == '1') return 1;
      }
      return 0;
    }

    final mainCandidate = images.cast<Map<String, dynamic>?>().firstWhere(
          (img) => img != null && normalizeIsMain(img['is_main']) == 1,
          orElse: () => null,
        );
    final int? mainServerId = mainCandidate == null ? null : (mainCandidate['id'] as num?)?.toInt();

    if (!replaceExisting && mainServerId != null) {
      batch.update(
        'client_images',
        {
          'is_main': 0,
          'updated_at': now,
        },
        where: 'client_code = ?',
        whereArgs: [clientCode],
      );
    }

    // Insert new image metadata (URLs only, no file downloads)
    for (final image in images) {
      final int? serverId = (image['id'] as num?)?.toInt();
      batch.insert('client_images', {
        'server_id': serverId,
        'client_code': clientCode,
        'client_id': image['client'],
        'image': image['image'],  // Server URL
        'image_url': image['image_url'],  // Server URL
        'image_sm_url': image['image_sm_url'],  // Server URL
        'image_md_url': image['image_md_url'],  // Server URL
        'image_lg_url': image['image_lg_url'],  // Server URL
        'image_thumbnail_url': image['image_thumbnail_url'],  // Server URL
        'image_dimensions': normalizeJson(image['image_dimensions']),
        'image_sm_dimensions': normalizeJson(image['image_sm_dimensions']),
        'image_md_dimensions': normalizeJson(image['image_md_dimensions']),
        'image_lg_dimensions': normalizeJson(image['image_lg_dimensions']),
        'image_thumbnail_dimensions': normalizeJson(image['image_thumbnail_dimensions']),
        'is_main': (mainServerId != null && serverId == mainServerId) ? 1 : normalizeIsMain(image['is_main']),
        'category': image['category'],
        'note': image['note'],
        'status': image['status'],
        'source': image['source'],
        'status_code': image['status_code'],
        'status_name': image['status_name'],
        'source_name': image['source_name'],
        'source_type': image['source_type'],
        'created_at_server': image['created_at'] ?? image['created_at_server'],
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  /// Get client images from database
  Future<List<ClientImage>> getClientImages(String? clientCode) async {
    if (clientCode == null || clientCode.trim().isEmpty) {
      return <ClientImage>[];
    }
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
  Future<ClientImage?> getMainClientImage(String? clientCode) async {
    if (clientCode == null || clientCode.trim().isEmpty) {
      return null;
    }
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

  /// Delete a single client image from both server and local database
  ///
  /// This method:
  /// 1. Validates the image has a valid server ID
  /// 2. Obtains a valid authentication token
  /// 3. Deletes the image from the server via REST API
  /// 4. Deletes the image from local database
  /// 5. Clears locally cached image files
  ///
  /// @param image The ClientImage object to delete
  /// @return Future<bool> True if deletion was successful
  /// @throws Exception on authentication or server errors
  Future<bool> deleteClientImageFromServer(ClientImage image) async {
    try {
      // Validate server ID
      if (image.serverId == null) {
        throw Exception('Rasmning server ID si mavjud emas');
      }

      if (kDebugMode) {
        print('ClientImagesService: Deleting image with server ID: ${image.serverId}');
        print('ClientImagesService: Client code: ${image.clientCode}');
      }

      // Get valid token using full authentication flow
      final token = await _tokenService.ensureValidToken();
      if (token == null || token.trim().isEmpty) {
        throw Exception('Autentifikatsiya muddati tugadi. Iltimos, qayta kiring.');
      }

      // Delete from server
      final success = await _apiService.deleteClientImage(
        authToken: token,
        imageId: image.serverId!,
      );

      if (!success) {
        throw Exception('Serverdan rasmni o\'chirishda xatolik');
      }

      // Delete from local database
      final db = await _databaseService.database;
      await db.delete(
        'client_images',
        where: 'server_id = ?',
        whereArgs: [image.serverId],
      );

      if (kDebugMode) {
        print('ClientImagesService: Successfully deleted image ID: ${image.serverId}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('ClientImagesService: Error deleting image: $e');
      }
      rethrow;
    }
  }

  /// Delete all client images for a client
  Future<void> deleteClientImages(String? clientCode) async {
    if (clientCode == null || clientCode.trim().isEmpty) {
      return;
    }
    final db = await _databaseService.database;
    await db.delete(
      'client_images',
      where: 'client_code = ?',
      whereArgs: [clientCode],
    );
  }

  /// Set a client image as the main image
  ///
  /// This method:
  /// 1. Validates that the image has a valid server ID
  /// 2. Gets a valid authentication token
  /// 3. Calls the server API to set the image as main (PATCH /api/v1/client-image/{id}/)
  /// 4. On success, updates the local database:
  ///    - Removes is_main flag from all other images of the same client
  ///    - Sets is_main flag on the selected image
  ///
  /// @param image The ClientImage to set as main
  /// @return Future<bool> True if operation was successful on both server and local
  /// @throws Exception if server operation fails or token is invalid
  Future<bool> setClientImageAsMain(ClientImage image) async {
    // Validate server ID
    if (image.serverId == null || image.serverId! <= 0) {
      if (kDebugMode) {
        print('ClientImagesService: Cannot set as main - no valid server ID');
      }
      throw Exception('Rasm serverda mavjud emas. Avval serverga yuklang.');
    }

    // Already main - no action needed
    if (image.isMain) {
      if (kDebugMode) {
        print('ClientImagesService: Image is already main, no action needed');
      }
      return true;
    }

    try {
      if (kDebugMode) {
        print('ClientImagesService: Setting image as main, serverId=${image.serverId}');
      }

      // Get valid token
      final token = await _tokenService.getValidAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Avtorizatsiya tokeni topilmadi. Qayta tizimga kiring.');
      }

      // Call server API to set as main
      final success = await _apiService.setClientImageAsMain(
        authToken: token,
        imageServerId: image.serverId!,
      );

      if (!success) {
        throw Exception('Serverda rasmni asosiy qilib belgilashda xatolik');
      }

      // Server success - now update local database
      final db = await _databaseService.database;

      // Start a transaction to ensure atomicity
      await db.transaction((txn) async {
        // 1. Remove is_main flag from all images of this client
        await txn.update(
          'client_images',
          {'is_main': 0},
          where: 'client_code = ?',
          whereArgs: [image.clientCode],
        );

        // 2. Set is_main flag on the selected image
        await txn.update(
          'client_images',
          {'is_main': 1},
          where: 'server_id = ?',
          whereArgs: [image.serverId],
        );
      });

      if (kDebugMode) {
        print('ClientImagesService: Successfully set image as main (serverId=${image.serverId})');
        print('ClientImagesService: Updated local database for client: ${image.clientCode}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('ClientImagesService: Error setting image as main: $e');
      }
      rethrow;
    }
  }

  /// Get client images statistics
  Future<Map<String, int>> getClientImagesStats() async {
    final db = await _databaseService.database;
    final clientImages = await db.rawQuery('SELECT COUNT(*) as count FROM client_images');

    return {
      'client_images': Sqflite.firstIntValue(clientImages) ?? 0,
    };
  }
}

class ThumbnailImageService extends ClientImagesService {
  ThumbnailImageService({
    required ApiDatabaseService databaseService,
    required RestApiService apiService,
    required TokenService tokenService,
    required Dio dio,
  }) : super(
          databaseService: databaseService,
          apiService: apiService,
          tokenService: tokenService,
          dio: dio,
        );

  Future<void> updateClientThumbnails(String? clientCode) async {
    if (clientCode == null || clientCode.trim().isEmpty) return;
    return fetchAndSaveClientImages(clientCode);
  }

  Future<void> fetchAndUpdateThumbnails({
    required String? entityType,
    required List<String>? entityIds,
    bool replaceExisting = false,
  }) async {
    return;
  }

  Future<Map<String, int>> getThumbnailStats() => getClientImagesStats();
}