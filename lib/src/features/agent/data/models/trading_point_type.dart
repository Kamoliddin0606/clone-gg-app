/// Trading Point Type Model
/// Represents a type of trading point (tip torgoviy tochka) from SOAP API
/// Linked to sales channels for cascading selection
class TradingPointType {
  /// Unique code identifier for the trading point type
  final String code;
  
  /// Display name of the type (e.g., "Supermarket", "Аптека")
  final String name;
  
  /// Parent sales channel name/group this type belongs to
  /// Used for cascading dropdown filtering
  final String? channelGroup;

  const TradingPointType({
    required this.code,
    required this.name,
    this.channelGroup,
  });

  /// Create TradingPointType from SOAP XML response
  factory TradingPointType.fromXml(Map<String, String?> xmlData) {
    return TradingPointType(
      code: xmlData['code'] ?? '',
      name: xmlData['Name'] ?? '',
      channelGroup: xmlData['Group']?.isEmpty ?? true 
          ? null 
          : xmlData['Group'],
    );
  }

  /// Create TradingPointType from database row
  factory TradingPointType.fromJson(Map<String, dynamic> json) {
    return TradingPointType(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      channelGroup: json['channel_group']?.toString(),
    );
  }

  /// Convert to database-compatible map
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'channel_group': channelGroup,
    };
  }

  /// Convert to database insert map with timestamps
  Map<String, dynamic> toDatabaseMap() {
    final now = DateTime.now().toIso8601String();
    return {
      'code': code,
      'name': name,
      'channel_group': channelGroup,
      'created_at': now,
      'updated_at': now,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TradingPointType && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() {
    return 'TradingPointType(code: $code, name: $name, channelGroup: $channelGroup)';
  }
}
