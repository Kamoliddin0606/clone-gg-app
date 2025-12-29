/// ============================================================================
/// Client Balance State
/// ============================================================================
/// ClientBalanceCubit uchun state sinflari.
/// Equatable yordamida state o'zgarishlarini samarali kuzatadi.
/// ============================================================================

import 'package:equatable/equatable.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_balance.dart';

/// ============================================================================
/// ClientBalanceStatus - Balans holatining enumlari
/// ============================================================================
enum ClientBalanceStatus {
  /// Boshlang'ich holat - hech qanday amal bajarilmagan
  initial,
  
  /// Yuklanmoqda - API'dan ma'lumot olinmoqda
  loading,
  
  /// Muvaffaqiyatli - balans ma'lumotlari yuklandi
  success,
  
  /// Yangilanmoqda - mavjud ma'lumot bilan birga yangilanmoqda
  refreshing,
  
  /// Xatolik - API yoki boshqa xatolik yuz berdi
  error,
}

/// ============================================================================
/// ClientBalanceState - Asosiy state sinfi
/// ============================================================================
/// Barcha state xususiyatlarini o'z ichiga oladi.
class ClientBalanceState extends Equatable {
  /// Joriy holat statusi
  final ClientBalanceStatus status;
  
  /// Balans ma'lumotlari (null bo'lishi mumkin)
  final ClientBalance? balance;
  
  /// Xatolik xabari (agar mavjud bo'lsa)
  final String? errorMessage;
  
  /// Xatolik turi (retry logic uchun)
  final ClientBalanceErrorType? errorType;
  
  /// Yangilash mumkinmi (cooldown tugadimi)
  final bool canRefresh;
  
  /// Yangilashgacha qolgan soniyalar
  final int remainingSeconds;
  
  /// So'nggi yangilanish vaqti
  final DateTime? lastFetchTime;

  const ClientBalanceState({
    this.status = ClientBalanceStatus.initial,
    this.balance,
    this.errorMessage,
    this.errorType,
    this.canRefresh = true,
    this.remainingSeconds = 0,
    this.lastFetchTime,
  });

  /// Boshlang'ich state
  factory ClientBalanceState.initial() {
    return const ClientBalanceState();
  }

  /// Nusxa yaratish (immutability uchun)
  ClientBalanceState copyWith({
    ClientBalanceStatus? status,
    ClientBalance? balance,
    String? errorMessage,
    ClientBalanceErrorType? errorType,
    bool? canRefresh,
    int? remainingSeconds,
    DateTime? lastFetchTime,
    bool clearError = false,
    bool clearBalance = false,
  }) {
    return ClientBalanceState(
      status: status ?? this.status,
      balance: clearBalance ? null : (balance ?? this.balance),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorType: clearError ? null : (errorType ?? this.errorType),
      canRefresh: canRefresh ?? this.canRefresh,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
    );
  }

  /// Yuklanmoqda holatiga o'tish
  ClientBalanceState toLoading() {
    return copyWith(
      status: ClientBalanceStatus.loading,
      clearError: true,
    );
  }

  /// Yangilanmoqda holatiga o'tish (mavjud balans bilan)
  ClientBalanceState toRefreshing() {
    return copyWith(
      status: ClientBalanceStatus.refreshing,
      clearError: true,
    );
  }

  /// Muvaffaqiyatli holatga o'tish
  ClientBalanceState toSuccess(ClientBalance balance) {
    return copyWith(
      status: ClientBalanceStatus.success,
      balance: balance,
      canRefresh: false,
      lastFetchTime: DateTime.now(),
      clearError: true,
    );
  }

  /// Xatolik holatiga o'tish
  ClientBalanceState toError(String message, {ClientBalanceErrorType? type}) {
    return copyWith(
      status: ClientBalanceStatus.error,
      errorMessage: message,
      errorType: type ?? ClientBalanceErrorType.unknown,
    );
  }

  /// Countdown yangilash
  ClientBalanceState updateCountdown(int seconds) {
    return copyWith(
      remainingSeconds: seconds,
      canRefresh: seconds <= 0,
    );
  }

  /// Loading yoki refreshing holatidami
  bool get isLoading => 
      status == ClientBalanceStatus.loading || 
      status == ClientBalanceStatus.refreshing;

  /// Ma'lumot bormi
  bool get hasData => balance != null;

  /// Xatolik bormi
  bool get hasError => 
      status == ClientBalanceStatus.error && 
      errorMessage != null;

  @override
  List<Object?> get props => [
        status,
        balance,
        errorMessage,
        errorType,
        canRefresh,
        remainingSeconds,
        lastFetchTime,
      ];

  @override
  String toString() {
    return 'ClientBalanceState('
        'status: $status, '
        'hasBalance: ${balance != null}, '
        'error: $errorMessage, '
        'canRefresh: $canRefresh, '
        'remaining: ${remainingSeconds}s)';
  }
}

/// ============================================================================
/// ClientBalanceErrorType - Xatolik turlari
/// ============================================================================
/// Har xil xatolik turlari uchun turli xil UI va retry logic ishlatiladi.
enum ClientBalanceErrorType {
  /// Network xatoligi - internet yo'q
  network,
  
  /// Server xatoligi - 5xx
  server,
  
  /// Timeout - so'rov vaqti tugadi
  timeout,
  
  /// Ma'lumot topilmadi - INN noto'g'ri yoki balans yo'q
  notFound,
  
  /// Noto'g'ri ma'lumot - parse xatoligi
  invalidData,
  
  /// Noma'lum xatolik
  unknown,
}

/// ============================================================================
/// Extension: Xatolik turini inson o'qiy oladigan xabarga aylantirish
/// ============================================================================
extension ClientBalanceErrorTypeExtension on ClientBalanceErrorType {
  /// Foydalanuvchi uchun xabar
  String get userMessage {
    switch (this) {
      case ClientBalanceErrorType.network:
        return 'Internet aloqasi yo\'q. Iltimos, internetni tekshiring.';
      case ClientBalanceErrorType.server:
        return 'Server bilan bog\'lanishda xatolik. Keyinroq urinib ko\'ring.';
      case ClientBalanceErrorType.timeout:
        return 'So\'rov vaqti tugadi. Qayta urinib ko\'ring.';
      case ClientBalanceErrorType.notFound:
        return 'Balans ma\'lumotlari topilmadi.';
      case ClientBalanceErrorType.invalidData:
        return 'Ma\'lumotlarni o\'qishda xatolik.';
      case ClientBalanceErrorType.unknown:
        return 'Noma\'lum xatolik yuz berdi.';
    }
  }

  /// Retry mumkinmi
  bool get canRetry {
    switch (this) {
      case ClientBalanceErrorType.network:
      case ClientBalanceErrorType.server:
      case ClientBalanceErrorType.timeout:
        return true;
      case ClientBalanceErrorType.notFound:
      case ClientBalanceErrorType.invalidData:
      case ClientBalanceErrorType.unknown:
        return false;
    }
  }
}
