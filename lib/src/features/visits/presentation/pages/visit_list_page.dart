import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../data/rest/visit_api.dart';
import '../../domain/entities/visit_read.dart';
import 'visit_detail_page.dart';

/// Cursor-paginated visit history. Pulls from `GET /visits/`, renders a
/// thin status chip + customer + timestamp per row, and lets the agent
/// drill into [VisitDetailPage] for the full task + photo view.
///
/// This is intentionally read-only — the new-visit entry point is on
/// the trading-points page. Visit history is for review only.
class VisitListPage extends StatefulWidget {
  const VisitListPage({super.key, this.customerId});

  /// Optional filter — pre-bound when the agent opens history from a
  /// customer's detail screen. Empty list page (no filter) shows every
  /// visit the caller owns.
  final String? customerId;

  @override
  State<VisitListPage> createState() => _VisitListPageState();
}

class _VisitListPageState extends State<VisitListPage> {
  final ScrollController _scrollController = ScrollController();
  final List<VisitReadSummary> _items = [];

  late final VisitApi _api;
  String? _cursor;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  static final _dateFmt = DateFormat.yMMMd().add_Hm();

  @override
  void initState() {
    super.initState();
    _api = GetIt.instance<VisitApi>();
    _scrollController.addListener(_onScroll);
    _loadNextPage(initial: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading) return;
    // Trigger the next page when the user gets within one viewport of
    // the bottom — feels smoother than waiting for the literal end.
    final threshold = _scrollController.position.maxScrollExtent -
        _scrollController.position.viewportDimension;
    if (_scrollController.position.pixels >= threshold) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage({bool initial = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      if (initial) _error = null;
    });
    try {
      final page = await _api.fetchVisits(
        cursor: _cursor,
        customerId: widget.customerId,
        limit: 50,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _cursor = _extractCursor(page.nextCursorUrl);
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  /// DRF returns the next page as a full URL containing `?cursor=…`.
  /// Strip everything but the cursor token so the next request stays
  /// shape-stable (the dispatcher already knows the base URL).
  String? _extractCursor(String? url) {
    if (url == null) return null;
    final uri = Uri.tryParse(url);
    return uri?.queryParameters['cursor'];
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _cursor = null;
      _hasMore = true;
      _error = null;
    });
    await _loadNextPage(initial: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tashriflar tarixi'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty && _error != null) {
      return _ErrorState(error: _error!, onRetry: _refresh);
    }
    if (_items.isEmpty) {
      return const _EmptyState();
    }
    // Scope-cascade rollout (2026-05-17): split the chronological list
    // into a planned section and an unplanned section so the agent sees
    // their route at a glance and ad-hoc orders are visibly distinct.
    // Order within each section follows the original cursor ordering
    // (newest first) — we only group, never re-sort.
    final planned = <VisitReadSummary>[];
    final unplanned = <VisitReadSummary>[];
    for (final v in _items) {
      (v.plannedFlag ? planned : unplanned).add(v);
    }
    final rows = <_ListRow>[
      if (planned.isNotEmpty) ...[
        _ListRow.header(
          icon: Icons.event_available,
          label: 'Bugungi reja',
          count: planned.length,
        ),
        ...planned.map(_ListRow.visit),
      ],
      if (unplanned.isNotEmpty) ...[
        _ListRow.header(
          icon: Icons.flash_on,
          label: 'Reja tashqari',
          count: unplanned.length,
        ),
        ...unplanned.map(_ListRow.visit),
      ],
    ];

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: rows.length + 1,
      separatorBuilder: (_, i) {
        // Don't draw a divider above a section header or above the
        // trailing footer slot — headers carry their own visual weight,
        // and the footer should sit clean below the last row.
        final atFooter = i == rows.length - 1;
        final nextIsHeader =
            i + 1 < rows.length && rows[i + 1].isHeader;
        if (atFooter || nextIsHeader) return const SizedBox.shrink();
        return const Divider(height: 1);
      },
      itemBuilder: (context, i) {
        if (i == rows.length) {
          // Trailing footer — progress while loading, "end" marker
          // otherwise, error banner with retry on failure.
          if (_loading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          if (_error != null) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: Text('Yuklashda xato: $_error')),
                  TextButton(
                    onPressed: _loadNextPage,
                    child: const Text('Qayta urinish'),
                  ),
                ],
              ),
            );
          }
          if (!_hasMore) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('Boshqa tashrif yo\'q')),
            );
          }
          return const SizedBox.shrink();
        }
        final row = rows[i];
        if (row.header != null) {
          return _SectionHeader(header: row.header!);
        }
        return _VisitRow(visit: row.visit!);
      },
    );
  }
}

/// Two-shape row: either a section header or a visit summary. We compose
/// the rendered list out of these so the `ListView.separated` divider
/// logic can treat the two uniformly.
class _ListRow {
  const _ListRow._({this.header, this.visit});
  factory _ListRow.header({
    required IconData icon,
    required String label,
    required int count,
  }) =>
      _ListRow._(header: _SectionHeaderData(icon: icon, label: label, count: count));
  factory _ListRow.visit(VisitReadSummary v) => _ListRow._(visit: v);

  final _SectionHeaderData? header;
  final VisitReadSummary? visit;

  bool get isHeader => header != null;
}

class _SectionHeaderData {
  const _SectionHeaderData({
    required this.icon,
    required this.label,
    required this.count,
  });
  final IconData icon;
  final String label;
  final int count;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.header});
  final _SectionHeaderData header;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Icon(header.icon,
              size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            header.label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${header.count}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitRow extends StatelessWidget {
  const _VisitRow({required this.visit});
  final VisitReadSummary visit;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _StatusDot(status: visit.status),
      title: Text(visit.customerId,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(_VisitListPageState._dateFmt.format(visit.startedAt)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => VisitDetailPage(visitId: visit.id),
        ));
      },
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'synced_1c' => (Colors.green, '1C'),
      'submitted' => (Theme.of(context).colorScheme.tertiary, '…'),
      'rejected' => (Colors.red, '!'),
      'cancelled' => (Theme.of(context).colorScheme.outline, '✕'),
      'draft' => (Theme.of(context).colorScheme.outline, 'D'),
      _ => (Theme.of(context).colorScheme.outline, '?'),
    };
    return CircleAvatar(
      backgroundColor: color,
      radius: 14,
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      // ListView so the parent RefreshIndicator stays responsive even
      // when there's nothing to scroll over.
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 12),
                const Text('Tashriflar topilmadi'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text('Yuklashda xato: $error',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Qayta urinish'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
