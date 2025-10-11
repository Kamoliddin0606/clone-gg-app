import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/telegram_token_service.dart';

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

      // Prepare message
      String message = 'Hisobot yuborildi. xabar mobile ilova orqali yuborildi';
      // TODO: Add actual report data here

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