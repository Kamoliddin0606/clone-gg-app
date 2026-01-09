import 'package:equatable/equatable.dart';

/// Model class for product images from REST API (nomenklatura-image)
/// 
/// This model represents image data for products fetched from the media server.
/// It mirrors the NomenklaturaImage API response structure and is stored
/// in the local database for offline access.
/// 
/// API Endpoint: GET /api/v1/nomenklatura-image/
/// Filter by: nomenklatura (product code_1c), is_main, category
class ProductImage extends Equatable {
  final int? id;
  final int? serverId;
  final String productCode;
  final int? nomenklaturaId;
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
  final String? createdAtServer;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductImage({
    this.id,
    this.serverId,
    required this.productCode,
    this.nomenklaturaId,
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
    this.createdAtServer,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ProductImage from API response map
  factory ProductImage.fromApiResponse(Map<String, dynamic> map, String productCode) {
    final now = DateTime.now();
    
    // Parse dimensions - can be object or string
    String? parseDimensions(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is Map) return '${value['width'] ?? 0}x${value['height'] ?? 0}';
      return value.toString();
    }

    return ProductImage(
      serverId: map['id'] as int?,
      productCode: productCode,
      nomenklaturaId: map['nomenklatura'] as int?,
      image: map['image'] as String?,
      imageUrl: map['image_url'] as String?,
      imageSmUrl: map['image_sm_url'] as String?,
      imageMdUrl: map['image_md_url'] as String?,
      imageLgUrl: map['image_lg_url'] as String?,
      imageThumbnailUrl: map['image_thumbnail_url'] as String?,
      imageDimensions: parseDimensions(map['image_dimensions']),
      imageSmDimensions: parseDimensions(map['image_sm_dimensions']),
      imageMdDimensions: parseDimensions(map['image_md_dimensions']),
      imageLgDimensions: parseDimensions(map['image_lg_dimensions']),
      imageThumbnailDimensions: parseDimensions(map['image_thumbnail_dimensions']),
      isMain: map['is_main'] == true,
      category: map['category'] as String?,
      note: map['note'] as String?,
      status: map['status'] as String?,
      source: map['source'] as String?,
      createdAtServer: map['created_at'] as String?,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create ProductImage from database row
  factory ProductImage.fromMap(Map<String, dynamic> map) {
    return ProductImage(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      productCode: map['product_code'] as String,
      nomenklaturaId: map['nomenklatura_id'] as int?,
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
      createdAtServer: map['created_at_server'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert to database map for insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'product_code': productCode,
      'nomenklatura_id': nomenklaturaId,
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
      'created_at_server': createdAtServer,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get the best available image URL (prefer thumbnail for lists)
  String? get thumbnailOrBestUrl {
    return imageThumbnailUrl ?? imageSmUrl ?? imageMdUrl ?? imageLgUrl ?? imageUrl ?? image;
  }

  /// Get the best quality image URL (prefer large for detail views)
  String? get bestQualityUrl {
    return imageLgUrl ?? imageMdUrl ?? imageSmUrl ?? imageUrl ?? image ?? imageThumbnailUrl;
  }

  ProductImage copyWith({
    int? id,
    int? serverId,
    String? productCode,
    int? nomenklaturaId,
    String? image,
    String? imageUrl,
    String? imageSmUrl,
    String? imageMdUrl,
    String? imageLgUrl,
    String? imageThumbnailUrl,
    String? imageDimensions,
    String? imageSmDimensions,
    String? imageMdDimensions,
    String? imageLgDimensions,
    String? imageThumbnailDimensions,
    bool? isMain,
    String? category,
    String? note,
    String? status,
    String? source,
    String? createdAtServer,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductImage(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      productCode: productCode ?? this.productCode,
      nomenklaturaId: nomenklaturaId ?? this.nomenklaturaId,
      image: image ?? this.image,
      imageUrl: imageUrl ?? this.imageUrl,
      imageSmUrl: imageSmUrl ?? this.imageSmUrl,
      imageMdUrl: imageMdUrl ?? this.imageMdUrl,
      imageLgUrl: imageLgUrl ?? this.imageLgUrl,
      imageThumbnailUrl: imageThumbnailUrl ?? this.imageThumbnailUrl,
      imageDimensions: imageDimensions ?? this.imageDimensions,
      imageSmDimensions: imageSmDimensions ?? this.imageSmDimensions,
      imageMdDimensions: imageMdDimensions ?? this.imageMdDimensions,
      imageLgDimensions: imageLgDimensions ?? this.imageLgDimensions,
      imageThumbnailDimensions: imageThumbnailDimensions ?? this.imageThumbnailDimensions,
      isMain: isMain ?? this.isMain,
      category: category ?? this.category,
      note: note ?? this.note,
      status: status ?? this.status,
      source: source ?? this.source,
      createdAtServer: createdAtServer ?? this.createdAtServer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        serverId,
        productCode,
        nomenklaturaId,
        image,
        imageUrl,
        imageSmUrl,
        imageMdUrl,
        imageLgUrl,
        imageThumbnailUrl,
        isMain,
        category,
        note,
        status,
        source,
        createdAtServer,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'ProductImage(id: $id, serverId: $serverId, productCode: $productCode, isMain: $isMain)';
  }
}
