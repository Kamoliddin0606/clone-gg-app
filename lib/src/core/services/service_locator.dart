import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/network/api_service.dart';
import 'package:gloria_marketing_flutter/src/core/network/url_failover_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/rest_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/reports_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/report_data_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/telegram_bot_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/telegram_token_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/location_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/permission_manager.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_key_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/thumbnail_image_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_orchestrator.dart';
import 'package:gloria_marketing_flutter/src/core/services/sync_notification_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/background_location_tracking_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/client_balance_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/local_uuid_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/startup_access_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/faktura_auth_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/faktura_company_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/product_image_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/connectivity_monitoring_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/gemini_time_verification_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/gemini_document_scanner_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/app_access_control_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/time_verification_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/connectivity_monitor_service.dart';
import 'package:gloria_marketing_flutter/src/features/time_verification/domain/repositories/time_verification_repository.dart';
import 'package:gloria_marketing_flutter/src/features/time_verification/data/repositories/time_verification_repository_impl.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/bloc/startup_access_bloc.dart';

import 'package:gloria_marketing_flutter/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/visit_data_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/visit_step_data_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/photo_storage_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/order_draft_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/order_creation_service.dart';

import '../network/server_service.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // 0) Critical Services
  sl.registerSingleton<SyncNotificationService>(SyncNotificationService());

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

  // 2.5) UrlFailoverService - URL failover mechanism for automatic switching
  // between domain and IP-based URLs when connection issues occur
  if (!sl.isRegistered<UrlFailoverService>()) {
    sl.registerLazySingleton<UrlFailoverService>(() => UrlFailoverService(
      serverService: sl<ServerService>(),
    ));
  }

  // 3) Pastdagilar endi xavfsiz
  if (!sl.isRegistered<DatabaseHelper>()) {
    sl.registerLazySingleton(() => DatabaseHelper());
  }
  if (!sl.isRegistered<Dio>()) {
    sl.registerLazySingleton(() => Dio());
  }
  if (!sl.isRegistered<ApiService>()) {
    sl.registerLazySingleton(() => ApiService(
      serverService: sl<ServerService>(),
      failoverService: sl<UrlFailoverService>(),
    ));
  }
  if (!sl.isRegistered<SoapApiService>()) {
    sl.registerLazySingleton<SoapApiService>(() => SoapApiService(sl<Dio>(), sl<ServerService>()));
  }
  if (!sl.isRegistered<ApiDatabaseService>()) {
    sl.registerLazySingleton<ApiDatabaseService>(() => ApiDatabaseService());
  }
  if (!sl.isRegistered<RestApiService>()) {
    sl.registerLazySingleton<RestApiService>(() => RestApiService(sl<Dio>()));
  }
  if (!sl.isRegistered<TokenService>()) {
    sl.registerLazySingleton<TokenService>(() => TokenService(sl<Dio>(), sl<SharedPreferencesService>()));
  }
  if (!sl.isRegistered<ClientImagesService>()) {
    sl.registerLazySingleton<ClientImagesService>(() => ClientImagesService(
      databaseService: sl<ApiDatabaseService>(),
      apiService: sl<RestApiService>(),
      tokenService: sl<TokenService>(),
      dio: sl<Dio>(),
    ));
  }
  if (!sl.isRegistered<DataSyncService>()) {
    sl.registerLazySingleton<DataSyncService>(() => DataSyncService(
      prefs: sl<SharedPreferencesService>(),
      apiService: sl<SoapApiService>(),
      dbService: sl<ApiDatabaseService>(),
      dbHelper: sl<DatabaseHelper>(),
    ));
  }
  
  // DataSyncOrchestrator - Global singleton for table-level sync management
  if (!sl.isRegistered<DataSyncOrchestrator>()) {
    sl.registerLazySingleton<DataSyncOrchestrator>(() => DataSyncOrchestrator(
      dataSyncService: sl<DataSyncService>(),
      prefs: sl<SharedPreferencesService>(),
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

  // Background Location Tracking Service - fonda joylashuvni kuzatish uchun
  // Bu service ilova aktiv bo'lmasa ham ishlaydi va serverga location yuboradi
  // Alohida Dio instance ishlatadi - boshqa service interceptorlaridan ta'sirlanmaydi
  if (!sl.isRegistered<BackgroundLocationTrackingService>()) {
    sl.registerLazySingleton<BackgroundLocationTrackingService>(() => BackgroundLocationTrackingService(
      prefs: sl<SharedPreferencesService>(),
      tokenService: sl<TokenService>(),
      dbService: sl<ApiDatabaseService>(),
    ));
  }

  // ClientBalanceService - Client balance data fetching and management
  // Uses SOAP API with automatic failover between domain and IP addresses
  // Fetches data via accounting API endpoint shared across all projects
  // 10-second cooldown between refreshes
  // 
  // Сервис баланса клиентов - получение и управление данными баланса
  // Использует SOAP API с автоматическим переключением между доменом и IP адресами
  // Получает данные через endpoint API бухгалтерии, общий для всех проектов
  // 10-секундный кулдаун между обновлениями
  // 
  // Mijoz balansi servisi - balans ma'lumotlarini olish va boshqarish
  // Domen va IP manzillar o'rtasida avtomatik o'tish bilan SOAP API ishlatadi
  // Barcha loyihalar uchun umumiy buxgalteriya API endpoint orqali ma'lumot oladi
  // Yangilashlar orasida 10 soniyalik cooldown
  if (!sl.isRegistered<ClientBalanceService>()) {
    sl.registerLazySingleton<ClientBalanceService>(() => ClientBalanceService(
      dbService: sl<ApiDatabaseService>(),
      failoverService: sl<UrlFailoverService>(),
      serverService: sl<ServerService>(),
      prefs: sl<SharedPreferencesService>(),
    ));
  }

  // Faktura.uz Services - Tashkilot ma'lumotlarini olish uchun
  // https://api.faktura.uz API'dan kompaniya ma'lumotlarini INN orqali oladi
  if (!sl.isRegistered<FakturaAuthService>()) {
    sl.registerFactory<FakturaAuthService>(() => FakturaAuthService(
      prefs: sl<SharedPreferencesService>(),
      username: '998909378702',
      password: '9118113',
      clientId: 'Gloriya',
      clientSecret: '55iK94yR2LdwrVVZSqS07CRTIXFYMxu9Tw2CtVDFdsBFdLLdhiIQx9fkIAHc',
    ));
  }
  if (!sl.isRegistered<FakturaCompanyService>()) {
    sl.registerFactory<FakturaCompanyService>(() => FakturaCompanyService(
      authService: sl<FakturaAuthService>(),
    ));
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
  if (!sl.isRegistered<OrderDraftService>()) {
    sl.registerLazySingleton<OrderDraftService>(() => OrderDraftService(sl<ApiDatabaseService>()));
  }
  if (!sl.isRegistered<OrderCreationService>()) {
    sl.registerLazySingleton<OrderCreationService>(() => OrderCreationService(
      visitDataRepository: sl<VisitDataRepository>(),
      orderDraftService: sl<OrderDraftService>(),
      prefs: sl<SharedPreferencesService>(),
      locationService: sl<LocationService>(),
    ));
  }

  // Product Image Service - caching and size-aware URL selection
  if (!sl.isRegistered<ProductImageService>()) {
    sl.registerLazySingleton<ProductImageService>(() => ProductImageService(
      dbService: sl<ApiDatabaseService>(),
    ));
  }

  // Security Services - Device va Account Access tekshiruvi uchun
  if (!sl.isRegistered<LocalUuidService>()) {
    sl.registerLazySingleton<LocalUuidService>(() => LocalUuidService());
  }
  if (!sl.isRegistered<StartupAccessService>()) {
    sl.registerLazySingleton<StartupAccessService>(() => StartupAccessService(
      localUuidService: sl<LocalUuidService>(),
      prefsService: sl<SharedPreferencesService>(),
      soapApiService: sl<SoapApiService>(),
    ));
  }

  // Access Control Services - App access validity and time verification
  // Note: AccessValidityService is deprecated and replaced by TimeVerificationService
  // which fetches timeLimit from server instead of using hardcoded date
  if (!sl.isRegistered<ConnectivityMonitoringService>()) {
    sl.registerLazySingleton<ConnectivityMonitoringService>(() => ConnectivityMonitoringService());
  }
  // Gemini AI Services - Unified API key management
  // All Gemini services use ApiKeyService for centralized key management
  // IMPORTANT: Gemini services need a SEPARATE Dio instance without auth interceptors
  // The shared Dio instance has SoapApiService interceptors that add wrong headers
  // (Authorization Bearer, SOAP Accept headers) which cause 401 errors with Gemini API
  if (!sl.isRegistered<GeminiDocumentScannerService>()) {
    // Create dedicated Dio instance for Gemini - no interceptors
    final geminiDio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
    sl.registerLazySingleton<GeminiDocumentScannerService>(() => GeminiDocumentScannerService(
      apiKeyService: sl<ApiKeyService>(),
      dio: geminiDio,
    ));
  }
  if (!sl.isRegistered<GeminiTimeVerificationService>()) {
    // Create dedicated Dio instance for Gemini Time Verification - no interceptors
    final geminiTimeDio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
    sl.registerLazySingleton<GeminiTimeVerificationService>(() => GeminiTimeVerificationService(
      apiKeyService: sl<ApiKeyService>(),
      dio: geminiTimeDio,
    ));
  }
  if (!sl.isRegistered<AppAccessControlService>()) {
    sl.registerLazySingleton<AppAccessControlService>(() => AppAccessControlService(
      timeVerificationService: sl<TimeVerificationService>(),
      connectivityService: sl<ConnectivityMonitoringService>(),
      prefsService: sl<SharedPreferencesService>(),
    ));
  }

  // Time Verification Services - Server time-based access control
  // Fetches server time and time limit via GetServerTime SOAP endpoint
  // Supports both online (server time) and offline (local time) verification
  // Automatically clears data when access expires
  if (!sl.isRegistered<TimeVerificationRepository>()) {
    sl.registerLazySingleton<TimeVerificationRepository>(() => TimeVerificationRepositoryImpl(
      apiService: sl<ApiService>(),
    ));
  }
  if (!sl.isRegistered<TimeVerificationService>()) {
    sl.registerLazySingleton<TimeVerificationService>(() => TimeVerificationService(
      repository: sl<TimeVerificationRepository>(),
      prefs: sl<SharedPreferencesService>(),
      dataSyncService: sl<DataSyncService>(),
    ));
  }
  if (!sl.isRegistered<ConnectivityMonitorService>()) {
    sl.registerLazySingleton<ConnectivityMonitorService>(() => ConnectivityMonitorService());
  }

  // Blocs
  if (!sl.isRegistered<AuthBloc>()) {
    sl.registerFactory(() => AuthBloc(
      authRepository: sl(),
      dataSyncService: sl(),
      prefs: sl(),
    ));
  }
  if (!sl.isRegistered<StartupAccessBloc>()) {
    sl.registerFactory(() => StartupAccessBloc(
      accessService: sl<StartupAccessService>(),
    ));
  }
}
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