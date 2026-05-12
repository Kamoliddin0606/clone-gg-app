import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/services/images/image_cache_manager.dart';
import '../../../core/services/images/unified_image.dart';
import '../data/repositories/customer_photo_repository.dart';

/// Orchestration layer that wraps [CustomerPhotoRepository].
///
/// **Responsibilities**
/// - Wait-for-ready polling for the async `pending → processing →
///   ready/failed` lifecycle.
/// - Re-throw the typed [CustomerPhotoCapExceeded] /
///   [CustomerPhotoValidationFailed] aliases so the cubit does not
///   need to inspect string error codes.
/// - Evict the per-photo image-cache entries on a successful replace
///   so widgets reload fresh variant URLs.
class CustomerPhotoService {
  static const Duration _defaultPollInterval = Duration(milliseconds: 1500);
  static const Duration _defaultPollTimeout = Duration(seconds: 20);

  final CustomerPhotoRepository _repo;

  CustomerPhotoService({required CustomerPhotoRepository repo}) : _repo = repo;

  // ---------------------------------------------------------------------------
  // Reads (proxied)
  // ---------------------------------------------------------------------------

  Future<List<UnifiedImage>> list(String customerId) =>
      _repo.list(customerId, ordering: 'order');

  Future<UnifiedImage> retrieve(String customerId, String photoId) =>
      _repo.retrieve(customerId, photoId);

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /// Upload one photo and (best-effort) wait until processing finishes.
  ///
  /// Returns the row in its final state (`ready` or `failed`). On a
  /// polling timeout returns the last observed row (still `pending`
  /// or `processing`) — the cubit will re-poll on the next list
  /// refresh.
  Future<UnifiedImage> addOne({
    required String customerId,
    required File image,
    String alt = '',
    int order = 0,
    bool isPrimary = false,
  }) async {
    final UnifiedImage created;
    try {
      created = await _repo.uploadOne(
        customerId: customerId,
        image: image,
        alt: alt,
        order: order,
        isPrimary: isPrimary,
      );
    } on CustomerPhotoException catch (e) {
      throw _mapException(e);
    }
    return _safelyWaitForReady(customerId: customerId, photoId: created.id);
  }

  /// Bulk upload. Atomic on the server: if it would breach the cap,
  /// zero rows are created and a [CustomerPhotoCapExceeded] is thrown.
  Future<List<UnifiedImage>> addMany({
    required String customerId,
    required List<File> images,
  }) async {
    if (images.isEmpty) return const <UnifiedImage>[];
    final List<UnifiedImage> rows;
    try {
      rows = await _repo.uploadBulk(customerId: customerId, images: images);
    } on CustomerPhotoException catch (e) {
      throw _mapException(e);
    }
    // Poll each row in parallel; tolerant of timeouts.
    final futures = rows.map(
      (r) => _safelyWaitForReady(customerId: customerId, photoId: r.id),
    );
    return Future.wait(futures);
  }

  Future<UnifiedImage> patchMetadata({
    required String customerId,
    required String photoId,
    String? alt,
    int? order,
    bool? isPrimary,
  }) async {
    try {
      return await _repo.patchMetadata(
        customerId: customerId,
        photoId: photoId,
        alt: alt,
        order: order,
        isPrimary: isPrimary,
      );
    } on CustomerPhotoException catch (e) {
      throw _mapException(e);
    }
  }

  /// Replace the file in an existing photo row. Old variant URLs are
  /// evicted from the image cache once processing finishes so widgets
  /// stop rendering the stale image.
  Future<UnifiedImage> replace({
    required String customerId,
    required String photoId,
    required File image,
  }) async {
    // Snapshot the old URLs BEFORE the replace so we can evict them
    // even though the immediate response will already carry the new
    // (or null) variant set.
    List<String> oldUrls = const <String>[];
    try {
      final before = await _repo.retrieve(customerId, photoId);
      oldUrls = <String>[
        if (before.smallUrl != null) before.smallUrl!,
        if (before.mediumUrl != null) before.mediumUrl!,
        if (before.largeUrl != null) before.largeUrl!,
      ];
    } catch (_) {
      // If we can't read the row, skip eviction — worst case the user
      // sees a brief stale image.
    }

    try {
      await _repo.replaceFile(
        customerId: customerId,
        photoId: photoId,
        image: image,
      );
    } on CustomerPhotoException catch (e) {
      throw _mapException(e);
    }

    final after = await _safelyWaitForReady(
      customerId: customerId,
      photoId: photoId,
    );
    await _evictUrls(oldUrls);
    return after;
  }

  Future<void> delete({
    required String customerId,
    required String photoId,
  }) async {
    try {
      await _repo.delete(customerId: customerId, photoId: photoId);
    } on CustomerPhotoException catch (e) {
      throw _mapException(e);
    }
  }

  /// Reprocess a failed row. Backend currently always returns
  /// `image_reprocess_not_supported` — that surface as
  /// [CustomerPhotoReprocessUnsupported].
  Future<void> reprocess({
    required String customerId,
    required String photoId,
  }) async {
    try {
      await _repo.reprocess(customerId: customerId, photoId: photoId);
    } on CustomerPhotoException catch (e) {
      throw _mapException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Polling
  // ---------------------------------------------------------------------------

  /// Poll the row detail until [_isTerminal] returns true or the
  /// timeout fires. Public so the cubit can re-poll a stuck row from
  /// the UI ("refresh" pull) without going through a write.
  Future<UnifiedImage> waitForReady({
    required String customerId,
    required String photoId,
    Duration interval = _defaultPollInterval,
    Duration timeout = _defaultPollTimeout,
  }) async {
    final deadline = DateTime.now().add(timeout);
    UnifiedImage? last;
    while (true) {
      try {
        final row = await _repo.retrieve(customerId, photoId);
        last = row;
        if (_isTerminal(row)) return row;
      } on CustomerPhotoException catch (e) {
        // 404 mid-poll → row gone, surface so caller refreshes list.
        if (e.statusCode == 404) {
          throw _mapException(e);
        }
        // Other transient errors: retry until the deadline.
      }
      if (!DateTime.now().isBefore(deadline)) {
        // Timed out — return last observed row (or refetch one final
        // time so the caller sees the latest state).
        return last ?? await _repo.retrieve(customerId, photoId);
      }
      await Future<void>.delayed(interval);
    }
  }

  /// Same as [waitForReady] but never throws — on any error, returns
  /// the row we managed to fetch most recently (or refetches one
  /// final time so the caller always gets *something* to render).
  Future<UnifiedImage> _safelyWaitForReady({
    required String customerId,
    required String photoId,
  }) async {
    try {
      return await waitForReady(customerId: customerId, photoId: photoId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CustomerPhotoService: polling fallback for $photoId: $e');
      }
      try {
        return await _repo.retrieve(customerId, photoId);
      } catch (_) {
        rethrow;
      }
    }
  }

  bool _isTerminal(UnifiedImage row) {
    // The mobile [UnifiedImage] doesn't carry a `status` field — but
    // a `ready` row always has at least one variant URL; a `failed`
    // row will never get one. We consider the presence of any URL the
    // signal that processing finished. (This matches what
    // ClientImageWidget already keys off for the read pipeline.)
    return row.hasUrl;
  }

  Future<void> _evictUrls(List<String> urls) async {
    if (urls.isEmpty) return;
    for (final url in urls) {
      try {
        await ImageCacheManager.instance.removeFile(url);
      } catch (_) {
        // Best-effort — eviction errors must not surface to the user.
      }
    }
  }

  /// Map the raw [CustomerPhotoException.code] to the typed alias the
  /// cubit / UI cares about. Anything we don't recognise re-surfaces
  /// as the generic [CustomerPhotoException] so the UI shows the
  /// fallback "unknown error" message.
  CustomerPhotoException _mapException(CustomerPhotoException e) {
    switch (e.code) {
      case 'customer_photo_limit_exceeded':
        final d = e.details ?? const <String, dynamic>{};
        return CustomerPhotoCapExceeded(
          max: (d['max'] as num?)?.toInt() ?? 0,
          current: (d['current'] as num?)?.toInt() ?? 0,
          available: (d['available'] as num?)?.toInt() ?? 0,
          requested: (d['requested'] as num?)?.toInt() ?? 0,
          message: e.message,
        );
      case 'image_too_large':
      case 'image_invalid_format':
      case 'image_dimensions_too_small':
      case 'image_dimensions_too_large':
      case 'image_not_failed':
        return CustomerPhotoValidationFailed(
          code: e.code,
          message: e.message,
          details: e.details,
        );
      case 'image_reprocess_not_supported':
        return CustomerPhotoReprocessUnsupported(message: e.message);
      default:
        return e;
    }
  }
}

/// Thrown when the org cap is reached. UI maps to the localised
/// "Chegara to'lgan ({current}/{max})" copy.
class CustomerPhotoCapExceeded extends CustomerPhotoException {
  final int max;
  final int current;
  final int available;
  final int requested;

  const CustomerPhotoCapExceeded({
    required this.max,
    required this.current,
    required this.available,
    required this.requested,
    required super.message,
  }) : super(
          code: 'customer_photo_limit_exceeded',
          statusCode: 409,
        );
}

/// Validation error from the upload pipeline (size / format / dims).
class CustomerPhotoValidationFailed extends CustomerPhotoException {
  const CustomerPhotoValidationFailed({
    required super.code,
    required super.message,
    super.details,
  }) : super(statusCode: 400);
}

/// Backend signals a failed row cannot be reprocessed (no original
/// kept). UI surfaces "O'chirib qayta yuklang".
class CustomerPhotoReprocessUnsupported extends CustomerPhotoException {
  const CustomerPhotoReprocessUnsupported({required super.message})
      : super(
          code: 'image_reprocess_not_supported',
          statusCode: 400,
        );
}
