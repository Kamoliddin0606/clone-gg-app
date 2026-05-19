import 'dart:io';

/// Per-photo capture record stored in `photo_uploads`.
class PhotoUpload {
  const PhotoUpload({
    required this.assetId,
    required this.visitId,
    required this.taskCode,
    required this.localPath,
    required this.sha256,
    required this.sizeBytes,
    required this.capturedAt,
    required this.status,
    required this.idempotencyKey,
    required this.createdAt,
    this.taskId,
    this.thumbnailPath,
    this.width,
    this.height,
    this.lat,
    this.lng,
    this.accuracyM,
    this.remoteAssetId,
    this.attempts = 0,
    this.lastError,
  });

  /// UUIDv7 the device assigns the moment the user snaps the shutter.
  final String assetId;

  final String visitId;
  final String? taskId;
  final String taskCode;
  final String localPath;
  final String? thumbnailPath;
  final String sha256;
  final int sizeBytes;
  final int? width;
  final int? height;
  final DateTime capturedAt;
  final double? lat;
  final double? lng;
  final double? accuracyM;

  /// `pending` | `uploading` | `confirmed` | `failed`.
  final String status;

  /// Server `EntityImage.id` returned by `POST /visits/{id}/photos/`. Used
  /// to populate `task.payload.photo_asset_ids` in the finish envelope.
  final String? remoteAssetId;

  final int attempts;
  final String? lastError;
  final String idempotencyKey;
  final DateTime createdAt;
}

abstract class PhotoRepository {
  /// Inserts a freshly captured photo. The data layer takes care of EXIF
  /// strip, SHA-256, thumbnail.
  Future<PhotoUpload> capture({
    required String visitId,
    required String taskCode,
    String? taskId,
    required File source,
    double? lat,
    double? lng,
    double? accuracyM,
  });

  /// Returns rows ready to upload (`pending` and `failed` with attempts left).
  Future<List<PhotoUpload>> findUploadable();

  /// Photos attached to a task, for UI thumbnails.
  Future<List<PhotoUpload>> findByTask(String visitId, String taskId);

  Future<void> markUploading(String assetId);
  Future<void> markConfirmed(String assetId, {required String remoteAssetId});
  Future<void> markFailed(String assetId, String error,
      {bool incrementAttempt = true});

  /// User removed a photo before the visit finished.
  Future<void> delete(String assetId);

  /// Have all photos attached to [visitId] been confirmed by the server?
  ///
  /// Strict check — only `status='confirmed'` counts. Older callers used
  /// this as a hard pre-finish gate; the backend's 2026-05-17 changelog
  /// softened `PhotoIntegrityValidator` so this is no longer required.
  /// Kept here for callers who still want the strict view (visit detail
  /// screens, observability badges).
  Future<bool> allConfirmedFor(String visitId);

  /// True when [visitId] has no `failed` photo rows.
  ///
  /// Backend changelog § 2 (2026-05-17): `PhotoIntegrityValidator`
  /// accepts `pending`/`processing`/`ready`. Mobile only has to make
  /// sure no asset is in a terminal-failure state before letting the
  /// agent tap finish — the dispatcher will keep retrying uploads in
  /// the background, and the backend accepts the envelope while photos
  /// are still mid-pipeline.
  Future<bool> noFailedFor(String visitId);
}
