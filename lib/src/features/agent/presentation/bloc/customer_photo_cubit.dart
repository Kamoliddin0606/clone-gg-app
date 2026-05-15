import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/images/unified_image.dart';
import '../../../../core/services/service_locator.dart';
import '../../data/repositories/customer_photo_repository.dart';
import '../../services/customer_photo_change_notifier.dart';
import '../../services/customer_photo_service.dart';
import 'customer_photo_state.dart';

/// State holder for [CustomerPhotosPage].
///
/// Wraps [CustomerPhotoService] and serialises mutations per customer
/// so two simultaneous taps on the FAB do not stack into parallel
/// POSTs (the backend cap check is serialised per customer anyway —
/// concurrent client requests just collapse into serial 409s).
class CustomerPhotoCubit extends Cubit<CustomerPhotoState> {
  final String customerId;
  final CustomerPhotoService _service;

  /// Serial mutation queue. Each enqueued future is awaited in order.
  Future<void> _pendingChain = Future<void>.value();

  CustomerPhotoCubit({
    required this.customerId,
    required CustomerPhotoService service,
  })  : _service = service,
        super(const CustomerPhotoState());

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  Future<void> load() async {
    emit(state.copyWith(status: CustomerPhotoStatus.loading, clearError: true));
    try {
      final photos = await _service.list(customerId);
      emit(state.copyWith(
        status: CustomerPhotoStatus.loaded,
        photos: photos,
        cap: state.cap.withCurrent(photos.length),
        clearError: true,
      ));
    } catch (e) {
      _emitError(e);
    }
  }

  Future<void> refresh() => load();

  // ---------------------------------------------------------------------------
  // Mutations (serialised)
  // ---------------------------------------------------------------------------

  Future<void> addOne(File image, {bool isPrimary = false}) =>
      _enqueue(() => _addOne(image, isPrimary: isPrimary));

  Future<void> _addOne(File image, {bool isPrimary = false}) async {
    _emitUploading(total: 1, completed: 0);
    try {
      await _service.addOne(
        customerId: customerId,
        image: image,
        isPrimary: isPrimary,
        order: state.photos.length,
      );
      await load();
      _notifyChanged();
    } catch (e) {
      _emitError(e, keepPhotos: true);
    }
  }

  Future<void> addMany(List<File> images) =>
      _enqueue(() => _addMany(images));

  Future<void> _addMany(List<File> images) async {
    if (images.isEmpty) return;
    _emitUploading(total: images.length, completed: 0);
    try {
      await _service.addMany(customerId: customerId, images: images);
      await load();
      _notifyChanged();
    } catch (e) {
      _emitError(e, keepPhotos: true);
    }
  }

  Future<void> patch(
    String photoId, {
    String? alt,
    int? order,
    bool? isPrimary,
  }) =>
      _enqueue(() => _patch(photoId, alt: alt, order: order, isPrimary: isPrimary));

  Future<void> _patch(
    String photoId, {
    String? alt,
    int? order,
    bool? isPrimary,
  }) async {
    try {
      await _service.patchMetadata(
        customerId: customerId,
        photoId: photoId,
        alt: alt,
        order: order,
        isPrimary: isPrimary,
      );
      await load();
      _notifyChanged();
    } catch (e) {
      _emitError(e, keepPhotos: true);
    }
  }

  Future<void> setPrimary(String photoId) =>
      patch(photoId, isPrimary: true);

  /// Optimistic variant of [setPrimary] — flips the local `isPrimary`
  /// flags before the PATCH round-trip completes, then enqueues the
  /// real PATCH which (on success) reloads the list and reconciles
  /// any drift with the server's truth.
  Future<void> setPrimaryOptimistic(String photoId) {
    final updated = state.photos.map((p) {
      if (p.id == photoId) {
        return p.isPrimary ? p : p.copyWith(isPrimary: true);
      }
      return p.isPrimary ? p.copyWith(isPrimary: false) : p;
    }).toList()
      ..sort((a, b) {
        final pa = a.isPrimary ? 0 : 1;
        final pb = b.isPrimary ? 0 : 1;
        if (pa != pb) return pa - pb;
        return a.order.compareTo(b.order);
      });
    emit(state.copyWith(photos: updated));
    return setPrimary(photoId);
  }

  Future<void> replace(String photoId, File image) =>
      _enqueue(() => _replace(photoId, image));

  Future<void> _replace(String photoId, File image) async {
    _emitUploading(total: 1, completed: 0);
    try {
      await _service.replace(
        customerId: customerId,
        photoId: photoId,
        image: image,
      );
      await load();
      _notifyChanged();
    } catch (e) {
      _emitError(e, keepPhotos: true);
    }
  }

  Future<void> delete(String photoId) =>
      _enqueue(() => _delete(photoId));

  Future<void> _delete(String photoId) async {
    try {
      await _service.delete(customerId: customerId, photoId: photoId);
      await load();
      _notifyChanged();
    } catch (e) {
      _emitError(e, keepPhotos: true);
    }
  }

  Future<void> reprocess(String photoId) =>
      _enqueue(() => _reprocess(photoId));

  Future<void> _reprocess(String photoId) async {
    try {
      await _service.reprocess(customerId: customerId, photoId: photoId);
      await load();
      _notifyChanged();
    } catch (e) {
      _emitError(e, keepPhotos: true);
    }
  }

  void _notifyChanged() {
    if (sl.isRegistered<CustomerPhotoChangeNotifier>()) {
      sl<CustomerPhotoChangeNotifier>().notifyChanged(customerId);
    }
  }

  /// Clear the pending error after the UI displays it. (Banners /
  /// snackbars consume this.)
  void clearError() {
    if (state.errorCode == null) return;
    emit(state.copyWith(clearError: true));
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _enqueue(Future<void> Function() task) {
    final next = _pendingChain.then((_) => task()).catchError((e, st) {
      if (kDebugMode) {
        debugPrint('CustomerPhotoCubit: unhandled queue error: $e');
      }
    });
    _pendingChain = next;
    return next;
  }

  void _emitUploading({required int total, required int completed}) {
    emit(state.copyWith(
      status: CustomerPhotoStatus.uploading,
      uploadingCount: total,
      uploadCompleted: completed,
      clearError: true,
    ));
  }

  void _emitError(Object e, {bool keepPhotos = false}) {
    final errorCode = e is CustomerPhotoException ? e.code : 'unknown_error';
    final errorDetails = e is CustomerPhotoException ? e.details : null;

    // If the cap is the cause, capture the max so the badge can
    // start rendering immediately.
    CustomerPhotoCapInfo cap = state.cap;
    if (e is CustomerPhotoCapExceeded) {
      cap = cap.withMax(e.max, e.current);
    }

    emit(state.copyWith(
      status:
          keepPhotos ? CustomerPhotoStatus.loaded : CustomerPhotoStatus.error,
      errorCode: errorCode,
      errorDetails: errorDetails,
      cap: cap,
      uploadingCount: 0,
      uploadCompleted: 0,
    ));
  }

  /// Snapshot of the photos in the current state — exposed for tests.
  @visibleForTesting
  List<UnifiedImage> get currentPhotos => state.photos;
}
