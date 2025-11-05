import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/visit_step_data_service.dart';

class PhotoStorageService {
  static const String _photosDir = 'visit_photos';
  static const String _thumbnailsDir = 'visit_thumbnails';
  static const int _thumbnailSize = 200;

  final VisitStepDataService _dataService;

  PhotoStorageService(this._dataService);

  /// Get application documents directory
  Future<Directory> _getAppDir() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Get photos directory
  Future<Directory> _getPhotosDir() async {
    final appDir = await _getAppDir();
    final photosDir = Directory('${appDir.path}/$_photosDir');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    return photosDir;
  }

  /// Get thumbnails directory
  Future<Directory> _getThumbnailsDir() async {
    final appDir = await _getAppDir();
    final thumbnailsDir = Directory('${appDir.path}/$_thumbnailsDir');
    if (!await thumbnailsDir.exists()) {
      await thumbnailsDir.create(recursive: true);
    }
    return thumbnailsDir;
  }

  /// Generate unique filename
  String _generateFileName(String visitId, int stepCode, {String suffix = ''}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${visitId}_${stepCode}_${timestamp}$suffix.jpg';
  }

  /// Save photo with thumbnail
  Future<Map<String, String>> savePhoto({
    required String visitId,
    required String clientCode,
    required int stepCode,
    required String stepName,
    required File imageFile,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final photosDir = await _getPhotosDir();
      final thumbnailsDir = await _getThumbnailsDir();

      // Generate filenames
      final imageFileName = _generateFileName(visitId, stepCode);
      final thumbnailFileName = _generateFileName(visitId, stepCode, suffix: '_thumb');

      // Full paths
      final imagePath = '${photosDir.path}/$imageFileName';
      final thumbnailPath = '${thumbnailsDir.path}/$thumbnailFileName';

      // Copy original image
      await imageFile.copy(imagePath);

      // Create and save thumbnail
      await _createThumbnail(imageFile, thumbnailPath);

      // Save to database
      await _dataService.savePhotoData(
        visitId: visitId,
        clientCode: clientCode,
        stepCode: stepCode,
        stepName: stepName,
        imagePath: imagePath,
        thumbnailPath: thumbnailPath,
        description: description,
        metadata: {
          ...?metadata,
          'originalFileName': imageFile.path.split('/').last,
          'fileSize': await imageFile.length(),
          'savedAt': DateTime.now().toIso8601String(),
        },
      );

      return {
        'imagePath': imagePath,
        'thumbnailPath': thumbnailPath,
      };
    } catch (e) {
      throw Exception('Failed to save photo: $e');
    }
  }

  /// Create thumbnail from image
  Future<void> _createThumbnail(File imageFile, String thumbnailPath) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate thumbnail dimensions
      final aspectRatio = image.width / image.height;
      int thumbWidth, thumbHeight;

      if (aspectRatio > 1) {
        // Landscape
        thumbWidth = _thumbnailSize;
        thumbHeight = (_thumbnailSize / aspectRatio).round();
      } else {
        // Portrait
        thumbHeight = _thumbnailSize;
        thumbWidth = (_thumbnailSize * aspectRatio).round();
      }

      // Resize image
      final thumbnail = img.copyResize(
        image,
        width: thumbWidth,
        height: thumbHeight,
        interpolation: img.Interpolation.linear,
      );

      // Save thumbnail
      final thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(img.encodeJpg(thumbnail, quality: 85));

    } catch (e) {
      // If thumbnail creation fails, copy original as thumbnail
      await imageFile.copy(thumbnailPath);
      print('Warning: Thumbnail creation failed, using original: $e');
    }
  }

  /// Delete photo and its thumbnail
  Future<void> deletePhoto(String visitId, int stepCode, String imagePath) async {
    try {
      // Delete from database
      await _dataService.deletePhoto(visitId, stepCode, imagePath);

      // Delete physical files
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }

      // Try to find and delete thumbnail
      final thumbnailPath = _getThumbnailPathFromImagePath(imagePath);
      final thumbnailFile = File(thumbnailPath);
      if (await thumbnailFile.exists()) {
        await thumbnailFile.delete();
      }

    } catch (e) {
      print('Error deleting photo: $e');
      // Don't throw - file deletion failure shouldn't break the flow
    }
  }

  /// Get thumbnail path from image path
  String _getThumbnailPathFromImagePath(String imagePath) {
    final fileName = imagePath.split('/').last;
    final baseName = fileName.replaceAll('.jpg', '').replaceAll('_thumb', '');
    return imagePath.replaceAll(_photosDir, _thumbnailsDir).replaceAll('.jpg', '_thumb.jpg');
  }

  /// Get photo file
  Future<File?> getPhotoFile(String imagePath) async {
    final file = File(imagePath);
    return await file.exists() ? file : null;
  }

  /// Get thumbnail file
  Future<File?> getThumbnailFile(String thumbnailPath) async {
    final file = File(thumbnailPath);
    return await file.exists() ? file : null;
  }

  /// Clean up orphaned files (files without database records)
  Future<void> cleanupOrphanedFiles() async {
    try {
      final photosDir = await _getPhotosDir();
      final thumbnailsDir = await _getThumbnailsDir();

      // Get all photo files
      final photoFiles = await photosDir.list().where((entity) => entity is File).toList();
      final thumbnailFiles = await thumbnailsDir.list().where((entity) => entity is File).toList();

      // This would need database access to check which files are referenced
      // For now, just clean files older than 30 days
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));

      for (final file in [...photoFiles, ...thumbnailFiles]) {
        final stat = await file.stat();
        if (stat.modified.isBefore(cutoffDate)) {
          await file.delete();
        }
      }

    } catch (e) {
      print('Error cleaning up orphaned files: $e');
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final photosDir = await _getPhotosDir();
      final thumbnailsDir = await _getThumbnailsDir();

      int photoCount = 0;
      int thumbnailCount = 0;
      int totalSize = 0;

      // Count photos
      await for (final entity in photosDir.list()) {
        if (entity is File) {
          photoCount++;
          totalSize += await entity.length();
        }
      }

      // Count thumbnails
      await for (final entity in thumbnailsDir.list()) {
        if (entity is File) {
          thumbnailCount++;
          totalSize += await entity.length();
        }
      }

      return {
        'photoCount': photoCount,
        'thumbnailCount': thumbnailCount,
        'totalSize': totalSize,
        'formattedSize': _formatFileSize(totalSize),
      };
    } catch (e) {
      return {
        'photoCount': 0,
        'thumbnailCount': 0,
        'totalSize': 0,
        'formattedSize': '0 B',
      };
    }
  }

  /// Format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).round()} MB';
    return '${(bytes / (1024 * 1024 * 1024)).round()} GB';
  }

  /// Compress image if too large
  Future<File> compressImage(File imageFile, {int maxSizeKB = 1024}) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final currentSizeKB = bytes.length / 1024;

      if (currentSizeKB <= maxSizeKB) {
        return imageFile; // No compression needed
      }

      final image = img.decodeImage(bytes);
      if (image == null) return imageFile;

      // Calculate compression ratio
      final compressionRatio = maxSizeKB / currentSizeKB;
      final quality = (85 * compressionRatio).clamp(10, 95).toInt();

      // Compress and save
      final compressedBytes = img.encodeJpg(image, quality: quality);
      final compressedFile = File('${imageFile.path}_compressed.jpg');
      await compressedFile.writeAsBytes(compressedBytes);

      return compressedFile;
    } catch (e) {
      print('Image compression failed: $e');
      return imageFile; // Return original if compression fails
    }
  }

  /// Batch process photos for a visit
  Future<void> batchProcessPhotos(String visitId, List<File> imageFiles) async {
    for (final imageFile in imageFiles) {
      try {
        // Compress if needed
        final compressedFile = await compressImage(imageFile);

        // Save with basic metadata
        await savePhoto(
          visitId: visitId,
          clientCode: 'batch', // Will be updated by caller
          stepCode: 0, // Will be updated by caller
          stepName: 'Batch Upload',
          imageFile: compressedFile,
          metadata: {
            'batchProcessed': true,
            'batchSize': imageFiles.length,
          },
        );

        // Clean up temporary compressed file if different
        if (compressedFile.path != imageFile.path) {
          await compressedFile.delete();
        }

      } catch (e) {
        print('Failed to process image ${imageFile.path}: $e');
        // Continue with other images
      }
    }
  }
}