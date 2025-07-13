import 'package:get_it/get_it.dart';
import 'package:get_it/get_it.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/network/api_service.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  // Blocs
  sl.registerFactory(() => AuthBloc(authRepository: sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(apiService: sl()));

  // Services
  sl.registerLazySingleton(() => DatabaseHelper());
  sl.registerLazySingleton(() => ApiService());
}