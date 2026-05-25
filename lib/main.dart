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

/// Completes when Firebase, DB, connectivity, and VersionAppInfo are ready.
/// `_AppState._runStartupChecks()` awaits this before issuing network calls.
late final Future<void> postRunAppInitFuture;

void main() async {
  // Ensure that Flutter bindings are initialized.
  WidgetsFlutterBinding.ensureInitialized();

  // ─── MINIMAL PRE-RUNAPP WORK ──────────────────────────────────────
  // Service locator + allReady are guarded by a try/catch + timeout so
  // that a corrupted cache or a hung platform channel NEVER prevents
  // runApp() from being called. Without this, the app stays on a blank
  // white Android surface forever (no Flutter frame is rendered).
  try {
    await initializeDateFormatting('uz', null);
    await ThemeController.I.restore();
    await setupServiceLocator();
    // allReady() waits for every registerSingletonAsync to complete.
    // LocationService's GPS warm-up and ApiKeyService's init can each
    // take several seconds on a cold device, and corrupt SharedPrefs
    // can make them hang indefinitely → timeout as a safety net.
    await sl.allReady().timeout(const Duration(seconds: 8));
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Main] Pre-runApp init error (proceeding anyway): $e');
    }
  }

  // ─── RENDER FIRST FRAME IMMEDIATELY ───────────────────────────────
  runApp(const App());

  // ─── POST-RUNAPP INIT ─────────────────────────────────────────────
  // Heavy I/O (Firebase, DB, connectivity, PackageInfo) runs after the
  // first frame is on screen. _AppState._runStartupChecks() awaits
  // this future before issuing network calls that depend on DB /
  // connectivity / VersionAppInfo.
  postRunAppInitFuture = _runPostRunAppInit();
  unawaited(_runDeferredBootstrap());
}

/// Initialisation that previously blocked `runApp()`. Now runs after the
/// first frame so the splash screen is visible immediately. Each block
/// is independent and runs in parallel via `Future.wait`.
Future<void> _runPostRunAppInit() async {
  await Future.wait<void>([
    // Firebase init — best-effort.
    _safe(() async {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);
      if (kDebugMode) debugPrint('[Main] Firebase initialised');
    }, tag: 'Firebase init'),

    // Database — needed by AppStartGuard and first route.
    _safe(() async {
      await sl<DatabaseHelper>().database;
    }, tag: 'Database init'),

    // Connectivity monitor.
    _safe(() async {
      await sl<ConnectivityMonitorService>().initialize();
    }, tag: 'Connectivity monitor'),

    // PackageInfo + DeviceInfo for X-App-* headers.
    _safe(() async {
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
    }, tag: 'VersionAppInfo'),
  ]);
}

/// Non-critical startup work moved off the cold-start critical path.
/// Each block keeps its own try/catch so a failure in one stage does
/// not block the others.
///
/// Parallelised into independent groups to reduce total wall-time and
/// frame drops (previously ~10 sequential awaits caused 147+ skipped
/// frames).
///
/// NOTE: FCM listener wiring and notification preferences bootstrap are
/// now handled inside `_AppState._runStartupChecks()`.
Future<void> _runDeferredBootstrap() async {
  // Wait for DB, connectivity, etc. to be ready before using services
  // that depend on them. Timeout so a hung init doesn't block forever.
  try {
    await postRunAppInitFuture.timeout(const Duration(seconds: 15));
  } catch (_) {}

  // ── WAVE 1: Independent local work — run in parallel ────────────
  await Future.wait<void>([
    // Hydrate the notification cache from sqflite so the bell badge
    // shows the correct count. Best-effort.
    _safe(() => sl<NotificationRepository>().bootstrap(),
        tag: 'Notification cache bootstrap'),

    // Initialize Gemini API key (default for development).
    _safe(() async {
      final apiKeyService = sl<ApiKeyService>();
      final hasGeminiKey =
          await apiKeyService.hasApiKey(ApiKeyService.geminiApiKey);
      if (!hasGeminiKey) {
        // TODO: Replace with server-provided key in production
        const defaultGeminiKey = 'AIzaSyDeIApWRmFwNOr5pQVvs_xwba0woIS3xYE';
        await apiKeyService.storeApiKey(
            ApiKeyService.geminiApiKey, defaultGeminiKey);
        if (kDebugMode) {
          debugPrint('[Main] Gemini API key initialized with default');
        }
      } else if (kDebugMode) {
        debugPrint('[Main] Gemini API key already configured');
      }
    }, tag: 'Gemini API key'),

    // Check (don't request) location permission status on app start.
    _safe(() async {
      final permissionManager = sl<PermissionManager>();
      await permissionManager.checkLocationPermission();
      final serviceEnabled =
          await permissionManager.isLocationServiceEnabled();
      if (!serviceEnabled && kDebugMode) {
        debugPrint('Location services are disabled on app start');
      }
    }, tag: 'Location permission check'),
  ]);

  // Debug-only: log resolved V2 URL and fire a single liveness probe.
  // Fire-and-forget — does NOT block the boot chain.
  if (kDebugMode) {
    debugPrint('[CONFIG] V2_BASE_URL=${TokenService.v2BaseUrl}');
    unawaited(sl<HealthCheckService>().pingV2().then((result) {
      if (result.ok) {
        debugPrint(
          '[HEALTH] V2 backend reachable in ${result.latency?.inMilliseconds}ms',
        );
      } else {
        debugPrint('[HEALTH] V2 backend UNREACHABLE: ${result.errorMessage}');
      }
    }));
  }

  // ── WAVE 2: Heavier I/O + network — run in parallel ────────────
  await Future.wait<void>([
    // Resolve Yandex MapKit API key and initialize MapKit.
    _safe(() async {
      final apiKey = await _ApiKeyProvider().resolveApiKey();
      if (kDebugMode) debugPrint('Your API key: $apiKey');
      await ymk_init.initMapkit(apiKey: apiKey);
    }, tag: 'MapKit init'),

    // Background location tracking.
    _safe(() async {
      final backgroundLocationService =
          sl<BackgroundLocationTrackingService>();
      await backgroundLocationService.initialize();
      final prefs = sl<SharedPreferencesService>();
      final userCode = prefs.getUserCode();
      if (userCode != null && userCode.isNotEmpty) {
        await backgroundLocationService.startTracking();
        if (kDebugMode) {
          debugPrint(
              'BackgroundLocationTracking: Started for user $userCode');
          debugPrint(
              'BackgroundLocationTracking: Interval: ${backgroundLocationService.currentIntervalSeconds}s');
        }
      } else if (kDebugMode) {
        debugPrint(
            'BackgroundLocationTracking: User not logged in, tracking not started');
      }
    }, tag: 'Background location tracking'),

    // Background data sync — re-register WorkManager task.
    _safe(() async {
      final prefs = sl<SharedPreferencesService>();
      if (prefs.isBgSyncEnabled()) {
        final dataSyncService = sl<DataSyncService>();
        await dataSyncService.toggleBackgroundSync(true);
        if (kDebugMode) {
          final intervalMinutes = prefs.getBgSyncCustomMinutes() ??
              (prefs.getBgSyncInterval() * 60);
          debugPrint('BackgroundDataSync: Re-registered on app startup');
          debugPrint('BackgroundDataSync: Interval: $intervalMinutes minutes');
        }
      }
    }, tag: 'Background data sync'),

    // Visits v2 — server time capture.
    _safe(() async {
      await sl<VisitApi>().syncServerTime();
      if (kDebugMode) debugPrint('[Visits v2] Server time captured');
    }, tag: 'Visits server time'),

    // Visits v2 — warm permissions/catalog cache.
    _safe(() async {
      final tokenService = sl<TokenService>();
      if (tokenService.hasValidV2Token()) {
        await sl<PermissionsRepository>().getCurrent(forceRefresh: true);
        await sl<CatalogRepository>().getCurrent(forceRefresh: true);
        if (kDebugMode) {
          debugPrint('[Visits v2] Permissions + catalog warmed');
        }
      }
    }, tag: 'Visits permissions/catalog warm-up'),
  ]);

  // ── WAVE 3: Depends on location tracking being initialised ──────
  await Future.wait<void>([
    _safe(() async {
      final coordinator = VisitsSyncCoordinator(
        dispatcher: sl(),
        photoUploader: sl(),
        connectivity: sl(),
      );
      await coordinator.start();
      if (!sl.isRegistered<VisitsSyncCoordinator>()) {
        sl.registerSingleton<VisitsSyncCoordinator>(coordinator);
      }
    }, tag: 'Visits sync coordinator'),

    _safe(() async {
      await VisitsBackgroundSync.schedule();
      if (kDebugMode) {
        debugPrint(
            '[Visits v2] Workmanager scheduled (15min, network-required)');
      }
    }, tag: 'Visits background sync schedule'),
  ]);
}

/// Fire-and-forget wrapper: runs [fn], catches any error, logs in debug.
Future<void> _safe(Future<void> Function() fn, {required String tag}) async {
  try {
    await fn();
  } catch (e) {
    if (kDebugMode) debugPrint('[Main] $tag skipped: $e');
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
    // TODO: Real backend request will be placed here (HTTP, auth, etc.).
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
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  final LocaleProvider _localeProvider = LocaleProvider();

  /// True once the deferred startup checks (VersionGate, AppStartGuard,
  /// FCM wiring) have completed and the resolved route is known.
  bool _startupDone = false;
  String _resolvedRoute = AppRouter.loginRoute;
  Object? _resolvedRouteArguments;
  VersionGateResponse? _pendingSoftUpdate;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    // App lifecycle events'ni kuzatish uchun observer qo'shish
    WidgetsBinding.instance.addObserver(this);
    // Run network-dependent startup checks in the background so the
    // first frame renders immediately (branded splash instead of white).
    _runStartupChecks();
  }

  /// Network-dependent startup checks that were previously blocking
  /// `main()` before `runApp()`. Now they run after the first frame
  /// so the user sees a loading screen instead of a white screen.
  ///
  /// CRITICAL: The entire body is wrapped in try/catch so that ANY
  /// failure still sets `_startupDone = true` and navigates to login.
  /// Without this, an unhandled error leaves the splash screen forever.
  Future<void> _runStartupChecks() async {
    String initialRouteName = AppRouter.loginRoute;
    Object? initialRouteArguments;
    VersionGateResponse? pendingSoftUpdate;

    try {
      // Wait for Firebase, DB, connectivity, and VersionAppInfo to be
      // ready. Timeout guards against a hung platform channel or locked
      // DB file leaving the splash screen visible forever.
      await postRunAppInitFuture.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('[Main] postRunAppInit timed out after 10s, proceeding anyway');
          }
        },
      );

      // 1. Version gate check (network call, 10s connect timeout).
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

      // 2. Determine the initial route via AppStartGuard.
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

      // 3. Wire FCM foreground/tap listeners.
      try {
        await sl<NotificationPreferencesService>().bootstrap();
        final pushHandler = sl<PushHandlerService>();
        pushHandler.onTap = NotificationTapRouter.handleRemoteMessage;
        await pushHandler.init();
        final tokenService = sl<TokenService>();
        if (tokenService.hasValidV2Token()) {
          unawaited(sl<FcmTokenService>().registerOnLogin());
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Main] Push handler early init skipped: $e');
        }
      }
    } catch (e) {
      // Catch-all: any unhandled error still lets the app proceed to
      // login rather than being stuck on the splash screen forever.
      if (kDebugMode) {
        debugPrint('[Main] _runStartupChecks fatal error (falling back to login): $e');
      }
    }

    if (!mounted) return;

    setState(() {
      _resolvedRoute = initialRouteName;
      _resolvedRouteArguments = initialRouteArguments;
      _pendingSoftUpdate = pendingSoftUpdate;
      _startupDone = true;
    });

    _scheduleSoftUpdateDialog();
  }

  /// If startup resolved a soft-update payload, show the dismissable dialog
  /// once the navigator finishes its first build. Best-effort: a missing
  /// VersionGateService or missing context simply skips the dialog.
  void _scheduleSoftUpdateDialog() {
    final pending = _pendingSoftUpdate;
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
        // Background isolat DB ga yozgan push stublarini stream ga chiqarish
        // va API dan yangi notificationlarni yuklash.
        _syncNotificationsOnResume();
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

  void _syncNotificationsOnResume() {
    try {
      final repo = sl<NotificationRepository>();
      // 1) Immediately reflect any rows the background isolate wrote to DB.
      unawaited(repo.refreshFromCache());
      // 2) Pull fresh data from the backend (best-effort, non-blocking).
      unawaited(repo.syncIncremental());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Main] _syncNotificationsOnResume error: $e');
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
              // While startup checks are still running, show a branded
              // splash screen so the user never sees a blank white page.
              if (!_startupDone) {
                return MaterialApp(
                  title: 'SelUp',
                  debugShowCheckedModeBanner: false,
                  theme: appLight,
                  darkTheme: appDark,
                  themeMode: themeMode,
                  locale: localeProvider.locale,
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: const _SplashLoadingScreen(),
                );
              }

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
                initialRoute: _resolvedRoute,
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
                    arguments: _resolvedRouteArguments,
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

/// Branded splash screen shown while deferred startup checks
/// (VersionGate, AppStartGuard, FCM wiring) are running in the
/// background. Replaces the white screen the user previously saw.
class _SplashLoadingScreen extends StatelessWidget {
  const _SplashLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icon/selup_icon.png',
              width: 96,
              height: 96,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: cs.primary,
              ),
            ),
          ],
        ),
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
