import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../shared_preferences_service.dart';
import '../token_service.dart';
import 'models/tracking_policy.dart';
import 'models/tracking_policy_envelope.dart';
import 'rest_logging.dart';

/// Yangi serverdan tracking policyni olish va lokal cache'da saqlash uchun
/// servis. Filtrlash helperlari ham shu yerda — har ping yuborishdan oldin
/// `BackgroundLocationTrackingService` shu servis orqali tekshiradi.
///
/// Endpoint: `GET {v2BaseUrl}/api/mobile/v1/telemetry/policy/`
/// Cache: SharedPreferences. ETag bilan `304 Not Modified` qo'llab-quvvatlanadi.
class TrackingPolicyService {
  static const String _endpoint = '/api/mobile/v1/telemetry/policy/';

  static const String _cacheBodyKey = 'tracking_policy_v2_cache';
  static const String _cacheEtagKey = 'tracking_policy_v2_etag';
  static const String _cacheUpdatedAtKey = 'tracking_policy_v2_updated_at';

  final Dio _dio;
  final TokenService _tokenService;
  final SharedPreferencesService _prefs;

  TrackingPolicyEnvelope? _cached;

  TrackingPolicyService({
    required TokenService tokenService,
    required SharedPreferencesService prefs,
    Dio? dio,
  })  : _tokenService = tokenService,
        _prefs = prefs,
        _dio = dio ?? Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    attachRestLogger(_dio, 'POLICY');
  }

  /// Joriy cached policy. Yo'q bo'lsa null.
  TrackingPolicyEnvelope? get cached => _cached;

  /// SharedPreferences'dan cached policyni yuklash. Service ishga tushganda
  /// bir marta chaqirilsin.
  Future<TrackingPolicyEnvelope?> loadFromCache() async {
    try {
      final raw = _prefs.preferences.getString(_cacheBodyKey);
      if (raw == null || raw.isEmpty) {
        if (kDebugMode) {
          print('═══════════════════════════════════════════════════════════════');
          print('[POLICY-FLOW] 📂 loadFromCache → MISS (empty / no key)');
          print('  prefs key   : $_cacheBodyKey');
          print('═══════════════════════════════════════════════════════════════');
        }
        return null;
      }
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _cached = TrackingPolicyEnvelope.fromJson(json);
      if (kDebugMode) {
        final p = _cached!.policy;
        final updatedAt = _prefs.preferences.getString(_cacheUpdatedAtKey);
        final etag = _prefs.preferences.getString(_cacheEtagKey);
        print('═══════════════════════════════════════════════════════════════');
        print('[POLICY-FLOW] 📂 loadFromCache → HIT');
        print('  prefs key       : $_cacheBodyKey (${raw.length} chars)');
        print('  cached_etag     : $etag');
        print('  cached_updated  : $updatedAt');
        print('  envelope.source : ${_cached!.source.toServerValue()}');
        print('  envelope.rev    : ${_cached!.revision}');
        print('  policy.is_active: ${p.isActive}, gps_enabled: ${p.gpsEnabled}');
        print('  policy.interval : ${p.gpsIntervalSeconds}s, min_dist=${p.gpsMinDistanceMeters}m, min_acc=${p.gpsMinAccuracyMeters}m');
        print('  active_hours    : ${p.activeHoursStart} .. ${p.activeHoursEnd}');
        print('  active_days     : ${p.activeDays.isEmpty ? "[every day]" : p.activeDays}');
        print('═══════════════════════════════════════════════════════════════');
      }
      return _cached;
    } catch (e) {
      if (kDebugMode) {
        print('[POLICY-FLOW] ❌ loadFromCache error: $e');
      }
      return null;
    }
  }

  /// Yangi policyni serverdan olish. Cached etag mavjud bo'lsa
  /// `If-None-Match` yuboriladi va server `304` qaytarsa cached envelope
  /// qaytariladi.
  ///
  /// Network/auth xatolari bo'lsa null qaytaradi (cached saqlanadi).
  Future<TrackingPolicyEnvelope?> fetchPolicy() async {
    try {
      final token = await _tokenService.ensureValidV2Token();
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('TrackingPolicyService: No V2 token, skipping fetch');
        }
        return _cached;
      }

      final url = '${TokenService.v2BaseUrl}$_endpoint';
      final etag = _prefs.preferences.getString(_cacheEtagKey);
      final headers = <String, String>{
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };
      if (etag != null && etag.isNotEmpty) {
        headers['If-None-Match'] = etag;
      }
      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════════════');
        print('[POLICY-FLOW] 🌐 fetchPolicy → GET $url');
        print('  If-None-Match : ${etag ?? "(none — first fetch)"}');
        print('═══════════════════════════════════════════════════════════════');
      }

      final response = await _dio.get(
        url,
        options: Options(
          headers: headers,
          validateStatus: (s) => s != null && (s == 200 || s == 304 || (s >= 400 && s < 500)),
        ),
      );

      if (response.statusCode == 304) {
        if (kDebugMode) {
          print('═══════════════════════════════════════════════════════════════');
          print('TrackingPolicyService: ✅ 304 NOT MODIFIED — server policy unchanged');
          print('  endpoint     : $url');
          print('  sent_etag    : $etag');
          print('  using cached : revision=${_cached?.revision} source=${_cached?.source.toServerValue()}');
          print('═══════════════════════════════════════════════════════════════');
        }
        return _cached ?? await loadFromCache();
      }

      if (response.statusCode == 200 && response.data is Map) {
        final body = response.data as Map<String, dynamic>;
        final envelope = TrackingPolicyEnvelope.fromJson(body);
        _cached = envelope;
        final headerEtag = response.headers.value('etag');
        await _saveToCache(envelope, headerEtag);
        if (kDebugMode) {
          final p = envelope.policy;
          print('═══════════════════════════════════════════════════════════════');
          print('TrackingPolicyService: ✅ POLICY RECEIVED FROM SERVER');
          print('  endpoint            : $url');
          print('  status              : ${response.statusCode}');
          print('  etag (header)       : $headerEtag');
          print('  etag (envelope)     : ${envelope.etag}');
          print('  revision            : ${envelope.revision}');
          print('  source              : ${envelope.source.toServerValue()}');
          print('  server_time         : ${envelope.serverTime}');
          print('  ── policy fields ──');
          print('  is_active           : ${p.isActive}');
          print('  is_required         : ${p.isRequired}');
          print('  gps_enabled         : ${p.gpsEnabled}');
          print('  gps_interval_seconds: ${p.gpsIntervalSeconds}');
          print('  gps_min_distance_m  : ${p.gpsMinDistanceMeters}');
          print('  gps_min_accuracy_m  : ${p.gpsMinAccuracyMeters}');
          print('  collect_device_info : ${p.collectDeviceInfo}');
          print('  collect_battery     : ${p.collectBattery}');
          print('  collect_network     : ${p.collectNetwork}');
          print('  collect_sensors     : ${p.collectSensors}');
          print('  active_hours        : ${p.activeHoursStart} .. ${p.activeHoursEnd}');
          print('  active_days         : ${p.activeDays}');
          print('  extras              : ${envelope.extras}');
          print('  cached_to_keys      : $_cacheBodyKey, $_cacheEtagKey, $_cacheUpdatedAtKey');
          print('═══════════════════════════════════════════════════════════════');
        }
        return envelope;
      }

      if (kDebugMode) {
        print('TrackingPolicyService: Unexpected status=${response.statusCode}');
      }
      return _cached;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('TrackingPolicyService: DioException ${e.type} status=${e.response?.statusCode}');
      }
      return _cached;
    } catch (e) {
      if (kDebugMode) {
        print('TrackingPolicyService: fetchPolicy error: $e');
      }
      return _cached;
    }
  }

  Future<void> _saveToCache(TrackingPolicyEnvelope envelope, String? headerEtag) async {
    try {
      final etag = (headerEtag != null && headerEtag.isNotEmpty)
          ? headerEtag
          : envelope.etag;
      final body = jsonEncode(envelope.toJson());
      await _prefs.preferences.setString(_cacheBodyKey, body);
      if (etag.isNotEmpty) {
        await _prefs.preferences.setString(_cacheEtagKey, etag);
      }
      final updatedAt = DateTime.now().toIso8601String();
      await _prefs.preferences.setString(_cacheUpdatedAtKey, updatedAt);
      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════════════');
        print('[POLICY-FLOW] 💾 _saveToCache → WRITTEN');
        print('  $_cacheBodyKey      : ${body.length} chars JSON');
        print('  $_cacheEtagKey      : $etag');
        print('  $_cacheUpdatedAtKey : $updatedAt');
        print('═══════════════════════════════════════════════════════════════');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[POLICY-FLOW] ❌ _saveToCache error: $e');
      }
    }
  }

  Future<void> clearCache() async {
    _cached = null;
    await _prefs.preferences.remove(_cacheBodyKey);
    await _prefs.preferences.remove(_cacheEtagKey);
    await _prefs.preferences.remove(_cacheUpdatedAtKey);
    if (kDebugMode) {
      print('[POLICY-FLOW] 🗑️  clearCache → 3 keys removed (body/etag/updated_at)');
    }
  }

  // ===========================================================================
  // FILTERING HELPERS
  // ===========================================================================
  // Bu helperlar `BackgroundLocationTrackingService` tomonidan har ping
  // yuborishdan oldin chaqiriladi. Server ham xuddi shunday filterni qo'llaydi
  // va policy buzgan yozuvlarni `rejected[]` ga tushiradi, lekin mobile o'zi
  // filterlasa traffic va batareya tejaladi.

  /// GPS yig'ish kerakmi? `is_active=false` yoki `gps_enabled=false` bo'lsa false.
  bool shouldCollectGps(TrackingPolicy policy) {
    return policy.isActive && policy.gpsEnabled;
  }

  /// Joriy vaqt active_hours oynasi ichidami?
  /// `active_hours_start`/`end` null bo'lsa har vaqt true.
  bool isWithinActiveHours(TrackingPolicy policy, DateTime now) {
    final start = policy.activeHoursStart;
    final end = policy.activeHoursEnd;
    if (start == null || end == null) return true;
    final startMin = _parseHm(start);
    final endMin = _parseHm(end);
    if (startMin == null || endMin == null) return true;
    final nowMin = now.hour * 60 + now.minute;
    if (startMin == endMin) return true; // 24-soat
    if (startMin < endMin) {
      return nowMin >= startMin && nowMin < endMin;
    }
    // O'rta tunda kesib o'tadi (masalan 22:00-06:00)
    return nowMin >= startMin || nowMin < endMin;
  }

  int? _parseHm(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  /// Joriy hafta kuni active_days ro'yxatida bormi?
  /// Bo'sh ro'yxat = har kun.
  bool isWithinActiveDays(TrackingPolicy policy, DateTime now) {
    if (policy.activeDays.isEmpty) return true;
    const codes = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final code = codes[(now.weekday - 1).clamp(0, 6)];
    return policy.activeDays.contains(code);
  }

  /// Joriy aniqlik (metr) cheklovni qondirsamidi?
  /// `gps_min_accuracy_meters` 0 yoki manfiy bo'lsa cheksiz (har qanday qabul).
  bool isAccuracyAcceptable(TrackingPolicy policy, double accuracyMeters) {
    if (policy.gpsMinAccuracyMeters <= 0) return true;
    return accuracyMeters <= policy.gpsMinAccuracyMeters;
  }

  /// Oldingi va yangi pozitsiya orasidagi masofa policy talabidan kattami?
  /// `gps_min_distance_meters` 0 bo'lsa har doim true (filter o'chirilgan).
  /// `prev` null bo'lsa birinchi fix sifatida true qaytariladi.
  bool isDistanceAcceptable(
    TrackingPolicy policy,
    Position? prev,
    Position next,
  ) {
    if (policy.gpsMinDistanceMeters <= 0) return true;
    if (prev == null) return true;
    final meters = Geolocator.distanceBetween(
      prev.latitude,
      prev.longitude,
      next.latitude,
      next.longitude,
    );
    return meters >= policy.gpsMinDistanceMeters;
  }
}
