import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gloria_marketing_flutter/firebase_options.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/providers/locale_provider.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/permission_manager.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_key_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/connectivity_monitor_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/app_start_guard.dart';
import 'package:gloria_marketing_flutter/src/core/services/health_check_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/core/version/data/version_app_info.dart';
import 'package:gloria_marketing_flutter/src/core/version/data/version_gate_response.dart';
import 'package:gloria_marketing_flutter/src/core/version/domain/version_gate_service.dart';
import 'package:gloria_marketing_flutter/src/core/version/presentation/update_available_dialog.dart';
import 'package:gloria_marketing_flutter/src/core/widgets/permission_gate.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/fcm_token_service.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/notification_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/push_handler_service.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/presentation/widgets/in_app_banner.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/services/notification_tap_router.dart';
import 'package:gloria_marketing_flutter/src/theme/theme_controller.dart';
import 'package:gloria_marketing_flutter/src/theme/theme_schemes.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart'; // if needed
import 'package:gloria_marketing_flutter/src/core/services/background_location/background_location_tracking_service.dart';
import 'package:gloria_marketing_flutter/src/features/visits/data/rest/visit_api.dart';
import 'package:gloria_marketing_flutter/src/features/visits/infra/sync/visits_background_sync.dart';
import 'package:gloria_marketing_flutter/src/features/visits/infra/sync/visits_sync_coordinator.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/repositories/permissions_repository.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/repositories/catalog_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';

import 'package:yandex_maps_mapkit/init.dart' as ymk_init;

void main() async {
  // Ensure that Flutter bindings are initialized.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for intl package
  await initializeDateFormatting('uz', null);

  await ThemeController.I.restore();
  // Set up service locator
  await setupServiceLocator();

  // Wait for async services to be ready
  await sl.allReady();

  // Firebase init — best-effort. If google-services.json /
  // GoogleService-Info.plist are missing the call throws; we log and
  // continue so the rest of the app still boots. Notification flow
  // simply stays inert until the config lands. The check for
  // `Firebase.apps.isNotEmpty` protects against duplicate init via
  // workmanager isolates.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    // Background handler must be registered before runApp so the
    // isolate spawned by FCM finds it. Top-level function lives in
    // push_handler_service.dart.
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);
    if (kDebugMode) {
      debugPrint('[Main] Firebase initialised');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint(
        '[Main] Firebase initialise SKIPPED ($e). '
        'Notifications will stay offline until '
        'google-services.json / GoogleService-Info.plist is provisioned.',
      );
    }
  }

  // Initialize Database — required by AppStartGuard's downstream callers
  // and by the very first route, so this stays eager.
  await sl<DatabaseHelper>().database;

  // Initialize connectivity monitor BEFORE runApp so the very first
  // frame of the home page reads an accurate `isConnected` value via
  // the StreamBuilder's `initialData`. If we deferred this (as the
  // legacy bootstrap did), the AppBar would always render with the
  // offline badge on cold-start regardless of real network state.
  try {
    await sl<ConnectivityMonitorService>().initialize();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Main] Error initializing connectivity monitor: $e');
    }
  }

  // Load PackageInfo + DeviceInfo BEFORE the first V2 call so the
  // `X-App-*` headers carry real values. The locator already exposes a
  // [VersionAppInfo.empty] sentinel; we swap it for the real snapshot
  // here. See docs/integration-prompts/mobile-app-version-passport.md §2.
  try {
    final info = await VersionAppInfo.load();
    if (sl.isRegistered<VersionAppInfo>()) {
      sl.unregister<VersionAppInfo>();
    }
    sl.registerSingleton<VersionAppInfo>(info);
    if (kDebugMode) {
      debugPrint(
        '[Main] VersionAppInfo ready: ${info.packageName} '
        '${info.platform} ${info.appVersion}+${info.buildNumber}',
      );
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Main] VersionAppInfo load failed: $e');
    }
  }

  // Run the splash version-check BEFORE AppStartGuard so a blocked or
  // maintenance state short-circuits the whole login/refresh dance.
  // Failure here is fail-open: if the endpoint is unreachable AND no
  // cached gate exists, the app proceeds with the normal start flow.
  VersionGateResponse? pendingSoftUpdate;
  VersionGateResponse? blockingGate;
  try {
    final locale = sl<SharedPreferencesService>().getUserSelectedLanguageCode() ?? 'uz';
    final gate = await sl<VersionGateService>().checkOnStartup(locale: locale);
    if (gate != null) {
      if (gate.status.blocksApp) {
        blockingGate = gate;
      } else if (gate.status.wireValue == 'soft_update') {
        final dismissed = await sl<VersionGateService>().isSoftUpdateDismissed();
        if (!dismissed) pendingSoftUpdate = gate;
      }
      if (kDebugMode) {
        debugPrint('[Main] VersionGate → ${gate.status.wireValue}');
      }
    } else if (kDebugMode) {
      debugPrint('[Main] VersionGate → null (offline + no cache)');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Main] VersionGate error (fail-open): $e');
    }
  }

  // Determine the initial route via the new AppStartGuard. The legacy
  // AppAccessControl/TimeVerification flow has been replaced — see
  // `app_start_guard.dart` for the decision tree.
  String initialRouteName = AppRouter.loginRoute;
  Object? initialRouteArguments;
  if (blockingGate != null) {
    initialRouteName = AppRouter.versionGateRoute;
    initialRouteArguments = blockingGate;
  } else {
    try {
      final guard = sl<AppStartGuard>();
      final result = await guard.decide();
      if (result.decision == StartDecision.showHome) {
        initialRouteName = AppRouter.mainAgentScreenRoute;
      } else {
        initialRouteName = AppRouter.loginRoute;
      }
      if (kDebugMode) {
        debugPrint('[Main] AppStartGuard → ${result.decision} (reason=${result.reason?.runtimeType})');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Main] AppStartGuard error (defaulting to login): $e');
      }
    }
  }

  // Render the first frame ASAP. Everything that does not influence the
  // initial route (notification cache, FCM wiring, MapKit, background
  // location, WorkManager re-register, debug health-check) is deferred
  // to a fire-and-forget bootstrap that runs after runApp().
  runApp(App(
    initialRoute: initialRouteName,
    initialRouteArguments: initialRouteArguments,
    pendingSoftUpdate: pendingSoftUpdate,
  ));

  unawaited(_runDeferredBootstrap());
}

/// Non-critical startup work moved off the cold-start critical path.
/// Each block keeps its own try/catch so a failure in one stage does
/// not block the others. Order is preserved from the original `main()`
/// so any implicit dependencies (e.g. PushHandler reading notification
/// preferences) still see the same sequencing.
Future<void> _runDeferredBootstrap() async {
  // Hydrate the notification cache from sqflite so the bell badge
  // shows the correct count. Best-effort.
  try {
    await sl<NotificationRepository>().bootstrap();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Main] Notification cache bootstrap skipped: $e');
    }
  }

  // Load notification preferences BEFORE the push handler initialises
  // Android channels — the channel shape is derived from the preference
  // snapshot.
  try {
    await sl<NotificationPreferencesService>().bootstrap();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Main] Notification preferences bootstrap skipped: $e');
    }
  }

  // Wire FCM listeners (foreground / background / terminated tap).
  try {
    final pushHandler = sl<PushHandlerService>();
    pushHandler.onTap = NotificationTapRouter.handleRemoteMessage;
    await pushHandler.init();
    final tokenService = sl<TokenService>();
    if (tokenService.hasValidV2Token()) {
      unawaited(sl<FcmTokenService>().registerOnLogin());
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Main] Push handler setup skipped: $e');
    }
  }

  // Initialize Gemini API key (default for development).
  try {
    final apiKeyService = sl<ApiKeyService>();
    final hasGeminiKey = await apiKeyService.hasApiKey(ApiKeyService.geminiApiKey);
    if (!hasGeminiKey) {
      // TODO: Replace with server-provided key in production
      const defaultGeminiKey = 'AIzaSyDeIApWRmFwNOr5pQVvs_xwba0woIS3xYE';
      await apiKeyService.storeApiKey(ApiKeyService.geminiApiKey, defaultGeminiKey);
      if (kDebugMode) {
        debugPrint('[Main] Gemini API key initialized with default');
      }
    } else {
      if (kDebugMode) {
        debugPrint('[Main] Gemini API key already configured');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Main] Error initializing Gemini API key: $e');
    }
  }

  // Note: ConnectivityMonitorService is now initialised before runApp()
  // so the home page's offline-badge StreamBuilder reads an accurate
  // initial value. See the corresponding block above in `main()`.

  // Debug-only: log resolved V2 URL and fire a single liveness probe.
  if (kDebugMode) {
    debugPrint('[CONFIG] V2_BASE_URL=${TokenService.v2BaseUrl}');
    sl<HealthCheckService>().pingV2().then((result) {
      if (result.ok) {
        debugPrint(
          '[HEALTH] V2 backend reachable in ${result.latency?.inMilliseconds}ms',
        );
      } else {
        debugPrint('[HEALTH] V2 backend UNREACHABLE: ${result.errorMessage}');
      }
    });
  }

  // Check (don't request) location permission status on app start.
  try {
    final permissionManager = sl<PermissionManager>();
    await permissionManager.checkLocationPermission();
    final serviceEnabled = await permissionManager.isLocationServiceEnabled();
    if (!serviceEnabled && kDebugMode) {
      debugPrint('Location services are disabled on app start');
    }
  } catch (_) {
    // App will handle permissions on demand.
  }

  // Resolve Yandex MapKit API key and initialize MapKit. The login and
  // main-agent landing screens do not embed maps, so this can run after
  // the first frame without affecting initial UI.
  try {
    final apiKey = await _ApiKeyProvider().resolveApiKey();
    if (kDebugMode) {
      debugPrint('Your API key: $apiKey');
    }
    await ymk_init.initMapkit(apiKey: apiKey);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Main] MapKit init error: $e');
    }
  }

  // Background location tracking — startTracking() is idempotent
  // (returns early if _isTrackingActive), so the AppLifecycleState
  // resume callback in _AppState cannot create a duplicate timer.
  try {
    final backgroundLocationService = sl<BackgroundLocationTrackingService>();
    await backgroundLocationService.initialize();
    final prefs = sl<SharedPreferencesService>();
    final userCode = prefs.getUserCode();
    if (userCode != null && userCode.isNotEmpty) {
      await backgroundLocationService.startTracking();
      if (kDebugMode) {
        debugPrint('BackgroundLocationTracking: Started for user $userCode');
        debugPrint('BackgroundLocationTracking: Interval: ${backgroundLocationService.currentIntervalSeconds}s');
      }
    } else if (kDebugMode) {
      debugPrint('BackgroundLocationTracking: User not logged in, tracking not started');
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('BackgroundLocationTracking: Initialization error: $e');
      debugPrint('BackgroundLocationTracking: Stack trace: $stackTrace');
    }
  }

  // Background data sync — re-register WorkManager task if the user
  // previously enabled it.
  try {
    final prefs = sl<SharedPreferencesService>();
    if (prefs.isBgSyncEnabled()) {
      final dataSyncService = sl<DataSyncService>();
      await dataSyncService.toggleBackgroundSync(true);
      if (kDebugMode) {
        final intervalMinutes = prefs.getBgSyncCustomMinutes() ?? (prefs.getBgSyncInterval() * 60);
        debugPrint('BackgroundDataSync: Re-registered on app startup');
        debugPrint('BackgroundDataSync: Interval: $intervalMinutes minutes');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('BackgroundDataSync: Error re-registering: $e');
    }
  }

  // Visits v2 — hit the auth-free `/server-time/` endpoint first so the
  // ServerTimeService captures the clock-drift baseline before any
  // envelope is timestamped. The endpoint replies with an empty body and
  // an `X-Server-Time` header; the response interceptor records it via
  // `ServerTimeService.recordServerTime`. Failure here is fine —
  // ClockDriftValidator falls back to drift=0 and only blocks visits
  // when the user's clock is *clearly* skewed.
  try {
    await sl<VisitApi>().syncServerTime();
    if (kDebugMode) {
      debugPrint('[Visits v2] Server time captured');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Visits v2] Server time sync skipped: $e');
    }
  }

  // Visits v2 — warm permissions/catalog cache so the feature flag and
  // task list are available the moment the user opens a trading point.
  // Best-effort: offline cache or empty state falls back to SOAP path.
  try {
    final tokenService = sl<TokenService>();
    if (tokenService.hasValidV2Token()) {
      await sl<PermissionsRepository>().getCurrent(forceRefresh: true);
      await sl<CatalogRepository>().getCurrent(forceRefresh: true);
      if (kDebugMode) {
        debugPrint('[Visits v2] Permissions + catalog warmed');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Visits v2] Permissions/catalog warm-up skipped: $e');
    }
  }

  // Visits v2 — foreground sync coordinator (lifecycle + connectivity +
  // 60s timer) and Workmanager background sync (15-min, network-required).
  // Both are idempotent: re-running on hot restart no-ops.
  try {
    final coordinator = VisitsSyncCoordinator(
      dispatcher: sl(),
      photoUploader: sl(),
      connectivity: sl(),
    );
    await coordinator.start();
    if (!sl.isRegistered<VisitsSyncCoordinator>()) {
      sl.registerSingleton<VisitsSyncCoordinator>(coordinator);
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Visits v2] Sync coordinator start failed: $e');
    }
  }

  try {
    await VisitsBackgroundSync.schedule();
    if (kDebugMode) {
      debugPrint('[Visits v2] Workmanager scheduled (15min, network-required)');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Visits v2] Workmanager schedule skipped: $e');
    }
  }
}

class _ApiKeyProvider {
  static const _prefsKey = 'yandex_maps_api_key';

  // ⚠️ BACKUP KEY — for testing only!
  // TODO: REMOVE IN PROD! Do not store API key in code.
  // In the future, this fallback will be completely removed.
  static const _fallbackHardcodedKey = 'bf2fb1fa-dd2f-4d56-8ea5-3f9d6350ea67';

  Future<String> resolveApiKey() async {
    try {
      final fromLocal = await _getFromLocal();
      if (fromLocal != null && fromLocal.trim().isNotEmpty) {
        debugPrint('[API KEY] Found in local storage.');
        return fromLocal;
      }

      final fromServer = await _getFromServerPlaceholder();
      if (fromServer != null && fromServer.trim().isNotEmpty) {
        debugPrint('[API KEY] Received from "server" placeholder and saved.');
        await _saveToLocal(fromServer);
        return fromServer;
      }

      debugPrint('[API KEY] Using HARD-CODED FALLBACK (test only, remove in prod).');
      return _fallbackHardcodedKey;
    } catch (e, st) {
      debugPrint('[API KEY] resolve error: $e\n$st');
      // Even if there's an error, return fallback key for demo to work.
      return _fallbackHardcodedKey;
    }
  }

  Future<String?> _getFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefsKey);
    } catch (e) {
      debugPrint('[API KEY] local read error: $e');
      return null;
    }
  }

  Future<void> _saveToLocal(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, key);
    } catch (e) {
      debugPrint('[API KEY] local write error: $e');
    }
  }

  /// "Server request" — placeholder for now (will be replaced with HTTP in the future).
  /// If null is returned for now, fallback is used.
  Future<String?> _getFromServerPlaceholder() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // TODO: Real backend request will be placed here (HTTP, auth, etc.).
    // For now null -> fallback works.
    final dataSyncService = sl<DataSyncService>();
    final result = await dataSyncService.syncMapTokens();
    var token = result['yandexToken'];
    if (token == null) {
      return null;
    }
    return token;
  }
}



class App extends StatefulWidget {
  /// Initial route resolved by [AppStartGuard] in `main()` before `runApp`.
  final String initialRoute;

  /// Optional argument forwarded to [AppRouter.generateRoute] for the
  /// initial route — currently used to hand the [VersionGateResponse]
  /// payload to [AppRouter.versionGateRoute].
  final Object? initialRouteArguments;

  /// Soft-update payload resolved at cold start. If non-null, the soft-update
  /// dialog is surfaced once the navigator is mounted.
  final VersionGateResponse? pendingSoftUpdate;

  const App({
    super.key,
    this.initialRoute = AppRouter.loginRoute,
    this.initialRouteArguments,
    this.pendingSoftUpdate,
  });

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  final LocaleProvider _localeProvider = LocaleProvider();

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    // App lifecycle events'ni kuzatish uchun observer qo'shish
    WidgetsBinding.instance.addObserver(this);
    _scheduleSoftUpdateDialog();
  }

  /// If main() resolved a soft-update payload, show the dismissable dialog
  /// once the navigator finishes its first build. Best-effort: a missing
  /// VersionGateService or missing context simply skips the dialog.
  void _scheduleSoftUpdateDialog() {
    final pending = widget.pendingSoftUpdate;
    if (pending == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ctx = AppRouter.navigatorKey.currentContext;
      if (ctx == null) return;
      if (!sl.isRegistered<VersionGateService>()) return;
      try {
        await showUpdateAvailableDialog(
          ctx,
          payload: pending,
          service: sl<VersionGateService>(),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Main] soft-update dialog skipped: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    // Observer'ni olib tashlash
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// App lifecycle state o'zgarganda chaqiriladi
  /// Bu metod ilova fonga o'tganda ham location tracking ishlashini ta'minlaydi
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (kDebugMode) {
      debugPrint('AppLifecycleState changed: $state');
    }

    // App lifecycle holatiga qarab harakat qilish
    switch (state) {
      case AppLifecycleState.resumed:
        // Ilova qayta aktiv bo'lganda
        // Agar tracking to'xtatilgan bo'lsa, qayta boshlash
        _ensureBackgroundLocationTracking();
        break;
      case AppLifecycleState.paused:
        // Ilova fonga o'tganda
        // Tracking davom etadi (Timer va Position stream ishlashda davom etadi)
        if (kDebugMode) {
          debugPrint('App paused - background location tracking continues');
        }
        break;
      case AppLifecycleState.inactive:
        // Ilova inactive holatda
        break;
      case AppLifecycleState.detached:
        // Ilova detached holatda
        break;
      case AppLifecycleState.hidden:
        // Ilova yashiringan holatda
        break;
    }
  }

  /// Background location tracking ishlayotganligini tekshirish va zarur bo'lsa boshlash.
  ///
  /// `startTracking()` permission so'ramaydi (auto-resume loop'ini
  /// oldini olish uchun) — shuning uchun bu yerda faqat
  /// `true` qaytarsa "restarted" log'ini bosamiz. False qaytsa
  /// (permission yo'q, login yo'q, init muvaffaqiyatsiz) jim
  /// turamiz — aks holda har resume'da bir xil "permission not
  /// granted" log'i takrorlanadi.
  Future<void> _ensureBackgroundLocationTracking() async {
    try {
      final backgroundLocationService = sl<BackgroundLocationTrackingService>();
      final prefs = sl<SharedPreferencesService>();
      final userCode = prefs.getUserCode();

      if (userCode == null || userCode.isEmpty) return;
      if (backgroundLocationService.isTrackingActive) return;

      final started = await backgroundLocationService.startTracking();
      if (started && kDebugMode) {
        debugPrint('BackgroundLocationTracking: Restarted after app resume');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BackgroundLocationTracking: Error ensuring tracking: $e');
      }
    }
  }

  Future<void> _initializeLocale() async {
    await _localeProvider.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider(create: (context) => sl<AuthBloc>()),
        ChangeNotifierProvider.value(value: _localeProvider),
        Provider<SharedPreferencesService>.value(
          value: sl<SharedPreferencesService>(),
        ),
        Provider<DataSyncService>.value(
          value: sl<DataSyncService>(),
        ),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.I.mode,
        builder: (context, themeMode, _) {
          return Consumer<LocaleProvider>(
            builder: (context, localeProvider, _) {
              return MaterialApp(
                navigatorKey: AppRouter.navigatorKey,
                scaffoldMessengerKey: AppRouter.scaffoldMessengerKey,
                title: 'SelUp',
                debugShowCheckedModeBanner: false,
                theme: appLight,
                darkTheme: appDark,
                themeMode: themeMode,
                locale: localeProvider.locale,
                onGenerateRoute: AppRouter.generateRoute,
                initialRoute: widget.initialRoute,
                // Wrap every page in the in-app banner host so foreground
                // pushes (FCM onMessage) can draw a transient banner via
                // the global overlay. Tap routes through the deep-link
                // router; the banner sets `onForegroundBanner` once the
                // overlay is available.
                builder: (context, child) {
                  // PermissionGate is mounted above the banner host so
                  // every route — login, home, settings — is shielded
                  // until location permission, GPS, and notification
                  // permission are all granted. State is preserved
                  // across route changes; lifecycle re-checks happen
                  // on every resume.
                  return PermissionGate(
                    child: _BannerHostBridge(
                      child: child ?? const SizedBox(),
                    ),
                  );
                },
                // Default Navigator.defaultGenerateInitialRoutes initialRoute'ni
                // '/' bo'yicha bo'laklab har bir prefix uchun route push qiladi.
                // loginRoute = '/' bo'lgani uchun '/main-agent' bilan ishga
                // tushganda stack [LoginPage, MainAgentScreen] bo'lib qoladi va
                // back tugmasi LoginPage'ga olib chiqadi. Faqat bitta initial
                // route push qilamiz. The optional `initialRouteArguments`
                // hands the VersionGate payload through for the blocked path.
                onGenerateInitialRoutes: (initialRoute) => [
                  AppRouter.generateRoute(RouteSettings(
                    name: initialRoute,
                    arguments: widget.initialRouteArguments,
                  )),
                ],
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              );
            },
          );
        },
      ),
    );
  }
}

/// Glue between [MaterialApp.builder] and the [InAppBannerHost]. The
/// host needs a [BuildContext] under the navigator so it can read the
/// root overlay; we register the foreground-banner callback on the
/// PushHandlerService once the host is mounted and tear it down on
/// dispose.
class _BannerHostBridge extends StatefulWidget {
  final Widget child;

  const _BannerHostBridge({required this.child});

  @override
  State<_BannerHostBridge> createState() => _BannerHostBridgeState();
}

class _BannerHostBridgeState extends State<_BannerHostBridge> {
  @override
  Widget build(BuildContext context) {
    return InAppBannerHost(
      onTap: (deepLink, notificationId) {
        NotificationTapRouter.handleDeepLink(
          context,
          deepLink: deepLink,
          notificationId: notificationId,
        );
      },
      child: Builder(
        builder: (ctx) {
          _wireForegroundCallback(ctx);
          return widget.child;
        },
      ),
    );
  }

  void _wireForegroundCallback(BuildContext ctx) {
    try {
      final pushHandler = sl<PushHandlerService>();
      pushHandler.onForegroundBanner = (message) {
        final controller = InAppBannerController.maybeOf(ctx);
        if (controller != null) {
          controller.show(message);
        }
      };
    } catch (_) {
      // PushHandlerService may not be registered yet during early
      // boot — the next rebuild after service-locator setup will
      // attach the callback.
    }
  }
}
