import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class ClientImageStorageService {
  static const String _clientImagesDir = 'client_images';
  static const String _previewsDir = 'client_previews';
  static const String _metadataFile = 'client_images_metadata.json';
  static const int _previewSize = 200;

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

  /// Get previews directory
  Future<Directory> _getPreviewsDir() async {
    final appDir = await _getAppDir();
    final previewsDir = Directory('${appDir.path}/$_previewsDir');
    if (!await previewsDir.exists()) {
      await previewsDir.create(recursive: true);
    }
    return previewsDir;
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

  /// Save client image with preview
  Future<Map<String, String>> saveClientImage({
    required String clientCode,
    required File imageFile,
    String? description,
  }) async {
    try {
      final imagesDir = await _getClientImagesDir();
      final previewsDir = await _getPreviewsDir();

      // Generate filenames
      final imageFileName = _generateFileName(clientCode);
      final previewFileName = '${imageFileName.replaceAll('.jpg', '')}_preview.jpg';

      // Full paths
      final imagePath = '${imagesDir.path}/$imageFileName';
      final previewPath = '${previewsDir.path}/$previewFileName';

      // Copy original image
      await imageFile.copy(imagePath);

      // Create and save preview
      await _createPreview(imageFile, previewPath);

      // Load existing metadata
      final metadata = await _loadMetadata();

      // Add new entry
      final newEntry = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'clientCode': clientCode,
        'imagePath': imagePath,
        'previewPath': previewPath,
        'thumbnailPath': previewPath,
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
        'previewPath': previewPath,
      };
    } catch (e) {
      throw Exception('Failed to save client image: $e');
    }
  }

  /// Create preview from image
  Future<void> _createPreview(File imageFile, String previewPath) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate preview dimensions
      final aspectRatio = image.width / image.height;
      int thumbWidth, thumbHeight;

      if (aspectRatio > 1) {
        // Landscape
        thumbWidth = _previewSize;
        thumbHeight = (_previewSize / aspectRatio).round();
      } else {
        // Portrait
        thumbHeight = _previewSize;
        thumbWidth = (_previewSize * aspectRatio).round();
      }

      // Resize image
      final preview = img.copyResize(
        image,
        width: thumbWidth,
        height: thumbHeight,
        interpolation: img.Interpolation.linear,
      );

      // Save preview
      final previewFile = File(previewPath);
      await previewFile.writeAsBytes(img.encodeJpg(preview, quality: 85));

    } catch (e) {
      // If preview creation fails, copy original as preview
      await imageFile.copy(previewPath);
      print('Warning: Preview creation failed, using original: $e');
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

      // Try to find and delete preview
      final previewPath = _getPreviewPathFromImagePath(imagePath);
      final previewFile = File(previewPath);
      if (await previewFile.exists()) {
        await previewFile.delete();
      }
    } catch (e) {
      print('Error deleting client image: $e');
    }
  }

  /// Get preview path from image path
  String _getPreviewPathFromImagePath(String imagePath) {
    final fileName = imagePath.split('/').last;
    final baseName = fileName.replaceAll('.jpg', '').replaceAll('_preview', '');
    return imagePath.replaceAll(_clientImagesDir, _previewsDir).replaceAll('.jpg', '_preview.jpg');
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

  /// Get preview file
  Future<File?> getPreviewFile(String previewPath) async {
    final file = File(previewPath);
    return await file.exists() ? file : null;
  }

  /// Clear all client images for a client (after upload)
  Future<void> clearClientImages(String clientCode) async {
    try {
      final metadata = await _loadMetadata();
      final imagesToDelete = metadata.where((entry) => entry['clientCode'] == clientCode).toList();

      for (final entry in imagesToDelete) {
        final imagePath = entry['imagePath'] as String?;
        final previewPath = (entry['previewPath'] ?? entry['thumbnailPath']) as String?;

        // Delete files
        if (imagePath != null) {
          final imageFile = File(imagePath);
          if (await imageFile.exists()) {
            await imageFile.delete();
          }
        }
        if (previewPath != null) {
          final previewFile = File(previewPath);
          if (await previewFile.exists()) {
            await previewFile.delete();
          }
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