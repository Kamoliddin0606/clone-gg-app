import 'package:flutter/material.dart';

import '../../../../core/maps/models/map_settings.dart' show MapProvider;
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/shared_preferences_service.dart';
import '../../data/models/trading_point.dart';
import '../pages/map_pages/map_detail_page_google.dart';
import '../pages/map_pages/map_detail_page_osm.dart';
import '../pages/map_pages/map_detail_page_yandex.dart';

/// Single entry-point for the "edit customer coordinates" action used
/// from the trading-points list card, the grid tile, and the client
/// detail sheet.
///
/// Picks the user's default map provider (Google / OSM / Yandex) from
/// `SharedPreferences` and opens the matching `MapDetailPage*` with
/// `initialEditMode: true`. The map page already owns the
/// pan-to-edit + confirm UX and the SOAP save call; we extended
/// `DataSyncService.updateClientCoordinates` so the same save now
/// dual-writes to V2 too, satisfying the runbook's "both servers"
/// rule without each call-site doing it manually.
Future<void> openCustomerCoordinatesEditor(
  BuildContext context, {
  required TradingPoint tradingPoint,
}) async {
  final provider = _readDefaultMapProvider();
  Widget builder(_) {
    switch (provider) {
      case MapProvider.google:
        return MapDetailPageGoogle(
          tradingPoint: tradingPoint,
          initialEditMode: true,
        );
      case MapProvider.yandex:
        return MapDetailPageYandex(
          tradingPoint: tradingPoint,
          initialEditMode: true,
        );
      case MapProvider.openStreetMap:
        return MapDetailPageOsm(
          tradingPoint: tradingPoint,
          initialEditMode: true,
        );
    }
  }
  await Navigator.of(context).push(MaterialPageRoute(builder: builder));
}

MapProvider _readDefaultMapProvider() {
  try {
    final prefs = sl<SharedPreferencesService>();
    final saved = prefs.preferences.getString('default_map_provider');
    if (saved == null) return MapProvider.openStreetMap;
    return MapProvider.values.firstWhere(
      (p) => p.toString() == saved,
      orElse: () => MapProvider.openStreetMap,
    );
  } catch (_) {
    // SL not ready / prefs corrupt — fall back to OSM.
    return MapProvider.openStreetMap;
  }
}
