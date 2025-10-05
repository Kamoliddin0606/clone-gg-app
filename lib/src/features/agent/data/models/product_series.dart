class ProductSeries {
  final String name;
  final String brandName; // Foreign key to ProductBrand
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductSeries({
    required this.name,
    required this.brandName,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductSeries.fromMap(Map<String, dynamic> map) {
    return ProductSeries(
      name: map['name'] as String,
      brandName: map['brand_name'] as String,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand_name': brandName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ProductSeries copyWith({
    String? name,
    String? brandName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductSeries(
      name: name ?? this.name,
      brandName: brandName ?? this.brandName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductSeries && other.name == name && other.brandName == brandName;
  }

  @override
  int get hashCode => Object.hash(name, brandName);

  @override
  String toString() {
    return 'ProductSeries(name: $name, brandName: $brandName)';
  }
}