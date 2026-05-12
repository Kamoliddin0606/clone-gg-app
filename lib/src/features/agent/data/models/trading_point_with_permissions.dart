import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';

/// Model combining TradingPoint with user permissions for efficient UI rendering
class TradingPointWithPermissions {
  final TradingPoint tradingPoint;
  final SalesReqPermissions? permissions;

  const TradingPointWithPermissions({
    required this.tradingPoint,
    this.permissions,
  });

  /// Factory constructor to create from database row
  factory TradingPointWithPermissions.fromMap(Map<String, dynamic> map) {
    // Create TradingPoint from the map
    final tradingPoint = TradingPoint(
      id: map['code'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      phone: map['phone'] as String? ?? '',
      ownerName: map['owner_name'] as String? ?? '',
      contactPerson: map['contact_person'] as String? ?? '',
      inn: map['inn'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      lastVisitDate: map['last_visit_date'] as String? ?? '',
      hasOrders: (map['has_orders'] as int?) == 1,
      hasContracts: (map['has_contracts'] as int?) == 1,
      isVisited: (map['is_visited'] as int?) == 1,
      hasContract: (map['has_contract'] as int?) == 1,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      region: map['region'] as String? ?? '',
      district: map['district'] as String? ?? '',
      signboard: map['signboard'] as String? ?? '',
      referencePoint: map['reference_point'] as String? ?? '',
      responsiblePerson: map['responsible_person'] as String? ?? '',
      responsiblePersonPhone: map['responsible_person_phone'] as String? ?? '',
      tradePointType: map['trade_point_type'] as String? ?? '',
      creditLimit: (map['credit_limit'] as num?)?.toDouble() ?? 0.0,
      accumulatedCredit: (map['accumulated_credit'] as num?)?.toDouble() ?? 0.0,
      codeRegion: map['code_region'] as String? ?? '',
      visitToday: (map['visit_today'] as int?) == 1,
      visitStepNumber: map['visit_step_number'] as int? ?? 0,
      plannedWeekDay: map['planned_week_day'] as String?,
    );

    // Create permissions if available
    SalesReqPermissions? permissions;
    if (map['permissions_id'] != null) {
      permissions = SalesReqPermissions(
        id: map['permissions_id'] as int,
        userCode: map['user_code'] as String,
        skipTINduplicateCheck: (map['skip_tin_duplicate_check'] as int?) == 1,
        allowCreationWithoutTIN: (map['allow_creation_without_tin'] as int?) == 1,
        visit: (map['visit'] as int?) == 1,
        strictSequence: (map['strict_sequence'] as int?) == 1,
        unplannedOrder: (map['unplanned_order'] as int?) == 1,
        plannedRoute: (map['planned_route'] as int?) == 1,
        editClientCoordinates: (map['edit_client_coordinates'] as int?) == 1,
        // Yangi qo'shilgan maydonlar: mijoz zona kirish va joylashuv yangilanish intervali
        clientZoneAccess: (map['client_zone_access'] as int?) ?? 0,
        locationUpdateInterval: (map['location_update_interval'] as int?) ?? 0,
        createdAt: DateTime.now(), // Default values since not in JOIN
        updatedAt: DateTime.now(),
        visitSteps: [], // Will be loaded separately if needed
      );
    }

    return TradingPointWithPermissions(
      tradingPoint: tradingPoint,
      permissions: permissions,
    );
  }

  /// Check if user can visit this trading point
  bool get canVisit => permissions?.visit ?? true;

  /// Check if user can create unplanned orders for this trading point
  bool get canCreateUnplannedOrder => permissions?.unplannedOrder ?? true;

  /// Check if user can view contracts for this trading point
  bool get canViewContracts => tradingPoint.hasContract;

  /// Visit today flag (computed from trading point data)
  bool get visitToday => tradingPoint.visitToday;

  /// Strict visit sequence flag (computed from permissions)
  bool get strictVisitSequence => permissions?.strictSequence ?? false;

  /// Visit step number (computed from trading point data)
  int get visitStepNumber => tradingPoint.visitStepNumber;

  /// Planned week day text (computed from trading point data)
  String? get plannedWeekDay => tradingPoint.plannedWeekDay;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TradingPointWithPermissions &&
        other.tradingPoint == tradingPoint &&
        other.permissions == permissions;
  }

  @override
  int get hashCode => tradingPoint.hashCode ^ permissions.hashCode;

  @override
  String toString() {
    return 'TradingPointWithPermissions(tradingPoint: $tradingPoint, permissions: $permissions, visitToday: $visitToday, strictVisitSequence: $strictVisitSequence, visitStepNumber: $visitStepNumber)';
  }
}