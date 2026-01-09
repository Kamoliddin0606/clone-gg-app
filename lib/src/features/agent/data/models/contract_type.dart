/// Model class representing a contract type from the server.
/// 
/// This model is used to store and retrieve contract types from the
/// GetTypeOfContract SOAP API response. Contract types are cached locally
/// in the database and displayed in the contract creation form.
class ContractType {
  /// Unique code identifier for the contract type
  final String code;
  
  /// Display name of the contract type
  final String name;
  
  /// Timestamp when this record was created locally
  final DateTime? createdAt;
  
  /// Timestamp when this record was last updated locally
  final DateTime? updatedAt;

  /// Creates a new ContractType instance
  ContractType({
    required this.code,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a ContractType from a database map
  factory ContractType.fromMap(Map<String, dynamic> map) {
    return ContractType(
      code: map['code'] as String,
      name: map['name'] as String,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String) 
          : null,
    );
  }

  /// Converts this ContractType to a database map
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Creates a copy of this ContractType with modified fields
  ContractType copyWith({
    String? code,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContractType(
      code: code ?? this.code,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContractType && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() {
    return 'ContractType(code: $code, name: $name)';
  }
}
