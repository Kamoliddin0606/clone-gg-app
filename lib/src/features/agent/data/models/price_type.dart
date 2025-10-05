class PriceType {
  final String code;
  final String name;
  final String description;
  final bool isDefault;

  const PriceType({
    required this.code,
    required this.name,
    this.description = '',
    this.isDefault = false,
  });

  factory PriceType.fromJson(Map<String, dynamic> json) {
    final code = json['code']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';

    // Validation
    if (code.isEmpty) {
      throw ArgumentError('PriceType code cannot be empty');
    }
    if (name.isEmpty) {
      throw ArgumentError('PriceType name cannot be empty');
    }

    return PriceType(
      code: code,
      name: name,
      description: json['description']?.toString() ?? '',
      isDefault: json['isDefault'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'isDefault': isDefault,
    };
  }

  PriceType copyWith({
    String? code,
    String? name,
    String? description,
    bool? isDefault,
  }) {
    return PriceType(
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PriceType &&
        other.code == code &&
        other.name == name &&
        other.description == description &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return Object.hash(code, name, description, isDefault);
  }

  @override
  String toString() {
    return 'PriceType(code: $code, name: $name, description: $description, isDefault: $isDefault)';
  }
}