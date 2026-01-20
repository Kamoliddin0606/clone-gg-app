import 'package:equatable/equatable.dart';

/// Entity representing server time and time limit from GetServerTime API
/// 
/// This entity contains:
/// - serverTime: Current server time (not stored, used for immediate verification)
/// - timeLimit: User access expiration time (stored in preferences)
class ServerTimeEntity extends Equatable {
  /// Current server time from the API
  final DateTime serverTime;
  
  /// Time limit until which user has access
  final DateTime timeLimit;

  const ServerTimeEntity({
    required this.serverTime,
    required this.timeLimit,
  });

  @override
  List<Object?> get props => [serverTime, timeLimit];

  @override
  String toString() {
    return 'ServerTimeEntity(serverTime: $serverTime, timeLimit: $timeLimit)';
  }

  /// Check if current server time has exceeded the time limit
  bool isExpired() {
    return serverTime.isAfter(timeLimit);
  }

  /// Get remaining time until expiration
  Duration getRemainingTime() {
    return timeLimit.difference(serverTime);
  }

  /// Check if time limit is valid (in the future)
  bool isValid() {
    return !isExpired();
  }
}
