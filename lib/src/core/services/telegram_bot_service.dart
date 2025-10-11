import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/telegram_token_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/daily_report_template.dart';

class TelegramBotService {
  final SharedPreferencesService _prefs = sl<SharedPreferencesService>();
  final Dio _dio = sl<Dio>();
  final TelegramTokenService _tokenService = sl<TelegramTokenService>();

  // Chat ID and Topic ID will be retrieved from shared preferences

  /// Sends report to Telegram bot.
  /// Configures to send to specified chat, uses topic if available.
  /// Adds "xabar mobile ilova orqali yuborildi" to the message.
  Future<bool> sendReportToTelegram(BuildContext context) async {
    try {
      // Show initial feedback
      _showSnackBar(context, 'Telegram bot bilan bog\'lanmoqda...');

      // Get token from server
      final botToken = await _tokenService.getToken();

      // Get chat ID and topic ID from shared preferences
      final chatId = _prefs.getChatID();
      final topicIdString = _prefs.getTopicID();
      final topicId = topicIdString != null ? int.tryParse(topicIdString) : null;

      if (chatId == null || chatId.isEmpty) {
        throw Exception('Chat ID not found in preferences');
      }

      // Prepare message using daily report template
      // TODO: Replace placeholder data with actual API data
      String message = DailyReportTemplate.generateDailyReport(
        date: DateTime.now().toString().split(' ')[0], // YYYY-MM-DD format
        time: DateTime.now().toString().split(' ')[1].substring(0, 8), // HH:MM:SS format
        fullName: _prefs.getUserName() ?? 'Agent User',
        territory: 'Tashkent', // TODO: Get from API
        phone: '+998901234567', // TODO: Get from API
        territoryList: 'Tashkent Region', // TODO: Get from API
        okbTerritory: '150', // TODO: Get from API
        visitedPoints: '25', // TODO: Get from API
        activeClients: '20', // TODO: Get from API
        region: 'Tashkent Center', // TODO: Get from API
        akbRegion: '75', // TODO: Get from API
        cash: '2,500,000', // TODO: Get from API
        nonCash: '1,750,000', // TODO: Get from API
        totalOrders: '4,250,000', // TODO: Get from API
        product1: 'Kosmetika', // TODO: Get from API
        quantity1: '50', // TODO: Get from API
        product2: 'Parfum', // TODO: Get from API
        quantity2: '30', // TODO: Get from API
        product3: 'Shampun', // TODO: Get from API
        quantity3: '25', // TODO: Get from API
        product4: 'Krem', // TODO: Get from API
        quantity4: '40', // TODO: Get from API
        product5: 'Loson', // TODO: Get from API
        quantity5: '15', // TODO: Get from API
        product6: 'Maskara', // TODO: Get from API
        quantity6: '35', // TODO: Get from API
        monthlyPlan: '50,000,000', // TODO: Get from API
        monthlyFact: '42,500,000', // TODO: Get from API
        factPercent: '85', // TODO: Get from API
        forecast: '48,000,000', // TODO: Get from API
        forecastPercent: '96', // TODO: Get from API
        okb: '180', // TODO: Get from API
        akbPlan: '100', // TODO: Get from API
        akbFact: '85', // TODO: Get from API
        akbPercent: '85', // TODO: Get from API
      );

      // Prepare request data
      Map<String, dynamic> data = {
        'chat_id': chatId,
        'text': message,
      };

      if (topicId != null) {
        data['message_thread_id'] = topicId;
      }

      // Send message via Telegram API
      final response = await _dio.post(
        'https://api.telegram.org/bot$botToken/sendMessage',
        data: data,
      );

      if (response.statusCode == 200) {
        // Log success
        print('Telegram Bot: Message sent successfully.');

        // Show success feedback
        _showSnackBar(context, 'Hisobot muvaffaqiyatli yuborildi!');

        // Update SharedPreferences on success
        await _prefs.setReportSentToTelegram(true);

        return true;
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      // Log error
      print('Telegram Bot Error: $e');

      // Show error UI feedback
      _showSnackBar(context, 'Xatolik: $e', isError: true);

      return false;
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}