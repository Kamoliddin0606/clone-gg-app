class OrderDetail {
  final int? id;
  final String numOrder;
  final bool credit;
  final String codePrice;
  final DateTime dateOrder;
  final String codeSklad;
  final String? commentSupervisor;
  final String? commentForwarder;
  final String? commentAgent;
  final String shippingDate;
  final int orderType;
  final String codeOrg;
  final List<OrderDetailProduct> productRows;
  final List<OrderPayment> creditDetailsList;

  const OrderDetail({
    this.id,
    required this.numOrder,
    required this.credit,
    required this.codePrice,
    required this.dateOrder,
    required this.codeSklad,
    this.commentSupervisor,
    this.commentForwarder,
    this.commentAgent,
    required this.shippingDate,
    required this.orderType,
    required this.codeOrg,
    required this.productRows,
    required this.creditDetailsList,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'] as int?,
      numOrder: json['numOrder']?.toString() ?? '',
      credit: json['credit'] as bool? ?? false,
      codePrice: json['codePrice']?.toString() ?? '',
      dateOrder: DateTime.parse(json['dateOrder']?.toString() ?? DateTime.now().toIso8601String()),
      codeSklad: json['codeSklad']?.toString() ?? '',
      commentSupervisor: json['commentSupervisor']?.toString(),
      commentForwarder: json['commentForwarder']?.toString(),
      commentAgent: json['commentAgent']?.toString(),
      shippingDate: json['shippingDate']?.toString() ?? '',
      orderType: (json['orderType'] as num?)?.toInt() ?? 0,
      codeOrg: json['codeOrg']?.toString() ?? '',
      productRows: (json['productRows'] as List<dynamic>?)
          ?.map((e) => OrderDetailProduct.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      creditDetailsList: (json['creditDetailsList'] as List<dynamic>?)
          ?.map((e) => OrderPayment.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numOrder': numOrder,
      'credit': credit,
      'codePrice': codePrice,
      'dateOrder': dateOrder.toIso8601String(),
      'codeSklad': codeSklad,
      'commentSupervisor': commentSupervisor,
      'commentForwarder': commentForwarder,
      'commentAgent': commentAgent,
      'shippingDate': shippingDate,
      'orderType': orderType,
      'codeOrg': codeOrg,
      'productRows': productRows.map((e) => e.toJson()).toList(),
      'creditDetailsList': creditDetailsList.map((e) => e.toJson()).toList(),
    };
  }

  OrderDetail copyWith({
    int? id,
    String? numOrder,
    bool? credit,
    String? codePrice,
    DateTime? dateOrder,
    String? codeSklad,
    String? commentSupervisor,
    String? commentForwarder,
    String? commentAgent,
    String? shippingDate,
    int? orderType,
    String? codeOrg,
    List<OrderDetailProduct>? productRows,
    List<OrderPayment>? creditDetailsList,
  }) {
    return OrderDetail(
      id: id ?? this.id,
      numOrder: numOrder ?? this.numOrder,
      credit: credit ?? this.credit,
      codePrice: codePrice ?? this.codePrice,
      dateOrder: dateOrder ?? this.dateOrder,
      codeSklad: codeSklad ?? this.codeSklad,
      commentSupervisor: commentSupervisor ?? this.commentSupervisor,
      commentForwarder: commentForwarder ?? this.commentForwarder,
      commentAgent: commentAgent ?? this.commentAgent,
      shippingDate: shippingDate ?? this.shippingDate,
      orderType: orderType ?? this.orderType,
      codeOrg: codeOrg ?? this.codeOrg,
      productRows: productRows ?? this.productRows,
      creditDetailsList: creditDetailsList ?? this.creditDetailsList,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderDetail &&
        other.id == id &&
        other.numOrder == numOrder &&
        other.credit == credit &&
        other.codePrice == codePrice &&
        other.dateOrder == dateOrder &&
        other.codeSklad == codeSklad &&
        other.commentSupervisor == commentSupervisor &&
        other.commentForwarder == commentForwarder &&
        other.commentAgent == commentAgent &&
        other.shippingDate == shippingDate &&
        other.orderType == orderType &&
        other.codeOrg == codeOrg &&
        other.productRows == productRows &&
        other.creditDetailsList == creditDetailsList;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      numOrder,
      credit,
      codePrice,
      dateOrder,
      codeSklad,
      commentSupervisor,
      commentForwarder,
      commentAgent,
      shippingDate,
      orderType,
      codeOrg,
      productRows,
      creditDetailsList,
    );
  }

  @override
  String toString() {
    return 'OrderDetail(id: $id, numOrder: $numOrder, credit: $credit, codePrice: $codePrice, dateOrder: $dateOrder, codeSklad: $codeSklad, commentSupervisor: $commentSupervisor, commentForwarder: $commentForwarder, commentAgent: $commentAgent, shippingDate: $shippingDate, orderType: $orderType, codeOrg: $codeOrg, productRows: $productRows, creditDetailsList: $creditDetailsList)';
  }
}

class OrderDetailProduct {
  final int? id;
  final String codeProduct;
  final String nameProduct;
  final int amount;
  final double price;
  final double total;
  final double discountRate;
  final double weight;
  final double capacity;

  const OrderDetailProduct({
    this.id,
    required this.codeProduct,
    required this.nameProduct,
    required this.amount,
    required this.price,
    required this.total,
    required this.discountRate,
    required this.weight,
    required this.capacity,
  });

  factory OrderDetailProduct.fromJson(Map<String, dynamic> json) {
    return OrderDetailProduct(
      id: json['id'] as int?,
      codeProduct: json['codeProduct']?.toString() ?? '',
      nameProduct: json['nameProduct']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      discountRate: (json['discountRate'] as num?)?.toDouble() ?? 0.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      capacity: (json['capacity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codeProduct': codeProduct,
      'nameProduct': nameProduct,
      'amount': amount,
      'price': price,
      'total': total,
      'discountRate': discountRate,
      'weight': weight,
      'capacity': capacity,
    };
  }

  OrderDetailProduct copyWith({
    int? id,
    String? codeProduct,
    String? nameProduct,
    int? amount,
    double? price,
    double? total,
    double? discountRate,
    double? weight,
    double? capacity,
  }) {
    return OrderDetailProduct(
      id: id ?? this.id,
      codeProduct: codeProduct ?? this.codeProduct,
      nameProduct: nameProduct ?? this.nameProduct,
      amount: amount ?? this.amount,
      price: price ?? this.price,
      total: total ?? this.total,
      discountRate: discountRate ?? this.discountRate,
      weight: weight ?? this.weight,
      capacity: capacity ?? this.capacity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderDetailProduct &&
        other.id == id &&
        other.codeProduct == codeProduct &&
        other.nameProduct == nameProduct &&
        other.amount == amount &&
        other.price == price &&
        other.total == total &&
        other.discountRate == discountRate &&
        other.weight == weight &&
        other.capacity == capacity;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      codeProduct,
      nameProduct,
      amount,
      price,
      total,
      discountRate,
      weight,
      capacity,
    );
  }

  @override
  String toString() {
    return 'OrderDetailProduct(id: $id, codeProduct: $codeProduct, nameProduct: $nameProduct, amount: $amount, price: $price, total: $total, discountRate: $discountRate, weight: $weight, capacity: $capacity)';
  }
}

class OrderPayment {
  final int? id;
  final String dateOfPayment;
  final double total;

  const OrderPayment({
    this.id,
    required this.dateOfPayment,
    required this.total,
  });

  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    return OrderPayment(
      id: json['id'] as int?,
      dateOfPayment: json['dateOfPayment']?.toString() ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateOfPayment': dateOfPayment,
      'total': total,
    };
  }

  OrderPayment copyWith({
    int? id,
    String? dateOfPayment,
    double? total,
  }) {
    return OrderPayment(
      id: id ?? this.id,
      dateOfPayment: dateOfPayment ?? this.dateOfPayment,
      total: total ?? this.total,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderPayment &&
        other.id == id &&
        other.dateOfPayment == dateOfPayment &&
        other.total == total;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      dateOfPayment,
      total,
    );
  }

  @override
  String toString() {
    return 'OrderPayment(id: $id, dateOfPayment: $dateOfPayment, total: $total)';
  }
}