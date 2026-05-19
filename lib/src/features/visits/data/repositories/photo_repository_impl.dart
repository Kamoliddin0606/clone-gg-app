import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../../domain/repositories/photo_repository.dart';
import '../local/photo_uploads_data_source.dart';

/// Concrete photo repository.
///
/// `capture` does the lightweight on-device work (SHA-256 + insert) but
/// leaves heavy lifting (compression, EXIF strip, thumbnail) to a service
/// invoked by the UI layer before calling `capture` — the data layer
/// receives an already-prepared [File].
class PhotoRepositoryImpl implements PhotoRepository {
  PhotoRepositoryImpl(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final PhotoUploadsDataSource _db;
  final Uuid _uuid;

  @override
  Future<PhotoUpload> capture({
    required String visitId,
    required String taskCode,
    String? taskId,
    required File source,
    double? lat,
    double? lng,
    double? accuracyM,
  }) async {
    final bytes = await source.readAsBytes();
    final digest = sha256.convert(bytes).toString();
    final upload = PhotoUpload(
      assetId: _uuid.v7(),
      visitId: visitId,
      taskId: taskId,
      taskCode: taskCode,
      localPath: source.path,
      sha256: digest,
      sizeBytes: bytes.length,
      capturedAt: DateTime.now().toUtc(),
      lat: lat,
      lng: lng,
      accuracyM: accuracyM,
      status: 'pending',
      idempotencyKey: _uuid.v7(),
      createdAt: DateTime.now().toUtc(),
    );
    await _db.insert(upload);
    return upload;
  }

  @override
  Future<List<PhotoUpload>> findUploadable() => _db.findUploadable();

  @override
  Future<List<PhotoUpload>> findByTask(String visitId, String taskId) =>
      _db.findByTask(visitId, taskId);

  @override
  Future<void> markUploading(String assetId) =>
      _db.updateStatus(assetId, status: 'uploading');

  @override
  Future<void> markConfirmed(String assetId,
          {required String remoteAssetId}) =>
      _db.updateStatus(assetId,
          status: 'confirmed', remoteAssetId: remoteAssetId);

  @override
  Future<void> markFailed(String assetId, String error,
          {bool incrementAttempt = true}) =>
      _db.updateStatus(assetId,
          status: 'failed',
          lastError: error,
          incrementAttempts: incrementAttempt);

  @override
  Future<void> delete(String assetId) => _db.delete(assetId);

  @override
  Future<bool> allConfirmedFor(String visitId) =>
      _db.allConfirmedFor(visitId);

  @override
  Future<bool> noFailedFor(String visitId) => _db.noFailedFor(visitId);
}
