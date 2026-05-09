import 'package:gloria_marketing_flutter/src/features/knowledge/domain/enums/assignment_target_type.dart';

import '_json_utils.dart';

class KnowledgeAssignment {
  final String id;
  final String organizationId;
  final String documentId;
  final AssignmentTargetType targetType;
  final String? targetRoleId;
  final String? targetUserId;
  final String? targetStaffId;
  final String? targetBranchId;
  final String? targetTerritoryId;
  final bool mandatory;
  final DateTime? dueAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const KnowledgeAssignment({
    required this.id,
    required this.organizationId,
    required this.documentId,
    this.targetType = AssignmentTargetType.unknown,
    this.targetRoleId,
    this.targetUserId,
    this.targetStaffId,
    this.targetBranchId,
    this.targetTerritoryId,
    this.mandatory = false,
    this.dueAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory KnowledgeAssignment.fromJson(Map<String, dynamic> json) {
    return KnowledgeAssignment(
      id: json['id'] as String,
      organizationId: (json['organization_id'] as String?) ?? '',
      documentId: json['document_id'] as String,
      targetType:
          AssignmentTargetTypeX.fromString(json['target_type'] as String?),
      targetRoleId: json['target_role_id'] as String?,
      targetUserId: json['target_user_id'] as String?,
      targetStaffId: json['target_staff_id'] as String?,
      targetBranchId: json['target_branch_id'] as String?,
      targetTerritoryId: json['target_territory_id'] as String?,
      mandatory: parseBool(json['mandatory']) ?? false,
      dueAt: json['due_at'] != null
          ? DateTime.tryParse(json['due_at'] as String)
          : null,
      updatedAt: DateTime.tryParse((json['updated_at'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'organization_id': organizationId,
        'document_id': documentId,
        'target_type': targetType.wireValue,
        'target_role_id': targetRoleId,
        'target_user_id': targetUserId,
        'target_staff_id': targetStaffId,
        'target_branch_id': targetBranchId,
        'target_territory_id': targetTerritoryId,
        'mandatory': mandatory ? 1 : 0,
        'due_at': dueAt?.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
      };

  factory KnowledgeAssignment.fromDbMap(Map<String, dynamic> row) {
    return KnowledgeAssignment(
      id: row['id'] as String,
      organizationId: (row['organization_id'] as String?) ?? '',
      documentId: row['document_id'] as String,
      targetType:
          AssignmentTargetTypeX.fromString(row['target_type'] as String?),
      targetRoleId: row['target_role_id'] as String?,
      targetUserId: row['target_user_id'] as String?,
      targetStaffId: row['target_staff_id'] as String?,
      targetBranchId: row['target_branch_id'] as String?,
      targetTerritoryId: row['target_territory_id'] as String?,
      mandatory: (row['mandatory'] as int? ?? 0) == 1,
      dueAt: row['due_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['due_at'] as int)
          : null,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (row['updated_at'] as int?) ?? 0),
      deletedAt: row['deleted_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['deleted_at'] as int)
          : null,
    );
  }
}
