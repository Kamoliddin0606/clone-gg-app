# Customer Balance Passport — umumiy standart (v2)

> Yagona haqiqat manbai. Backend va Mobile har qanday implementation savolida shu hujjatga murojaat qiladi. Bu yerda yo'q narsa — bog'lovchi emas. Bu yerdagi shartlarga zid implementation noto'g'ri.

## 0. Maqsad

Mijozning loyiha bo'yicha qarzdorligini (balans) olishni mobile ilovadan **butunlay backendga ko'chirish** va loyiha qarz chegarasi (`debt_limit`) bo'yicha buyurtma olishni bloklash mexanizmini joriy etish.

Hozir mobile to'g'ridan-to'g'ri 1C buxgalteriya SOAP serveriga (`http://kit.gloriya.uz:5443/gloriya_buh2/...`) ulanadi. **Yangi rejim** — mobile faqat bizning backendga REST so'rovi yuboradi; backend o'z navbatida tegishli 1C endpointga SOAP yuboradi.

## 1. Ma'lumotlar egaligi (data ownership)

| Konfiguratsiya | Joyi | Sabab |
|---|---|---|
| Balans SOAP URL'i, fallback IP'lar, auth credentials | **Organization** modeli (`apps/tenants/models.py`) | Bitta tashkilotning barcha loyihalari shu yagona buxgalteriya bazasidan o'qiydi. Project'da takrorlash chiqindi. |
| External `<sam:Project>` qiymati (SOAP'ga jo'natiladigan loyiha nomi, mas. `"EVYAP"`) | **Project** modeli (`external_balance_project_name`) | Har loyihaning o'z 1C-side identifikatori bor. |
| `debt_limit`, `debt_limit_currency` | **Project** modeli | Har loyiha o'z chegarasini belgilaydi. NULL = limit yo'q. |
| Cached balans + breakdown | **`CustomerBalanceCache`** model — `(customer, project)` unique | Har bir `(mijoz, loyiha)` juftligi uchun yagona keng yozuv. |

## 1.5 Authentication & headers (barcha endpoint'lar uchun umumiy)

Quyidagi qoidalar §2, §3 va §3.5'da yozilgan **uchchala** balance endpoint'iga taalluqli.

### Headerlar

| Header | Qachon | Sabab |
|---|---|---|
| `Authorization: Bearer <token>` | Har doim majburiy | Mobile [`ApiService`](../lib/src/core/network/api_service.dart) interceptori avtomatik attach qiladi (V2 token) |
| `X-Project-Id: <uuid \| 1c-ref \| code>` | **Project-scope tenant'larda majburiy** | Mobile [`CustomerEndpointHeaders`](../lib/src/core/network/customer_endpoint_headers.dart) attach qiladi |
| `Content-Type: application/json` | POST'larda | Standart |
| `Accept: application/json` | Standart | — |

### `X-Project-Id` qoida

- **Org-scope tenant** (`Organization.customer_scope == "organization"`): backend header'ni e'tiborsiz qoldiradi. Customer global org ostida resolve qilinadi.
- **Project-scope tenant** (`Organization.customer_scope == "project"`):
  - Header **majburiy**. Yo'q bo'lsa: HTTP 400 + `{"error":{"code":"customer_project_required",...}}`.
  - Backend qabul qilishi kerak bo'lgan format: `Project.id` (UUID), `Project.id_1c` (`00-XXXXXX`), yoki `Project.code` (SOAP-style). Uchchalasini ham resolve qiladi (priority: UUID → 1C → code).
  - Backend `Customer.objects.filter(project=<resolved>, code_1c=<request.code_1c>)` aniq filter — boshqa loyiha customer'ini qaytarmasligi kerak (cross-project leak yo'q).

### Permission

Hamma uchun: `customers.view_customer` codename. Foydalanuvchining `BackendPermissionStore` ga sync qilinadigan codename'lari ichida.

## 2. Endpoint — `POST /api/mobile/v2/customers/balance/`

**Auth:** §1.5'ga binoan Bearer + (project-scope'da) X-Project-Id. Permission: `customers.view_customer`.

**Request body:**

```json
{
  "code_1c": "00-00053242",
  "project_code": "EVYAP",
  "force_refresh": false
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `code_1c` | string | yes | Mijozning 1C kodi. Mobile `TradingPoint.code1c`. |
| `project_code` | string | yes | Loyiha backend `code`'i. Mobile `UserProject.code`. |
| `force_refresh` | bool | no | `true` — cache TTL chetlab o'tiladi, SOAP majburiy chaqiriladi. |

### 2.1 Response 200 — to'liq shape

JSON kalitlari mobile [`lib/src/features/agent/data/models/client_balance.dart`](https://github.com/) ichidagi `ClientBalance.toJson()` chiqarayotgan kalitlar bilan **aynan bir xil**. Bu mobile `ClientBalance.fromJson()`'ga kalit nomlari uchun o'zgartirish kiritmaslikka imkon beradi — faqat yangi optional maydonlar qo'shiladi.

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
  "contract_balances": [
    {
      "project_name": "Проект  ТМ \"AVON\"",
      "region": "Ташкент",
      "tax_id": "308976156",
      "customer_name": "\"FAMILY-HONEST-TRADE\" Масъулияти чекланган жамият",
      "contract_code": "Договор № 6060001/24 от 15 февраля 2024 г.",
      "payment_amount": "5356620",
      "debt_amount": "-2250",
      "contract_id": "7034593"
    }
  ],
  "order_balances": [
    {
      "project_name": "Проект  ТМ \"AVON\"",
      "region": "Ташкент",
      "tax_id": "308976156",
      "customer_name": "\"FAMILY-HONEST-TRADE\" Масъулияти чекланган жамият",
      "contract_code": "7034593",
      "sales_channel": "",
      "order_number": "Реализация товаров и услуг 00000015128 от 09.07.2024 12:00:00",
      "order_date": "2024-07-09",
      "order_amount": "633270",
      "payment_amount": "633270",
      "debt_amount": "0",
      "status": "Оплачено",
      "overdue_days": 0,
      "contract_id": "7034593"
    },
    {
      "project_name": "Проект  ТМ \"AVON\"",
      "region": "Ташкент",
      "tax_id": "308976156",
      "customer_name": "\"FAMILY-HONEST-TRADE\" Масъулияти чекланган жамият",
      "contract_code": "7034593",
      "sales_channel": "",
      "order_number": "",
      "order_date": null,
      "order_amount": null,
      "payment_amount": "2250",
      "debt_amount": "-2250",
      "status": "Переплата",
      "overdue_days": null,
      "contract_id": "7034593"
    }
  ]
}
```

### 2.2 Top-level fields

| Field | Type | Nullable | Mobile model field | Notes |
|---|---|---|---|---|
| `inn` | string | no | `ClientBalance.inn` | So'ralgan INN. |
| `client_code` | string | yes | `ClientBalance.clientCode` | Backend `Customer.code` (`C-XXXXXXXX`). |
| `project_name` | string | no | `ClientBalance.projectName` | SOAP'ga jo'natilgan `<sam:Project>` qiymati (= `Project.external_balance_project_name`). |
| `balance` | string (Decimal) | no | `ClientBalance.balance` | **Musbat = qarzdorlik**. **Manfiy = oldindan to'lov.** |
| `currency` | string | no | (yangi) | ISO 4217 — default `"UZS"`. |
| `debt_limit` | string (Decimal) | yes | (yangi) | `null` = limit yo'q. |
| `debt_limit_currency` | string | no | (yangi) | Default `"UZS"`. |
| `server_data_updated_at` | ISO-8601 datetime (TZ-naive bo'lishi mumkin) | yes | `serverDataUpdatedAt` | 1C `updatedDateTime` qiymati **verbatim**. |
| `last_updated` | ISO-8601 datetime | no | `lastUpdated` | Backend cache yozish vaqti (= `fetched_at` semantikasi). |
| `blocked` | bool | no | (yangi) | `(debt_limit != null) AND (balance > debt_limit)`. Backend qarori. |
| `block_reason` | string | yes | (yangi) | Hozir faqat `"debt_limit_exceeded"` yoki `null`. |
| `source` | enum string | no | (yangi) | `"fresh"` / `"cache"` / `"stale"`. |
| `last_error` | string | yes | (yangi) | `source="stale"` bo'lganda SOAP xatosi qisqacha tavsifi. |
| `contract_balances` | array | no | `contractBalances` | 1C `<m:ClientBalanceByContract>` list'i. |
| `order_balances` | array | no | `orderBalances` | 1C `<m:ClientBalanceByOrder>` list'i. |

### 2.3 Contract item shape (`contract_balances[]`)

| Field | Type | Nullable | 1C SOAP element |
|---|---|---|---|
| `project_name` | string | no | `<m:projectName>` |
| `region` | string | no | `<m:region>` |
| `tax_id` | string | no | `<m:taxId>` |
| `customer_name` | string | no | `<m:customerName>` |
| `contract_code` | string | no | `<m:contractCode>` |
| `payment_amount` | string (Decimal) | no | `<m:paymentAmount>` |
| `debt_amount` | string (Decimal) | no | `<m:debtAmount>` — musbat = qarz, manfiy = oldindan to'lov. |
| `contract_id` | string | no | `<m:contractId>` |

### 2.4 Order item shape (`order_balances[]`)

| Field | Type | Nullable | 1C SOAP element |
|---|---|---|---|
| `project_name` | string | no | `<m:projectName>` |
| `region` | string | no | `<m:region>` |
| `tax_id` | string | no | `<m:taxId>` |
| `customer_name` | string | no | `<m:customerName>` |
| `contract_code` | string | no | `<m:contractCode>` |
| `sales_channel` | string | no | `<m:salesChannel>` — bo'sh bo'lsa `""`. |
| `order_number` | string | no | `<m:orderNumber>` — bo'sh bo'lsa `""`. |
| `order_date` | ISO-8601 date | yes | `<m:orderDate>` — `xsi:nil="true"` bo'lsa `null`. |
| `order_amount` | string (Decimal) | yes | `<m:orderAmount>` — `xsi:nil="true"` bo'lsa `null`. |
| `payment_amount` | string (Decimal) | no | `<m:paymentAmount>` |
| `debt_amount` | string (Decimal) | no | `<m:debtAmount>` |
| `status` | string | no | `<m:status>` — **verbatim russian**. Mavjud qiymatlar: `"Оплачено"`, `"Неоплачен"`, `"Частично"`, `"Переплата"`. Backend tarjima qilmaydi. |
| `overdue_days` | int | yes | `<m:overdueDays>` — `xsi:nil="true"` bo'lsa `null`. |
| `contract_id` | string | no | `<m:contractId>` |

### 2.5 Error responses

| Status | Body | Sabab |
|---|---|---|
| 400 | `{"error": "validation", "details": {...}}` | Body invalid. |
| 403 | `{"error": "forbidden"}` | Auth/permission yetishmaydi. |
| 404 | `{"error": "not_found", "what": "customer"\|"project"}` | Mijoz yoki loyiha topilmadi. |
| 502 | `{"error": "upstream_unavailable", "detail": "..."}` | SOAP ishlamadi **va** hech qanday cached qiymat yo'q. |
| 503 | `{"error": "not_configured"}` | `organization.external_balance_is_enabled == false` yoki URL bo'sh. |

## 3. Endpoint — `GET /api/mobile/v2/projects/config/`

**Auth:** §1.5'ga binoan Bearer + (project-scope'da) X-Project-Id.

**Response 200:**

```json
[
  { "code": "EVYAP",     "debt_limit": "5000000.00", "debt_limit_currency": "UZS" },
  { "code": "LOREAL_UT", "debt_limit": null,         "debt_limit_currency": "UZS" }
]
```

Foydalanuvchiga ko'rinadigan loyihalar bilan cheklanadi. Mobile bu endpointni `syncUserProjects` oxirida chaqirib lokal `user_projects` jadvalini yangilaydi.

`debt_limit_currency` har doim string (default `"UZS"`). `debt_limit` `null` bo'lsa — limit yo'q (mobile uni `noDebt` sifatida ko'radi).

## 3.5 Endpoint — `POST /api/mobile/v2/analytics/balance-gate/`

Mobile [`BalanceGateEventLogger`](../lib/src/features/agent/services/balance_gate_event_logger.dart) `DebtBlockedDialog` ko'rsatilgan har gal shu endpoint'ga **best-effort** event yuboradi (Passport §7 talabini qondirish uchun).

**Auth:** §1.5'ga binoan Bearer + (project-scope'da) X-Project-Id.

**Request body:**

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

| Field | Type | Required | Notes |
|---|---|---|---|
| `event` | string | yes | Hozircha faqat `"customer.balance.blocked"`. Kelajakda boshqa event'lar (`"customer.balance.fetched"`, etc.) qo'shilishi mumkin. |
| `code_1c` | string | yes | Empty bo'lishi mumkin (legacy caller'lar). |
| `project_code` | string | yes | Empty bo'lishi mumkin. |
| `balance` | number (double) | yes | Spec note: bu yerda **double**, chunki mobile-dan keladi. §2.2 string-Decimal qoidasi faqat backend → mobile yo'nalishida. |
| `limit` | number (double) \| null | yes | `null` = limit yo'q. |
| `currency` | string | yes | ISO 4217. |
| `source` | string | yes | `"fresh" \| "cache" \| "stale" \| "local"`. `"local"` = offline branch. |
| `reason` | string \| null | yes | `"debt_limit_exceeded" \| "no_cached_balance" \| "fetch_failed" \| "no_active_project" \| null`. |
| `is_offline` | bool | yes | Mobile `ConnectivityMonitorService.isConnected == false` bo'lganmi. |
| `is_stale` | bool | yes | Cached balans 24+ soat eskirganmi. |
| `trigger` | string | yes | Kim emit qildi: `"visit_step_entry" \| "visit_step_tile" \| "pre_submit" \| "detail_sheet" \| "unknown"`. |
| `timestamp` | ISO-8601 (UTC) | yes | Mobile tomonida yaratilgan vaqt. |

**Response 204** — body yo'q. Mobile body o'qimaydi.

**Behavior:**

- Idempotent emas — har dialog show alohida event sifatida saqlanadi.
- Failure'ni mobile silently swallow qiladi (analytics hech qachon UI'ni bloklamaydi). Endpoint deploy bo'lmaganda mobile 404 oladi va e'tiborsiz qoldiradi.

**Storage (backend tavsiya etiladigan):** `apps.analytics.BalanceGateEvent` Django model:

```python
class BalanceGateEvent(models.Model):
    organization = models.ForeignKey('tenants.Organization', on_delete=models.CASCADE)
    user = models.ForeignKey('users.User', on_delete=models.CASCADE)
    project = models.ForeignKey('projects.Project', on_delete=models.SET_NULL, null=True)
    customer_code_1c = models.CharField(max_length=64)
    event_name = models.CharField(max_length=64)  # "customer.balance.blocked"
    balance = models.DecimalField(max_digits=20, decimal_places=2)
    debt_limit = models.DecimalField(max_digits=20, decimal_places=2, null=True)
    currency = models.CharField(max_length=8, default='UZS')
    source = models.CharField(max_length=16)
    reason = models.CharField(max_length=64, null=True)
    is_offline = models.BooleanField(default=False)
    is_stale = models.BooleanField(default=False)
    trigger = models.CharField(max_length=32, default='unknown')
    client_timestamp = models.DateTimeField()
    server_timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=['organization', 'project', 'server_timestamp']),
            models.Index(fields=['customer_code_1c', 'server_timestamp']),
        ]
```

## 4. Cache va TTL invariantlari

- `CustomerBalanceCache` — har `(customer, project)` juftligi uchun bittadan qator.
- TTL: **60 sekund**. Shu vaqt ichida `source="cache"` qaytadi, SOAP chaqirilmaydi.
- `force_refresh=true` — TTL'ni chetlab o'tadi.
- SOAP failure + cached qiymat mavjud → `source="stale"`, javob baribir 200. `last_error` to'ldiriladi.
- SOAP failure + cached qiymat yo'q → 502.

## 5. Block decision invariant

`blocked` qaroriga **birinchi navbatda backend** mas'ul. Formula:

```
blocked = (debt_limit != null) AND (balance > debt_limit)
```

Mobile **online** holatda backend qaroriga ergashadi. **Offline** holatda esa lokal `ClientBalance.balance` va lokal `UserProject.debtLimit` bilan **aynan o'sha formula** bo'yicha qayta hisoblaydi.

Defense-in-depth: offline-yig'ilgan buyurtmani serverga yuborishdan oldin mobile yana bir bor `force_refresh=true` bilan balansni so'raydi va `blocked=true` bo'lsa buyurtmani yubormaydi.

## 6. SOAP edge case'lari (parser MUST handle)

Real 1C namunasidan tasdiqlangan:

1. **Manfiy balans** (`<m:balance>-2250</m:balance>`) — oldindan to'lov. JSON: `"balance": "-2250"`.
2. **Status `"Переплата"`** — overpayment qatori (`orderAmount` null, `paymentAmount > 0`, `debtAmount < 0`).
3. **`xsi:nil="true"`** — `orderDate`, `orderAmount`, `overdueDays`'da uchraydi → JSON `null`.
4. **Bo'sh element** — `<m:orderNumber/>`, `<m:salesChannel/>` → JSON `""`.
5. **Timezone-naive datetime** — `<m:updatedDateTime>2026-05-14T00:00:00</m:updatedDateTime>` — TZ yo'q. Backend verbatim string sifatida o'tkazadi.
6. **Cyrillic + maxsus belgilar** — qo'shtirnoq, hash sanasi, lotin-kirill aralash — JSON escape orqali to'g'ri uzatiladi.
7. **Sonlar integer-like** — `"5356620"` (decimal point yo'q). Backend Decimal sifatida saqlaydi, JSON'ga string sifatida chiqaradi.
8. **Whitespace** — `<m:projectName>Проект  ТМ "AVON"</m:projectName>` — qo'sh probel saqlanadi.

## 7. Logging va audit

### 7.1 SOAP chaqiruvlari (har bir `customers/balance/` POST'da)

`apps.sync.IntegrationLog` model'iga yoziladi (har bir SOAP chaqiruv = bitta qator):

```python
IntegrationLog.objects.create(
    endpoint=organization.external_balance_url,
    project=project,                            # FK
    organization=organization,                  # FK
    request_payload=soap_envelope_xml,          # full XML
    response_payload=soap_response_xml[:5000],  # truncated
    status='OK' | 'HTTP_ERROR' | 'TIMEOUT' | 'TRANSPORT_ERROR',
    duration_ms=elapsed_ms,
    created_at=timezone.now(),
)
```

SOAP failure bo'lsa `CustomerBalanceCache.last_error`'ga ham qisqacha tavsif yoziladi (mobile uchun `last_error` field'i orqali ko'rinadi).

### 7.2 Block decision (har bir `blocked=true` qarorda)

`/customers/balance/` ichida `blocked = true` qaror chiqarilganda alohida log:

```python
IntegrationLog.objects.create(
    endpoint='customers/balance/blocked',
    project=project,
    organization=organization,
    customer=customer,                          # FK (yangi field, optional)
    request_payload={
        'code_1c': customer.code_1c,
        'project_code': project.code,
        'balance': str(balance),
        'debt_limit': str(project.debt_limit),
    },
    response_payload={'reason': 'debt_limit_exceeded'},
    status='OK',
    duration_ms=0,
)
```

### 7.3 Mobile-side analytics

Mobile [`BalanceGateEventLogger`](../lib/src/features/agent/services/balance_gate_event_logger.dart) Passport §3.5 endpoint'iga POST yuboradi (`POST /api/mobile/v2/analytics/balance-gate/`). Backend bu event'larni `BalanceGateEvent` model'ida saqlaydi (Passport §3.5 storage misoliga qarang).

**Diff vs §7.2:** §7.2 backend o'z block qarorini log qiladi, §7.3 mobile-side observability — masalan, offline holda mobile o'zicha block qarorini chiqargan bo'lsa, bu §7.2'ga tushmaydi (backend chaqiruv bo'lmaydi), faqat §7.3'da ko'rinadi. Shuning uchun ikkala log to'liq picture beradi.

## 8. Versioning

- Endpoint URL'i `v2` ostida.
- Yangi field qo'shish — non-breaking. Mobile noma'lum maydonlarni e'tiborsiz qoldiradi.
- Field nomi yoki shape o'zgarishi — `v3` ostida chiqariladi.

## 9. Real SOAP namunasi

**Request:**

```xml
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:GeClientBalance>
         <sam:INN>308976156</sam:INN>
         <sam:Project>EVYAP</sam:Project>
      </sam:GeClientBalance>
   </soap:Body>
</soap:Envelope>
```

Headers: `Content-Type: application/soap+xml; charset=utf-8`, `SOAPAction: ""`.

**Response (qisqartirilgan):**

```xml
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
   <soap:Body>
      <m:GeClientBalanceResponse xmlns:m="http://www.sample-package.org">
         <m:return xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <m:balance>-2250</m:balance>
            <m:updatedDateTime>2026-05-14T00:00:00</m:updatedDateTime>
            <m:ClientBalanceByContract xsi:type="m:ClientBalanceByContract">
               <m:projectName>Проект  ТМ "AVON"</m:projectName>
               <m:region>Ташкент</m:region>
               <m:taxId>308976156</m:taxId>
               <m:customerName>"FAMILY-HONEST-TRADE" Масъулияти чекланган жамият</m:customerName>
               <m:contractCode>Договор № 6060001/24 от 15 февраля 2024 г.</m:contractCode>
               <m:paymentAmount>5356620</m:paymentAmount>
               <m:debtAmount>-2250</m:debtAmount>
               <m:contractId>7034593</m:contractId>
            </m:ClientBalanceByContract>
            <m:ClientBalanceByOrder xsi:type="m:ClientBalanceByOrder">
               <m:projectName>Проект  ТМ "AVON"</m:projectName>
               <m:region>Ташкент</m:region>
               <m:taxId>308976156</m:taxId>
               <m:customerName>"FAMILY-HONEST-TRADE" Масъулияти чекланган жамият</m:customerName>
               <m:contractCode>7034593</m:contractCode>
               <m:salesChannel/>
               <m:orderNumber/>
               <m:orderDate xsi:nil="true"/>
               <m:orderAmount xsi:nil="true"/>
               <m:paymentAmount>2250</m:paymentAmount>
               <m:debtAmount>-2250</m:debtAmount>
               <m:status>Переплата</m:status>
               <m:overdueDays xsi:nil="true"/>
               <m:contractId>7034593</m:contractId>
            </m:ClientBalanceByOrder>
         </m:return>
      </m:GeClientBalanceResponse>
   </soap:Body>
</soap:Envelope>
```

## 10. Mas'uliyat chegarasi (kim nima qiladi)

| Bosqich | Backend | Mobile |
|---|---|---|
| Mijoz balansini olish | SOAP chaqiruvi, parsing, cache, blocked qaror | REST chaqiruvi, JSON deserialize, UI'ga ko'rsatish |
| `debt_limit` saqlash | `Project.debt_limit` | Lokal `UserProject.debtLimit` (sync orqali) |
| Online order gate | `blocked` qaytarish | UI'da `blocked=true` bo'lsa step'ni ochmaslik |
| Offline order gate | yo'q (mobile'da) | Lokal cache + lokal limit bo'yicha taqqoslash |
| Pre-submit recheck | yangi SOAP + cache update | mobile chaqiradi (force_refresh=true) |
| Bloklangan order UI | yo'q | `sync_error="debt_limit_exceeded"` rows uchun badge |

## 11. O'zgartirish jurnali

| Versiya | Sana | O'zgarish |
|---|---|---|
| v1 | 2026-05-14 | Birinchi versiya. |
| v2 | 2026-05-15 | §1.5 (Authentication + X-Project-Id qoidasi) qo'shildi. §3.5 (`POST /api/mobile/v2/analytics/balance-gate/`) qo'shildi. §7 IntegrationLog format aniq belgilandi. Mobile P0 ishlari hisobga olindi. |
