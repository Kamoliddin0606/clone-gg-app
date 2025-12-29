import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloria_marketing_flutter/src/core/models/access_check_result.dart';
import 'package:gloria_marketing_flutter/src/core/services/startup_access_service.dart';

/// =============================================================================
/// Startup Access BLoC
/// =============================================================================
/// 
/// Bu BLoC ilova ishga tushganda qurilma va account access tekshiruvini boshqaradi.
/// =============================================================================

// ============================================================================
// EVENTS
// ============================================================================

abstract class StartupAccessEvent {}

/// Access tekshiruvini boshlash
class CheckAccessEvent extends StartupAccessEvent {}

/// Qayta tekshirish
class RetryAccessCheckEvent extends StartupAccessEvent {}

/// Holatni tozalash
class ResetAccessStateEvent extends StartupAccessEvent {}

// ============================================================================
// STATES
// ============================================================================

abstract class StartupAccessState {}

/// Boshlang'ich holat
class StartupAccessInitial extends StartupAccessState {}

/// Tekshiruv jarayonida
class StartupAccessLoading extends StartupAccessState {}

/// Ruxsat berildi
class StartupAccessAllowed extends StartupAccessState {
  final int? riskScore;
  
  StartupAccessAllowed({this.riskScore});
}

/// Bloklangan
class StartupAccessBlocked extends StartupAccessState {
  final AccessBlockReason reason;
  final String message;
  final int? riskScore;
  
  StartupAccessBlocked({
    required this.reason,
    required this.message,
    this.riskScore,
  });
}

/// Xatolik yuz berdi
class StartupAccessError extends StartupAccessState {
  final String message;
  
  StartupAccessError({required this.message});
}

/// Login qilinmagan
class StartupAccessNotLoggedIn extends StartupAccessState {}

// ============================================================================
// BLOC
// ============================================================================

class StartupAccessBloc extends Bloc<StartupAccessEvent, StartupAccessState> {
  final StartupAccessService _accessService;

  StartupAccessBloc({
    required StartupAccessService accessService,
  })  : _accessService = accessService,
        super(StartupAccessInitial()) {
    on<CheckAccessEvent>(_onCheckAccess);
    on<RetryAccessCheckEvent>(_onRetryAccessCheck);
    on<ResetAccessStateEvent>(_onResetAccessState);
  }

  /// Access tekshiruvini bajarish
  Future<void> _onCheckAccess(
    CheckAccessEvent event,
    Emitter<StartupAccessState> emit,
  ) async {
    emit(StartupAccessLoading());

    try {
      // Foydalanuvchi login qilganmi tekshirish
      if (!_accessService.isUserLoggedIn()) {
        emit(StartupAccessNotLoggedIn());
        return;
      }

      // Access tekshiruvi
      final result = await _accessService.checkAccess();

      if (result.isAllowed) {
        emit(StartupAccessAllowed(riskScore: result.riskScore));
      } else {
        emit(StartupAccessBlocked(
          reason: result.reason ?? AccessBlockReason.unknown,
          message: result.displayMessage,
          riskScore: result.riskScore,
        ));
      }
    } catch (e) {
      emit(StartupAccessError(message: e.toString()));
    }
  }

  /// Qayta tekshirish
  Future<void> _onRetryAccessCheck(
    RetryAccessCheckEvent event,
    Emitter<StartupAccessState> emit,
  ) async {
    add(CheckAccessEvent());
  }

  /// Holatni tozalash
  void _onResetAccessState(
    ResetAccessStateEvent event,
    Emitter<StartupAccessState> emit,
  ) {
    emit(StartupAccessInitial());
  }
}
