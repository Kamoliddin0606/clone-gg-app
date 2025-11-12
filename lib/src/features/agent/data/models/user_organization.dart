/// Model class representing a user organization
/// This model stores organization data retrieved from the server
/// via GetOrganizationByUserCode SOAP API method
class UserOrganization {
  /// Unique identifier for the organization record in database
  final int? id;

  /// User code this organization belongs to
  final String userCode;

  /// Unique code identifier for the organization
  final String code;

  /// Display name of the organization
  final String name;

  /// Timestamp when this organization was created locally
  final DateTime? createdAt;

  /// Timestamp when this organization was last updated locally
  final DateTime? updatedAt;

  UserOrganization({
    this.id,
    required this.userCode,
    required this.code,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor to create UserOrganization from database map
  factory UserOrganization.fromMap(Map<String, dynamic> map) {
    return UserOrganization(
      id: map['id'] as int?,
      userCode: map['user_code'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  /// Convert UserOrganization to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_code': userCode,
      'code': code,
      'name': name,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy of UserOrganization with optional field updates
  UserOrganization copyWith({
    int? id,
    String? userCode,
    String? code,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserOrganization(
      id: id ?? this.id,
      userCode: userCode ?? this.userCode,
      code: code ?? this.code,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserOrganization && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() {
    return 'UserOrganization(code: $code, name: $name)';
  }
}