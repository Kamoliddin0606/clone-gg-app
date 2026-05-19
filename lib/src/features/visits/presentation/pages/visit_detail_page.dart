import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../data/rest/visit_api.dart';
import '../../domain/entities/entity_image_ref.dart';
import '../../domain/entities/visit_read.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../widgets/retention_aware_photo.dart';

/// Read-only detail view for a finished visit. Used from
/// [VisitListPage] and (later) from the dead-letter screen so the
/// agent / ops can inspect the exact envelope the backend persisted.
///
/// The page fetches `GET /visits/{id}/` once and renders four
/// sections:
///   1. Header — customer + status + duration.
///   2. Location — start / finish GPS fixes (raw lat/lng + accuracy).
///   3. Tasks — one card per task with payload preview + retention-
///      aware photo strip.
///   4. Debug — collapsible "raw payload JSON" for the keenest ops.
class VisitDetailPage extends StatefulWidget {
  const VisitDetailPage({super.key, required this.visitId});
  final String visitId;

  @override
  State<VisitDetailPage> createState() => _VisitDetailPageState();
}

class _VisitDetailPageState extends State<VisitDetailPage> {
  late final Future<VisitReadDetail?> _future;
  static final _dateFmt = DateFormat.yMMMd().add_Hms();

  @override
  void initState() {
    super.initState();
    _future = GetIt.instance<VisitApi>().fetchVisitDetail(widget.visitId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tashrif tafsilotlari')),
      body: FutureBuilder<VisitReadDetail?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorView(
              error: snap.error!,
              onRetry: () => setState(() {
                _future = GetIt.instance<VisitApi>()
                    .fetchVisitDetail(widget.visitId);
              }),
            );
          }
          final visit = snap.data;
          if (visit == null) return const _NotFoundView();
          return _DetailBody(visit: visit, dateFmt: _dateFmt);
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.visit, required this.dateFmt});
  final VisitReadDetail visit;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    // Catalog drives display names ("Foto oldidan" vs raw "PHOTO_BEFORE").
    // It might not be warmed yet (offline boot) — fall back to the wire
    // code in that case.
    final catalog = GetIt.instance.isRegistered<CatalogRepository>()
        ? GetIt.instance<CatalogRepository>().cached
        : null;
    final locale = Localizations.localeOf(context).languageCode;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderCard(visit: visit, dateFmt: dateFmt),
        const SizedBox(height: 12),
        _LocationCard(visit: visit),
        const SizedBox(height: 12),
        Text(
          'Vazifalar (${visit.tasks.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final task in [...visit.tasks]..sort(
            (a, b) => a.displayOrder.compareTo(b.displayOrder)))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _TaskCard(
              task: task,
              displayName: catalog?.byCode(task.taskCode)?.displayName(locale) ??
                  task.taskCode,
              dateFmt: dateFmt,
            ),
          ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.visit, required this.dateFmt});
  final VisitReadDetail visit;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(visit.customerId,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                _StatusChip(status: visit.status),
              ],
            ),
            const SizedBox(height: 8),
            _kv('Boshlangan', dateFmt.format(visit.startedAt)),
            if (visit.finishedAt != null)
              _kv('Yakunlangan', dateFmt.format(visit.finishedAt!)),
            if (visit.totalDurationMs != null)
              _kv('Davomiyligi', _formatDuration(visit.totalDurationMs!)),
            _kv('Rejali', visit.plannedFlag ? 'Ha' : 'Yo\'q'),
            if (visit.outcome != null) _kv('Natija', visit.outcome!),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int ms) {
    final secs = ms ~/ 1000;
    final mins = secs ~/ 60;
    final hours = mins ~/ 60;
    if (hours > 0) return '$hours soat ${mins % 60} daqiqa';
    if (mins > 0) return '$mins daqiqa ${secs % 60} soniya';
    return '$secs soniya';
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(key)),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'synced_1c' => (Colors.green, '1C ga yetkazildi'),
      'submitted' => (Theme.of(context).colorScheme.tertiary, 'Yuborildi'),
      'rejected' => (Colors.red, 'Rad etildi'),
      'cancelled' => (Theme.of(context).colorScheme.outline, 'Bekor'),
      'draft' => (Theme.of(context).colorScheme.outline, 'Qoralama'),
      _ => (Theme.of(context).colorScheme.outline, status),
    };
    return Chip(
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      label: Text(label, style: TextStyle(color: color)),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.visit});
  final VisitReadDetail visit;

  @override
  Widget build(BuildContext context) {
    if (visit.startLocation == null && visit.finishLocation == null) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lokatsiya',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (visit.startLocation != null)
              _LocationRow(
                label: 'Boshlangan',
                location: visit.startLocation!,
              ),
            if (visit.finishLocation != null)
              _LocationRow(
                label: 'Yakunlangan',
                location: visit.finishLocation!,
              ),
          ],
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.label, required this.location});
  final String label;
  final Map<String, dynamic> location;

  @override
  Widget build(BuildContext context) {
    final lat = (location['lat'] as num?)?.toStringAsFixed(6);
    final lng = (location['lng'] as num?)?.toStringAsFixed(6);
    final accuracy = (location['accuracy_m'] as num?)?.toStringAsFixed(1);
    final mocked = location['mocked'] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label)),
          Expanded(
            child: Text(
              '$lat, $lng${accuracy != null ? ' (±${accuracy}m)' : ''}'
              '${mocked ? ' ⚠️ mock' : ''}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.displayName,
    required this.dateFmt,
  });

  final VisitReadTask task;
  final String displayName;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconFor(task.status),
                    color: _colorFor(task.status, context)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(displayName,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                Text(task.taskCode,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if (task.durationMs != null && task.durationMs! > 0) ...[
              const SizedBox(height: 4),
              Text('Davomiyligi: ${(task.durationMs! / 1000).toStringAsFixed(1)} s',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            if (task.images.isNotEmpty) ...[
              const SizedBox(height: 8),
              _PhotoStrip(images: task.images),
            ],
            if (_payloadPreview(task.payload).isNotEmpty) ...[
              const SizedBox(height: 8),
              _PayloadPreview(rows: _payloadPreview(task.payload)),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String status) => switch (status) {
        'completed' => Icons.check_circle,
        'skipped' => Icons.skip_next,
        'failed' => Icons.error_outline,
        _ => Icons.radio_button_unchecked,
      };

  Color _colorFor(String status, BuildContext ctx) => switch (status) {
        'completed' => Colors.green,
        'skipped' => Theme.of(ctx).colorScheme.outline,
        'failed' => Colors.red,
        _ => Theme.of(ctx).colorScheme.outline,
      };

  /// Cheap key-value preview for the payload. We avoid dumping nested
  /// arrays (audit items, product lists) — those can balloon to dozens
  /// of rows and aren't useful in a quick-scan UI. Tap-to-expand can be
  /// added later if ops asks.
  List<MapEntry<String, String>> _payloadPreview(Map<String, dynamic> p) {
    final rows = <MapEntry<String, String>>[];
    p.forEach((k, v) {
      if (v is Map || v is List) {
        if (v is List) {
          rows.add(MapEntry(k, '${v.length} ta element'));
        }
        return;
      }
      if (v == null || v.toString().isEmpty) return;
      rows.add(MapEntry(k, v.toString()));
    });
    return rows.take(8).toList(growable: false);
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.images});
  final List<EntityImageRef> images;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final image = images[i];
          return GestureDetector(
            onTap: () => _showFullScreen(context, image),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 80,
                height: 80,
                child: RetentionAwarePhoto(image: image),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullScreen(BuildContext context, EntityImageRef image) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(backgroundColor: Colors.black),
        backgroundColor: Colors.black,
        body: Center(
          child: InteractiveViewer(
            child: RetentionAwarePhoto(image: image, thumbnail: false),
          ),
        ),
      ),
    ));
  }
}

class _PayloadPreview extends StatelessWidget {
  const _PayloadPreview({required this.rows});
  final List<MapEntry<String, String>> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(e.key,
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                    Expanded(
                      child: Text(e.value,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ],
                ),
              ))
          .toList(growable: false),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          const Text('Tashrif topilmadi'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text('Yuklashda xato:\n$error',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Qayta urinish')),
          ],
        ),
      ),
    );
  }
}
