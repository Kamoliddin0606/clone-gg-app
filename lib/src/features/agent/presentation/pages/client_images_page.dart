import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/photo_storage_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/rest_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/token_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/thumbnail_image_service.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

ImageProvider? _clientImageProviderFromUrl(String? url) {
  if (url == null) return null;
  final u = url.trim();
  if (u.isEmpty) return null;
  if (u.startsWith('http://') || u.startsWith('https://')) {
    return NetworkImage(u);
  }
  return FileImage(File(u));
}

String? _bestClientImagePreviewUrl(ClientImage img) {
  final candidates = <String?>[
    img.imageThumbnailUrl,
    img.imageSmUrl,
    img.imageMdUrl,
    img.imageUrl,
    img.image,
  ];
  for (final s in candidates) {
    if (s != null && s.trim().isNotEmpty) return s;
  }
  return null;
}

String? _bestClientImageFullscreenUrl(ClientImage img) {
  final candidates = <String?>[
    img.imageLgUrl,
    img.imageMdUrl,
    img.imageSmUrl,
    img.imageUrl,
    img.imageThumbnailUrl,
    img.image,
  ];
  for (final s in candidates) {
    if (s != null && s.trim().isNotEmpty) return s;
  }
  return null;
}

/// Client Images Management Page
/// This page allows viewing, creating, and uploading client images to the server
/// Designed for future expansion to handle multiple client images
/// Uses RestApiService for server communication and bulk upload functionality
class ClientImagesPage extends StatefulWidget {
  final TradingPointWithPermissions tradingPoint;

  const ClientImagesPage({
    super.key,
    required this.tradingPoint,
  });

  @override
  State<ClientImagesPage> createState() => _ClientImagesPageState();
}

class _ClientImagesPageState extends State<ClientImagesPage>
    with TickerProviderStateMixin {
  final PhotoStorageService _photoStorageService = sl<PhotoStorageService>();
  final RestApiService _restApiService = sl<RestApiService>();
  final TokenService _tokenService = sl<TokenService>();
  final ClientImagesService _clientImagesService = sl<ClientImagesService>();

  // UI State management
  bool _isLoading = true;
  List<Map<String, dynamic>> _photos = [];
  ViewMode _viewMode = ViewMode.grid;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  final TextEditingController _notesController = TextEditingController();

  /// Server-synced images loaded from local database (client_images table)
  ///
  /// This list is the authoritative source for displaying *server images*.
  /// It is refreshed by:
  /// - reading DB via `ClientImagesService.getClientImages`
  /// - optionally syncing from server via `ClientImagesService.fetchAndSaveClientImages`
  List<ClientImage> _serverImages = [];

  /// Loading state for server images list
  bool _isServerImagesLoading = false;

  /// State to prevent duplicate main-selection requests
  bool _isSettingMain = false;

  /// Uploading state for local pending images
  bool _isUploading = false;

  /// State for server image deletion in progress
  bool _isDeletingServerImage = false;

  // Camera related
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  /// Convenience getter for current client code
  ///
  /// In this project, `tradingPoint.id` is used as client 1C code.
  String get _clientCode => widget.tradingPoint.tradingPoint.id;

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

      if (_cameraController!.value.hasError) {
        throw Exception('Camera initialization failed: ${_cameraController!.value.errorDescription}');
      }

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
          _reinitializeCamera();
        }
      }
    }
  }

  /// Reinitialize camera after error
  Future<void> _reinitializeCamera() async {
    try {
      await _disposeCamera();
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

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _reinitializeCamera();
        }
      });
    }
  }

  /// Initialize page data
  ///
  /// Responsibilities:
  /// - load local pending photos
  /// - load server images from DB
  /// - attempt server sync (if token is available)
  Future<void> _initializePage() async {
    try {
      setState(() => _isLoading = true);

      await _loadClientPhotos();
      await _loadServerImagesFromDatabase();
      await _syncServerImagesFromApiIfPossible(replaceExisting: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sahifa yuklanishda xatolik: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Load server images from local database (client_images table)
  ///
  /// This does not call the network.
  Future<void> _loadServerImagesFromDatabase() async {
    try {
      setState(() => _isServerImagesLoading = true);

      final images = await _clientImagesService.getClientImages(_clientCode);

      if (!mounted) return;

      setState(() {
        _serverImages = images;
        _isServerImagesLoading = false;
      });

      if (kDebugMode) {
        print('ClientImagesPage: Loaded ${images.length} server images from DB for client $_clientCode');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _serverImages = [];
        _isServerImagesLoading = false;
      });

      if (kDebugMode) {
        print('ClientImagesPage: Error loading server images from DB: $e');
      }
    }
  }

  /// Sync server images from API to local database when possible
  ///
  /// This method:
  /// - checks token availability
  /// - calls `ClientImagesService.fetchAndSaveClientImages`
  /// - reloads the images from DB
  Future<void> _syncServerImagesFromApiIfPossible({bool replaceExisting = true}) async {
    try {
      final token = await _tokenService.getValidAccessToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('ClientImagesPage: Skipping server images sync - no valid access token');
        }
        return;
      }

      await _clientImagesService.fetchAndSaveClientImages(
        _clientCode,
        replaceExisting: replaceExisting,
      );

      await _loadServerImagesFromDatabase();
    } catch (e) {
      if (kDebugMode) {
        print('ClientImagesPage: Error syncing server images: $e');
      }
    }
  }

  /// Request to set a server image as main
  ///
  /// This method:
  /// 1. Calls ClientImagesService to set the image as main on server (PATCH API)
  /// 2. On success, updates local database (removes main from others, sets this as main)
  /// 3. Reloads the images list from local database to reflect changes
  /// 4. Shows success/error feedback to user
  Future<void> _requestSetAsMain(ClientImage image) async {
    if (_isSettingMain) return;
    if (image.isMain) return;

    try {
      setState(() => _isSettingMain = true);

      // Call service to set as main (handles both server and local update)
      final success = await _clientImagesService.setClientImageAsMain(image);

      if (!mounted) return;

      if (success) {
        // Reload images from local database to reflect changes
        await _loadServerImagesFromDatabase();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rasm asosiy qilib belgilandi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Asosiy rasmni o\'zgartirishda xatolik: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSettingMain = false);
      }
    }
  }

  /// Delete a server image from both server and local database
  ///
  /// Shows confirmation dialog, then deletes image via ClientImagesService.
  /// On success, reloads the image list and shows success message.
  Future<void> _deleteServerImage(ClientImage image) async {
    if (_isDeletingServerImage) return;

    try {
      setState(() => _isDeletingServerImage = true);

      // Delete from server and local DB
      await _clientImagesService.deleteClientImageFromServer(image);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rasm muvaffaqiyatli o\'chirildi'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload images from database
      await _loadServerImagesFromDatabase();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rasmni o\'chirishda xatolik: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeletingServerImage = false);
      }
    }
  }

  /// Show confirmation dialog for deleting a server image
  void _showServerImageDeleteConfirmation(ClientImage image) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rasmni o\'chirish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Haqiqatan ham bu rasmni o\'chirmoqchimisiz?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bu amal qaytarib bo\'lmaydi. Rasm serverdan ham o\'chiriladi.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteServerImage(image);
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

  /// Load existing client photos from local storage
  /// Loads photos from photo storage service with client-specific logic
  Future<void> _loadClientPhotos() async {
    try {
      final clientPhotos = await _photoStorageService.getClientPhotos(_clientCode);
      if (!mounted) return;
      setState(() => _photos = clientPhotos);

      if (kDebugMode) {
        print('ClientImagesPage: Loaded ${clientPhotos.length} local photos for client $_clientCode');
      }
    } catch (e) {
      debugPrint('Error loading client photos: $e');
      if (!mounted) return;
      setState(() => _photos = []);
    }
  }

  /// Save captured photo for client
  Future<void> _saveCapturedPhoto(File imageFile) async {
    try {
      final clientVisitId = 'client_${_clientCode}_${DateTime.now().millisecondsSinceEpoch}';

      final result = await _photoStorageService.savePhoto(
        visitId: clientVisitId,
        clientCode: _clientCode,
        stepCode: 999,
        stepName: 'Client Images',
        imageFile: imageFile,
        description: 'Client image - ${widget.tradingPoint.tradingPoint.name}',
      );

      final newPhoto = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'visitId': clientVisitId,
        'imagePath': result['imagePath'],
        'thumbnailPath': result['thumbnailPath'],
        'timestamp': DateTime.now(),
        'description': 'Client image',
        'clientCode': _clientCode,
      };

      if (!mounted) return;

      setState(() => _photos.add(newPhoto));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rasm muvaffaqiyatli saqlandi')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rasm saqlashda xatolik: $e')),
        );
      }
    }
  }

  /// Delete local pending photo
  Future<void> _deletePhoto(int index) async {
    try {
      final photo = _photos[index];
      final imagePath = photo['imagePath'];
      final visitId = photo['visitId'];

      await _photoStorageService.deletePhoto(
        visitId,
        999,
        imagePath,
      );

      if (!mounted) return;

      setState(() => _photos.removeAt(index));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rasm o\'chirildi')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rasm o\'chirishda xatolik: $e')),
        );
      }
    }
  }

  /// Delete all local photos after successful upload to server
  /// This cleans up the local storage to avoid duplicate data
  Future<void> _deleteLocalPhotosAfterUpload() async {
    for (final photo in _photos) {
      try {
        final imagePath = photo['imagePath'] as String?;
        final thumbnailPath = photo['thumbnailPath'] as String?;
        final visitId = photo['visitId'] as String?;

        // Delete main image file
        if (imagePath != null) {
          final imageFile = File(imagePath);
          if (await imageFile.exists()) {
            await imageFile.delete();
            if (kDebugMode) {
              print('ClientImagesPage: Deleted local image: $imagePath');
            }
          }
        }

        // Delete thumbnail file
        if (thumbnailPath != null && thumbnailPath != imagePath) {
          final thumbFile = File(thumbnailPath);
          if (await thumbFile.exists()) {
            await thumbFile.delete();
            if (kDebugMode) {
              print('ClientImagesPage: Deleted local thumbnail: $thumbnailPath');
            }
          }
        }

        // Delete from photo storage service
        if (visitId != null && imagePath != null) {
          await _photoStorageService.deletePhoto(visitId, 999, imagePath);
        }
      } catch (e) {
        // Log but don't fail - cleanup errors are not critical
        if (kDebugMode) {
          print('ClientImagesPage: Error deleting local photo: $e');
        }
      }
    }

    if (kDebugMode) {
      print('ClientImagesPage: Local photos cleanup completed');
    }
  }

  /// Upload all local images to server
  Future<void> _uploadImagesToServer() async {
    if (_photos.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yuklash uchun rasm yo\'q')),
        );
      }
      return;
    }

    setState(() => _isUploading = true);

    try {
      final imageFiles = <File>[];
      for (final photo in _photos) {
        final file = File(photo['imagePath']);
        if (await file.exists()) {
          imageFiles.add(file);
        }
      }

      if (imageFiles.isEmpty) {
        throw Exception('Hech bir rasm fayli topilmadi');
      }

      // Use ensureValidToken for complete auth flow:
      // 1. Check access token validity
      // 2. Refresh if expired  
      // 3. Re-authenticate if refresh fails
      final accessToken = await _tokenService.ensureValidToken();
      if (accessToken == null) {
        throw Exception('Autentifikatsiya muddati tugadi. Iltimos, qayta kiring.');
      }

      final uploadedUrls = await _restApiService.uploadClientImagesBulk(
        clientCode: _clientCode,
        images: imageFiles,
      );

      if (!mounted) return;

      // Successfully uploaded - delete local files from storage
      if (uploadedUrls.isNotEmpty) {
        await _deleteLocalPhotosAfterUpload();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${uploadedUrls.length} ta rasm muvaffaqiyatli yuklandi'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() => _photos.clear());

      await _syncServerImagesFromApiIfPossible(replaceExisting: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rasmlarni yuklashda xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  /// Open camera page
  Future<void> _openCameraPage() async {
    if (_cameraController == null || !_isCameraInitialized) {
      await _initializeCameras();
      if (_cameraController == null || !_isCameraInitialized) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kamera tayyor emas')),
          );
        }
        return;
      }
    }

    if (_cameraController!.value.isRecordingVideo ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.hasError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamera mavjud emas yoki ishlamayapti')),
        );
      }
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CameraCapturePage(
          cameraController: _cameraController!,
          onPhotoCaptured: _saveCapturedPhoto,
          capturedPhotos: _photos.map((p) => p['imagePath'] as String).toList(),
        ),
      ),
    );

    await _loadClientPhotos();
  }

  /// Open full screen image viewer for local photos
  void _openFullScreenViewer(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          photos: _photos,
          initialIndex: initialIndex,
          onDeletePhoto: _deletePhoto,
          readOnly: false,
        ),
      ),
    );
  }

  /// Open full screen image viewer for server images
  void _openServerImageViewer(ClientImage image) {
    final url = _bestClientImageFullscreenUrl(image);

    if (url == null || url.isEmpty) {
      return;
    }

    final provider = _clientImageProviderFromUrl(url);
    if (provider == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black.withOpacity(0.7),
            foregroundColor: Colors.white,
            title: const Text('Rasm'),
          ),
          body: PhotoView(
            imageProvider: provider,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image, color: Colors.white),
              );
            },
          ),
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
        title: Text('${widget.tradingPoint.tradingPoint.name} - Rasmlar'),
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
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildPhotoContent(theme, l10n),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCameraPage,
        child: const Icon(Icons.add_a_photo),
        tooltip: 'Rasmga olish',
      ),
      bottomNavigationBar: _buildBottomBar(theme, l10n),
    );
  }

  /// Build main photo content
  Widget _buildPhotoContent(ThemeData theme, AppLocalizations? l10n) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadClientPhotos();
        await _syncServerImagesFromApiIfPossible(replaceExisting: true);
      },
      child: _buildCombinedContent(theme, l10n),
    );
  }

  /// Build combined content (server images + local pending images)
  ///
  /// Priority:
  /// - Show server images (authoritative)
  /// - Also show local images (captured but not uploaded yet) as "pending"
  Widget _buildCombinedContent(ThemeData theme, AppLocalizations? l10n) {
    final hasAny = _serverImages.isNotEmpty || _photos.isNotEmpty;

    if (!hasAny && !_isServerImagesLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          _buildEmptyState(theme, l10n),
        ],
      );
    }

    if (_isServerImagesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _viewMode == ViewMode.grid
        ? _buildGridViewCombined(theme)
        : _buildListViewCombined(theme);
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
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Mijoz rasmlari',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Bu yerda ${widget.tradingPoint.tradingPoint.name} mijoziga tegishli rasmlar ko\'rsatiladi',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build grid view for server images + local images
  Widget _buildGridViewCombined(ThemeData theme) {
    final totalCount = _serverImages.length + _photos.length;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        itemCount: totalCount,
        itemBuilder: (context, index) {
          if (index < _serverImages.length) {
            final image = _serverImages[index];
            return _buildServerImageCard(image, theme);
          }

          final localIndex = index - _serverImages.length;
          final photo = _photos[localIndex];
          return _buildLocalPhotoCard(photo, localIndex, theme);
        },
      ),
    );
  }

  /// Build list view for server images + local images
  Widget _buildListViewCombined(ThemeData theme) {
    final totalCount = _serverImages.length + _photos.length;

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index < _serverImages.length) {
          final image = _serverImages[index];
          return _buildServerImageListItem(image, theme);
        }

        final localIndex = index - _serverImages.length;
        final photo = _photos[localIndex];
        return _buildPhotoListItem(photo, localIndex, theme);
      },
    );
  }

  /// Build server image card for grid view
  Widget _buildServerImageCard(ClientImage image, ThemeData theme) {
    final previewUrl = _bestClientImagePreviewUrl(image);
    final previewProvider = _clientImageProviderFromUrl(previewUrl);

    return GestureDetector(
      onTap: () => _openServerImageViewer(image),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 1.0, // 1:1 aspect ratio
              child: previewProvider == null
                  ? Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(child: Icon(Icons.broken_image)),
                    )
                  : Image(
                      image: previewProvider,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (c, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                      },
                      errorBuilder: (c, e, s) {
                        return Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(child: Icon(Icons.broken_image)),
                        );
                      },
                    ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: image.isMain
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Main',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _isDeletingServerImage 
                        ? null 
                        : () => _showServerImageDeleteConfirmation(image),
                    tooltip: 'Rasmni o\'chirish',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  if (!image.isMain) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.star_border, color: Colors.amber),
                      onPressed: () => _requestSetAsMain(image),
                      tooltip: 'Asosiy rasmga o\'zgartirish',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build server image list item
  Widget _buildServerImageListItem(ClientImage image, ThemeData theme) {
    final previewUrl = _bestClientImagePreviewUrl(image);
    final previewProvider = _clientImageProviderFromUrl(previewUrl);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: GestureDetector(
          onTap: () => _openServerImageViewer(image),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: previewProvider == null
                  ? null
                  : DecorationImage(
                      image: previewProvider,
                      fit: BoxFit.cover,
                    ),
            ),
            child: previewProvider == null
                ? const Center(child: Icon(Icons.broken_image))
                : null,
          ),
        ),
        title: Text(
          image.isMain ? 'Asosiy rasm' : 'Rasm',
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          image.createdAtServer ?? 'Server vaqti noma\'lum',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: _isDeletingServerImage
                  ? null
                  : () => _showServerImageDeleteConfirmation(image),
              tooltip: 'Rasmni o\'chirish',
            ),
            if (image.isMain)
              const Icon(Icons.star, color: Colors.green)
            else
              IconButton(
                icon: const Icon(Icons.star_border, color: Colors.amber, size: 20),
                onPressed: () => _requestSetAsMain(image),
                tooltip: 'Asosiy rasmga o\'zgartirish',
              ),
          ],
        ),
        onTap: () => _openServerImageViewer(image),
      ),
    );
  }

  /// Build local photo card for grid view
  Widget _buildLocalPhotoCard(Map<String, dynamic> photo, int index, ThemeData theme) {
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
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Yuborilmagan',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
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
          child: Stack(
            children: [
              Container(
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
              // Small "pending" indicator on thumbnail
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
        ),
        title: Row(
          children: [
            Text(
              'Rasm ${index + 1}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            // "Yuborilmagan" badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange, width: 1),
              ),
              child: const Text(
                'Yuborilmagan',
                style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        subtitle: Text(
          photo['timestamp'] != null
              ? _formatDateTime(photo['timestamp'])
              : 'Vaqt noma\'lum',
        ),
        trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(index),
          ),
        onTap: () => _openFullScreenViewer(index),
      ),
    );
  }

  /// Build bottom bar with upload button
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
        child: _isUploading
            ? const Center(child: CircularProgressIndicator())
            : FilledButton.icon(
                onPressed: _photos.isEmpty ? null : _uploadImagesToServer,
                icon: const Icon(Icons.cloud_upload),
                label: Text('Serverga yuborish (${_photos.length} ta rasm)'),
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
  bool _isCapturing = false;
  late List<String> _localCapturedPhotos;
  bool _isCameraAvailable = true;

  @override
  void initState() {
    super.initState();
    _localCapturedPhotos = List.from(widget.capturedPhotos);

    // Listen for camera errors
    widget.cameraController.addListener(_onCameraError);
  }

  @override
  void dispose() {
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
      }
    }
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

          // Bottom spacing for safe area (moved to bottom of stack)
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

          // Capture button at bottom center (moved up in stack order)
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
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _localCapturedPhotos.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _openFullScreenViewer(index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(_localCapturedPhotos[index])),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
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
        ],
      ),
    );
  }

  /// Open full screen image viewer for camera slider
  void _openFullScreenViewer(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CameraFullScreenImageViewer(
          photos: _localCapturedPhotos,
          initialIndex: initialIndex,
        ),
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

      // Call the callback to save the photo
      await widget.onPhotoCaptured(imageFile);

      // Add to local list for immediate UI update
      if (mounted) {
        setState(() {
          _localCapturedPhotos.add(imageFile.path);
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

/// Full screen image viewer for camera captured photos
class CameraFullScreenImageViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const CameraFullScreenImageViewer({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<CameraFullScreenImageViewer> createState() => _CameraFullScreenImageViewerState();
}

class _CameraFullScreenImageViewerState extends State<CameraFullScreenImageViewer> {
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.photos.length}'),
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: FileImage(File(widget.photos[index])),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
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
}