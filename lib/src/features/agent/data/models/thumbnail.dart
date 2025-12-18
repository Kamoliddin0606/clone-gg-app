class Thumbnail {
  final int? id;
  final String? entityType;
  final int? entityId;
  final String? code1c;
  final String? entityName;
  final int? imageId;
  final String? thumbnailUrl;
  final String? thumbnailDimensions;
  final String? originalDimensions;
  final bool isMain;
  final String? category;
  final String? note;
  final String? statusCode;
  final String? statusName;
  final String? sourceName;
  final String? sourceType;
  final dynamic createdAt;

  const Thumbnail({
    this.id,
    this.entityType,
    this.entityId,
    this.code1c,
    this.entityName,
    this.imageId,
    this.thumbnailUrl,
    this.thumbnailDimensions,
    this.originalDimensions,
    this.isMain = false,
    this.category,
    this.note,
    this.statusCode,
    this.statusName,
    this.sourceName,
    this.sourceType,
    this.createdAt,
  });

  factory Thumbnail.fromMap(Map<String, dynamic> map) {
    return Thumbnail(
      id: (map['id'] as num?)?.toInt(),
      entityType: map['entity_type'] as String?,
      entityId: (map['entity_id'] as num?)?.toInt(),
      code1c: map['code_1c'] as String?,
      entityName: map['entity_name'] as String?,
      imageId: (map['image_id'] as num?)?.toInt(),
      thumbnailUrl: map['thumbnail_url'] as String?,
      thumbnailDimensions: map['thumbnail_dimensions'] as String?,
      originalDimensions: map['original_dimensions'] as String?,
      isMain: (map['is_main'] as num?)?.toInt() == 1,
      category: map['category'] as String?,
      note: map['note'] as String?,
      statusCode: map['status_code'] as String?,
      statusName: map['status_name'] as String?,
      sourceName: map['source_name'] as String?,
      sourceType: map['source_type'] as String?,
      createdAt: map['created_at'],
    );
  }

  Thumbnail copyWith({
    int? id,
    String? entityType,
    int? entityId,
    String? code1c,
    String? entityName,
    int? imageId,
    String? thumbnailUrl,
    String? thumbnailDimensions,
    String? originalDimensions,
    bool? isMain,
    String? category,
    String? note,
    String? statusCode,
    String? statusName,
    String? sourceName,
    String? sourceType,
    dynamic createdAt,
  }) {
    return Thumbnail(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      code1c: code1c ?? this.code1c,
      entityName: entityName ?? this.entityName,
      imageId: imageId ?? this.imageId,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      thumbnailDimensions: thumbnailDimensions ?? this.thumbnailDimensions,
      originalDimensions: originalDimensions ?? this.originalDimensions,
      isMain: isMain ?? this.isMain,
      category: category ?? this.category,
      note: note ?? this.note,
      statusCode: statusCode ?? this.statusCode,
      statusName: statusName ?? this.statusName,
      sourceName: sourceName ?? this.sourceName,
      sourceType: sourceType ?? this.sourceType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'code_1c': code1c,
      'entity_name': entityName,
      'image_id': imageId,
      'thumbnail_url': thumbnailUrl,
      'thumbnail_dimensions': thumbnailDimensions,
      'original_dimensions': originalDimensions,
      'is_main': isMain,
      'category': category,
      'note': note,
      'status_code': statusCode,
      'status_name': statusName,
      'source_name': sourceName,
      'source_type': sourceType,
      'created_at': createdAt,
    };
  }
}