import 'package:gloria_marketing_flutter/src/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.username,
    required super.fullName,
    required super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      fullName: json['fullName'],
      role: json['role'],
    );
  }

  factory UserModel.fromSoap(Map<String, dynamic> soapResponse) {
    return UserModel(
      id: soapResponse['Code'],
      username: '', // Username is not in the response, should be passed from request
      fullName: soapResponse['Name'],
      role: _mapUserType(soapResponse['Type']),
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'role': role,
    };
  }
}