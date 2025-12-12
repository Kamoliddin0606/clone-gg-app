/// Model for thumbnail data from REST API
/// Represents image thumbnails for clients and products (nomenklatura)
class Thumbnail {
  final int? id;
  final String entityType; // 'client' or 'nomenklatura'
  final int entityId; // ID from API
  final String code1c; // Linking field (clients.code or products.code)
  final String entityName;
  final int imageId;
  final String thumbnailUrl;
  final Map<String, dynamic> thumbnailDimensions; // JSON: {width, height, format, size}
  final Map<String, dynamic> originalDimensions; // JSON: {width, height, format, size_bytes, size}
  final bool isMain;
  final String? category;
  final String? note;
  final String statusCode;
  final String statusName;
  final String sourceName;
  final String sourceType;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Foreign keys (populated when saving)
  final int? clientId; // FK to clients.id
  final int? productId; // FK to products.id

  const Thumbnail({
    this.id,
    required this.entityType,
    required this.entityId,
    required this.code1c,
    required this.entityName,
    required this.imageId,
    required this.thumbnailUrl,
    required this.thumbnailDimensions,
    required this.originalDimensions,
    required this.isMain,
    this.category,
    this.note,
    required this.statusCode,
    required this.statusName,
    required this.sourceName,
    required this.sourceType,
    required this.createdAt,
    this.updatedAt,
    this.clientId,
    this.productId,
  });

  factory Thumbnail.fromJson(Map<String, dynamic> json) {
    return Thumbnail(
      id: json['id'] as int?,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as int,
      code1c: json['code_1c'] as String,
      entityName: json['entity_name'] as String,
      imageId: json['image_id'] as int,
      thumbnailUrl: json['thumbnail_url'] as String,
      thumbnailDimensions: json['thumbnail_dimensions'] as Map<String, dynamic>,
      originalDimensions: json['original_dimensions'] as Map<String, dynamic>,
      isMain: json['is_main'] as bool,
      category: json['category'] as String?,
      note: json['note'] as String?,
      statusCode: json['status_code'] as String,
      statusName: json['status_name'] as String,
      sourceName: json['source_name'] as String,
      sourceType: json['source_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      clientId: json['client_id'] as int?,
      productId: json['product_id'] as int?,
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'client_id': clientId,
      'product_id': productId,
    };
  }

  Thumbnail copyWith({
    int? id,
    String? entityType,
    int? entityId,
    String? code1c,
    String? entityName,
    int? imageId,
    String? thumbnailUrl,
    Map<String, dynamic>? thumbnailDimensions,
    Map<String, dynamic>? originalDimensions,
    bool? isMain,
    String? category,
    String? note,
    String? statusCode,
    String? statusName,
    String? sourceName,
    String? sourceType,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? clientId,
    int? productId,
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
      updatedAt: updatedAt ?? this.updatedAt,
      clientId: clientId ?? this.clientId,
      productId: productId ?? this.productId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Thumbnail &&
        other.id == id &&
        other.entityType == entityType &&
        other.entityId == entityId &&
        other.code1c == code1c &&
        other.entityName == entityName &&
        other.imageId == imageId &&
        other.thumbnailUrl == thumbnailUrl &&
        other.thumbnailDimensions == thumbnailDimensions &&
        other.originalDimensions == originalDimensions &&
        other.isMain == isMain &&
        other.category == category &&
        other.note == note &&
        other.statusCode == statusCode &&
        other.statusName == statusName &&
        other.sourceName == sourceName &&
        other.sourceType == sourceType &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.clientId == clientId &&
        other.productId == productId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      entityType,
      entityId,
      code1c,
      entityName,
      imageId,
      thumbnailUrl,
      thumbnailDimensions,
      originalDimensions,
      isMain,
      category,
      note,
      statusCode,
      statusName,
      sourceName,
      sourceType,
      createdAt,
      updatedAt,
      clientId,
      productId,
    );
  }

  @override
  String toString() {
    return 'Thumbnail(id: $id, entityType: $entityType, entityId: $entityId, code1c: $code1c, entityName: $entityName, imageId: $imageId, thumbnailUrl: $thumbnailUrl, isMain: $isMain, statusCode: $statusCode, statusName: $statusName, clientId: $clientId, productId: $productId)';
  }
}