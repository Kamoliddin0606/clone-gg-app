/// Media reference embedded in IMAGE / FILE / EMBED blocks. URLs are
/// fully qualified — render directly via `cached_network_image`.
class KnowledgeMedia {
  final String id;
  final String organizationId;
  final String? kind;
  final String? mimeType;
  final int? sizeBytes;
  final String? small;
  final String? medium;
  final String? large;
  final String? blurhash;
  final int? width;
  final int? height;
  final String? storageKey;
  final DateTime updatedAt;

  const KnowledgeMedia({
    required this.id,
    required this.organizationId,
    this.kind,
    this.mimeType,
    this.sizeBytes,
    this.small,
    this.medium,
    this.large,
    this.blurhash,
    this.width,
    this.height,
    this.storageKey,
    required this.updatedAt,
  });

  factory KnowledgeMedia.fromJson(Map<String, dynamic> json) {
    return KnowledgeMedia(
      id: json['id'] as String,
      organizationId: (json['organization_id'] as String?) ?? '',
      kind: json['kind'] as String?,
      mimeType: json['mime_type'] as String?,
      sizeBytes: json['size_bytes'] as int?,
      small: json['small'] as String?,
      medium: json['medium'] as String?,
      large: json['large'] as String?,
      blurhash: json['blurhash'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      storageKey: json['storage_key'] as String?,
      updatedAt: DateTime.tryParse((json['updated_at'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'organization_id': organizationId,
        'kind': kind,
        'mime_type': mimeType,
        'size_bytes': sizeBytes,
        'small_url': small,
        'medium_url': medium,
        'large_url': large,
        'blurhash': blurhash,
        'width': width,
        'height': height,
        'storage_key': storageKey,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory KnowledgeMedia.fromDbMap(Map<String, dynamic> row) {
    return KnowledgeMedia(
      id: row['id'] as String,
      organizationId: (row['organization_id'] as String?) ?? '',
      kind: row['kind'] as String?,
      mimeType: row['mime_type'] as String?,
      sizeBytes: row['size_bytes'] as int?,
      small: row['small_url'] as String?,
      medium: row['medium_url'] as String?,
      large: row['large_url'] as String?,
      blurhash: row['blurhash'] as String?,
      width: row['width'] as int?,
      height: row['height'] as int?,
      storageKey: row['storage_key'] as String?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (row['updated_at'] as int?) ?? 0),
    );
  }

  /// Best display URL for the requested size, falling back to whichever
  /// variant is available. Backend produces small/medium/large in
  /// parallel but during partial migrations only one may exist.
  String? bestUrlFor({String preferred = 'medium'}) {
    final ladder = switch (preferred) {
      'small' => [small, medium, large],
      'large' => [large, medium, small],
      _ => [medium, large, small],
    };
    for (final url in ladder) {
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }
}
