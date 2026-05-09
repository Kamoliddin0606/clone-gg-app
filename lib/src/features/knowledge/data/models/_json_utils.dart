/// Defensive bool parser for backend payloads.
///
/// Backend may return booleans as `bool`, `int` (0/1), or `String`
/// ("true"/"false"/"1"/"0"). A direct `as bool?` cast on a string
/// crashes the entire sync bundle, so all knowledge models route
/// through this helper.
bool? parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.toLowerCase().trim()) {
      case 'true':
      case '1':
      case 'yes':
        return true;
      case 'false':
      case '0':
      case 'no':
      case '':
        return false;
    }
  }
  return null;
}
