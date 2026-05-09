import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/network/api_service.dart';
import 'package:gloria_marketing_flutter/src/core/network/url_failover_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/reports_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/report_data_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/telegram_bot_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/telegram_token_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/location_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/permission_manager.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_key_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_orchestrator.dart';
import 'package:gloria_marketing_flutter/src/core/services/sync_notification_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/background_location_tracking_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/telemetry_v2/tracking_policy_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/telemetry_v2/device_registration_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/telemetry_v2/rest_logging.dart';
import 'package:gloria_marketing_flutter/src/core/services/client_balance_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/local_uuid_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/login_device_payload_builder.dart';
import 'package:gloria_marketing_flutter/src/core/services/faktura_auth_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/faktura_company_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/agent_organization_context.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/new_backend_image_repository.dart';
import 'package:gloria_marketing_flutter/src/core/services/gemini_document_scanner_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/connectivity_monitor_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/app_start_guard.dart';
import 'package:gloria_marketing_flutter/src/core/services/health_check_service.dart';

import 'package:gloria_marketing_flutter/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/visit_data_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/visit_step_data_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/photo_storage_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/order_draft_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/order_creation_service.dart';

import 'package:gloria_marketing_flutter/src/features/knowledge/data/repositories/knowledge_repository.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/services/knowledge_api_service.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/services/knowledge_db_dao.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/services/knowledge_sync_service.dart';

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
    sl.registerLazySingleton(() {
      // Shared Dio used by SoapApiService. SOAP envelopes are too large to
      // print on every call, so the REST logger is left detached. V2 services
      // (token, policy, device, telemetry) each have their own Dio instance
      // with `attachRestLogger` so their HTTP traffic still surfaces under
      // [AUTH] / [POLICY] / [DEVICE] / [TELEMETRY].
      // attachRestLogger(dio, 'REST');
      return Dio();
    });
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
  // TokenService - REST API token management with dedicated Dio instance
  // IMPORTANT: TokenService needs a SEPARATE Dio instance without other service interceptors
  // The shared Dio instance has SoapApiService interceptors that can
  // interfere with the 1C-Login authentication endpoint responses
  if (!sl.isRegistered<TokenService>()) {
    // Create dedicated Dio instance for TokenService - no other interceptors
    final tokenDio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
    attachRestLogger(tokenDio, 'AUTH');

    sl.registerLazySingleton<TokenService>(() => TokenService(
      tokenDio,
      sl<SharedPreferencesService>()
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
  // Alohida Dio instance ishlatadi - boshqa service interceptorlaridan ta'sirlanmaydi.
  // V2 (yangi server) telemetry endpointlariga yuboradi va TrackingPolicyService
  // hamda DeviceRegistrationService bilan birga ishlaydi.
  if (!sl.isRegistered<TrackingPolicyService>()) {
    sl.registerLazySingleton<TrackingPolicyService>(() => TrackingPolicyService(
      tokenService: sl<TokenService>(),
      prefs: sl<SharedPreferencesService>(),
    ));
  }
  if (!sl.isRegistered<DeviceRegistrationService>()) {
    sl.registerLazySingleton<DeviceRegistrationService>(() => DeviceRegistrationService(
      tokenService: sl<TokenService>(),
      prefs: sl<SharedPreferencesService>(),
    ));
  }
  if (!sl.isRegistered<BackgroundLocationTrackingService>()) {
    sl.registerLazySingleton<BackgroundLocationTrackingService>(() => BackgroundLocationTrackingService(
      prefs: sl<SharedPreferencesService>(),
      tokenService: sl<TokenService>(),
      dbService: sl<ApiDatabaseService>(),
      policyService: sl<TrackingPolicyService>(),
      deviceRegistrationService: sl<DeviceRegistrationService>(),
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

  // Image stack (lib/src/core/services/images/) — single repository
  // talking to /api/mobile/v1/images/. Legacy image host fully
  // decommissioned 2026-05-08; uploads happen via the web admin panel.
  if (!sl.isRegistered<NewBackendImageRepository>()) {
    sl.registerLazySingleton<NewBackendImageRepository>(
      () => NewBackendImageRepository(
        dio: sl<Dio>(),
        tokenService: sl<TokenService>(),
      ),
    );
  }
  // Helper that surfaces the agent's primary organisation id from the
  // cached gates envelope. Image widget call sites use it as a default
  // when the entity itself does not (yet) carry an organization_id.
  if (!sl.isRegistered<AgentOrganizationContext>()) {
    sl.registerLazySingleton<AgentOrganizationContext>(
      () => AgentOrganizationContext(prefs: sl<SharedPreferencesService>()),
    );
  }

  // Security helpers — kept for callers that still need a stable per-install
  // identifier (e.g. telemetry device fingerprint, device binding).
  if (!sl.isRegistered<LocalUuidService>()) {
    sl.registerLazySingleton<LocalUuidService>(() => LocalUuidService());
  }

  // Builder for the JWT login `device` block. Memoises the payload after
  // the first build so repeat logins skip the I/O. Depends on the
  // LocalUuidService registered immediately above.
  if (!sl.isRegistered<LoginDevicePayloadBuilder>()) {
    sl.registerLazySingleton<LoginDevicePayloadBuilder>(
      () => LoginDevicePayloadBuilder(uuidService: sl<LocalUuidService>()),
    );
  }

  // Connectivity monitoring used by AppStartGuard (and downstream UI).
  if (!sl.isRegistered<ConnectivityMonitorService>()) {
    sl.registerLazySingleton<ConnectivityMonitorService>(() => ConnectivityMonitorService());
  }

  // Gemini AI Services - Unified API key management
  if (!sl.isRegistered<GeminiDocumentScannerService>()) {
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

  // V2 backend liveness probe. Used at startup (debug log) and from the
  // LoginPage "Test connection" button. Self-contained Dio instance.
  if (!sl.isRegistered<HealthCheckService>()) {
    sl.registerLazySingleton<HealthCheckService>(() => HealthCheckService());
  }

  // Boot-time access guard. Replaces the legacy AppAccessControlService /
  // TimeVerificationService / StartupAccessBloc trio. Decides on each cold
  // start whether to land on `/login` or `/home` based on the cached
  // `gates` envelope from the V2 backend.
  if (!sl.isRegistered<AppStartGuard>()) {
    sl.registerLazySingleton<AppStartGuard>(() => AppStartGuard(
      prefs: sl<SharedPreferencesService>(),
      tokenService: sl<TokenService>(),
      connectivity: sl<ConnectivityMonitorService>(),
    ));
  }

  // Knowledge Base feature — offline-first reglament/training docs.
  // KnowledgeApiService re-resolves the V2 token + X-Organization-Id
  // per request via TokenService + AgentOrganizationContext, so it
  // stays correct after multi-tenant org switching.
  if (!sl.isRegistered<KnowledgeApiService>()) {
    sl.registerLazySingleton<KnowledgeApiService>(() => KnowledgeApiService(
          sl<TokenService>(),
          sl<AgentOrganizationContext>(),
        ));
  }
  if (!sl.isRegistered<KnowledgeDbDao>()) {
    sl.registerLazySingleton<KnowledgeDbDao>(
      () => KnowledgeDbDao(sl<ApiDatabaseService>()),
    );
  }
  if (!sl.isRegistered<KnowledgeSyncService>()) {
    sl.registerLazySingleton<KnowledgeSyncService>(
      () => KnowledgeSyncService(
        sl<KnowledgeApiService>(),
        sl<KnowledgeDbDao>(),
      ),
    );
  }
  if (!sl.isRegistered<KnowledgeRepository>()) {
    sl.registerLazySingleton<KnowledgeRepository>(
      () => KnowledgeRepository(
        sl<KnowledgeSyncService>(),
        sl<KnowledgeDbDao>(),
        sl<AgentOrganizationContext>(),
      ),
    );
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