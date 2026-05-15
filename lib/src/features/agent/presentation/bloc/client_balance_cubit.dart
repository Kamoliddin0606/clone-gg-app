/// ============================================================================
/// Client Balance Cubit
/// ============================================================================
/// Mijoz balansi state management uchun Cubit.
/// SOAP API orqali balans olish, kesh boshqarish va countdown logic.
/// ============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloria_marketing_flutter/src/core/services/client_balance_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/project_context.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';

import 'client_balance_state.dart';

/// ============================================================================
/// ClientBalanceCubit - Balans state boshqaruvchisi
/// ============================================================================
/// Vazifalar:
/// - API'dan balans olish
/// - Kesh bilan ishlash
/// - 10 soniyalik cooldown countdown
/// - Error handling va retry logic
class ClientBalanceCubit extends Cubit<ClientBalanceState> {
  /// Client balance service - API va DB operatsiyalari
  final ClientBalanceService _balanceService;

  /// Joriy mijoz INN raqami (cooldown va kesh kaliti uchun)
  final String inn;

  /// Joriy mijoz kodi (clients table bilan bog'lanish)
  final String? clientCode;

  /// 1C customer code — backend balance proxy uchun (`code_1c`).
  /// `TradingPoint.code1c` qiymati. Bo'sh bo'lsa REST so'rov yuborilmaydi.
  final String code1c;

  /// Countdown timer
  Timer? _countdownTimer;

  /// Auto-refresh timer (ixtiyoriy)
  Timer? _autoRefreshTimer;

  ClientBalanceCubit({
    required ClientBalanceService balanceService,
    required this.inn,
    required this.code1c,
    this.clientCode,
  })  : _balanceService = balanceService,
        super(ClientBalanceState.initial()) {
    // Dastlabki yuklanish
    _initialize();
  }

  /// ============================================================================
  /// Boshlang'ich yuklanish
  /// ============================================================================
  Future<void> _initialize() async {
    if (kDebugMode) {
      print('ClientBalanceCubit: Initializing for INN $inn');
    }

    // Avval keshdan tekshirish
    final cachedBalance = _balanceService.getClientBalanceFromCache(inn);
    if (cachedBalance != null) {
      emit(state.toSuccess(cachedBalance));
      _startCountdown();
      return;
    }

    // Keyin DB dan tekshirish
    final dbBalance = await _balanceService.getClientBalanceFromDb(inn);
    if (dbBalance != null) {
      emit(state.toSuccess(dbBalance));
      _updateCountdownFromService();
      return;
    }

    // Ma'lumot yo'q - API'dan olish
    await fetchBalance();
  }

  /// ============================================================================
  /// Balansni API'dan olish
  /// ============================================================================
  /// [forceRefresh] - cooldown'ni e'tiborsiz qoldirish
  Future<void> fetchBalance({bool forceRefresh = false}) async {
    // INN tekshirish
    if (inn.isEmpty) {
      emit(state.toError(
        'Mijoz INN raqami mavjud emas',
        type: ClientBalanceErrorType.notFound,
      ));
      return;
    }

    // Cooldown tekshirish
    if (!forceRefresh && !_balanceService.canRefresh(inn)) {
      if (kDebugMode) {
        print('ClientBalanceCubit: Cooldown active, ${_balanceService.getSecondsUntilRefresh(inn)}s remaining');
      }
      _updateCountdownFromService();
      return;
    }

    // Loading yoki refreshing holatiga o'tish
    if (state.hasData) {
      emit(state.toRefreshing());
    } else {
      emit(state.toLoading());
    }

    try {
      final projectCode = _resolveProjectCode();
      if (projectCode == null) {
        emit(state.toError(
          'Faol loyiha tanlanmagan',
          type: ClientBalanceErrorType.notFound,
        ));
        return;
      }
      if (code1c.isEmpty) {
        emit(state.toError(
          'Mijoz 1C kodi mavjud emas',
          type: ClientBalanceErrorType.notFound,
        ));
        return;
      }

      if (kDebugMode) {
        print('ClientBalanceCubit: Fetching balance for code_1c=$code1c project_code=$projectCode');
      }

      final balance = await _balanceService.fetchClientBalance(
        code1c: code1c,
        projectCode: projectCode,
        inn: inn,
        forceRefresh: forceRefresh,
      );

      if (balance != null) {
        emit(state.toSuccess(balance));
        _startCountdown();
        
        if (kDebugMode) {
          print('ClientBalanceCubit: Successfully fetched balance: ${balance.balance}');
        }
      } else {
        // API javob bermadi - keshdan olishga urinish
        final cachedBalance = _balanceService.getClientBalanceFromCache(inn) ??
            await _balanceService.getClientBalanceFromDb(inn);
        
        if (cachedBalance != null) {
          emit(state.toSuccess(cachedBalance));
          _updateCountdownFromService();
        } else {
          emit(state.toError(
            'Balans ma\'lumotlari topilmadi',
            type: ClientBalanceErrorType.notFound,
          ));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ClientBalanceCubit: Error fetching balance: $e');
      }
      
      // Xatolik turini aniqlash
      final errorType = _classifyError(e);
      
      // Agar keshda ma'lumot bo'lsa, uni ko'rsatish
      if (state.hasData) {
        emit(state.copyWith(
          status: ClientBalanceStatus.success,
          errorMessage: errorType.userMessage,
          errorType: errorType,
        ));
      } else {
        emit(state.toError(errorType.userMessage, type: errorType));
      }
    }
  }

  /// ============================================================================
  /// Balansni yangilash (cooldown bilan)
  /// ============================================================================
  Future<void> refreshBalance() async {
    if (!state.canRefresh) {
      if (kDebugMode) {
        print('ClientBalanceCubit: Cannot refresh, ${state.remainingSeconds}s remaining');
      }
      return;
    }
    
    await fetchBalance();
  }

  /// ============================================================================
  /// Majburiy yangilash (cooldown'ni e'tiborsiz qoldirish)
  /// ============================================================================
  Future<void> forceRefreshBalance() async {
    await fetchBalance(forceRefresh: true);
  }

  /// ============================================================================
  /// Keshni tozalash
  /// ============================================================================
  Future<void> clearCache() async {
    if (kDebugMode) {
      print('ClientBalanceCubit: Clearing cache for INN $inn');
    }
    
    await _balanceService.deleteClientBalance(inn);
    emit(ClientBalanceState.initial());
  }

  /// Active project code from [ProjectContext]. The REST balance proxy
  /// (Passport §2) requires `project_code` = `UserProject.code` — without an
  /// active project we cannot fetch.
  String? _resolveProjectCode() {
    if (!sl.isRegistered<ProjectContext>()) return null;
    return sl<ProjectContext>().activeProject?.code;
  }

  /// ============================================================================
  /// Xatolik turini aniqlash
  /// ============================================================================
  ClientBalanceErrorType _classifyError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('socketexception') || 
        errorStr.contains('connection refused') ||
        errorStr.contains('network')) {
      return ClientBalanceErrorType.network;
    }
    
    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return ClientBalanceErrorType.timeout;
    }
    
    if (errorStr.contains('500') || 
        errorStr.contains('502') || 
        errorStr.contains('503')) {
      return ClientBalanceErrorType.server;
    }
    
    if (errorStr.contains('404') || errorStr.contains('not found')) {
      return ClientBalanceErrorType.notFound;
    }
    
    if (errorStr.contains('parse') || errorStr.contains('format')) {
      return ClientBalanceErrorType.invalidData;
    }
    
    return ClientBalanceErrorType.unknown;
  }

  /// ============================================================================
  /// Countdown timer boshlash
  /// ============================================================================
  void _startCountdown() {
    _countdownTimer?.cancel();
    
    int remaining = ClientBalanceService.refreshCooldownSeconds;
    emit(state.updateCountdown(remaining));

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      
      if (remaining <= 0) {
        timer.cancel();
        emit(state.updateCountdown(0));
      } else {
        emit(state.updateCountdown(remaining));
      }
    });
  }

  /// ============================================================================
  /// Service'dan countdown yangilash
  /// ============================================================================
  void _updateCountdownFromService() {
    final remaining = _balanceService.getSecondsUntilRefresh(inn);
    
    if (remaining > 0) {
      _countdownTimer?.cancel();
      
      emit(state.updateCountdown(remaining));

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final newRemaining = _balanceService.getSecondsUntilRefresh(inn);
        
        if (newRemaining <= 0) {
          timer.cancel();
          emit(state.updateCountdown(0));
        } else {
          emit(state.updateCountdown(newRemaining));
        }
      });
    } else {
      emit(state.updateCountdown(0));
    }
  }

  /// ============================================================================
  /// Auto-refresh boshlash (ixtiyoriy)
  /// ============================================================================
  void startAutoRefresh({Duration interval = const Duration(minutes: 5)}) {
    _autoRefreshTimer?.cancel();
    
    _autoRefreshTimer = Timer.periodic(interval, (_) {
      if (state.canRefresh) {
        fetchBalance();
      }
    });
    
    if (kDebugMode) {
      print('ClientBalanceCubit: Auto-refresh started with ${interval.inMinutes}min interval');
    }
  }

  /// ============================================================================
  /// Auto-refresh to'xtatish
  /// ============================================================================
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    
    if (kDebugMode) {
      print('ClientBalanceCubit: Auto-refresh stopped');
    }
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    _autoRefreshTimer?.cancel();
    
    if (kDebugMode) {
      print('ClientBalanceCubit: Closed for INN $inn');
    }
    
    return super.close();
  }
}
