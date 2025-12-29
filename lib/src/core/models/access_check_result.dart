import 'package:xml/xml.dart';

/// =============================================================================
/// Access Check Result Model
/// =============================================================================
/// 
/// Bu model SOAP CheckAccessOnStartup javobini qayta ishlash uchun ishlatiladi.
/// Server ALLOW yoki BLOCK qaytaradi.
/// =============================================================================

/// Access status enumlari
enum AccessStatus {
  /// Ruxsat berildi - ilova ishlashda davom etadi
  allow,
  
  /// Bloklangan - ilova ishga tushmaydi
  block,
}

/// Access tekshiruvi sabablari (BLOCK holati uchun)
enum AccessBlockReason {
  /// Account boshqa qurilmaga bog'langan
  accountAlreadyBoundToAnotherDevice,
  
  /// Qurilmada boshqa account mavjud
  deviceAlreadyHasAnotherAccount,
  
  /// Yuqori xavfli qurilma
  highRiskDevice,
  
  /// Xavfsizlik siyosati buzilgan
  securityPolicyViolation,
  
  /// Noma'lum sabab
  unknown,
}

/// Access tekshiruvi natijasi modeli
class AccessCheckResult {
  /// Tekshiruv statusi (ALLOW/BLOCK)
  final AccessStatus status;
  
  /// Risk ball (0-100)
  final int? riskScore;
  
  /// Bloklash sababi (faqat BLOCK holatida)
  final AccessBlockReason? reason;
  
  /// Server xabari (foydalanuvchiga ko'rsatish uchun)
  final String? message;
  
  /// Raw server javobi (debug uchun)
  final String? rawReason;

  const AccessCheckResult({
    required this.status,
    this.riskScore,
    this.reason,
    this.message,
    this.rawReason,
  });

  /// SOAP javobidan AccessCheckResult yaratish
  /// 
  /// Kutilgan XML struktura:
  /// ```xml
  /// <m:return>
  ///   <m:Status>ALLOW</m:Status>
  ///   <m:RiskScore>25</m:RiskScore>
  ///   <m:Reason>NONE</m:Reason>
  ///   <m:Message>Access granted</m:Message>
  /// </m:return>
  /// ```
  factory AccessCheckResult.fromSoapResponse(XmlElement element) {
    // Status ni olish
    final statusText = element.findElements('m:Status').firstOrNull?.innerText 
        ?? element.findElements('Status').firstOrNull?.innerText
        ?? 'BLOCK';
    
    // Risk score ni olish
    final riskScoreText = element.findElements('m:RiskScore').firstOrNull?.innerText
        ?? element.findElements('RiskScore').firstOrNull?.innerText;
    
    // Reason ni olish
    final reasonText = element.findElements('m:Reason').firstOrNull?.innerText
        ?? element.findElements('Reason').firstOrNull?.innerText;
    
    // Message ni olish
    final messageText = element.findElements('m:Message').firstOrNull?.innerText
        ?? element.findElements('Message').firstOrNull?.innerText;

    return AccessCheckResult(
      status: _parseStatus(statusText),
      riskScore: riskScoreText != null ? int.tryParse(riskScoreText) : null,
      reason: _parseReason(reasonText),
      message: messageText,
      rawReason: reasonText,
    );
  }

  /// Default ALLOW natija (server javob bermagan holatda)
  factory AccessCheckResult.allowed() {
    return const AccessCheckResult(
      status: AccessStatus.allow,
      riskScore: 0,
    );
  }

  /// Default BLOCK natija (xatolik holatida)
  factory AccessCheckResult.blocked({
    AccessBlockReason reason = AccessBlockReason.unknown,
    String? message,
  }) {
    return AccessCheckResult(
      status: AccessStatus.block,
      reason: reason,
      message: message,
    );
  }

  /// Error holatida natija
  factory AccessCheckResult.error(String errorMessage) {
    return AccessCheckResult(
      status: AccessStatus.block,
      reason: AccessBlockReason.unknown,
      message: errorMessage,
    );
  }

  /// Status textdan enum ga o'girish
  static AccessStatus _parseStatus(String text) {
    switch (text.toUpperCase().trim()) {
      case 'ALLOW':
      case 'ALLOWED':
      case 'OK':
      case '1':
        return AccessStatus.allow;
      case 'BLOCK':
      case 'BLOCKED':
      case 'DENY':
      case 'DENIED':
      case '0':
      default:
        return AccessStatus.block;
    }
  }

  /// Reason textdan enum ga o'girish
  static AccessBlockReason? _parseReason(String? text) {
    if (text == null || text.isEmpty) return null;
    
    switch (text.toUpperCase().trim()) {
      case 'ACCOUNT_ALREADY_BOUND_TO_ANOTHER_DEVICE':
      case 'ACCOUNT_BOUND':
        return AccessBlockReason.accountAlreadyBoundToAnotherDevice;
      case 'DEVICE_ALREADY_HAS_ANOTHER_ACCOUNT':
      case 'DEVICE_BOUND':
        return AccessBlockReason.deviceAlreadyHasAnotherAccount;
      case 'HIGH_RISK_DEVICE':
      case 'HIGH_RISK':
        return AccessBlockReason.highRiskDevice;
      case 'SECURITY_POLICY_VIOLATION':
      case 'POLICY_VIOLATION':
        return AccessBlockReason.securityPolicyViolation;
      case 'NONE':
      case '':
        return null;
      default:
        return AccessBlockReason.unknown;
    }
  }

  /// Ruxsat berilganmi
  bool get isAllowed => status == AccessStatus.allow;
  
  /// Bloklanganmi
  bool get isBlocked => status == AccessStatus.block;

  /// Foydalanuvchiga ko'rsatiladigan xabar
  String get displayMessage {
    if (message != null && message!.isNotEmpty) {
      return message!;
    }
    
    switch (reason) {
      case AccessBlockReason.accountAlreadyBoundToAnotherDevice:
        return 'Bu hisob boshqa qurilmaga bog\'langan. Iltimos, administrator bilan bog\'laning.';
      case AccessBlockReason.deviceAlreadyHasAnotherAccount:
        return 'Bu qurilmada boshqa hisob mavjud. Iltimos, administrator bilan bog\'laning.';
      case AccessBlockReason.highRiskDevice:
        return 'Qurilma xavfsizlik tekshiruvidan o\'tmadi.';
      case AccessBlockReason.securityPolicyViolation:
        return 'Xavfsizlik siyosati buzilgan.';
      case AccessBlockReason.unknown:
      case null:
        return 'Noma\'lum xatolik yuz berdi. Iltimos, administrator bilan bog\'laning.';
    }
  }

  @override
  String toString() {
    return 'AccessCheckResult(status: $status, riskScore: $riskScore, reason: $reason, message: $message)';
  }
}
