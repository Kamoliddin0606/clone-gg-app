import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/auth/backend_permission_store.dart';
import '../../../../core/auth/permission_codenames.dart';
import '../../../../core/services/images/image_cache_manager.dart';
import '../../../../core/services/images/unified_image.dart';
import '../../../../core/services/service_locator.dart';
import '../../data/repositories/customer_photo_repository.dart';
import '../../services/customer_photo_change_notifier.dart';
import '../pages/customer_photo_fullscreen_page.dart';
import '../pages/customer_photos_page.dart';

/// V2 customer-photo carousel rendered on the client detail sheet.
/// Replaces the legacy V1 `ClientImageWidget` surface and the
/// previous single-image preview.
///
/// Behaviour:
/// - Loads `GET /api/mobile/v2/customers/{customerId}/photos/?ordering=-is_primary,order`
///   so the primary photo is always the first page.
/// - Auto-rotates every 4 s with a 6 s pause window after any user
///   pointer event (touch / swipe). Auto-rotate is suppressed when
///   the OS reports `MediaQuery.disableAnimations`.
/// - Manual swipe via [PageView] is always available.
/// - Double-tap opens [CustomerPhotoFullscreenPage] (Hero animated).
/// - Top-right edit button opens the V2 [CustomerPhotosPage] for
///   add / replace / delete / set-primary actions; on return the
///   carousel re-loads. Listens to [CustomerPhotoChangeNotifier]
///   for cross-screen edits as well.
/// - Single-photo: renders a static image with no PageView, dots,
///   or auto-timer (saves a frame, avoids the swipe affordance hint).
/// - Empty state: shows the centre add CTA when the user has the
///   `customers.add_customer_photo` permission, otherwise a quiet
///   read-only placeholder.
class CustomerPhotoPreview extends StatefulWidget {
  /// Backend exchange key — `tradingPoint.id` (the backend `code`).
  final String customerId;

  /// Display name — passed through to [CustomerPhotosPage] for its
  /// app bar.
  final String customerName;

  final double height;
  final BorderRadius? borderRadius;

  const CustomerPhotoPreview({
    super.key,
    required this.customerId,
    required this.customerName,
    this.height = 200,
    this.borderRadius,
  });

  @override
  State<CustomerPhotoPreview> createState() => _CustomerPhotoPreviewState();
}

class _CustomerPhotoPreviewState extends State<CustomerPhotoPreview> {
  late final CustomerPhotoRepository _repo;
  late final BackendPermissionStore _permStore;
  StreamSubscription<String>? _changeSub;

  late final PageController _pageController;
  Timer? _autoTimer;
  DateTime _lastInteractionAt = DateTime.fromMillisecondsSinceEpoch(0);

  List<UnifiedImage> _photos = const <UnifiedImage>[];
  int _currentIndex = 0;
  bool _isLoading = true;

  static const Duration _autoRotateInterval = Duration(seconds: 4);
  static const Duration _interactionPause = Duration(seconds: 6);

  @override
  void initState() {
    super.initState();
    _repo = sl<CustomerPhotoRepository>();
    _permStore = sl<BackendPermissionStore>();
    _pageController = PageController();
    _permStore.addListener(_onPermissionsChanged);
    if (sl.isRegistered<CustomerPhotoChangeNotifier>()) {
      _changeSub = sl<CustomerPhotoChangeNotifier>()
          .stream
          .where((id) => id == widget.customerId)
          .listen((_) {
        if (mounted) _load();
      });
    }
    _load();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _changeSub?.cancel();
    _permStore.removeListener(_onPermissionsChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPermissionsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final photos = await _repo.list(
        widget.customerId,
        ordering: '-is_primary,order',
      );
      if (!mounted) return;
      setState(() {
        _photos = photos;
        _currentIndex = 0;
        _isLoading = false;
      });
      _restartAutoTimer();
      _precacheNeighbours();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[PHOTO-PREVIEW] ✗ load failed for "${widget.customerId}": $e',
        );
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _photos = const [];
      });
      _autoTimer?.cancel();
    }
  }

  void _restartAutoTimer() {
    _autoTimer?.cancel();
    if (_photos.length < 2) return;
    if (MediaQuery.of(context).disableAnimations) return;
    _autoTimer = Timer.periodic(_autoRotateInterval, (_) {
      if (!mounted || !_pageController.hasClients) return;
      if (_photos.length < 2) return;
      if (DateTime.now().difference(_lastInteractionAt) < _interactionPause) {
        return;
      }
      final next = (_currentIndex + 1) % _photos.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _markInteraction() {
    _lastInteractionAt = DateTime.now();
  }

  void _precacheNeighbours() {
    if (_photos.isEmpty) return;
    final indices = <int>{
      _currentIndex,
      if (_photos.length > 1) (_currentIndex + 1) % _photos.length,
      if (_photos.length > 1)
        (_currentIndex - 1 + _photos.length) % _photos.length,
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final i in indices) {
        final url = _photos[i].urlForSize(UnifiedImageSize.medium) ??
            _photos[i].urlForSize(UnifiedImageSize.large);
        if (url == null) continue;
        precacheImage(
          CachedNetworkImageProvider(
            url,
            cacheManager: ImageCacheManager.instance,
          ),
          context,
        );
      }
    });
  }

  bool get _canViewGallery =>
      _permStore.hasAny(PermissionCodenames.customerPhotoAny);

  bool get _canAddPhoto =>
      _permStore.has(PermissionCodenames.customerAddPhoto);

  bool get _canEditPhotos =>
      _permStore.has(PermissionCodenames.customerChangePhoto) ||
      _permStore.has(PermissionCodenames.customerReplacePhoto) ||
      _permStore.has(PermissionCodenames.customerDeletePhoto) ||
      _permStore.has(PermissionCodenames.customerAddPhoto);

  Future<void> _openGallery() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerPhotosPage(
          customerId: widget.customerId,
          customerName: widget.customerName,
        ),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _openFullscreen() async {
    if (_photos.isEmpty) return;
    _autoTimer?.cancel();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerPhotoFullscreenPage(
          photos: _photos,
          initialIndex: _currentIndex,
          customerId: widget.customerId,
          customerName: widget.customerName,
          heroTagPrefix: 'customer-photo-${widget.customerId}',
        ),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final radius = widget.borderRadius ?? BorderRadius.circular(12);

    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: radius,
            child: _buildContent(theme, cs, l10n),
          ),
          if (_photos.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: _PageDots(count: _photos.length, current: _currentIndex),
            ),
          if (_photos.isNotEmpty && _canEditPhotos)
            _PositionedOverlayButton(
              alignment: Alignment.topRight,
              icon: Icons.edit,
              tooltip: l10n.customerPhotoPreview_editTooltip,
              onPressed: _openGallery,
            ),
          if (_photos.isEmpty && !_isLoading && _canAddPhoto)
            _PositionedOverlayButton(
              alignment: Alignment.center,
              icon: Icons.add_a_photo,
              tooltip: l10n.customerPhotoPreview_addTooltip,
              onPressed: _openGallery,
              expanded: true,
            ),
        ],
      ),
    );
  }

  Widget _buildContent(
    ThemeData theme,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    if (_isLoading) {
      return _ShimmerPlaceholder(color: cs.surfaceContainerHighest);
    }
    if (_photos.isEmpty) {
      return _EmptyState(l10n: l10n, cs: cs, canAdd: _canAddPhoto);
    }
    if (_photos.length == 1) {
      return _PhotoFrame(
        photo: _photos.first,
        cs: cs,
        heroTagPrefix: 'customer-photo-${widget.customerId}',
        onDoubleTap: _canViewGallery ? _openFullscreen : null,
      );
    }
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _markInteraction(),
      child: PageView.builder(
        controller: _pageController,
        itemCount: _photos.length,
        onPageChanged: (i) {
          setState(() => _currentIndex = i);
          _markInteraction();
          _precacheNeighbours();
        },
        itemBuilder: (context, i) => _PhotoFrame(
          photo: _photos[i],
          cs: cs,
          heroTagPrefix: 'customer-photo-${widget.customerId}',
          onDoubleTap: _canViewGallery ? _openFullscreen : null,
        ),
      ),
    );
  }
}

class _PhotoFrame extends StatelessWidget {
  final UnifiedImage photo;
  final ColorScheme cs;
  final String heroTagPrefix;
  final VoidCallback? onDoubleTap;

  const _PhotoFrame({
    required this.photo,
    required this.cs,
    required this.heroTagPrefix,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final url = photo.urlForSize(UnifiedImageSize.large) ??
        photo.urlForSize(UnifiedImageSize.medium);
    Widget image;
    if (url == null) {
      image = photo.hasBlurhash
          ? BlurHash(hash: photo.blurhash)
          : Container(color: cs.surfaceContainerHighest);
    } else {
      image = CachedNetworkImage(
        cacheManager: ImageCacheManager.instance,
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, _) => photo.hasBlurhash
            ? BlurHash(hash: photo.blurhash)
            : Container(color: cs.surfaceContainerHighest),
        errorWidget: (_, _, _) => Container(
          color: cs.surfaceContainerHighest,
          child: Icon(Icons.broken_image, color: cs.onSurfaceVariant),
        ),
      );
    }

    final hero = Hero(
      tag: '$heroTagPrefix-${photo.id}',
      child: image,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: onDoubleTap,
      child: hero,
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int current;

  const _PageDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(count, (i) {
            final active = i == current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: active ? 8 : 6,
              height: active ? 8 : 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: active ? Colors.white : Colors.white54,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ShimmerPlaceholder extends StatelessWidget {
  final Color color;
  const _ShimmerPlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  final ColorScheme cs;
  final bool canAdd;

  const _EmptyState({
    required this.l10n,
    required this.cs,
    required this.canAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_library_outlined,
                  size: 36, color: cs.onSurfaceVariant),
              const SizedBox(height: 8),
              Text(
                l10n.customerPhotoPreview_emptyTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                canAdd
                    ? l10n.customerPhotoPreview_emptyHintAdd
                    : l10n.customerPhotoPreview_emptyHintReadOnly,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PositionedOverlayButton extends StatelessWidget {
  final Alignment alignment;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool expanded;

  const _PositionedOverlayButton({
    required this.alignment,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final button = Tooltip(
      message: tooltip,
      child: Material(
        color: cs.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.all(expanded ? 16 : 10),
            child: Icon(
              icon,
              size: expanded ? 28 : 18,
              color: cs.onPrimary,
            ),
          ),
        ),
      ),
    );
    if (alignment == Alignment.center) {
      return Positioned.fill(child: Center(child: button));
    }
    return Positioned(
      top: 8,
      right: 8,
      child: button,
    );
  }
}
