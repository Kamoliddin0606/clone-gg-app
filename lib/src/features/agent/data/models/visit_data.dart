import 'dart:convert';

/// VisitData model for storing visit step data persistently
/// This model handles all data associated with visit steps including
/// photos, forms, orders, and audit data
class VisitData {
  final int? id;
  final String visitId; // Unique identifier for the visit session
  final String clientCode; // Client being visited
  final int stepCode; // Step identifier
  final String stepName; // Step name for reference
  final String dataType; // Type of data: 'photo', 'form', 'order', 'audit', 'note'
  final String dataContent; // JSON string containing the actual data
  final DateTime timestamp; // When this data was created/modified
  final bool isSynced; // Whether this data has been synced to server
  final DateTime? syncedAt; // When it was last synced
  final String? syncError; // Error message if sync failed

  VisitData({
    this.id,
    required this.visitId,
    required this.clientCode,
    required this.stepCode,
    required this.stepName,
    required this.dataType,
    required this.dataContent,
    required this.timestamp,
    this.isSynced = false,
    this.syncedAt,
    this.syncError,
  });

  factory VisitData.fromMap(Map<String, dynamic> map) {
    return VisitData(
      id: map['id'] as int?,
      visitId: map['visit_id'] as String,
      clientCode: map['client_code'] as String,
      stepCode: map['step_code'] as int,
      stepName: map['step_name'] as String,
      dataType: map['data_type'] as String,
      dataContent: map['data_content'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
      syncedAt: map['synced_at'] != null ? DateTime.parse(map['synced_at'] as String) : null,
      syncError: map['sync_error'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'visit_id': visitId,
      'client_code': clientCode,
      'step_code': stepCode,
      'step_name': stepName,
      'data_type': dataType,
      'data_content': dataContent,
      'timestamp': timestamp.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'synced_at': syncedAt?.toIso8601String(),
      'sync_error': syncError,
    };
  }

  VisitData copyWith({
    int? id,
    String? visitId,
    String? clientCode,
    int? stepCode,
    String? stepName,
    String? dataType,
    String? dataContent,
    DateTime? timestamp,
    bool? isSynced,
    DateTime? syncedAt,
    String? syncError,
  }) {
    return VisitData(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      clientCode: clientCode ?? this.clientCode,
      stepCode: stepCode ?? this.stepCode,
      stepName: stepName ?? this.stepName,
      dataType: dataType ?? this.dataType,
      dataContent: dataContent ?? this.dataContent,
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
      syncedAt: syncedAt ?? this.syncedAt,
      syncError: syncError ?? this.syncError,
    );
  }

  // Helper methods for data content handling
  Map<String, dynamic> get parsedDataContent {
    try {
      return json.decode(dataContent) as Map<String, dynamic>;
    } catch (e) {
      return {'raw_content': dataContent};
    }
  }

  VisitData withDataContent(Map<String, dynamic> data) {
    return copyWith(dataContent: json.encode(data));
  }

  // Factory constructors for different data types
  factory VisitData.photo({
    required String visitId,
    required String clientCode,
    required int stepCode,
    required String stepName,
    required String imagePath,
    required String thumbnailPath,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    final data = {
      'image_path': imagePath,
      'thumbnail_path': thumbnailPath,
      'description': description,
      'metadata': metadata,
      'created_at': DateTime.now().toIso8601String(),
    };

    return VisitData(
      visitId: visitId,
      clientCode: clientCode,
      stepCode: stepCode,
      stepName: stepName,
      dataType: 'photo',
      dataContent: json.encode(data),
      timestamp: DateTime.now(),
    );
  }

  factory VisitData.form({
    required String visitId,
    required String clientCode,
    required int stepCode,
    required String stepName,
    required Map<String, dynamic> formData,
  }) {
    return VisitData(
      visitId: visitId,
      clientCode: clientCode,
      stepCode: stepCode,
      stepName: stepName,
      dataType: 'form',
      dataContent: json.encode(formData),
      timestamp: DateTime.now(),
    );
  }

  factory VisitData.order({
    required String visitId,
    required String clientCode,
    required int stepCode,
    required String stepName,
    required Map<String, dynamic> orderData,
  }) {
    return VisitData(
      visitId: visitId,
      clientCode: clientCode,
      stepCode: stepCode,
      stepName: stepName,
      dataType: 'order',
      dataContent: json.encode(orderData),
      timestamp: DateTime.now(),
    );
  }

  factory VisitData.audit({
    required String visitId,
    required String clientCode,
    required int stepCode,
    required String stepName,
    required Map<String, dynamic> auditData,
  }) {
    return VisitData(
      visitId: visitId,
      clientCode: clientCode,
      stepCode: stepCode,
      stepName: stepName,
      dataType: 'audit',
      dataContent: json.encode(auditData),
      timestamp: DateTime.now(),
    );
  }

  factory VisitData.note({
    required String visitId,
    required String clientCode,
    required int stepCode,
    required String stepName,
    required String note,
  }) {
    final data = {
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
    };

    return VisitData(
      visitId: visitId,
      clientCode: clientCode,
      stepCode: stepCode,
      stepName: stepName,
      dataType: 'note',
      dataContent: json.encode(data),
      timestamp: DateTime.now(),
    );
  }
}

/// Enum for data types to ensure type safety
enum VisitDataType {
  photo,
  form,
  order,
  audit,
  note,
}

extension VisitDataTypeExtension on VisitDataType {
  String get value {
    switch (this) {
      case VisitDataType.photo:
        return 'photo';
      case VisitDataType.form:
        return 'form';
      case VisitDataType.order:
        return 'order';
      case VisitDataType.audit:
        return 'audit';
      case VisitDataType.note:
        return 'note';
    }
  }

  static VisitDataType fromString(String value) {
    switch (value) {
      case 'photo':
        return VisitDataType.photo;
      case 'form':
        return VisitDataType.form;
      case 'order':
        return VisitDataType.order;
      case 'audit':
        return VisitDataType.audit;
      case 'note':
        return VisitDataType.note;
      default:
        throw ArgumentError('Unknown VisitDataType: $value');
    }
  }
}