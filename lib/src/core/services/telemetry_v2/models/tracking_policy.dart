/// Mobile uchun tracking policy (yangi server schema'siga moslashgan).
///
/// Server javobi `MobileTrackingPolicyEnvelope.policy` ichida keladi.
/// Mobile bu qoidalarga ko'ra qaysi telemetry'ni qachon yig'ish va serverga
/// yuborishni hal qiladi.
class TrackingPolicy {
  final String id;
  final bool isActive;
  final bool isRequired;
  final bool gpsEnabled;
  final int gpsIntervalSeconds;
  final int gpsMinDistanceMeters;
  final int gpsMinAccuracyMeters;
  final bool collectDeviceInfo;
  final bool collectBattery;
  final bool collectNetwork;
  final bool collectSensors;

  /// `HH:mm:ss` formatda yoki null (har vaqt).
  final String? activeHoursStart;
  final String? activeHoursEnd;

  /// `['mon','tue',...]`. Bo'sh = har kun.
  final List<String> activeDays;

  const TrackingPolicy({
    required this.id,
    required this.isActive,
    required this.isRequired,
    required this.gpsEnabled,
    required this.gpsIntervalSeconds,
    required this.gpsMinDistanceMeters,
    required this.gpsMinAccuracyMeters,
    required this.collectDeviceInfo,
    required this.collectBattery,
    required this.collectNetwork,
    required this.collectSensors,
    required this.activeHoursStart,
    required this.activeHoursEnd,
    required this.activeDays,
  });

  /// Synthetic "default off" policy — server hech narsa qaytarmasa ishlatiladi.
  factory TrackingPolicy.defaultOff() {
    return const TrackingPolicy(
      id: '00000000-0000-0000-0000-000000000000',
      isActive: false,
      isRequired: false,
      gpsEnabled: false,
      gpsIntervalSeconds: 0,
      gpsMinDistanceMeters: 0,
      gpsMinAccuracyMeters: 0,
      collectDeviceInfo: false,
      collectBattery: false,
      collectNetwork: false,
      collectSensors: false,
      activeHoursStart: null,
      activeHoursEnd: null,
      activeDays: <String>[],
    );
  }

  factory TrackingPolicy.fromJson(Map<String, dynamic> json) {
    final daysRaw = json['active_days'];
    final List<String> days;
    if (daysRaw is List) {
      days = daysRaw.map((e) => e.toString()).toList();
    } else {
      days = const <String>[];
    }
    return TrackingPolicy(
      id: (json['id'] ?? '').toString(),
      isActive: (json['is_active'] as bool?) ?? false,
      isRequired: (json['is_required'] as bool?) ?? false,
      gpsEnabled: (json['gps_enabled'] as bool?) ?? false,
      gpsIntervalSeconds: (json['gps_interval_seconds'] as int?) ?? 0,
      gpsMinDistanceMeters: (json['gps_min_distance_meters'] as int?) ?? 0,
      gpsMinAccuracyMeters: (json['gps_min_accuracy_meters'] as int?) ?? 0,
      collectDeviceInfo: (json['collect_device_info'] as bool?) ?? false,
      collectBattery: (json['collect_battery'] as bool?) ?? false,
      collectNetwork: (json['collect_network'] as bool?) ?? false,
      collectSensors: (json['collect_sensors'] as bool?) ?? false,
      activeHoursStart: json['active_hours_start'] as String?,
      activeHoursEnd: json['active_hours_end'] as String?,
      activeDays: days,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'is_active': isActive,
      'is_required': isRequired,
      'gps_enabled': gpsEnabled,
      'gps_interval_seconds': gpsIntervalSeconds,
      'gps_min_distance_meters': gpsMinDistanceMeters,
      'gps_min_accuracy_meters': gpsMinAccuracyMeters,
      'collect_device_info': collectDeviceInfo,
      'collect_battery': collectBattery,
      'collect_network': collectNetwork,
      'collect_sensors': collectSensors,
      'active_hours_start': activeHoursStart,
      'active_hours_end': activeHoursEnd,
      'active_days': activeDays,
    };
  }
}
