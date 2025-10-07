import 'package:flutter/foundation.dart';
import '../services/shared_preferences_service.dart';

enum ServerEnv { Evyap, Garnier, PPD, Avon, AvonTest }

extension ServerEnvX on ServerEnv {
  String get label => switch (this) {
    ServerEnv.Evyap    => 'Evyap',
    ServerEnv.Garnier => 'Garnier',
    ServerEnv.PPD    => 'PPD',
    ServerEnv.Avon     => 'Avon',
    ServerEnv.AvonTest     => 'Avon Test',

  };

  String get url => switch (this) {
    ServerEnv.Evyap    => 'http://kit.gloriya.uz:5443/EVYAP_UT/EVYAP_UT.1cws',
    ServerEnv.Garnier => 'http://kit.gloriya.uz:5443/loreal_ut/loreal_ut.1cws',
    ServerEnv.PPD    => 'http://kit.gloriya.uz:5443/UT_Professionnel/UT_Professionnel.1cws',
    ServerEnv.Avon     => 'http://kit.gloriya.uz:5443/AVON_UT/AVON_UT.1cws',
    ServerEnv.AvonTest     => 'http://kit.gloriya.uz:5443/TEST_UT/TEST_UT.1cws',
  };
}

class ServerService {
  static const _kKey = 'selected_server_env';
  final SharedPreferencesService _prefs;

  /// Tanlangan serverni hamma joyga tarqatish uchun
  final ValueNotifier<ServerEnv> current = ValueNotifier(ServerEnv.Evyap);

  ServerService(this._prefs);

  Future<void> restore() async {
    final name = _prefs.getServerName();
    final env = ServerEnv.values.firstWhere(
          (e) => e.name == name,
      orElse: () => ServerEnv.Evyap,
    );
    current.value = env;
  }

  Future<void> set(ServerEnv env) async {
    current.value = env;
    await _prefs.setServerName(env.name);
    await _prefs.setBaseUrl(env.url);
  }

  String get baseUrl => current.value.url;
}
