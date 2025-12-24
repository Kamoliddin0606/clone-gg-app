import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'api_database_service.dart';
import 'rest_api_service.dart';
import 'token_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/client_image_storage_service.dart';

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
  final ClientImageStorageService _clientImageStorageService;

  ClientImagesService({
    required ApiDatabaseService databaseService,
    required RestApiService apiService,
    required TokenService tokenService,
    required Dio dio,
    ClientImageStorageService? clientImageStorageService,
  })  : _databaseService = databaseService,
        _apiService = apiService,
        _tokenService = tokenService,
        _dio = dio,
        _clientImageStorageService = clientImageStorageService ?? ClientImageStorageService();

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

  Future<List<Map<String, dynamic>>> _cacheImagesLocally({
    required String clientCode,
    required List<Map<String, dynamic>> images,
  }) async {
    final out = <Map<String, dynamic>>[];

    for (final image in images) {
      String? pickUrl(Map<String, dynamic> img) {
        final candidates = <dynamic>[
          img['image_thumbnail_url'],
          img['image_sm_url'],
          img['image_md_url'],
          img['image_lg_url'],
          img['image_url'],
          img['image'],
        ];
        for (final c in candidates) {
          if (c is String && c.trim().isNotEmpty) return c;
        }
        return null;
      }

      final url = pickUrl(image);
      if (url == null) {
        out.add(image);
        continue;
      }

      try {
        final resp = await _dio.get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        final bytes = resp.data;
        if (bytes == null || bytes.isEmpty) {
          out.add(image);
          continue;
        }

        final tmpDir = await Directory.systemTemp.createTemp('client_img_');
        final tmpFile = File('${tmpDir.path}/img_${DateTime.now().microsecondsSinceEpoch}.jpg');
        await tmpFile.writeAsBytes(bytes, flush: true);

        final saved = await _clientImageStorageService.saveClientImage(
          clientCode: clientCode,
          imageFile: tmpFile,
          description: 'Client image',
        );

        out.add({
          ...image,
          // Store local paths so UI can render offline
          'image': saved['imagePath'],
          'image_thumbnail_url': saved['previewPath'],
        });
      } catch (_) {
        out.add(image);
      }
    }

    return out;
  }

  /// Fetch all images for a specific client and save to client_images table
  Future<void> fetchAndSaveClientImages(String? clientCode, {bool? replaceExisting = false}) async {
    try {
      if (clientCode == null || clientCode.trim().isEmpty) {
        return;
      }

      if (kDebugMode) {
        print('ClientImagesService: Starting client image fetch for client: $clientCode');
      }

      _checkCancelled();
      onProgressUpdate?.call(0.0, 'Starting client image fetch...');

      // Ensure we have a valid token using the full authentication flow:
      // 1. Check access token validity
      // 2. Refresh if expired
      // 3. Re-authenticate if refresh fails
      final token = await _tokenService.ensureValidToken();
      if (token == null || token.trim().isEmpty) {
        if (kDebugMode) {
          print('ClientImagesService: Failed to obtain valid token after all attempts');
        }
        throw Exception('Autentifikatsiya muddati tugadi. Iltimos, qayta kiring.');
      }

      onProgressUpdate?.call(25.0, 'Fetching images from server...');

      // Fetch client images from API (filtered by client)
      final images = await _apiService.getClientImages(
        authToken: token,
        clientCode: clientCode,
      );

      // Always clear existing locally cached images for this client before saving new ones
      await _clientImageStorageService.clearClientImages(clientCode);

      final cachedImages = await _cacheImagesLocally(
        clientCode: clientCode,
        images: images,
      );

      onProgressUpdate?.call(75.0, 'Saving images to database...');

      if (cachedImages.isNotEmpty) {
        // Save images to database
        await _saveClientImagesToDatabase(clientCode, cachedImages, replaceExisting == true);
      }

      onProgressUpdate?.call(100.0, 'Client images saved successfully');

      if (kDebugMode) {
        print('ClientImagesService: Client image fetch completed for client: $clientCode');
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

    // Insert new images
    for (final image in images) {
      final int? serverId = (image['id'] as num?)?.toInt();
      batch.insert('client_images', {
        'server_id': serverId,
        'client_code': clientCode,
        'client_id': image['client'],
        'image': image['image'],
        'image_url': image['image_url'],
        'image_sm_url': image['image_sm_url'],
        'image_md_url': image['image_md_url'],
        'image_lg_url': image['image_lg_url'],
        'image_thumbnail_url': image['image_thumbnail_url'],
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

  /// Delete client images
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