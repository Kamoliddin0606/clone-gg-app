import 'package:equatable/equatable.dart';

import '../../data/models/trading_point.dart';

/// Discrete action the cubit is currently performing — lets the UI
/// distinguish "submitting create" vs "submitting coordinates" so two
/// concurrent sheets stay coherent.
enum CustomerWriteAction { none, create, updateProfile, updateCoordinates }

/// Status of the most recent action — UI listens to transitions
/// `submitting → success / error` and pops the sheet on success.
enum CustomerWriteStatus { initial, submitting, success, error }

/// State machine for [CustomerWriteCubit]. Holds the most recent
/// submitted row on success and a typed `errorCode` (ARB key, NOT
/// user-facing copy) on failure.
class CustomerWriteState extends Equatable {
  final CustomerWriteStatus status;
  final CustomerWriteAction action;
  final TradingPoint? lastResult;
  final String? errorCode;
  final Map<String, dynamic>? errorDetails;

  const CustomerWriteState({
    this.status = CustomerWriteStatus.initial,
    this.action = CustomerWriteAction.none,
    this.lastResult,
    this.errorCode,
    this.errorDetails,
  });

  bool get isSubmitting => status == CustomerWriteStatus.submitting;

  CustomerWriteState copyWith({
    CustomerWriteStatus? status,
    CustomerWriteAction? action,
    TradingPoint? lastResult,
    String? errorCode,
    Map<String, dynamic>? errorDetails,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return CustomerWriteState(
      status: status ?? this.status,
      action: action ?? this.action,
      lastResult: clearResult ? null : (lastResult ?? this.lastResult),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      errorDetails:
          clearError ? null : (errorDetails ?? this.errorDetails),
    );
  }

  @override
  List<Object?> get props =>
      [status, action, lastResult, errorCode, errorDetails];
}
