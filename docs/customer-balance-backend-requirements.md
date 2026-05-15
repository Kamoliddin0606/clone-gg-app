# Customer Balance — backend tomonidagi talab va audit

> Bu hujjat mobile (clone-gg-app) tomondan backend'dan talab qilinadigan
> aniq belgilangan endpoint shartnomalarini va deploy holatini tekshirish
> ro'yxatini sanab beradi. Mobile P0/P1 ishlari ([texnik-kamchilik plan](.claude/plans/texnik-kamchilik-muammo-test-hazy-chipmunk.md))
> shu hujjatdagi shartlar bajarilishini taxmin qiladi.
>
> **Source of truth:** [customer-balance-passport.md](customer-balance-passport.md)

## 1. Audit chek-listi

### 1.1 Endpoint mavjudligi

```bash
# Backend repo'da run qiling:
grep -rn "/api/mobile/v2/customers/balance/" backend/  # POST endpoint
grep -rn "/api/mobile/v2/projects/config/" backend/    # GET endpoint
```

Agar topilmasa — endpoint **deploy bo'lmagan**. Mobile P0 ishlarining hech biri test qilolmaydi.

### 1.2 Auth + headerlar

Har ikkala endpoint quyidagilarni qabul qilishi kerak:

| Header | Talab | Sabab |
|---|---|---|
| `Authorization: Bearer <token>` | Majburiy | Mobile auth interceptor avtomatik attach qiladi |
| `X-Project-Id: <uuid|1c-ref|code>` | Project-scope tenant'larda majburiy | Mobile [`CustomerEndpointHeaders`](../lib/src/core/network/customer_endpoint_headers.dart) attach qiladi |
| `Content-Type: application/json` | POST uchun | Standard |
| `Accept: application/json` | Standard | — |

Backend tomonida tekshirilishi:

- [ ] `X-Project-Id` o'qish va `Project.objects.get(id=...)` orqali resolve.
  - UUID, 1C ref (`00-XXXXX`), va SOAP-style `code` — uchchalasini ham qabul qilish.
- [ ] Project-scope tenant + header etishmasa: HTTP 400 + `{"error":{"code":"customer_project_required",...}}` (Passport §2.5).
- [ ] Org-scope tenant + header bor: e'tiborsiz qoldirish.

### 1.3 POST `/api/mobile/v2/customers/balance/`

#### Request shape (mobile yuboradi)

```json
{
  "code_1c": "00-00053242",
  "project_code": "EVYAP",
  "force_refresh": false
}
```

| Field | Type | Required | Validation |
|---|---|---|---|
| `code_1c` | string | yes | non-empty; mavjud `Customer`'ga match |
| `project_code` | string | yes | mavjud `Project.code`'ga match (project-scope'da `X-Project-Id`'ga ham mos bo'lishi kerak) |
| `force_refresh` | bool | no | `true` → backend cache TTL chetlab o'tadi (Passport §4) |

#### Response 200 (Passport §2.1 to'liq shape)

Mobile [`ClientBalance.fromJson`](../lib/src/features/agent/data/models/client_balance.dart) defensive parser ishlatadi (num + string ikkalasini ham qabul qiladi), lekin **spec-compliant** versiyasi:

```json
{
  "inn": "308976156",
  "client_code": "C-00012345",
  "project_name": "EVYAP",
  "balance": "-2250",
  "currency": "UZS",
  "debt_limit": "5000000.00",
  "debt_limit_currency": "UZS",
  "server_data_updated_at": "2026-05-14T00:00:00",
  "last_updated": "2026-05-14T07:12:31+05:00",
  "blocked": false,
  "block_reason": null,
  "source": "fresh",
  "last_error": null,
  "contract_balances": [...],
  "order_balances": [...]
}
```

**Critical**:
- `balance`, `debt_limit` — **string Decimal** (Passport §2.2). `123.45` emas, `"123.45"`.
- `blocked` — bool (mobile har doim ishonadi).
- `source` — `"fresh" | "cache" | "stale"` faqat.
- `block_reason` — hozircha `"debt_limit_exceeded" | null`.
- `last_error` — `source="stale"` bo'lganda SOAP xatosi qisqacha.

#### Error responses (Passport §2.5)

| Status | Body | Sabab | Mobile reaktsiyasi |
|---|---|---|---|
| 400 | `{"error":{"code":"validation",...}}` | Body invalid | `ClientBalanceErrorType.invalidData` |
| 400 | `{"error":{"code":"customer_project_required",...}}` | Project-scope + header yo'q | `notFound` (mobile picker'ga yo'naltirish kerak) |
| 403 | `{"error":{"code":"forbidden"}}` | Permission yetishmaydi | `forbidden` |
| 404 | `{"error":{"code":"not_found","what":"customer\|project"}}` | Topilmadi | `notFound` |
| 502 | `{"error":{"code":"upstream_unavailable",...}}` | SOAP down + cache yo'q | `upstreamUnavailable` (retry mumkin) |
| 503 | `{"error":{"code":"not_configured"}}` | Org `external_balance_is_enabled=false` | `notConfigured` (retry yo'q) |

Mobile [`ClientBalanceCubit._classifyError`](../lib/src/features/agent/presentation/bloc/client_balance_cubit.dart) shu envelope'larni mapping qiladi.

### 1.4 GET `/api/mobile/v2/projects/config/`

#### Response 200 (Passport §3)

```json
[
  {"code": "EVYAP", "debt_limit": "5000000.00", "debt_limit_currency": "UZS"},
  {"code": "LOREAL_UT", "debt_limit": null, "debt_limit_currency": "UZS"}
]
```

**Behavior:**
- Faqat foydalanuvchiga ko'rinadigan loyihalar.
- `debt_limit = null` → limit yo'q (mobile `noDebt` sifatida ko'radi).
- Mobile [`DataSyncService._syncProjectsConfig`](../lib/src/core/services/data_sync_service.dart#L2382) `_syncUserProjects` oxirida chaqiradi.

### 1.5 Audit / IntegrationLog (Passport §7)

Backend tomonida **har bir SOAP chaqiruv** logga yozilishi kerak:

```python
# apps/sync/integration_log.py
IntegrationLog.objects.create(
    endpoint=organization.external_balance_url,
    project=project,
    organization=organization,
    request_payload=soap_envelope,
    response_payload=soap_response[:5000],  # truncate
    status='OK' | 'HTTP_ERROR' | 'TIMEOUT' | 'TRANSPORT_ERROR',
    duration_ms=elapsed_ms,
)
```

**Va** har bir `blocked=true` decision alohida log:
```python
IntegrationLog.objects.create(
    endpoint='customers/balance/blocked',
    customer=customer,
    project=project,
    organization=organization,
    request_payload={'balance': str(balance), 'limit': str(debt_limit)},
    response_payload={'reason': 'debt_limit_exceeded'},
    status='OK',
)
```

### 1.6 Telemetry endpoint (P0.4 mobile)

Mobile [`BalanceGateEventLogger`](../lib/src/features/agent/services/balance_gate_event_logger.dart) `balance_gate_blocked` event'ni quyidagi endpoint'ga POST qiladi:

```
POST /api/mobile/v2/analytics/balance-gate/
```

**Hozircha mobile failure'ni silently swallow qiladi** — endpoint deploy bo'lmaguncha. Backend tomonida quyidagi shape'ni qabul qilishi:

```json
{
  "event": "customer.balance.blocked",
  "code_1c": "00-00053242",
  "project_code": "EVYAP",
  "balance": -2250.0,
  "limit": 5000000.0,
  "currency": "UZS",
  "source": "fresh",
  "reason": "debt_limit_exceeded",
  "is_offline": false,
  "is_stale": false,
  "trigger": "visit_step_entry",
  "timestamp": "2026-05-14T12:00:00Z"
}
```

Response: `204 No Content` (mobile body o'qimaydi).

**Storage:** `apps.analytics.BalanceGateEvent` (yangi model). Index: `(organization, code_1c, project_code, timestamp)`.

### 1.7 Project switch backend semantikasi

Mobile [`clearCustomerCacheForProjectSwitch`](../lib/src/core/services/api_database_service.dart#L9307) loyiha o'zgarganda `client_balances/contracts/orders` ni tozalaydi (M12 P0.2). Backend tomondan:

- [ ] Token yangi `X-Project-Id` bilan kelganda: `Customer.objects.filter(project=project)` aniq filter.
- [ ] Loyiha B'da loyiha A'ning balansini qaytarmasligi.
- [ ] Regression test: 2 ta loyiha + bir xil INN → har biriga alohida balans.

## 2. Smoke test playbook

### 2.1 Local backend

```bash
# Backend repo'da:
docker-compose up -d
python manage.py migrate
python manage.py runserver 0.0.0.0:8080
```

### 2.2 Mobile config

```dart
// lib/src/core/network/server_service.dart
const _devBaseUrl = 'http://192.168.0.194:8080';  // backend container
```

### 2.3 Charles Proxy bilan kuzatish

Quyidagilarni kuzating:

1. **Login** → POST `/api/mobile/v1/auth/login_1c/` → 200 + Bearer token.
2. **Sync** → GET `/api/mobile/v2/customers/` → 200 + customer list. **Header'da `X-Project-Id` ko'rinishi**.
3. **Sync** → GET `/api/mobile/v2/projects/config/` → 200 + array. **Header'da `X-Project-Id` ko'rinishi**.
4. **Mijozni ochish** → POST `/api/mobile/v2/customers/balance/` → 200 + Passport §2.1 shape. **`X-Project-Id` header**.
5. **Force refresh tugma** → xuddi shunday POST, lekin `force_refresh: true` body'da.
6. **Charles'da TAQIQLANGAN host'lar:** `kit.gloriya.uz:5443`, `178.218.200.120`, `109.94.175.104` — **bularga hech qanday so'rov ketmasligi**.

### 2.4 Force-fail scenariolar

| Scenario | Backend qanday qilinadi | Kutilgan mobile UI |
|---|---|---|
| `not_configured` | Test org'ni `external_balance_is_enabled=False` qilish | Error sheet "Balans tekshiruvi sozlanmagan" |
| `upstream_unavailable` | SOAP URL'ni invalid qilish, cache tozalash | Sheet "Buxgalteriya serveri ishlamayapti" |
| `not_found` | Mavjud bo'lmagan `code_1c` yuborish | Sheet "Mijoz topilmadi" |
| `customer_project_required` | Mobile'da loyiha tanlanmagan holatda fetch | Picker'ga avtomatik yo'naltirish |
| `debt_limit_exceeded` | Test mijozning balansini limit'dan oshirish | Card qizil, indicator pulse, "create order" disabled |
| `stale` | SOAP'ni o'chirib qo'yib, cache mavjud | Sheet'da "24 soatdan eskirgan" warning |

## 3. CI integration test (kelajak)

Yaratish: `integration_test/customer_balance_e2e_test.dart`

```dart
testWidgets('balance gate full flow', (tester) async {
  // Login → mijozlar list → ko'rish → indicator → bottom sheet →
  // Refresh tugma → backend log'ga balance fetch yozilishi.
});
```

GitHub Actions workflow:
```yaml
# .github/workflows/integration.yml
- name: Run integration tests
  run: flutter test integration_test/
  env:
    BACKEND_URL: http://staging.api.gloriya.uz
```

## 4. Deploy gating

Mobile P0/P1 release'gacha quyidagi backend gatelari tasdiqlanishi kerak:

- [ ] `/api/mobile/v2/customers/balance/` deploy bo'lgan va Passport §2.1 shape qaytaradi
- [ ] `/api/mobile/v2/projects/config/` deploy bo'lgan
- [ ] `X-Project-Id` ikkala endpoint'da ham o'qiladi
- [ ] Passport §2.5 error envelope (5 ta status)
- [ ] IntegrationLog yoziladi (har SOAP + har blocked decision)
- [ ] (Optional, P0.4 to'liq bo'lishi uchun) `/api/mobile/v2/analytics/balance-gate/` deploy bo'lgan

Bular tasdiqlangach mobile production rollout boshlanishi mumkin.
