import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import 'package:gloria_marketing_flutter/src/core/auth/backend_permission_store.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/network/api_service.dart';
import 'package:gloria_marketing_flutter/src/core/network/url_failover_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/project_context.dart';
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
import 'package:gloria_marketing_flutter/src/features/agent/services/order_balance_gate.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/customer_balance_status_cache.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/balance_gate_event_logger.dart';
import 'package:gloria_marketing_flutter/src/core/services/local_uuid_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/login_device_payload_builder.dart';
import 'package:gloria_marketing_flutter/src/core/services/faktura_auth_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/faktura_company_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/agent_organization_context.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/new_backend_image_repository.dart';
import 'package:gloria_marketing_flutter/src/core/services/gemini_document_scanner_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/connectivity_monitor_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/network_mode_gate.dart';
import 'package:gloria_marketing_flutter/src/core/services/app_start_guard.dart';
import 'package:gloria_marketing_flutter/src/core/services/health_check_service.dart';
import 'package:gloria_marketing_flutter/src/core/version/data/app_version_interceptor.dart';
import 'package:gloria_marketing_flutter/src/core/version/data/version_app_info.dart';
import 'package:gloria_marketing_flutter/src/core/version/data/version_check_cache.dart';
import 'package:gloria_marketing_flutter/src/core/version/data/version_gate_api.dart';
import 'package:gloria_marketing_flutter/src/core/version/data/version_gate_response_interceptor.dart';
import 'package:gloria_marketing_flutter/src/core/version/domain/version_gate_service.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';

import 'package:gloria_marketing_flutter/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:gloria_marketing_flutter/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/visit_data_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/customer_photo_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/customer_read_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/customer_write_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/bloc/customer_write_cubit.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/visit_step_data_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/photo_storage_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/order_draft_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/order_creation_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/customer_photo_change_notifier.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/customer_photo_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/customer_primary_photo_cache.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/bloc/customer_photo_cubit.dart';

import 'package:gloria_marketing_flutter/src/features/knowledge/data/repositories/knowledge_repository.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/services/knowledge_api_service.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/services/knowledge_db_dao.dart';
import 'package:gloria_marketing_flutter/src/features/knowledge/data/services/knowledge_sync_service.dart';

import 'package:gloria_marketing_flutter/src/features/notifications/data/db/notification_db_dao.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/fcm_token_service.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/notification_api_service.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/notification_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/push_handler_service.dart';

import '../network/server_service.dart';

final sl = GetIt.instance;

/// Attach the [AppVersionInterceptor] AND [VersionGateResponseInterceptor]
/// to a Dio used for the V2 backend. Two-in-one because every V2 Dio needs
/// both: outbound headers identify the app to the backend middleware, and
/// inbound 426s must route to the full-screen block surface.
///
/// Pulls [VersionAppInfo] lazily from the service locator so the cached
/// snapshot reflects the latest [main()] load. Skips quietly if either the
/// locator entry is missing (early bootstrap) or the same interceptor is
/// already attached (idempotency for tests that re-run setup).
void _attachAppVersionHeaders(Dio dio) {
  final alreadyRequestAttached =
      dio.interceptors.any((i) => i is AppVersionInterceptor);
  if (!alreadyRequestAttached) {
    dio.interceptors.add(AppVersionInterceptor(() {
      try {
        if (sl.isRegistered<VersionAppInfo>()) {
          return sl<VersionAppInfo>();
        }
      } catch (_) {}
      return VersionAppInfo.empty;
    }));
  }

  final alreadyResponseAttached =
      dio.interceptors.any((i) => i is VersionGateResponseInterceptor);
  if (!alreadyResponseAttached) {
    dio.interceptors.add(VersionGateResponseInterceptor(
      navigatorKey: AppRouter.navigatorKey,
      cache: sl.isRegistered<VersionCheckCache>()
          ? sl<VersionCheckCache>()
          : VersionCheckCache(),
    ));
  }
}

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

  // BackendPermissionStore — backend-sourced codename cache, distinct
  // from the SOAP `sales_req_permissions` row. Registered eagerly so
  // [TokenService] can sync into it during login/refresh.
  if (!sl.isRegistered<BackendPermissionStore>()) {
    sl.registerLazySingleton<BackendPermissionStore>(
      () => BackendPermissionStore(prefs: sl<SharedPreferencesService>()),
    );
  }
  // Cold-start bootstrap: if a cached `gates` envelope exists from
  // a prior login, push its permissions list (with the explicit
  // `provided` flag) into the store. Without this the store stays
  // empty until the next token refresh and the optimistic-empty
  // fallback over-grants codenames the backend never actually
  // returned for this user.
  try {
    final cachedGates = sl<SharedPreferencesService>().getCachedGates();
    if (cachedGates != null) {
      if (kDebugMode) {
        // Cold-start view of what the last login / refresh left in
        // the cached gates envelope — useful for diagnosing
        // "buttons show but server denies" with no fresh login in
        // the session. Source endpoint was the auth API the user
        // hit on their previous app run.
        debugPrint(
          '[GATES-FLOW] ❄️  COLD-START BOOTSTRAP from cached gates\n'
          '  source endpoint (last login) : POST /api/auth/token/[/refresh/]\n'
          '  cached permissions           : ${cachedGates.permissions}\n'
          '  permissions count            : ${cachedGates.permissions.length}\n'
          '  permissionsProvided          : ${cachedGates.permissionsProvided}\n'
          '  organization_id              : ${cachedGates.organizationId}\n'
          '  bypass (superuser)           : ${cachedGates.bypass}',
        );
      }
      await sl<BackendPermissionStore>().replaceFromLogin(
        cachedGates.permissions,
        provided: cachedGates.permissionsProvided,
      );
    } else if (kDebugMode) {
      debugPrint(
        '[GATES-FLOW] ❄️  COLD-START BOOTSTRAP → no cached gates '
        '(first launch or post-logout); optimistic-empty fallback '
        'remains active until next login',
      );
    }
  } catch (_) {
    // Bootstrap is best-effort; never block service-locator setup.
  }

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

  // ProjectContext — single source of truth for `customer_scope=project`
  // active project tracking. Reads cached gates and SQLite-cached projects
  // to expose the `X-Project-Id` header value used by the three customer
  // repositories.
  if (!sl.isRegistered<ProjectContext>()) {
    sl.registerLazySingleton<ProjectContext>(() => ProjectContext(
          sl<SharedPreferencesService>(),
          sl<ApiDatabaseService>(),
        ));
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
    _attachAppVersionHeaders(tokenDio);

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

  // OrderBalanceGate — visit "create order" step entry guard +
  // pre-submit recheck for offline-collected orders. See
  // docs/customer-balance-mobile.md M8/M9/M11.
  if (!sl.isRegistered<OrderBalanceGate>()) {
    sl.registerLazySingleton<OrderBalanceGate>(() => OrderBalanceGate(
          balanceService: sl<ClientBalanceService>(),
          connectivity: sl<ConnectivityMonitorService>(),
          projectContext: sl<ProjectContext>(),
        ));
  }

  // CustomerBalanceStatusCache — shared in-memory map of
  // `inn → CustomerBalanceStatusEntry` consumed by trading-points list/grid,
  // client detail sheet and visit-step "create order" tile to render the
  // tint + indicator. See docs/customer-balance-mobile.md M12 (rebuilt).
  if (!sl.isRegistered<CustomerBalanceStatusCache>()) {
    sl.registerLazySingleton<CustomerBalanceStatusCache>(
      () => CustomerBalanceStatusCache(
        dbService: sl<ApiDatabaseService>(),
        projectContext: sl<ProjectContext>(),
      ),
    );
  }

  // BalanceGateEventLogger — emits `customer.balance.blocked` analytics
  // events whenever DebtBlockedDialog is surfaced (Passport §7, M12 P0.4).
  // Best-effort POST; failure is silent and never blocks the UI.
  if (!sl.isRegistered<BalanceGateEventLogger>()) {
    sl.registerLazySingleton<BalanceGateEventLogger>(
      () => BalanceGateEventLogger(),
    );
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
  //
  // Dedicated Dio instance: the shared sl<Dio>() carries SoapApiService's
  // global interceptor that overwrites Accept with
  // `application/soap+xml, text/xml, application/xml`, which makes the
  // V2 JSON endpoint return HTTP 406. Same pattern as TokenService.
  if (!sl.isRegistered<NewBackendImageRepository>()) {
    final imageDio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
    attachRestLogger(imageDio, 'IMG');
    _attachAppVersionHeaders(imageDio);

    sl.registerLazySingleton<NewBackendImageRepository>(
      () => NewBackendImageRepository(
        dio: imageDio,
        tokenService: sl<TokenService>(),
      ),
    );
  }

  // Customer photo write API (`/api/mobile/v2/customers/{id}/photos/`).
  // Repository owns the typed Dio + idempotency cache; service wraps
  // it with polling + cap-aware errors; cubit is a per-customer
  // factory so multiple gallery pages can coexist (deep-link, etc.).
  // Dedicated Dio for the same reason as the image repo above.
  if (!sl.isRegistered<CustomerPhotoRepository>()) {
    final customerPhotoDio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
    attachRestLogger(customerPhotoDio, 'PHOTO');
    _attachAppVersionHeaders(customerPhotoDio);

    sl.registerLazySingleton<CustomerPhotoRepository>(
      () => CustomerPhotoRepository(
        dio: customerPhotoDio,
        tokenService: sl<TokenService>(),
        prefs: sl<SharedPreferencesService>(),
      ),
    );
  }
  if (!sl.isRegistered<CustomerPhotoCubit>()) {
    sl.registerFactoryParam<CustomerPhotoCubit, String, void>(
      (customerId, _) => CustomerPhotoCubit(
        customerId: customerId,
        service: CustomerPhotoService(repo: sl<CustomerPhotoRepository>()),
      ),
    );
  }

  // Global pub/sub for "this customer's photos changed" events.
  // Emitted by CustomerPhotoCubit after every successful mutation;
  // subscribed by CustomerPrimaryThumbnail (trading-point grid /
  // avatar) and CustomerPhotoPreview (detail-sheet carousel) so
  // surfaces outside the gallery refresh immediately on edits.
  if (!sl.isRegistered<CustomerPhotoChangeNotifier>()) {
    sl.registerLazySingleton<CustomerPhotoChangeNotifier>(
      () => CustomerPhotoChangeNotifier(),
    );
  }

  // In-memory de-duped cache for `primary photo per customer`
  // lookups. Backs CustomerPrimaryThumbnail in long grids/lists so
  // 50–100 mounting tiles collapse to a single GET per customer.
  if (!sl.isRegistered<CustomerPrimaryPhotoCache>()) {
    sl.registerLazySingleton<CustomerPrimaryPhotoCache>(
      () => CustomerPrimaryPhotoCache(repo: sl<CustomerPhotoRepository>()),
    );
  }

  // Customer write API (`/api/mobile/v2/customers/` create / PATCH).
  // Dedicated Dio for the same reason as the photo repository above:
  // the shared sl<Dio>() carries SoapApiService's interceptor that
  // overwrites Accept with `application/soap+xml`, which makes the
  // V2 JSON endpoint return HTTP 406.
  if (!sl.isRegistered<CustomerWriteRepository>()) {
    final customerWriteDio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
    attachRestLogger(customerWriteDio, 'CUSTOMER');
    _attachAppVersionHeaders(customerWriteDio);

    sl.registerLazySingleton<CustomerWriteRepository>(
      () => CustomerWriteRepository(
        dio: customerWriteDio,
        tokenService: sl<TokenService>(),
        prefs: sl<SharedPreferencesService>(),
      ),
    );
  }

  // Customer read API (`GET /api/mobile/v2/customers/`). Replaces the
  // legacy SOAP `getClients` pull. Dedicated Dio for the same reason
  // as the write repository above — the shared sl<Dio>() carries the
  // SOAP Accept-header interceptor that breaks V2 JSON.
  if (!sl.isRegistered<CustomerReadRepository>()) {
    final customerReadDio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
    _attachAppVersionHeaders(customerReadDio);
    // Intentionally no attachRestLogger here: listAll() paginates through
    // the full customer list (~150 KB per page) and LogInterceptor would
    // dump every page's body via debugPrint, throttling the log queue and
    // jamming the UI thread on the customers screen. The repository's own
    // `[CUSTOMER-READ] listAll → N rows` summary is enough for debugging.
    // Per-customer traces still come from customerWriteDio (create/patch).

    sl.registerLazySingleton<CustomerReadRepository>(
      () => CustomerReadRepository(
        dio: customerReadDio,
        tokenService: sl<TokenService>(),
      ),
    );
  }
  if (!sl.isRegistered<CustomerWriteCubit>()) {
    sl.registerFactory<CustomerWriteCubit>(
      () => CustomerWriteCubit(repo: sl<CustomerWriteRepository>()),
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

  // Mode gate — arbitrates between the persisted offline flag and live
  // connectivity. UI handlers (pull-to-refresh, offline badge tap, etc.)
  // call this instead of flipping `prefs.setOfflineMode` directly.
  if (!sl.isRegistered<NetworkModeGate>()) {
    sl.registerLazySingleton<NetworkModeGate>(() => NetworkModeGate(
      prefs: sl<SharedPreferencesService>(),
      connectivity: sl<ConnectivityMonitorService>(),
      serverService: sl<ServerService>(),
    ));
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

  // ===========================================================================
  // App-version gating layer (docs/integration-prompts/mobile-app-version-*.md)
  // ===========================================================================
  //
  // Three runtime singletons + two Dio interceptor factories. The runtime
  // singletons are eager because every V2 Dio in the locator must be able to
  // attach the request interceptor on first construction.
  //
  //   - VersionAppInfo  : cached package + device telemetry. Loaded ASYNC in
  //                       main() before runApp(). Until the async load lands
  //                       the locator returns [VersionAppInfo.empty] (the
  //                       request interceptor drops empty headers, so this
  //                       stays correct — version-check just runs without
  //                       identifiers and the backend treats it as unknown).
  //   - VersionCheckCache: SharedPreferences-backed.
  //   - VersionGateApi   : dedicated Dio, NO global interceptors (must not
  //                        loop through itself on 426).
  //   - VersionGateService: the orchestrator the splash uses.
  if (!sl.isRegistered<VersionAppInfo>()) {
    // Registered up-front with the empty sentinel; main() overwrites once
    // PackageInfo + DeviceInfo finish loading.
    sl.registerSingleton<VersionAppInfo>(VersionAppInfo.empty);
  }
  if (!sl.isRegistered<VersionCheckCache>()) {
    sl.registerLazySingleton<VersionCheckCache>(() => VersionCheckCache());
  }
  if (!sl.isRegistered<VersionGateApi>()) {
    sl.registerLazySingleton<VersionGateApi>(() => VersionGateApi(
          appInfoProvider: () => sl<VersionAppInfo>(),
        ));
  }
  if (!sl.isRegistered<VersionGateService>()) {
    sl.registerLazySingleton<VersionGateService>(() => VersionGateService(
          api: sl<VersionGateApi>(),
          cache: sl<VersionCheckCache>(),
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

  // Notification Center — see docs/notifications/passport-mobile.md.
  // The repository owns a behavior-subject stream of unread counts, so
  // it MUST be a singleton (cubit subscribes on every screen build).
  // The API client uses a dedicated Dio instance for the same reason as
  // CustomerPhotoRepository: the shared sl<Dio>() carries SoapApiService's
  // interceptor that overwrites Accept with `application/soap+xml`,
  // which would make the V2 JSON endpoint return 406.
  if (!sl.isRegistered<NotificationDbDao>()) {
    sl.registerLazySingleton<NotificationDbDao>(
      () => NotificationDbDao(sl<DatabaseHelper>()),
    );
  }
  if (!sl.isRegistered<NotificationApiService>()) {
    final notifDio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
    attachRestLogger(notifDio, 'NOTIF');
    _attachAppVersionHeaders(notifDio);
    sl.registerLazySingleton<NotificationApiService>(
      () => NotificationApiService(
        dio: notifDio,
        tokenService: sl<TokenService>(),
      ),
    );
  }
  if (!sl.isRegistered<NotificationRepository>()) {
    sl.registerLazySingleton<NotificationRepository>(
      () => NotificationRepository(
        api: sl<NotificationApiService>(),
        dao: sl<NotificationDbDao>(),
        uuidService: sl<LocalUuidService>(),
      ),
    );
  }
  if (!sl.isRegistered<FcmTokenService>()) {
    sl.registerLazySingleton<FcmTokenService>(
      () => FcmTokenService(
        api: sl<NotificationApiService>(),
        prefs: sl<SharedPreferencesService>(),
        uuidService: sl<LocalUuidService>(),
      ),
    );
  }
  // Reactive client-side preference store (Phase 2 §1). Must be ready
  // BEFORE PushHandlerService so the filter sees a hydrated snapshot
  // on the very first foreground push. Bootstrap in main() after the
  // service-locator setup returns.
  if (!sl.isRegistered<NotificationPreferencesService>()) {
    sl.registerLazySingleton<NotificationPreferencesService>(
      () => NotificationPreferencesService(
        prefs: sl<SharedPreferencesService>(),
      ),
    );
  }
  if (!sl.isRegistered<PushHandlerService>()) {
    sl.registerLazySingleton<PushHandlerService>(
      () => PushHandlerService(
        repo: sl<NotificationRepository>(),
        dao: sl<NotificationDbDao>(),
        preferences: sl<NotificationPreferencesService>(),
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