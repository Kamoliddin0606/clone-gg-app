import 'package:gloria_marketing_flutter/src/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login({
    required String username,
    required String password,
    String? appVersion, // Optional: For GetUserEx SOAP method
  });

  // TODO: Add other auth methods like logout, checkStatus, etc.
}