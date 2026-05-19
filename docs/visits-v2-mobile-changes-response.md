# Visits v2 — Mobile response to backend 2026-05-17 changelog

> **Maqsad**: Backend `docs/integration-prompts/visits-v2-mobile-changes.md`
> (2026-05-17) talab qilgan har bir nuqtaning mobile tomondagi javobi.
> Backend wire shape o'zgartirilmagan, lekin 11 ta xulq nuance bor —
> har biri uchun mobile audit / kod o'zgarishi / test.
>
> **Status**: ✅ Hammasi tugadi. Mobile rollout R1 (dev pilot) ga tayyor.

---

## Checklist mapping

| # | Backend talab | Mobile holat | Joy |
|---|---|---|---|
| 1 | `visit_submission_path` har refresh'da o'qish | ✅ Audit pass + `_informVisit` best-effort refresh | `trading_points_page.dart` |
| 2 | Photo upload → finish polling olib tashlash | ✅ `PhotoRepository.noFailedFor` + `_onFinish` yumshatildi | `photo_repository.dart`, `visit_session_bloc.dart` |
| 3 | 30+ kun foto fallback chain | ✅ `EntityImageRef` + `RetentionAwarePhoto` widget | `entity_image_ref.dart`, `retention_aware_photo.dart` |
| 4 | `client_uuid` / `idempotency_key` namespace | ✅ Audit pass — best practice (per-attempt UUIDv7) | — |
| 5 | 2 parallel finish xavfsizligi | ✅ Yangi test: 200 replay + parallel cycle | `outbox_dispatcher_test.dart` |
| 6 | `Idempotent-Replay: true` header → telemetry | ✅ `DispatchSuccess.idempotentReplay` → Crashlytics breadcrumb | `outbox_dispatcher.dart`, `visits_crashlytics_reporter.dart` |
| 7 | `Visit.status=synced_1c` polling (30s) | ✅ `VisitStatusPoller` + `VisitApi.fetchVisitStatus` | `visit_status_poller.dart`, `visit_api.dart` |
| 8 | ETag handling (`/permissions/`, `/catalog/`) | ✅ `NotModifiedException` public + 304 fast-path | `visit_api.dart`, `*_repository_impl.dart` |
| 9 | Yangi `visits_*` error code UX translations | ✅ `VisitFailureCopy.localize(failure, locale)` uz/ru/en | `failure_messages.dart` |
| 10 | `client_uuid` per device, `idempotency_key` per attempt | ✅ Audit pass (`LocalUuidService` + `Uuid().v7()` per envelope) | — |
| 11 | `Wire shape o'zgartirilmagan` | ✅ Hech qanday DTO o'zgarishi shart bo'lmadi (Phase 2 da contract regression test mavjud) | `backend_contract_regression_test.dart` |

---

## 1. `visit_submission_path` (changelog § 1)

**Mavjud xulq**: `FeatureFlags.visitSubmissionPath` getter har chaqirilganda
`permissions.cached?.flags.visitSubmissionPath` ni o'qiydi. Cache TTL 1 soat;
login va app bootstrap'da `forceRefresh: true` bilan yangilanadi.

**Yangi qadam**: `TradingPointsPage._informVisit` ham visit start'dan oldin
best-effort `getCurrent()` qiladi. Admin flag flip propagation latency
1 soatdan ≤ 1 round-trip ga tushadi.

```dart
if (sl.isRegistered<PermissionsRepository>()) {
  try {
    await sl<PermissionsRepository>().getCurrent();
  } catch (_) {/* cache fallback */}
}
final useRestV2 = sl<FeatureFlags>().useRestV2;
```

---

## 2. Pre-finish photo gate yumshatish (changelog § 2)

**Eski qoida**: `PhotoIntegrityValidator` faqat `status='ready'` qabul qilardi;
mobile finish'gacha `confirmed` ga o'tishini polling qilardi.

**Yangi qoida** (backend yumshatdi): `pending` / `processing` / `ready`
o'tadi; faqat `failed` rad etiladi.

**Mobile o'zgarishi**:
- `PhotoRepository.noFailedFor(visitId)` qo'shildi — faqat `failed` mavjudligini
  tekshiradi.
- `VisitSessionBloc._onFinish` `allConfirmedFor` o'rniga `noFailedFor` ishlatadi.
- Outbox dispatcher photo upload'larni davom etadi (asinxron).

UX foydasi: ~2-5 s tezroq finish, agent kutmaydi.

---

## 3. Photo retention fallback (changelog § 3)

**Yangi widget** `RetentionAwarePhoto`:

```
thumbnail  : small → medium → blurhash → placeholder
full-screen: large → medium → blurhash → placeholder
```

`CachedNetworkImage.errorWidget` chain ishlatiladi — 404 (small/large
o'chirilgan) avtomatik medium ga tushadi. 90+ kun visit'larda
`blurhash` qoladi.

**EntityImageRef DTO** (`entity_image_ref.dart`): `id`, `smallUrl`,
`mediumUrl`, `largeUrl`, `blurhash`, `status` — backend response
shape'iga to'liq mos.

---

## 4. Idempotency key namespace (changelog § 4)

**Audit**:
- Har envelope: `Uuid().v7()` (`VisitEnvelopeBuilder`).
- Har photo: `Uuid().v7()` (`PhotoRepositoryImpl.capture`).
- Cancel chaqirilsa: caller yangi `idempotency_key` taqdim etishi shart
  (mobile UI hozir `VisitFinishOrchestrator.retry` orqali shu yo'lda
  ishlaydi).

**Best practice ga to'liq mos** — backend kafolatidan ham qattiqroq.

---

## 5. Concurrency safety (changelog § 5)

**Yangi test'lar** (`outbox_dispatcher_test.dart`):

- `idempotent 200 replay (backend changelog § 5) acks as cleanly as 201` —
  200 status code 201 kabi `DispatchSuccess` deb tan olinishi.
- `two parallel cycles on the same outbox process the row exactly once` —
  `_dispatching` re-entrance latch Workmanager + foreground
  konfliktlarini bartaraf qilishi.

`sendCount == 1` invariant'i ikkala stsenariy uchun ham qattiq.

---

## 6. `Idempotent-Replay: true` header (changelog § 6)

**Mobile o'zgarishi**:

```dart
// outbox_dispatcher.dart _send()
final replay = response.headers.value('idempotent-replay')?.trim()
                  .toLowerCase() == 'true';
return DispatchSuccess(httpStatus: status, idempotentReplay: replay);
```

`OutboxStatus.acked` flag'ni Crashlytics breadcrumb'ga yetkazadi:
```
outbox kind=acked envelope_id=... http=200 replay=true
```

Network-quality dashboards bu yorliqdan "fresh write" vs "retry replay"
ni ajratishi mumkin.

---

## 7. Visit status polling (changelog § 7)

**Yangi service** `VisitStatusPoller`:

```dart
final handle = sl<VisitStatusPoller>().pollUntilTerminal(
  visitId,
  timeout: const Duration(seconds: 30),
  interval: const Duration(seconds: 5),
);
final result = await handle.future;
if (result.reached1C) showSnackBar('Buyurtma 1C ga yetkazildi');
else if (result.timedOut) showSnackBar('Buyurtma yo\'lda...');
else if (result.rejected) showSnackBar('1C qabul qilmadi: ops ko\'rib chiqadi');
```

Cubit/page ixtiyoriy darajada chaqiradi — outbox `ack` o'z-o'zidan
`visits_v2.status='synced'` ni belgilab beradi, bu polling faqat
**1C-side** statusni ko'rsatish uchun.

---

## 8. ETag handling (changelog § 9)

**Eski**: `_NotModified` private exception — repository tuta olmasdi;
304 holatlari `Exception` deb umumiy tushar edi.

**Yangi**: `NotModifiedException` public + repository fast-path:

```dart
try {
  final fresh = await _api.fetchPermissions(etag: _hot?.etag);
  ...
} on NotModifiedException {
  return _hot!;            // 304 — cached snapshot is authoritative
} on NetworkFailure {
  if (_hot != null) return _hot!;
  rethrow;
}
```

Permissions va catalog ikkalasi uchun bir xil shakl.

---

## 9. Error code UX (changelog § 10)

**Yangi** `VisitFailureCopy.localize(failure, locale: 'uz')`:

```dart
final message = VisitFailureCopy.localize(failure, locale: 'uz');
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
```

8 ta error code (`VISITS_GEOFENCE_VIOLATION`, `VISITS_CLOCK_DRIFT`, …) uchun
uz/ru/en triple. Noma'lum code → `failure.message` fallback.

---

## 10-11. Wire shape stability + final checklist

Backend `Wire shape o'zgartirilmagan` (changelog § 8). Mobile DTO'lar
(`VisitFinishEnvelope`, `VisitsPermissions`, `VisitsCatalog`,
`EntityImageRef`) o'zgartirilmagan asosli kontrakt'da ishlaydi. Phase 2
da yozilgan contract regression test
(`backend_contract_regression_test.dart`, 8 scenariy) hali ham yashil.

---

## Test natijasi

```bash
flutter analyze lib/src/features/visits/ test/features/visits/
  → No issues found

flutter test test/features/visits/
  → 64/64 All tests passed
```

Yangi qo'shilgan testlar: outbox 200 idempotent replay, parallel cycle
race.

---

## Yangi/o'zgartirilgan fayllar (12 ta)

| Fayl | Hajm |
|---|---|
| `lib/src/features/visits/domain/entities/entity_image_ref.dart` | yangi (~60 satr) |
| `lib/src/features/visits/domain/failure_messages.dart` | yangi (~70 satr) |
| `lib/src/features/visits/domain/repositories/photo_repository.dart` | +`noFailedFor` |
| `lib/src/features/visits/data/local/photo_uploads_data_source.dart` | +`noFailedFor` SQL |
| `lib/src/features/visits/data/repositories/photo_repository_impl.dart` | +`noFailedFor` proxy |
| `lib/src/features/visits/data/repositories/permissions_repository_impl.dart` | 304 fast-path |
| `lib/src/features/visits/data/repositories/catalog_repository_impl.dart` | 304 fast-path |
| `lib/src/features/visits/data/rest/visit_api.dart` | `NotModifiedException` public + `fetchVisitStatus` |
| `lib/src/features/visits/infra/sync/outbox_dispatcher.dart` | `Idempotent-Replay` header |
| `lib/src/features/visits/infra/sync/outbox_dispatch_result.dart` | `DispatchSuccess.idempotentReplay` |
| `lib/src/features/visits/infra/sync/visit_status_poller.dart` | yangi (~110 satr) |
| `lib/src/features/visits/infra/telemetry/visits_crashlytics_reporter.dart` | replay breadcrumb |
| `lib/src/features/visits/presentation/widgets/retention_aware_photo.dart` | yangi (~100 satr) |
| `lib/src/features/visits/presentation/bloc/visit_session/visit_session_bloc.dart` | `noFailedFor` gate |
| `lib/src/features/visits/visits_module.dart` | `VisitStatusPoller` DI |
| `lib/src/features/agent/presentation/pages/trading_points_page.dart` | pre-visit permissions refresh |
| `test/features/visits/infra/outbox_dispatcher_test.dart` | +2 scenariy |
| `test/features/visits/presentation/visit_session_bloc_test.dart` | `_NoopPhotos.noFailedFor` |

---

## Rollout R1 boshlash hozir mumkin

Backend `feature_flags.visits_rest_v2_enabled` ni biron-bir test
organizatsiyasi uchun `true` qilsa, mobile darhol REST v2 yo'lga
o'tadi. Health check protokoli: `SelUp_Backend/docs/runbooks/visits-v2/HEALTH_CHECK.md`.

**Reference**:
- Backend changelog: `SelUp_Backend/docs/integration-prompts/visits-v2-mobile-changes.md`
- Mobile passport: `docs/visits-v2-mobile-passport.md`
- Backend passport: `SelUp_Backend/docs/integration-prompts/visits-v2-backend-passport.md`
- Plan: `~/.claude/plans/loyihani-chuqur-professional-tahlil-eager-volcano.md`
