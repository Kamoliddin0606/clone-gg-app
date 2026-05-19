import 'package:equatable/equatable.dart';

/// Server-side `EntityImage` shape — the photo variant URLs the backend
/// embeds in visit-detail responses for visit history / dead-letter
/// inspection screens.
///
/// Backend changelog § 3 (2026-05-17) — **photo retention**:
///   * 0-30 days → all variants present (small, medium, large, blurhash)
///   * 30-90 days → only `medium` + `blurhash`; small/large 404
///   * 90+ days  → row hard-deleted; the entire asset 404s
///
/// Callers must walk the fallback chain (`medium` → `blurhash` →
/// placeholder) — never assume `smallUrl` resolves on an aged visit.
class EntityImageRef extends Equatable {
  const EntityImageRef({
    required this.id,
    this.smallUrl,
    this.mediumUrl,
    this.largeUrl,
    this.blurhash,
    this.status = 'ready',
  });

  /// Backend `EntityImage.id`. Mobile keeps this so a 404 on any variant
  /// can be cross-referenced against the visit's `tasks[].payload.
  /// photo_asset_ids` for diagnostics.
  final String id;
  final String? smallUrl;
  final String? mediumUrl;
  final String? largeUrl;
  final String? blurhash;

  /// `pending` | `processing` | `ready` | `failed`. Pending photos are
  /// allowed in the envelope (changelog § 2) but their variant URLs
  /// stay `null` until the worker promotes the row to `ready`.
  final String status;

  factory EntityImageRef.fromJson(Map<String, dynamic> json) {
    return EntityImageRef(
      id: json['id'] as String,
      smallUrl: json['small_url'] as String?,
      mediumUrl: json['medium_url'] as String?,
      largeUrl: json['large_url'] as String?,
      blurhash: json['blurhash'] as String?,
      status: (json['status'] as String?) ?? 'ready',
    );
  }

  /// Preferred wire order for displaying a small thumbnail. Walks
  /// `small → medium`; falls back to `null` when both are gone (caller
  /// should render the blurhash or a placeholder).
  ///
  /// `large` is intentionally skipped here — using it as a thumbnail
  /// would burn bandwidth and is the first variant retention drops.
  String? get thumbnailUrl => smallUrl ?? mediumUrl;

  /// Preferred wire order for displaying a full-screen view. Walks
  /// `large → medium`. `medium` is the retention-safe variant.
  String? get fullUrl => largeUrl ?? mediumUrl;

  bool get hasAnyVariant =>
      smallUrl != null || mediumUrl != null || largeUrl != null;

  @override
  List<Object?> get props =>
      [id, smallUrl, mediumUrl, largeUrl, blurhash, status];
}
