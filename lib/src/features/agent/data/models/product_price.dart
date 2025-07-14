class ProductPrice {
  final String productCode;
  final String priceTypeCode;
  final double price;
  final String currency;
  final String validFrom;
  final String validTo;

  const ProductPrice({
    required this.productCode,
    required this.priceTypeCode,
    required this.price,
    this.currency = 'UZS',
    this.validFrom = '',
    this.validTo = '',
  });

  factory ProductPrice.fromJson(Map<String, dynamic> json) {
    return ProductPrice(
      productCode: json['productCode']?.toString() ?? '',
      priceTypeCode: json['priceTypeCode']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'UZS',
      validFrom: json['validFrom']?.toString() ?? '',
      validTo: json['validTo']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productCode': productCode,
      'priceTypeCode': priceTypeCode,
      'price': price,
      'currency': currency,
      'validFrom': validFrom,
      'validTo': validTo,
    };
  }

  ProductPrice copyWith({
    String? productCode,
    String? priceTypeCode,
    double? price,
    String? currency,
    String? validFrom,
    String? validTo,
  }) {
    return ProductPrice(
      productCode: productCode ?? this.productCode,
      priceTypeCode: priceTypeCode ?? this.priceTypeCode,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductPrice &&
        other.productCode == productCode &&
        other.priceTypeCode == priceTypeCode &&
        other.price == price &&
        other.currency == currency &&
        other.validFrom == validFrom &&
        other.validTo == validTo;
  }

  @override
  int get hashCode {
    return Object.hash(productCode, priceTypeCode, price, currency, validFrom, validTo);
  }

  @override
  String toString() {
    return 'ProductPrice(productCode: $productCode, priceTypeCode: $priceTypeCode, price: $price, currency: $currency, validFrom: $validFrom, validTo: $validTo)';
  }
}