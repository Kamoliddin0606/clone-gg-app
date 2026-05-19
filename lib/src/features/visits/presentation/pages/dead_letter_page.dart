import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/repositories/outbox_repository.dart';
import '../../infra/visit_finish_orchestrator.dart';
import '../bloc/outbox_status/outbox_status_cubit.dart';

/// Settings → Sync screen.
///
/// Lists envelopes the dispatcher gave up on (`dead_letter`) plus those
/// currently mid-retry (`pending` / `retrying`) so the agent can see
/// progress. Manual "retry" requeues with `attempts = 0`; "discard"
/// drops the row entirely (and is the only way to clear a sync after the
/// customer decision to abandon the visit).
class DeadLetterPage extends StatefulWidget {
  const DeadLetterPage({super.key});

  @override
  State<DeadLetterPage> createState() => _DeadLetterPageState();
}

class _DeadLetterPageState extends State<DeadLetterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sinxronlash'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Yuborilmagan'),
            Tab(text: 'Kutilmoqda'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Hammasini qayta urinish',
            icon: const Icon(Icons.replay),
            onPressed: () =>
                context.read<OutboxStatusCubit>().retryAllDeadLetter(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _StatusList(status: 'dead_letter', emptyHint: 'Yuborilmagan tashriflar yo\'q.'),
          _StatusList(status: 'pending', emptyHint: 'Kutayotgan tashriflar yo\'q.'),
        ],
      ),
    );
  }
}

class _StatusList extends StatefulWidget {
  const _StatusList({required this.status, required this.emptyHint});

  final String status;
  final String emptyHint;

  @override
  State<_StatusList> createState() => _StatusListState();
}

class _StatusListState extends State<_StatusList> {
  late Future<List<OutboxEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<OutboxEntry>> _load() {
    return context.read<OutboxRepository>().findByStatus(widget.status);
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _retry(OutboxEntry entry) async {
    await context
        .read<VisitFinishOrchestrator>()
        .retry(entry.envelopeId);
    if (mounted) {
      await context.read<OutboxStatusCubit>().refresh();
      _refresh();
    }
  }

  Future<void> _discard(OutboxEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tashrifni o\'chirish?'),
        content: Text('Envelope ${entry.envelopeId} qaytarib bo\'lmas tarzda o\'chiriladi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Yo\'q'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ha, o\'chirish'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<OutboxRepository>().delete(entry.envelopeId);
    if (mounted) {
      await context.read<OutboxStatusCubit>().refresh();
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OutboxStatusCubit, OutboxStatusState>(
      listenWhen: (a, b) =>
          a.pending != b.pending ||
          a.retrying != b.retrying ||
          a.deadLetter != b.deadLetter,
      listener: (_, _) => _refresh(),
      child: FutureBuilder<List<OutboxEntry>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snap.data!;
          if (rows.isEmpty) {
            return Center(
                child: Text(widget.emptyHint,
                    style: Theme.of(context).textTheme.bodyMedium));
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _EntryTile(
                entry: rows[i],
                onRetry: () => _retry(rows[i]),
                onDiscard: () => _discard(rows[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.onRetry,
    required this.onDiscard,
  });

  final OutboxEntry entry;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd().add_Hm();
    final updated = dateFmt.format(entry.updatedAt);
    final subtitle = StringBuffer()
      ..write(entry.endpoint)
      ..write(' · ')
      ..write('${entry.attempts}/${entry.maxAttempts} urinish');
    if (entry.lastError != null) {
      subtitle.write(' · ${entry.lastError}');
    }
    return ListTile(
      title: Text(entry.envelopeId,
          style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text('$updated\n$subtitle'),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          switch (v) {
            case 'retry':
              onRetry();
              break;
            case 'discard':
              onDiscard();
              break;
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'retry', child: Text('Qayta urinish')),
          PopupMenuItem(value: 'discard', child: Text('O\'chirish')),
        ],
      ),
    );
  }
}
