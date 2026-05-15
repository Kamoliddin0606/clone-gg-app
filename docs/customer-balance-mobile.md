# Mobile (Flutter) — Customer Balance Proxy + Debt-Limit Gate (implementation prompt)

> Bu hujjatni butunligicha yangi sessiyaga task brief sifatida nusxalang.
> Self-contained — oldindan kontekst kerak emas.
> **Avval [customer-balance-passport.md](./customer-balance-passport.md)'ni o'qing** — bu yagona shartnoma manbai. Hujjat va prompt orasida ziddiyat bo'lsa — passport ustun.

## Maqsad

Mijoz balansini olishni to'g'ridan-to'g'ri 1C SOAP serveridan **bizning backendga** ko'chirish (REST orqali). Visit ichida "Buyurtma yaratish" stepida balans va loyiha `debt_limit`'iga binoan stepni bloklash. Offline yig'ilgan buyurtmalarni serverga yuborishdan oldin qayta tekshirish.

**MUHIM minimal-o'zgarish printsipi:** mavjud `ClientBalance`, `ClientBalanceByContract`, `ClientBalanceByOrder` modellari, `ClientBalanceWidgetV2`, `ClientBalanceDetailsPage`, `ClientBalanceCubit` va uchchala SQLite jadval **o'zgartirilmaydi**. Faqat transport qatlami (XML SOAP → JSON REST) almashtiriladi va ba'zi ixtiyoriy yangi maydonlar qo'shiladi.

## Repository

- Yo'l: `/Users/kamoliddin/Documents/GitHub/clone-gg-app`
- Framework: Flutter (Dart).
- DI: GetIt (`sl<...>()`).
- Tests: `flutter test`.

## Asosiy bosqichlar

### M1 — `ClientBalanceService` ni backend REST'ga ko'chirish (transport-only o'zgarish)

File: `lib/src/core/services/client_balance_service.dart`.

Olib tashlanadi:
- `_buildSoapRequest`, `_parseSoapResponse`, `_parseContractBalance`, `_parseOrderBalance` — SOAP-specific funksiyalar.
- `_failoverService` bog'liqlik (yagona ishlatuvchi shu service edi — auditga muhtoj).
- `_serverService.accountingApiConfig` chaqiruvlari.

Yangi imzo:

```dart
Future<ClientBalance?> fetchClientBalance({
  required String code1c,
  required String projectCode,
  String? inn,                  // optional — eski caller'lar uchun
  bool forceRefresh = false,
});
```

Implementation:

```dart
final response = await _apiService.post(
  '/api/mobile/v2/customers/balance/',
  body: {
    'code_1c': code1c,
    'project_code': projectCode,
    'force_refresh': forceRefresh,
  },
);
final balance = ClientBalance.fromJson(response.data as Map<String, dynamic>);
_cache[balance.inn] = balance;
_lastRefreshTimes[balance.inn] = DateTime.now();
await saveClientBalance(balance);
return balance;
```

`ClientBalance.fromJson()` o'zgarmaydi — Passport §2.1 JSON kalitlari mavjud `toJson()` chiqarayotgan kalitlarga aynan mos.

### M2 — Direct SOAP yo'lini o'chirish (rollout oxirida)

File: `lib/src/core/network/server_service.dart` (lines ~45-61).

`accountingApiConfig` va undagi host'lar (`kit.gloriya.uz:5443/gloriya_buh2`, `178.218.200.120`, `109.94.175.104`) **butunlay o'chiriladi**. `UrlFailoverService`'ning `customUrlConfig` parametrini ishlatuvchi boshqa joylar bo'lsa, audit qiling.

**MUHIM:** bu bosqich M1 mustahkam ishlagani aniq bo'lganidan keyin bajariladi (log monitoring orqali).

### M3 — `ClientBalance` modeliga yangi optional maydonlar

File: `lib/src/features/agent/data/models/client_balance.dart`.

Mavjud konstruktor parametrlari saqlanadi. Quyidagi optional maydonlar qo'shiladi:

```dart
final double? debtLimit;
final String? debtLimitCurrency;
final String? currency;
final bool? blocked;
final String? blockReason;
final String? source;          // "fresh" | "cache" | "stale"
final String? lastError;
```

`fromJson` ga yangi qatorlar qo'shiladi (mavjud parsing o'zgartirilmaydi):

```dart
debtLimit: (json['debt_limit'] as num?)?.toDouble(),
debtLimitCurrency: json['debt_limit_currency']?.toString(),
currency: json['currency']?.toString(),
blocked: json['blocked'] as bool?,
blockReason: json['block_reason']?.toString(),
source: json['source']?.toString(),
lastError: json['last_error']?.toString(),
```

`toJson` va `copyWith` shu maydonlarni qo'shadi.

### M4 — SQLite schema migration

File: `lib/src/core/services/api_database_service.dart` (mavjud migration mexanizmida).

`client_balances` jadvaliga yangi ustunlar:

```sql
ALTER TABLE client_balances ADD COLUMN debt_limit REAL NULL;
ALTER TABLE client_balances ADD COLUMN debt_limit_currency TEXT NULL;
ALTER TABLE client_balances ADD COLUMN currency TEXT NULL;
ALTER TABLE client_balances ADD COLUMN blocked INTEGER NULL;
ALTER TABLE client_balances ADD COLUMN block_reason TEXT NULL;
ALTER TABLE client_balances ADD COLUMN source TEXT NULL;
ALTER TABLE client_balances ADD COLUMN last_error TEXT NULL;
```

`saveClientBalance(...)` va `getClientBalanceFromDb(...)` shu ustunlarni o'qiydi/yozadi. `client_balance_contracts` va `client_balance_orders` jadvallari **o'zgarmaydi**.

### M5 — `UserProject.debtLimit` qo'shish

File: `lib/src/features/agent/data/models/user_project.dart`.

```dart
final double? debtLimit;
final String? debtLimitCurrency;
```

`fromMap/toMap/copyWith` ni yangilang.

Schema migration: `user_projects` jadvaliga `debt_limit REAL NULL`, `debt_limit_currency TEXT NULL`.

### M6 — Project config'ni sync engine'ga ulash

File: `lib/src/core/services/data_sync_service.dart`. `_syncUserProjects` ichida (yoki uning oxirida) yangi chaqiruv:

```dart
final config = await _apiService.get('/api/mobile/v2/projects/config/');
for (final entry in (config.data as List)) {
  await _db.updateUserProjectDebtLimit(
    code: entry['code'],
    debtLimit: (entry['debt_limit'] as num?)?.toDouble(),
    debtLimitCurrency: entry['debt_limit_currency']?.toString(),
  );
}
```

`data_sync_config.dart`'da `user_projects` jadvalining sync funktsiyasi shu ikki bosqichni o'rashi mumkin.

### M7 — `ConnectivityService` (yangi)

File: `lib/src/core/services/connectivity_service.dart` (yangi, agar mavjud bo'lmasa).

```dart
class ConnectivityService {
  final ValueNotifier<bool> isOnline = ValueNotifier(true);
  Stream<bool> get stream => /* ... */;
}
```

Implementation: `package:connectivity_plus` (yoki mavjud bo'lsa) subscription. GetIt'ga ro'yxat.

### M8 — `OrderBalanceGate` (yangi)

File: `lib/src/features/agent/services/order_balance_gate.dart` (yangi).

```dart
class BalanceGateResult {
  final bool blocked;
  final double balance;
  final double? limit;
  final String currency;
  final DateTime? fetchedAt;
  final DateTime? externalUpdatedAt;
  final bool isStale;
  final bool isOffline;
  final String source;            // "fresh" | "cache" | "stale" | "local"
  final String? reason;            // "debt_limit_exceeded" | "no_cached_balance" | null
}

class OrderBalanceGate {
  Future<BalanceGateResult> check(TradingPoint tp, {bool forceFresh = false}) async {
    if (_connectivity.isOnline.value) {
      // Backend qarorga ergashadi.
      final cb = await _balanceService.fetchClientBalance(
        code1c: tp.code1c,
        projectCode: _projectContext.activeProject!.code,
        inn: tp.inn,
        forceRefresh: forceFresh,
      );
      if (cb == null) {
        return _fallbackToOffline(tp, reason: 'fetch_failed');
      }
      return BalanceGateResult(
        blocked: cb.blocked ?? false,
        balance: cb.balance,
        limit: cb.debtLimit,
        currency: cb.currency ?? 'UZS',
        fetchedAt: cb.lastUpdated,
        externalUpdatedAt: cb.serverDataUpdatedAt,
        isStale: cb.source == 'stale',
        isOffline: false,
        source: cb.source ?? 'fresh',
        reason: cb.blockReason,
      );
    }
    return _checkOffline(tp);
  }

  Future<BalanceGateResult> _checkOffline(TradingPoint tp) async {
    final cached = await _balanceService.getCachedClientBalance(
      code1c: tp.code1c, projectCode: _projectContext.activeProject!.code,
    );
    final limit = _projectContext.activeProject!.debtLimit;
    if (cached == null) {
      return BalanceGateResult(blocked: true, /* ... */, reason: 'no_cached_balance');
    }
    final isStale = DateTime.now().difference(cached.lastUpdated).inHours > 24;
    final blocked = limit != null && cached.balance > limit;
    return BalanceGateResult(
      blocked: blocked,
      balance: cached.balance,
      limit: limit,
      currency: cached.currency ?? 'UZS',
      fetchedAt: cached.lastUpdated,
      externalUpdatedAt: cached.serverDataUpdatedAt,
      isStale: isStale,
      isOffline: true,
      source: 'local',
      reason: blocked ? 'debt_limit_exceeded' : null,
    );
  }
}
```

**Block decision formula** (online va offline'da bir xil): `blocked = (limit != null) AND (balance > limit)`.

### M9 — Visit step entry gate

File: `lib/src/features/agent/presentation/pages/visit_steps_page.dart` line ~3643 (`case 'создать заказ':`).

`page = CreateOrderPage(...)` belgilashidan **oldin** gate'ni chaqirish:

```dart
case 'создать заказ':
  final gate = await sl<OrderBalanceGate>().check(widget.tradingPoint);
  if (gate.blocked) {
    await showDialog(
      context: context,
      builder: (_) => DebtBlockedDialog(
        gateResult: gate,
        customerName: widget.tradingPoint.name,
      ),
    );
    return;     // CreateOrderPage'ga push qilinmaydi
  }
  page = CreateOrderPage(
    tradingPoint: widget.tradingPoint,
    visitId: widget.visitId,
    stepCode: step.stepCode,
    stepName: step.stepName,
    readOnly: readOnly,
  );
  break;
```

### M10 — `DebtBlockedDialog` widget (yangi)

File: `lib/src/features/agent/presentation/widgets/debt_blocked_dialog.dart` (yangi).

Argumentlar: `BalanceGateResult gateResult`, `String customerName`.

Ko'rsatilishi:
- Sarlavha: "Buyurtma berib bo'lmaydi" (l10n).
- Tana: mijoz nomi, joriy balans (`gate.balance`), limit (`gate.limit`), oxirgi yangilanish vaqti (`gate.fetchedAt`).
- Offline holatda qo'shimcha ogohlantirish: "Internetsiz tekshirildi (oxirgi balans X soat oldin)".
- Stale (24+ soat) holatda yana qo'shimcha ogohlantirish.
- `gate.reason == 'no_cached_balance'` holatida: "Balans hech qachon yuklanmagan, internetga ulanib qayta urinib ko'ring".
- "Orqaga" tugmasi.

Lokalizatsiya kalitlari M13'da.

### M11 — Pre-submit qayta tekshiruv (offline → online flush)

File: `lib/src/core/services/data_sync_service.dart` line ~2447 (`// This method sends unsynced create orders to the server via SetOrder API`).

`_apiService.setOrder(order: order)`'dan **oldin**:

```dart
final gate = await sl<OrderBalanceGate>().check(
  _tradingPointForOrder(order),
  forceFresh: true,    // serverdan yangi qiymat majburiy
);
if (gate.blocked) {
  await _db.updateCreateOrderSyncError(
    order.id,
    reason: 'debt_limit_exceeded',
    blockedBalance: gate.balance,
    blockedLimit: gate.limit,
  );
  continue;  // bu buyurtmani o'tkazib yuborish
}
// proceed with _apiService.setOrder(order: order)
```

`create_order` jadvaliga `sync_error` ustuni allaqachon mavjud — shu maqsadda foydalanamiz.

### M12 — Bloklangan buyurtmalar UI

File: `lib/src/features/agent/presentation/pages/orders_page.dart`.

`sync_error == "debt_limit_exceeded"` qatorlar uchun:
- Qizil badge — "Qarz limiti oshib ketgan" (l10n).
- "Qayta yuborish" tugmasi — `OrderBalanceGate.check(..., forceFresh: true)` yana ishga tushiradi va `gate.blocked == false` bo'lsa `_apiService.setOrder(...)` chaqiriladi.

### M13 — Lokalizatsiya

Fayllar: `lib/l10n/app_localizations_{en,ru,uz}.dart`.

Yangi kalitlar:
- `debtBlockedTitle`
- `debtBlockedBodyOnline` (placeholder'lar: balance, limit, currency)
- `debtBlockedBodyOffline` (placeholder'lar: balance, limit, age)
- `debtBlockedNoCachedBalance`
- `debtBlockedStaleWarning`
- `orderBlockedByDebtBadge`
- `retrySyncButton`

### M14 — Tests

- `test/services/order_balance_gate_test.dart` — online/offline × cache yes/no × over/under limit kombinatsiyalari.
- `test/services/client_balance_service_test.dart` — REST chaqiruv va response → `ClientBalance.fromJson` parsing. Real Passport §2.1 JSON namunasini fixture sifatida ishlating.

Mock: `ApiService`'ni mock qilish (Dio'ni emas).

## Bog'liqliklar va asoslar

- **Passport** ([customer-balance-passport.md](./customer-balance-passport.md)) — har qanday ziddiyatda ustun.
- Mavjud `ApiService` (`lib/src/core/network/api_service.dart`) — POST/GET interfeysi.
- `ProjectContext.activeProject` (`lib/src/core/services/project_context.dart`) — joriy loyiha.
- `TradingPoint.code1c` va `TradingPoint.inn` (`lib/src/features/agent/data/models/trading_point.dart`).
- `ClientBalance` model va parsing — `lib/src/features/agent/data/models/client_balance.dart`.

## Done definition

- [ ] `flutter test` yashil.
- [ ] Manual online:
  - Customer detail oynasi balansni backenddan ko'rsatadi (`ClientBalanceWidgetV2` va `ClientBalanceDetailsPage` o'zgarishsiz ishlaydi).
  - Limit ostidagi mijoz: "Buyurtma yaratish" → CreateOrderPage ochiladi.
  - Limit ustidagi mijoz: `DebtBlockedDialog` ko'rsatiladi, CreateOrderPage ochilmaydi.
- [ ] Manual offline:
  - Cache mavjud mijozda gate ishlashi (limit bo'yicha).
  - Cache yo'q mijozda → "Balans yuklanmagan" dialogi.
  - Offline buyurtma yaratish → internetni yoqish → `data_sync_service` `force_refresh=true` bilan gate'ni chaqiradi → blokda buyurtma `sync_error="debt_limit_exceeded"`, orders_page'da qizil badge.
- [ ] Charles Proxy bilan auditda: `kit.gloriya.uz:5443`, `178.218.200.120`, `109.94.175.104` hostlariga **hech qanday so'rov bormaydi** (M2 bajarilgandan keyin).

## Rollout order

1. **M3 + M4 + M5** — modellar va schema migration (UI hali ishlatmaydi).
2. **M6** — backend `/projects/config/` chaqiriladi, lokal `debt_limit` to'ladi.
3. **M1** — `ClientBalanceService` REST'ga ko'chiriladi. Customer detail backenddan o'qiy boshlaydi.
4. **M7 + M8 + M9 + M10 + M11 + M12 + M13** — gate, UX, lokalizatsiya.
5. **M14** — testlar.
6. **M2** — eski SOAP yo'li o'chiriladi (faqat 1–4 mustahkam ishlagani aniq bo'lganidan keyin).

## Backend bog'liqligi

Bu prompt backend tomonda quyidagi endpointlar **deploy bo'lgan**ligini taxmin qiladi:

- `POST /api/mobile/v2/customers/balance/` (Passport §2)
- `GET /api/mobile/v2/projects/config/` (Passport §3)

Backend tayyor bo'lmaguncha mobile M1/M6'ni production'ga chiqarmang.

## Ko'rib chiqish savollari

1. **`ConnectivityService` mavjudmi?** — `package:connectivity_plus` ishlatilyaptimi? Aks holda backend `/healthz`'ga davriy ping.
2. **`_tradingPointForOrder(order)`** — `CreateOrder` modelidan `TradingPoint`'ni qanday olamiz? Mavjud lookup metodlari bormi?
3. **Lokalizatsiya stringlari** — translation team bilan tasdiqlash kerakmi?
