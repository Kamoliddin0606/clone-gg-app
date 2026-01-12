import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Structured address model with parsed components
class StructuredAddress {
  final String country;
  final String region;
  final String district;
  final String street;
  final String houseNumber;
  final String fullAddress;
  final double confidence;

  const StructuredAddress({
    required this.country,
    required this.region,
    required this.district,
    required this.street,
    required this.houseNumber,
    required this.fullAddress,
    required this.confidence,
  });

  /// Create empty/unknown address
  factory StructuredAddress.unknown() => const StructuredAddress(
    country: "O'zbekiston",
    region: '',
    district: '',
    street: '',
    houseNumber: '',
    fullAddress: 'Manzil aniqlanmadi',
    confidence: 0.0,
  );

  /// Format: "O'zbekiston, Toshkent shahri, Mirzo Ulug'bek tumani, AB ko'chasi, 12-uy"
  String toFormattedString() {
    final parts = <String>[];
    
    if (country.isNotEmpty) parts.add(country);
    if (region.isNotEmpty) parts.add(region);
    if (district.isNotEmpty) parts.add(district);
    if (street.isNotEmpty) parts.add(street);
    if (houseNumber.isNotEmpty) parts.add(houseNumber);
    
    return parts.isNotEmpty ? parts.join(', ') : 'Manzil aniqlanmadi';
  }

  @override
  String toString() => toFormattedString();
}

/// Service for resolving coordinates to structured addresses
/// Primary: OpenStreetMap Nominatim API
/// Fallback: Yandex Geocoding API, Google Geocoding API
class AddressResolverService {
  final Dio _dio;
  final String? _yandexApiKey;
  final String? _googleApiKey;

  AddressResolverService({
    Dio? dio,
    String? yandexApiKey,
    String? googleApiKey,
  }) : _dio = dio ?? Dio(),
       _yandexApiKey = yandexApiKey,
       _googleApiKey = googleApiKey;

  /// Resolve coordinates to structured address
  /// Uses Nominatim as primary, with Yandex and Google as fallbacks
  Future<StructuredAddress> resolveAddress(double latitude, double longitude) async {
    // Try Nominatim (OpenStreetMap) first - primary
    try {
      final result = await _resolveWithNominatim(latitude, longitude);
      if (result.confidence > 0.3) {
        return result;
      }
    } catch (e) {
      if (kDebugMode) print('Nominatim failed: $e');
    }

    // Fallback to Yandex
    if (_yandexApiKey != null && _yandexApiKey.isNotEmpty) {
      try {
        final result = await _resolveWithYandex(latitude, longitude);
        if (result.confidence > 0.3) {
          return result;
        }
      } catch (e) {
        if (kDebugMode) print('Yandex fallback failed: $e');
      }
    }

    // Fallback to Google
    if (_googleApiKey != null && _googleApiKey.isNotEmpty) {
      try {
        final result = await _resolveWithGoogle(latitude, longitude);
        if (result.confidence > 0.3) {
          return result;
        }
      } catch (e) {
        if (kDebugMode) print('Google fallback failed: $e');
      }
    }

    return StructuredAddress.unknown();
  }

  /// Resolve using Nominatim (OpenStreetMap) API
  Future<StructuredAddress> _resolveWithNominatim(double lat, double lng) async {
    final response = await _dio.get(
      'https://nominatim.openstreetmap.org/reverse',
      queryParameters: {
        'format': 'json',
        'lat': lat,
        'lon': lng,
        'addressdetails': 1,
        'accept-language': 'uz,ru,en',
        'zoom': 18,
      },
      options: Options(
        headers: {
          'User-Agent': 'GloriaMarketingApp/1.0',
        },
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Nominatim API error: ${response.statusCode}');
    }

    final data = response.data;
    final address = data['address'] as Map<String, dynamic>? ?? {};

    // Parse country
    String country = address['country'] ?? "O'zbekiston";
    if (country.toLowerCase().contains('uzbekistan') || 
        country.toLowerCase().contains('oʻzbekiston')) {
      country = "O'zbekiston";
    }

    // Parse region (city/state)
    String region = '';
    final city = address['city'] ?? address['town'] ?? address['state'] ?? '';
    if (city.isNotEmpty) {
      region = _formatRegion(city);
    }

    // Parse district
    String district = '';
    final districtRaw = address['city_district'] ?? 
                        address['suburb'] ?? 
                        address['county'] ?? 
                        address['district'] ?? '';
    if (districtRaw.isNotEmpty) {
      district = _formatDistrict(districtRaw);
    }

    // Parse street
    String street = '';
    final streetRaw = address['road'] ?? address['street'] ?? '';
    if (streetRaw.isNotEmpty) {
      street = _formatStreet(streetRaw);
    }

    // Parse house number
    String houseNumber = '';
    final houseRaw = address['house_number'] ?? '';
    if (houseRaw.isNotEmpty) {
      houseNumber = _formatHouseNumber(houseRaw);
    }

    // Calculate confidence based on available data
    double confidence = _calculateConfidence(
      hasCountry: country.isNotEmpty,
      hasRegion: region.isNotEmpty,
      hasDistrict: district.isNotEmpty,
      hasStreet: street.isNotEmpty,
      hasHouse: houseNumber.isNotEmpty,
    );

    final structured = StructuredAddress(
      country: country,
      region: region,
      district: district,
      street: street,
      houseNumber: houseNumber,
      fullAddress: data['display_name'] ?? '',
      confidence: confidence,
    );

    if (kDebugMode) {
      print('Nominatim result: ${structured.toFormattedString()} (confidence: $confidence)');
    }

    return structured;
  }

  /// Resolve using Yandex Geocoding API
  Future<StructuredAddress> _resolveWithYandex(double lat, double lng) async {
    final response = await _dio.get(
      'https://geocode-maps.yandex.ru/1.x/',
      queryParameters: {
        'apikey': _yandexApiKey,
        'format': 'json',
        'geocode': '$lng,$lat',
        'lang': 'uz_UZ',
        'results': 1,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Yandex API error: ${response.statusCode}');
    }

    final data = response.data;
    final geoObjectCollection = data['response']['GeoObjectCollection'];
    final featureMembers = geoObjectCollection['featureMember'] as List;

    if (featureMembers.isEmpty) {
      return StructuredAddress.unknown();
    }

    final geoObject = featureMembers[0]['GeoObject'];
    final metaData = geoObject['metaDataProperty']['GeocoderMetaData'];
    final addressDetails = metaData['AddressDetails']['Country'];

    String country = "O'zbekiston";
    String region = '';
    String district = '';
    String street = '';
    String houseNumber = '';

    // Parse administrative area
    final adminArea = addressDetails['AdministrativeArea'];
    if (adminArea != null) {
      region = _formatRegion(adminArea['AdministrativeAreaName'] ?? '');
      
      final subAdminArea = adminArea['SubAdministrativeArea'];
      if (subAdminArea != null) {
        district = _formatDistrict(subAdminArea['SubAdministrativeAreaName'] ?? '');
        
        final locality = subAdminArea['Locality'];
        if (locality != null) {
          final thoroughfare = locality['Thoroughfare'];
          if (thoroughfare != null) {
            street = _formatStreet(thoroughfare['ThoroughfareName'] ?? '');
            
            final premise = thoroughfare['Premise'];
            if (premise != null) {
              houseNumber = _formatHouseNumber(premise['PremiseNumber'] ?? '');
            }
          }
        }
      }
    }

    // Try locality directly if no admin area
    final locality = addressDetails['Locality'];
    if (locality != null && region.isEmpty) {
      region = _formatRegion(locality['LocalityName'] ?? '');
    }

    double confidence = _calculateConfidence(
      hasCountry: true,
      hasRegion: region.isNotEmpty,
      hasDistrict: district.isNotEmpty,
      hasStreet: street.isNotEmpty,
      hasHouse: houseNumber.isNotEmpty,
    );

    return StructuredAddress(
      country: country,
      region: region,
      district: district,
      street: street,
      houseNumber: houseNumber,
      fullAddress: metaData['text'] ?? '',
      confidence: confidence,
    );
  }

  /// Resolve using Google Geocoding API
  Future<StructuredAddress> _resolveWithGoogle(double lat, double lng) async {
    final response = await _dio.get(
      'https://maps.googleapis.com/maps/api/geocode/json',
      queryParameters: {
        'latlng': '$lat,$lng',
        'key': _googleApiKey,
        'language': 'uz',
      },
    );

    if (response.statusCode != 200 || response.data['status'] != 'OK') {
      throw Exception('Google API error');
    }

    final results = response.data['results'] as List;
    if (results.isEmpty) {
      return StructuredAddress.unknown();
    }

    final components = results[0]['address_components'] as List;

    String country = "O'zbekiston";
    String region = '';
    String district = '';
    String street = '';
    String houseNumber = '';

    for (var component in components) {
      final types = component['types'] as List;
      final name = component['long_name'] as String;

      if (types.contains('country')) {
        country = "O'zbekiston";
      } else if (types.contains('administrative_area_level_1') || types.contains('locality')) {
        if (region.isEmpty) region = _formatRegion(name);
      } else if (types.contains('administrative_area_level_2') || types.contains('sublocality_level_1')) {
        if (district.isEmpty) district = _formatDistrict(name);
      } else if (types.contains('route')) {
        street = _formatStreet(name);
      } else if (types.contains('street_number')) {
        houseNumber = _formatHouseNumber(name);
      }
    }

    double confidence = _calculateConfidence(
      hasCountry: true,
      hasRegion: region.isNotEmpty,
      hasDistrict: district.isNotEmpty,
      hasStreet: street.isNotEmpty,
      hasHouse: houseNumber.isNotEmpty,
    );

    return StructuredAddress(
      country: country,
      region: region,
      district: district,
      street: street,
      houseNumber: houseNumber,
      fullAddress: results[0]['formatted_address'] ?? '',
      confidence: confidence,
    );
  }

  /// Format region name (e.g., "Toshkent" -> "Toshkent shahri")
  String _formatRegion(String raw) {
    if (raw.isEmpty) return '';
    
    String normalized = raw.trim();
    
    // Translate Russian city names to Uzbek
    normalized = _translateToUzbek(normalized);
    
    // Check if already has suffix
    if (normalized.toLowerCase().contains('shahri') || 
        normalized.toLowerCase().contains('viloyati') ||
        normalized.toLowerCase().contains('city') ||
        normalized.toLowerCase().contains('область')) {
      // Normalize to Uzbek
      return normalized
          .replaceAll(RegExp(r'\s+city', caseSensitive: false), ' shahri')
          .replaceAll(RegExp(r'\s+область', caseSensitive: false), ' viloyati');
    }
    
    // Add appropriate suffix
    final lowerName = normalized.toLowerCase();
    if (lowerName == 'toshkent' || lowerName == 'tashkent' || lowerName == 'ташкент') {
      return 'Toshkent shahri';
    }
    
    // For other cities, add "shahri" by default
    return '$normalized shahri';
  }

  /// Format district name (e.g., "Mirzo Ulug'bek" -> "Mirzo Ulug'bek tumani")
  String _formatDistrict(String raw) {
    if (raw.isEmpty) return '';
    
    String normalized = raw.trim();
    
    // Translate Russian district names to Uzbek
    normalized = _translateToUzbek(normalized);
    
    // Check if already has suffix
    if (normalized.toLowerCase().contains('tumani') || 
        normalized.toLowerCase().contains('district') ||
        normalized.toLowerCase().contains('район')) {
      return normalized
          .replaceAll(RegExp(r'\s+district', caseSensitive: false), ' tumani')
          .replaceAll(RegExp(r'\s+район', caseSensitive: false), ' tumani');
    }
    
    return '$normalized tumani';
  }

  /// Format street name (e.g., "Amir Temur" -> "Amir Temur ko'chasi")
  String _formatStreet(String raw) {
    if (raw.isEmpty) return '';
    
    String normalized = raw.trim();
    
    // Translate Russian street names to Uzbek
    normalized = _translateToUzbek(normalized);
    
    // Check if already has suffix
    if (normalized.toLowerCase().contains("ko'chasi") || 
        normalized.toLowerCase().contains('street') ||
        normalized.toLowerCase().contains('улица') ||
        normalized.toLowerCase().contains('shoh ko\'chasi') ||
        normalized.toLowerCase().contains('prospekti')) {
      return normalized
          .replaceAll(RegExp(r'\s+street', caseSensitive: false), " ko'chasi")
          .replaceAll(RegExp(r'\s+улица', caseSensitive: false), " ko'chasi");
    }
    
    return "$normalized ko'chasi";
  }

  /// Format house number (e.g., "12" -> "12-uy")
  String _formatHouseNumber(String raw) {
    if (raw.isEmpty) return '';
    
    final normalized = raw.trim();
    
    // Check if already has suffix
    if (normalized.toLowerCase().contains('-uy') || 
        normalized.toLowerCase().contains('uy')) {
      return normalized;
    }
    
    return '$normalized-uy';
  }

  /// Calculate confidence score based on available address components
  double _calculateConfidence({
    required bool hasCountry,
    required bool hasRegion,
    required bool hasDistrict,
    required bool hasStreet,
    required bool hasHouse,
  }) {
    double score = 0.0;
    
    if (hasCountry) score += 0.1;
    if (hasRegion) score += 0.25;
    if (hasDistrict) score += 0.25;
    if (hasStreet) score += 0.25;
    if (hasHouse) score += 0.15;
    
    return score;
  }

  /// Translate Russian/Cyrillic place names to Uzbek Latin
  String _translateToUzbek(String text) {
    if (text.isEmpty) return text;
    
    // Common Russian -> Uzbek translations for districts and streets
    final translations = {
      // Districts
      'Мирзо-Улугбекский': "Mirzo Ulug'bek",
      'Мирзо Улугбекский': "Mirzo Ulug'bek",
      'Учтепинский': 'Uchtepa',
      'Яшнабадский': 'Yashnobod',
      'Юнусабадский': 'Yunusobod',
      'Чиланзарский': 'Chilonzor',
      'Сергелийский': 'Sergeli',
      'Шайхантахурский': 'Shayxontohur',
      'Яккасарайский': 'Yakkasaroy',
      'Бектемирский': 'Bektemir',
      'Алмазарский': 'Olmazor',
      'Мирабадский': 'Mirobod',
      
      // Cities/Regions
      'Ташкент': 'Toshkent',
      'Самарканд': 'Samarqand',
      'Бухара': 'Buxoro',
      'Андижан': 'Andijon',
      'Наманган': 'Namangan',
      'Фергана': 'Farg\'ona',
      'Коканд': 'Qo\'qon',
      'Нукус': 'Nukus',
      'Карши': 'Qarshi',
      'Термез': 'Termiz',
      'Хива': 'Xiva',
      'Гулистан': 'Guliston',
      'Джизак': 'Jizzax',
      'Навои': 'Navoiy',
      'Ургенч': 'Urganch',
      
      // Common street words
      'улица': "ko'chasi",
      'проспект': 'prospekti',
      'переулок': 'tor ko\'chasi',
      'бульвар': 'bulvar',
      'площадь': 'maydon',
      'район': 'tumani',
      
      // Common street names
      'Амира Темура': 'Amir Temur',
      'Мустақиллик': "Mustaqillik",
      'Бунёдкор': 'Bunyodkor',
      'Шота Руставели': 'Shota Rustaveli',
      'Абдулла Кодирий': 'Abdulla Qodiriy',
      'Алишер Навои': 'Alisher Navoiy',
      'Бабур': 'Bobur',
      'Беруний': 'Beruniy',
      'Фараби': 'Forobiy',
      'Ибн Сино': 'Ibn Sino',
      'Паркент': 'Parkent',
    };
    
    String result = text;
    
    // First apply specific translations
    translations.forEach((russian, uzbek) {
      result = result.replaceAll(russian, uzbek);
      // Case insensitive replacement
      result = result.replaceAll(
        RegExp(russian, caseSensitive: false),
        uzbek,
      );
    });
    
    // Then apply general Cyrillic to Latin transliteration for remaining Cyrillic text
    result = _transliterateCyrillicToLatin(result);
    
    return result;
  }
  
  /// Transliterate Cyrillic text to Latin script (Uzbek alphabet)
  String _transliterateCyrillicToLatin(String text) {
    // Cyrillic to Latin mapping for Uzbek
    final Map<String, String> cyrillicToLatin = {
      'А': 'A', 'а': 'a',
      'Б': 'B', 'б': 'b',
      'В': 'V', 'в': 'v',
      'Г': 'G', 'г': 'g',
      'Д': 'D', 'д': 'd',
      'Е': 'E', 'е': 'e',
      'Ё': 'Yo', 'ё': 'yo',
      'Ж': 'J', 'ж': 'j',
      'З': 'Z', 'з': 'z',
      'И': 'I', 'и': 'i',
      'Й': 'Y', 'й': 'y',
      'К': 'K', 'к': 'k',
      'Л': 'L', 'л': 'l',
      'М': 'M', 'м': 'm',
      'Н': 'N', 'н': 'n',
      'О': 'O', 'о': 'o',
      'П': 'P', 'п': 'p',
      'Р': 'R', 'р': 'r',
      'С': 'S', 'с': 's',
      'Т': 'T', 'т': 't',
      'У': 'U', 'у': 'u',
      'Ф': 'F', 'ф': 'f',
      'Х': 'X', 'х': 'x',
      'Ц': 'Ts', 'ц': 'ts',
      'Ч': 'Ch', 'ч': 'ch',
      'Ш': 'Sh', 'ш': 'sh',
      'Щ': 'Sh', 'щ': 'sh',
      'Ъ': '', 'ъ': '',
      'Ы': 'I', 'ы': 'i',
      'Ь': '', 'ь': '',
      'Э': 'E', 'э': 'e',
      'Ю': 'Yu', 'ю': 'yu',
      'Я': 'Ya', 'я': 'ya',
      'Ў': 'O\'', 'ў': 'o\'',
      'Қ': 'Q', 'қ': 'q',
      'Ғ': 'G\'', 'ғ': 'g\'',
      'Ҳ': 'H', 'ҳ': 'h',
    };
    
    String result = text;
    cyrillicToLatin.forEach((cyrillic, latin) {
      result = result.replaceAll(cyrillic, latin);
    });
    
    return result;
  }
}
