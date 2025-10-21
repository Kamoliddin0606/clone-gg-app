import 'package:equatable/equatable.dart';

/// Model for planned route data from server
class PlannedRoute extends Equatable {
  final int id;
  final String userCode;
  final int codeWeekday;
  final String weekDay;
  final String codeClient;
  final String clientName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlannedRoute({
    required this.id,
    required this.userCode,
    required this.codeWeekday,
    required this.weekDay,
    required this.codeClient,
    required this.clientName,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from map (database row)
  factory PlannedRoute.fromMap(Map<String, dynamic> map) {
    return PlannedRoute(
      id: map['id'] as int,
      userCode: map['user_code'] as String,
      codeWeekday: map['code_weekday'] as int,
      weekDay: map['week_day'] as String,
      codeClient: map['code_client'] as String,
      clientName: map['client_name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert to map (for database storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_code': userCode,
      'code_weekday': codeWeekday,
      'week_day': weekDay,
      'code_client': codeClient,
      'client_name': clientName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create copy with updated fields
  PlannedRoute copyWith({
    int? id,
    String? userCode,
    int? codeWeekday,
    String? weekDay,
    String? codeClient,
    String? clientName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlannedRoute(
      id: id ?? this.id,
      userCode: userCode ?? this.userCode,
      codeWeekday: codeWeekday ?? this.codeWeekday,
      weekDay: weekDay ?? this.weekDay,
      codeClient: codeClient ?? this.codeClient,
      clientName: clientName ?? this.clientName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userCode,
        codeWeekday,
        weekDay,
        codeClient,
        clientName,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'PlannedRoute(id: $id, userCode: $userCode, codeWeekday: $codeWeekday, weekDay: $weekDay, codeClient: $codeClient, clientName: $clientName)';
  }
}