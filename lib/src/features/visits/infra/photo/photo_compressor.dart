import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Compresses captured images to a target size + dimension before they hit
/// the upload pipeline.
///
/// Lives in `infra/` rather than `data/` because compression is platform
/// glue, not domain shape. The repository receives an already-prepared
/// file and never touches EXIF / pixels.
class PhotoCompressor {
  PhotoCompressor({
    this.maxWidth = 1920,
    this.maxHeight = 1920,
    this.quality = 85,
    this.subfolder = 'visit_photos',
  });

  /// Pixel cap on the longer edge. 1920 keeps the file usable for shelf
  /// audit zoom while staying well under typical 4G upload budgets.
  final int maxWidth;
  final int maxHeight;

  /// JPEG quality 0..100. The passport calls for 85; we expose it so a
  /// future "low bandwidth" toggle can drop it without code surgery.
  final int quality;

  /// Subdirectory under `getApplicationDocumentsDirectory()`. Photos
  /// outlive the app process, so we don't use the cache directory.
  final String subfolder;

  /// Compresses [source] into a sibling file under the documents dir and
  /// returns the compressed [File]. The original is left untouched so the
  /// caller can dispose of it (camera plugin temp files vanish on their own).
  ///
  /// Strips EXIF as a side effect — `flutter_image_compress` re-encodes
  /// the JPEG, so location/orientation metadata embedded in the source is
  /// dropped. The location stays in `photo_uploads.lat/lng` instead, which
  /// is what the server reads.
  Future<File> compress(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory(p.join(dir.path, subfolder));
    if (!await outDir.exists()) await outDir.create(recursive: true);

    final targetPath = p.join(
      outDir.path,
      '${DateTime.now().microsecondsSinceEpoch}_${p.basenameWithoutExtension(source.path)}.jpg',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      source.absolute.path,
      targetPath,
      minWidth: maxWidth,
      minHeight: maxHeight,
      quality: quality,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
    if (result == null) {
      throw PhotoCompressionError('compress_returned_null', source.path);
    }
    return File(result.path);
  }
}

class PhotoCompressionError implements Exception {
  const PhotoCompressionError(this.code, this.sourcePath);
  final String code;
  final String sourcePath;

  @override
  String toString() => 'PhotoCompressionError($code, $sourcePath)';
}
