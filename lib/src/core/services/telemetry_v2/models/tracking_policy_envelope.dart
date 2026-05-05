import 'policy_source.dart';
import 'tracking_policy.dart';

/// `GET /api/mobile/v1/telemetry/policy/` javobining stable konverti.
///
/// Server yangi metadata field'larini qo'shsa ham mobile buzilmasligi uchun
/// envelope ishlatiladi. Mobile asosan `policy` ni o'qiydi, `revision`/`etag`
/// cache invalidatsiya uchun ishlatiladi.
class TrackingPolicyEnvelope {
  final int revision;
  final String etag;
  final PolicySource source;
  final DateTime serverTime;
  final TrackingPolicy policy;
  final Map<String, dynamic> extras;

  const TrackingPolicyEnvelope({
    required this.revision,
    required this.etag,
    required this.source,
    required this.serverTime,
    required this.policy,
    required this.extras,
  });

  /// Hech qanday policy yo'q yoki server javob bermaganda ishlatiladi —
  /// mobile `gps_enabled=false` bilan hech narsa to'plamaydi.
  factory TrackingPolicyEnvelope.defaultOff() {
    return TrackingPolicyEnvelope(
      revision: 0,
      etag: '',
      source: PolicySource.defaultOff,
      serverTime: DateTime.now().toUtc(),
      policy: TrackingPolicy.defaultOff(),
      extras: const <String, dynamic>{},
    );
  }

  factory TrackingPolicyEnvelope.fromJson(Map<String, dynamic> json) {
    final policyRaw = json['policy'];
    final TrackingPolicy policy;
    if (policyRaw is Map<String, dynamic>) {
      policy = TrackingPolicy.fromJson(policyRaw);
    } else {
      policy = TrackingPolicy.defaultOff();
    }

    final extrasRaw = json['extras'];
    final Map<String, dynamic> extras;
    if (extrasRaw is Map<String, dynamic>) {
      extras = Map<String, dynamic>.from(extrasRaw);
    } else {
      extras = const <String, dynamic>{};
    }

    DateTime parsedTime;
    final serverTimeStr = json['server_time'] as String?;
    if (serverTimeStr != null) {
      try {
        parsedTime = DateTime.parse(serverTimeStr);
      } catch (_) {
        parsedTime = DateTime.now().toUtc();
      }
    } else {
      parsedTime = DateTime.now().toUtc();
    }

    return TrackingPolicyEnvelope(
      revision: (json['revision'] as int?) ?? 0,
      etag: (json['etag'] as String?) ?? '',
      source: PolicySource.fromString(json['source'] as String?),
      serverTime: parsedTime,
      policy: policy,
      extras: extras,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'revision': revision,
      'etag': etag,
      'source': source.toServerValue(),
      'server_time': serverTime.toIso8601String(),
      'policy': policy.toJson(),
      'extras': extras,
    };
  }
}
