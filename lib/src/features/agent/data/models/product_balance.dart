class ProductBalance {
  final String codeSklad;
  final String codeProduct;
  final String nameProduct;
  final int have;
  final int reserved;
  final int available;
  final double weight;
  final double capacity;
  final String codeProject;
  final String vendorCode;
  final String productBrand;
  final String productSeries;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductBalance({
    required this.codeSklad,
    required this.codeProduct,
    required this.nameProduct,
    required this.have,
    required this.reserved,
    required this.available,
    required this.weight,
    required this.capacity,
    required this.codeProject,
    required this.vendorCode,
    required this.productBrand,
    required this.productSeries,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductBalance.fromMap(Map<String, dynamic> map) {
    return ProductBalance(
      codeSklad: map['code_sklad'] as String,
      codeProduct: map['code_product'] as String,
      nameProduct: map['name_product'] as String,
      have: map['have'] as int,
      reserved: map['reserved'] as int,
      available: map['available'] as int,
      weight: map['weight'] as double,
      capacity: map['capacity'] as double,
      codeProject: map['code_project'] as String,
      vendorCode: map['vendor_code'] as String,
      productBrand: map['product_brand'] as String,
      productSeries: map['product_series'] as String,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code_sklad': codeSklad,
      'code_product': codeProduct,
      'name_product': nameProduct,
      'have': have,
      'reserved': reserved,
      'available': available,
      'weight': weight,
      'capacity': capacity,
      'code_project': codeProject,
      'vendor_code': vendorCode,
      'product_brand': productBrand,
      'product_series': productSeries,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ProductBalance copyWith({
    String? codeSklad,
    String? codeProduct,
    String? nameProduct,
    int? have,
    int? reserved,
    int? available,
    double? weight,
    double? capacity,
    String? codeProject,
    String? vendorCode,
    String? productBrand,
    String? productSeries,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductBalance(
      codeSklad: codeSklad ?? this.codeSklad,
      codeProduct: codeProduct ?? this.codeProduct,
      nameProduct: nameProduct ?? this.nameProduct,
      have: have ?? this.have,
      reserved: reserved ?? this.reserved,
      available: available ?? this.available,
      weight: weight ?? this.weight,
      capacity: capacity ?? this.capacity,
      codeProject: codeProject ?? this.codeProject,
      vendorCode: vendorCode ?? this.vendorCode,
      productBrand: productBrand ?? this.productBrand,
      productSeries: productSeries ?? this.productSeries,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductBalance &&
        other.codeSklad == codeSklad &&
        other.codeProduct == codeProduct &&
        other.nameProduct == nameProduct &&
        other.have == have &&
        other.reserved == reserved &&
        other.available == available &&
        other.weight == weight &&
        other.capacity == capacity &&
        other.codeProject == codeProject &&
        other.vendorCode == vendorCode &&
        other.productBrand == productBrand &&
        other.productSeries == productSeries;
  }

  @override
  int get hashCode {
    return Object.hash(
      codeSklad,
      codeProduct,
      nameProduct,
      have,
      reserved,
      available,
      weight,
      capacity,
      codeProject,
      vendorCode,
      productBrand,
      productSeries,
    );
  }

  @override
  String toString() {
    return 'ProductBalance(codeSklad: $codeSklad, codeProduct: $codeProduct, nameProduct: $nameProduct, have: $have, reserved: $reserved, available: $available, weight: $weight, capacity: $capacity, codeProject: $codeProject, vendorCode: $vendorCode, productBrand: $productBrand, productSeries: $productSeries)';
  }
}