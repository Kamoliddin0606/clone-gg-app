import 'api_database_service.dart';
import '../../features/agent/data/models/thumbnail.dart';

class RestApiDatabaseService {
  final ApiDatabaseService _apiDb;

  RestApiDatabaseService(this._apiDb);

  Future<void> saveThumbnails(List<Thumbnail> thumbnails) async {
    return;
  }

  Future<List<Thumbnail>> getAllThumbnails() async {
    return <Thumbnail>[];
  }

  Future<List<Thumbnail>> getThumbnailsByCode(String code1c) async {
    return <Thumbnail>[];
  }

  Future<Map<String, int>> getThumbnailsStatistics() async {
    return <String, int>{
      'thumbnails': 0,
    };
  }

  Map<String, dynamic> convertThumbnailToMap(Thumbnail thumbnail) {
    return {
      'entity_type': thumbnail.entityType,
      'entity_id': thumbnail.entityId,
      'code_1c': thumbnail.code1c,
      'entity_name': thumbnail.entityName,
      'image_id': thumbnail.imageId,
      'thumbnail_url': thumbnail.thumbnailUrl,
      'thumbnail_dimensions': thumbnail.thumbnailDimensions,
      'original_dimensions': thumbnail.originalDimensions,
      'is_main': thumbnail.isMain ? 1 : 0,
      'category': thumbnail.category,
      'note': thumbnail.note,
      'status_code': thumbnail.statusCode,
      'status_name': thumbnail.statusName,
      'source_name': thumbnail.sourceName,
      'source_type': thumbnail.sourceType,
      'created_at': thumbnail.createdAt,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}