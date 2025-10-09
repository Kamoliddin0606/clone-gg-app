class ClientContract {
  final String codeContract;
  final DateTime? dateOfContract;
  final double sumOfContract;
  final DateTime? termOfContract;
  final String? typeContract;
  final String? numbReference;
  final String? numbCertificate;
  final DateTime? termReference;
  final DateTime? termCertificate;
  final String? numbPassport;
  final DateTime? termPassport;
  final int certificateUnlimited;
  final String? codeDistrict;
  final String? nameDistrict;
  final String? codeProject;
  final String codeClient;
  final bool active;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ClientContract({
    required this.codeContract,
    this.dateOfContract,
    required this.sumOfContract,
    this.termOfContract,
    this.typeContract,
    this.numbReference,
    this.numbCertificate,
    this.termReference,
    this.termCertificate,
    this.numbPassport,
    this.termPassport,
    required this.certificateUnlimited,
    this.codeDistrict,
    this.nameDistrict,
    this.codeProject,
    required this.codeClient,
    required this.active,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory ClientContract.fromMap(Map<String, dynamic> map) {
    return ClientContract(
      codeContract: map['code_contract'] as String,
      dateOfContract: map['date_of_contract'] != null ? DateTime.parse(map['date_of_contract'] as String) : null,
      sumOfContract: (map['sum_of_contract'] as num?)?.toDouble() ?? 0.0,
      termOfContract: map['term_of_contract'] != null ? DateTime.parse(map['term_of_contract'] as String) : null,
      typeContract: map['type_contract'] as String?,
      numbReference: map['numb_reference'] as String?,
      numbCertificate: map['numb_certificate'] as String?,
      termReference: map['term_reference'] != null ? DateTime.parse(map['term_reference'] as String) : null,
      termCertificate: map['term_certificate'] != null ? DateTime.parse(map['term_certificate'] as String) : null,
      numbPassport: map['numb_passport'] as String?,
      termPassport: map['term_passport'] != null ? DateTime.parse(map['term_passport'] as String) : null,
      certificateUnlimited: (map['certificate_unlimited'] as num?)?.toInt() ?? 0,
      codeDistrict: map['code_district'] as String?,
      nameDistrict: map['name_district'] as String?,
      codeProject: map['code_project'] as String?,
      codeClient: map['code_client'] as String,
      active: (map['active'] as num?) == 1,
      status: map['status'] as String,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code_contract': codeContract,
      'date_of_contract': dateOfContract?.toIso8601String(),
      'sum_of_contract': sumOfContract,
      'term_of_contract': termOfContract?.toIso8601String(),
      'type_contract': typeContract,
      'numb_reference': numbReference,
      'numb_certificate': numbCertificate,
      'term_reference': termReference?.toIso8601String(),
      'term_certificate': termCertificate?.toIso8601String(),
      'numb_passport': numbPassport,
      'term_passport': termPassport?.toIso8601String(),
      'certificate_unlimited': certificateUnlimited,
      'code_district': codeDistrict,
      'name_district': nameDistrict,
      'code_project': codeProject,
      'code_client': codeClient,
      'active': active ? 1 : 0,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ClientContract copyWith({
    String? codeContract,
    DateTime? dateOfContract,
    double? sumOfContract,
    DateTime? termOfContract,
    String? typeContract,
    String? numbReference,
    String? numbCertificate,
    DateTime? termReference,
    DateTime? termCertificate,
    String? numbPassport,
    DateTime? termPassport,
    int? certificateUnlimited,
    String? codeDistrict,
    String? nameDistrict,
    String? codeProject,
    String? codeClient,
    bool? active,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientContract(
      codeContract: codeContract ?? this.codeContract,
      dateOfContract: dateOfContract ?? this.dateOfContract,
      sumOfContract: sumOfContract ?? this.sumOfContract,
      termOfContract: termOfContract ?? this.termOfContract,
      typeContract: typeContract ?? this.typeContract,
      numbReference: numbReference ?? this.numbReference,
      numbCertificate: numbCertificate ?? this.numbCertificate,
      termReference: termReference ?? this.termReference,
      termCertificate: termCertificate ?? this.termCertificate,
      numbPassport: numbPassport ?? this.numbPassport,
      termPassport: termPassport ?? this.termPassport,
      certificateUnlimited: certificateUnlimited ?? this.certificateUnlimited,
      codeDistrict: codeDistrict ?? this.codeDistrict,
      nameDistrict: nameDistrict ?? this.nameDistrict,
      codeProject: codeProject ?? this.codeProject,
      codeClient: codeClient ?? this.codeClient,
      active: active ?? this.active,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClientContract && other.codeContract == codeContract;
  }

  @override
  int get hashCode => codeContract.hashCode;

  @override
  String toString() {
    return 'ClientContract(codeContract: $codeContract, codeClient: $codeClient, active: $active, status: $status)';
  }
}