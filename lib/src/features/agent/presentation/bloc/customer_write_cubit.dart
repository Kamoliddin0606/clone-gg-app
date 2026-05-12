import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/customer_write_repository.dart';
import 'customer_write_state.dart';

/// State holder for the customer create / edit / coordinates sheets.
///
/// Concurrency rule: while [CustomerWriteState.isSubmitting], further
/// calls short-circuit with an `in_flight` error rather than stacking
/// — protects against double-tap on the save button.
///
/// After a successful action the cubit emits
/// [CustomerWriteStatus.success] with the new row in `lastResult` so
/// the parent feature can `BlocListener` for it and refresh the
/// trading-points list without re-fetching from the network.
class CustomerWriteCubit extends Cubit<CustomerWriteState> {
  final CustomerWriteRepository _repo;

  CustomerWriteCubit({required CustomerWriteRepository repo})
      : _repo = repo,
        super(const CustomerWriteState());

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> create({
    required String code1c,
    required String name,
    String inn = '',
    String phone = '',
    String address = '',
    double? latitude,
    double? longitude,
  }) async {
    if (state.isSubmitting) {
      _emitInFlight();
      return;
    }
    emit(state.copyWith(
      status: CustomerWriteStatus.submitting,
      action: CustomerWriteAction.create,
      clearError: true,
      clearResult: true,
    ));
    try {
      final row = await _repo.create(
        code1c: code1c,
        name: name,
        inn: inn,
        phone: phone,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
      emit(state.copyWith(
        status: CustomerWriteStatus.success,
        lastResult: row,
        clearError: true,
      ));
    } catch (e) {
      _emitError(e);
    }
  }

  Future<void> updateProfile({
    required String customerId,
    String? name,
    String? inn,
    String? phone,
    String? address,
  }) async {
    if (state.isSubmitting) {
      _emitInFlight();
      return;
    }
    emit(state.copyWith(
      status: CustomerWriteStatus.submitting,
      action: CustomerWriteAction.updateProfile,
      clearError: true,
      clearResult: true,
    ));
    try {
      final row = await _repo.updateProfile(
        customerId: customerId,
        name: name,
        inn: inn,
        phone: phone,
        address: address,
      );
      emit(state.copyWith(
        status: CustomerWriteStatus.success,
        lastResult: row,
        clearError: true,
      ));
    } catch (e) {
      _emitError(e);
    }
  }

  Future<void> updateCoordinates({
    required String customerId,
    required double latitude,
    required double longitude,
  }) async {
    if (state.isSubmitting) {
      _emitInFlight();
      return;
    }
    emit(state.copyWith(
      status: CustomerWriteStatus.submitting,
      action: CustomerWriteAction.updateCoordinates,
      clearError: true,
      clearResult: true,
    ));
    try {
      final row = await _repo.updateCoordinates(
        customerId: customerId,
        latitude: latitude,
        longitude: longitude,
      );
      emit(state.copyWith(
        status: CustomerWriteStatus.success,
        lastResult: row,
        clearError: true,
      ));
    } catch (e) {
      _emitError(e);
    }
  }

  /// Clear the pending error / success after the UI consumes it.
  void reset() {
    emit(const CustomerWriteState());
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _emitInFlight() {
    emit(state.copyWith(
      status: CustomerWriteStatus.error,
      errorCode: 'in_flight',
    ));
  }

  void _emitError(Object e) {
    if (e is CustomerWriteException) {
      emit(state.copyWith(
        status: CustomerWriteStatus.error,
        errorCode: e.code,
        errorDetails: e.details,
      ));
      return;
    }
    emit(state.copyWith(
      status: CustomerWriteStatus.error,
      errorCode: 'unknown_error',
    ));
  }
}
