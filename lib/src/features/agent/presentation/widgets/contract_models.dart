import 'package:flutter/material.dart';

/// Contract status groups based on business logic
enum ContractStatusGroup {
  all,           // Hammasi - barcha shartnomalar
  active,        // Amalda - Действует + active=true + muddat kelajakda
  expired,       // Muddati o'tgan - Действует + active=true + muddat o'tgan
  cancelled,     // Bekor qilingan - active=false (har qanday status)
  pending,       // Tastiqlanmagan - Не согласован + active=true + muddat kelajakda
}

/// Efficiently calculate contract status group
/// Uses minimal memory and fast comparison operations
ContractStatusGroup calculateContractStatus({
  required String status,
  required bool active,
  DateTime? termOfContract,
}) {
  // Fast path: if not active, always cancelled
  if (!active) return ContractStatusGroup.cancelled;
  
  // Check status string (case-sensitive for performance)
  final isActive = status == 'Действует';
  final isPending = status == 'Не согласован';
  
  // Handle pending contracts
  if (isPending) {
    // Pending contracts with active=true and valid term
    if (termOfContract != null && termOfContract.isAfter(DateTime.now())) {
      return ContractStatusGroup.pending;
    }
    // Pending with expired term or no term - treat as cancelled
    return ContractStatusGroup.cancelled;
  }
  
  // Handle active contracts
  if (isActive) {
    // Check term expiration
    if (termOfContract != null) {
      return termOfContract.isAfter(DateTime.now())
          ? ContractStatusGroup.active
          : ContractStatusGroup.expired;
    }
    // No term specified - treat as active
    return ContractStatusGroup.active;
  }
  
  // Default fallback for unknown statuses
  return ContractStatusGroup.cancelled;
}

/// Legacy enum for backward compatibility during migration
enum ContractStatus { all, active, inactive, expired, pending }

class ContractsFilterState {
  Set<String> tradingPointCodes; // multi-select trading points by code
  DateTimeRange? dateRange;
  ContractStatusGroup? status;

  ContractsFilterState({
    Set<String>? tradingPointCodes,
    this.dateRange,
    this.status,
  }) : tradingPointCodes = tradingPointCodes ?? {};

  ContractsFilterState copyWith({
    Set<String>? tradingPointCodes,
    DateTimeRange? dateRange,
    ContractStatusGroup? status,
  }) {
    return ContractsFilterState(
      tradingPointCodes: tradingPointCodes ?? this.tradingPointCodes,
      dateRange: dateRange ?? this.dateRange,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContractsFilterState &&
        other.tradingPointCodes == tradingPointCodes &&
        other.dateRange == dateRange &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(tradingPointCodes, dateRange, status);
}