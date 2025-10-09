class VisitPlanList {
  final int? id;
  final int visitPlanId;
  final String productCode;
  final String productName;
  final int plannedQuantity;
  final int? actualQuantity;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VisitPlanList({
    this.id,
    required this.visitPlanId,
    required this.productCode,
    required this.productName,
    required this.plannedQuantity,
    this.actualQuantity,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory VisitPlanList.fromMap(Map<String, dynamic> map) {
    return VisitPlanList(
      id: map['id'] as int?,
      visitPlanId: map['visit_plan_id'] as int,
      productCode: map['product_code'] as String,
      productName: map['product_name'] as String,
      plannedQuantity: map['planned_quantity'] as int,
      actualQuantity: map['actual_quantity'] as int?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'visit_plan_id': visitPlanId,
      'product_code': productCode,
      'product_name': productName,
      'planned_quantity': plannedQuantity,
      'actual_quantity': actualQuantity,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  VisitPlanList copyWith({
    int? id,
    int? visitPlanId,
    String? productCode,
    String? productName,
    int? plannedQuantity,
    int? actualQuantity,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VisitPlanList(
      id: id ?? this.id,
      visitPlanId: visitPlanId ?? this.visitPlanId,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      plannedQuantity: plannedQuantity ?? this.plannedQuantity,
      actualQuantity: actualQuantity ?? this.actualQuantity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}