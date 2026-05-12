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
import '../pages/customer_photos_page.dart';

/// V2-only customer photo preview rendered on the client detail
/// sheet. Replaces the legacy [ClientImageWidget] surface there.
///
/// Responsibilities:
/// - Read the first / primary photo from
///   `GET /api/mobile/v2/customers/{code_1c}/photos/`.
/// - Surface a permission-gated **edit overlay** in the top-right
///   corner (visible when the user holds any of the four photo
///   codenames).
/// - When the customer has no photos yet, render a clear empty
///   placeholder + an **Add** affordance for users with
///   `customers.add_customer_photo`.
/// - Tap on the preview always opens the full V2 gallery
///   ([CustomerPhotosPage]), where add / replace / delete / set-primary
///   are implemented.
///
/// The legacy V1 `/api/mobile/v1/images/` endpoint is NOT consulted
/// from here — this surface is the V2 cutover for the customer-photo
/// flow on mobile.
class CustomerPhotoPreview extends StatefulWidget {
  /// Backend exchange key: `code_1c` of the customer (NOT a UUID).
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

  UnifiedImage? _photo;
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _repo = sl<CustomerPhotoRepository>();
    _permStore = sl<BackendPermissionStore>();
    _permStore.addListener(_onPermissionsChanged);
    _load();
  }

  @override
  void dispose() {
    _permStore.removeListener(_onPermissionsChanged);
    super.dispose();
  }

  void _onPermissionsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Prefer the customer's primary photo so the preview matches
      // what `is_primary=true` users expect from the legacy UX.
      // `ordering=-is_primary,order` keeps a primary row first when
      // one exists; fall back to the first row otherwise.
      final photos = await _repo.list(
        widget.customerId,
        ordering: '-is_primary,order',
      );
      if (!mounted) return;
      setState(() {
        _photo = photos.isEmpty
            ? null
            : (photos.firstWhere(
                (p) => p.isPrimary,
                orElse: () => photos.first,
              ));
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[PHOTO-PREVIEW] ✗ load failed for code_1c="${widget.customerId}": $e',
        );
      }
      if (!mounted) return;
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
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
    // Refresh on return — the gallery may have added / replaced /
    // deleted; the preview should reflect the new primary state.
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _canViewGallery ? _openGallery : null,
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: radius,
                child: _buildPreviewLayer(theme, cs, l10n),
              ),
              if (_photo != null && _canEditPhotos)
                _PositionedOverlayButton(
                  alignment: Alignment.topRight,
                  icon: Icons.edit,
                  tooltip: l10n.customerPhotoPreview_editTooltip,
                  onPressed: _openGallery,
                ),
              if (_photo == null && !_isLoading && _canAddPhoto)
                _PositionedOverlayButton(
                  alignment: Alignment.center,
                  icon: Icons.add_a_photo,
                  tooltip: l10n.customerPhotoPreview_addTooltip,
                  onPressed: _openGallery,
                  expanded: true,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewLayer(
    ThemeData theme,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    if (_isLoading) {
      return _ShimmerPlaceholder(color: cs.surfaceVariant);
    }
    if (_error != null && _photo == null) {
      // Treat error like empty — the V2 endpoint legitimately returns
      // 404 / 401 if the customer is unknown or the user lost access.
      return _EmptyState(
        l10n: l10n,
        cs: cs,
        canAdd: _canAddPhoto,
      );
    }
    final photo = _photo;
    if (photo == null) {
      return _EmptyState(l10n: l10n, cs: cs, canAdd: _canAddPhoto);
    }
    final url = photo.urlForSize(UnifiedImageSize.large) ??
        photo.urlForSize(UnifiedImageSize.medium);
    if (url == null) {
      // Photo row exists but the variants haven't been processed yet.
      return photo.blurhash.isNotEmpty
          ? BlurHash(hash: photo.blurhash)
          : Container(color: cs.surfaceVariant);
    }
    return CachedNetworkImage(
      cacheManager: ImageCacheManager.instance,
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => photo.blurhash.isNotEmpty
          ? BlurHash(hash: photo.blurhash)
          : Container(color: cs.surfaceVariant),
      errorWidget: (_, _, _) => Container(
        color: cs.surfaceVariant,
        child: Icon(Icons.broken_image, color: cs.onSurfaceVariant),
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
      color: cs.surfaceVariant.withOpacity(0.35),
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
    // The Stack puts the centre overlay using Positioned.fill; the
    // edge overlay uses an 8 px gap from the requested corner.
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
