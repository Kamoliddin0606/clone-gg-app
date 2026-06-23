import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/auth/permission_codenames.dart';
import '../../../../core/services/images/image_cache_manager.dart';
import '../../../../core/services/images/unified_image.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/token_service.dart';
import '../../../../../l10n/app_localizations.dart';
import '../bloc/customer_photo_cubit.dart';
import '../widgets/customer_scope_error_handler.dart';
import '../bloc/customer_photo_state.dart';

/// Per-customer photo gallery page.
///
/// Reachable from the trading-points list. Reads + writes go through
/// the V2 customer-photo CRUD endpoints; the display layer reuses the
/// existing image cache + BlurHash pipeline.
class CustomerPhotosPage extends StatelessWidget {
  /// Backend UUID of the customer (NOT the 1C `code_1c`). Required.
  final String customerId;

  /// Customer display name — only used for the AppBar title.
  final String customerName;

  const CustomerPhotosPage({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CustomerPhotoCubit>(
      create: (_) =>
          sl.get<CustomerPhotoCubit>(param1: customerId)..load(),
      child: _CustomerPhotosView(customerName: customerName),
    );
  }
}

class _CustomerPhotosView extends StatelessWidget {
  final String customerName;

  const _CustomerPhotosView({required this.customerName});

  List<String> get _permissions =>
      sl<TokenService>().getCachedGates()?.permissions ??
      const <String>[];

  bool get _canAdd =>
      _permissions.has(PermissionCodenames.customerAddPhoto);
  bool get _canChange =>
      _permissions.has(PermissionCodenames.customerChangePhoto);
  bool get _canDelete =>
      _permissions.has(PermissionCodenames.customerDeletePhoto);
  bool get _canReplace =>
      _permissions.has(PermissionCodenames.customerReplacePhoto);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<CustomerPhotoCubit, CustomerPhotoState>(
      listenWhen: (prev, curr) =>
          prev.errorCode != curr.errorCode && curr.errorCode != null,
      listener: (context, state) async {
        final code = state.errorCode ?? '';
        if (CustomerScopeErrorHandler.handles(code)) {
          final shouldRetry =
              await CustomerScopeErrorHandler.handle(context, code);
          // Picking a project resolves `customer_project_required` — reload
          // the gallery so the now-valid `X-Project-Id` header is applied.
          // Scoped to this one code so codes the client can't self-fix
          // never trigger a reload loop.
          if (shouldRetry &&
              code == 'customer_project_required' &&
              context.mounted) {
            context.read<CustomerPhotoCubit>().load();
          }
        } else {
          final messenger = ScaffoldMessenger.of(context);
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(_errorText(l10n, state))));
        }
        if (context.mounted) {
          context.read<CustomerPhotoCubit>().clearError();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  l10n.customerPhotos_title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              if (state.cap.knownMax != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: Chip(
                      label: Text(
                        l10n.customerPhotos_capBadge(
                          state.cap.current,
                          state.cap.knownMax!,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
            ],
          ),
          body: _buildBody(context, state, l10n),
          floatingActionButton: _canAdd
              ? FloatingActionButton(
                  onPressed: state.status == CustomerPhotoStatus.uploading
                      ? null
                      : () => _onAddTapped(context),
                  child: const Icon(Icons.add_a_photo),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    CustomerPhotoState state,
    AppLocalizations l10n,
  ) {
    if (state.status == CustomerPhotoStatus.loading && state.photos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.photos.isEmpty &&
        state.status != CustomerPhotoStatus.uploading) {
      return _EmptyState(canAdd: _canAdd, onAdd: () => _onAddTapped(context));
    }

    return RefreshIndicator(
      onRefresh: () => context.read<CustomerPhotoCubit>().refresh(),
      child: CustomScrollView(
        slivers: [
          if (state.status == CustomerPhotoStatus.uploading)
            SliverToBoxAdapter(
              child: _UploadProgressBanner(
                completed: state.uploadCompleted,
                total: state.uploadingCount,
                label: l10n.customerPhotos_uploading,
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _PhotoTile(
                  photo: state.photos[i],
                  onLongPress: () => _onPhotoLongPress(
                    context,
                    state.photos[i],
                  ),
                ),
                childCount: state.photos.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Actions -------------------------------------------------------------

  Future<void> _onAddTapped(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(l10n.customerPhotos_pickCamera),
              onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.customerPhotos_pickGallery),
              onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    if (!context.mounted) return;

    final picker = ImagePicker();
    if (source == ImageSource.camera) {
      final shot = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 88,
      );
      if (shot == null || !context.mounted) return;
      await context
          .read<CustomerPhotoCubit>()
          .addOne(File(shot.path));
    } else {
      final picks = await picker.pickMultiImage(imageQuality: 88);
      if (picks.isEmpty || !context.mounted) return;
      // Backend caps the bulk endpoint at 20 files; clip on the
      // client side just to fail fast with a friendlier UX.
      final selected = picks.take(20).toList(growable: false);
      if (selected.length == 1) {
        await context
            .read<CustomerPhotoCubit>()
            .addOne(File(selected.first.path));
      } else {
        await context
            .read<CustomerPhotoCubit>()
            .addMany(selected.map((p) => File(p.path)).toList());
      }
    }
  }

  Future<void> _onPhotoLongPress(
    BuildContext context,
    UnifiedImage photo,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<CustomerPhotoCubit>();
    final action = await showModalBottomSheet<_TileAction>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Wrap(
          children: [
            if (_canChange && !photo.isPrimary)
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: Text(l10n.customerPhotos_setPrimary),
                onTap: () => Navigator.pop(sheetCtx, _TileAction.setPrimary),
              ),
            if (_canChange)
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(l10n.customerPhotos_editAlt),
                onTap: () => Navigator.pop(sheetCtx, _TileAction.editAlt),
              ),
            if (_canReplace)
              ListTile(
                leading: const Icon(Icons.cameraswitch_outlined),
                title: Text(l10n.customerPhotos_replaceAction),
                onTap: () => Navigator.pop(sheetCtx, _TileAction.replace),
              ),
            if (_canDelete)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.customerPhotos_deleteAction),
                onTap: () => Navigator.pop(sheetCtx, _TileAction.delete),
              ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case _TileAction.setPrimary:
        await cubit.setPrimary(photo.id);
        break;
      case _TileAction.editAlt:
        if (!context.mounted) return;
        final newAlt = await _promptForAlt(context, initial: photo.alt);
        if (newAlt != null) {
          await cubit.patch(photo.id, alt: newAlt);
        }
        break;
      case _TileAction.replace:
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 88,
        );
        if (picked == null) return;
        await cubit.replace(photo.id, File(picked.path));
        break;
      case _TileAction.delete:
        if (!context.mounted) return;
        final confirmed = await _confirmDelete(context);
        if (confirmed == true) {
          await cubit.delete(photo.id);
        }
        break;
    }
  }

  Future<String?> _promptForAlt(
    BuildContext context, {
    required String initial,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(l10n.customerPhotos_editAlt),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 200,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text(MaterialLocalizations.of(dlgCtx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dlgCtx, controller.text.trim()),
            child: Text(l10n.customerPhotos_save),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(l10n.customerPhotos_confirmDeleteTitle),
        content: Text(l10n.customerPhotos_confirmDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: Text(MaterialLocalizations.of(dlgCtx).cancelButtonLabel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: Text(l10n.customerPhotos_deleteAction),
          ),
        ],
      ),
    );
  }

  // ---- Error mapping -------------------------------------------------------

  String _errorText(AppLocalizations l10n, CustomerPhotoState state) {
    final code = state.errorCode ?? '';
    final details = state.errorDetails ?? const <String, dynamic>{};
    switch (code) {
      case 'customer_photo_limit_exceeded':
        final max = (details['max'] as num?)?.toInt() ?? 0;
        final current = (details['current'] as num?)?.toInt() ?? 0;
        return l10n.customerPhotos_capExceeded(current, max);
      case 'image_too_large':
        return l10n.customerPhotos_err_tooLarge;
      case 'image_invalid_format':
        return l10n.customerPhotos_err_invalidFormat;
      case 'image_dimensions_too_small':
        return l10n.customerPhotos_err_dimensionsTooSmall;
      case 'image_dimensions_too_large':
        return l10n.customerPhotos_err_dimensionsTooLarge;
      case 'customer_photo_not_found':
      case 'not_found':
        return l10n.customerPhotos_err_notFound;
      case 'permission_denied':
        return l10n.customerPhotos_err_permissionDenied;
      case 'image_reprocess_not_supported':
        return l10n.customerPhotos_reprocessNotSupported;
      case 'endpoint_not_implemented':
        return l10n.customerPhotos_err_endpointNotImplemented;
      default:
        return l10n.customerPhotos_err_unknown;
    }
  }
}

enum _TileAction { setPrimary, editAlt, replace, delete }

class _PhotoTile extends StatelessWidget {
  final UnifiedImage photo;
  final VoidCallback onLongPress;

  const _PhotoTile({required this.photo, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final url = photo.urlForSize(UnifiedImageSize.medium);
    final hasBlurhash = photo.blurhash.isNotEmpty;

    Widget child;
    if (url != null) {
      child = CachedNetworkImage(
        cacheManager: ImageCacheManager.instance,
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, _) => hasBlurhash
            ? BlurHash(hash: photo.blurhash)
            : Container(color: Colors.black12),
        errorWidget: (_, _, _) => Container(
          color: Colors.black12,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    } else {
      // No variant URL yet → still processing. Show BlurHash if any,
      // otherwise a neutral placeholder + spinner.
      child = Stack(
        fit: StackFit.expand,
        children: [
          if (hasBlurhash)
            BlurHash(hash: photo.blurhash)
          else
            Container(color: Colors.black12),
          const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (photo.isPrimary)
              const Positioned(
                left: 4,
                top: 4,
                child: _PrimaryBadge(),
              ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryBadge extends StatelessWidget {
  const _PrimaryBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.white, size: 12),
          const SizedBox(width: 2),
          Text(
            l10n.customerPhotos_primaryBadge,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _UploadProgressBanner extends StatelessWidget {
  final int completed;
  final int total;
  final String label;

  const _UploadProgressBanner({
    required this.completed,
    required this.total,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? null : completed / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label  ($completed / $total)'),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: value),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool canAdd;
  final VoidCallback onAdd;

  const _EmptyState({required this.canAdd, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_library_outlined,
              size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(l10n.customerPhotos_emptyState),
          if (canAdd) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_a_photo),
              label: Text(l10n.customerPhotos_addAction),
            ),
          ],
        ],
      ),
    );
  }
}

