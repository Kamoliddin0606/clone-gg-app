class SalesReqPermissions {
  final int? id;
  final String userCode;
  final bool skipTINduplicateCheck;
  final bool allowCreationWithoutTIN;
  final bool allowCreatingPointOfSale;
  final bool visit;
  final bool strictSequence;
  final bool unplannedOrder;
  final bool plannedRoute;
  final bool editClientCoordinates;
  final int clientZoneAccess;
  final int locationUpdateInterval;
  final List<VisitStep> visitSteps;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SalesReqPermissions({
    this.id,
    required this.userCode,
    required this.skipTINduplicateCheck,
    required this.allowCreationWithoutTIN,
    required this.allowCreatingPointOfSale,
    required this.visit,
    required this.strictSequence,
    required this.unplannedOrder,
    required this.plannedRoute,
    required this.editClientCoordinates,
    this.clientZoneAccess = 0,
    this.locationUpdateInterval = 0,
    required this.visitSteps,
    this.createdAt,
    this.updatedAt,
  });

  factory SalesReqPermissions.fromMap(Map<String, dynamic> map) {
    return SalesReqPermissions(
      id: map['id'] as int?,
      userCode: map['user_code'] as String,
      skipTINduplicateCheck: (map['skip_tin_duplicate_check'] as int?) == 1,
      allowCreationWithoutTIN: (map['allow_creation_without_tin'] as int?) == 1,
      allowCreatingPointOfSale: (map['allow_creating_point_of_sale'] as int?) == 1,
      visit: (map['visit'] as int?) == 1,
      strictSequence: (map['strict_sequence'] as int?) == 1,
      unplannedOrder: (map['unplanned_order'] as int?) == 1,
      plannedRoute: (map['planned_route'] as int?) == 1,
      editClientCoordinates: (map['edit_client_coordinates'] as int?) == 1,
      clientZoneAccess: (map['client_zone_access'] as int?) ?? 0,
      locationUpdateInterval: (map['location_update_interval'] as int?) ?? 0,
      visitSteps: [], // Will be populated separately
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_code': userCode,
      'skip_tin_duplicate_check': skipTINduplicateCheck ? 1 : 0,
      'allow_creation_without_tin': allowCreationWithoutTIN ? 1 : 0,
      'allow_creating_point_of_sale': allowCreatingPointOfSale ? 1 : 0,
      'visit': visit ? 1 : 0,
      'strict_sequence': strictSequence ? 1 : 0,
      'unplanned_order': unplannedOrder ? 1 : 0,
      'planned_route': plannedRoute ? 1 : 0,
      'edit_client_coordinates': editClientCoordinates ? 1 : 0,
      'client_zone_access': clientZoneAccess,
      'location_update_interval': locationUpdateInterval,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  SalesReqPermissions copyWith({
    int? id,
    String? userCode,
    bool? skipTINduplicateCheck,
    bool? allowCreationWithoutTIN,
    bool? allowCreatingPointOfSale,
    bool? visit,
    bool? strictSequence,
    bool? unplannedOrder,
    bool? plannedRoute,
    bool? editClientCoordinates,
    int? clientZoneAccess,
    int? locationUpdateInterval,
    List<VisitStep>? visitSteps,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SalesReqPermissions(
      id: id ?? this.id,
      userCode: userCode ?? this.userCode,
      skipTINduplicateCheck: skipTINduplicateCheck ?? this.skipTINduplicateCheck,
      allowCreationWithoutTIN: allowCreationWithoutTIN ?? this.allowCreationWithoutTIN,
      allowCreatingPointOfSale: allowCreatingPointOfSale ?? this.allowCreatingPointOfSale,
      visit: visit ?? this.visit,
      strictSequence: strictSequence ?? this.strictSequence,
      unplannedOrder: unplannedOrder ?? this.unplannedOrder,
      plannedRoute: plannedRoute ?? this.plannedRoute,
      editClientCoordinates: editClientCoordinates ?? this.editClientCoordinates,
      clientZoneAccess: clientZoneAccess ?? this.clientZoneAccess,
      locationUpdateInterval: locationUpdateInterval ?? this.locationUpdateInterval,
      visitSteps: visitSteps ?? this.visitSteps,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class VisitStep {
  final int? id;
  final int? salesReqPermissionsId;
  final int stepCode;
  final String stepName;
  final bool stepRequired;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VisitStep({
    this.id,
    this.salesReqPermissionsId,
    required this.stepCode,
    required this.stepName,
    required this.stepRequired,
    this.createdAt,
    this.updatedAt,
  });

  factory VisitStep.fromMap(Map<String, dynamic> map) {
    return VisitStep(
      id: map['id'] as int?,
      salesReqPermissionsId: map['sales_req_permissions_id'] as int?,
      stepCode: map['step_code'] as int,
      stepName: map['step_name'] as String,
      stepRequired: (map['step_required'] as int?) == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sales_req_permissions_id': salesReqPermissionsId,
      'step_code': stepCode,
      'step_name': stepName,
      'step_required': stepRequired ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  VisitStep copyWith({
    int? id,
    int? salesReqPermissionsId,
    int? stepCode,
    String? stepName,
    bool? stepRequired,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VisitStep(
      id: id ?? this.id,
      salesReqPermissionsId: salesReqPermissionsId ?? this.salesReqPermissionsId,
      stepCode: stepCode ?? this.stepCode,
      stepName: stepName ?? this.stepName,
      stepRequired: stepRequired ?? this.stepRequired,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}