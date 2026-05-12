import 'package:equatable/equatable.dart';

import '../../../../core/services/images/unified_image.dart';

/// Snapshot of what the gallery knows about the per-org photo cap.
///
/// The cap value is server-authoritative and only revealed via a 409
/// [`customer_photo_limit_exceeded`] response — see [knownMax]. Until
/// the first 409 fires, [knownMax] is `null` and the badge stays
/// hidden.
class CustomerPhotoCapInfo extends Equatable {
  /// Total cap. `null` until the backend has surfaced it via a 409
  /// response. Once known, persists for the rest of the session.
  final int? knownMax;

  /// Most recent observed photo count. Always derived from the latest
  /// successful list response.
  final int current;

  const CustomerPhotoCapInfo({this.knownMax, this.current = 0});

  CustomerPhotoCapInfo withCurrent(int newCurrent) =>
      CustomerPhotoCapInfo(knownMax: knownMax, current: newCurrent);

  CustomerPhotoCapInfo withMax(int max, int current) =>
      CustomerPhotoCapInfo(knownMax: max, current: current);

  @override
  List<Object?> get props => [knownMax, current];
}

enum CustomerPhotoStatus { initial, loading, loaded, uploading, error }

/// State machine for the customer-photos gallery.
class CustomerPhotoState extends Equatable {
  final CustomerPhotoStatus status;

  /// Loaded photos. Empty when [status] is initial / loading / error
  /// before the first fetch.
  final List<UnifiedImage> photos;

  /// Cap info — see [CustomerPhotoCapInfo].
  final CustomerPhotoCapInfo cap;

  /// Number of photos currently being uploaded (for the progress
  /// indicator). 0 outside the [CustomerPhotoStatus.uploading] window.
  final int uploadingCount;

  /// Number of uploads that have completed in the current batch — used
  /// to render "x / y" progress.
  final int uploadCompleted;

  /// ARB key (NOT user-facing string) describing the most recent
  /// error — UI maps to localised copy. `null` when no error pending.
  final String? errorCode;

  /// Backend-supplied numeric details on the most recent error (e.g.
  /// `{max, current, available}` for the cap exceeded case). UI uses
  /// these to render "{current}/{max}" inline.
  final Map<String, dynamic>? errorDetails;

  const CustomerPhotoState({
    this.status = CustomerPhotoStatus.initial,
    this.photos = const <UnifiedImage>[],
    this.cap = const CustomerPhotoCapInfo(),
    this.uploadingCount = 0,
    this.uploadCompleted = 0,
    this.errorCode,
    this.errorDetails,
  });

  CustomerPhotoState copyWith({
    CustomerPhotoStatus? status,
    List<UnifiedImage>? photos,
    CustomerPhotoCapInfo? cap,
    int? uploadingCount,
    int? uploadCompleted,
    String? errorCode,
    Map<String, dynamic>? errorDetails,
    bool clearError = false,
  }) {
    return CustomerPhotoState(
      status: status ?? this.status,
      photos: photos ?? this.photos,
      cap: cap ?? this.cap,
      uploadingCount: uploadingCount ?? this.uploadingCount,
      uploadCompleted: uploadCompleted ?? this.uploadCompleted,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      errorDetails: clearError ? null : (errorDetails ?? this.errorDetails),
    );
  }

  @override
  List<Object?> get props => [
        status,
        photos,
        cap,
        uploadingCount,
        uploadCompleted,
        errorCode,
        errorDetails,
      ];
}
