# Visits v2 — Mobile Standartlar Pasporti

> **Maqsad**: `clone-gg-app` (Flutter) ichida `lib/src/features/visits/` modul uchun yagona standart, qoidalar va kontrakt. Bu hujjat **qanday** qilish kerakligini aytadi (promt `visits-v2-mobile.md` **nima** qilish kerakligini aytadi).

> **Versiya**: 1.0 — 2026-05-16. Plan reference: `/Users/kamoliddin/.claude/plans/loyihani-chuqur-professional-tahlil-eager-volcano.md`.

> **Backend juftligi**: `SelUp_Backend/docs/integration-prompts/visits-v2-backend-passport.md`.

---

## 1. Texnologiya stack

| Komponent | Versiya | Maqsad |
|---|---|---|
| Flutter | 3.x (SDK ^3.8.1) | Asosiy framework |
| Dart | 3.x | Til |
| flutter_bloc | ^9.1.1 | State management (Cubit + Bloc) |
| equatable | ^2.0.5 | Value equality |
| dio | ^5.4.0 | HTTP client (REST v2) |
| sqflite | ^2.3.2 | Local DB (offline buffer) |
| path_provider | ^2.1.2 | File paths |
| connectivity_plus | ^7.0.0 | Network state listener |
| workmanager | ^0.9.0 | Background sync (Android) |
| flutter_secure_storage | ^9.2.4 | JWT saqlash |
| uuid | ^4.5.1 | UUIDv4/v7 generatsiya |
| geolocator | ^14.0.2 | GPS + accuracy + isMockLocation |
| camera | ^0.11.3 | Foto olish |
| image_picker | ^1.2.0 | Galereya |
| flutter_image_compress | ^2.3.0 | Foto compress |
| crypto (built-in) | — | SHA-256 |
| device_info_plus | ^12.3.0 | DeviceId, OS info |
| battery_plus | ^6.0.3 | Battery level |
| package_info_plus | ^8.0.0 | App version |
| get_it | ^8.0.3 | DI |
| rxdart | ^0.28.0 | Streams |
| intl | ^0.20.2 | i18n |

**Yangi paket qo'shilishi mumkin** (faqat zarurat bo'lganda):
- `jsonschema` ekvivalenti — agar generic renderer JSON Schema validation kerak bo'lsa, custom utility yozish (paket qo'shmasdan).
- `flutter_jailbreak_detection` — agar real device security check kerak bo'lsa.

---

## 2. Folder structure (clean architecture)

```
lib/src/features/visits/                # YANGI MODUL
├── domain/                             # PURE Dart, no Flutter import
│   ├── entities/
│   │   ├── visit_session.dart         # VisitSession aggregate
│   │   ├── task.dart                  # sealed class Task + subclasses
│   │   ├── task_code.dart             # enum TaskCode
│   │   ├── visit_envelope.dart        # Immutable DTO
│   │   ├── visit_status.dart          # enum LocalVisitStatus
│   │   ├── geofence_rule.dart
│   │   ├── sequence_policy.dart       # StrictSequencePolicy, FreeSequencePolicy
│   │   ├── catalog_task.dart          # VisitTaskCatalog model
│   │   └── permissions.dart           # PermissionsModel (flags + thresholds + enabled_tasks)
│   ├── failures.dart                  # sealed class Failure + subclasses
│   └── repositories/                  # Abstract interfaces
│       ├── visit_repository.dart
│       ├── permissions_repository.dart
│       ├── catalog_repository.dart
│       ├── outbox_repository.dart
│       └── photo_repository.dart
├── data/
│   ├── rest/
│   │   ├── rest_v2_client.dart        # Dio wrapper
│   │   ├── interceptors/
│   │   │   ├── auth_interceptor.dart
│   │   │   ├── project_header_interceptor.dart
│   │   │   ├── idempotency_interceptor.dart  # logging only
│   │   │   ├── server_time_interceptor.dart  # X-Server-Time → ServerTimeService
│   │   │   └── error_mapper_interceptor.dart # HTTP → Failure
│   │   ├── dto/
│   │   │   ├── visit_finish_envelope_dto.dart
│   │   │   ├── visit_read_dto.dart
│   │   │   ├── photo_upload_response_dto.dart
│   │   │   ├── permissions_dto.dart
│   │   │   └── catalog_dto.dart
│   │   └── visit_api.dart             # High-level wrapper (finish, photos, list, ...)
│   ├── local/
│   │   ├── visit_local_data_source.dart  # sqflite CRUD: visits_v2, visit_tasks_v2
│   │   ├── outbox_data_source.dart       # sqflite CRUD: outbox
│   │   ├── photo_uploads_data_source.dart
│   │   └── migrations/
│   │       ├── v6_to_v7.dart          # Add outbox, photo_uploads, visits_v2, visit_tasks_v2
│   │       └── v7_to_v6.dart          # Rollback (Phase 4 only)
│   └── repositories/                  # Concrete impls of domain interfaces
│       ├── visit_repository_impl.dart
│       ├── permissions_repository_impl.dart
│       ├── catalog_repository_impl.dart
│       ├── outbox_repository_impl.dart
│       └── photo_repository_impl.dart
├── presentation/
│   ├── bloc/
│   │   ├── visit_list/
│   │   │   ├── visit_list_bloc.dart
│   │   │   ├── visit_list_event.dart
│   │   │   └── visit_list_state.dart
│   │   ├── visit_session/             # << CORE (visit lifecycle)
│   │   │   ├── visit_session_bloc.dart  # < 500 satr
│   │   │   ├── visit_session_event.dart
│   │   │   └── visit_session_state.dart
│   │   ├── task_runner/
│   │   │   ├── task_runner_bloc.dart
│   │   │   ├── task_runner_event.dart
│   │   │   └── task_runner_state.dart
│   │   └── outbox_status/
│   │       ├── outbox_status_cubit.dart
│   │       └── outbox_status_state.dart
│   ├── pages/
│   │   ├── visit_session_page.dart    # << UI thin (~300-400 satr)
│   │   ├── dead_letter_page.dart
│   │   └── task_pages/
│   │       ├── _registry.dart         # registerCustomTaskRenderers()
│   │       ├── photo_before_page.dart
│   │       ├── photo_after_page.dart
│   │       ├── audit_own_page.dart
│   │       ├── audit_competitor_page.dart
│   │       ├── order_create_page.dart
│   │       └── generic_form_page.dart  # Fallback (JSON Schema renderer)
│   ├── widgets/
│   │   ├── locked_task_card.dart      # Strict sequence UX
│   │   ├── outbox_status_badge.dart   # AppBar / Settings
│   │   ├── task_progress_bar.dart
│   │   ├── photo_capture_widget.dart
│   │   ├── location_picker_widget.dart
│   │   ├── signature_pad_widget.dart
│   │   └── generic_schema_form/       # JSON Schema → Widget tree
│   │       ├── schema_form_renderer.dart
│   │       ├── field_renderers/
│   │       │   ├── string_field.dart
│   │       │   ├── number_field.dart
│   │       │   ├── boolean_field.dart
│   │       │   ├── enum_field.dart
│   │       │   ├── array_field.dart
│   │       │   ├── photo_field.dart
│   │       │   ├── gps_field.dart
│   │       │   ├── date_field.dart
│   │       │   ├── scale_field.dart
│   │       │   ├── barcode_field.dart
│   │       │   └── signature_field.dart
│   │       └── schema_validator.dart  # Local JSON Schema validation
│   └── task_renderer_registry.dart    # TaskRendererRegistry
└── infra/
    ├── sync/
    │   ├── outbox_dispatcher.dart     # Engine
    │   ├── backoff_scheduler.dart     # Exponential + jitter
    │   ├── connectivity_listener.dart # connectivity_plus wrapper
    │   └── background_sync.dart       # Workmanager / BGTaskScheduler
    ├── time/
    │   └── server_time_service.dart   # X-Server-Time delta
    ├── location/
    │   ├── secure_location_service.dart  # accuracy + mock + jailbreak
    │   └── haversine.dart
    ├── security/
    │   └── jailbreak_detector.dart
    └── feature_flags.dart             # Visit submission path toggle
```

**Hard rules**:
- `domain/` faqat pure Dart (Flutter import yo'q).
- `data/` → `domain/` (interfaces) ga bog'liq, hech qachon prezentatsiya'ga.
- `presentation/` → `domain/` (use case) bilan ishlaydi, `data/` to'g'ridan-to'g'ri kirmaydi (DI orqali).
- `infra/` — cross-cutting (sync, time, location) — har qatlamdan foydalaniladi.

---

## 3. State management qoidalari

### 3.1 BLoC + Cubit

- **BLoC** — murakkab state machine (`VisitSessionBloc`, `TaskRunnerBloc`).
- **Cubit** — oddiy state (`OutboxStatusCubit`, `PermissionsCubit`).
- **Provider mixing taqiqlangan** — faqat BLoC ekosistemasi.

### 3.2 State sealed class'lar

```dart
sealed class VisitSessionState extends Equatable {
  const VisitSessionState();
}

class VisitSessionInitial extends VisitSessionState { ... }
class VisitSessionLoading extends VisitSessionState { ... }
class VisitSessionActive extends VisitSessionState {
  final VisitSession session;
  final int currentTaskIndex;
  final Map<int, Duration> taskDurations;
  ...
}
class VisitSessionFinishing extends VisitSessionState { ... }
class VisitSessionCompleted extends VisitSessionState { ... }
class VisitSessionError extends VisitSessionState {
  final Failure failure;
  ...
}
```

### 3.3 Event naming

- `LoadVisitSession`, `StartTask`, `CompleteTask`, `SkipTask`, `FinishVisit`, `CancelVisit`.
- Past tense — past event ("FoundClient"), Imperative — komanda ("LoadClient").

### 3.4 Bloc max satrlar

- BLoC fayl: **< 500 satr**. Agar oshsa — domain'ga handler ajratiladi.
- Page fayl: **< 500 satr**. Murakkab UI → kichik widget'lar.

---

## 4. REST kontrakti

### 4.1 Base URL

`https://api.gloriya.uz/api/mobile/v2/` (config'da). Per-environment:
- dev: `http://localhost:8000/api/mobile/v2/`
- staging: `https://staging-api.gloriya.uz/api/mobile/v2/`
- prod: `https://api.gloriya.uz/api/mobile/v2/`

### 4.2 Headers

| Header | Vaqti | Qiymat |
|---|---|---|
| `Authorization` | Har auth-protected request | `Bearer <accessToken>` |
| `X-Project-Id` | `customer_scope='project'` bo'lsa | Active project UUID |
| `Accept` | Har request | `application/vnd.gloria.v2+json` |
| `Content-Type` | POST/PATCH | `application/json` yoki `multipart/form-data` |
| `Accept-Language` | Har request | `uz,ru;q=0.9,en;q=0.8` |
| `If-None-Match` | GET (caching) | `<etag>` (mobile cache'idan) |

### 4.3 Endpoint ro'yxati (mobile foydalanadi)

| Method | Path | Vazifa |
|---|---|---|
| GET | `/visits/server-time/` | Server time sync (auth-free) |
| GET | `/visits/permissions/` | User flags + thresholds + enabled_tasks (ETag) |
| GET | `/visits/catalog/` | Task type katalogi |
| POST | `/visits/finish/` | Atomik VisitFinishEnvelope |
| POST | `/visits/{id}/photos/` | Foto yuklash (multipart) |
| POST | `/visits/{id}/cancel/` | Visit'ni cancel qilish |
| GET | `/visits/` | Visit tarixi |
| GET | `/visits/{id}/` | Visit detail |

### 4.4 Idempotency

Har mutating endpoint body'da:

```dart
{
  "client_uuid": "<device UUID, persistent>",
  "idempotency_key": "<envelope UUIDv7, per-attempt>",
  ...
}
```

- `client_uuid` — `LocalUuidService` orqali install-time generated, secure storage'da.
- `idempotency_key` — har outbox entry uchun bir marta yaratiladi va retry'da o'zgarmaydi.

### 4.5 Error envelope

```json
{ "error": { "code": "VISITS_GEOFENCE_VIOLATION", "message": "Distance 250m > allowed 100m", "details": {...}, "traceId": "..." } }
```

`ErrorMapperInterceptor` HTTP status + code'ni Domain `Failure` ga aylantiradi:

```dart
sealed class Failure extends Equatable { ... }
class GeofenceFailure extends Failure { ... }
class ClockDriftFailure extends Failure { ... }
class PhotoMissingFailure extends Failure { ... }
class IdempotencyMismatchFailure extends Failure { ... }
class NetworkFailure extends Failure { ... }  // 5xx, timeout, no connection
class AuthFailure extends Failure { ... }     // 401, 403
class ValidationFailure extends Failure { ... }
class UnknownFailure extends Failure { ... }
```

---

## 5. JSON DTO formatlari

### 5.1 VisitFinishEnvelope (POST `/visits/finish/`)

```json
{
  "client_uuid": "uuid-of-device",
  "idempotency_key": "uuid-per-envelope",
  "visit_id": "uuid-v7",
  "customer_id": "uuid",
  "planned_flag": true,
  "started_at": "2026-05-16T08:14:22.103Z",
  "finished_at": "2026-05-16T08:47:55.221Z",
  "total_duration_ms": 2033118,
  "outcome": "completed",
  "start_location": {
    "lat": 41.311081, "lng": 69.279729,
    "accuracy_m": 14.2, "altitude_m": 425.1,
    "source": "gps", "mocked": false,
    "provider_ts": "2026-05-16T08:14:21.500Z"
  },
  "finish_location": { /* same */ },
  "device": {
    "device_id": "uuid", "platform": "android",
    "os_version": "14", "app_version": "2.5.0+318",
    "model": "SM-G990B", "battery_level": 0.83,
    "network_type": "wifi", "is_jailbroken": false,
    "timezone": "Asia/Tashkent", "locale": "uz_UZ"
  },
  "client_clock_drift_ms": 1820,
  "network_flags": {
    "was_offline": true, "offline_duration_ms": 1200000, "outbox_attempts": 1
  },
  "tasks": [
    {
      "task_id": "uuid",
      "task_code": "PHOTO_BEFORE",
      "started_at": "...", "ended_at": "...", "duration_ms": 92000,
      "status": "completed",
      "payload": { "photo_asset_ids": ["uuid", "uuid"] },
      "payload_schema_version": 1
    },
    { "task_code": "AUDIT_OWN", "payload": { "items": [...] } },
    { "task_code": "AUDIT_COMPETITOR", "payload": { "competitors": [...] } },
    { "task_code": "ORDER_CREATE", "payload": { "products": [...], "total_uzs": 300000 } },
    { "task_code": "PHOTO_AFTER", "payload": { "photo_asset_ids": ["uuid"] } }
  ]
}
```

### 5.2 Permissions response

```json
{
  "etag": "W/\"abc123\"",
  "user_code": "U001",
  "project_code": "evyap",
  "flags": {
    "visit": true, "strict_sequence": true, "unplanned_order": false,
    "planned_route": true, "edit_client_coordinates": false,
    "skip_tin_duplicate_check": false, "allow_creation_without_tin": false,
    "visit_submission_path": "rest_v2"
  },
  "thresholds": {
    "client_zone_access_m": 100, "location_update_interval_s": 30,
    "gps_accuracy_max_m": 30, "clock_drift_max_s": 300,
    "max_photos_per_task": 10,
    "min_photos_per_task": { "PHOTO_BEFORE": 1, "PHOTO_AFTER": 1 }
  },
  "enabled_tasks": ["PHOTO_BEFORE", "AUDIT_OWN", "AUDIT_COMPETITOR", "ORDER_CREATE", "PHOTO_AFTER"],
  "task_order": ["PHOTO_BEFORE", "AUDIT_OWN", "AUDIT_COMPETITOR", "ORDER_CREATE", "PHOTO_AFTER"],
  "task_required": { "PHOTO_BEFORE": true, "AUDIT_OWN": true, "ORDER_CREATE": false }
}
```

### 5.3 Catalog response

```json
{
  "tasks": [
    {
      "task_code": "PHOTO_BEFORE",
      "name_i18n": { "uz": "Foto oldidan", "ru": "Фото до", "en": "Photo before" },
      "required": true,
      "display_order": 1,
      "payload_schema_version": 1,
      "payload_schema": { /* JSON Schema draft-07 */ },
      "config": { "min_count": 1, "max_count": 5 },
      "renderer_hint": "custom"  // "custom" → use TaskRendererRegistry; "generic" → GenericFormRenderer
    },
    ...
  ]
}
```

---

## 6. SQLite migration v6 → v7

### 6.1 Yangi jadvallar

```sql
-- Outbox (har envelope)
CREATE TABLE outbox (
  envelope_id TEXT PRIMARY KEY,
  visit_id TEXT,
  endpoint TEXT NOT NULL,                 -- 'POST /api/mobile/v2/visits/finish/'
  http_method TEXT NOT NULL,
  payload_json TEXT NOT NULL,
  idempotency_key TEXT NOT NULL UNIQUE,
  client_uuid TEXT NOT NULL,
  status TEXT NOT NULL,                   -- pending|in_flight|retrying|ack|dead_letter
  attempts INTEGER NOT NULL DEFAULT 0,
  max_attempts INTEGER NOT NULL DEFAULT 10,
  next_attempt_at INTEGER NOT NULL,       -- epoch ms
  last_error TEXT,
  last_http_status INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX idx_outbox_due ON outbox(status, next_attempt_at);
CREATE INDEX idx_outbox_visit ON outbox(visit_id);

-- Photo uploads (har foto)
CREATE TABLE photo_uploads (
  asset_id TEXT PRIMARY KEY,              -- UUIDv7 (mobile generate)
  visit_id TEXT NOT NULL,
  task_id TEXT,                            -- VisitTask id (envelope ichida bog'lanadi)
  task_code TEXT NOT NULL,
  local_path TEXT NOT NULL,
  thumbnail_path TEXT,
  sha256 TEXT NOT NULL,
  size_bytes INTEGER NOT NULL,
  width INTEGER, height INTEGER,
  captured_at INTEGER NOT NULL,
  lat REAL, lng REAL, accuracy_m REAL,
  status TEXT NOT NULL,                   -- pending|uploading|confirmed|failed
  remote_asset_id TEXT,                   -- server qaytargan EntityImage UUID
  attempts INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  idempotency_key TEXT NOT NULL UNIQUE,
  created_at INTEGER NOT NULL
);
CREATE INDEX idx_photos_visit ON photo_uploads(visit_id, status);
CREATE INDEX idx_photos_status ON photo_uploads(status);

-- Visits (lokal cache + offline buffer)
CREATE TABLE visits_v2 (
  visit_id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,
  planned_flag INTEGER NOT NULL,
  status TEXT NOT NULL,                   -- in_progress|finished_local|synced|cancelled|rejected
  started_at INTEGER NOT NULL,
  finished_at INTEGER,
  envelope_id TEXT,                       -- bog'liq outbox
  app_version TEXT,
  start_location_json TEXT,
  finish_location_json TEXT,
  device_info_json TEXT,
  network_flags_json TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX idx_visits_v2_status ON visits_v2(status);
CREATE INDEX idx_visits_v2_customer ON visits_v2(customer_id, started_at DESC);

-- Tasks (per-visit per-task payload)
CREATE TABLE visit_tasks_v2 (
  task_id TEXT PRIMARY KEY,
  visit_id TEXT NOT NULL,
  task_code TEXT NOT NULL,
  display_order INTEGER NOT NULL,
  started_at INTEGER, ended_at INTEGER, duration_ms INTEGER,
  status TEXT NOT NULL,                   -- pending|in_progress|completed|skipped
  payload_json TEXT NOT NULL,
  payload_schema_version INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY(visit_id) REFERENCES visits_v2(visit_id) ON DELETE CASCADE
);
CREATE INDEX idx_visit_tasks_v2_visit ON visit_tasks_v2(visit_id, display_order);

-- Permissions cache (ETag)
CREATE TABLE permissions_cache (
  user_code TEXT NOT NULL,
  project_code TEXT NOT NULL,
  etag TEXT NOT NULL,
  json TEXT NOT NULL,
  fetched_at INTEGER NOT NULL,
  PRIMARY KEY (user_code, project_code)
);

-- Catalog cache (ETag, per-project)
CREATE TABLE catalog_cache (
  project_code TEXT PRIMARY KEY,
  etag TEXT NOT NULL,
  json TEXT NOT NULL,
  fetched_at INTEGER NOT NULL
);
```

### 6.2 Eski jadvallar

`visit_steps_data`, `create_order`, `create_order_products` — **saqlanadi** (Phase 4 oxirigacha) backwards-compat va in-flight visit recovery uchun. Phase 5'da deprecate, Phase 6'da hard remove.

### 6.3 Migration kod skelet

```dart
// lib/src/features/visits/data/local/migrations/v6_to_v7.dart
class V6ToV7Migration {
  static Future<void> apply(Database db) async {
    await db.execute('CREATE TABLE outbox (...);');
    await db.execute('CREATE INDEX idx_outbox_due ...;');
    await db.execute('CREATE TABLE photo_uploads (...);');
    await db.execute('CREATE TABLE visits_v2 (...);');
    await db.execute('CREATE TABLE visit_tasks_v2 (...);');
    await db.execute('CREATE TABLE permissions_cache (...);');
    await db.execute('CREATE TABLE catalog_cache (...);');
    // Eski jadvallar saqlanadi.
  }
}
```

`DatabaseHelper.onUpgrade` ichida `oldVersion=6, newVersion=7` → `V6ToV7Migration.apply(db)`.

### 6.4 Rollback

`v7_to_v6.dart`:
```dart
await db.execute('DROP TABLE outbox;');
await db.execute('DROP TABLE photo_uploads;');
await db.execute('DROP TABLE visits_v2;');
await db.execute('DROP TABLE visit_tasks_v2;');
await db.execute('DROP TABLE permissions_cache;');
await db.execute('DROP TABLE catalog_cache;');
```

**Faqat outbox bo'sh bo'lsa** rollback xavfsiz (pending entries yo'qoladi). Aks holda admin manual intervention.

---

## 7. OutboxDispatcher standarti

### 7.1 Algoritm

```dart
class OutboxDispatcher {
  bool _isDispatching = false;
  
  Future<void> cycle() async {
    if (_isDispatching) return;  // Re-entrance protection
    _isDispatching = true;
    try {
      while (true) {
        if (!await connectivity.isOnline) break;
        final entry = await outboxRepo.peekDue(DateTime.now());
        if (entry == null) break;
        await outboxRepo.markInFlight(entry.envelopeId, DateTime.now());
        final result = await restClient.send(entry);
        await _classify(entry, result);
      }
    } finally {
      _isDispatching = false;
    }
  }
  
  Future<void> _classify(OutboxEntry entry, SendResult result) async {
    if (result.is2xx) {
      await outboxRepo.markAck(entry.envelopeId);
      await visitRepo.markSynced(entry.visitId);
      telemetry.emit('outbox.success', {'attempts': entry.attempts});
    } else if (result.httpStatus == 401) {
      // Token refresh, retry without incrementing
      await authService.refresh();
      await outboxRepo.markRetrying(entry.envelopeId, DateTime.now(), 'token_refresh');
    } else if (result.httpStatus == 409) {
      // Duplicate / already accepted — treat as success
      await outboxRepo.markAck(entry.envelopeId);
      await visitRepo.markSynced(entry.visitId);
    } else if (result.isTransient) {
      // 5xx, timeout, network, 429
      entry.attempts++;
      if (entry.attempts >= entry.maxAttempts) {
        await outboxRepo.markDeadLetter(entry.envelopeId, result.errorMessage);
        notify.show('Yuborilmagan tashriflar mavjud — Sozlamalar > Dead-letter');
      } else {
        final delay = backoff.compute(entry.attempts);
        final nextAttempt = DateTime.now().add(delay);
        await outboxRepo.markRetrying(entry.envelopeId, nextAttempt, result.errorMessage);
      }
    } else if (result.isTerminal) {
      // 400, 422 — validation error, no retry
      await outboxRepo.markDeadLetter(entry.envelopeId, result.errorMessage);
      notify.show('Server rad etdi: ${result.errorMessage}');
    }
  }
}
```

### 7.2 Backoff

```dart
class BackoffScheduler {
  static const _baseDelays = [
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 16),
    Duration(seconds: 32),
    Duration(seconds: 64),
    Duration(seconds: 128),
    Duration(seconds: 300),
    Duration(seconds: 300),
    Duration(seconds: 300),
  ];
  
  Duration compute(int attempts) {
    final base = _baseDelays[(attempts - 1).clamp(0, _baseDelays.length - 1)];
    final jitter = Random().nextDouble() * 0.2 - 0.1;  // ±10%
    return Duration(milliseconds: (base.inMilliseconds * (1 + jitter)).round());
  }
}
```

### 7.3 Triggerlar

| Trigger | Vaqti |
|---|---|
| App start | `main()` → `dispatcher.cycle()` |
| App foreground | `WidgetsBindingObserver.didChangeAppLifecycleState(resumed)` |
| Connectivity change | `connectivity_plus` listener |
| Periodic timer | 60s timer (foreground only) |
| Workmanager (Android) | 15 min |
| BGTaskScheduler (iOS) | iOS background tasks |
| Manual retry | Dead-letter UI button |

### 7.4 Dead-letter UI

`Settings > Sync` ekrani:
- Pending count badge
- Dead-letter list (envelope_id, visit_id, customer name, error message, attempts, last try)
- "Qayta urinish" → `outboxRepo.markRetrying(envelopeId, now, null)` → dispatcher cycle
- "O'chirish" → confirm dialog → `outboxRepo.delete(envelopeId)`

---

## 8. Photo upload pipeline

### 8.1 Lokal qadamlar

1. **Capture** (`PhotoCaptureWidget`) — camera yoki gallery.
2. **Compress** — `flutter_image_compress`:
   - `minWidth: 1920`, `minHeight: 1080`, `quality: 85`, `format: jpeg`.
   - Max 1024 KB (agar oshsa quality reduce).
3. **Strip EXIF** (opsiyaviy mobile, server ham qiladi).
4. **SHA-256** — `crypto.sha256.convert(fileBytes).toString()`.
5. **Insert `photo_uploads`** — status=`pending`, `idempotency_key=UUIDv7`.
6. **Schedule upload** — `OutboxDispatcher.cycle()` trigger (alohida photo outbox emas, balki `photo_uploads.status` trigger).

### 8.2 Upload qadami

```dart
class PhotoUploadService {
  Future<void> uploadAll() async {
    final pending = await photoRepo.findPending();
    for (final photo in pending) {
      try {
        await photoRepo.updateStatus(photo.assetId, 'uploading');
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(photo.localPath),
          'client_uuid': await LocalUuidService.deviceUuid,
          'idempotency_key': photo.idempotencyKey,
          'task_code': photo.taskCode,
          'captured_at': photo.capturedAt.toIso8601String(),
          'sha256': photo.sha256,
          'lat': photo.lat, 'lng': photo.lng, 'accuracy_m': photo.accuracyM,
        });
        final res = await restClient.dio.post(
          '/visits/${photo.visitId}/photos/',
          data: formData,
        );
        await photoRepo.markConfirmed(photo.assetId, remoteAssetId: res.data['asset_id']);
      } on DioException catch (e) {
        if (_isTransient(e)) {
          await photoRepo.incrementAttempts(photo.assetId, e.message);
        } else {
          await photoRepo.markFailed(photo.assetId, e.message);
        }
      }
    }
  }
}
```

### 8.3 Visit finish bog'lanish

Visit finish paytida `task.payload.photo_asset_ids` — **lokal `remote_asset_id`'lar** (server qaytargan). Hech bir `pending` foto qoldirish mumkin emas — agar bo'lsa user "Foto yuborilmagan, sync kuting" dialog.

---

## 9. TaskRendererRegistry (extensibility)

### 9.1 Interface

```dart
typedef TaskRendererFactory = Widget Function(TaskContext ctx);

class TaskContext {
  final String visitId;
  final String taskId;
  final String taskCode;
  final Map<String, dynamic> payloadSchema;
  final Map<String, dynamic> config;
  final Map<String, dynamic>? draftPayload;
  final void Function(Map<String, dynamic> payload) onCompleted;
  final void Function(String reason) onSkipped;
  final void Function() onBack;
}

class TaskRendererRegistry {
  static final Map<String, TaskRendererFactory> _factories = {};
  
  static void register(String taskCode, TaskRendererFactory factory) {
    _factories[taskCode] = factory;
  }
  
  static Widget resolve(TaskContext ctx) {
    final factory = _factories[ctx.taskCode];
    if (factory != null) return factory(ctx);
    // Fallback to GenericFormRenderer
    return GenericFormPage(ctx: ctx);
  }
}
```

### 9.2 Registration

`lib/src/features/visits/presentation/pages/task_pages/_registry.dart`:

```dart
void registerBuiltInTaskRenderers() {
  TaskRendererRegistry.register('PHOTO_BEFORE', (ctx) => PhotoBeforePage(ctx: ctx));
  TaskRendererRegistry.register('PHOTO_AFTER', (ctx) => PhotoAfterPage(ctx: ctx));
  TaskRendererRegistry.register('AUDIT_OWN', (ctx) => AuditOwnPage(ctx: ctx));
  TaskRendererRegistry.register('AUDIT_COMPETITOR', (ctx) => AuditCompetitorPage(ctx: ctx));
  TaskRendererRegistry.register('ORDER_CREATE', (ctx) => OrderCreatePage(ctx: ctx));
  // Yangi task qo'shilganda: shu yerga bitta qator
}
```

`main.dart` da: `registerBuiltInTaskRenderers();`

### 9.3 GenericFormRenderer

JSON Schema'dan UI tug'diradi:

| Schema | Widget |
|---|---|
| `type: string` | TextField |
| `type: string, format: email` | TextField (email validator) |
| `type: string, format: phone` | TextField (mask) |
| `type: integer/number` | NumberField (min/max) |
| `type: boolean` | Switch |
| `type: array` | ListView (sub-renderer per item) |
| `type: object` | Section |
| `enum: [...]` | Dropdown |
| `oneOf: [...]` | RadioGroup |
| `format: photo` | PhotoCaptureWidget |
| `format: gps` | LocationPicker |
| `format: signature` | SignaturePad |
| `format: barcode` | BarcodeScanner (mobile_scanner) |
| `format: date` | DatePicker |
| `format: scale_1_5` | StarRating |
| `format: rich_text` | RichTextEditor |

---

## 10. Geofence + Time + Security

### 10.1 SecureLocationService

```dart
class SecureLocationService {
  Future<LocationResult> getCurrentPosition() async {
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final mocked = pos.isMocked;  // Android only; iOS always false
    final accuracy = pos.accuracy;
    return LocationResult(
      lat: pos.latitude, lng: pos.longitude,
      accuracyM: accuracy, altitudeM: pos.altitude,
      source: 'gps', mocked: mocked,
      providerTs: DateTime.fromMillisecondsSinceEpoch(pos.timestamp.millisecondsSinceEpoch),
    );
  }
  
  bool isValidForVisit(LocationResult loc, double allowedRadiusM) {
    final accuracyThreshold = max(allowedRadiusM / 3, 30);
    if (loc.accuracyM > accuracyThreshold) return false;
    if (loc.mocked && !kDebugMode) return false;
    return true;
  }
}
```

### 10.2 ServerTimeService

```dart
class ServerTimeService {
  int _deltaMs = 0;
  
  Future<void> sync() async {
    final response = await restClient.dio.get('/visits/server-time/');
    final serverTimeStr = response.headers.value('X-Server-Time')!;
    final serverTime = DateTime.parse(serverTimeStr);
    _deltaMs = serverTime.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('server_time_delta_ms', _deltaMs);
  }
  
  DateTime now() => DateTime.now().add(Duration(milliseconds: _deltaMs));
  
  int get clientClockDriftMs => -_deltaMs;
  
  bool isDriftAcceptable(int maxDriftS) => clientClockDriftMs.abs() < maxDriftS * 1000;
}
```

### 10.3 JailbreakDetector

```dart
class JailbreakDetector {
  Future<bool> isCompromised() async {
    // Android: check root via known binaries / system properties
    // iOS: check Cydia URL scheme, file system paths
    return await FlutterJailbreakDetection.jailbroken;
  }
}
```

---

## 11. Feature flag (gradual migration)

### 11.1 Config

```dart
enum VisitSubmissionPath { soap, restV2 }

class FeatureFlags {
  static VisitSubmissionPath get visitSubmission {
    final cached = PermissionsRepository.cached?.flags.visitSubmissionPath;
    return cached ?? VisitSubmissionPath.soap;  // Default safe
  }
}
```

### 11.2 Routing

```dart
class VisitFinishOrchestrator {
  Future<void> finish(VisitSession session) async {
    switch (FeatureFlags.visitSubmission) {
      case VisitSubmissionPath.soap:
        await _soapFinishService.finishVisit(...);  // Mavjud eski yo'l
      case VisitSubmissionPath.restV2:
        final envelope = VisitEnvelopeBuilder.build(session);
        await outboxRepo.enqueue(
          OutboxEntry(
            envelopeId: const Uuid().v7(),
            visitId: session.visitId,
            endpoint: '/visits/finish/',
            httpMethod: 'POST',
            payloadJson: jsonEncode(envelope.toJson()),
            idempotencyKey: envelope.idempotencyKey,
            clientUuid: await LocalUuidService.deviceUuid,
            status: 'pending',
            nextAttemptAt: DateTime.now(),
            maxAttempts: 10,
          ),
        );
        await outboxDispatcher.cycle();
    }
  }
}
```

---

## 12. L10n va task naming

- Hech qachon `step.stepName.toLowerCase() == 'фото до ...'` taqqoslashi yo'q.
- Faqat `TaskCode` enum.
- Display name `Catalog.tasks[i].nameI18n[currentLocale]` (server'dan).
- Fallback `.arb` fayl (uz/ru/en) lokal task'lar uchun (PHOTO_BEFORE → "Foto oldidan"/"Фото до"/"Photo before").

```dart
String taskDisplayName(String taskCode, BuildContext context) {
  final locale = context.locale.languageCode;
  final catalogEntry = CatalogRepository.cached?.tasks.firstWhereOrNull((t) => t.taskCode == taskCode);
  if (catalogEntry != null) {
    return catalogEntry.nameI18n[locale] ?? catalogEntry.nameI18n['en'] ?? taskCode;
  }
  return AppLocalizations.of(context)!.taskName(taskCode);  // .arb fallback
}
```

---

## 13. Telemetry

`telemetry_v2` (mavjud) kengaytirilishi:

| Event | When | Properties |
|---|---|---|
| `visit_started_v2` | VisitSession start | visitId, customerId, plannedFlag, deviceInfo |
| `visit_finished_local` | User taps "Finish" | visitId, totalDurationMs, taskCount |
| `visit_synced` | Outbox ack | visitId, attempts, syncLatencyMs |
| `task_started` | Task page open | visitId, taskId, taskCode |
| `task_completed` | Task complete | visitId, taskId, taskCode, durationMs |
| `task_skipped` | Task skip | visitId, taskCode, reason |
| `sync_failed` | Outbox transient/terminal | envelopeId, errorCode, attempts |
| `sync_succeeded` | Outbox ack | envelopeId, latencyMs |
| `mock_location_blocked` | Geofence check | visitId, customerCode |
| `clock_drift_blocked` | Visit start | driftMs, maxAllowedMs |
| `gps_accuracy_blocked` | Visit start | accuracyM, requiredM |
| `outbox_dead_letter` | Max attempts | envelopeId, errorCode |
| `photo_capture` | Camera | visitId, taskCode, sizeKb, latencyMs |
| `photo_upload_failed` | Photo upload retry | assetId, error |
| `feature_flag_resolved` | Permissions refresh | visitSubmissionPath |

---

## 14. Tests standarti

### 14.1 Coverage

- Min **80%** line coverage `lib/src/features/visits/`.
- Critical paths (OutboxDispatcher, VisitEnvelopeBuilder, SequencePolicy) — 100%.

### 14.2 Test pyramidasi

| Turi | Vazifa | Qayerda |
|---|---|---|
| Unit | Domain logic, builder, dispatcher | `test/features/visits/domain/`, `test/features/visits/infra/` |
| Widget | LockedTaskCard, OutboxStatusBadge, GenericFormRenderer | `test/features/visits/presentation/widgets/` |
| Integration | Full visit lifecycle (mock REST) | `integration_test/visits/` |
| Golden | Task pages snapshot | `test/features/visits/golden/` |

### 14.3 Asosiy test scenariolar

| Test | Scenario |
|---|---|
| Outbox happy | enqueue → online → 2xx → ack |
| Outbox offline | enqueue → offline → connectivity restored → retry → ack |
| Outbox backoff | 5xx → retry with delay → max attempts → dead_letter |
| Outbox 409 | duplicate → mark ack |
| Outbox 401 | refresh → retry without attempts++ |
| Outbox 422 | terminal → dead_letter |
| Envelope builder | VisitSession → JSON matches schema |
| SequencePolicy strict | task2 cannot start before task1 completed |
| SequencePolicy free | any order |
| GeofenceRule | accuracy > radius/3 → blocked |
| Mock location | mocked=true → blocked (release) |
| Clock drift | drift > 5 min → blocked |
| Crash recovery | app kill → restart → in_progress visit restored |
| Photo upload retry | network fail → next cycle → success |
| Feature flag | flag=soap → SoapFinishService called |
| Feature flag | flag=restV2 → OutboxRepository.enqueue called |

### 14.4 Mock REST server

`test/utils/mock_rest_server.dart` — `shelf` package yoki `Dio` interceptor mock:

```dart
class MockRestServer {
  late HttpServer _server;
  
  Future<void> start({int port = 8888}) async {
    _server = await io.serve(_handler, 'localhost', port);
  }
  
  Future<Response> _handler(Request req) async {
    if (req.url.path == 'api/mobile/v2/visits/finish/') {
      return Response(201, body: jsonEncode({...}));
    }
    ...
  }
}
```

---

## 15. CI / build / lint

### 15.1 Pre-commit

`.git/hooks/pre-commit` (yoki `lefthook`):
- `flutter format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test --no-pub`

### 15.2 CI

GitHub Actions:
- `flutter pub get`
- `flutter analyze` (0 issue)
- `flutter test --coverage` (≥ 80%)
- `flutter test integration_test/` (mock server)
- `flutter build apk --debug` (build pass)

### 15.3 Code style

- `lib/` 100% Dart format
- Public API'da type hints majburiy
- `// ignore: ...` faqat zarurat
- Hard rule: file > 500 satr → bo'lish

---

## 16. Eslatmalar va anti-patternlar

❌ **Qilmang**:
- `step.stepName == 'фото до (facing correction)'` — TaskCode enum'ga ko'chiring.
- visitId formati `visit_{user}_{client}_{date}` — UUIDv7.
- Sinxron `setState(() {...})` ichida async — Bloc emit qiling.
- `Future.delayed(Duration(ms: 500))` placeholder server call — real REST endpoint.
- View ichida `Dio.post(...)` to'g'ridan-to'g'ri — repository orqali.
- Hard delete photo files — `photo_uploads.status='confirmed'` bo'lgandagina S3 ack'dan keyin.
- BLoC fayl > 500 satr — handler ajrating.
- `print(...)` — `developer.log()` yoki telemetry.

✅ **Qiling**:
- Har envelope `idempotency_key=UUIDv7` bir marta, retry'da o'zgarmaydi.
- Photo upload **avval**, finish envelope ichida faqat ID.
- `transaction` da bir nechta DB write — sqflite `db.transaction`.
- Time tracking `Stopwatch` (ms aniqligida) — server'ga ms o'rniga ISO `started_at/ended_at`.
- Strict sequence — `LockedTaskCard` + tooltip + tap → SnackBar.
- Feature flag bilan SOAP/REST toggle.

---

## 17. Reference

- Plan: `/Users/kamoliddin/.claude/plans/loyihani-chuqur-professional-tahlil-eager-volcano.md`
- Promt: `docs/visits-v2-mobile.md` (juftligi)
- Backend passport (juftligi): `SelUp_Backend/docs/integration-prompts/visits-v2-backend-passport.md`
- Backend promt: `SelUp_Backend/docs/integration-prompts/visits-v2-backend.md`
- Eski kod (deprecate qilinadi):
  - `lib/src/features/agent/services/visit_finish_service.dart` — 689 satr placeholder
  - `lib/src/features/agent/presentation/pages/visit_steps_page.dart` — 3921 satr monolithic
  - `lib/src/core/services/visit_step_sync_service.dart` — yarim sync
  - `lib/src/core/services/soap_api_service.dart` — saqlanadi (feature flag bypass)
- Mavjud templates:
  - `lib/src/core/services/service_locator.dart` — DI registration
  - `lib/src/core/services/telemetry_v2/` — analytics events
  - `lib/src/core/database/database_helper.dart` — sqflite migrations
  - `lib/src/features/agent/services/photo_storage_service.dart` — eski photo (refactor uchun reference)
