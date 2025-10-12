class OrderStatus {
  final int? id;
  final String message;

  const OrderStatus({
    this.id,
    required this.message,
  });

  factory OrderStatus.fromJson(Map<String, dynamic> json) {
    return OrderStatus(
      id: json['id'] as int?,
      message: json['message']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
    };
  }

  OrderStatus copyWith({
    int? id,
    String? message,
  }) {
    return OrderStatus(
      id: id ?? this.id,
      message: message ?? this.message,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderStatus &&
        other.id == id &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(id, message);

  @override
  String toString() {
    return 'OrderStatus(id: $id, message: $message)';
  }
}