/// Sales Channel Model
/// Represents a sales channel (kanal prodaja) from SOAP API
/// Used for client classification and categorization
class SalesChannel {
  /// Unique code identifier for the channel
  final String code;
  
  /// Display name of the channel (e.g., "Bazaar", "Modern trade")
  final String name;
  
  /// Upper group code if this channel belongs to a parent group
  final String? upperGroup;
  
  /// Whether this is a group/category (Да/Нет from SOAP)
  final bool isGroup;

  const SalesChannel({
    required this.code,
    required this.name,
    this.upperGroup,
    required this.isGroup,
  });

  /// Create SalesChannel from SOAP XML response
  /// Handles Russian "Да"/"Нет" values for isGroup field
  factory SalesChannel.fromXml(Map<String, String?> xmlData) {
    return SalesChannel(
      code: xmlData['code'] ?? '',
      name: xmlData['Name'] ?? '',
      upperGroup: xmlData['UpperGroup']?.isEmpty ?? true 
          ? null 
          : xmlData['UpperGroup'],
      isGroup: xmlData['isGroup']?.toLowerCase() == 'да' || 
               xmlData['isGroup']?.toLowerCase() == 'yes',
    );
  }

  /// Create SalesChannel from database row
  factory SalesChannel.fromJson(Map<String, dynamic> json) {
    return SalesChannel(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      upperGroup: json['upper_group']?.toString(),
      isGroup: (json['is_group'] as int?) == 1,
    );
  }

  /// Convert to database-compatible map
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'upper_group': upperGroup,
      'is_group': isGroup ? 1 : 0,
    };
  }

  /// Convert to database insert map with timestamps
  Map<String, dynamic> toDatabaseMap() {
    final now = DateTime.now().toIso8601String();
    return {
      'code': code,
      'name': name,
      'upper_group': upperGroup,
      'is_group': isGroup ? 1 : 0,
      'created_at': now,
      'updated_at': now,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SalesChannel && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() {
    return 'SalesChannel(code: $code, name: $name, isGroup: $isGroup)';
  }
}
