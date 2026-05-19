import 'package:shared_preferences/shared_preferences.dart';

/// Tracks `client_now - server_time` so the visit pipeline can detect
/// tampered clocks and stamp envelopes with the drift value the backend
/// audits.
///
/// `sync()` is called from `RestV2Client` via the response interceptor,
/// not directly. The service therefore only needs a setter and a couple of
/// derived getters.
class ServerTimeService {
  ServerTimeService({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  int _deltaMs = 0;

  static const _prefsKey = 'visits_v2_server_time_delta_ms';

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _deltaMs = _prefs!.getInt(_prefsKey) ?? 0;
  }

  /// Called by the interceptor whenever a response carries `X-Server-Time`.
  void recordServerTime(DateTime serverUtc) {
    final delta =
        serverUtc.toUtc().millisecondsSinceEpoch - DateTime.now().toUtc().millisecondsSinceEpoch;
    _deltaMs = delta;
    // Fire-and-forget — we don't await prefs writes off the hot path.
    _prefs?.setInt(_prefsKey, delta);
  }

  /// Server-corrected `now`. Used by the envelope builder when stamping
  /// `started_at` / `finished_at` so per-task durations stay consistent
  /// across handsets with misaligned clocks.
  DateTime now() => DateTime.now().toUtc().add(Duration(milliseconds: _deltaMs));

  /// `client_now - server_time` in milliseconds. Positive ⇒ device is ahead.
  int get clientClockDriftMs => -_deltaMs;

  bool isDriftAcceptable({required int maxDriftS}) =>
      clientClockDriftMs.abs() <= maxDriftS * 1000;
}
