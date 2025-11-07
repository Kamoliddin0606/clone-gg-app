import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/visit_step_data_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/photo_storage_service.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

/// Фото ДО (Facing correction) - Before photos page
/// Supports read-only mode for completed steps
/// Enhanced with full photo management capabilities including camera, gallery viewing, and zoom functionality
class PhotoFacingBeforePage extends StatefulWidget {
  final TradingPointWithPermissions tradingPoint;
  final String visitId;
  final int stepCode;
  final String stepName;
  final bool readOnly;

  const PhotoFacingBeforePage({
    super.key,
    required this.tradingPoint,
    required this.visitId,
    required this.stepCode,
    required this.stepName,
    this.readOnly = false,
  });

  @override
  State<PhotoFacingBeforePage> createState() => _PhotoFacingBeforePageState();
}

class _PhotoFacingBeforePageState extends State<PhotoFacingBeforePage>
    with TickerProviderStateMixin {
  final VisitStepDataService _dataService = sl<VisitStepDataService>();
  final PhotoStorageService _photoStorageService = sl<PhotoStorageService>();
  final TextEditingController _notesController = TextEditingController();

  // UI State management
  bool _isLoading = true;
  List<Map<String, dynamic>> _photos = [];
  ViewMode _viewMode = ViewMode.grid;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  // Camera related
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePage();
    _setupAnimations();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _fabAnimationController.dispose();
    _disposeCamera();
    super.dispose();
  }

  /// Dispose camera resources properly
  Future<void> _disposeCamera() async {
    try {
      if (_cameraController != null) {
        _cameraController!.removeListener(_onCameraError);
        await _cameraController!.dispose();
        _cameraController = null;
      }
      _isCameraInitialized = false;
    } catch (e) {
      debugPrint('Camera disposal error: $e');
    }
  }

  /// Initialize page data and camera
  Future<void> _initializePage() async {
    try {
      setState(() => _isLoading = true);

      // Load existing photos
      await _loadPhotos();

      // Initialize cameras for camera functionality only when needed
      // Camera will be initialized when add_a_photo button is pressed
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik yuz berdi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Setup FAB animation
  void _setupAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _fabAnimationController.forward();
  }

  /// Initialize available cameras
  Future<void> _initializeCameras() async {
    try {
      // Request camera permission first
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kamera ruxsati berilmadi')),
          );
        }
        return;
      }

      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        await _initializeCameraController(_cameras!.first);
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kamera ishga tushirishda xatolik: $e')),
        );
      }
    }
  }

  /// Initialize camera controller
  Future<void> _initializeCameraController(CameraDescription camera) async {
    try {
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      // Check if initialization was successful
      if (_cameraController!.value.hasError) {
        throw Exception('Camera initialization failed: ${_cameraController!.value.errorDescription}');
      }

      // Add error listener for camera errors
      _cameraController!.addListener(_onCameraError);

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint('Camera controller initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kamera ishga tushirishda xatolik: $e')),
        );
      }
    }
  }

  /// Handle camera errors
  void _onCameraError() {
    if (_cameraController?.value.hasError ?? false) {
      final error = _cameraController!.value.errorDescription;
      debugPrint('Camera error: $error');

      if (mounted) {
        // Check if it's an eviction error (code 3)
        if (error?.contains('code 3') ?? false) {
          _handleCameraEviction();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kamera xatoligi: $error')),
          );

          // Try to reinitialize camera if possible
          _reinitializeCamera();
        }
      }
    }
  }

  /// Reinitialize camera after error
  Future<void> _reinitializeCamera() async {
    try {
      await _disposeCamera();

      // Wait a bit before reinitializing
      await Future.delayed(const Duration(seconds: 1));

      if (_cameras != null && _cameras!.isNotEmpty) {
        await _initializeCameraController(_cameras!.first);
      }
    } catch (e) {
      debugPrint('Camera reinitialization error: $e');
    }
  }

  /// Handle camera eviction and reconnection
  void _handleCameraEviction() {
    if (mounted) {
      setState(() => _isCameraInitialized = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kamera boshqa ilova tomonidan ishlatilmoqda. Qayta ulanishga harakat qilinmoqda...'),
          duration: Duration(seconds: 3),
        ),
      );

      // Try to reconnect after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _reinitializeCamera();
        }
      });
    }
  }

  /// Load existing photos for this step
  Future<void> _loadPhotos() async {
    try {
      final stepPhotos = await _dataService.getStepPhotos(widget.visitId, widget.stepCode);
      final photos = <Map<String, dynamic>>[];

      for (final photo in stepPhotos) {
        final content = photo.parsedDataContent;
        final imagePath = content['image_path'];
        final thumbnailPath = content['thumbnail_path'];

        if (imagePath != null && await File(imagePath).exists()) {
          photos.add({
            'id': photo.id,
            'imagePath': imagePath,
            'thumbnailPath': thumbnailPath,
            'timestamp': photo.timestamp,
            'description': content['description'],
          });
        }
      }

      if (mounted) {
        setState(() => _photos = photos);
      }
    } catch (e) {
      debugPrint('Error loading photos: $e');
    }
  }

  /// Save captured photo
  Future<void> _saveCapturedPhoto(File imageFile) async {
    try {
      final result = await _photoStorageService.savePhoto(
        visitId: widget.visitId,
        clientCode: widget.tradingPoint.tradingPoint.id,
        stepCode: widget.stepCode,
        stepName: widget.stepName,
        imageFile: imageFile,
        description: 'Facing correction - Before',
      );

      // Add to local photos list
      final newPhoto = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'imagePath': result['imagePath'],
        'thumbnailPath': result['thumbnailPath'],
        'timestamp': DateTime.now(),
        'description': 'Facing correction - Before',
      };

      setState(() => _photos.add(newPhoto));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rasm muvaffaqiyatli saqlandi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rasm saqlashda xatolik: $e')),
        );
      }
    }
  }

  /// Save captured photo and return path for camera page
  Future<String> _saveCapturedPhotoAndReturnPath(File imageFile) async {
    await _saveCapturedPhoto(imageFile);
    return imageFile.path;
  }

  /// Delete photo
  Future<void> _deletePhoto(int index) async {
    try {
      final photo = _photos[index];
      final imagePath = photo['imagePath'];

      await _photoStorageService.deletePhoto(
        widget.visitId,
        widget.stepCode,
        imagePath,
      );

      setState(() => _photos.removeAt(index));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rasm o\'chirildi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rasm o\'chirishda xatolik: $e')),
        );
      }
    }
  }


  /// Open camera page
  void _openCameraPage() async {
    // Initialize camera only when button is pressed
    if (_cameraController == null || !_isCameraInitialized) {
      await _initializeCameras();
      if (_cameraController == null || !_isCameraInitialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamera tayyor emas')),
        );
        return;
      }
    }

    // Check if camera is still available and properly initialized
    if (_cameraController!.value.isRecordingVideo ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamera mavjud emas yoki ishlamayapti')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CameraCapturePage(
          cameraController: _cameraController!,
          onPhotoCaptured: _saveCapturedPhotoAndReturnPath,
          capturedPhotos: _photos.map((p) => p['imagePath'] as String).toList(),
        ),
      ),
    );
  }

  /// Open full screen image viewer
  void _openFullScreenViewer(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          photos: _photos,
          initialIndex: initialIndex,
          onDeletePhoto: _deletePhoto,
          readOnly: widget.readOnly,
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
        title: Text(widget.stepName),
        centerTitle: true,
        actions: [
          if (_photos.isNotEmpty) ...[
            IconButton(
              icon: Icon(
                _viewMode == ViewMode.grid ? Icons.list : Icons.grid_view,
              ),
              onPressed: () {
                setState(() {
                  _viewMode = _viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
                });
              },
              tooltip: _viewMode == ViewMode.grid ? 'Ro\'yxat ko\'rinishi' : 'Panjara ko\'rinishi',
            ),
          ],
          if (widget.readOnly) ...[
            const Icon(Icons.visibility, color: Colors.grey),
            const SizedBox(width: 8),
            const Text(
              'Faqat ko\'rish',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildPhotoContent(theme, l10n),
      floatingActionButton: widget.readOnly ? null : _buildFloatingActionButton(),
      bottomNavigationBar: _buildBottomBar(theme, l10n),
    );
  }

  /// Build main photo content
  Widget _buildPhotoContent(ThemeData theme, AppLocalizations? l10n) {
    if (_photos.isEmpty) {
      return _buildEmptyState(theme, l10n);
    }

    return _viewMode == ViewMode.grid
        ? _buildGridView(theme)
        : _buildListView(theme);
  }

  /// Build empty state when no photos
  Widget _buildEmptyState(ThemeData theme, AppLocalizations? l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera,
            size: 64,
            color: widget.readOnly ? Colors.grey : theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Фото ДО (Facing correction)',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.readOnly
                ? 'Bu step yakunlangan. Faqat ko\'rish rejimida.'
                : 'Rasmlar hali yuklanmagan',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build grid view for photos
  Widget _buildGridView(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          final photo = _photos[index];
          return _buildPhotoCard(photo, index, theme);
        },
      ),
    );
  }

  /// Build list view for photos
  Widget _buildListView(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        return _buildPhotoListItem(photo, index, theme);
      },
    );
  }

  /// Build photo card for grid view
  Widget _buildPhotoCard(Map<String, dynamic> photo, int index, ThemeData theme) {
    return GestureDetector(
      onTap: () => _openFullScreenViewer(index),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 1.0, // 1:1 aspect ratio
              child: Image.file(
                File(photo['thumbnailPath'] ?? photo['imagePath']),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            if (!widget.readOnly)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmation(index),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build photo list item
  Widget _buildPhotoListItem(Map<String, dynamic> photo, int index, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: GestureDetector(
          onTap: () => _openFullScreenViewer(index),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: FileImage(File(photo['thumbnailPath'] ?? photo['imagePath'])),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        title: Text(
          'Rasm ${index + 1}',
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          photo['timestamp'] != null
              ? _formatDateTime(photo['timestamp'])
              : 'Vaqt noma\'lum',
        ),
        trailing: widget.readOnly
            ? null
            : IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteConfirmation(index),
              ),
        onTap: () => _openFullScreenViewer(index),
      ),
    );
  }

  /// Build floating action button
  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: FloatingActionButton(
            onPressed: _openCameraPage,
            child: const Icon(Icons.add_a_photo),
            tooltip: 'Rasmga olish',
          ),
        );
      },
    );
  }

  /// Build bottom bar with complete button
  Widget _buildBottomBar(ThemeData theme, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: FilledButton.icon(
          onPressed: () => _showCompleteDialog(context),
          icon: const Icon(Icons.check),
          label: Text(l10n?.completeStep ?? 'Complete Step'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
        ),
      ),
    );
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation(int index) {
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
              _deletePhoto(index);
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

  /// Show complete step dialog
  void _showCompleteDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.stepName} ${l10n?.completed?.toLowerCase() ?? 'completed'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_photos.length} ta rasm saqlandi'),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Izoh (ixtiyoriy)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n?.cancelCompletion ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop({
                'completed': true,
                'notes': _notesController.text.trim(),
                'photoCount': _photos.length,
              }); // Return result
            },
            child: Text(l10n?.confirmCompletion ?? 'Confirm'),
          ),
        ],
      ),
    );
  }

  /// Format date time for display
  String _formatDateTime(dynamic timestamp) {
    if (timestamp is DateTime) {
      return '${timestamp.day.toString().padLeft(2, '0')}.'
             '${timestamp.month.toString().padLeft(2, '0')}.'
             '${timestamp.year} '
             '${timestamp.hour.toString().padLeft(2, '0')}:'
             '${timestamp.minute.toString().padLeft(2, '0')}';
    }
    return 'Vaqt noma\'lum';
  }
}

/// View mode enum
enum ViewMode { grid, list }

/// Full screen image viewer with zoom and swipe functionality
class FullScreenImageViewer extends StatefulWidget {
  final List<Map<String, dynamic>> photos;
  final int initialIndex;
  final Function(int)? onDeletePhoto;
  final bool readOnly;

  const FullScreenImageViewer({
    super.key,
    required this.photos,
    required this.initialIndex,
    this.onDeletePhoto,
    this.readOnly = false,
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
        title: Text('${_currentIndex + 1} / ${widget.photos.length}'),
        actions: widget.readOnly
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _showDeleteConfirmation,
                  tooltip: 'Rasmni o\'chirish',
                ),
              ],
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          final photo = widget.photos[index];
          return PhotoViewGalleryPageOptions(
            imageProvider: FileImage(File(photo['imagePath'])),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(tag: photo['id']),
          );
        },
        itemCount: widget.photos.length,
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
              widget.onDeletePhoto?.call(_currentIndex);
              if (widget.photos.length == 1) {
                Navigator.of(context).pop(); // Close viewer if no photos left
              } else {
                // Adjust current index if needed
                if (_currentIndex >= widget.photos.length - 1) {
                  _currentIndex = widget.photos.length - 2;
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

/// Camera capture page with full screen camera and image slider
class CameraCapturePage extends StatefulWidget {
  final CameraController cameraController;
  final Function(File) onPhotoCaptured;
  final List<String> capturedPhotos;

  const CameraCapturePage({
    super.key,
    required this.cameraController,
    required this.onPhotoCaptured,
    required this.capturedPhotos,
  });

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  late PageController _photoSliderController;
  bool _isCapturing = false;
  late List<String> _localCapturedPhotos;
  bool _isCameraAvailable = true;

  @override
  void initState() {
    super.initState();
    _photoSliderController = PageController();
    _localCapturedPhotos = List.from(widget.capturedPhotos);

    // Listen for camera errors
    widget.cameraController.addListener(_onCameraError);
  }

  @override
  void dispose() {
    _photoSliderController.dispose();
    widget.cameraController.removeListener(_onCameraError);
    super.dispose();
  }

  /// Handle camera errors in capture page
  void _onCameraError() {
    if (widget.cameraController.value.hasError) {
      final error = widget.cameraController.value.errorDescription;
      debugPrint('Camera error in capture page: $error');

      if (mounted) {
        setState(() => _isCameraAvailable = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kamera xatoligi: $error')),
        );

        // Try to reinitialize camera after error
        _tryReinitializeCamera();
      }
    }
  }

  /// Try to reinitialize camera after error
  Future<void> _tryReinitializeCamera() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted && widget.cameraController.value.hasError) {
        // Dispose and try to reinitialize
        await widget.cameraController.dispose();
        // Note: Full reinitialization would require access to camera list
        // For now, just mark as unavailable
      }
    } catch (e) {
      debugPrint('Camera reinitialization failed: $e');
    }
  }

  /// Delete photo from camera slider
  void _deletePhotoFromCameraSlider(int index) {
    setState(() {
      _localCapturedPhotos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen camera preview
          Positioned.fill(
            child: CameraPreview(widget.cameraController),
          ),

          // Top bar with captured photos count and finish button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),

                  // Photos count and finish button
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_localCapturedPhotos.length} ta rasm',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _localCapturedPhotos.isNotEmpty
                            ? () => Navigator.of(context).pop()
                            : null,
                        icon: const Icon(Icons.check),
                        label: const Text('Yakunlash'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Captured photos slider below capture button
          if (_localCapturedPhotos.isNotEmpty)
            Positioned(
              bottom: 110,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: PageView.builder(
                  controller: _photoSliderController,
                  scrollDirection: Axis.horizontal,
                  itemCount: _localCapturedPhotos.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(File(_localCapturedPhotos[index])),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _deletePhotoFromCameraSlider(index),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

          // Capture button at bottom center
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: (_isCapturing || !_isCameraAvailable) ? null : _capturePhoto,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: _isCapturing
                        ? Colors.grey
                        : !_isCameraAvailable
                            ? Colors.red.withOpacity(0.5)
                            : Colors.transparent,
                  ),
                  child: _isCapturing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : !_isCameraAvailable
                          ? const Icon(Icons.error, color: Colors.white)
                          : Container(), // Empty circle with white border
                ),
              ),
            ),
          ),

          // Bottom spacing for safe area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Capture photo from camera
  Future<void> _capturePhoto() async {
    if (_isCapturing || !_isCameraAvailable) return;

    setState(() => _isCapturing = true);

    try {
      // Check camera state before capturing
      if (!widget.cameraController.value.isInitialized ||
          widget.cameraController.value.isRecordingVideo ||
          widget.cameraController.value.hasError) {
        throw Exception('Kamera tayyor emas');
      }

      final image = await widget.cameraController.takePicture();
      final imageFile = File(image.path);

      // Call the callback to save the photo and get the path
      final savedPath = await widget.onPhotoCaptured(imageFile);

      // Add to local list for immediate UI update
      if (mounted) {
        setState(() {
          _localCapturedPhotos.add(savedPath);
        });
      }

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rasm muvaffaqiyatli olingan'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Photo capture error: $e');
      if (mounted) {
        setState(() => _isCameraAvailable = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rasm olishda xatolik: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }
}