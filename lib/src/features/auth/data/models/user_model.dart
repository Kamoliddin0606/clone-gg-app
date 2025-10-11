import 'package:gloria_marketing_flutter/src/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.username,
    required super.fullName,
    required super.role,
    required super.code,
    required super.name,
    required super.warehouseCode,
    required super.codeProject,
    required super.baseUrl,
    required super.telegramID,
    required super.chatID,
    required super.topicID,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final baseUrl = json['baseUrl'] ?? '';
    if (baseUrl.isNotEmpty && !_isValidUrl(baseUrl)) {
      throw FormatException('Invalid baseUrl format: $baseUrl');
    }
    return UserModel(
      id: json['id'],
      username: json['username'],
      fullName: json['fullName'],
      role: json['role'],
      code: json['code'],
      name: json['name'],
      warehouseCode: json['warehouseCode'],
      codeProject: json['codeProject'] ?? '',
      baseUrl: baseUrl,
      telegramID: json['telegramID'] ?? '',
      chatID: json['chatID'] ?? '',
      topicID: json['topicID'] ?? '',
    );
  }

  factory UserModel.fromSoap(Map<String, dynamic> soapResponse, {String? username, required String baseUrl}) {
    if (baseUrl.isNotEmpty && !_isValidUrl(baseUrl)) {
      throw FormatException('Invalid baseUrl format: $baseUrl');
    }
    // Log new parameters for debugging
    print('TelegramID: ${soapResponse['TelegramID'] ?? 'N/A'}');
    print('ChatID: ${soapResponse['ChatID'] ?? 'N/A'}');
    print('TopicID: ${soapResponse['TopicID'] ?? 'N/A'}');

    return UserModel(
      id: soapResponse['Code'],
      username: username ?? '', // Username is passed from request
      fullName: soapResponse['Name'],
      role: _mapUserType(soapResponse['Type']),
      code: soapResponse['Code'],
      name: soapResponse['Name'],
      warehouseCode: soapResponse['WarehouseCode'] ?? '',
      codeProject: soapResponse['CodeProject'] ?? '',
      baseUrl: baseUrl,
      telegramID: soapResponse['TelegramID'] ?? '',
      chatID: soapResponse['ChatID'] ?? '',
      topicID: soapResponse['TopicID'] ?? '',
    );
  }

  static String _mapUserType(String type) {
    // This logic is based on UserType.java
    switch (int.tryParse(type) ?? 0) {
      case 1:
        return 'Agent';
      case 2:
        return 'Forwarder';
      case 3:
        return 'Supervisor';
      case 4:
        return 'Boss';
      case 5:
        return 'Collector';
      case 6:
        return 'Packer';
      case 7:
        return 'WarehouseManager';
      default:
        return 'Unknown';
    }
  }

  static bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'role': role,
      'code': code,
      'name': name,
      'warehouseCode': warehouseCode,
      'codeProject': codeProject,
      'baseUrl': baseUrl,
      'telegramID': telegramID,
      'chatID': chatID,
      'topicID': topicID,
    };
  }
}