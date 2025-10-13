

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
}

