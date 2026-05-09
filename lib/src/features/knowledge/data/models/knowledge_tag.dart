class KnowledgeTag {
  final String id;
  final String organizationId;
  final String? slug;
  final String? name;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const KnowledgeTag({
    required this.id,
    required this.organizationId,
    this.slug,
    this.name,
    required this.updatedAt,
    this.deletedAt,
  });

  factory KnowledgeTag.fromJson(Map<String, dynamic> json) {
    return KnowledgeTag(
      id: json['id'] as String,
      organizationId: (json['organization_id'] as String?) ?? '',
      slug: json['slug'] as String?,
      name: json['name'] as String?,
      updatedAt: DateTime.tryParse((json['updated_at'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'organization_id': organizationId,
        'slug': slug,
        'name': name,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
      };

  factory KnowledgeTag.fromDbMap(Map<String, dynamic> row) {
    return KnowledgeTag(
      id: row['id'] as String,
      organizationId: (row['organization_id'] as String?) ?? '',
      slug: row['slug'] as String?,
      name: row['name'] as String?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (row['updated_at'] as int?) ?? 0),
      deletedAt: row['deleted_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['deleted_at'] as int)
          : null,
    );
  }
}
