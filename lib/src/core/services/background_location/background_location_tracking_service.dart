// =============================================================================
// Background Location Tracking Service (V2 — yangi server)
// =============================================================================
//
// Bu service fonda joylashuv/telemetry ma'lumotlarini yig'ib, durable
// `telemetry_outbox` (sqflite) ga yozadi va internet bor bo'lganda
// `TelemetryDispatcher` orqali batch ko'rinishida serverga yuboradi.
//
// PROFESSIONAL ARXITEKTURA (audit asosida qayta qurilgan):
// - COLLECT-FIRST / SEND-IF-ONLINE: har yozuv avval outbox'ga yoziladi
//   (GPS yoki internet holatidan qat'i nazar), so'ng yuborishga urinadi.
//   Yuborish endi yig'ishni hech qachon bloklamaydi.
// - GPS-DAN MUSTAQIL: yig'ish konveyeri location-service/permission darvozasi
//   ortida EMAS. GPS o'chiq bo'lsa "lokatsiyasiz heartbeat" (null koordinata +
//   oxirgi ma'lum joylashuv + batareya/tarmoq/qurilma) yoziladi.
// - BATAREYA-TEJAMKOR: asosiy pozitsiya manbai distanceFilter'li position
//   stream (OS tomonidan batch qilinadi) — har tick'da yuqori-aniqlikdagi
//   `getCurrentPosition` polling QILINMAYDI.
// - GPS AUTO-REARM: `getServiceStatusStream()` orqali GPS yoqilganda stream
//   avtomatik tiklanadi.
// - DURABLE: SharedPreferences JSON navbat o'rniga sqflite outbox (idempotency,
//   backoff, 4xx/5xx/401 klassifikatsiya — `TelemetryDispatcher`).
//
// Endpoint: POST {V2}/api/mobile/v1/telemetry/pings/  (dispatcher orqali)
// =============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';
// `ServiceStatus` is exported by both geolocator and permission_handler — we
// want geolocator's (location-service on/off), so hide the permission_handler one.
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;
import 'package:uuid/uuid.dart';

import 'package:gloria_marketing_flutter/src/core/services/background_location/foreground_service_keeper.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/helpers/device_data_collector.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/outbox/telemetry_dispatcher.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/outbox/telemetry_outbox_entry.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/outbox/telemetry_outbox_repository.dart';
import 'package:gloria_marketing_flutter/src/core/services/local_uuid_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/telemetry_v2/device_registration_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/telemetry_v2/rest_logging.dart';
import 'package:gloria_marketing_flutter/src/core/services/telemetry_v2/models/telemetry_ping_request.dart';
import 'package:gloria_marketing_flutter/src/core/services/telemetry_v2/models/tracking_policy.dart';
import 'package:gloria_marketing_flutter/src/core/services/telemetry_v2/models/tracking_policy_envelope.dart';
import 'package:gloria_marketing_flutter/src/core/services/telemetry_v2/tracking_policy_service.dart';
import 'package:gloria_marketing_flutter/src/features/visits/infra/sync/connectivity_listener.dart';

/// Why background tracking is degraded / not collecting fixes. Persisted to
/// SharedPrefs (`_lastFailureKey`) so diagnostic UI can surface a concrete
/// reason. NOTE: with the new collect-first design these are no longer
/// "fatal" — collection (heartbeat) continues even when a fresh GPS fix is
/// unavailable; the reason only explains why coordinates may be missing.
enum BackgroundLocationFailureReason {
  none,
  locationServiceDisabled,
  foregroundPermissionMissing,
  backgroundPermissionMissing,
  notLoggedIn,
  noToken,
  noNetwork,
  policyDisabled,
  unknown,
}

class BackgroundLocationTrackingService {
  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const int _defaultIntervalSeconds = 60;
  static const int _minIntervalSeconds = 10;
  static const Duration _policyRefreshInterval = Duration(minutes: 15);

  static const String _lastLocationUpdateKey =
      'background_location_v2_last_update';
  static const String _trackingEnabledKey =
      'background_location_tracking_enabled';
  static const String _lastFailureKey = 'background_location_last_failure';
  static const String _lastFailureAtKey = 'background_location_last_failure_at';

  /// Legacy SharedPreferences queue key — drained into the sqflite outbox once
  /// on first run after the upgrade, then removed (no data left behind).
  static const String _legacyOfflineQueueKey =
      'background_location_v2_offline_queue';

  /// How long a cached position is still acceptable as the "current" fix before
  /// we treat it as stale (a heartbeat with `location_source=last_known`).
  static const Duration _positionFreshness = Duration(minutes: 2);

  // ===========================================================================
  // DEPENDENCIES
  // ===========================================================================

  final SharedPreferencesService _prefs;
  final TrackingPolicyService _policyService;
  final DeviceRegistrationService _deviceRegistrationService;
  final TelemetryOutboxRepository _outbox;
  final TelemetryDispatcher _dispatcher;
  final LocalUuidService _uuidService;
  final ConnectivityListener _connectivity;
  final DeviceDataCollector _deviceDataCollector = DeviceDataCollector();
  final ForegroundServiceKeeper _foregroundKeeper = ForegroundServiceKeeper();
  final Uuid _uuid = const Uuid();

  // ===========================================================================
  // STATE
  // ===========================================================================

  Timer? _collectTimer;
  Timer? _policyTimer;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<ServiceStatus>? _serviceStatusSub;

  bool _isInitialized = false;
  bool _isTrackingActive = false;

  int _currentIntervalSeconds = _defaultIntervalSeconds;
  Position? _lastPosition;
  DateTime? _lastPositionAt;

  PackageInfo? _packageInfo;

  /// Guards against overlapping collect ticks.
  bool _isCollecting = false;

  /// Cached pending count for the (sync) diagnostics getter.
  int _lastKnownQueueSize = 0;

  bool _loggedPermissionMissing = false;

  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================

  BackgroundLocationTrackingService({
    required SharedPreferencesService prefs,
    required TrackingPolicyService policyService,
    required DeviceRegistrationService deviceRegistrationService,
    required TelemetryOutboxRepository outbox,
    required TelemetryDispatcher dispatcher,
    required LocalUuidService uuidService,
    required ConnectivityListener connectivity,
  })  : _prefs = prefs,
        _policyService = policyService,
        _deviceRegistrationService = deviceRegistrationService,
        _outbox = outbox,
        _dispatcher = dispatcher,
        _uuidService = uuidService,
        _connectivity = connectivity;

  // ===========================================================================
  // PUBLIC GETTERS (backward-compatible)
  // ===========================================================================

  bool get isTrackingActive => _isTrackingActive;
  int get currentIntervalSeconds => _currentIntervalSeconds;

  /// Cached pending-row count. Kept for diagnostic UI backward compat; the
  /// authoritative source is now [TelemetryOutboxRepository.countByStatus].
  int get offlineQueueSize => _lastKnownQueueSize;

  String? get lastFailureReason =>
      _prefs.preferences.getString(_lastFailureKey);
  String? get lastFailureAt => _prefs.preferences.getString(_lastFailureAtKey);

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;

      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Initializing (V2, outbox)...');
      }

      // Cached policy (offline-first).
      final cachedEnvelope = await _policyService.loadFromCache();
      if (cachedEnvelope != null) {
        _applyPolicyInterval(cachedEnvelope.policy);
      }

      try {
        _packageInfo = await PackageInfo.fromPlatform();
      } catch (_) {
        _packageInfo = null;
      }

      // One-time migration of the legacy SharedPreferences queue → outbox so no
      // previously-collected ping is lost across the upgrade.
      await _migrateLegacyQueue();

      // Reactive flush on connectivity regained (uses distinct() so we only
      // fire on real transitions). Independent of GPS state.
      _connectivitySub?.cancel();
      _connectivitySub = _connectivity.watch().listen((online) {
        if (online) {
          // ignore: unawaited_futures
          _drain();
        }
      });

      // Initial-state flush: connectivity_plus' stream only emits on CHANGE, so
      // a relaunch that is already online would never wake the listener. Kick a
      // drain here, independent of the GPS gate.
      if (await _connectivity.isOnline) {
        // ignore: unawaited_futures
        _drain();
      }

      _isInitialized = true;
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: Initialized. '
            'interval=$_currentIntervalSeconds s');
      }
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: init error: $e\n$st');
      }
      return false;
    }
  }

  Future<void> _migrateLegacyQueue() async {
    try {
      final raw = _prefs.preferences.getString(_legacyOfflineQueueKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final now = DateTime.now();
        for (final item in decoded.whereType<Map>()) {
          final payload = Map<String, dynamic>.from(item);
          final pingId = _uuid.v4();
          payload['metadata'] = <String, dynamic>{
            ...?(payload['metadata'] as Map?)?.cast<String, dynamic>(),
            'idempotency_key': pingId,
            'migrated_from': 'sharedprefs_v2',
          };
          DateTime loggedAt = now;
          final la = payload['logged_at'];
          if (la is String) {
            try {
              loggedAt = DateTime.parse(la);
            } catch (_) {}
          }
          await _outbox.enqueue(TelemetryOutboxEntry(
            pingId: pingId,
            payloadJson: jsonEncode(payload),
            clientUuid: await _safeClientUuid(),
            idempotencyKey: pingId,
            status: TelemetryOutboxEntry.statusPending,
            attempts: 0,
            maxAttempts: 12,
            nextAttemptAt: now,
            loggedAt: loggedAt,
            createdAt: now,
            updatedAt: now,
          ));
        }
      }
      await _prefs.preferences.remove(_legacyOfflineQueueKey);
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: migrated legacy queue → outbox');
      }
    } catch (e) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: legacy migration error: $e');
      }
    }
  }

  // ===========================================================================
  // TRACKING CONTROL
  // ===========================================================================

  Future<bool> startTracking() async {
    try {
      if (!_isInitialized) {
        final ok = await initialize();
        if (!ok) return false;
      }
      if (_isTrackingActive) {
        // Already running — still kick a drain in case a backlog accumulated.
        // ignore: unawaited_futures
        _drain();
        return true;
      }

      // Diagnostics only — NEVER gates collection (collect-first design).
      final reason = await _checkLocationPermission();
      if (reason != BackgroundLocationFailureReason.none) {
        await _recordFailure(reason);
        if (kDebugMode && !_loggedPermissionMissing) {
          _loggedPermissionMissing = true;
          print('BackgroundLocationTrackingService: degraded → ${reason.name} '
              '(collection continues in heartbeat mode; fixes resume when '
              'GPS/permission is available)');
        }
      } else {
        _loggedPermissionMissing = false;
        await _clearFailure();
      }

      // Policy + device registration (failure-tolerant).
      // ignore: unawaited_futures
      _refreshPolicy();
      // ignore: unawaited_futures
      _deviceRegistrationService.register();

      // Position stream — only when the OS can actually deliver fixes. Heartbeat
      // collection runs regardless.
      final canFix = reason == BackgroundLocationFailureReason.none;
      if (canFix) {
        _startPositionStream();
      }

      // Auto-rearm: react to the OS location toggle so we don't depend on an
      // app resume to recover fixes (audit O1/O7).
      _startServiceStatusListener();

      // Foreground service keeps the process (and our timer) alive in the
      // background — as long as we at least have foreground location permission.
      if (reason == BackgroundLocationFailureReason.none ||
          reason == BackgroundLocationFailureReason.locationServiceDisabled ||
          reason == BackgroundLocationFailureReason.backgroundPermissionMissing) {
        // ignore: unawaited_futures
        _foregroundKeeper.start();
      }

      _startCollectTimer();
      _startPolicyTimer();

      _isTrackingActive = true;
      await _prefs.preferences.setBool(_trackingEnabledKey, true);

      // Immediate first tick + drain any backlog.
      // ignore: unawaited_futures
      _collectTick();
      // ignore: unawaited_futures
      _drain();

      if (kDebugMode) {
        print('BackgroundLocationTrackingService: tracking started '
            '(canFix=$canFix)');
      }
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: startTracking error: $e\n$st');
      }
      return false;
    }
  }

  Future<void> stopTracking() async {
    try {
      _collectTimer?.cancel();
      _collectTimer = null;
      _policyTimer?.cancel();
      _policyTimer = null;
      await _positionStream?.cancel();
      _positionStream = null;
      await _serviceStatusSub?.cancel();
      _serviceStatusSub = null;
      await _foregroundKeeper.stop();
      await _prefs.preferences.setBool(_trackingEnabledKey, false);
      _isTrackingActive = false;
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: tracking stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: stopTracking error: $e');
      }
    }
  }

  Future<void> dispose() async {
    try {
      _collectTimer?.cancel();
      _policyTimer?.cancel();
      await _positionStream?.cancel();
      await _connectivitySub?.cancel();
      await _serviceStatusSub?.cancel();
      await _foregroundKeeper.stop();
      _collectTimer = null;
      _policyTimer = null;
      _positionStream = null;
      _connectivitySub = null;
      _serviceStatusSub = null;
      _isInitialized = false;
      _isTrackingActive = false;
    } catch (e) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: dispose error: $e');
      }
    }
  }

  // ===========================================================================
  // PERMISSION (diagnostics only — does NOT gate collection)
  // ===========================================================================

  Future<BackgroundLocationFailureReason> _checkLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return BackgroundLocationFailureReason.locationServiceDisabled;
      }
      final permission = await Geolocator.checkPermission();
      final hasForeground = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (!hasForeground) {
        return BackgroundLocationFailureReason.foregroundPermissionMissing;
      }
      if (permission != LocationPermission.always) {
        try {
          final bg = await Permission.locationAlways.status;
          if (!bg.isGranted) {
            return BackgroundLocationFailureReason.backgroundPermissionMissing;
          }
        } catch (_) {
          // permission_handler unavailable on this platform — accept whileInUse.
        }
      }
      return BackgroundLocationFailureReason.none;
    } catch (_) {
      return BackgroundLocationFailureReason.unknown;
    }
  }

  // ===========================================================================
  // FAILURE DIAGNOSTICS
  // ===========================================================================

  Future<void> _recordFailure(BackgroundLocationFailureReason reason) async {
    try {
      await _prefs.preferences.setString(_lastFailureKey, reason.name);
      await _prefs.preferences
          .setString(_lastFailureAtKey, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  Future<void> _clearFailure() async {
    try {
      if (_prefs.preferences.getString(_lastFailureKey) == null) return;
      await _prefs.preferences.remove(_lastFailureKey);
      await _prefs.preferences.remove(_lastFailureAtKey);
    } catch (_) {}
  }

  // ===========================================================================
  // TIMERS & STREAMS
  // ===========================================================================

  void _startCollectTimer() {
    _collectTimer?.cancel();
    _collectTimer = Timer.periodic(
      Duration(seconds: _currentIntervalSeconds),
      (_) => _collectTick(),
    );
  }

  void _startPolicyTimer() {
    _policyTimer?.cancel();
    _policyTimer =
        Timer.periodic(_policyRefreshInterval, (_) => _refreshPolicy());
  }

  void _startPositionStream() {
    _positionStream?.cancel();
    final policy = _policyService.cached?.policy;
    _positionStream = Geolocator.getPositionStream(
      locationSettings: _streamSettings(policy),
    ).listen(
      (position) {
        _lastPosition = position;
        _lastPositionAt = DateTime.now();
      },
      onError: (e) {
        if (kDebugMode) {
          print('BackgroundLocationTrackingService: position stream error: $e');
        }
      },
    );
  }

  void _startServiceStatusListener() {
    _serviceStatusSub?.cancel();
    try {
      _serviceStatusSub = Geolocator.getServiceStatusStream().listen((status) {
        if (status == ServiceStatus.enabled) {
          if (kDebugMode) {
            print('BackgroundLocationTrackingService: GPS enabled → rearming '
                'position stream');
          }
          _clearFailure();
          _startPositionStream();
          // ignore: unawaited_futures
          _drain();
        } else {
          // GPS turned off — stop the stream to save battery. Heartbeat
          // collection continues via the timer.
          // ignore: unawaited_futures
          _positionStream?.cancel();
          _positionStream = null;
          _recordFailure(BackgroundLocationFailureReason.locationServiceDisabled);
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: serviceStatusStream '
            'unavailable: $e');
      }
    }
  }

  /// Battery-friendly stream settings derived from the server policy. The OS
  /// batches updates and only wakes us when the device moves >= distanceFilter,
  /// which is far cheaper than per-tick high-accuracy polling.
  LocationSettings _streamSettings(TrackingPolicy? policy) {
    final minAcc = policy?.gpsMinAccuracyMeters ?? 0;
    final LocationAccuracy accuracy;
    if (minAcc > 0 && minAcc <= 20) {
      accuracy = LocationAccuracy.high;
    } else {
      accuracy = LocationAccuracy.medium; // default: battery-friendly
    }
    final minDist = policy?.gpsMinDistanceMeters ?? 0;
    final distanceFilter = minDist > 0 ? minDist.round() : 0;
    return LocationSettings(accuracy: accuracy, distanceFilter: distanceFilter);
  }

  Future<void> _refreshPolicy() async {
    try {
      final envelope = await _policyService.fetchPolicy();
      if (envelope != null) {
        _applyPolicyInterval(envelope.policy);
      }
    } catch (e) {
      if (kDebugMode) {
        print('BackgroundLocationTrackingService: refreshPolicy error: $e');
      }
    }
  }

  void _applyPolicyInterval(TrackingPolicy policy) {
    final raw = policy.gpsIntervalSeconds;
    if (raw <= 0) return;
    final clamped = raw < _minIntervalSeconds ? _minIntervalSeconds : raw;
    if (clamped == _currentIntervalSeconds) return;
    _currentIntervalSeconds = clamped;
    if (_isTrackingActive) {
      _startCollectTimer();
      // Re-tune the stream's distanceFilter/accuracy too.
      if (_positionStream != null) _startPositionStream();
    }
  }

  // ===========================================================================
  // COLLECTION (collect-first → enqueue → drain)
  // ===========================================================================

  Future<void> _collectTick() async {
    if (_isCollecting) return;
    _isCollecting = true;
    try {
      final envelope =
          _policyService.cached ?? TrackingPolicyEnvelope.safeDefault();
      final policy = envelope.policy;

      // Server-controlled gates (intentional config — honored).
      if (!_policyService.shouldCollectGps(policy)) {
        await _recordFailure(BackgroundLocationFailureReason.policyDisabled);
        return;
      }
      final now = DateTime.now();
      if (!_policyService.isWithinActiveHours(policy, now)) return;
      if (!_policyService.isWithinActiveDays(policy, now)) return;

      // Resolve the best available position WITHOUT a blocking high-accuracy
      // request: prefer the fresh streamed fix, fall back to the OS last-known
      // cache. If neither exists we still emit a heartbeat (collect-always).
      Position? position = _freshStreamPosition();
      String locationSource = 'gps';
      if (position == null) {
        try {
          position = await Geolocator.getLastKnownPosition();
        } catch (_) {
          position = null;
        }
        locationSource = position != null ? 'last_known' : 'none';
      } else {
        _lastPosition = position;
      }

      final ping = await _buildPing(
        position: position,
        policy: policy,
        locationSource: locationSource,
      );

      await _enqueue(ping, loggedAt: ping.loggedAt ?? now);
      await _prefs.preferences
          .setString(_lastLocationUpdateKey, now.toIso8601String());

      // Send-if-online (non-blocking for collection).
      // ignore: unawaited_futures
      _drain();
    } catch (e, st) {
      restLog('GPS', 'ERROR _collectTick: $e\n$st');
    } finally {
      _isCollecting = false;
    }
  }

  Position? _freshStreamPosition() {
    final p = _lastPosition;
    final at = _lastPositionAt;
    if (p == null || at == null) return null;
    if (DateTime.now().difference(at) > _positionFreshness) return null;
    return p;
  }

  Future<void> _enqueue(TelemetryPingRequest ping, {required DateTime loggedAt}) async {
    final pingId = _uuid.v4();
    final clientUuid = await _safeClientUuid();
    final payload = ping.toJson();
    // Embed idempotency + client uuid so the server can dedup replays.
    final meta = <String, dynamic>{
      ...?ping.metadata,
      'idempotency_key': pingId,
      'client_uuid': clientUuid,
    };
    payload['metadata'] = meta;

    final now = DateTime.now();
    await _outbox.enqueue(TelemetryOutboxEntry(
      pingId: pingId,
      payloadJson: jsonEncode(payload),
      clientUuid: clientUuid,
      idempotencyKey: pingId,
      status: TelemetryOutboxEntry.statusPending,
      attempts: 0,
      maxAttempts: 12,
      nextAttemptAt: now,
      loggedAt: loggedAt,
      createdAt: now,
      updatedAt: now,
    ));
    _lastKnownQueueSize++;
  }

  Future<void> _drain() async {
    try {
      await _dispatcher.cycle();
    } catch (_) {
    } finally {
      // Refresh cached count for diagnostics (best-effort).
      try {
        final counts = await _outbox.countByStatus();
        _lastKnownQueueSize = (counts[TelemetryOutboxEntry.statusPending] ?? 0) +
            (counts[TelemetryOutboxEntry.statusRetrying] ?? 0) +
            (counts[TelemetryOutboxEntry.statusInFlight] ?? 0);
      } catch (_) {}
    }
  }

  Future<String> _safeClientUuid() async {
    try {
      return await _uuidService.getOrCreateLocalUuid();
    } catch (_) {
      return '';
    }
  }

  // ===========================================================================
  // PAYLOAD
  // ===========================================================================

  Future<TelemetryPingRequest> _buildPing({
    required Position? position,
    required TrackingPolicy policy,
    required String locationSource,
  }) async {
    final agentCode = _prefs.getUserCode() ?? '';
    final agentName = _prefs.getUserName();
    final agentPhone = _prefs.getTelegramID();
    final region = _prefs.getServerName();
    final deviceData = await _deviceDataCollector.collectAllData();
    final pkg = _packageInfo ?? await _safePackageInfo();

    String? toFixedString(double? v, int n) => v?.toStringAsFixed(n);

    String? batteryLevel,
        batteryHealth,
        batteryTemperature,
        batteryVoltage;
    bool? isCharging;
    if (policy.collectBattery) {
      batteryLevel = deviceData['battery_level']?.toString();
      isCharging = deviceData['is_charging'] as bool?;
      batteryHealth = deviceData['battery_health'] as String?;
      batteryTemperature = deviceData['battery_temperature']?.toString();
      batteryVoltage = deviceData['battery_voltage']?.toString();
    }

    String? networkType,
        wifiSsid,
        wifiBssid,
        cellularOperator,
        cellularNetworkType,
        ipAddress,
        connectionType,
        signalStrength;
    if (policy.collectNetwork) {
      networkType = deviceData['network_type'] as String?;
      wifiSsid = deviceData['wifi_ssid'] as String?;
      wifiBssid = deviceData['wifi_bssid'] as String?;
      cellularOperator = deviceData['cellular_operator'] as String?;
      cellularNetworkType = deviceData['cellular_network_type'] as String?;
      ipAddress = deviceData['ip_address'] as String?;
      connectionType = deviceData['connection_type'] as String?;
      signalStrength = deviceData['signal_strength']?.toString();
    }

    String? deviceId,
        deviceName,
        deviceManufacturer,
        deviceModel,
        deviceFingerprint,
        platform,
        osVersion,
        screenDensity,
        appVersion,
        appBuildNumber,
        screenLockType;
    int? screenWidth, screenHeight, ramTotal, ramAvailable, storageTotal, storageAvailable;
    bool? cameraFront, cameraBack, isRooted, isJailbroken, encryptionEnabled;
    String? cameraResolution;
    if (policy.collectDeviceInfo) {
      deviceId = deviceData['device_id'] as String?;
      deviceName = deviceData['device_name'] as String?;
      deviceManufacturer = deviceData['device_manufacturer'] as String?;
      deviceModel = deviceData['device_model'] as String?;
      deviceFingerprint = deviceData['device_fingerprint'] as String?;
      platform = _normalizePlatform(deviceData['platform'] as String?);
      osVersion = deviceData['os_version'] as String?;
      screenWidth = deviceData['screen_width'] as int?;
      screenHeight = deviceData['screen_height'] as int?;
      screenDensity = deviceData['screen_density'] as String?;
      appVersion = pkg?.version;
      appBuildNumber = pkg?.buildNumber;
      isRooted = deviceData['is_rooted'] as bool?;
      isJailbroken = deviceData['is_jailbroken'] as bool?;
      encryptionEnabled = deviceData['encryption_enabled'] as bool?;
      screenLockType = deviceData['screen_lock_type'] as String?;
      ramTotal = deviceData['ram_total'] as int?;
      ramAvailable = deviceData['ram_available'] as int?;
      storageTotal = deviceData['storage_total'] as int?;
      storageAvailable = deviceData['storage_available'] as int?;
      cameraFront = deviceData['camera_front'] as bool?;
      cameraBack = deviceData['camera_back'] as bool?;
      cameraResolution = deviceData['camera_resolution'] as String?;
    } else {
      // Always send device_id + platform so the server links the ping to a Device.
      deviceId = deviceData['device_id'] as String?;
      platform = _normalizePlatform(deviceData['platform'] as String?);
    }

    String? accelerometerX,
        accelerometerY,
        accelerometerZ,
        gyroscopeX,
        gyroscopeY,
        gyroscopeZ,
        magnetometerX,
        magnetometerY,
        magnetometerZ,
        proximitySensor,
        lightSensor,
        temperature,
        humidity,
        pressure;
    if (policy.collectSensors) {
      accelerometerX = deviceData['accelerometer_x']?.toString();
      accelerometerY = deviceData['accelerometer_y']?.toString();
      accelerometerZ = deviceData['accelerometer_z']?.toString();
      gyroscopeX = deviceData['gyroscope_x']?.toString();
      gyroscopeY = deviceData['gyroscope_y']?.toString();
      gyroscopeZ = deviceData['gyroscope_z']?.toString();
      magnetometerX = deviceData['magnetometer_x']?.toString();
      magnetometerY = deviceData['magnetometer_y']?.toString();
      magnetometerZ = deviceData['magnetometer_z']?.toString();
      proximitySensor = deviceData['proximity_sensor']?.toString();
      lightSensor = deviceData['light_sensor']?.toString();
      temperature = deviceData['temperature']?.toString();
      humidity = deviceData['humidity']?.toString();
      pressure = deviceData['pressure']?.toString();
    }

    final hasFix = position != null;
    return TelemetryPingRequest(
      latitude: hasFix ? position.latitude.toStringAsFixed(6) : null,
      longitude: hasFix ? position.longitude.toStringAsFixed(6) : null,
      agentCode: agentCode.isEmpty ? null : agentCode,
      agentName: agentName,
      agentPhone: agentPhone,
      region: region,
      isActive: true,
      isDeleted: false,
      accuracy: hasFix ? toFixedString(position.accuracy, 2) : null,
      altitude: hasFix ? toFixedString(position.altitude, 2) : null,
      speed: hasFix ? toFixedString(position.speed, 2) : null,
      heading: hasFix ? toFixedString(position.heading, 2) : null,
      locationProvider: hasFix
          ? (locationSource == 'last_known' ? 'last_known' : 'geolocator')
          : 'none',
      timezone: deviceData['timezone'] as String?,
      deviceId: deviceId,
      deviceName: deviceName,
      deviceManufacturer: deviceManufacturer,
      deviceModel: deviceModel,
      deviceFingerprint: deviceFingerprint,
      platform: platform,
      osVersion: osVersion,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      screenDensity: screenDensity,
      ramTotal: ramTotal,
      ramAvailable: ramAvailable,
      storageTotal: storageTotal,
      storageAvailable: storageAvailable,
      cameraFront: cameraFront,
      cameraBack: cameraBack,
      cameraResolution: cameraResolution,
      appVersion: appVersion,
      appBuildNumber: appBuildNumber,
      batteryLevel: batteryLevel,
      isCharging: isCharging,
      batteryHealth: batteryHealth,
      batteryTemperature: batteryTemperature,
      batteryVoltage: batteryVoltage,
      signalStrength: signalStrength,
      networkType: networkType,
      wifiSsid: wifiSsid,
      wifiBssid: wifiBssid,
      cellularOperator: cellularOperator,
      cellularNetworkType: cellularNetworkType,
      ipAddress: ipAddress,
      connectionType: connectionType,
      accelerometerX: accelerometerX,
      accelerometerY: accelerometerY,
      accelerometerZ: accelerometerZ,
      gyroscopeX: gyroscopeX,
      gyroscopeY: gyroscopeY,
      gyroscopeZ: gyroscopeZ,
      magnetometerX: magnetometerX,
      magnetometerY: magnetometerY,
      magnetometerZ: magnetometerZ,
      proximitySensor: proximitySensor,
      lightSensor: lightSensor,
      temperature: temperature,
      humidity: humidity,
      pressure: pressure,
      isRooted: isRooted,
      isJailbroken: isJailbroken,
      encryptionEnabled: encryptionEnabled,
      screenLockType: screenLockType,
      // Heartbeat / staleness flags for the server timeline.
      metadata: <String, dynamic>{
        'location_source': locationSource,
        if (locationSource != 'gps') 'stale_location': true,
      },
      loggedAt: DateTime.now().toUtc(),
    );
  }

  String? _normalizePlatform(String? raw) {
    if (raw == null) return null;
    final lower = raw.toLowerCase();
    if (lower.contains('android')) return 'android';
    if (lower.contains('ios')) return 'ios';
    if (lower.contains('web')) return 'web';
    return 'other';
  }

  Future<PackageInfo?> _safePackageInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      return _packageInfo;
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // PUBLIC API (backward-compatible)
  // ===========================================================================

  /// Backward-compatible interval override (e.g. legacy SOAP policy push).
  Future<void> updateInterval(int intervalSeconds) async {
    if (intervalSeconds <= 0) return;
    final clamped = intervalSeconds < _minIntervalSeconds
        ? _minIntervalSeconds
        : intervalSeconds;
    if (clamped == _currentIntervalSeconds) return;
    _currentIntervalSeconds = clamped;
    if (_isTrackingActive) _startCollectTimer();
  }

  /// Drain trigger usable by the Workmanager isolate / external callers.
  Future<void> flushOutbox() => _drain();

  /// Logout hygiene — wipe the backlog so it can't be re-uploaded under a
  /// different user's token (audit H5).
  Future<void> clearOfflineQueue() async {
    await _outbox.purgeAll();
    _lastKnownQueueSize = 0;
  }

  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'isTrackingActive': _isTrackingActive,
      'currentIntervalSeconds': _currentIntervalSeconds,
      'pendingQueueSize': _lastKnownQueueSize,
      'lastPosition': _lastPosition != null
          ? '${_lastPosition!.latitude}, ${_lastPosition!.longitude}'
          : null,
      'lastUpdate': _prefs.preferences.getString(_lastLocationUpdateKey),
      'cachedPolicySource': _policyService.cached?.source.toServerValue(),
      'lastFailureReason': lastFailureReason,
      'lastFailureAt': lastFailureAt,
    };
  }

  /// Live outbox status counts (pending/in_flight/retrying/dead_letter) for the
  /// diagnostics surface.
  Future<Map<String, int>> outboxStatusCounts() => _outbox.countByStatus();
}
