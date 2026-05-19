# Visits v2 — Mobile Muhandis uchun Promt

> **Bu hujjat — executable promt.** Mobile muhandisi (yoki AI agent) bu hujjatni o'qib `clone-gg-app` Flutter ilovasini REST v2 ga refaktor qiladi. Hech qanday qaror sizdan kutilmaydi — barcha kontrakt, schema, qoidalar pasportda aniq belgilangan.

> **Standartlar pasporti**: `docs/visits-v2-mobile-passport.md` — har biri **majburiy**.

> **Backend juftligi**: `SelUp_Backend/docs/integration-prompts/visits-v2-backend.md` (backend promt).

> **Plan reference**: `/Users/kamoliddin/.claude/plans/loyihani-chuqur-professional-tahlil-eager-volcano.md`

---

## Vazifa

`clone-gg-app` (Flutter sales rep ilovasi) ichida yangi `lib/src/features/visits/` modulini qurish va mavjud SOAP-asoslangan visit pipeline ni REST v2 (SelUp_Backend `/api/mobile/v2/visits/`) ga ko'chirish. Eski kod **feature flag** orqali parallel saqlanadi va asta-sekin deprecate qilinadi. Mobile **bitta atomik visit envelope** ni `POST /finish/` orqali yuboradi, photo'lar alohida idempotent endpoint orqali yuklanadi.

**Asosiy konstrukt sifatlari**:
- **Atomik finish** — bitta JSON envelope ichida visit + barcha tasks + photo references.
- **Idempotent** — har envelope `idempotency_key=UUIDv7` bir marta yaratiladi, retry'da o'zgarmaydi.
- **Offline-first** — outbox jadval, exponential backoff, connectivity-triggered dispatcher.
- **Crash-safe** — app kill/restart-da `visits_v2.status='in_progress'` rekordlar tiklanadi.
- **Extensible (Lego)** — `TaskRendererRegistry` orqali yangi task UI qo'shilishi mavjud kodga to'qinmaydi.
- **Secure** — mock location, clock drift, GPS accuracy gate.

---

## Kontekst (qisqacha)

### Hozirgi kamchiliklar (siz ulardan voz kechishingiz shart)

1. `lib/src/features/agent/services/visit_finish_service.dart` (689 satr) — **faqat `_processCreateOrderStep`** real SOAP `setOrder` chaqiradi. Boshqa 4 step processor (`_processPhotoFacingBeforeStep`, `_processShelfAuditStep`, `_processCompetitorAuditStep`, `_processPhotoFacingAfterStep`) — `// TODO: Implement actual server call` placeholderlari + `Future.delayed(500ms)`. **Photo, audit ma'lumotlari haqiqatan ham serverga yuborilmaydi.**
2. `_processVisitDataStep` da `visitStartTime = DateTime.now().subtract(Duration(hours:1))` — hardcoded.
3. `_cancelProcessedSteps` ham TODO — rollback amalda yo'q.
4. Task identifikatsiyasi ruscha matn (`'фото до (facing correction)'.toLowerCase()`) — **TaskCode enum**ga ko'chiriladi.
5. visitId formati `visit_{user}_{client}_{YYYY-MM-DD}` — **UUIDv7**ga.
6. Idempotency, exponential backoff, atomarlik yo'q — qo'shiladi.
7. Outbox ~60% (`is_synced/synced_at/sync_error` bor, engine yo'q) — **OutboxDispatcher** quriladi.
8. `lib/src/features/agent/presentation/pages/visit_steps_page.dart` — **3921 satr** monolithic — `VisitSessionBloc` + `TaskRunnerBloc` + thin UI ga ajratiladi (har biri < 500 satr).
9. Mock location, GPS accuracy gate, jailbreak detection yo'q — qo'shiladi.
10. Strict sequence UX faqat disabled button — `LockedTaskCard` + tooltip + tap'da sabab.

### Backend kontrakti (mavjud)

- `POST /api/mobile/v2/visits/finish/` — atomik envelope (idempotent).
- `POST /api/mobile/v2/visits/{id}/photos/` — multipart, idempotent.
- `POST /api/mobile/v2/visits/{id}/cancel/`.
- `GET /api/mobile/v2/visits/server-time/` — `X-Server-Time` header.
- `GET /api/mobile/v2/visits/permissions/` — ETag, flags + thresholds + enabled_tasks.
- `GET /api/mobile/v2/visits/catalog/` — task type katalogi (JSON Schema).
- `GET /api/mobile/v2/visits/`, `GET /{id}/` — read.

JWT auth (Bearer), `X-Project-Id` header (agar `customer_scope='project'`).

---

## Hard Rules (Passport § 2-3, 16)

1. **Folder structure** — `lib/src/features/visits/{domain,data,presentation,infra}`. `domain/` pure Dart.
2. **State management** — BLoC + Cubit. Provider mixing taqiqlangan.
3. **Bloc file** — < 500 satr. Page file — < 500 satr.
4. **Task identifikatsiya** — faqat `TaskCode` enum. Ruscha matn taqqoslash YO'Q.
5. **visitId** — `Uuid().v7()`. Sana-asoslangan format YO'Q.
6. **Time tracking** — `Stopwatch` (ms aniqligida). `started_at`/`ended_at` ISO timestamp.
7. **Idempotency key** — har outbox entry uchun bir marta yaratiladi, retry'da o'zgarmaydi.
8. **Photo upload** — avval (Visit finish'dan oldin). Finish envelope ichida faqat `remote_asset_id`.
9. **Feature flag** — `PermissionsRepository.cached.flags.visitSubmissionPath` (`soap` | `restV2`). Default safe = `soap`.
10. **No placeholders** — `Future.delayed(Duration(milliseconds: 500))` simulyatsiya YO'Q. Real REST endpoint.
11. **L10n** — `.arb` fayllar (uz/ru/en). Server `name_i18n` primary, lokal fallback.
12. **DI** — `get_it`. Yangi servicelar `service_locator.dart` da registratsiya.

---

## Deliverable papka tarkibi

Pasport § 2 da to'liq strukturasi mavjud. Asosiy fayllar:

```
lib/src/features/visits/
├── domain/                          # Pure Dart, no Flutter
│   ├── entities/                    # VisitSession, Task (sealed), TaskCode, VisitEnvelope, Permissions, ...
│   ├── failures.dart                # sealed Failure + subclasses
│   └── repositories/                # Abstract interfaces
├── data/
│   ├── rest/                        # Dio + 5 interceptor + DTOs + visit_api.dart
│   ├── local/                       # sqflite data sources + v6→v7 migration
│   └── repositories/                # Concrete impls
├── presentation/
│   ├── bloc/                        # VisitListBloc, VisitSessionBloc, TaskRunnerBloc, OutboxStatusCubit
│   ├── pages/                       # visit_session_page.dart + task_pages/ + dead_letter_page.dart
│   ├── widgets/                     # LockedTaskCard, PhotoCaptureWidget, generic_schema_form/
│   └── task_renderer_registry.dart
└── infra/
    ├── sync/                        # OutboxDispatcher, BackoffScheduler, ConnectivityListener, background_sync
    ├── time/server_time_service.dart
    ├── location/secure_location_service.dart
    ├── security/jailbreak_detector.dart
    └── feature_flags.dart
```

---

## Implementatsiya bosqichlari

### Bosqich 1 — Skelet + DI + DB migration

1. `lib/src/features/visits/` papkasi yaratiladi (Passport § 2 strukturasi).
2. `pubspec.yaml` ga (zarurat bo'lsa) yangi paket: yo'q — barchasi mavjud.
3. **DB migration v6 → v7** (Passport § 6):
   - `lib/src/features/visits/data/local/migrations/v6_to_v7.dart` — 6 ta yangi jadval.
   - `lib/src/core/database/database_helper.dart` ga `onUpgrade` hook qo'shish (version 7).
   - Eski jadvallar (`visit_steps_data`, `create_order`, `create_order_products`) saqlanadi.
4. **DI** `service_locator.dart` ga:
   - `RestV2Client` (singleton)
   - `OutboxRepository`, `PhotoRepository`, `VisitRepository`, `PermissionsRepository`, `CatalogRepository`
   - `OutboxDispatcher`, `ConnectivityListener`, `BackoffScheduler`
   - `ServerTimeService`, `SecureLocationService`, `JailbreakDetector`
5. **Tests**: `test/features/visits/data/local/v6_to_v7_migration_test.dart` — sqflite_common_ffi bilan.

**Deliverable**: `flutter test test/features/visits/data/local/` 0 xato.

### Bosqich 2 — Domain entities + Failures

1. `domain/entities/task_code.dart`:
   ```dart
   enum TaskCode {
     photoBefore('PHOTO_BEFORE'),
     photoAfter('PHOTO_AFTER'),
     auditOwn('AUDIT_OWN'),
     auditCompetitor('AUDIT_COMPETITOR'),
     orderCreate('ORDER_CREATE'),
     // Future: customerSurvey, deviceInventory, pricetagCheck, ...
     final String code;
     const TaskCode(this.code);
     static TaskCode? fromCode(String code) => values.firstWhereOrNull((e) => e.code == code);
   }
   ```
2. `domain/entities/task.dart` — sealed class:
   ```dart
   sealed class Task extends Equatable {
     final String taskId;
     final TaskCode taskCode;
     final int displayOrder;
     final bool required;
     ...
   }
   class PhotoTask extends Task { final int minCount, maxCount; final List<String> photoAssetIds; ... }
   class AuditTask extends Task { final List<AuditItem> items; ... }
   class OrderTask extends Task { final List<OrderLine> products; ... }
   class GenericTask extends Task { final Map<String, dynamic> payloadSchema; final Map<String, dynamic> payload; ... }
   ```
3. `domain/entities/visit_session.dart`, `visit_envelope.dart`, `permissions.dart`, `catalog_task.dart`, `geofence_rule.dart`, `sequence_policy.dart`.
4. `domain/failures.dart` (Passport § 4.5):
   ```dart
   sealed class Failure extends Equatable { final String message; ... }
   class GeofenceFailure extends Failure { ... }
   class ClockDriftFailure extends Failure { ... }
   class PhotoMissingFailure extends Failure { ... }
   class IdempotencyMismatchFailure extends Failure { ... }
   class NetworkFailure extends Failure { ... }
   class AuthFailure extends Failure { ... }
   class ValidationFailure extends Failure { ... }
   class UnknownFailure extends Failure { ... }
   ```
5. Abstract repositories `domain/repositories/`.
6. **Tests**: `test/features/visits/domain/` — entity equality, sequence policy, geofence rule.

### Bosqich 3 — Data layer (REST + local + repositories)

1. `data/rest/rest_v2_client.dart`:
   ```dart
   class RestV2Client {
     final Dio dio;
     RestV2Client._({required this.dio});
     factory RestV2Client.create({required String baseUrl, required AuthService auth, ...}) {
       final dio = Dio(BaseOptions(
         baseUrl: baseUrl,
         connectTimeout: Duration(seconds: 30),
         receiveTimeout: Duration(seconds: 30),
         headers: {'Accept': 'application/vnd.gloria.v2+json'},
       ));
       dio.interceptors.addAll([
         AuthInterceptor(auth),
         ProjectHeaderInterceptor(),
         IdempotencyInterceptor(),  // log only (header value comes from body)
         ServerTimeInterceptor(serverTimeService),
         ErrorMapperInterceptor(),
       ]);
       return RestV2Client._(dio: dio);
     }
   }
   ```
2. 5 interceptor (Passport § 4.2):
   - `AuthInterceptor` — Bearer token, 401 → refresh + retry once.
   - `ProjectHeaderInterceptor` — `X-Project-Id` agar `customer_scope='project'`.
   - `IdempotencyInterceptor` — logging.
   - `ServerTimeInterceptor` — `X-Server-Time` headerni `ServerTimeService.deltaMs` ga yozadi.
   - `ErrorMapperInterceptor` — HTTP status + error code → Domain `Failure`.
3. DTOs `data/rest/dto/` — JSON serialization (manual yoki `json_serializable`).
4. `data/rest/visit_api.dart` — yuqori darajali wrapper:
   ```dart
   class VisitApi {
     Future<VisitReadDto> finish(VisitFinishEnvelopeDto envelope) async { ... }
     Future<PhotoUploadResponseDto> uploadPhoto(String visitId, File file, PhotoMeta meta) async { ... }
     Future<PermissionsDto> fetchPermissions({String? etag}) async { ... }
     Future<CatalogDto> fetchCatalog({String? etag}) async { ... }
     Future<CursorPage<VisitReadDto>> listVisits({...}) async { ... }
     Future<void> serverTimeSync() async { ... }
   }
   ```
5. `data/local/` — sqflite data sources (Passport § 6 schema).
6. `data/repositories/` — concrete impls (interface'lar `domain/repositories/`).
7. **Tests**: `test/features/visits/data/rest/` (mock Dio), `test/features/visits/data/local/` (sqflite_common_ffi).

### Bosqich 4 — Infra (sync, time, location, security)

1. `infra/sync/outbox_dispatcher.dart` (Passport § 7.1 algoritm).
2. `infra/sync/backoff_scheduler.dart` (Passport § 7.2).
3. `infra/sync/connectivity_listener.dart` — `connectivity_plus` wrapper, `Stream<bool> get isOnline`.
4. `infra/sync/background_sync.dart` — `Workmanager` (Android) + `BGTaskScheduler` (iOS) setup.
5. `infra/time/server_time_service.dart` (Passport § 10.2).
6. `infra/location/secure_location_service.dart` (Passport § 10.1).
7. `infra/location/haversine.dart` — `haversineM(lat1, lng1, lat2, lng2)`.
8. `infra/security/jailbreak_detector.dart` — `flutter_jailbreak_detection` (yangi paket bo'lsa qo'shing).
9. `infra/feature_flags.dart`.
10. **Tests**:
    - `outbox_dispatcher_test.dart` — happy, offline, backoff, dead-letter, 401 refresh.
    - `backoff_scheduler_test.dart`.
    - `server_time_service_test.dart`.
    - `secure_location_service_test.dart`.

### Bosqich 5 — Presentation: BLoC

1. `presentation/bloc/visit_session/visit_session_bloc.dart`:
   - Events: `LoadVisitSession(visitId | newSession(customer))`, `StartTask(taskId)`, `CompleteTask(taskId, payload)`, `SkipTask(taskId, reason)`, `FinishVisit`, `CancelVisit(reason)`.
   - States (Passport § 3.2).
   - Lifecycle:
     1. `LoadVisitSession` → lokal `visits_v2` dan o'qish (resume) yoki yangi yaratish.
     2. Geofence + clock drift validate → agar fail bo'lsa `VisitSessionError(GeofenceFailure)`.
     3. State: `VisitSessionActive(session, currentTaskIndex)`.
     4. `CompleteTask` → `visit_tasks_v2.payload_json` update + `Stopwatch.stop()` → `task_durations[taskId]`.
     5. `FinishVisit` → `VisitEnvelopeBuilder.build()` → `OutboxRepository.enqueue()` → `OutboxDispatcher.cycle()` → `VisitSessionCompleted`.
2. `task_runner_bloc.dart` — per-task UI state (loading, editing, completed).
3. `outbox_status_cubit.dart` — pending/dead-letter count uchun (Settings ekranida badge).
4. `visit_list_bloc.dart` — visit history.
5. **Tests**: `test/features/visits/presentation/bloc/` — Bloc test (initial → events → expected states).

### Bosqich 6 — Presentation: Pages + Widgets

1. `presentation/pages/visit_session_page.dart` — < 500 satr:
   - AppBar (visit info + timer)
   - PageView yoki Stepper (tasks)
   - Bottom: progress bar + Finish button (disabled until required tasks completed)
   - State'ga reaksiya (loading, error, active, completed)
2. `task_pages/`:
   - `photo_before_page.dart`, `photo_after_page.dart` — `PhotoCaptureWidget` (max N).
   - `audit_own_page.dart`, `audit_competitor_page.dart` — product list + quantity input.
   - `order_create_page.dart` — mavjud `CreateOrderPage` refaktor.
   - `generic_form_page.dart` — JSON Schema asosida dinamik form (Passport § 9.3).
   - `_registry.dart` — `registerBuiltInTaskRenderers()`.
3. `widgets/`:
   - `locked_task_card.dart` — strict sequence UX (lock ikon + tooltip + tap → SnackBar).
   - `outbox_status_badge.dart`.
   - `task_progress_bar.dart`.
   - `photo_capture_widget.dart`.
   - `generic_schema_form/` — JSON Schema → Widget tree (10 field renderer).
4. `presentation/pages/dead_letter_page.dart` — Settings ekrandagi "Yuborilmagan tashriflar".
5. `task_renderer_registry.dart` (Passport § 9).
6. `main.dart` da `registerBuiltInTaskRenderers()` chaqirish.
7. **Tests**: widget tests (`LockedTaskCard`, `OutboxStatusBadge`, `GenericFormRenderer` per field).

### Bosqich 7 — Feature flag + VisitFinishOrchestrator

1. `infra/feature_flags.dart`:
   ```dart
   enum VisitSubmissionPath { soap, restV2 }
   class FeatureFlags {
     static VisitSubmissionPath get visitSubmission {
       return PermissionsRepository.cached?.flags.visitSubmissionPath ?? VisitSubmissionPath.soap;
     }
   }
   ```
2. `VisitFinishOrchestrator` (Passport § 11.2):
   - `soap` → mavjud `VisitFinishService.finishVisit()` (eski kod o'zgarmaydi).
   - `restV2` → `VisitEnvelopeBuilder.build()` → `OutboxRepository.enqueue()` → `dispatcher.cycle()`.
3. `VisitEnvelopeBuilder.build(session)` — `domain/entities/visit_envelope.dart` ni hosil qiladi (Passport § 5.1 format).
4. **Tests**: `feature_flags_test.dart` — har ikkala path mock'lar bilan.

### Bosqich 8 — Photo pipeline

1. `data/repositories/photo_repository_impl.dart` (Passport § 8):
   - `capture(image: File, meta)` → compress → SHA-256 → `photo_uploads` insert (status=`pending`).
   - `uploadAll()` → har `pending` foto: REST POST → `remote_asset_id` → status=`confirmed`.
2. `PhotoUploadService` background — har 30s yoki connectivity-trigger.
3. Visit finish'dan oldin: agar `photo_uploads.status IN (pending, uploading, failed)` bor bo'lsa, user'ga "Foto yuborilmagan, kuting" dialog (Passport § 8.3).
4. **Tests**: photo pipeline e2e mock.

### Bosqich 9 — Eski kod migration

1. `visit_steps_page.dart` (3921 satr) — **eski hodisaqilmaydi**. Lekin yangi `visit_session_page.dart` parallel quriladi. Navigation feature flag bilan:
   ```dart
   if (FeatureFlags.visitSubmission == VisitSubmissionPath.restV2) {
     Navigator.push(MaterialPageRoute(builder: (_) => VisitSessionPage(...)));
   } else {
     Navigator.push(MaterialPageRoute(builder: (_) => VisitStepsPage(...)));  // eski
   }
   ```
2. `visit_finish_service.dart` (689 satr placeholder'lar) — **eski qoldiriladi** (SOAP path). Phase 5 oxirida `// DEPRECATED — to be removed in v3.0` comment.
3. `visit_step_sync_service.dart` — yangi `OutboxDispatcher` mavjudligida, faqat SOAP yo'l ishlatadi (refactor minimal).
4. `soap_api_service.dart` — o'zgarmaydi.

### Bosqich 10 — Server time, geofence, mock detection integration

1. App start (`main.dart`):
   ```dart
   await ServerTimeService.sync();  // X-Server-Time fetch
   ```
2. Visit start oldin (`VisitSessionBloc._onLoadVisitSession`):
   - `ServerTimeService.isDriftAcceptable(maxDriftS: permissions.thresholds.clockDriftMaxS)` → false bo'lsa `ClockDriftFailure`.
   - `SecureLocationService.getCurrentPosition()` → `isValidForVisit(loc, radius)` → false bo'lsa `GeofenceFailure`.
   - `JailbreakDetector.isCompromised()` → release rejimda `SecurityFailure` (opsiyaviy).
3. UI'da dialog: "Telefon vaqti to'g'ri emas. Sozlamalardan vaqtni avtomatik qiling." / "GPS aniq emas, ochiq joyga chiqing." / "Mock location aniqlandi."

### Bosqich 11 — Telemetry

1. `lib/src/core/services/telemetry_v2/` mavjud — kengaytirish (Passport § 13).
2. `VisitSessionBloc` har event'da telemetry emit.
3. `OutboxDispatcher` success/failure event'lar.
4. Dashboard'da kuzatish (Firebase Analytics yoki Sentry breadcrumbs).

### Bosqich 12 — Tests + CI

1. Unit tests (Passport § 14):
   - `outbox_dispatcher_test.dart` (8 scenario)
   - `visit_envelope_builder_test.dart` (schema match)
   - `sequence_policy_test.dart` (strict, free)
   - `geofence_rule_test.dart`
   - `server_time_service_test.dart`
2. Widget tests:
   - `locked_task_card_test.dart`
   - `outbox_status_badge_test.dart`
   - `generic_schema_form/*_test.dart` (10 field renderer)
3. Integration tests (`integration_test/visits/`):
   - `full_lifecycle_test.dart` — mock REST server, visit start → all tasks → finish → outbox ack.
   - `offline_to_online_test.dart` — network off → finish → outbox pending → network on → ack.
   - `crash_recovery_test.dart` — app restart simulation, in_progress visit restore.
   - `feature_flag_test.dart` — soap vs restV2 routing.
4. CI (`.github/workflows/flutter.yml`):
   - `flutter analyze` 0 issue
   - `flutter test --coverage` ≥ 80%
   - `flutter test integration_test/`
   - `flutter build apk --debug` pass

---

## Acceptance Criteria

### Texnik

- ✅ `flutter analyze` 0 issue
- ✅ `flutter test --coverage` ≥ 80% line coverage (`lib/src/features/visits/`)
- ✅ Critical paths (OutboxDispatcher, VisitEnvelopeBuilder, SequencePolicy) — 100%
- ✅ DB v6 → v7 migration ishlaydi (existing data preserved)
- ✅ `visit_session_page.dart` < 500 satr
- ✅ `visit_session_bloc.dart` < 500 satr
- ✅ `visit_finish_service.dart` da bironta `// TODO: Implement actual server call` qolmasligi (rest_v2 yo'l)

### Funksional (e2e mock REST)

- ✅ Visit start → all 5 tasks → finish (REST v2) → 201 + outbox ack
- ✅ Offline visit: outbox pending → online → avto-yuborish → ack
- ✅ App crash mid-visit → restart → "Davom etish?" dialog → state restore
- ✅ Photo upload retry: network fail → next cycle → success
- ✅ Same idempotency_key replay → 200 + bitta Visit
- ✅ Different payload same key → 409 → dead-letter UI
- ✅ Mock location release rejimda → visit start blocked + `MockLocationFailure` dialog
- ✅ Clock drift > 5 min → visit start blocked + dialog
- ✅ GPS accuracy > radius/3 → visit start blocked + dialog
- ✅ Strict sequence: 2-task locked → tap → SnackBar sabab matni
- ✅ Feature flag `soap` → eski yo'l, `restV2` → yangi outbox yo'l
- ✅ Task identifikatsiya — faqat `TaskCode` enum (ruscha matn YO'Q)
- ✅ visitId UUIDv7 format

### Outbox engine

- ✅ Connectivity change (offline → online) → 5s ichida dispatcher cycle
- ✅ 401 → token refresh → retry without attempt++
- ✅ 409 → mark ack (server allaqachon qabul qilgan)
- ✅ 5xx/timeout → exponential backoff (2s, 4s, 8s, 16s, 32s, 64s, 128s, 300s×3)
- ✅ 10 attempts → dead_letter
- ✅ 400/422 → dead_letter darhol
- ✅ Dead-letter UI: list, manual retry, delete

### Extensibility verification

- ✅ `TaskRendererRegistry.register('NEW_TASK', () => CustomPage(...))` — visit pipeline o'zgartirilmasdan ishlaydi.
- ✅ Server `/catalog/` yangi `CUSTOMER_SURVEY` task qaytarsa, `GenericFormRenderer` JSON Schema asosida UI tug'diradi (custom widget yozmasdan).
- ✅ Test: `task_renderer_registry_test.dart` — registry fallback, custom widget resolve.

---

## Anti-patternlar (qilmang!)

❌ `step.stepName == 'фото до (facing correction)'` — `TaskCode` enum.
❌ `Future.delayed(Duration(ms: 500))` placeholder — real REST endpoint.
❌ View ichida `Dio.post(...)` to'g'ridan-to'g'ri — repository orqali.
❌ visitId formati `visit_{user}_{client}_{date}` — `Uuid().v7()`.
❌ Photo upload visit finish bilan birga (1 ta multipart) — alohida endpoint avval.
❌ `setState(() {...})` Bloc state o'rniga — har doim `emit(...)`.
❌ Hard delete photo files — `status='confirmed'` bo'lganidan keyin server ack bilan.
❌ Big monolithic page — < 500 satr.
❌ `print(...)` — `developer.log()` yoki telemetry.
❌ Idempotency key har retry'da yangi UUID — bir marta yaratiladi va saqlanadi.

✅ Qiling:
- UUIDv7 (vaqt monotonik, debug oson)
- `Stopwatch` ms aniqligida (ISO `started_at`/`ended_at` envelope'ga)
- Atomik DB transactionlar — `db.transaction((txn) async { ... })`
- Bloc emit qoidalari (immutable state, no async gap)
- Feature flag bilan SOAP/REST toggle (production safe)

---

## Reference materiallar (avval o'qing!)

### Eski kod (deprecate qilinadi — REFERENCE faqat)

| Fayl | Nima uchun |
|---|---|
| `lib/src/features/agent/services/visit_finish_service.dart` | 689 satr, 4 placeholder — REFACTOR target |
| `lib/src/features/agent/presentation/pages/visit_steps_page.dart` | 3921 satr monolithic — AJRATISH target |
| `lib/src/core/services/visit_step_sync_service.dart` | yarim sync — REPLACE with OutboxDispatcher |
| `lib/src/features/agent/data/models/sales_req_permissions.dart` | Eski permissions — yangi `Permissions` modeliga adapter |
| `lib/src/core/services/soap_api_service.dart` | SAQLANADI feature flag bypass |
| `lib/src/features/agent/services/photo_storage_service.dart` | Eski photo — yangi `PhotoUploadService` reference |
| `lib/src/core/database/database_helper.dart` | sqflite onUpgrade hook (v6→v7) |

### Yangi/qayta ishlatiladigan templates

| Fayl | Nima uchun |
|---|---|
| `lib/src/core/services/service_locator.dart` | DI registratsiya |
| `lib/src/core/services/telemetry_v2/` | Analytics events |
| `lib/src/core/services/local_uuid_service.dart` | Device UUID (persistent) |
| `lib/src/core/services/connectivity_monitor_service.dart` | Connectivity wrapper |

### Hujjatlar

- `docs/visits-v2-mobile-passport.md` — bu promtning juftligi (standartlar)
- `docs/visits-v2-mobile.md` — bu hujjat
- Backend passport: `SelUp_Backend/docs/integration-prompts/visits-v2-backend-passport.md`
- Backend promt: `SelUp_Backend/docs/integration-prompts/visits-v2-backend.md`
- Plan: `/Users/kamoliddin/.claude/plans/loyihani-chuqur-professional-tahlil-eager-volcano.md`
- Mavjud paired docs (style reference):
  - `docs/customer-balance-mobile.md` (mobile promt template)
  - `docs/customer-balance-passport.md` (passport template)

---

## Tartib va PR strategiyasi

Bitta katta PR emas — bo'limma-bo'lim PR'lar:

| PR | Bosqich | Reviewer e'tibori |
|---|---|---|
| PR 1 | Skelet + DB migration v6→v7 + DI | Migration safety, rollback |
| PR 2 | Domain entities + Failures | Sealed classes, immutability |
| PR 3 | Data layer (REST client + interceptors + DTOs) | Auth refresh, error mapping |
| PR 4 | Local data sources + repositories | sqflite CRUD, FK cascade |
| PR 5 | Infra (sync, time, location, security) | OutboxDispatcher algoritm |
| PR 6 | BLoC + Cubit | State sealed class, no async gap |
| PR 7 | Pages + Widgets + TaskRendererRegistry | < 500 satr/page, LockedTaskCard UX |
| PR 8 | Photo pipeline | Idempotency, compress, SHA-256 |
| PR 9 | Feature flag + VisitFinishOrchestrator | SOAP/REST toggle parallel |
| PR 10 | Integration tests + telemetry + CI | Mock REST server, offline scenario |

Har PR — to'liq tests + lint pass + format clean.

---

## Yakuniy savol-javob

- **Visit start backend'ga yuboriladimi?** Yo'q. User qarori: visit faqat finish'da serverga keladi. Photo upload paytida server stub Visit yaratadi.
- **Lokal in-flight visit qayerda saqlanadi?** `visits_v2.status='in_progress'`. Crash bo'lsa restart'da tiklanadi.
- **Feature flag qayerda?** Backend `/permissions/` response'da `flags.visit_submission_path`. Mobile cache (1 soat TTL).
- **Eski SOAP code o'chiriladimi?** Yo'q (Phase 4 oxirigacha). Faqat feature flag orqali bypass. Phase 5'da `// DEPRECATED` comment, Phase 6'da hard remove.
- **Photo va task envelope birgalikda yuboriladimi?** Yo'q. Photo avval (alohida endpoint), envelope finish'da faqat `remote_asset_id` ro'yxatini ko'taradi.
- **Mock location debug rejimda nima qiladi?** `kDebugMode` bo'lsa warning only, release rejimda block.
- **Idempotency key qayerda yaratiladi?** `OutboxRepository.enqueue()` ichida bir marta. Retry'da o'zgarmaydi.
- **UUIDv7 ni qanday generatsiya?** `uuid` package `Uuid().v7()` API (v4.x).
- **Strict sequence backend'da ham tekshiriladimi?** Yo'q (hozircha). Faqat mobile UI cheklov. Backend `display_order` qaytaradi, visualizatsiya mobile.
- **Yangi task uchun mobile build kerakmi?** Faqat custom widget kerak bo'lsa (DEVICE_INVENTORY kabi). Oddiy so'rovnoma (CUSTOMER_SURVEY) — server schema yetarli, mobile `GenericFormRenderer` avtomatik ishlatadi.

Hammasi aniq. Boshlaymiz.
