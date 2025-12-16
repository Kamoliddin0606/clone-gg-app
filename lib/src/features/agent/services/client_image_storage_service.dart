import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class ClientImageStorageService {
  static const String _clientImagesDir = 'client_images';
  static const String _thumbnailsDir = 'client_thumbnails';
  static const String _metadataFile = 'client_images_metadata.json';
  static const int _thumbnailSize = 200;

  /// Get application documents directory
  Future<Directory> _getAppDir() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Get client images directory
  Future<Directory> _getClientImagesDir() async {
    final appDir = await _getAppDir();
    final imagesDir = Directory('${appDir.path}/$_clientImagesDir');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
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

  /// Get metadata file path
  Future<String> _getMetadataFilePath() async {
    final appDir = await _getAppDir();
    return '${appDir.path}/$_metadataFile';
  }

  /// Generate unique filename for client image
  String _generateFileName(String clientCode) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${clientCode}_${timestamp}.jpg';
  }

  /// Load metadata from file
  Future<List<Map<String, dynamic>>> _loadMetadata() async {
    try {
      final metadataPath = await _getMetadataFilePath();
      final file = File(metadataPath);
      if (!await file.exists()) {
        return [];
      }
      final content = await file.readAsString();
      final data = jsonDecode(content) as List;
      return data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error loading metadata: $e');
      return [];
    }
  }

  /// Save metadata to file
  Future<void> _saveMetadata(List<Map<String, dynamic>> metadata) async {
    try {
      final metadataPath = await _getMetadataFilePath();
      final file = File(metadataPath);
      await file.writeAsString(jsonEncode(metadata));
    } catch (e) {
      print('Error saving metadata: $e');
    }
  }

  /// Save client image with thumbnail
  Future<Map<String, String>> saveClientImage({
    required String clientCode,
    required File imageFile,
    String? description,
  }) async {
    try {
      final imagesDir = await _getClientImagesDir();
      final thumbnailsDir = await _getThumbnailsDir();

      // Generate filenames
      final imageFileName = _generateFileName(clientCode);
      final thumbnailFileName = '${imageFileName.replaceAll('.jpg', '')}_thumb.jpg';

      // Full paths
      final imagePath = '${imagesDir.path}/$imageFileName';
      final thumbnailPath = '${thumbnailsDir.path}/$thumbnailFileName';

      // Copy original image
      await imageFile.copy(imagePath);

      // Create and save thumbnail
      await _createThumbnail(imageFile, thumbnailPath);

      // Load existing metadata
      final metadata = await _loadMetadata();

      // Add new entry
      final newEntry = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'clientCode': clientCode,
        'imagePath': imagePath,
        'thumbnailPath': thumbnailPath,
        'timestamp': DateTime.now().toIso8601String(),
        'description': description ?? 'Client image',
        'originalFileName': imageFile.path.split('/').last,
        'fileSize': await imageFile.length(),
      };

      metadata.add(newEntry);

      // Save metadata
      await _saveMetadata(metadata);

      return {
        'imagePath': imagePath,
        'thumbnailPath': thumbnailPath,
      };
    } catch (e) {
      throw Exception('Failed to save client image: $e');
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

  /// Delete client image
  Future<void> deleteClientImage(String imagePath) async {
    try {
      // Load metadata
      final metadata = await _loadMetadata();

      // Find and remove entry
      metadata.removeWhere((entry) => entry['imagePath'] == imagePath);

      // Save updated metadata
      await _saveMetadata(metadata);

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
      print('Error deleting client image: $e');
    }
  }

  /// Get thumbnail path from image path
  String _getThumbnailPathFromImagePath(String imagePath) {
    final fileName = imagePath.split('/').last;
    final baseName = fileName.replaceAll('.jpg', '');
    return imagePath.replaceAll(_clientImagesDir, _thumbnailsDir).replaceAll('.jpg', '_thumb.jpg');
  }

  /// Get all client images for a specific client
  Future<List<Map<String, dynamic>>> getClientImages(String clientCode) async {
    try {
      final metadata = await _loadMetadata();
      return metadata.where((entry) => entry['clientCode'] == clientCode).toList();
    } catch (e) {
      print('Error getting client images: $e');
      return [];
    }
  }

  /// Get photo file
  Future<File?> getImageFile(String imagePath) async {
    final file = File(imagePath);
    return await file.exists() ? file : null;
  }

  /// Get thumbnail file
  Future<File?> getThumbnailFile(String thumbnailPath) async {
    final file = File(thumbnailPath);
    return await file.exists() ? file : null;
  }

  /// Clear all client images for a client (after upload)
  Future<void> clearClientImages(String clientCode) async {
    try {
      final metadata = await _loadMetadata();
      final imagesToDelete = metadata.where((entry) => entry['clientCode'] == clientCode).toList();

      for (final entry in imagesToDelete) {
        final imagePath = entry['imagePath'];
        final thumbnailPath = entry['thumbnailPath'];

        // Delete files
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
        final thumbnailFile = File(thumbnailPath);
        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
        }
      }

      // Remove from metadata
      metadata.removeWhere((entry) => entry['clientCode'] == clientCode);
      await _saveMetadata(metadata);

    } catch (e) {
      print('Error clearing client images: $e');
    }
  }
}