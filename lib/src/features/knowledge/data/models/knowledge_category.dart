class KnowledgeCategory {
  final String id;
  final String organizationId;
  final String? parentId;
  final String slug;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final String? coverMediaId;
  final int orderIdx;
  final bool isActive;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const KnowledgeCategory({
    required this.id,
    required this.organizationId,
    this.parentId,
    required this.slug,
    required this.name,
    this.description,
    this.icon,
    this.color,
    this.coverMediaId,
    this.orderIdx = 0,
    this.isActive = true,
    required this.updatedAt,
    this.deletedAt,
  });

  factory KnowledgeCategory.fromJson(Map<String, dynamic> json) {
    return KnowledgeCategory(
      id: json['id'] as String,
      organizationId: (json['organization_id'] as String?) ?? '',
      parentId: json['parent_id'] as String?,
      slug: (json['slug'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      coverMediaId: json['cover_media_id'] as String?,
      orderIdx: (json['order'] as int?) ?? (json['order_idx'] as int?) ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
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
        'parent_id': parentId,
        'slug': slug,
        'name': name,
        'description': description,
        'icon': icon,
        'color': color,
        'cover_media_id': coverMediaId,
        'order_idx': orderIdx,
        'is_active': isActive ? 1 : 0,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
      };

  factory KnowledgeCategory.fromDbMap(Map<String, dynamic> row) {
    return KnowledgeCategory(
      id: row['id'] as String,
      organizationId: (row['organization_id'] as String?) ?? '',
      parentId: row['parent_id'] as String?,
      slug: (row['slug'] as String?) ?? '',
      name: (row['name'] as String?) ?? '',
      description: row['description'] as String?,
      icon: row['icon'] as String?,
      color: row['color'] as String?,
      coverMediaId: row['cover_media_id'] as String?,
      orderIdx: (row['order_idx'] as int?) ?? 0,
      isActive: (row['is_active'] as int? ?? 1) == 1,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (row['updated_at'] as int?) ?? 0),
      deletedAt: row['deleted_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['deleted_at'] as int)
          : null,
    );
  }
}
