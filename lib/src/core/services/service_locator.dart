import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/network/api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/reports_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/report_data_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/telegram_bot_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/telegram_token_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/location_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/permission_manager.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_key_service.dart';

import 'package:gloria_marketing_flutter/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/visit_data_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/visit_step_data_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/photo_storage_service.dart';

import '../network/server_service.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // 1) SharedPreferences (ASYNC singleton)
  if (!sl.isRegistered<SharedPreferencesService>()) {
    sl.registerSingletonAsync<SharedPreferencesService>(
          () async => await SharedPreferencesService.getInstance(),
    );
  }
  await sl.isReady<SharedPreferencesService>();

  // 2) ServerService (ASYNC singleton) — prefs’ga tayanadi
  if (!sl.isRegistered<ServerService>()) {
    sl.registerSingletonAsync<ServerService>(() async {
      final srv = ServerService(sl<SharedPreferencesService>());
      await srv.restore(); // tanlangan serverni tiklash
      return srv;
    });
  }
  await sl.isReady<ServerService>();

  // 3) Pastdagilar endi xavfsiz
  if (!sl.isRegistered<DatabaseHelper>()) {
    sl.registerLazySingleton(() => DatabaseHelper());
  }
  if (!sl.isRegistered<Dio>()) {
    sl.registerLazySingleton(() => Dio());
  }
  if (!sl.isRegistered<ApiService>()) {
    sl.registerLazySingleton(() => ApiService());
    // Agar ApiService serverga bog‘lanishi kerak bo‘lsa:
    // sl.registerLazySingleton(() => ApiService.fromServer(sl<ServerService>()));
  }
  if (!sl.isRegistered<SoapApiService>()) {
    sl.registerLazySingleton<SoapApiService>(() => SoapApiService(sl<Dio>(), sl<ServerService>()));
  }
  if (!sl.isRegistered<ApiDatabaseService>()) {
    sl.registerLazySingleton<ApiDatabaseService>(() => ApiDatabaseService());
  }
  if (!sl.isRegistered<DataSyncService>()) {
    sl.registerLazySingleton<DataSyncService>(() => DataSyncService(
      prefs: sl<SharedPreferencesService>(),
      apiService: sl<SoapApiService>(),
      dbService: sl<ApiDatabaseService>(),
      dbHelper: sl<DatabaseHelper>(),
    ));
  }
  if (!sl.isRegistered<ReportsSyncService>()) {
    sl.registerLazySingleton<ReportsSyncService>(() => ReportsSyncService(
      prefs: sl<SharedPreferencesService>(),
      apiService: sl<SoapApiService>(),
      dbService: sl<ApiDatabaseService>(),
      dbHelper: sl<DatabaseHelper>(),
    ));
  }
  if (!sl.isRegistered<ReportDataService>()) {
    sl.registerLazySingleton<ReportDataService>(() => ReportDataService(
      prefs: sl<SharedPreferencesService>(),
      soapApiService: sl<SoapApiService>(),
    ));
  }
  if (!sl.isRegistered<TelegramTokenService>()) {
    sl.registerLazySingleton<TelegramTokenService>(() => TelegramTokenService());
  }
  if (!sl.isRegistered<TelegramBotService>()) {
    sl.registerLazySingleton<TelegramBotService>(() => TelegramBotService());
  }
  if (!sl.isRegistered<LocationService>()) {
    sl.registerSingletonAsync<LocationService>(() async {
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();
      final locationService = LocationService(prefs.preferences);
      await locationService.initialize();
      return locationService;
    });
  }
  if (!sl.isRegistered<PermissionManager>()) {
    sl.registerLazySingleton<PermissionManager>(() => PermissionManager());
  }

  // API Key Service - depends on SharedPreferences
  if (!sl.isRegistered<ApiKeyService>()) {
    sl.registerSingletonAsync<ApiKeyService>(() async {
      await sl.isReady<SharedPreferencesService>();
      final apiKeyService = ApiKeyService.instance;
      await apiKeyService.initialize(sl<SharedPreferencesService>());
      return apiKeyService;
    });
  }

  // Repositories
  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(apiService: sl(), serverService: sl()));
  }
  if (!sl.isRegistered<AgentRepository>()) {
    sl.registerLazySingleton<AgentRepository>(() => AgentRepository(
      dataSyncService: sl<DataSyncService>(),
    ));
  }
  if (!sl.isRegistered<VisitDataRepository>()) {
    sl.registerLazySingleton<VisitDataRepository>(() => VisitDataRepository(sl<ApiDatabaseService>()));
  }
  if (!sl.isRegistered<VisitStepDataService>()) {
    sl.registerLazySingleton<VisitStepDataService>(() => VisitStepDataService(sl<VisitDataRepository>()));
  }
  if (!sl.isRegistered<PhotoStorageService>()) {
    sl.registerLazySingleton<PhotoStorageService>(() => PhotoStorageService(sl<VisitStepDataService>()));
  }

  // Blocs
  if (!sl.isRegistered<AuthBloc>()) {
    sl.registerFactory(() => AuthBloc(
      authRepository: sl(),
      dataSyncService: sl(),
      prefs: sl(),
    ));
  }
}

// import 'package:get_it/get_it.dart';
// import 'package:dio/dio.dart';
// import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
// import 'package:gloria_marketing_flutter/src/core/network/api_service.dart';
// import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
// import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
// import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
// import 'package:gloria_marketing_flutter/src/features/auth/data/repositories/auth_repository_impl.dart';
// import 'package:gloria_marketing_flutter/src/features/auth/domain/repositories/auth_repository.dart';
// import 'package:gloria_marketing_flutter/src/features/auth/presentation/bloc/auth_bloc.dart';
// import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';
//
// import '../network/server_service.dart';
//
// final sl = GetIt.instance;
//
// Future <void> setupServiceLocator()  async{
//   // Blocs
//
//   sl.registerFactory(() => AuthBloc(authRepository: sl()));
//
//   // Repositories
//   sl.registerLazySingleton<AuthRepository>(
//       () => AuthRepositoryImpl(apiService: sl()));
//
//   // Services
//   // ServerService:
//   if (!sl.isRegistered<SharedPreferencesService>()) {
//     sl.registerSingleton(ServerService(sl<SharedPreferencesService>()));
//   }
//   await sl<ServerService>().restore();
//   sl.registerLazySingleton(() => DatabaseHelper());
//   sl.registerLazySingleton(() => ApiService());
//   sl.registerLazySingleton(() => Dio());
//   sl.registerLazySingleton<SoapApiService>(() => SoapApiService(sl<Dio>()));
//   sl.registerLazySingleton<ApiDatabaseService>(() => ApiDatabaseService());
//   sl.registerLazySingletonAsync<SharedPreferencesService>(
//     () => SharedPreferencesService.getInstance(),
//   );
//
//   // Agent Repository
//   sl.registerLazySingleton<AgentRepository>(
//     () => AgentRepository(
//       apiService: sl<SoapApiService>(),
//       databaseService: sl<ApiDatabaseService>(),
//     ),
//   );
//
//   // // SharedPreferencesService ro‘yxatga olingan bo‘lsin:
//   // sl.registerLazySingleton<SharedPreferencesService>(() => SharedPreferencesService());
//   // await sl<SharedPreferencesService>().init();
//
//
//
//
// }