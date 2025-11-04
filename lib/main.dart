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
import 'package:gloria_marketing_flutter/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gloria_marketing_flutter/src/theme/theme_controller.dart';
import 'package:gloria_marketing_flutter/src/theme/theme_schemes.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart'; // agar kerak bo‘lsa
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';
import 'dart:math' show sin, cos, sqrt, asin, pi;

import 'package:yandex_maps_mapkit/init.dart' as ymk_init;

// YandexMap vidjeti va MapWindow APIlari
import 'package:yandex_maps_mapkit/yandex_map.dart';

// MapKit core APIlari (MapKit, MapInputListener, UserLocationLayer, LocationManager, Point, CameraPosition, va h.k.)
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
      print('Location services are disabled on app start');
    }
  } catch (e) {
    // Permission check failed, continue without it
    // App will handle permissions when needed
  }
  final apiKey = await _ApiKeyProvider().resolveApiKey();
  print('your api key: $apiKey');
  await ymk_init.initMapkit(apiKey: apiKey);
  // TODO: Initialize other services

  runApp(const App());
}
class _ApiKeyProvider {
  static const _prefsKey = 'yandex_maps_api_key';

  // ⚠️ ZAXIRA KALIT — faqat test uchun!
  // TODO: PROD’DA OLIB TASHLANG! API kalitni kodda saqlamang.
  // Kelajakda bu fallback butunlay olib tashlanadi.
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

      debugPrint(
          '[API KEY] Using HARD-CODED FALLBACK (test only, remove in prod).');
      return _fallbackHardcodedKey;
    } catch (e, st) {
      debugPrint('[API KEY] resolve error: $e\n$st');
      // Xatolik bo‘lsa ham, demo ishlashi uchun fallback kalitni qaytaramiz.
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

  /// "Server so‘rovi" — hozircha placeholder (kelajakda HTTP bilan almashtiriladi).
  /// Hozircha null qaytarsa, fallback ishlatiladi.
  Future<String?> _getFromServerPlaceholder() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // TODO: bu yerga haqiqiy backend so‘rovi qo‘yiladi (HTTP, auth, va h.k.).
    // Hozircha null — > fallback ishlaydi.
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

class _AppState extends State<App> {
  final LocaleProvider _localeProvider = LocaleProvider();

  @override
  void initState() {
    super.initState();
    _initializeLocale();
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
                title: 'SelUp',
                theme: appLight,
                darkTheme: appDark,
                themeMode: themeMode,
                locale: localeProvider.locale,
                onGenerateRoute: AppRouter.generateRoute,
                initialRoute: AppRouter.loginRoute,
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
