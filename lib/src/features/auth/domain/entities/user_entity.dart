import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String fullName;
  final String role; // e.g., "agent", "boss", "collector"
  final String code; // User code for API calls
  final String name; // Display name
  final String warehouseCode; // Warehouse code
  final String codeProject; // Project code
  final String baseUrl; // Server base URL for API calls
  final String telegramID; // Telegram user ID
  final String chatID; // Telegram chat ID
  final String topicID; // Telegram topic ID

  const UserEntity({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.code,
    required this.name,
    required this.warehouseCode,
    required this.codeProject,
    required this.baseUrl,
    required this.telegramID,
    required this.chatID,
    required this.topicID,
  });

  @override
  List<Object?> get props => [id, username, fullName, role, code, name, warehouseCode, codeProject, baseUrl, telegramID, chatID, topicID];
}