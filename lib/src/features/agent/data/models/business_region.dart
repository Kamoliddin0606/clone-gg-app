class BusinessRegion {
  final String code;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BusinessRegion({
    required this.code,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory BusinessRegion.fromMap(Map<String, dynamic> map) {
    return BusinessRegion(
      code: map['code'] as String,
      name: map['name'] as String,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  BusinessRegion copyWith({
    String? code,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessRegion(
      code: code ?? this.code,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusinessRegion && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() {
    return 'BusinessRegion(code: $code, name: $name)';
  }
}