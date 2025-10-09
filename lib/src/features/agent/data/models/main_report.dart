class MainReport {
  final int? id;
  final String userCode;
  final DateTime dateStart;
  final DateTime dateEnd;
  final int countAKB;
  final int countOKB;
  final double cash;
  final double transfer;
  final double sum;
  final int countVisited;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MainReport({
    this.id,
    required this.userCode,
    required this.dateStart,
    required this.dateEnd,
    required this.countAKB,
    required this.countOKB,
    required this.cash,
    required this.transfer,
    required this.sum,
    required this.countVisited,
    this.createdAt,
    this.updatedAt,
  });

  factory MainReport.fromMap(Map<String, dynamic> map) {
    return MainReport(
      id: map['id'] as int?,
      userCode: map['user_code'] as String,
      dateStart: DateTime.parse(map['date_start'] as String),
      dateEnd: DateTime.parse(map['date_end'] as String),
      countAKB: map['count_akb'] as int,
      countOKB: map['count_okb'] as int,
      cash: (map['cash'] as num).toDouble(),
      transfer: (map['transfer'] as num).toDouble(),
      sum: (map['sum'] as num).toDouble(),
      countVisited: map['count_visited'] as int,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_code': userCode,
      'date_start': dateStart.toIso8601String().split('T')[0], // Convert to YYYY-MM-DD format
      'date_end': dateEnd.toIso8601String().split('T')[0], // Convert to YYYY-MM-DD format
      'count_akb': countAKB,
      'count_okb': countOKB,
      'cash': cash,
      'transfer': transfer,
      'sum': sum,
      'count_visited': countVisited,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  MainReport copyWith({
    int? id,
    String? userCode,
    DateTime? dateStart,
    DateTime? dateEnd,
    int? countAKB,
    int? countOKB,
    double? cash,
    double? transfer,
    double? sum,
    int? countVisited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MainReport(
      id: id ?? this.id,
      userCode: userCode ?? this.userCode,
      dateStart: dateStart ?? this.dateStart,
      dateEnd: dateEnd ?? this.dateEnd,
      countAKB: countAKB ?? this.countAKB,
      countOKB: countOKB ?? this.countOKB,
      cash: cash ?? this.cash,
      transfer: transfer ?? this.transfer,
      sum: sum ?? this.sum,
      countVisited: countVisited ?? this.countVisited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}