class OrderItem {
  final String productName;
  final String article;
  final double quantity;
  final double price;
  final String priceTypeCode;
  final String? priceTypeName;
  final double? lineTotal;

  const OrderItem({
    required this.productName,
    required this.article,
    required this.quantity,
    required this.price,
    required this.priceTypeCode,
    this.priceTypeName,
    this.lineTotal,
  });

  /// Calculated total: price × quantity
  double get calculatedTotal => quantity * price;

  /// Actual sum from server or calculated
  double get sum => lineTotal ?? calculatedTotal;

  /// Check if calculated total matches the line total from server
  bool get hasTotalMismatch =>
      lineTotal != null && (lineTotal! - calculatedTotal).abs() > 0.01;

  /// Display name for price type with fallback logic:
  /// 1. priceTypeName if available
  /// 2. "Bonus" if price is 0
  /// 3. priceTypeCode as fallback
  String get priceTypeDisplayName {
    if (priceTypeName != null && priceTypeName!.isNotEmpty) {
      return priceTypeName!;
    }
    if (price == 0) {
      return 'Bonus';
    }
    return priceTypeCode.isNotEmpty ? priceTypeCode : '-';
  }

  /// Legacy getter for backward compatibility
  String get priceType => priceTypeCode;
}

class OrderModel {
  final int? id;
  final String numOrder;
  final DateTime dateOrder;
  final String captionOrder;
  final String typePriceCode;
  final int status;
  final String? commentSupervisor;
  final String? commentForwarder;
  final String? commentAgent;
  final DateTime? shippingDate;
  final double total;
  final String clientCode;
  final String clientName;
  final String codeOrg;
  final String? organizationName;
  final String mainStatus;
  final String? courierName;
  final String? courierCar;
  final String? courierPlate;
  final List<OrderItem> items;
  final bool promo;
  const OrderModel({
    required this.id,
    required this.numOrder,
    required this.dateOrder,
    required this.captionOrder,
    required this.typePriceCode,
    required this.status,
    this.commentSupervisor,
    this.commentForwarder,
    this.commentAgent,
    this.shippingDate,
    required this.total,
    required this.clientCode,
    required this.clientName,
    required this.codeOrg,
    this.organizationName,
    required this.mainStatus,
    this.courierName,
    this.courierCar,
    this.courierPlate,
    this.items = const [],
    this.promo = false,
  });

  OrderModel copyWith({
    int? id,
    String? numOrder,
    DateTime? dateOrder,
    String? captionOrder,
    String? typePriceCode,
    int? status,
    String? commentSupervisor,
    String? commentForwarder,
    String? commentAgent,
    DateTime? shippingDate,
    double? total,
    String? clientCode,
    String? clientName,
    String? codeOrg,
    String? organizationName,
    String? mainStatus,
    String? courierName,
    String? courierCar,
    String? courierPlate,
    List<OrderItem>? items,
    bool? promo,
  }) {
    return OrderModel(
      id: id ?? this.id,
      numOrder: numOrder ?? this.numOrder,
      dateOrder: dateOrder ?? this.dateOrder,
      captionOrder: captionOrder ?? this.captionOrder,
      typePriceCode: typePriceCode ?? this.typePriceCode,
      status: status ?? this.status,
      commentSupervisor: commentSupervisor ?? this.commentSupervisor,
      commentForwarder: commentForwarder ?? this.commentForwarder,
      commentAgent: commentAgent ?? this.commentAgent,
      shippingDate: shippingDate ?? this.shippingDate,
      total: total ?? this.total,
      clientCode: clientCode ?? this.clientCode,
      clientName: clientName ?? this.clientName,
      codeOrg: codeOrg ?? this.codeOrg,
      organizationName: organizationName ?? this.organizationName,
      mainStatus: mainStatus ?? this.mainStatus,
      courierName: courierName ?? this.courierName,
      courierCar: courierCar ?? this.courierCar,
      courierPlate: courierPlate ?? this.courierPlate,
      items: items ?? this.items,
      promo: promo ?? this.promo,
    );
  }
}
