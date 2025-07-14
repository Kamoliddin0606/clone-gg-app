import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/network/api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';

final sl = GetIt.instance;

Future <void> setupServiceLocator()  async{
  // Blocs
  sl.registerFactory(() => AuthBloc(authRepository: sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(apiService: sl()));

  // Services
  sl.registerLazySingleton(() => DatabaseHelper());
  sl.registerLazySingleton(() => ApiService());
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton<SoapApiService>(() => SoapApiService(sl<Dio>()));
  sl.registerLazySingleton<ApiDatabaseService>(() => ApiDatabaseService());
  sl.registerLazySingletonAsync<SharedPreferencesService>(
    () => SharedPreferencesService.getInstance(),
  );

  // Agent Repository
  sl.registerLazySingleton<AgentRepository>(
    () => AgentRepository(
      apiService: sl<SoapApiService>(),
      databaseService: sl<ApiDatabaseService>(),
    ),
  );

  
}