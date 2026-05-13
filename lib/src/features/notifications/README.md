# Notification Center — Flutter (Phase 1)

Klient kontrakti: `docs/notifications/passport-mobile.md` (backend repo).
Strategiya: `docs/notifications/PLAN.md`.

## Tarkibi

```
lib/src/features/notifications/
├── data/
│   ├── db/notification_db_dao.dart          # sqflite DAO: notifications + pending_read_marks
│   ├── models/app_notification.dart         # entity + JSON/DB mapping
│   ├── repositories/notification_repository.dart  # API + DAO orkestratsiyasi, unread/list streams
│   └── services/
│       ├── notification_api_service.dart    # /api/mobile/v2/notifications/* klient
│       ├── fcm_token_service.dart           # register / rotate / revoke
│       └── push_handler_service.dart        # foreground / background / terminated
├── presentation/
│   ├── bloc/                                # NotificationListCubit, UnreadCountCubit, DetailCubit
│   ├── pages/                               # NotificationListPage, NotificationDetailPage
│   └── widgets/                             # NotificationBell, InAppBannerHost
└── services/notification_tap_router.dart    # selup:// deep-link → route
```

## Lifecycle

| Vaqt | Nima sodir bo'ladi |
| --- | --- |
| `main()` cold-start | Firebase init, push handlerlar attach, local cache hydrate. FCM permission so'ramaydi (passport §2.4). |
| Login muvaffaqiyatli | `AuthBloc._initNotificationCenter` → `FcmTokenService.registerOnLogin` + `syncIncremental(force: true)`. |
| Foydalanuvchi bell'ga tegadi | OS notification permissionini birinchi marta so'raydi, list ochiladi. |
| Push (foreground) | `PushHandlerService` → `InAppBannerController.show` (banner) + `NotificationRepository.fetchAndCache`. |
| Push (background) | Top-level `firebaseBackgroundMessageHandler` → DAO'ga stub yoziladi. Keyingi sync to'liq xabarni oladi. |
| Push (terminated tap) | `getInitialMessage()` → `NotificationTapRouter`. |
| Logout | FCM token revoke, local cache wipe, pending_read_marks ham tozalanadi. |

## Native setup (manual qadamlar)

Bu fayllar repo'da yo'q va siz qo'shasiz:

### Android

1. Firebase Console → loyiha yarating → Android app qo'shing
   (`applicationId = com.maxsoft.selup`).
2. `google-services.json` faylni `android/app/` ichiga joylang.
3. (Optional) Gradle sync — `com.google.gms.google-services` plagini allaqachon
   `android/settings.gradle.kts` va `android/app/build.gradle.kts`'da ulangan.

### iOS

1. Firebase Console → iOS app qo'shing (`com.maxsoft.selup` bundle id).
2. `GoogleService-Info.plist`'ni `ios/Runner/` papkasiga drag-drop qiling
   (Xcode → "Add Files to Runner" → Copy items if needed).
3. Xcode → Runner target → **Signing & Capabilities**:
   - `Push Notifications` capability qo'shing.
   - `Background Modes`: `Remote notifications` belgilang
     (`Info.plist`'da `remote-notification` allaqachon mavjud).
4. Firebase Console → Cloud Messaging → APNs Authentication Key yuklang
   (Apple Developer → Keys → APNs key, `.p8` fayl).

### Backend

`POST /api/mobile/v2/notifications/devices/` endpointi `--dart-define=V2_BASE_URL=...`
orqali konfiguratsiya qilingan baseURL'ga tushadi. Backend `notification_id`
asosida thin payload yuborishi shart (passport §3.4).

## Manual test cheklist

| # | Scenariy | Kutilgan natija |
| --- | --- | --- |
| 1 | Login → bell ko'rinishi | Badge ko'rsatkichi local cache'dan derived (boshida 0). |
| 2 | Backend admin paneldan push yuboradi (foreground) | Banner ko'rinadi 5s, badge +1, list yangilanadi. |
| 3 | Push (background — ekran o'chirilgan) | OS tray banner, app ochilgandan list +1. |
| 4 | Push tap (terminated state) | App ochiladi → notification detail yoki deep-link. |
| 5 | Detail screen tap | Avto-mark-read, badge -1. |
| 6 | Long-press bell → "mark all read" | Tasdiqlash dialog → barchasi o'qilgan, badge 0. |
| 7 | Offline + mark-read → online | `pending_read_marks` queue → flush → bulk-read API. |
| 8 | Logout | FCM token revoke, cache bo'shaydi. Yangi login boshqa userda eski xabarlar yo'q. |

## Bog'liq fayllar (modifikatsiyalar)

- `pubspec.yaml` — `firebase_messaging`, `flutter_local_notifications`.
- `android/settings.gradle.kts` — google-services plugin declaration.
- `android/app/build.gradle.kts` — plugin apply.
- `android/app/src/main/AndroidManifest.xml` — `POST_NOTIFICATIONS` mavjud.
- `ios/Runner/Info.plist` — `remote-notification` + `FirebaseAppDelegateProxyEnabled`.
- `lib/main.dart` — Firebase init, push handler init, in-app banner host.
- `lib/src/core/database/database_helper.dart` — DB v5 (notifications + pending_read_marks).
- `lib/src/core/router/app_router.dart` — `/notifications` va `/notifications/detail` route'lar.
- `lib/src/core/services/service_locator.dart` — DI registratsiyasi.
- `lib/src/features/auth/presentation/bloc/auth_bloc.dart` — login/logout hooklar.
- `lib/src/features/agent/presentation/pages/agent_home_modern.dart` — `NotificationBell` joylashtirildi.

## Phase 2 — joriy holat

| Sub-phase | Tarkibi | Holati |
| --- | --- | --- |
| 2a | Notification preferences (type on/off, DND, sound per priority) + Android channel per type | ✅ |
| 2b | Snooze (1h / 4h / 08:00 ertaga) + mark-as-unread (long-press menyu) | ✅ |
| 2c | iOS critical alert (`urgent` → `InterruptionLevel.critical`) + Android `Importance.max` urgent uchun | ⚠️ kod tayyor, lekin iOS'da Apple entitlement kerak |
| 2d | Tablet master-detail (≥ 720dp width) | ✅ |

### Phase 2c — iOS critical alert entitlement

Kod `priority == 'urgent'` push'larda `InterruptionLevel.critical`'ni
ishlatadi. iOS uni quyidagi shartlardan biriga ko'ra silent ravishda
downgrade qiladi:

- App `com.apple.developer.usernotifications.critical-alerts`
  entitlement'ga ega emas → `timeSensitive` ga downgrade.
- App entitlement'ga ega, lekin foydalanuvchi rad etgan → `active`.

**To enable real critical alerts** (lock-screen orqali tovush DND
da):

1. Apple Developer Portal'da `com.apple.developer.usernotifications.critical-alerts`
   entitlement uchun ariza topshiring. Apple ~3-5 ish kuni javob beradi
   (legitimacy review).
2. Apple javobi kelgach `ios/Runner/Runner.entitlements` fayliga shu
   kalitni qo'shing:
   ```xml
   <key>com.apple.developer.usernotifications.critical-alerts</key>
   <true/>
   ```
3. Xcode → Runner → Signing & Capabilities → provisioning profile'ni
   yangilang.

Entitlement yo'q paytda kod ham xato bermaydi, ham crash qilmaydi —
faqat critical sound o'rniga oddiy alert chiqadi.
