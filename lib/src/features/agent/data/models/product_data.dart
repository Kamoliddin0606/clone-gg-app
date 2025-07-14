class ProductData {
  final String code;
  final String name;
  final String unit;
  final double quantity;
  final double reserved;
  final double available;
  final String category;
  final String barcode;
  final int have;
  final String warehouseCode;
  final double weight;
  final double capacity;
  final String vendorCode;
  final String productBrand;
  final String productSeries;
  final String codeProject;

  const ProductData({
    required this.code,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.reserved,
    required this.available,
    required this.category,
    required this.barcode,
    required this.have,
    required this.warehouseCode,
    required this.weight,
    required this.capacity,
    required this.vendorCode,
    required this.productBrand,
    required this.productSeries,
    required this.codeProject,
  });

  factory ProductData.fromJson(Map<String, dynamic> json) {
    return ProductData(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      reserved: (json['reserved'] as num?)?.toDouble() ?? 0.0,
      available: (json['available'] as num?)?.toDouble() ?? 0.0,
      category: json['category']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      have: (json['have'] as num?)?.toInt() ?? 0,
      warehouseCode: json['warehouseCode']?.toString() ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      capacity: (json['capacity'] as num?)?.toDouble() ?? 0.0,
      vendorCode: json['vendorCode']?.toString() ?? '',
      productBrand: json['productBrand']?.toString() ?? '',
      productSeries: json['productSeries']?.toString() ?? '',
      codeProject: json['codeProject']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'unit': unit,
      'quantity': quantity,
      'reserved': reserved,
      'available': available,
      'category': category,
      'barcode': barcode,
      'have': have,
      'warehouseCode': warehouseCode,
      'weight': weight,
      'capacity': capacity,
      'vendorCode': vendorCode,
      'productBrand': productBrand,
      'productSeries': productSeries,
      'codeProject': codeProject,
    };
  }

  ProductData copyWith({
    String? code,
    String? name,
    String? unit,
    double? quantity,
    double? reserved,
    double? available,
    String? category,
    String? barcode,
    int? have,
    String? warehouseCode,
    double? weight,
    double? capacity,
    String? vendorCode,
    String? productBrand,
    String? productSeries,
    String? codeProject,
  }) {
    return ProductData(
      code: code ?? this.code,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      reserved: reserved ?? this.reserved,
      available: available ?? this.available,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      have: have ?? this.have,
      warehouseCode: warehouseCode ?? this.warehouseCode,
      weight: weight ?? this.weight,
      capacity: capacity ?? this.capacity,
      vendorCode: vendorCode ?? this.vendorCode,
      productBrand: productBrand ?? this.productBrand,
      productSeries: productSeries ?? this.productSeries,
      codeProject: codeProject ?? this.codeProject,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductData &&
        other.code == code &&
        other.name == name &&
        other.unit == unit &&
        other.quantity == quantity &&
        other.reserved == reserved &&
        other.available == available &&
        other.category == category &&
        other.barcode == barcode &&
        other.have == have &&
        other.warehouseCode == warehouseCode &&
        other.weight == weight &&
        other.capacity == capacity &&
        other.vendorCode == vendorCode &&
        other.productBrand == productBrand &&
        other.productSeries == productSeries &&
        other.codeProject == codeProject;
  }

  @override
  int get hashCode {
    return Object.hash(
      code, name, unit, quantity, reserved, available, category, barcode,
      have, warehouseCode, weight, capacity, vendorCode, productBrand,
      productSeries, codeProject
    );
  }

  @override
  String toString() {
    return 'ProductData(code: $code, name: $name, unit: $unit, quantity: $quantity, reserved: $reserved, available: $available, category: $category, barcode: $barcode, have: $have, warehouseCode: $warehouseCode, weight: $weight, capacity: $capacity, vendorCode: $vendorCode, productBrand: $productBrand, productSeries: $productSeries, codeProject: $codeProject)';
  }
}