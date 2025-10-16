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

  // TODO: Initialize other services

  runApp(const App());
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
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.I.mode,
        builder: (context, themeMode, _) {
          return Consumer<LocaleProvider>(
            builder: (context, localeProvider, _) {
              return MaterialApp(
                title: 'Gloria Marketing',
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
