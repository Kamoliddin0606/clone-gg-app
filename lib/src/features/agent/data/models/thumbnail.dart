/// Model for thumbnail data from REST API
/// Represents image thumbnails for clients and products (nomenklatura)
class Thumbnail {
  final int? id;
  final String? entityType; // 'client' or 'nomenklatura' - can be null in DB
  final int? entityId; // ID from API - can be null in DB
  final String code1c; // Linking field (clients.code or products.code) - required
  final String? entityName; // can be null in DB
  final int imageId;
  final String? thumbnailUrl; // can be null in DB
  final Map<String, dynamic>? thumbnailDimensions; // JSON: {width, height, format, size} - can be null in DB
  final Map<String, dynamic>? originalDimensions; // JSON: {width, height, format, size_bytes, size} - can be null in DB
  final bool isMain;
  final String? category;
  final String? note;
  final String? statusCode;
  final String? statusName;
  final String? sourceName;
  final String? sourceType;
  final DateTime? createdAt; // can be null in DB
  final DateTime? updatedAt;

  // Foreign keys (populated when saving)
  final int? clientId; // FK to clients.id
  final int? productId; // FK to products.id

  const Thumbnail({
    this.id,
    this.entityType,
    this.entityId,
    required this.code1c,
    this.entityName,
    this.imageId = 0,
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
    this.updatedAt,
    this.clientId,
    this.productId,
  });

  factory Thumbnail.fromJson(Map<String, dynamic> json) {
    return Thumbnail(
      id: json['id'] as int?,
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as int?,
      code1c: json['code_1c'] as String,
      entityName: json['entity_name'] as String?,
      imageId: json['image_id'] as int? ?? 0,
      thumbnailUrl: json['thumbnail_url'] as String?,
      thumbnailDimensions: json['thumbnail_dimensions'] as Map<String, dynamic>?,
      originalDimensions: json['original_dimensions'] as Map<String, dynamic>?,
      isMain: json['is_main'] as bool? ?? false,
      category: json['category'] as String?,
      note: json['note'] as String?,
      statusCode: json['status_code'] as String?,
      statusName: json['status_name'] as String?,
      sourceName: json['source_name'] as String?,
      sourceType: json['source_type'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      clientId: json['client_id'] as int?,
      productId: json['product_id'] as int?,
    );
  }

  /// Factory constructor for database row maps
  /// Safely maps DB fields to model with casting, null checks, and defaults
  /// Updated to parse image_id field from database for server-side image tracking
  factory Thumbnail.fromMap(Map<String, dynamic> map) {
    return Thumbnail(
      id: _parseInt(map['id']),
      entityType: map['entity_type'] as String? ?? 'unknown',
      entityId: _parseInt(map['entity_id']),
      code1c: map['code_1c'] as String? ?? '',
      entityName: map['entity_name'] as String? ?? '',
      imageId: _parseInt(map['image_id'], 0), // Parse image_id from database field, default to 0 if null
      thumbnailUrl: map['thumbnail_url'] as String? ?? '',
      thumbnailDimensions: _parseThumbnailDimensions(map),
      originalDimensions: _parseOriginalDimensions(map),
      isMain: _parseBool(map['is_main']),
      category: map['category'] as String?,
      note: map['note'] as String?,
      statusCode: map['status_code'] as String? ?? '',
      statusName: map['status_name'] as String? ?? '',
      sourceName: map['source_name'] as String? ?? '',
      sourceType: map['source_type'] as String? ?? '',
      createdAt: _parseDateTime(map['created_at_server']),
      updatedAt: map['updated_at'] != null ? _parseDateTime(map['updated_at']) : null,
      clientId: null, // Set when linking to clients table if needed
      productId: null, // Set when linking to products table if needed
    );
  }

  // Safe parsing helpers
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
      'created_at': createdAt?.toIso8601String(),
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