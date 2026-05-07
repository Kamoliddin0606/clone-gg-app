# Running the mobile app

The V2 backend URL and the legacy 1C SOAP host are now compile-time
constants resolved via `String.fromEnvironment`. There are no LAN IPs
hardcoded in `lib/`. Pass the right host for your scenario via
`--dart-define`.

The two knobs:

| Define          | Used by                | Default                       |
| --------------- | ---------------------- | ----------------------------- |
| `V2_BASE_URL`   | All V2 JWT auth + telemetry calls | `http://localhost:8080` |
| `SOAP_BASE_URL` | Legacy 1C SOAP login (post-V2 session warm-up) | `http://178.218.200.120:1596` |

Defaults stay developer-safe: nothing reaches a customer environment by
accident.

## Recipes

### macOS / desktop dev

```bash
flutter run -d macos \
  --dart-define=V2_BASE_URL=http://localhost:8080
```

### Android emulator

The emulator's `localhost` is the emulator itself — use `10.0.2.2` to
reach the Mac host:

```bash
flutter run -d emulator-5554 \
  --dart-define=V2_BASE_URL=http://10.0.2.2:8080
```

### iOS simulator

The simulator shares the Mac's network stack, so `localhost` works:

```bash
flutter run -d "iPhone 15 Pro" \
  --dart-define=V2_BASE_URL=http://localhost:8080
```

### Real Android phone on the same Wi-Fi as the dev Mac

`<MAC_LAN_IP>` is your Mac's address on the local network
(`ipconfig getifaddr en0`). The phone must be on the same SSID and the
backend must be listening on that interface (not just `127.0.0.1`).

```bash
flutter run -d <ANDROID_DEVICE_ID> \
  --dart-define=V2_BASE_URL=http://192.168.1.42:8080
```

### Real iPhone (off-LAN) via ngrok

Expose the local backend with `ngrok http 8080`, then point the phone
at the public URL. ATS exceptions for `*.ngrok-free.app` are already in
the iOS `Info.plist`.

```bash
ngrok http 8080
flutter run -d <IPHONE_DEVICE_ID> \
  --dart-define=V2_BASE_URL=https://your-tunnel-id.ngrok-free.app
```

### Production / staging

```bash
flutter build ipa --release \
  --dart-define=V2_BASE_URL=https://api.example.com \
  --dart-define=SOAP_BASE_URL=http://soap.example.com:1596
```

Use the same `--dart-define` values for the `flutter build apk` /
`flutter build appbundle` Android lanes.

## Verifying the resolved URL on device

In debug builds the login screen shows a `Backend: <url>` footer and a
`Test connection` button (gated by `kDebugMode`). The startup log also
prints:

```
[CONFIG] V2_BASE_URL=http://192.168.1.42:8080
[HEALTH] V2 backend reachable in 41ms
```

If the URL is wrong (typo, stale `--dart-define`, wrong network), the
health probe surfaces the failure immediately:

```
[HEALTH] V2 backend UNREACHABLE: connection error: ...
```

Release builds strip both the footer and the startup probe.

## Notes

- The mobile app no longer falls back to the legacy SOAP login when the
  V2 backend is unreachable. A transport error blocks the login with a
  Retry banner that clears the credential fields. Auto-retry is
  forbidden — the user must press Retry deliberately.
- SOAP keeps running for **non-auth** business calls (KPI, products,
  prices, orders) and for the post-V2 1C session warm-up only.
