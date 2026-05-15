import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/auth/backend_permission_store.dart';
import '../../../../core/auth/permission_codenames.dart';
import '../../../../core/services/images/image_cache_manager.dart';
import '../../../../core/services/images/unified_image.dart';
import '../../../../core/services/service_locator.dart';
import '../../data/repositories/customer_photo_repository.dart';
import '../../services/customer_photo_change_notifier.dart';

/// Immersive full-screen viewer for customer photos with pinch-zoom
/// + pan via [PhotoViewGallery]. Opened from [CustomerPhotoPreview]
/// on double-tap.
///
/// The photos list is passed in directly (rather than re-fetched)
/// so the Hero animation from the carousel page is deterministic
/// and there is no extra round-trip on open.
///
/// Single-tap on a photo toggles the chrome (close button + page
/// indicator + set-primary button). The "Set as primary" action is
/// gated on `customerChangePhoto`; on success the photos list is
/// re-fetched and the carousel that triggered this page also
/// reloads on pop.
class CustomerPhotoFullscreenPage extends StatefulWidget {
  final List<UnifiedImage> photos;
  final int initialIndex;
  final String customerId;
  final String customerName;

  /// Hero tag prefix shared with [CustomerPhotoPreview]. Per-photo
  /// tag is `${heroTagPrefix}-${photo.id}`.
  final String heroTagPrefix;

  const CustomerPhotoFullscreenPage({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.customerId,
    required this.customerName,
    required this.heroTagPrefix,
  });

  @override
  State<CustomerPhotoFullscreenPage> createState() =>
      _CustomerPhotoFullscreenPageState();
}

class _CustomerPhotoFullscreenPageState
    extends State<CustomerPhotoFullscreenPage> with WidgetsBindingObserver {
  late PageController _pageController;
  late int _currentIndex;
  late List<UnifiedImage> _photos;
  bool _chromeVisible = true;
  bool _settingPrimary = false;

  @override
  void initState() {
    super.initState();
    _photos = List<UnifiedImage>.of(widget.photos);
    _currentIndex = widget.initialIndex.clamp(0, _photos.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restoreSystemUi();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the OS pauses us (e.g. user backgrounds the app from the
    // viewer) the UI mode reset in `dispose` may not fire — make
    // sure overlays come back so other pages don't end up
    // chrome-less on resume.
    if (state == AppLifecycleState.paused) {
      _restoreSystemUi();
    } else if (state == AppLifecycleState.resumed && mounted) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _restoreSystemUi() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
  }

  bool get _canSetPrimary =>
      sl<BackendPermissionStore>().has(PermissionCodenames.customerChangePhoto);

  Future<void> _setCurrentAsPrimary() async {
    if (_settingPrimary) return;
    final current = _photos[_currentIndex];
    if (current.isPrimary) return;
    setState(() => _settingPrimary = true);
    try {
      await sl<CustomerPhotoRepository>().patchMetadata(
        customerId: widget.customerId,
        photoId: current.id,
        isPrimary: true,
      );
      // Optimistic local update — flip flags so the star reflects
      // the new primary without an extra GET.
      setState(() {
        _photos = _photos.map((p) {
          if (p.id == current.id) {
            return p.copyWith(isPrimary: true);
          }
          return p.isPrimary ? p.copyWith(isPrimary: false) : p;
        }).toList();
        _settingPrimary = false;
      });
      if (sl.isRegistered<CustomerPhotoChangeNotifier>()) {
        sl<CustomerPhotoChangeNotifier>().notifyChanged(widget.customerId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _settingPrimary = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = _photos[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => setState(() => _chromeVisible = !_chromeVisible),
            child: PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: _photos.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              scrollPhysics: const BouncingScrollPhysics(),
              backgroundDecoration:
                  const BoxDecoration(color: Colors.black),
              loadingBuilder: (context, event) => const Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
              builder: (context, i) {
                final p = _photos[i];
                final url = p.urlForSize(UnifiedImageSize.large) ??
                    p.urlForSize(UnifiedImageSize.medium) ??
                    p.urlForSize(UnifiedImageSize.small);
                return PhotoViewGalleryPageOptions(
                  imageProvider: url == null
                      ? const AssetImage('assets/images/marker.png')
                          as ImageProvider
                      : CachedNetworkImageProvider(
                          url,
                          cacheManager: ImageCacheManager.instance,
                        ),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                  heroAttributes: PhotoViewHeroAttributes(
                    tag: '${widget.heroTagPrefix}-${p.id}',
                  ),
                );
              },
            ),
          ),
          AnimatedOpacity(
            opacity: _chromeVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_chromeVisible,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _ChromeButton(
                        icon: Icons.close,
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_currentIndex + 1} / ${_photos.length}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (current.isPrimary)
                        _ChromeButton(
                          icon: Icons.star,
                          tooltip: l10n.customerPhotos_primaryBadge,
                          onPressed: null,
                          iconColor: Colors.amberAccent,
                        )
                      else if (_canSetPrimary)
                        _ChromeButton(
                          icon: _settingPrimary
                              ? Icons.hourglass_top
                              : Icons.star_border,
                          tooltip: l10n.customerPhotos_setPrimary,
                          onPressed:
                              _settingPrimary ? null : _setCurrentAsPrimary,
                        )
                      else
                        const SizedBox(width: 44),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChromeButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? iconColor;

  const _ChromeButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: Icon(icon, color: iconColor ?? Colors.white),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
