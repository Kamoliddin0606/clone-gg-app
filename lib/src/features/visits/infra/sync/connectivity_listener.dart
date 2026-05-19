import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around `connectivity_plus` that yields a simple
/// `Stream<bool>` (`true` ⇒ usable connection).
///
/// We treat wifi / mobile / ethernet / vpn as online. `none` and `bluetooth`
/// are offline — both reachable but useless for our REST traffic.
class ConnectivityListener {
  ConnectivityListener({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any(_isUsable);
  }

  Stream<bool> watch() {
    return _connectivity.onConnectivityChanged
        .map((results) => results.any(_isUsable))
        .distinct();
  }

  bool _isUsable(ConnectivityResult r) {
    return r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn;
  }
}
