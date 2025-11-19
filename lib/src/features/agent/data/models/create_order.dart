/// Model for local order creation that will be sent to server via SetOrder API
class CreateOrder {
  final int? id;
  final String codeAgent;
  final String codeClient;
  final String codePrice;
  final String payment;
  final DateTime shippingDate;
  final String? commentSupervisor;
  final String? commentForwarder;
  final String? comment;
  final DateTime createDate;
  final double longitude;
  final double latitude;
  final double weight;
  final double capacity;
  final bool credit;
  final String codeProject;
  final int orderType;
  final String codeOrg;
  final String codeSklad;
  final String? codeContract;
  final bool hasPromo;
  final bool isSynced; // Track if order has been sent to server
  final DateTime? syncedAt;
  final String? syncError;

  // Related data
  final List<CreateOrderProduct> products;
  final List<CompetitiveIntelligence> competitiveIntelligence;
  final List<CreditDetail> creditDetails;

  const CreateOrder({
    this.id,
    required this.codeAgent,
    required this.codeClient,
    required this.codePrice,
    required this.payment,
    required this.shippingDate,
    this.commentSupervisor,
    this.commentForwarder,
    this.comment,
    required this.createDate,
    required this.longitude,
    required this.latitude,
    required this.weight,
    required this.capacity,
    required this.credit,
    required this.codeProject,
    required this.orderType,
    required this.codeOrg,
    required this.codeSklad,
    this.codeContract,
    required this.hasPromo,
    this.isSynced = false,
    this.syncedAt,
    this.syncError,
    this.products = const [],
    this.competitiveIntelligence = const [],
    this.creditDetails = const [],
  });

  factory CreateOrder.fromJson(Map<String, dynamic> json) {
    return CreateOrder(
      id: json['id'] as int?,
      codeAgent: json['codeAgent']?.toString() ?? '',
      codeClient: json['codeClient']?.toString() ?? '',
      codePrice: json['codePrice']?.toString() ?? '',
      payment: json['payment']?.toString() ?? '',
      shippingDate: DateTime.parse(json['shippingDate']?.toString() ?? DateTime.now().toIso8601String()),
      commentSupervisor: json['commentSupervisor']?.toString(),
      commentForwarder: json['commentForwarder']?.toString(),
      comment: json['comment']?.toString(),
      createDate: DateTime.parse(json['createDate']?.toString() ?? DateTime.now().toIso8601String()),
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      capacity: (json['capacity'] as num?)?.toDouble() ?? 0.0,
      credit: json['credit'] as bool? ?? false,
      codeProject: json['codeProject']?.toString() ?? '',
      orderType: (json['orderType'] as num?)?.toInt() ?? 0,
      codeOrg: json['codeOrg']?.toString() ?? '',
      codeSklad: json['codeSklad']?.toString() ?? '',
      codeContract: json['codeContract']?.toString(),
      hasPromo: json['hasPromo'] as bool? ?? false,
      isSynced: json['isSynced'] as bool? ?? false,
      syncedAt: json['syncedAt'] != null ? DateTime.parse(json['syncedAt'].toString()) : null,
      syncError: json['syncError']?.toString(),
      products: (json['products'] as List<dynamic>?)
          ?.map((e) => CreateOrderProduct.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      competitiveIntelligence: (json['competitiveIntelligence'] as List<dynamic>?)
          ?.map((e) => CompetitiveIntelligence.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      creditDetails: (json['creditDetails'] as List<dynamic>?)
          ?.map((e) => CreditDetail.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codeAgent': codeAgent,
      'codeClient': codeClient,
      'codePrice': codePrice,
      'payment': payment,
      'shippingDate': shippingDate.toIso8601String(),
      'commentSupervisor': commentSupervisor,
      'commentForwarder': commentForwarder,
      'comment': comment,
      'createDate': createDate.toIso8601String(),
      'longitude': longitude,
      'latitude': latitude,
      'weight': weight,
      'capacity': capacity,
      'credit': credit,
      'codeProject': codeProject,
      'orderType': orderType,
      'codeOrg': codeOrg,
      'codeSklad': codeSklad,
      'codeContract': codeContract,
      'hasPromo': hasPromo,
      'isSynced': isSynced,
      'syncedAt': syncedAt?.toIso8601String(),
      'syncError': syncError,
      'products': products.map((e) => e.toJson()).toList(),
      'competitiveIntelligence': competitiveIntelligence.map((e) => e.toJson()).toList(),
      'creditDetails': creditDetails.map((e) => e.toJson()).toList(),
    };
  }

  CreateOrder copyWith({
    int? id,
    String? codeAgent,
    String? codeClient,
    String? codePrice,
    String? payment,
    DateTime? shippingDate,
    String? commentSupervisor,
    String? commentForwarder,
    String? comment,
    DateTime? createDate,
    double? longitude,
    double? latitude,
    double? weight,
    double? capacity,
    bool? credit,
    String? codeProject,
    int? orderType,
    String? codeOrg,
    String? codeSklad,
    String? codeContract,
    bool? hasPromo,
    bool? isSynced,
    DateTime? syncedAt,
    String? syncError,
    List<CreateOrderProduct>? products,
    List<CompetitiveIntelligence>? competitiveIntelligence,
    List<CreditDetail>? creditDetails,
  }) {
    return CreateOrder(
      id: id ?? this.id,
      codeAgent: codeAgent ?? this.codeAgent,
      codeClient: codeClient ?? this.codeClient,
      codePrice: codePrice ?? this.codePrice,
      payment: payment ?? this.payment,
      shippingDate: shippingDate ?? this.shippingDate,
      commentSupervisor: commentSupervisor ?? this.commentSupervisor,
      commentForwarder: commentForwarder ?? this.commentForwarder,
      comment: comment ?? this.comment,
      createDate: createDate ?? this.createDate,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      weight: weight ?? this.weight,
      capacity: capacity ?? this.capacity,
      credit: credit ?? this.credit,
      codeProject: codeProject ?? this.codeProject,
      orderType: orderType ?? this.orderType,
      codeOrg: codeOrg ?? this.codeOrg,
      codeSklad: codeSklad ?? this.codeSklad,
      codeContract: codeContract ?? this.codeContract,
      hasPromo: hasPromo ?? this.hasPromo,
      isSynced: isSynced ?? this.isSynced,
      syncedAt: syncedAt ?? this.syncedAt,
      syncError: syncError ?? this.syncError,
      products: products ?? this.products,
      competitiveIntelligence: competitiveIntelligence ?? this.competitiveIntelligence,
      creditDetails: creditDetails ?? this.creditDetails,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateOrder &&
        other.id == id &&
        other.codeAgent == codeAgent &&
        other.codeClient == codeClient &&
        other.codePrice == codePrice &&
        other.payment == payment &&
        other.shippingDate == shippingDate &&
        other.commentSupervisor == commentSupervisor &&
        other.commentForwarder == commentForwarder &&
        other.comment == comment &&
        other.createDate == createDate &&
        other.longitude == longitude &&
        other.latitude == latitude &&
        other.weight == weight &&
        other.capacity == capacity &&
        other.credit == credit &&
        other.codeProject == codeProject &&
        other.orderType == orderType &&
        other.codeOrg == codeOrg &&
        other.codeSklad == codeSklad &&
        other.codeContract == codeContract &&
        other.hasPromo == hasPromo &&
        other.isSynced == isSynced &&
        other.syncedAt == syncedAt &&
        other.syncError == syncError &&
        other.products == products &&
        other.competitiveIntelligence == competitiveIntelligence &&
        other.creditDetails == creditDetails;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      codeAgent,
      codeClient,
      codePrice,
      payment,
      shippingDate,
      commentSupervisor,
      commentForwarder,
      comment,
      createDate,
      longitude,
      latitude,
      weight,
      capacity,
      credit,
      codeProject,
      orderType,
      codeOrg,
      codeSklad,
      codeContract,
    ) ^ Object.hash(
      hasPromo,
      isSynced,
      syncedAt,
      syncError,
      products,
      competitiveIntelligence,
      creditDetails,
    );
  }

  @override
  String toString() {
    return 'CreateOrder(id: $id, codeAgent: $codeAgent, codeClient: $codeClient, codePrice: $codePrice, payment: $payment, shippingDate: $shippingDate, commentSupervisor: $commentSupervisor, commentForwarder: $commentForwarder, comment: $comment, createDate: $createDate, longitude: $longitude, latitude: $latitude, weight: $weight, capacity: $capacity, credit: $credit, codeProject: $codeProject, orderType: $orderType, codeOrg: $codeOrg, codeSklad: $codeSklad, codeContract: $codeContract, hasPromo: $hasPromo, isSynced: $isSynced, syncedAt: $syncedAt, syncError: $syncError, products: $products, competitiveIntelligence: $competitiveIntelligence, creditDetails: $creditDetails)';
  }
}

/// Model for products in create order
class CreateOrderProduct {
  final int? id;
  final int? createOrderId; // Foreign key to create_order
  final String codeSklad;
  final String codeProduct;
  final int amount;
  final double price;
  final double total;
  final double weight;
  final double capacity;
  final int paymentType;
  final double discountSum;
  final double discountRate;
  final int giftAmount;
  final bool promo;
  final String vendorCode;

  const CreateOrderProduct({
    this.id,
    this.createOrderId,
    required this.codeSklad,
    required this.codeProduct,
    required this.amount,
    required this.price,
    required this.total,
    required this.weight,
    required this.capacity,
    required this.paymentType,
    required this.discountSum,
    required this.discountRate,
    required this.giftAmount,
    required this.promo,
    required this.vendorCode,
  });

  factory CreateOrderProduct.fromJson(Map<String, dynamic> json) {
    return CreateOrderProduct(
      id: json['id'] as int?,
      createOrderId: json['createOrderId'] as int?,
      codeSklad: json['codeSklad']?.toString() ?? '',
      codeProduct: json['codeProduct']?.toString() ?? '',
      vendorCode: json['vendorCode']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      capacity: (json['capacity'] as num?)?.toDouble() ?? 0.0,
      paymentType: (json['paymentType'] as num?)?.toInt() ?? 0,
      discountSum: (json['discountSum'] as num?)?.toDouble() ?? 0.0,
      discountRate: (json['discountRate'] as num?)?.toDouble() ?? 0.0,
      giftAmount: (json['giftAmount'] as num?)?.toInt() ?? 0,
      promo: json['promo'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createOrderId': createOrderId,
      'codeSklad': codeSklad,
      'codeProduct': codeProduct,
      'vendorCode': vendorCode,
      'amount': amount,
      'price': price,
      'total': total,
      'weight': weight,
      'capacity': capacity,
      'paymentType': paymentType,
      'discountSum': discountSum,
      'discountRate': discountRate,
      'giftAmount': giftAmount,
      'promo': promo,
    };
  }

  CreateOrderProduct copyWith({
    int? id,
    int? createOrderId,
    String? codeSklad,
    String? codeProduct,
    String? vendorCode,
    int? amount,
    double? price,
    double? total,
    double? weight,
    double? capacity,
    int? paymentType,
    double? discountSum,
    double? discountRate,
    int? giftAmount,
    bool? promo,
  }) {
    return CreateOrderProduct(
      id: id ?? this.id,
      createOrderId: createOrderId ?? this.createOrderId,
      codeSklad: codeSklad ?? this.codeSklad,
      codeProduct: codeProduct ?? this.codeProduct,
      vendorCode: vendorCode ?? this.vendorCode,
      amount: amount ?? this.amount,
      price: price ?? this.price,
      total: total ?? this.total,
      weight: weight ?? this.weight,
      capacity: capacity ?? this.capacity,
      paymentType: paymentType ?? this.paymentType,
      discountSum: discountSum ?? this.discountSum,
      discountRate: discountRate ?? this.discountRate,
      giftAmount: giftAmount ?? this.giftAmount,
      promo: promo ?? this.promo,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateOrderProduct &&
        other.id == id &&
        other.createOrderId == createOrderId &&
        other.codeSklad == codeSklad &&
        other.codeProduct == codeProduct &&
        other.vendorCode == vendorCode &&
        other.amount == amount &&
        other.price == price &&
        other.total == total &&
        other.weight == weight &&
        other.capacity == capacity &&
        other.paymentType == paymentType &&
        other.discountSum == discountSum &&
        other.discountRate == discountRate &&
        other.giftAmount == giftAmount &&
        other.promo == promo;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      createOrderId,
      codeSklad,
      codeProduct,
      vendorCode,
      amount,
      price,
      total,
      weight,
      capacity,
      paymentType,
      discountSum,
      discountRate,
      giftAmount,
      promo,
    );
  }

  @override
  String toString() {
    return 'CreateOrderProduct(id: $id, createOrderId: $createOrderId, codeSklad: $codeSklad, codeProduct: $codeProduct, vendorCode: $vendorCode, amount: $amount, price: $price, total: $total, weight: $weight, capacity: $capacity, paymentType: $paymentType, discountSum: $discountSum, discountRate: $discountRate, giftAmount: $giftAmount, promo: $promo)';
  }
}

/// Model for competitive intelligence data
class CompetitiveIntelligence {
  final int? id;
  final int? createOrderId; // Foreign key to create_order
  final String competitor;
  final String product;
  final double price;

  const CompetitiveIntelligence({
    this.id,
    this.createOrderId,
    required this.competitor,
    required this.product,
    required this.price,
  });

  factory CompetitiveIntelligence.fromJson(Map<String, dynamic> json) {
    return CompetitiveIntelligence(
      id: json['id'] as int?,
      createOrderId: json['createOrderId'] as int?,
      competitor: json['competitor']?.toString() ?? '',
      product: json['product']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createOrderId': createOrderId,
      'competitor': competitor,
      'product': product,
      'price': price,
    };
  }

  CompetitiveIntelligence copyWith({
    int? id,
    int? createOrderId,
    String? competitor,
    String? product,
    double? price,
  }) {
    return CompetitiveIntelligence(
      id: id ?? this.id,
      createOrderId: createOrderId ?? this.createOrderId,
      competitor: competitor ?? this.competitor,
      product: product ?? this.product,
      price: price ?? this.price,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompetitiveIntelligence &&
        other.id == id &&
        other.createOrderId == createOrderId &&
        other.competitor == competitor &&
        other.product == product &&
        other.price == price;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      createOrderId,
      competitor,
      product,
      price,
    );
  }

  @override
  String toString() {
    return 'CompetitiveIntelligence(id: $id, createOrderId: $createOrderId, competitor: $competitor, product: $product, price: $price)';
  }
}

/// Model for credit details (payment schedule)
class CreditDetail {
  final int? id;
  final int? createOrderId; // Foreign key to create_order
  final DateTime dateOfPayment;
  final double total;

  const CreditDetail({
    this.id,
    this.createOrderId,
    required this.dateOfPayment,
    required this.total,
  });

  factory CreditDetail.fromJson(Map<String, dynamic> json) {
    return CreditDetail(
      id: json['id'] as int?,
      createOrderId: json['createOrderId'] as int?,
      dateOfPayment: DateTime.parse(json['dateOfPayment']?.toString() ?? DateTime.now().toIso8601String()),
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createOrderId': createOrderId,
      'dateOfPayment': dateOfPayment.toIso8601String(),
      'total': total,
    };
  }

  CreditDetail copyWith({
    int? id,
    int? createOrderId,
    DateTime? dateOfPayment,
    double? total,
  }) {
    return CreditDetail(
      id: id ?? this.id,
      createOrderId: createOrderId ?? this.createOrderId,
      dateOfPayment: dateOfPayment ?? this.dateOfPayment,
      total: total ?? this.total,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreditDetail &&
        other.id == id &&
        other.createOrderId == createOrderId &&
        other.dateOfPayment == dateOfPayment &&
        other.total == total;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      createOrderId,
      dateOfPayment,
      total,
    );
  }

  @override
  String toString() {
    return 'CreditDetail(id: $id, createOrderId: $createOrderId, dateOfPayment: $dateOfPayment, total: $total)';
  }
}