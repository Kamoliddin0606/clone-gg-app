import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/network/api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';

import 'package:gloria_marketing_flutter/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';

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

  // Repositories
  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(apiService: sl()));
  }
  if (!sl.isRegistered<AgentRepository>()) {
    sl.registerLazySingleton<AgentRepository>(() => AgentRepository(
      dataSyncService: sl<DataSyncService>(),
    ));
  }

  // Blocs
  if (!sl.isRegistered<AuthBloc>()) {
    sl.registerFactory(() => AuthBloc(
      authRepository: sl(),
      dataSyncService: sl(),
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