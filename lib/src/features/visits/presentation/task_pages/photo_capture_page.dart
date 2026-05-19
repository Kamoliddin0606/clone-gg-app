import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/repositories/photo_repository.dart';
import '../../infra/photo/photo_compressor.dart';
import '../../infra/photo/photo_upload_service.dart';
import 'task_context.dart';

/// Shared widget for PHOTO_BEFORE / PHOTO_AFTER and any other "snap N
/// photos and move on" task. The page itself is renderer-agnostic — it
/// just enforces min/max counts pulled from the catalog's `config`.
///
/// Each captured shot is compressed, persisted to `photo_uploads` and
/// queued via [PhotoUploadService]; the finish envelope later picks up
/// the `remote_asset_id`s and stamps them onto the task payload.
class PhotoCapturePage extends StatefulWidget {
  const PhotoCapturePage({
    super.key,
    required this.ctx,
    required this.photos,
    required this.compressor,
    required this.uploader,
    required this.title,
  });

  final TaskContext ctx;
  final PhotoRepository photos;
  final PhotoCompressor compressor;
  final PhotoUploadService uploader;
  final String title;

  int get minCount => (ctx.config['min_count'] as int?) ?? 1;
  int get maxCount => (ctx.config['max_count'] as int?) ?? 5;

  @override
  State<PhotoCapturePage> createState() => _PhotoCapturePageState();
}

class _PhotoCapturePageState extends State<PhotoCapturePage> {
  final ImagePicker _picker = ImagePicker();
  final List<PhotoUpload> _captured = [];
  bool _busy = false;
  String? _error;

  Future<void> _capture(ImageSource source) async {
    if (_captured.length >= widget.maxCount) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final raw = await _picker.pickImage(
        source: source,
        imageQuality: 100, // we own compression downstream
      );
      if (raw == null) return;
      final compressed = await widget.compressor.compress(File(raw.path));
      final record = await widget.photos.capture(
        visitId: widget.ctx.visitId,
        taskCode: widget.ctx.taskCode,
        taskId: widget.ctx.taskId,
        source: compressed,
      );
      setState(() => _captured.add(record));
      // Fire-and-forget upload — UI will reflect status via repository reads.
      // ignore: unawaited_futures
      widget.uploader.cycle();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(PhotoUpload photo) async {
    await widget.photos.delete(photo.assetId);
    setState(() => _captured.removeWhere((p) => p.assetId == photo.assetId));
  }

  bool get _canComplete =>
      _captured.length >= widget.minCount && _captured.length <= widget.maxCount;

  void _complete() {
    widget.ctx.onCompleted({
      'photo_asset_ids':
          _captured.map((p) => p.assetId).toList(growable: false),
      'photo_count': _captured.length,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.ctx.onBack,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Suratlar: ${_captured.length} / ${widget.maxCount} '
                    '(kamida ${widget.minCount})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (_busy)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _captured.length,
              itemBuilder: (context, i) {
                final photo = _captured[i];
                return _PhotoTile(
                  photo: photo,
                  onDelete: () => _remove(photo),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _busy ? null : () => _capture(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Kamera'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _busy ? null : () => _capture(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galereya'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _canComplete ? _complete : null,
                    child: const Text('Tugatish'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, required this.onDelete});

  final PhotoUpload photo;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(photo.localPath),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ),
        Positioned(
          left: 4,
          bottom: 4,
          child: _StatusChip(status: photo.status),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, bg) = switch (status) {
      'confirmed' => ('OK', Colors.green),
      'uploading' => ('···', Colors.blue),
      'failed' => ('!', Colors.red),
      _ => ('…', theme.colorScheme.outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }
}
