# Time Verification Resilience Implementation Prompt

## Muammo Tavsifi

Hozirgi `AppAccessControlService` vaqt tekshiruvida quyidagi muammolar mavjud:

1. **Internet bor, lekin AI javob bermasa** - ilova xato chiqaradi va foydalanuvchini bloklaydi
2. **AI servisi vaqtincha ishlamasa** - ilova to'liq ishlamay qoladi
3. **Gemini API limitlari yoki xatoliklari** - foydalanuvchi kirishdan mahrum bo'ladi

Bu holat **noto'g'ri** - AI servisining ishlamasligi foydalanuvchini to'smasligi kerak.

---

## Maqsad

`AppAccessControlService` ni shunday refaktor qilish kerakki:

1. **Internet aloqasi yo'q** → Oflayn rejimda ishlash (mavjud kesh/mahalliy tekshiruv)
2. **Internet bor, AI javob berdi** → Vaqtni tekshirish va saqlash
3. **Internet bor, AI javob bermadi** → **Graceful degradation** - xato chiqarmasdan davom etish

---

## Arxitektura Talablari

### 1. Graceful Degradation Pattern

```dart
/// Time verification with graceful degradation
/// 
/// Priority order:
/// 1. Try Gemini AI verification (most accurate)
/// 2. If AI fails - use device time with warning flag
/// 3. Never block user access due to AI service failure
```

### 2. Verification States

```dart
enum TimeVerificationStatus {
  /// AI verification successful - time is trusted
  verified,
  
  /// AI unavailable but internet exists - use device time with caution
  aiUnavailable,
  
  /// No internet - offline mode
  offline,
  
  /// AI returned suspicious time difference
  timeMismatch,
}
```

### 3. Verification Result Model

```dart
class TimeVerificationResult {
  final TimeVerificationStatus status;
  final DateTime verifiedTime;
  final DateTime deviceTime;
  final Duration? timeDifference;
  final String? warningMessage;
  final bool shouldAllowAccess;
}
```

---

## Implementatsiya Talablari

### AppAccessControlService O'zgarishlari

#### A. `_checkAccessWithInternet()` Metodini Yangilash

```dart
Future<AccessCheckResult> _checkAccessWithInternet() async {
  try {
    // 1. Try AI verification
    final timeResult = await _verifyTimeWithGracefulDegradation();
    
    // 2. Process result based on status
    switch (timeResult.status) {
      case TimeVerificationStatus.verified:
        // AI confirmed time - full trust
        return AccessCheckResult.granted(
          expiryDate: _validityService.getExpiryDate(),
          verifiedTime: timeResult.verifiedTime,
        );
        
      case TimeVerificationStatus.aiUnavailable:
        // AI failed but internet exists - allow with warning
        if (kDebugMode) {
          debugPrint('[AccessControl] AI unavailable, using device time');
        }
        return AccessCheckResult.grantedWithWarning(
          expiryDate: _validityService.getExpiryDate(),
          warningMessage: 'Time verification service temporarily unavailable',
          deviceTime: timeResult.deviceTime,
        );
        
      case TimeVerificationStatus.timeMismatch:
        // Suspicious time difference detected
        return AccessCheckResult.denied(
          reason: AccessDeniedReason.timeManipulation,
          message: 'Device time appears to be manipulated',
        );
        
      case TimeVerificationStatus.offline:
        // Shouldn't reach here if we have internet
        return _checkAccessWithoutInternet();
    }
  } catch (e) {
    // Any unexpected error - don't block user
    if (kDebugMode) {
      debugPrint('[AccessControl] Unexpected error, allowing access: $e');
    }
    return AccessCheckResult.grantedWithWarning(
      expiryDate: _validityService.getExpiryDate(),
      warningMessage: 'Access verification partially completed',
    );
  }
}
```

#### B. Yangi Graceful Degradation Metodi

```dart
/// Verify time with graceful degradation
/// 
/// Never throws - always returns a result
Future<TimeVerificationResult> _verifyTimeWithGracefulDegradation() async {
  final deviceTime = DateTime.now();
  
  try {
    // Try AI verification with short timeout
    final verifiedTime = await _geminiService
        .verifyRealTimeWithRetry(
          maxRetries: 2, // Reduced retries for faster fallback
          retryDelay: const Duration(seconds: 1),
        )
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('AI verification timeout'),
        );
    
    // Check time difference
    final difference = verifiedTime.difference(deviceTime).abs();
    
    if (difference > const Duration(minutes: 5)) {
      // Suspicious time difference
      return TimeVerificationResult(
        status: TimeVerificationStatus.timeMismatch,
        verifiedTime: verifiedTime,
        deviceTime: deviceTime,
        timeDifference: difference,
        shouldAllowAccess: false,
      );
    }
    
    // Time verified successfully
    return TimeVerificationResult(
      status: TimeVerificationStatus.verified,
      verifiedTime: verifiedTime,
      deviceTime: deviceTime,
      timeDifference: difference,
      shouldAllowAccess: true,
    );
    
  } on GeminiException catch (e) {
    // AI service error - graceful degradation
    if (kDebugMode) {
      debugPrint('[TimeVerification] AI error: ${e.message}');
    }
    
    return TimeVerificationResult(
      status: TimeVerificationStatus.aiUnavailable,
      verifiedTime: deviceTime, // Use device time as fallback
      deviceTime: deviceTime,
      warningMessage: 'AI verification unavailable: ${e.code}',
      shouldAllowAccess: true, // Allow access despite AI failure
    );
    
  } on TimeoutException {
    // Timeout - AI too slow
    if (kDebugMode) {
      debugPrint('[TimeVerification] AI timeout - using device time');
    }
    
    return TimeVerificationResult(
      status: TimeVerificationStatus.aiUnavailable,
      verifiedTime: deviceTime,
      deviceTime: deviceTime,
      warningMessage: 'Time verification timed out',
      shouldAllowAccess: true,
    );
    
  } catch (e) {
    // Any other error - graceful degradation
    if (kDebugMode) {
      debugPrint('[TimeVerification] Unexpected error: $e');
    }
    
    return TimeVerificationResult(
      status: TimeVerificationStatus.aiUnavailable,
      verifiedTime: deviceTime,
      deviceTime: deviceTime,
      warningMessage: 'Time verification error',
      shouldAllowAccess: true,
    );
  }
}
```

---

## Holat Diagrammasi

```
┌─────────────────────────────────────────────────────────────────┐
│                    ACCESS CHECK START                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ Internet bormi? │
                    └─────────────────┘
                     │              │
                    YES            NO
                     │              │
                     ▼              ▼
            ┌────────────────┐   ┌──────────────────┐
            │ AI tekshiruv   │   │ Oflayn tekshiruv │
            └────────────────┘   └──────────────────┘
                     │                    │
        ┌────────────┼────────────┐       │
        │            │            │       │
     SUCCESS      TIMEOUT      ERROR      │
        │            │            │       │
        ▼            ▼            ▼       ▼
   ┌─────────┐  ┌─────────┐  ┌─────────┐ ┌─────────┐
   │ VERIFIED │  │ WARNING │  │ WARNING │ │ OFFLINE │
   │ (trust)  │  │ (allow) │  │ (allow) │ │ MODE    │
   └─────────┘  └─────────┘  └─────────┘ └─────────┘
        │            │            │            │
        └────────────┴────────────┴────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  ACCESS GRANTED │
                    │  (with status)  │
                    └─────────────────┘
```

---

## Muhim Qoidalar

### 1. Hech qachon AI xatosi tufayli foydalanuvchini bloklama

```dart
// ❌ NOTO'G'RI
try {
  await geminiService.verifyTime();
} catch (e) {
  throw AccessDeniedException('Time verification failed'); // XATO!
}

// ✅ TO'G'RI
try {
  await geminiService.verifyTime();
} catch (e) {
  // Graceful degradation - allow with warning
  return AccessResult.grantedWithWarning();
}
```

### 2. Timeout ishlatish

```dart
// AI so'rovi 10 sekunddan oshmasin
final result = await geminiService
    .verifyTime()
    .timeout(Duration(seconds: 10));
```

### 3. Retry sonini kamaytirish

```dart
// Tez fallback uchun 2 retry yetarli
maxRetries: 2,
retryDelay: Duration(seconds: 1),
```

### 4. Logging va Monitoring

```dart
// Barcha holatlarni log qilish
if (kDebugMode) {
  debugPrint('[TimeVerification] Status: $status');
  debugPrint('[TimeVerification] Device time: $deviceTime');
  debugPrint('[TimeVerification] Verified time: $verifiedTime');
  debugPrint('[TimeVerification] Difference: $difference');
}
```

---

## Localization Strings (app_*.arb)

```json
{
  "accessTimeVerificationUnavailable": "Time verification service temporarily unavailable",
  "accessUsingDeviceTime": "Using device time for verification",
  "accessVerificationPartial": "Access verification partially completed",
  "accessTimeVerificationTimeout": "Time verification timed out",
  "accessGrantedWithWarning": "Access granted with limited verification"
}
```

---

## Test Scenarios

| # | Scenario | Expected Result |
|---|----------|-----------------|
| 1 | Internet ✅, AI ✅ | `verified` - full trust |
| 2 | Internet ✅, AI ❌ (error) | `aiUnavailable` - allow with warning |
| 3 | Internet ✅, AI ⏱️ (timeout) | `aiUnavailable` - allow with warning |
| 4 | Internet ❌ | `offline` - use cached/local check |
| 5 | Internet ✅, AI ✅, time diff > 5 min | `timeMismatch` - deny access |

---

## Xulosa

**Asosiy printsip:** AI servisi - bu **qo'shimcha xavfsizlik qatlami**, lekin u **majburiy bloklash mexanizmi emas**. Agar AI ishlamasa, ilova ishlashni davom ettirishi kerak.

---

## Implementatsiya Tartibi

1. [ ] `TimeVerificationStatus` enum yaratish
2. [ ] `TimeVerificationResult` model yaratish
3. [ ] `_verifyTimeWithGracefulDegradation()` metodini qo'shish
4. [ ] `_checkAccessWithInternet()` ni yangilash
5. [ ] `AccessCheckResult` ga `grantedWithWarning` variant qo'shish
6. [ ] Localization strings qo'shish (EN, RU, UZ)
7. [ ] Unit testlar yozish
8. [ ] Integration test
