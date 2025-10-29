import 'dart:math';
import 'package:yandex_maps_mapkit/mapkit.dart' as mk;

double haversineKm(mk.Point a, mk.Point b) {
  const R = 6371.0;
  final dLat = _deg2rad(b.latitude - a.latitude);
  final dLng = _deg2rad(b.longitude - a.longitude);
  final lat1 = _deg2rad(a.latitude);
  final lat2 = _deg2rad(b.latitude);

  final x = sin(dLat/2)*sin(dLat/2) + cos(lat1)*cos(lat2)*sin(dLng/2)*sin(dLng/2);
  final c = 2 * atan2(sqrt(x), sqrt(1 - x));
  return R * c;
}

String estimateTravelTimeCity(double distanceKm, {double speedKmh = 40}) {
  final minutes = ((distanceKm / speedKmh) * 60).round();
  if (minutes < 60) return '$minutes daqiqa';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m > 0 ? '$h soat $m daqiqa' : '$h soat';
}

double computeZoomForBounds(List<mk.Point> pts) {
  if (pts.isEmpty) return 16.0;
  double minLat = pts.first.latitude, maxLat = pts.first.latitude;
  double minLng = pts.first.longitude, maxLng = pts.first.longitude;
  for (final p in pts) {
    minLat = min(minLat, p.latitude);
    maxLat = max(maxLat, p.latitude);
    minLng = min(minLng, p.longitude);
    maxLng = max(maxLng, p.longitude);
  }
  final maxDiff = max((maxLat - minLat).abs(), (maxLng - minLng).abs());
  if (maxDiff == 0) return 16.0;
  return max(0.0, 16.0 - log(maxDiff * 111000) / log(2));
}

double _deg2rad(double d) => d * pi / 180.0;