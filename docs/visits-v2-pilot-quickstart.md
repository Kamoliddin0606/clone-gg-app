# Visits v2 — Mobile pilot quickstart (Rollout R1)

> Yo'l-yo'riq dev pilot uchun (1 user, 24 soat). Mobile tomondagi qadamlar
> + flag toggle SQL'i + minimal verifikatsiya sxenariysi. Backend tomondagi
> health check `SelUp_Backend/docs/runbooks/visits-v2/HEALTH_CHECK.md` § 1.

---

## 1. Pilot build chiqarish

```bash
cd clone-gg-app
flutter pub get
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

APK'ni pilot foydalanuvchi qurilmasiga `adb install` orqali yetkazing.
Debug build kifoya — Firebase Crashlytics inert (real google-services.json
yo'q), lekin mobile flow REST v2 yo'lda to'liq ishlaydi.

Production build keyingi sprint (B4 follow-up).

---

## 2. Backend flag flip (test orgda)

```sql
UPDATE tenants_organization
SET feature_flags = jsonb_set(coalesce(feature_flags, '{}'::jsonb),
                              '{visits_rest_v2_enabled}', 'true')
WHERE code = 'internal_qa';
```

Tasdiqlash:

```bash
curl -fsS -H "Authorization: Bearer $TOKEN" \
  https://staging-api.gloriya.uz/api/mobile/v2/visits/permissions/ \
  | jq '.flags.visit_submission_path'
# kutilgan: "rest_v2"
```

---

## 3. Mobile bilan first-visit walkthrough

| Qadam | Kutilgan natija |
|---|---|
| 1. Login QA user bilan | `AuthBloc` `/visits/permissions/` ni warm qiladi |
| 2. Trading point ro'yxati ochish | Eski sahifa, REST v2 yo'l hali yashirin |
| 3. Trading point'ni tanlab "Visit" tugmasi | `TradingPointsPage._informVisit` best-effort permissions refresh + `useRestV2 == true` → `VisitSessionPage` yangi UI |
| 4. Geofence dialog (radius cheklov bor bo'lsa) | OK basish → BLoC `StartVisit` event |
| 5. Tasks ro'yxati | Catalog'dan kelgan `name_i18n[uz]` matnlari |
| 6. Har task ni bajaring (photo + audit + order) | Photolar `photo_uploads` jadvalga `pending`, dispatcher background'da yuklaydi |
| 7. Finish tugmasi | `noFailedFor` gate (faqat `failed` rad etiladi) → envelope outbox'ga → cycle online → backend 201/200 |
| 8. SnackBar "Tashrif serverga yuborildi" | `VisitSessionEnqueued` state, `OutboxStatusCubit.ack` ticked |
| 9. (Ixtiyoriy) `VisitStatusPoller` ulansa → "Buyurtma 1C ga yetkazildi" | Phase B1 da ulanadi; hozir hosil bo'lmaydi |

---

## 4. Verifikatsiya — backend tomon

```sql
-- Visit serverga tushganmi?
SELECT id, status, outcome, finished_at
FROM visits_visit
WHERE user_id = (SELECT id FROM accounts_user WHERE username='qa@selup.uz')
ORDER BY created_at DESC LIMIT 1;
-- kutilgan: status='submitted'

-- 1C ga forward bo'ldimi? (60 soniya ichida)
SELECT event_type, status, retry_count
FROM sync_outboxevent
WHERE entity_id = '<visit-id>'
  AND event_type = 'visit.finished';
-- kutilgan: status='success'
```

---

## 5. Negative scenariolarni qisqartirilgan smoke

| Stsenariy | Aksiya | Kutilgan |
|---|---|---|
| Geofence | Mijoz manzilidan 500m uzoqda visit start | `VisitSessionError(GeofenceFailure)` → uzbek SnackBar (B1 da to'liq lokalizatsiya) |
| Clock drift | Telefon vaqtini 10 min orqaga sur | Visit start rad → "Telefon vaqti noto'g'ri" |
| Offline finish | Airplane mode → finish | Outbox `pending`, online → 60s ichida ack |
| Crash recovery | Visit yarim bo'lganda app force-stop | Home sahifada "Davom etish?" dialog (60s ichida) |
| Idempotent retry | Charles bilan duplicate POST | 200 OK + Crashlytics breadcrumb `replay=true` |

---

## 6. Kuzatuv (24 soat davomida)

| Manba | Kuzatishi shart |
|---|---|
| Grafana panel #2 (Finish error rate) | < 0.5% |
| Grafana panel #3 (Outbox dead-letter) | = 0 |
| Grafana panel #4 (1C lag p95) | < 120 s |
| Crashlytics `visits.*` issues | yangi issue yo'q |
| Pilot user feedback (Telegram) | UX shikoyatlari ro'yxat |

Pilot OK bo'lsa: R2 (10% rollout) — RUNBOOK.md § 4.2.

---

## 7. Abort tugmalari

| Holat | Aksiya |
|---|---|
| Error rate > 1% sustained 10 min | Backend flag flip: `'rest_v2_enabled': false` |
| Yangi crash class | Crashlytics issue ID bilan flag flip + bug fayl ochish |
| 1C lag > 5 min | Faqat 1C transient — flag o'zgarmaydi; outbox o'zi retry qiladi |
| Pilot user "yangi UI ishlamaydi" | Flag flip + UX shikoyatlarini hujjatlash, R2 ga o'tmaslik |

Flag flip darhol mobile foydalanuvchisini eski SOAP yo'liga qaytaradi
(keyingi `/permissions/` refresh, ≤ 1 round-trip). Outbox'dagi pending
envelopelar backend tomondan baribir qabul qilinadi.

---

## Reference

- Backend health check: `SelUp_Backend/docs/runbooks/visits-v2/HEALTH_CHECK.md` § 1
- Backend runbook (rollback): `SelUp_Backend/docs/runbooks/visits-v2/RUNBOOK.md` § 5
- Mobile changelog javobi: `docs/visits-v2-mobile-changes-response.md`
- Mobile passport: `docs/visits-v2-mobile-passport.md`
- Grafana dashboard: `SelUp_Backend/docs/runbooks/visits-v2/dashboard.json`
