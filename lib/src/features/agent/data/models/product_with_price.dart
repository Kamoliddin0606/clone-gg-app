class ProductWithPrice {
  final String productCode;
  final String productName;
  final String unit;
  final double quantity;
  final double reserved;
  final double available;
  final String category;
  final String barcode;
  final int have;
  final String warehouseCode;
  final String warehouseName;
  final double weight;
  final double capacity;
  final String vendorCode;
  final String productBrand;
  final String productSeries;
  final String codeProject;
  final String priceTypeCode;
  final String priceTypeName;
  final double price;
  final String currency;
  final String validFrom;
  final String validTo;
  final int stock; // Available stock from product_balances

  const ProductWithPrice({
    required this.productCode,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.reserved,
    required this.available,
    required this.category,
    required this.barcode,
    required this.have,
    required this.warehouseCode,
    required this.warehouseName,
    required this.weight,
    required this.capacity,
    required this.vendorCode,
    required this.productBrand,
    required this.productSeries,
    required this.codeProject,
    required this.priceTypeCode,
    required this.priceTypeName,
    required this.price,
    required this.currency,
    required this.validFrom,
    required this.validTo,
    required this.stock,
  });

  factory ProductWithPrice.fromMap(Map<String, dynamic> map) {
    return ProductWithPrice(
      productCode: map['product_code'] as String,
      productName: map['product_name'] as String,
      unit: map['unit'] as String,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      reserved: (map['reserved'] as num?)?.toDouble() ?? 0.0,
      available: (map['available'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? '',
      barcode: map['barcode'] as String? ?? '',
      have: (map['have'] as int?) ?? 0,
      warehouseCode: map['warehouse_code'] as String? ?? '',
      warehouseName: map['warehouse_name'] as String? ?? '',
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      capacity: (map['capacity'] as num?)?.toDouble() ?? 0.0,
      vendorCode: map['vendor_code'] as String? ?? '',
      productBrand: map['product_brand'] as String? ?? '',
      productSeries: map['product_series'] as String? ?? '',
      codeProject: map['code_project'] as String? ?? '',
      priceTypeCode: map['price_type_code'] as String,
      priceTypeName: map['price_type_name'] as String,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'UZS',
      validFrom: map['valid_from'] as String? ?? '',
      validTo: map['valid_to'] as String? ?? '',
      stock: (map['stock'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_code': productCode,
      'product_name': productName,
      'unit': unit,
      'quantity': quantity,
      'reserved': reserved,
      'available': available,
      'category': category,
      'barcode': barcode,
      'have': have,
      'warehouse_code': warehouseCode,
      'warehouse_name': warehouseName,
      'weight': weight,
      'capacity': capacity,
      'vendor_code': vendorCode,
      'product_brand': productBrand,
      'product_series': productSeries,
      'code_project': codeProject,
      'price_type_code': priceTypeCode,
      'price_type_name': priceTypeName,
      'price': price,
      'currency': currency,
      'valid_from': validFrom,
      'valid_to': validTo,
      'stock': stock,
    };
  }

  ProductWithPrice copyWith({
    String? productCode,
    String? productName,
    String? unit,
    double? quantity,
    double? reserved,
    double? available,
    String? category,
    String? barcode,
    int? have,
    String? warehouseCode,
    String? warehouseName,
    double? weight,
    double? capacity,
    String? vendorCode,
    String? productBrand,
    String? productSeries,
    String? codeProject,
    String? priceTypeCode,
    String? priceTypeName,
    double? price,
    String? currency,
    String? validFrom,
    String? validTo,
    int? stock,
  }) {
    return ProductWithPrice(
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      reserved: reserved ?? this.reserved,
      available: available ?? this.available,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      have: have ?? this.have,
      warehouseCode: warehouseCode ?? this.warehouseCode,
      warehouseName: warehouseName ?? this.warehouseName,
      weight: weight ?? this.weight,
      capacity: capacity ?? this.capacity,
      vendorCode: vendorCode ?? this.vendorCode,
      productBrand: productBrand ?? this.productBrand,
      productSeries: productSeries ?? this.productSeries,
      codeProject: codeProject ?? this.codeProject,
      priceTypeCode: priceTypeCode ?? this.priceTypeCode,
      priceTypeName: priceTypeName ?? this.priceTypeName,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      stock: stock ?? this.stock,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductWithPrice &&
        other.productCode == productCode &&
        other.priceTypeCode == priceTypeCode;
  }

  @override
  int get hashCode => Object.hash(productCode, priceTypeCode);

  @override
  String toString() {
    return 'ProductWithPrice(productCode: $productCode, productName: $productName, priceTypeName: $priceTypeName, price: $price, stock: $stock, warehouseCode: $warehouseCode)';
  }
}