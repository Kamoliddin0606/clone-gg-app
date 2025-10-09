class VisitPlan {
  final int? id;
  final int mainReportId;
  final String clientCode;
  final String clientName;
  final String plannedDate;
  final String? actualVisitDate;
  final bool isCompleted;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VisitPlan({
    this.id,
    required this.mainReportId,
    required this.clientCode,
    required this.clientName,
    required this.plannedDate,
    this.actualVisitDate,
    this.isCompleted = false,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory VisitPlan.fromMap(Map<String, dynamic> map) {
    return VisitPlan(
      id: map['id'] as int?,
      mainReportId: map['main_report_id'] as int,
      clientCode: map['client_code'] as String,
      clientName: map['client_name'] as String,
      plannedDate: map['planned_date'] as String,
      actualVisitDate: map['actual_visit_date'] as String?,
      isCompleted: (map['is_completed'] as int?) == 1,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'main_report_id': mainReportId,
      'client_code': clientCode,
      'client_name': clientName,
      'planned_date': plannedDate,
      'actual_visit_date': actualVisitDate,
      'is_completed': isCompleted ? 1 : 0,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  VisitPlan copyWith({
    int? id,
    int? mainReportId,
    String? clientCode,
    String? clientName,
    String? plannedDate,
    String? actualVisitDate,
    bool? isCompleted,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VisitPlan(
      id: id ?? this.id,
      mainReportId: mainReportId ?? this.mainReportId,
      clientCode: clientCode ?? this.clientCode,
      clientName: clientName ?? this.clientName,
      plannedDate: plannedDate ?? this.plannedDate,
      actualVisitDate: actualVisitDate ?? this.actualVisitDate,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}