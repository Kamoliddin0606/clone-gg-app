import 'package:equatable/equatable.dart';

import 'unified_image.dart';

/// One page of [UnifiedImage] records returned by an [ImageRepository].
///
/// The new backend paginates with cursor URLs (DRF cursor pagination);
/// the legacy host has no pagination. Both implementations return the
/// same envelope so consumer widgets do not branch on the source.
class UnifiedImagePage extends Equatable {
  /// Images on this page, already ordered by the backend.
  final List<UnifiedImage> images;

  /// Opaque cursor for the next page, or `null` when this is the last
  /// page. The new backend returns a full URL — pass it back to the
  /// repository unchanged. The legacy repository ALWAYS returns
  /// `null` here so consumer code never paginates against it.
  final String? nextCursor;

  const UnifiedImagePage({
    required this.images,
    required this.nextCursor,
  });

  static const UnifiedImagePage empty =
      UnifiedImagePage(images: <UnifiedImage>[], nextCursor: null);

  bool get isEmpty => images.isEmpty;
  bool get isNotEmpty => images.isNotEmpty;
  bool get hasMore => nextCursor != null;

  @override
  List<Object?> get props => [images, nextCursor];
}
