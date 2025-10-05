class UserWarehouse {
  final String code;
  final String name;
  final String organization;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserWarehouse({
    required this.code,
    required this.name,
    required this.organization,
    this.createdAt,
    this.updatedAt,
  });

  factory UserWarehouse.fromMap(Map<String, dynamic> map) {
    return UserWarehouse(
      code: map['code'] as String,
      name: map['name'] as String,
      organization: map['organization'] as String,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'organization': organization,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserWarehouse copyWith({
    String? code,
    String? name,
    String? organization,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserWarehouse(
      code: code ?? this.code,
      name: name ?? this.name,
      organization: organization ?? this.organization,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserWarehouse && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() {
    return 'UserWarehouse(code: $code, name: $name, organization: $organization)';
  }
}