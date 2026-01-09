class DistrictContracting {
  final String codeDistrict;
  final String nameDistrict;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DistrictContracting({
    required this.codeDistrict,
    required this.nameDistrict,
    this.createdAt,
    this.updatedAt,
  });

  factory DistrictContracting.fromMap(Map<String, dynamic> map) {
    return DistrictContracting(
      codeDistrict: map['code_district'] as String,
      nameDistrict: map['name_district'] as String,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  factory DistrictContracting.fromXml(Map<String, String> xmlData) {
    return DistrictContracting(
      codeDistrict: xmlData['CodeDistrict'] ?? '',
      nameDistrict: xmlData['NameDistrict'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code_district': codeDistrict,
      'name_district': nameDistrict,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  DistrictContracting copyWith({
    String? codeDistrict,
    String? nameDistrict,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DistrictContracting(
      codeDistrict: codeDistrict ?? this.codeDistrict,
      nameDistrict: nameDistrict ?? this.nameDistrict,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DistrictContracting && other.codeDistrict == codeDistrict;
  }

  @override
  int get hashCode => codeDistrict.hashCode;

  @override
  String toString() {
    return 'DistrictContracting(codeDistrict: $codeDistrict, nameDistrict: $nameDistrict)';
  }
}
