import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/rest_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/rest_api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/thumbnail.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

/// Client Images Management Page
/// Allows viewing existing client images, adding new images via camera/gallery, and bulk uploading to server
/// Expandable for future features like image editing, categorization, etc.
class ClientImagesManagementPage extends StatefulWidget {
  final String clientCode;
  final String clientName;

  const ClientImagesManagementPage({
    super.key,
    required this.clientCode,
    required this.clientName,
  });

  @override
  State<ClientImagesManagementPage> createState() => _ClientImagesManagementPageState();
}

class _ClientImagesManagementPageState extends State<ClientImagesManagementPage> {
  final RestApiService _restApiService = sl<RestApiService>();
  final RestApiDatabaseService _restApiDatabaseService = sl<RestApiDatabaseService>();
  final ImagePicker _imagePicker = ImagePicker();

  /// List of server thumbnails for the client
  List<Thumbnail> _serverImages = [];

  /// List of new images to be uploaded
  List<XFile> _pendingImages = [];

  /// Loading state for initial data load
  bool _isLoading = true;

  /// Uploading state
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadServerImages();
  }

  /// Load existing server images for the client
  Future<void> _loadServerImages() async {
    try {
      setState(() => _isLoading = true);
      final images = await _restApiDatabaseService.getThumbnailsByCode(widget.clientCode);
      setState(() {
        _serverImages = images;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server rasmlarini yuklashda xatolik: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  /// Pick image from gallery
  Future<void> _pickFromGallery() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _pendingImages.add(image));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Galereyadan rasm tanlashda xatolik: $e')),
        );
      }
    }
  }

  /// Capture image from camera
  Future<void> _captureFromCamera() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() => _pendingImages.add(image));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kameradan rasm olishda xatolik: $e')),
        );
      }
    }
  }

  /// Delete pending image
  void _deletePendingImage(int index) {
    setState(() => _pendingImages.removeAt(index));
  }

  /// Upload all pending images to server
  Future<void> _uploadImages() async {
    if (_pendingImages.isEmpty) return;

    try {
      setState(() => _isUploading = true);
      final files = _pendingImages.map((xfile) => File(xfile.path)).toList();
      final urls = await _restApiService.uploadClientImagesBulk(
        clientCode: widget.clientCode,
        images: files,
      );
      // Refresh server images
      await _loadServerImages();
      // Clear pending
      setState(() {
        _pendingImages.clear();
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rasmlar muvaffaqiyatli yuklandi')),
        );
        // Return success to refresh parent
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rasmlarni yuklashda xatolik: $e')),
        );
      }
    }
  }

  /// Show add image options
  void _showAddImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.of(context).pop();
                _captureFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galereya'),
              onTap: () {
                Navigator.of(context).pop();
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Open full screen image viewer
  void _openFullScreenViewer(int initialIndex, bool isServer) {
    final images = isServer ? _serverImages : _pendingImages;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          images: images,
          initialIndex: initialIndex,
          isServer: isServer,
          onDelete: isServer ? null : _deletePendingImage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.clientName} - Rasmlar'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildImageGrid(theme),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddImageOptions,
        child: const Icon(Icons.add_a_photo),
        tooltip: 'Rasm qo\'shish',
      ),
      bottomNavigationBar: _pendingImages.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _isUploading ? null : _uploadImages,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isUploading ? 'Yuklanmoqda...' : 'Serverga yuborish'),
              ),
            )
          : null,
    );
  }

  /// Build grid view of images
  Widget _buildImageGrid(ThemeData theme) {
    final allImages = _serverImages.length + _pendingImages.length;
    if (allImages == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Rasmlar mavjud emas',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Yangi rasm qo\'shish uchun + tugmasini bosing',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        itemCount: allImages,
        itemBuilder: (context, index) {
          if (index < _serverImages.length) {
            // Server image
            final thumbnail = _serverImages[index];
            return _buildImageCard(
              imageUrl: thumbnail.thumbnailUrl,
              isServer: true,
              index: index,
              theme: theme,
            );
          } else {
            // Pending image
            final pendingIndex = index - _serverImages.length;
            final xfile = _pendingImages[pendingIndex];
            return _buildImageCard(
              file: File(xfile.path),
              isServer: false,
              index: pendingIndex,
              theme: theme,
            );
          }
        },
      ),
    );
  }

  /// Build image card
  Widget _buildImageCard({
    String? imageUrl,
    File? file,
    required bool isServer,
    required int index,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: () => _openFullScreenViewer(index, isServer),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (c, child, p) => p == null
                          ? child
                          : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      errorBuilder: (c, e, s) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(child: Icon(Icons.broken_image)),
                      ),
                    )
                  : Image.file(
                      file!,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
            ),
            if (!isServer)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deletePendingImage(index),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            if (isServer)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Server',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full screen image viewer
class FullScreenImageViewer extends StatefulWidget {
  final List<dynamic> images; // List<Thumbnail> or List<XFile>
  final int initialIndex;
  final bool isServer;
  final Function(int)? onDelete;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.isServer,
    this.onDelete,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.images.length}'),
        actions: widget.onDelete != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _showDeleteConfirmation,
                  tooltip: 'Rasmni o\'chirish',
                ),
              ]
            : null,
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          final image = widget.images[index];
          if (widget.isServer) {
            final thumbnail = image as Thumbnail;
            return PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(thumbnail.thumbnailUrl!),
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            );
          } else {
            final xfile = image as XFile;
            return PhotoViewGalleryPageOptions(
              imageProvider: FileImage(File(xfile.path)),
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            );
          }
        },
        itemCount: widget.images.length,
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        pageController: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }

  /// Show delete confirmation
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rasmni o\'chirish'),
        content: const Text('Haqiqatan ham bu rasmni o\'chirmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete?.call(_currentIndex);
              if (widget.images.length == 1) {
                Navigator.of(context).pop(); // Close viewer if no images left
              } else {
                // Adjust current index if needed
                if (_currentIndex >= widget.images.length - 1) {
                  _currentIndex = widget.images.length - 2;
                  _pageController.jumpToPage(_currentIndex);
                }
                setState(() {});
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
  }
}