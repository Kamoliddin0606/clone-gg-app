import 'package:gloria_marketing_flutter/src/core/version/domain/version_gate_status.dart';

/// JSON contract for `GET /api/mobile/v2/app/version-check/` and for the
/// 426 body that the backend middleware emits on stale-version requests.
///
/// All string fields default to empty (never null) so the UI can call
/// `text.isNotEmpty` without sprinkling null checks.
class VersionGateResponse {
  final VersionGateStatus status;
  final String app;
  final String platform;
  final String currentVersion;
  final String latestVersion;
  final String minSupportedVersion;
  final String storeUrl;
  final String releaseNotes;
  final String title;
  final String message;
  final bool canDismiss;
  final DateTime checkedAt;

  const VersionGateResponse({
    required this.status,
    required this.app,
    required this.platform,
    required this.currentVersion,
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.storeUrl,
    required this.releaseNotes,
    required this.title,
    required this.message,
    required this.canDismiss,
    required this.checkedAt,
  });

  factory VersionGateResponse.fromJson(Map<String, dynamic> json) {
    return VersionGateResponse(
      status: VersionGateStatus.fromString(json['status'] as String?),
      app: (json['app'] as String?) ?? '',
      platform: (json['platform'] as String?) ?? '',
      currentVersion: (json['current_version'] as String?) ?? '',
      latestVersion: (json['latest_version'] as String?) ?? '',
      minSupportedVersion: (json['min_supported_version'] as String?) ?? '',
      storeUrl: (json['store_url'] as String?) ?? '',
      releaseNotes: (json['release_notes'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      canDismiss: (json['can_dismiss'] as bool?) ?? false,
      checkedAt: _parseDate(json['checked_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status.wireValue,
        'app': app,
        'platform': platform,
        'current_version': currentVersion,
        'latest_version': latestVersion,
        'min_supported_version': minSupportedVersion,
        'store_url': storeUrl,
        'release_notes': releaseNotes,
        'title': title,
        'message': message,
        'can_dismiss': canDismiss,
        'checked_at': checkedAt.toUtc().toIso8601String(),
      };

  static DateTime _parseDate(Object? raw) {
    if (raw is String && raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed.toUtc();
    }
    return DateTime.now().toUtc();
  }
}
