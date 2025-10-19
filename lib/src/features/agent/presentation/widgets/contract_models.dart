import 'package:flutter/material.dart';

enum ContractStatus { all, active, inactive, expired, pending }

class ContractsFilterState {
  Set<String> tradingPointCodes; // multi-select trading points by code
  DateTimeRange? dateRange;
  ContractStatus? status;

  ContractsFilterState({
    Set<String>? tradingPointCodes,
    this.dateRange,
    this.status,
  }) : tradingPointCodes = tradingPointCodes ?? {};

  ContractsFilterState copyWith({
    Set<String>? tradingPointCodes,
    DateTimeRange? dateRange,
    ContractStatus? status,
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