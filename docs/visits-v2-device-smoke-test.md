# Visits v2 — Real device smoke test checklist

> Manual smoke matrix run after every build that changes the visit
> pipeline. Designed for two devices: one Android (camera + Workmanager
> + Geolocator) + one iOS (BGTaskScheduler + Info.plist permissions).
> 30 minutes per device covers the critical paths.

---

## 0. Pre-flight

| # | Step | Pass criteria |
|---|---|---|
| 0.1 | `flutter pub get` succeeds | no resolver errors |
| 0.2 | `flutter analyze lib/src/features/visits/ test/features/visits/` | "No issues found" |
| 0.3 | `flutter test test/features/visits/` | All tests pass (current count: 64) |
| 0.4 | `flutter build apk --debug` (Android) | `build/app/outputs/flutter-apk/app-debug.apk` exists |
| 0.5 | `flutter build ios --debug --no-codesign` (iOS) | builds without Xcode signing |
| 0.6 | Backend `feature_flags.visits_rest_v2_enabled=true` on the test org | confirm with `curl …/permissions/` |

---

## 1. Android — happy path (15 min)

| # | Action | Expected |
|---|---|---|
| 1.1 | `adb install build/app/outputs/flutter-apk/app-debug.apk` | install OK |
| 1.2 | Launch app, login as QA agent | home screen renders |
| 1.3 | Logs show `[Visits v2] Server time captured` + `Permissions + catalog warmed` | grep `flutter` logs in `adb logcat` |
| 1.4 | Settings → "Tashriflar tarixi" icon | `VisitListPage` opens (empty state OK for first run) |
| 1.5 | Settings → sync icon (no badge) | `DeadLetterPage` shows zero rows |
| 1.6 | Trading points → tap one → "Visit" | `VisitSessionPage` opens (new UI, not legacy) |
| 1.7 | Permission prompts (location, camera, storage) | granted → no error |
| 1.8 | Task 1 (PHOTO_BEFORE): camera, snap 1 photo, "Tugatish" | photo tile shows status chip ("…" → "OK") |
| 1.9 | Task 2 (AUDIT_OWN): add 1 row, fill fields, "Yakunlash" | next task active |
| 1.10 | Task 3 (ORDER_CREATE): tap "Buyurtmasiz yakunlash" | next task |
| 1.11 | Task 4 (PHOTO_AFTER): 1 photo, "Tugatish" | progress bar hits 4/4 |
| 1.12 | Tap "Tashrifni yakunlash" | `VisitSessionFinishing` → `VisitSessionEnqueued` |
| 1.13 | UX (changelog § 7): "Tashrif serverga yuborildi" → 5-30s later "Buyurtma 1C ga yetkazildi" | green checkmark appears |
| 1.14 | Tap "Davom etish" → returns to home | home screen visible |
| 1.15 | Settings → "Tashriflar tarixi" → new visit at top | status chip shows "1C" (green) |
| 1.16 | Tap the visit row → `VisitDetailPage` | tasks render, photo strip shows uploaded photos |
| 1.17 | Tap a photo → full-screen viewer | `InteractiveViewer` zoom works |

---

## 2. Android — failure scenarios (8 min)

| # | Action | Expected |
|---|---|---|
| 2.1 | Disable GPS in device settings, try visit start | dialog: "GPS yo\'q: location_services_disabled" |
| 2.2 | Re-enable GPS, set phone clock 10 min back, try visit start | `ClockDriftFailure` SnackBar in Uzbek (changelog § 9: "Telefon vaqti noto'g'ri…") |
| 2.3 | Reset clock, enable mock location (developer settings → mock GPS), try visit start | release build blocks ("Mock location aniqlandi"); debug build warns only |
| 2.4 | Pick a trading point further than `clientZoneAccess` (≥ 500m), try visit start | `GeofenceFailure` SnackBar |
| 2.5 | Airplane mode → finish visit | `OutboxStatusBadge` shows "1" (pending); dispatcher logs offline |
| 2.6 | Disable airplane mode → wait ≤ 60s | badge clears (`ack`); Crashlytics breadcrumb `outbox kind=acked` |
| 2.7 | Start visit, complete one task, force-stop the app from settings | next launch home shows "Davom etish?" recovery dialog |
| 2.8 | Tap "Davom etish" | `VisitSessionPage` resumes at next task |

---

## 3. iOS — parity (10 min)

iOS-specific spots; the rest of the matrix above is symmetric.

| # | Action | Expected |
|---|---|---|
| 3.1 | Xcode → Run on connected device | app launches |
| 3.2 | Info.plist permissions prompt order | location → camera → photo library |
| 3.3 | Capture photo via `image_picker` | image lands in `photo_uploads`, status promotes to `confirmed` |
| 3.4 | `BGTaskSchedulerPermittedIdentifiers` registered | check `Info.plist` contains `visits_v2.outbox_sync` |
| 3.5 | Background app for 16+ minutes (battery > 20%) | iOS opportunistically fires the BG task; outbox drains |
| 3.6 | `Geolocator.isMocked` always `false` on iOS | mock-location stanza never blocks (platform limitation) |
| 3.7 | App Refresh disabled in Settings → background sync inert | foreground coordinator still drains on resume |

---

## 4. Edge cases (5 min)

| # | Action | Expected |
|---|---|---|
| 4.1 | Photo upload during slow network (Charles throttle to 64 kbps) | retries with exponential backoff; eventually `confirmed` |
| 4.2 | Charles replay the same `POST /finish/` body | second response = 200 OK with `Idempotent-Replay: true` header; Crashlytics breadcrumb has `replay=true` |
| 4.3 | Backend admin flips `visits_rest_v2_enabled` to `false` mid-session | next `_informVisit` reads cached snapshot, then refreshes → legacy `VisitStepsPage` opens for the next visit |
| 4.4 | Photo deleted by user before finish | row removed from `photo_uploads`; UI tile disappears |
| 4.5 | Visit 35+ days old in history list (retention seam) | thumbnail falls back to `medium` (small purged); detail page still renders via `RetentionAwarePhoto` chain |
| 4.6 | Visit 95+ days old (purged) | 404 from `GET /visits/{id}/` → "Tashrif topilmadi" screen |

---

## 5. Logs to capture during the run

```bash
# Android — full Flutter + visits namespace
adb logcat -s flutter:V visits.bg:V outbox:V

# iOS — Console.app, filter by process "Runner"
log stream --predicate 'subsystem CONTAINS "io.flutter" OR subsystem CONTAINS "visits"'
```

Pin the following in the QA report:

- Crashlytics issue counts before / after (target: zero new `visits.*` issues)
- `OutboxStatusBadge` peak count (informational)
- 1C lag for the test visits (panel #4 on Grafana)

---

## 6. Sign-off

A pilot APK is shippable when:

- [ ] Sections 1, 2, 4 (Android) — all rows green.
- [ ] Section 3 (iOS) — all rows green on at least one iPhone (12+).
- [ ] No new Crashlytics issues filed under `visits.*` during the run.
- [ ] Grafana panel #2 (error rate) stayed at 0 throughout.
- [ ] Tester writes a one-paragraph QA note attached to the rollout ticket.

Anything red → flip the org's feature flag back to `false` before
shipping to additional users (RUNBOOK § 5.1).

---

## Reference

- Pilot quickstart: `docs/visits-v2-pilot-quickstart.md`
- Backend health check: `SelUp_Backend/docs/runbooks/visits-v2/HEALTH_CHECK.md`
- Backend runbook (rollback): `SelUp_Backend/docs/runbooks/visits-v2/RUNBOOK.md` § 5
- Changelog response: `docs/visits-v2-mobile-changes-response.md`
