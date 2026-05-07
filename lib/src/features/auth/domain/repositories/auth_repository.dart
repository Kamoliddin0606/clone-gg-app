import 'package:gloria_marketing_flutter/src/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  /// Establishes the 1C SOAP session (used by inventory / pricing /
  /// orders downstream). Called ONLY after V2 JWT authentication has
  /// already succeeded — this is **not** an authentication step on its
  /// own.
  ///
  /// Throws [OneCUserNotFoundException] when 1C does not recognize the
  /// V2-authenticated user; the bloc surfaces it as a localized banner.
  /// Other failures rethrow whatever the SOAP layer produced.
  Future<UserEntity> establish1cSession({
    required String username,
    required String password,
    String? appVersion, // Optional: For GetUserEx SOAP method
  });
}