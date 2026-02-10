/// Client Class Model
/// Represents a client classification (class torgoviy tochka) from SOAP API
/// Used for client categorization (A, B, C, D, X)
class ClientClass {
  /// Class code/name (e.g., "A", "B", "C", "D", "X")
  final String classCode;

  const ClientClass({
    required this.classCode,
  });

  /// Create ClientClass from SOAP XML response
  factory ClientClass.fromXml(Map<String, String?> xmlData) {
    return ClientClass(
      classCode: xmlData['class'] ?? '',
    );
  }

  /// Create ClientClass from database row
  factory ClientClass.fromJson(Map<String, dynamic> json) {
    return ClientClass(
      classCode: json['class_code']?.toString() ?? '',
    );
  }

  /// Convert to database-compatible map
  Map<String, dynamic> toJson() {
    return {
      'class_code': classCode,
    };
  }

  /// Convert to database insert map with timestamps
  Map<String, dynamic> toDatabaseMap() {
    final now = DateTime.now().toIso8601String();
    return {
      'class_code': classCode,
      'created_at': now,
      'updated_at': now,
    };
  }

  /// Get display name with localization support
  /// Returns formatted class name for UI display
  String getDisplayName() {
    return 'Class $classCode';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClientClass && other.classCode == classCode;
  }

  @override
  int get hashCode => classCode.hashCode;

  @override
  String toString() {
    return 'ClientClass(classCode: $classCode)';
  }
}
