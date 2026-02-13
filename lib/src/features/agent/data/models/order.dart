class Order {
  final int? id;
  final String numOrder;
  final DateTime dateOrder;
  final String captionOrder;
  final String typePriceCode;
  final int status;
  final String? commentSupervisor;
  final String? commentForwarder;
  final String? commentAgent;
  final double total;
  final String clientCode;
  final String clientName;
  final String codeOrg;
  final String mainStatus;
  final String? courierName;
  final String? courierCar;
  final DateTime? shippingDate;
  final bool
  server; // true for server-sourced data, false for local unsent orders
  final bool promo; // true if order is promotional

  const Order({
    this.id,
    required this.numOrder,
    required this.dateOrder,
    required this.captionOrder,
    required this.typePriceCode,
    required this.status,
    this.commentSupervisor,
    this.commentForwarder,
    this.commentAgent,
    required this.total,
    required this.clientCode,
    required this.clientName,
    required this.codeOrg,
    required this.mainStatus,
    this.courierName,
    this.courierCar,
    this.shippingDate,
    this.server = false, // Default to false for local orders
    this.promo = false, // Default to false for non-promotional orders
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int?,
      numOrder: json['numOrder']?.toString() ?? '',
      dateOrder: DateTime.parse(
        json['dateOrder']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      captionOrder: json['captionOrder']?.toString() ?? '',
      typePriceCode: json['typePriceCode']?.toString() ?? '',
      status: (json['status'] as num?)?.toInt() ?? 0,
      commentSupervisor: json['commentSupervisor']?.toString(),
      commentForwarder: json['commentForwarder']?.toString(),
      commentAgent: json['commentAgent']?.toString(),
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      clientCode: json['clientCode']?.toString() ?? '',
      clientName: json['clientName']?.toString() ?? '',
      codeOrg: json['codeOrg']?.toString() ?? '',
      mainStatus: json['mainStatus']?.toString() ?? '',
      courierName: json['courierName']?.toString(),
      courierCar: json['courierCar']?.toString(),
      shippingDate: json['shippingDate'] != null
          ? DateTime.tryParse(json['shippingDate'].toString())
          : null,
      server: json['server'] as bool? ?? false,
      promo: json['promo'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numOrder': numOrder,
      'dateOrder': dateOrder.toIso8601String(),
      'captionOrder': captionOrder,
      'typePriceCode': typePriceCode,
      'status': status,
      'commentSupervisor': commentSupervisor,
      'commentForwarder': commentForwarder,
      'commentAgent': commentAgent,
      'total': total,
      'clientCode': clientCode,
      'clientName': clientName,
      'codeOrg': codeOrg,
      'mainStatus': mainStatus,
      'courierName': courierName,
      'courierCar': courierCar,
      'shippingDate': shippingDate?.toIso8601String(),
      'server': server,
      'promo': promo,
    };
  }

  Order copyWith({
    int? id,
    String? numOrder,
    DateTime? dateOrder,
    String? captionOrder,
    String? typePriceCode,
    int? status,
    String? commentSupervisor,
    String? commentForwarder,
    String? commentAgent,
    double? total,
    String? clientCode,
    String? clientName,
    String? codeOrg,
    String? mainStatus,
    String? courierName,
    String? courierCar,
    DateTime? shippingDate,
    bool? server,
    bool? promo,
  }) {
    return Order(
      id: id ?? this.id,
      numOrder: numOrder ?? this.numOrder,
      dateOrder: dateOrder ?? this.dateOrder,
      captionOrder: captionOrder ?? this.captionOrder,
      typePriceCode: typePriceCode ?? this.typePriceCode,
      status: status ?? this.status,
      commentSupervisor: commentSupervisor ?? this.commentSupervisor,
      commentForwarder: commentForwarder ?? this.commentForwarder,
      commentAgent: commentAgent ?? this.commentAgent,
      total: total ?? this.total,
      clientCode: clientCode ?? this.clientCode,
      clientName: clientName ?? this.clientName,
      codeOrg: codeOrg ?? this.codeOrg,
      mainStatus: mainStatus ?? this.mainStatus,
      courierName: courierName ?? this.courierName,
      courierCar: courierCar ?? this.courierCar,
      shippingDate: shippingDate ?? this.shippingDate,
      server: server ?? this.server,
      promo: promo ?? this.promo,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order &&
        other.id == id &&
        other.numOrder == numOrder &&
        other.dateOrder == dateOrder &&
        other.captionOrder == captionOrder &&
        other.typePriceCode == typePriceCode &&
        other.status == status &&
        other.commentSupervisor == commentSupervisor &&
        other.commentForwarder == commentForwarder &&
        other.commentAgent == commentAgent &&
        other.total == total &&
        other.clientCode == clientCode &&
        other.clientName == clientName &&
        other.codeOrg == codeOrg &&
        other.mainStatus == mainStatus &&
        other.courierName == courierName &&
        other.courierCar == courierCar &&
        other.shippingDate == shippingDate &&
        other.server == server &&
        other.promo == promo;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      numOrder,
      dateOrder,
      captionOrder,
      typePriceCode,
      status,
      commentSupervisor,
      commentForwarder,
      commentAgent,
      total,
      clientCode,
      clientName,
      codeOrg,
      mainStatus,
      courierName,
      courierCar,
      shippingDate,
      server,
      promo,
    );
  }

  @override
  String toString() {
    return 'Order(id: $id, numOrder: $numOrder, dateOrder: $dateOrder, captionOrder: $captionOrder, typePriceCode: $typePriceCode, status: $status, commentSupervisor: $commentSupervisor, commentForwarder: $commentForwarder, commentAgent: $commentAgent, total: $total, clientCode: $clientCode, clientName: $clientName, codeOrg: $codeOrg, mainStatus: $mainStatus, courierName: $courierName, courierCar: $courierCar, shippingDate: $shippingDate, server: $server, promo: $promo)';
  }
}
