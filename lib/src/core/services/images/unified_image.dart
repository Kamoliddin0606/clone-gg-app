import 'package:equatable/equatable.dart';

/// Image size category requested by the consuming widget.
///
/// The four buckets line up with the variant ladder the backend
/// produces (small / medium / large WebP) so widgets can request a
/// canonical size without touching URL math.
enum UnifiedImageSize {
  /// 48-64px — compact list rows, dense grids.
  thumbnail,

  /// 80-120px — standard list rows.
  small,

  /// 150-200px — grid tiles, card headers.
  medium,

  /// 300+px — detail pages, full-screen views.
  large,
}

/// Single image record consumed by the image widgets.
///
/// Maps 1-to-1 to a row from `GET /api/mobile/v1/images/`. The mobile
/// app stores no image metadata locally any more — every render path
/// goes through [NewBackendImageRepository] and surfaces a
/// [UnifiedImage] for the widget to draw.
class UnifiedImage extends Equatable {
  /// Backend-assigned image UUID. Opaque to the UI.
  final String id;

  /// One of `product` / `customer` / `project`. The wire format may be
  /// `projectproduct` (Django ContentType.model name); the repository
  /// normalises both to the canonical key here.
  final String targetType;

  /// Backend UUID of the owning entity. Opaque — never displayed,
  /// never persisted on the mobile side. Use [targetCode1c] when
  /// matching against the local catalog.
  final String targetId;

  /// Owning organisation UUID. Required by the backend filter; the
  /// resolver passes it through verbatim from the calling widget.
  final String targetOrganizationId;

  /// 1C code of the owning entity. This is what the mobile catalog
  /// keys by (`product.code` / `client.code` / `project.id_1c`).
  /// Empty only on transitional rows where the backend's
  /// `code_1c` denorm hasn't fired yet — callers should treat
  /// empty as "no usable identifier".
  final String targetCode1c;

  /// Variant URLs. `null` only while the backend is still processing
  /// the upload (`status="processing"`); the mobile endpoint silently
  /// filters such rows out, so production reads never see this state.
  final String? smallUrl;
  final String? mediumUrl;
  final String? largeUrl;

  /// BlurHash placeholder string. Empty string when the backend has
  /// not (yet) computed one; widgets fall back to a generic shimmer.
  final String blurhash;

  /// Source dimensions. Optional — backend reports them once
  /// processing completes.
  final int? width;
  final int? height;

  /// Whether this row is the cover for the target's gallery.
  final bool isPrimary;

  /// Optional alt text. Empty when not provided.
  final String alt;

  /// Sort order within the target's gallery.
  final int order;

  const UnifiedImage({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.targetOrganizationId,
    required this.targetCode1c,
    required this.smallUrl,
    required this.mediumUrl,
    required this.largeUrl,
    required this.blurhash,
    required this.width,
    required this.height,
    required this.isPrimary,
    required this.alt,
    required this.order,
  });

  /// Returns the URL the widget should load for the given [size],
  /// falling back through the variant chain when the preferred one
  /// is missing. Returns `null` when no variant is available.
  String? urlForSize(UnifiedImageSize size) {
    switch (size) {
      case UnifiedImageSize.thumbnail:
      case UnifiedImageSize.small:
        return smallUrl ?? mediumUrl ?? largeUrl;
      case UnifiedImageSize.medium:
        return mediumUrl ?? smallUrl ?? largeUrl;
      case UnifiedImageSize.large:
        return largeUrl ?? mediumUrl ?? smallUrl;
    }
  }

  /// True when at least one variant URL is available.
  bool get hasUrl => smallUrl != null || mediumUrl != null || largeUrl != null;

  /// True when the BlurHash placeholder string is present.
  bool get hasBlurhash => blurhash.isNotEmpty;

  /// Returns a copy of this image with the given fields replaced.
  /// Used by [CustomerPhotoCubit.setPrimaryOptimistic] to flip
  /// `isPrimary` locally before the PATCH round-trip completes.
  UnifiedImage copyWith({
    String? id,
    String? targetType,
    String? targetId,
    String? targetOrganizationId,
    String? targetCode1c,
    String? smallUrl,
    String? mediumUrl,
    String? largeUrl,
    String? blurhash,
    int? width,
    int? height,
    bool? isPrimary,
    String? alt,
    int? order,
  }) {
    return UnifiedImage(
      id: id ?? this.id,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      targetOrganizationId: targetOrganizationId ?? this.targetOrganizationId,
      targetCode1c: targetCode1c ?? this.targetCode1c,
      smallUrl: smallUrl ?? this.smallUrl,
      mediumUrl: mediumUrl ?? this.mediumUrl,
      largeUrl: largeUrl ?? this.largeUrl,
      blurhash: blurhash ?? this.blurhash,
      width: width ?? this.width,
      height: height ?? this.height,
      isPrimary: isPrimary ?? this.isPrimary,
      alt: alt ?? this.alt,
      order: order ?? this.order,
    );
  }

  @override
  List<Object?> get props => [
        id,
        targetType,
        targetId,
        targetOrganizationId,
        targetCode1c,
        smallUrl,
        mediumUrl,
        largeUrl,
        blurhash,
        width,
        height,
        isPrimary,
        alt,
        order,
      ];
}
