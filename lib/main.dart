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

  runApp(const App());
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
  const App({super.key});

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
                theme: appLight,
                darkTheme: appDark,
                themeMode: themeMode,
                locale: localeProvider.locale,
                onGenerateRoute: AppRouter.generateRoute,
                initialRoute: AppRouter.permissionCheckRoute,
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
