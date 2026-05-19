# Visits v2 — Production Firebase config swap

> Operational note: visits pipeline relies on Firebase Crashlytics for
> `visits.*` breadcrumb / non-fatal capture (`VisitsCrashlyticsReporter`).
> This document is the swap-in instruction for the debug → production
> Firebase project. **DevOps task, no Dart code changes.**

---

## Hozirgi holat

Debug pilot APK Firebase'ni init qila olmaydi — `main.dart` § 63-84:

```
[Main] Firebase initialise SKIPPED (...).
Notifications will stay offline until google-services.json /
GoogleService-Info.plist is provisioned.
```

Bu **xato emas** — fail-open by design. Crashlytics inert holatda, visits
breadcrumb'lar `Future` ichida bo'g'iladi (`_crashlytics.log` no-op).
Mobile flow REST v2 yo'lda to'liq ishlaydi.

Pilot R1 davomida bu adekvat — Grafana panel #2 (server-side error rate)
va backend `audit_log` jadvali kuzatuv uchun yetarli.

---

## Production swap qadamlari

### 1. Firebase console (DevOps)

Selup Marketing Firebase loyihasiga kirish (yoki yangi loyiha):

| Manifest | Joy |
|---|---|
| `android/app/google-services.json` | Android app config (package `uz.gloriya.marketing`) |
| `ios/Runner/GoogleService-Info.plist` | iOS app config (bundle `uz.gloriya.marketing`) |

Console → Project settings → Apps → Download config. Ikkalasini
repo'ga commit qiling (yoki CI secret sifatida).

### 2. Crashlytics yoqilishi

Console → Crashlytics → Enable. Mobile init'da Firebase
`onBackgroundMessage` registratsiya qiladi va `recordError(fatal: false)`
chaqirilganda issue paydo bo'ladi.

Birinchi event Crashlytics dashboard'ida ko'rinishi uchun 1 ta tashrif
yakunlash kifoya — `VisitsCrashlyticsReporter._logOutbox` har envelope
acceptida `outbox kind=acked …` breadcrumb yozadi.

### 3. Custom keys filtering

Crashlytics → Filters → Custom keys'ga ushbu kalitlarni qo'shing:

| Key | Value tipi | Maqsad |
|---|---|---|
| `visits.visit_id` | UUID | Visit-level grouping |
| `visits.customer_id` | UUID | Customer-level grouping |
| `visits.envelope_id` | UUID | Envelope-level (outbox row) |
| `visits.status` | enum | `draft`/`submitted`/`synced_1c`/… |
| `visits.planned` | bool | planned vs unplanned |
| `visits.task_count` | int | task hajmi |

`VisitsCrashlyticsReporter.bindActiveVisit` har visit start'da bu
kalitlarni o'rnatadi. Filter ham `is set`, ham aniq qiymat bo'yicha
ishlaydi.

### 4. Alert qoidalari (Crashlytics)

| Alert | Threshold |
|---|---|
| Yangi `visits.*` issue klassi | har soat darhol email + Telegram |
| Velocity > 1% per session for any `visits.*` issue | darhol pager |
| `non-fatal recordError` count > 10/min | informational, Slack-ga |

---

## Sanity check (production swap'dan keyin)

1. Pilot agentga yangi APK yetkazing.
2. 1 ta tashrif yakunlang.
3. Firebase Crashlytics → Logs → grep `outbox kind=acked` → birinchi event ko'rinishi shart.
4. Custom keys filtering chap menu'da paydo bo'lishi shart (5-10 daqiqa kechikish bo'lishi mumkin).
5. Test sifatida sun'iy fatal: agent QA build'da geofence bilan ataylab uzoq joydan visit start qilsa, `non-fatal` event Crashlytics'ga tushadi.

---

## Mobile-side hech narsa o'zgartirilmaydi

Kod allaqachon tayyor (`firebase_crashlytics: ^5.0.2` mavjud,
`VisitsCrashlyticsReporter` DI'da, `main.dart` Firebase init'ni
try/catch bilan o'rab oladi). Faqat config fayllar qo'shilishi kifoya.

Agar maxsus build flavor kerak bo'lsa (staging vs prod Firebase),
keyingi sprint'da:

- `android/app/src/{flavor}/google-services.json`
- `ios/Runner/Firebase/{Flavor}-GoogleService-Info.plist`
- `flutter build apk --flavor prod` / `staging`

Pilot uchun shart emas — bitta prod config yetarli.

---

## Reference

- Pilot quickstart: `docs/visits-v2-pilot-quickstart.md`
- Smoke test: `docs/visits-v2-device-smoke-test.md`
- Reporter manbaa: `lib/src/features/visits/infra/telemetry/visits_crashlytics_reporter.dart`
- `main.dart` § 63-84 — Firebase init guard
