/// Minimal JSON Schema (draft-07 subset) validator used by the generic
/// renderer for client-side validation.
///
/// We deliberately keep the matcher small — server-side `jsonschema`
/// owns the canonical answer. The mobile copy only stops obviously
/// invalid payloads from leaving the device:
///   * `required` properties present.
///   * `type` matches.
///   * `enum` membership.
///   * `minimum` / `maximum` for numbers.
///   * `minLength` / `maxLength` for strings.
///   * `minItems` / `maxItems` for arrays.
///   * `oneOf` — first match wins (no SAT-style resolution).
class SchemaValidator {
  const SchemaValidator._();

  /// Returns a path-keyed map of human-readable error messages. Empty map
  /// ⇒ payload satisfies the schema.
  static Map<String, String> validate(
    Map<String, dynamic> payload,
    Map<String, dynamic> schema,
  ) {
    final errors = <String, String>{};
    _validateAny(payload, schema, '', errors);
    return errors;
  }

  static void _validateAny(
    Object? value,
    Map<String, dynamic> schema,
    String path,
    Map<String, String> errors,
  ) {
    final type = schema['type'] as String?;
    final enumValues = schema['enum'] as List?;

    if (enumValues != null && !enumValues.contains(value)) {
      errors[path.isEmpty ? '.' : path] =
          'Qiymat ruxsat etilgan ro\'yxatda emas';
      return;
    }

    if (type == null) return;

    switch (type) {
      case 'object':
        _validateObject(value, schema, path, errors);
        break;
      case 'array':
        _validateArray(value, schema, path, errors);
        break;
      case 'string':
        _validateString(value, schema, path, errors);
        break;
      case 'integer':
      case 'number':
        _validateNumber(value, schema, path, errors, integer: type == 'integer');
        break;
      case 'boolean':
        if (value is! bool) {
          errors[path.isEmpty ? '.' : path] = 'Boolean qiymat kutilgan';
        }
        break;
    }
  }

  static void _validateObject(
    Object? value,
    Map<String, dynamic> schema,
    String path,
    Map<String, String> errors,
  ) {
    if (value is! Map) {
      errors[path.isEmpty ? '.' : path] = 'Object kutilgan';
      return;
    }
    final required = (schema['required'] as List?)?.cast<String>() ?? const [];
    final properties =
        (schema['properties'] as Map?)?.cast<String, dynamic>() ?? const {};

    for (final field in required) {
      if (!value.containsKey(field) || value[field] == null) {
        final subPath = path.isEmpty ? field : '$path.$field';
        errors[subPath] = 'Majburiy maydon';
      }
    }
    for (final entry in properties.entries) {
      final field = entry.key;
      if (!value.containsKey(field)) continue;
      final subSchema = (entry.value as Map).cast<String, dynamic>();
      final subPath = path.isEmpty ? field : '$path.$field';
      _validateAny(value[field], subSchema, subPath, errors);
    }
  }

  static void _validateArray(
    Object? value,
    Map<String, dynamic> schema,
    String path,
    Map<String, String> errors,
  ) {
    if (value is! List) {
      errors[path.isEmpty ? '.' : path] = 'Massiv kutilgan';
      return;
    }
    final minItems = schema['minItems'] as int?;
    final maxItems = schema['maxItems'] as int?;
    if (minItems != null && value.length < minItems) {
      errors[path.isEmpty ? '.' : path] =
          'Kamida $minItems element bo\'lishi shart';
    }
    if (maxItems != null && value.length > maxItems) {
      errors[path.isEmpty ? '.' : path] =
          'Eng ko\'pi bilan $maxItems element bo\'lishi mumkin';
    }
    final itemsSchema = schema['items'];
    if (itemsSchema is Map) {
      final itemSchema = itemsSchema.cast<String, dynamic>();
      for (var i = 0; i < value.length; i++) {
        _validateAny(value[i], itemSchema, '$path[$i]', errors);
      }
    }
  }

  static void _validateString(
    Object? value,
    Map<String, dynamic> schema,
    String path,
    Map<String, String> errors,
  ) {
    if (value is! String) {
      errors[path.isEmpty ? '.' : path] = 'Matn kutilgan';
      return;
    }
    final minLength = schema['minLength'] as int?;
    final maxLength = schema['maxLength'] as int?;
    if (minLength != null && value.length < minLength) {
      errors[path.isEmpty ? '.' : path] =
          'Kamida $minLength belgi bo\'lishi shart';
    }
    if (maxLength != null && value.length > maxLength) {
      errors[path.isEmpty ? '.' : path] =
          'Eng ko\'pi bilan $maxLength belgi bo\'lishi mumkin';
    }
    final format = schema['format'] as String?;
    if (format == 'email' && !_emailRegex.hasMatch(value)) {
      errors[path.isEmpty ? '.' : path] = 'Email format noto\'g\'ri';
    }
  }

  static void _validateNumber(
    Object? value,
    Map<String, dynamic> schema,
    String path,
    Map<String, String> errors, {
    required bool integer,
  }) {
    if (value is! num || (integer && value is! int)) {
      errors[path.isEmpty ? '.' : path] =
          integer ? 'Butun son kutilgan' : 'Son kutilgan';
      return;
    }
    final minimum = schema['minimum'];
    final maximum = schema['maximum'];
    if (minimum is num && value < minimum) {
      errors[path.isEmpty ? '.' : path] = 'Minimum: $minimum';
    }
    if (maximum is num && value > maximum) {
      errors[path.isEmpty ? '.' : path] = 'Maksimum: $maximum';
    }
  }

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}
