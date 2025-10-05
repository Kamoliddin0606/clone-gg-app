class ProductBrand {
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductBrand({
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductBrand.fromMap(Map<String, dynamic> map) {
    return ProductBrand(
      name: map['name'] as String,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ProductBrand copyWith({
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductBrand(
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductBrand && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() {
    return 'ProductBrand(name: $name)';
  }
}