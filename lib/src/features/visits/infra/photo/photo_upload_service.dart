import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';

import '../../data/rest/visit_api.dart';
import '../../domain/failures.dart';
import '../../domain/repositories/photo_repository.dart';
import '../sync/connectivity_listener.dart';
import 'photo_compressor.dart';

/// Drives photo uploads independently of the visit-envelope outbox.
///
/// Photos must reach the server (with `status='confirmed'`) before the
/// finish envelope is allowed to leave — otherwise the backend rejects with
/// `VISITS_PHOTO_MISSING`. This service is the loop that makes that
/// invariant hold: pick up `pending`/`failed` rows, upload via [VisitApi],
/// stamp `remote_asset_id` on success.
class PhotoUploadService {
  PhotoUploadService({
    required PhotoRepository photos,
    required VisitApi api,
    required ConnectivityListener connectivity,
    required Future<String> Function() clientUuidLoader,
    PhotoCompressor? compressor,
  })  : _photos = photos,
        _api = api,
        _connectivity = connectivity,
        _clientUuid = clientUuidLoader,
        _compressor = compressor ?? PhotoCompressor();

  final PhotoRepository _photos;
  final VisitApi _api;
  final ConnectivityListener _connectivity;
  final Future<String> Function() _clientUuid;
  // Reserved for callers who want to recompress before upload retries
  // (current path compresses at capture time).
  // ignore: unused_field
  final PhotoCompressor _compressor;

  bool _running = false;

  /// Drains the queue. Re-entrant safe — concurrent invocations no-op.
  /// Triggered by: capture (immediate), connectivity flip, app foreground.
  Future<void> cycle() async {
    if (_running) return;
    _running = true;
    try {
      if (!await _connectivity.isOnline) return;

      final clientUuid = await _clientUuid();
      while (true) {
        final batch = await _photos.findUploadable();
        if (batch.isEmpty) break;

        for (final photo in batch) {
          await _uploadOne(photo, clientUuid);
        }
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _uploadOne(PhotoUpload photo, String clientUuid) async {
    final file = File(photo.localPath);
    if (!await file.exists()) {
      // Local file vanished (user cleared storage). Mark failed without
      // an attempt so the dead-letter UI can offer a delete.
      await _photos.markFailed(photo.assetId, 'local_file_missing',
          incrementAttempt: false);
      return;
    }

    await _photos.markUploading(photo.assetId);
    try {
      final remoteId = await _api.uploadPhoto(
        visitId: photo.visitId,
        file: file,
        clientUuid: clientUuid,
        idempotencyKey: photo.idempotencyKey,
        taskCode: photo.taskCode,
        capturedAt: photo.capturedAt,
        sha256: photo.sha256,
        lat: photo.lat,
        lng: photo.lng,
        accuracyM: photo.accuracyM,
      );
      await _photos.markConfirmed(photo.assetId, remoteAssetId: remoteId);
    } on DioException catch (e) {
      final mapped = e.error;
      final transient = mapped is NetworkFailure && mapped.transient;
      await _photos.markFailed(photo.assetId, mapped is Failure ? mapped.message : (e.message ?? 'dio_error'),
          incrementAttempt: !transient || photo.attempts >= 4);
      developer.log('Photo upload failed: ${photo.assetId}',
          name: 'visits.photos', error: e);
    } catch (e, st) {
      developer.log('Photo upload unexpected error',
          name: 'visits.photos', error: e, stackTrace: st);
      await _photos.markFailed(photo.assetId, e.toString());
    }
  }
}
