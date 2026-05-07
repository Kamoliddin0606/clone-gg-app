import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'package:gloria_marketing_flutter/src/core/widgets/permission_dialog.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gloria_marketing_flutter/src/theme/theme_controller.dart';
import 'package:gloria_marketing_flutter/src/theme/theme_schemes.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart'; // if needed
import 'package:gloria_marketing_flutter/src/core/services/background_location/background_location_tracking_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';
import 'dart:math' show sin, cos, sqrt, asin, pi;

import 'package:yandex_maps_mapkit/init.dart' as ymk_init;

// YandexMap widget and MapWindow APIs
import 'package:yandex_maps_mapkit/yandex_map.dart';

// MapKit core APIs (MapKit, MapInputListener, UserLocationLayer, LocationManager, Point, CameraPosition, etc.)
import 'package:yandex_maps_mapkit/mapkit.dart' as mk;

import 'package:yandex_maps_mapkit/mapkit_factory.dart' as mkf;

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

  // TODO: Initialize Firebase
  // await Firebase.initializeApp();

  // Initialize Database
  await sl<DatabaseHelper>().database;

  // Initialize Gemini API key
  // In production, this should be fetched from server
  try {
    final apiKeyService = sl<ApiKeyService>();
    
    // Check if Gemini API key exists, if not - set default
    final hasGeminiKey = await apiKeyService.hasApiKey(ApiKeyService.geminiApiKey);
    
    if (!hasGeminiKey) {
      // Use default key for development
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

  // Initialize connectivity monitor (still needed by AppStartGuard and UI).
  try {
    final connectivityMonitor = sl<ConnectivityMonitorService>();
    await connectivityMonitor.initialize();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Main] Error initializing connectivity monitor: $e');
    }
  }

  // Debug-only: log the resolved V2 backend URL and fire a single liveness
  // probe so engineers see misconfigured `--dart-define` values immediately.
  // Release builds skip both — no extra request, no log noise.
  if (kDebugMode) {
    debugPrint('[CONFIG] V2_BASE_URL=${TokenService.v2BaseUrl}');
    // Fire-and-forget; we don't want to block the boot sequence on it.
    // ignore: unawaited_futures
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

  // Determine the initial route via the new AppStartGuard. The legacy
  // AppAccessControl/TimeVerification flow has been replaced — see
  // `app_start_guard.dart` for the decision tree.
  String initialRouteName = AppRouter.loginRoute;
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

  // Initialize Permission Manager (lazy singleton, no need for isReady)
  // PermissionManager is ready when accessed

  // Initialize critical permissions on app start
  try {
    final permissionManager = sl<PermissionManager>();
    // Check location permission status on app start (doesn't request, just checks)
    await permissionManager.checkLocationPermission();

    // Also check location services status
    final serviceEnabled = await permissionManager.isLocationServiceEnabled();
    if (!serviceEnabled && kDebugMode) {
      debugPrint('Location services are disabled on app start');
    }
  } catch (e) {
    // Permission check failed, continue without it
    // App will handle permissions when needed
  }
  final apiKey = await _ApiKeyProvider().resolveApiKey();
  if (kDebugMode) {
    debugPrint('Your API key: $apiKey');
  }
  await ymk_init.initMapkit(apiKey: apiKey);

  // =========================================================================
  // Background Location Tracking Service - fonda joylashuvni kuzatish
  // =========================================================================
  // Bu service ilova aktiv bo'lmasa ham ishlaydi va serverga location yuboradi.
  // LocationUpdateInterval serverdan olingan vaqt oralig'ida ishlaydi.
  try {
    final backgroundLocationService = sl<BackgroundLocationTrackingService>();
    await backgroundLocationService.initialize();
    
    // Agar user tizimga kirgan bo'lsa, tracking'ni boshlash
    final prefs = sl<SharedPreferencesService>();
    final userCode = prefs.getUserCode();
    if (userCode != null && userCode.isNotEmpty) {
      await backgroundLocationService.startTracking();
      if (kDebugMode) {
        debugPrint('BackgroundLocationTracking: Started for user $userCode');
        debugPrint('BackgroundLocationTracking: Interval: ${backgroundLocationService.currentIntervalSeconds}s');
      }
    } else {
      if (kDebugMode) {
        debugPrint('BackgroundLocationTracking: User not logged in, tracking not started');
      }
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('BackgroundLocationTracking: Initialization error: $e');
      debugPrint('BackgroundLocationTracking: Stack trace: $stackTrace');
    }
    // Xato bo'lsa ham ilova ishlashni davom ettiradi
  }

  // =========================================================================
  // Background Data Sync - avto sinxronizatsiya
  // =========================================================================
  // Agar foydalanuvchi avval background sync'ni yoqgan bo'lsa,
  // ilova qayta ishga tushganda WorkManager task'ni qayta ro'yxatga olish
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

  runApp(App(initialRoute: initialRouteName));
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

  const App({super.key, this.initialRoute = AppRouter.loginRoute});

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

  /// Background location tracking ishlayotganligini tekshirish va zarur bo'lsa boshlash
  Future<void> _ensureBackgroundLocationTracking() async {
    try {
      final backgroundLocationService = sl<BackgroundLocationTrackingService>();
      final prefs = sl<SharedPreferencesService>();
      final userCode = prefs.getUserCode();
      
      // Agar user login qilgan bo'lsa va tracking ishlamayotgan bo'lsa
      if (userCode != null && userCode.isNotEmpty && !backgroundLocationService.isTrackingActive) {
        await backgroundLocationService.startTracking();
        if (kDebugMode) {
          debugPrint('BackgroundLocationTracking: Restarted after app resume');
        }
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
