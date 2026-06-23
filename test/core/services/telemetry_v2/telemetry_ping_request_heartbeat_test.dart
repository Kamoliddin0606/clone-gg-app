import 'package:flutter_test/flutter_test.dart';

import 'package:gloria_marketing_flutter/src/core/services/telemetry_v2/models/telemetry_ping_request.dart';

/// Verifies the heartbeat (GPS-off) serialization contract: a ping with null
/// coordinates omits latitude/longitude entirely rather than emitting empty
/// strings, and still carries the device/metadata payload.
void main() {
  test('positioned ping serializes latitude/longitude', () {
    final json = const TelemetryPingRequest(
      latitude: '41.311081',
      longitude: '69.240562',
      locationProvider: 'geolocator',
    ).toJson();

    expect(json['latitude'], '41.311081');
    expect(json['longitude'], '69.240562');
    expect(json['location_provider'], 'geolocator');
  });

  test('heartbeat ping (null coords) omits latitude/longitude', () {
    final json = const TelemetryPingRequest(
      latitude: null,
      longitude: null,
      locationProvider: 'none',
      batteryLevel: '88',
      networkType: 'WiFi',
      metadata: {'location_source': 'none', 'stale_location': true},
    ).toJson();

    expect(json.containsKey('latitude'), isFalse);
    expect(json.containsKey('longitude'), isFalse);
    // Non-GPS context still travels with the heartbeat.
    expect(json['location_provider'], 'none');
    expect(json['battery_level'], '88');
    expect(json['network_type'], 'WiFi');
    expect((json['metadata'] as Map)['location_source'], 'none');
    expect((json['metadata'] as Map)['stale_location'], true);
  });

  test('round-trips through fromJson with null coords', () {
    final original = const TelemetryPingRequest(
      latitude: null,
      longitude: null,
      locationProvider: 'none',
    );
    final restored = TelemetryPingRequest.fromJson(original.toJson());
    expect(restored.latitude, isNull);
    expect(restored.longitude, isNull);
    expect(restored.locationProvider, 'none');
  });
}
