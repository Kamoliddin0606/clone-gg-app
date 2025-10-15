

class OrderItem {
  final String productName;
  final String article;
  final double quantity;
  final double price;
  final String priceType;
  const OrderItem({
    required this.productName,
    required this.article,
    required this.quantity,
    required this.price,
    required this.priceType,
  });
  double get sum => quantity * price;
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
  final double total;
  final String clientCode;
  final String clientName;
  final String codeOrg;
  final String mainStatus;
  final String? courierName;
  final String? courierCar;
  final String? courierPlate;
  final List<OrderItem> items;
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
    required this.total,
    required this.clientCode,
    required this.clientName,
    required this.codeOrg,
    required this.mainStatus,
    this.courierName,
    this.courierCar,
    this.courierPlate,
    this.items = const [],
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
    double? total,
    String? clientCode,
    String? clientName,
    String? codeOrg,
    String? mainStatus,
    String? courierName,
    String? courierCar,
    String? courierPlate,
    List<OrderItem>? items,
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
      total: total ?? this.total,
      clientCode: clientCode ?? this.clientCode,
      clientName: clientName ?? this.clientName,
      codeOrg: codeOrg ?? this.codeOrg,
      mainStatus: mainStatus ?? this.mainStatus,
      courierName: courierName ?? this.courierName,
      courierCar: courierCar ?? this.courierCar,
      courierPlate: courierPlate ?? this.courierPlate,
      items: items ?? this.items,
    );
  }
}

