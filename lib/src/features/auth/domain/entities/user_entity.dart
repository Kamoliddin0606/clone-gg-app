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

  /// Backend-suggested default project for `customer_scope=project` tenants.
  /// Sourced from `gates.primary_project_id` in the login response.
  /// `null` when the org runs in `customer_scope=organization` mode or
  /// the backend hasn't shipped the field yet.
  final String? primaryProjectId;

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
    this.primaryProjectId,
  });

  @override
  List<Object?> get props => [id, username, fullName, role, code, name, warehouseCode, codeProject, baseUrl, telegramID, chatID, topicID, primaryProjectId];
}