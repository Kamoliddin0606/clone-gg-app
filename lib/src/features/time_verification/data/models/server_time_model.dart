import 'package:gloria_marketing_flutter/src/features/time_verification/domain/entities/server_time_entity.dart';

/// Data model for server time response from SOAP API
/// 
/// Extends [ServerTimeEntity] and provides factory for parsing SOAP XML response
class ServerTimeModel extends ServerTimeEntity {
  const ServerTimeModel({
    required super.serverTime,
    required super.timeLimit,
  });

  /// Factory constructor to create model from SOAP XML response
  /// 
  /// Expected XML structure:
  /// ```xml
  /// <m:return>
  ///   <m:DateTime>2026-01-20T09:45:45</m:DateTime>
  ///   <m:DateTimeLimit>2026-01-20T00:00:00</m:DateTimeLimit>
  /// </m:return>
  /// ```
  /// 
  /// Parameters:
  /// - [dateTimeStr]: ISO 8601 formatted server time string
  /// - [dateLimitStr]: ISO 8601 formatted time limit string
  factory ServerTimeModel.fromSoap({
    required String dateTimeStr,
    required String dateLimitStr,
  }) {
    return ServerTimeModel(
      serverTime: DateTime.parse(dateTimeStr),
      timeLimit: DateTime.parse(dateLimitStr),
    );
  }

  /// Convert model to entity
  ServerTimeEntity toEntity() {
    return ServerTimeEntity(
      serverTime: serverTime,
      timeLimit: timeLimit,
    );
  }

  @override
  String toString() {
    return 'ServerTimeModel(serverTime: $serverTime, timeLimit: $timeLimit)';
  }
}
