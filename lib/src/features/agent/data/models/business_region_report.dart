class BusinessRegionReport {
  final int? id;
  final int mainReportId;
  final String code;
  final String name;
  final int akb;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BusinessRegionReport({
    this.id,
    required this.mainReportId,
    required this.code,
    required this.name,
    required this.akb,
    this.createdAt,
    this.updatedAt,
  });

  factory BusinessRegionReport.fromMap(Map<String, dynamic> map) {
    return BusinessRegionReport(
      id: map['id'] as int?,
      mainReportId: map['main_report_id'] as int,
      code: map['code'] as String,
      name: map['name'] as String,
      akb: map['akb'] as int,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'main_report_id': mainReportId,
      'code': code,
      'name': name,
      'akb': akb,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  BusinessRegionReport copyWith({
    int? id,
    int? mainReportId,
    String? code,
    String? name,
    int? akb,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessRegionReport(
      id: id ?? this.id,
      mainReportId: mainReportId ?? this.mainReportId,
      code: code ?? this.code,
      name: name ?? this.name,
      akb: akb ?? this.akb,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}