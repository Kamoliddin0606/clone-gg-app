import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';
import '../../core/services/local_uuid_service.dart';
import '../../core/services/project_context.dart';
import '../../core/services/shared_preferences_service.dart';
import '../../core/services/token_service.dart';
import 'data/local/etag_cache_data_source.dart';
import 'data/local/outbox_data_source.dart';
import 'data/local/photo_uploads_data_source.dart';
import 'data/local/visit_local_data_source.dart';
import 'data/repositories/catalog_repository_impl.dart';
import 'data/repositories/outbox_repository_impl.dart';
import 'data/repositories/permissions_repository_impl.dart';
import 'data/repositories/photo_repository_impl.dart';
import 'data/repositories/visit_repository_impl.dart';
import 'data/rest/rest_v2_client.dart';
import 'data/rest/visit_api.dart';
import 'domain/repositories/catalog_repository.dart';
import 'domain/repositories/outbox_repository.dart';
import 'domain/repositories/permissions_repository.dart';
import 'domain/repositories/photo_repository.dart';
import 'domain/repositories/visit_repository.dart';
import 'infra/envelope/visit_envelope_builder.dart';
import 'infra/feature_flags.dart';
import 'infra/location/secure_location_service.dart';
import 'infra/photo/photo_compressor.dart';
import 'infra/photo/photo_upload_service.dart';
import 'infra/security/jailbreak_detector.dart';
import 'infra/sync/backoff_scheduler.dart';
import 'infra/sync/connectivity_listener.dart';
import 'infra/sync/outbox_dispatcher.dart';
import 'infra/sync/visit_status_poller.dart';
import 'infra/telemetry/visits_crashlytics_reporter.dart';
import 'infra/time/server_time_service.dart';
import 'infra/visit_finish_orchestrator.dart';
import 'presentation/bloc/outbox_status/outbox_status_cubit.dart';
import 'presentation/bloc/visit_session/visit_session_bloc.dart';
import 'presentation/task_pages/_registry.dart';

/// Wires every Visits v2 collaborator into the shared GetIt locator.
///
/// Called once from `setupServiceLocator()` after the database, token, and
/// project-context singletons are available. We keep it in its own file so
/// the legacy `service_locator.dart` stays focused on the agent / SOAP
/// flows; modules add a single line.
class VisitsModule {
  /// Sentinel value stored in the locator so `setupServiceLocator()` can
  /// detect a previous call and stay idempotent across hot restarts /
  /// re-entrant bootstrap paths. The class otherwise has no state — all
  /// behaviour lives in [register].
  const VisitsModule.marker();

  static Future<void> register(
    GetIt sl, {
    required String restV2BaseUrl,
  }) async {
    // ---- platform glue -------------------------------------------------

    sl.registerLazySingleton<ConnectivityListener>(
        () => ConnectivityListener());
    sl.registerLazySingleton<BackoffScheduler>(() => BackoffScheduler());
    sl.registerLazySingleton<SecureLocationService>(
        () => SecureLocationService());
    sl.registerLazySingleton<JailbreakDetector>(() => const JailbreakDetector());
    sl.registerLazySingleton<PhotoCompressor>(() => PhotoCompressor());

    sl.registerSingletonAsync<ServerTimeService>(() async {
      final service = ServerTimeService();
      await service.init();
      return service;
    });

    // ---- data sources --------------------------------------------------

    Future<Database> dbProvider() => sl<DatabaseHelper>().database;

    sl.registerLazySingleton<OutboxDataSource>(
        () => OutboxDataSource(dbProvider));
    sl.registerLazySingleton<VisitLocalDataSource>(
        () => VisitLocalDataSource(dbProvider));
    sl.registerLazySingleton<PhotoUploadsDataSource>(
        () => PhotoUploadsDataSource(dbProvider));
    sl.registerLazySingleton<EtagCacheDataSource>(
        () => EtagCacheDataSource(dbProvider));

    // ---- REST client --------------------------------------------------
    //
    // The client is created lazily so it picks up `ServerTimeService`
    // after its async init. Avoids a registration-order foot-gun.

    sl.registerLazySingleton<RestV2Client>(() {
      return RestV2Client.create(
        baseUrl: restV2BaseUrl,
        accessTokenLoader: () async {
          final tokenService = sl<TokenService>();
          return tokenService.getStoredAccessToken();
        },
        projectIdLoader: () async {
          if (!sl.isRegistered<ProjectContext>()) return null;
          return sl<ProjectContext>().activeProjectHeaderValue;
        },
        // ServerTimeService async-registered — resolve it at callback
        // time (after sl.allReady()), not at RestV2Client factory time.
        // Otherwise eager consumers of RestV2Client (the task-renderer
        // registry at the bottom of this method) crash with
        // "Bad state: not ready yet" and `runApp()` never fires.
        onServerTime: (ts) {
          if (sl.isRegistered<ServerTimeService>() &&
              sl.isReadySync<ServerTimeService>()) {
            sl<ServerTimeService>().recordServerTime(ts);
          }
        },
      );
    });

    sl.registerLazySingleton<VisitApi>(() => VisitApi(sl<RestV2Client>()));

    // Polling helper for the post-finish UX (changelog § 7). Cubits /
    // pages resolve this when they want to render the "buyurtma 1C ga
    // yetkazildi" confirmation; it has no global side effects so a
    // lazy singleton is fine.
    sl.registerLazySingleton<VisitStatusPoller>(
        () => VisitStatusPoller(sl<VisitApi>()));

    // ---- repositories -------------------------------------------------

    sl.registerLazySingleton<OutboxRepository>(
        () => OutboxRepositoryImpl(sl<OutboxDataSource>()));
    sl.registerLazySingleton<VisitRepository>(
        () => VisitRepositoryImpl(sl<VisitLocalDataSource>()));
    sl.registerLazySingleton<PhotoRepository>(
        () => PhotoRepositoryImpl(sl<PhotoUploadsDataSource>()));

    sl.registerLazySingleton<PermissionsRepository>(() {
      return PermissionsRepositoryImpl(
        api: sl<VisitApi>(),
        cache: sl<EtagCacheDataSource>(),
        userCodeLoader: _userCodeLoader(sl),
        projectCodeLoader: _projectCodeLoader(sl),
      );
    });

    sl.registerLazySingleton<CatalogRepository>(() {
      return CatalogRepositoryImpl(
        api: sl<VisitApi>(),
        cache: sl<EtagCacheDataSource>(),
        projectCodeLoader: _projectCodeLoader(sl),
      );
    });

    // ---- infra services that depend on repos --------------------------

    sl.registerLazySingleton<VisitEnvelopeBuilder>(
        () => VisitEnvelopeBuilder());

    sl.registerLazySingleton<OutboxDispatcher>(() => OutboxDispatcher(
          outbox: sl<OutboxRepository>(),
          visits: sl<VisitRepository>(),
          client: sl<RestV2Client>(),
          connectivity: sl<ConnectivityListener>(),
          backoff: sl<BackoffScheduler>(),
          authRefresh: () async {
            final token = await sl<TokenService>().refreshAccessToken();
            return token != null;
          },
        ));

    sl.registerLazySingleton<PhotoUploadService>(() => PhotoUploadService(
          photos: sl<PhotoRepository>(),
          api: sl<VisitApi>(),
          connectivity: sl<ConnectivityListener>(),
          clientUuidLoader: () => sl<LocalUuidService>().getOrCreateLocalUuid(),
          compressor: sl<PhotoCompressor>(),
        ));

    sl.registerLazySingleton<FeatureFlags>(
        () => FeatureFlags(sl<PermissionsRepository>()));
    sl.registerLazySingleton<VisitFinishOrchestrator>(
        () => VisitFinishOrchestrator(
              outbox: sl<OutboxRepository>(),
              dispatcher: sl<OutboxDispatcher>(),
              flags: sl<FeatureFlags>(),
            ));

    // Crashlytics breadcrumbs for the visit pipeline. Wires itself onto
    // the dispatcher's status stream on creation so every send/retry/
    // dead-letter lands in the next crash report — no opt-in needed at
    // call sites.
    sl.registerLazySingleton<VisitsCrashlyticsReporter>(() {
      final reporter = VisitsCrashlyticsReporter();
      reporter.attachOutbox(sl<OutboxDispatcher>().statusStream);
      return reporter;
    });

    // ---- BLoCs -------------------------------------------------------
    //
    // Cubit/Bloc instances are short-lived (one per visit screen), so they
    // register as factories. `BlocProvider` instantiates them and disposes
    // alongside the page lifecycle.

    sl.registerFactory<VisitSessionBloc>(() => VisitSessionBloc(
          permissions: sl<PermissionsRepository>(),
          catalog: sl<CatalogRepository>(),
          visits: sl<VisitRepository>(),
          photos: sl<PhotoRepository>(),
          envelopeBuilder: sl<VisitEnvelopeBuilder>(),
          finishOrchestrator: sl<VisitFinishOrchestrator>(),
          serverTime: sl<ServerTimeService>(),
          clientUuidLoader: () => sl<LocalUuidService>().getOrCreateLocalUuid(),
          crashReporter: sl<VisitsCrashlyticsReporter>(),
          jailbreakDetector: sl<JailbreakDetector>(),
        ));

    // A single cubit instance survives the navigator so the AppBar badge
    // doesn't flicker between routes.
    sl.registerLazySingleton<OutboxStatusCubit>(() => OutboxStatusCubit(
          outbox: sl<OutboxRepository>(),
          dispatcher: sl<OutboxDispatcher>(),
        ));

    // ---- task renderer registry --------------------------------------

    registerBuiltInTaskRenderers(
      photos: sl<PhotoRepository>(),
      compressor: sl<PhotoCompressor>(),
      uploader: sl<PhotoUploadService>(),
    );
  }

  static Future<String> Function() _userCodeLoader(GetIt sl) {
    return () async {
      if (!sl.isRegistered<SharedPreferencesService>()) return '';
      final prefs = sl<SharedPreferencesService>();
      return prefs.getUserCode() ?? '';
    };
  }

  static Future<String> Function() _projectCodeLoader(GetIt sl) {
    return () async {
      if (!sl.isRegistered<ProjectContext>()) return '';
      return sl<ProjectContext>().activeProjectHeaderValue ?? '';
    };
  }
}

/// Convenience widget the host app can drop in to provide the visit BLoCs
/// to a screen subtree without each call site repeating the wiring.
class VisitsBlocProviders extends StatelessWidget {
  const VisitsBlocProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<VisitSessionBloc>(
          create: (_) => GetIt.instance<VisitSessionBloc>(),
        ),
        BlocProvider<OutboxStatusCubit>.value(
          value: GetIt.instance<OutboxStatusCubit>(),
        ),
      ],
      child: child,
    );
  }
}
