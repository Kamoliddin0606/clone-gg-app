/// `POST /api/mobile/v1/telemetry/pings/` javobi.
///
/// Server policy buzgan yozuvlarni `rejected[]` ga o'tkazadi (silent drop),
/// lekin butun batch fail qilmaydi.
class TelemetryAcceptedResponse {
  final List<String> accepted;
  final int acceptedCount;
  final List<RejectedPing> rejected;
  final int rejectedCount;
  final String? deviceId;

  const TelemetryAcceptedResponse({
    required this.accepted,
    required this.acceptedCount,
    required this.rejected,
    required this.rejectedCount,
    required this.deviceId,
  });

  factory TelemetryAcceptedResponse.fromJson(Map<String, dynamic> json) {
    final acceptedRaw = json['accepted'];
    final List<String> accepted = acceptedRaw is List
        ? acceptedRaw.map((e) => e.toString()).toList()
        : <String>[];

    final rejectedRaw = json['rejected'];
    final List<RejectedPing> rejected = rejectedRaw is List
        ? rejectedRaw
            .whereType<Map>()
            .map((e) => RejectedPing.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <RejectedPing>[];

    return TelemetryAcceptedResponse(
      accepted: accepted,
      acceptedCount: (json['accepted_count'] as int?) ?? accepted.length,
      rejected: rejected,
      rejectedCount: (json['rejected_count'] as int?) ?? rejected.length,
      deviceId: json['device'] as String?,
    );
  }
}

class RejectedPing {
  final int index;
  final String reason;

  const RejectedPing({required this.index, required this.reason});

  factory RejectedPing.fromJson(Map<String, dynamic> json) {
    return RejectedPing(
      index: (json['index'] as int?) ?? -1,
      reason: (json['reason'] as String?) ?? 'unknown',
    );
  }
}
