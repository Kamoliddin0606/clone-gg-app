import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/network/server_service.dart';

class TelegramTokenService {
  final SharedPreferencesService _prefs = sl<SharedPreferencesService>();
  final Dio _dio = sl<Dio>();
  final String _baseUrl = sl<ServerService>().baseUrl;

  /// Fetches Telegram token from server via SOAP request.
  /// Handles network, parsing, and server errors, logs them, and throws exceptions on failure.
  Future<String> getToken() async {
    try {
      // Get credentials from prefs
      final username = _prefs.getSavedUsername();
      final password = _prefs.getSavedPassword();

      if (username == null || password == null) {
        throw Exception('Foydalanuvchi ma\'lumotlari topilmadi');
      }

      // SOAP request body
      final soapBody = '''<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:GetTelegramToken>
         <sam:Login>$username</sam:Login>
         <sam:Password>$password</sam:Password>
      </sam:GetTelegramToken>
   </soap:Body>
</soap:Envelope>''';

      // Send request with timeout
      final response = await _dio.post(
        _baseUrl,
        data: soapBody,
        options: Options(
          headers: {'Content-Type': 'text/xml; charset=utf-8'},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        // Parse XML response
        final document = XmlDocument.parse(response.data);
        final tokenElement = document.findAllElements('token').firstOrNull;
        final errorElement = document.findAllElements('error').firstOrNull;
        final messageElement = document.findAllElements('message').firstOrNull;

        final error = errorElement?.innerText == 'true';
        final message = messageElement?.innerText ?? 'Noma\'lum xatolik';

        if (error) {
          if (kDebugMode) print('Telegram Token Error: $message');
          throw Exception('Server xatolik: $message');
        }

        final token = tokenElement?.innerText;
        if (token == null || token.isEmpty) {
          throw Exception('Token topilmadi');
        }

        if (kDebugMode) print('Telegram Token: Muvaffaqiyatli olindi');
        return token;
      } else {
        throw Exception('HTTP xatolik: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('Telegram Token Fetch Error: $e');
      throw Exception('Token olishda xatolik: $e');
    }
  }
}