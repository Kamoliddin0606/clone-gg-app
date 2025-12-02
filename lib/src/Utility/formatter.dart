import 'package:intl/intl.dart';

String formatSum(num? value) {
  if (value == null) return '-';
  final formatter = NumberFormat('#,###', 'uz_UZ');
  return '${formatter.format(value).replaceAll(',', ' ')} so\'m';
}
String formatProcent(num? value) {
  if (value == null) return '-';
  final formatter = NumberFormat('#,###', 'uz_UZ');
  return '${formatter.format(value).replaceAll(',', ' ')} %';
}

// Transliteration mappings
const Map<String, String> _cyrillicToLatin = {
  'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo',
  'ж': 'j', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm',
  'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
  'ф': 'f', 'х': 'x', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'shch',
  'ъ': '\'', 'ы': 'y', 'ь': '\'', 'э': 'e', 'ю': 'yu', 'я': 'ya',
  'А': 'A', 'Б': 'B', 'В': 'V', 'Г': 'G', 'Д': 'D', 'Е': 'E', 'Ё': 'Yo',
  'Ж': 'J', 'З': 'Z', 'И': 'I', 'Й': 'Y', 'К': 'K', 'Л': 'L', 'М': 'M',
  'Н': 'N', 'О': 'O', 'П': 'P', 'Р': 'R', 'С': 'S', 'Т': 'T', 'У': 'U',
  'Ф': 'F', 'Х': 'X', 'Ц': 'Ts', 'Ч': 'Ch', 'Ш': 'Sh', 'Щ': 'Shch',
  'Ъ': '\'', 'Ы': 'Y', 'Ь': '\'', 'Э': 'E', 'Ю': 'Yu', 'Я': 'Ya',
};

const Map<String, String> _latinToCyrillic = {
  'a': 'а', 'b': 'б', 'v': 'в', 'g': 'г', 'd': 'д', 'e': 'е', 'yo': 'ё',
  'j': 'ж', 'z': 'з', 'i': 'и', 'y': 'й', 'k': 'к', 'l': 'л', 'm': 'м',
  'n': 'н', 'o': 'о', 'p': 'п', 'r': 'р', 's': 'с', 't': 'т', 'u': 'у',
  'f': 'ф', 'x': 'х', 'ts': 'ц', 'ch': 'ч', 'sh': 'ш', 'shch': 'щ',
  '\'': 'ъ', 'yu': 'ю', 'ya': 'я',
  'A': 'А', 'B': 'Б', 'V': 'В', 'G': 'Г', 'D': 'Д', 'E': 'Е', 'Yo': 'Ё',
  'J': 'Ж', 'Z': 'З', 'I': 'И', 'Y': 'Й', 'K': 'К', 'L': 'Л', 'M': 'М',
  'N': 'Н', 'O': 'О', 'P': 'П', 'R': 'Р', 'S': 'С', 'T': 'Т', 'U': 'У',
  'F': 'Ф', 'X': 'Х', 'Ts': 'Ц', 'Ch': 'Ч', 'Sh': 'Ш', 'Shch': 'Щ',
  'Yu': 'Ю', 'Ya': 'Я',
};

String transliterateToLatin(String text) {
  String result = text;
  _cyrillicToLatin.forEach((cyr, lat) {
    result = result.replaceAll(cyr, lat);
  });
  return result;
}

String transliterateToCyrillic(String text) {
  String result = text;
  // Sort by length descending to handle multi-char first
  final sortedKeys = _latinToCyrillic.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
  for (final lat in sortedKeys) {
    result = result.replaceAll(lat, _latinToCyrillic[lat]!);
  }
  return result;
}

String normalizeForSearch(String text) {
  final lower = text.toLowerCase();
  final latin = transliterateToLatin(lower);
  final cyrillic = transliterateToCyrillic(lower);
  return '$lower|$latin|$cyrillic';
}

bool matchesSearch(String text, String query) {
  if (query.isEmpty) return true;
  final normalizedText = normalizeForSearch(text);
  final normalizedQuery = normalizeForSearch(query);
  final queries = normalizedQuery.split('|');
  return queries.any((q) => normalizedText.contains(q));
}

/// Formats distance for display in UI.
/// Shows distance in meters for distances less than 1km, otherwise in kilometers.
/// Example: 0.9km displays as "900m", 1.5km displays as "1.5km"
String formatDistance(double? distanceKm) {
  if (distanceKm == null) return '';

  if (distanceKm < 1.0) {
    // Convert km to meters and round to nearest integer
    final meters = (distanceKm * 1000).round();
    return '${meters}m';
  } else {
    // Show distance in kilometers with one decimal place
    return '${distanceKm.toStringAsFixed(1)}km';
  }
}