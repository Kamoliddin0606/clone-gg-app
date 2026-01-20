import 'package:gloria_marketing_flutter/src/features/time_verification/domain/entities/server_time_entity.dart';

/// Repository interface for time verification operations
/// 
/// Defines contract for fetching server time and time limit from API
abstract class TimeVerificationRepository {
  /// Fetch current server time and time limit from GetServerTime API
  /// 
  /// Returns [ServerTimeEntity] containing:
  /// - serverTime: Current server time
  /// - timeLimit: User access expiration time
  /// 
  /// Throws:
  /// - [ConnectivityException] if network connection fails
  /// - [ServerException] if server returns error or SOAP Fault
  /// - [AllServersUnavailableException] if all server URLs fail
  Future<ServerTimeEntity> getServerTime();
}
