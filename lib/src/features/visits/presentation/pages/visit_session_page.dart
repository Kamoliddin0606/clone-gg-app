import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:get_it/get_it.dart';

import '../../domain/entities/catalog_task.dart';
import '../../domain/entities/permissions.dart';
import '../../domain/entities/sequence_policy.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/visit_location.dart';
import '../../domain/entities/visit_session.dart';
import '../../domain/failure_messages.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/repositories/permissions_repository.dart';
import '../../infra/location/secure_location_service.dart';
import '../../infra/sync/visit_status_poller.dart';
import '../bloc/visit_session/visit_session_bloc.dart';
import '../bloc/visit_session/visit_session_event.dart';
import '../bloc/visit_session/visit_session_state.dart';
import '../task_pages/task_context.dart';
import '../task_renderer_registry.dart';
import '../widgets/locked_task_card.dart';
import '../widgets/task_progress_bar.dart';

/// Thin shell around [VisitSessionBloc] — picks the right task widget,
/// surfaces errors, and gates the finish button. Heavy lifting (timers,
/// validation, persistence) lives in the BLoC.
class VisitSessionPage extends StatelessWidget {
  const VisitSessionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VisitSessionBloc, VisitSessionState>(
      listener: _onState,
      builder: (context, state) => switch (state) {
        VisitSessionInitial() || VisitSessionLoading() =>
          const _LoadingScaffold(),
        VisitSessionActive() => _ActiveScaffold(state: state),
        VisitSessionFinishing(:final session) =>
          _BusyScaffold(message: 'Tashrif yakunlanmoqda…', session: session),
        VisitSessionEnqueued(:final session) =>
          _EnqueuedScaffold(session: session),
        VisitSessionCancelled() => const _CancelledScaffold(),
        VisitSessionError(:final failure, :final session) =>
          _ErrorScaffold(failure: failure, session: session),
      },
    );
  }

  void _onState(BuildContext context, VisitSessionState state) {
    if (state is VisitSessionError) {
      // Surface a localised message (uz/ru/en) instead of the raw wire
      // code. The locale comes from the navigator context so the same
      // failure renders differently for an uz user vs a ru one.
      final locale = Localizations.localeOf(context).languageCode;
      final text = VisitFailureCopy.localize(state.failure, locale: locale);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
    }
    if (state is VisitSessionCancelled) {
      Future.microtask(() {
        if (!context.mounted) return;
        Navigator.of(context).maybePop(state);
      });
    }
    // Enqueued no longer pops immediately — the EnqueuedScaffold polls
    // the backend for synced_1c so the agent sees confirmation that the
    // order reached 1C before we close the page.
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}

class _BusyScaffold extends StatelessWidget {
  const _BusyScaffold({required this.message, required this.session});
  final String message;
  final VisitSession session;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Tashrif')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      );
}

/// Post-finish surface. Shows an immediate "envelope queued" tick, then
/// fires [VisitStatusPoller] in the background and upgrades the copy to
/// "1C ga yetkazildi" once the backend's Celery forwarder lands the
/// SOAP `setOrder` (backend changelog § 7). Timeout falls back to
/// "1C'da qayta ishlanmoqda" — the visit is durable in the outbox
/// either way, so this is purely a UX feedback layer.
class _EnqueuedScaffold extends StatefulWidget {
  const _EnqueuedScaffold({required this.session});
  final VisitSession session;

  @override
  State<_EnqueuedScaffold> createState() => _EnqueuedScaffoldState();
}

class _EnqueuedScaffoldState extends State<_EnqueuedScaffold> {
  VisitStatusPollHandle? _handle;
  _PollPhase _phase = _PollPhase.queued;

  @override
  void initState() {
    super.initState();
    // Optional service — when the visits module isn't registered (tests,
    // legacy SOAP path) we just stay on the "queued" copy without
    // polling. Otherwise kick off the 30 s status poll.
    final sl = GetIt.instance;
    if (!sl.isRegistered<VisitStatusPoller>()) return;
    _handle = sl<VisitStatusPoller>().pollUntilTerminal(widget.session.visitId);
    _handle!.future.then((result) {
      if (!mounted) return;
      setState(() {
        if (result.reached1C) {
          _phase = _PollPhase.synced1C;
        } else if (result.rejected) {
          _phase = _PollPhase.rejected;
        } else if (result.timedOut) {
          _phase = _PollPhase.timedOut;
        } else {
          _phase = _PollPhase.queued;
        }
      });
    });
  }

  @override
  void dispose() {
    _handle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color, text) = switch (_phase) {
      _PollPhase.queued => (
          Icons.cloud_upload_outlined,
          Theme.of(context).colorScheme.primary,
          'Tashrif serverga yuborildi',
        ),
      _PollPhase.synced1C => (
          Icons.check_circle,
          Colors.green,
          'Buyurtma 1C ga yetkazildi',
        ),
      _PollPhase.rejected => (
          Icons.error_outline,
          Colors.red,
          '1C buyurtmani qabul qilmadi — ops ko\'rib chiqadi',
        ),
      _PollPhase.timedOut => (
          Icons.hourglass_bottom,
          Theme.of(context).colorScheme.tertiary,
          'Buyurtma 1C\'da qayta ishlanmoqda',
        ),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Tashrif yakunlandi')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (_phase == _PollPhase.queued)
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(true),
                child: const Text('Davom etish'),
              ),
          ],
        ),
      ),
    );
  }
}

enum _PollPhase { queued, synced1C, rejected, timedOut }

class _CancelledScaffold extends StatelessWidget {
  const _CancelledScaffold();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Tashrif bekor qilindi')),
        body: const Center(child: Icon(Icons.cancel, size: 64)),
      );
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.failure, this.session});
  final Object failure;
  final VisitSession? session;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<VisitSessionBloc>();
    return Scaffold(
      appBar: AppBar(title: const Text('Xatolik')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(failure.toString(),
                style: Theme.of(context).textTheme.bodyLarge),
            const Spacer(),
            FilledButton(
              onPressed: () {
                if (session != null) {
                  bloc.add(ResumeVisit(session!.visitId));
                } else {
                  Navigator.of(context).maybePop();
                }
              },
              child: Text(session == null ? 'Orqaga' : 'Qaytadan urinish'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveScaffold extends StatelessWidget {
  const _ActiveScaffold({required this.state});
  final VisitSessionActive state;

  @override
  Widget build(BuildContext context) {
    final session = state.session;
    final permissions = context.read<PermissionsRepository>().cached;
    final catalog = context.read<CatalogRepository>().cached;
    final policy = (permissions?.flags.strictSequence ?? false)
        ? const StrictSequencePolicy()
        : const FreeSequencePolicy();
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tashrif vazifalari'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _confirmCancel(context),
          ),
        ],
      ),
      body: Column(
        children: [
          TaskProgressBar(tasks: session.tasks),
          Expanded(
            child: state.activeTaskId == null
                ? _TaskList(
                    session: session,
                    catalog: catalog,
                    policy: policy,
                    locale: locale,
                    permissions: permissions,
                  )
                : _ActiveTaskHost(
                    session: session,
                    activeTaskId: state.activeTaskId!,
                    catalog: catalog,
                  ),
          ),
          if (state.activeTaskId == null)
            _FinishBar(session: session, permissions: permissions),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final cancelled = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tashrifni bekor qilish?'),
        content: const Text('Lokal ma\'lumotlar saqlanadi, lekin tashrif yakunlanmaydi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Yo\'q'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ha, bekor qilish'),
          ),
        ],
      ),
    );
    if (cancelled == true && context.mounted) {
      context
          .read<VisitSessionBloc>()
          .add(const CancelVisit(reason: 'user_cancelled'));
    }
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.session,
    required this.catalog,
    required this.policy,
    required this.locale,
    required this.permissions,
  });

  final VisitSession session;
  final VisitsCatalog? catalog;
  final SequencePolicy policy;
  final String locale;
  final VisitsPermissions? permissions;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: session.tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final task = session.tasks[i];
        final displayName =
            catalog?.byCode(task.taskCodeRaw)?.displayName(locale) ??
                task.taskCodeRaw;
        if (task.status == TaskRunStatus.completed ||
            task.status == TaskRunStatus.skipped) {
          return _CompletedTaskCard(task: task, displayName: displayName);
        }
        final block =
            policy.canStart(task: task, allTasks: session.tasks);
        if (block != null) {
          final blockingName =
              catalog?.byCode(block.blockingTask.taskCodeRaw)?.displayName(locale) ??
                  block.blockingTask.taskCodeRaw;
          return LockedTaskCard(
            task: task,
            blockingTask: block.blockingTask,
            displayName: displayName,
            blockingDisplayName: blockingName,
          );
        }
        return _PendingTaskCard(task: task, displayName: displayName);
      },
    );
  }
}

class _CompletedTaskCard extends StatelessWidget {
  const _CompletedTaskCard({required this.task, required this.displayName});
  final VisitTask task;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSkipped = task.status == TaskRunStatus.skipped;
    return Card(
      child: ListTile(
        leading: Icon(
          isSkipped ? Icons.skip_next : Icons.check_circle,
          color: isSkipped ? theme.colorScheme.outline : Colors.green,
        ),
        title: Text(displayName),
        subtitle: Text(isSkipped ? 'O\'tkazib yuborildi' : 'Bajarildi'),
      ),
    );
  }
}

class _PendingTaskCard extends StatelessWidget {
  const _PendingTaskCard({required this.task, required this.displayName});
  final VisitTask task;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.radio_button_unchecked),
        title: Text(displayName),
        subtitle: Text(task.required ? 'Majburiy' : 'Ixtiyoriy'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            context.read<VisitSessionBloc>().add(StartTask(task.taskId)),
      ),
    );
  }
}

class _ActiveTaskHost extends StatelessWidget {
  const _ActiveTaskHost({
    required this.session,
    required this.activeTaskId,
    required this.catalog,
  });

  final VisitSession session;
  final String activeTaskId;
  final VisitsCatalog? catalog;

  @override
  Widget build(BuildContext context) {
    final task = session.tasks.firstWhere((t) => t.taskId == activeTaskId);
    final entry = catalog?.byCode(task.taskCodeRaw);
    final bloc = context.read<VisitSessionBloc>();

    final ctx = TaskContext(
      visitId: session.visitId,
      taskId: task.taskId,
      taskCode: task.taskCodeRaw,
      payloadSchema: entry?.payloadSchema ?? const {},
      config: entry?.config ?? const {},
      draftPayload: task.payload.isEmpty ? null : task.payload,
      onCompleted: (payload) =>
          bloc.add(CompleteTask(taskId: task.taskId, payload: payload)),
      onSkipped: (reason) =>
          bloc.add(SkipTask(taskId: task.taskId, reason: reason)),
      onBack: () =>
          bloc.add(ResumeVisit(session.visitId)), // back to task list
    );

    return TaskRendererRegistry.instance.resolve(ctx);
  }
}

class _FinishBar extends StatelessWidget {
  const _FinishBar({required this.session, required this.permissions});
  final VisitSession session;
  final VisitsPermissions? permissions;

  @override
  Widget build(BuildContext context) {
    final ready = session.allRequiredCompleted;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: ready ? () => _finish(context) : null,
          icon: const Icon(Icons.flag),
          label: Text(ready
              ? 'Tashrifni yakunlash'
              : 'Majburiy vazifalar yakunlanmagan'),
        ),
      ),
    );
  }

  Future<void> _finish(BuildContext context) async {
    final location = context.read<SecureLocationService>();
    final bloc = context.read<VisitSessionBloc>();
    try {
      final fix = await location.currentPosition();
      bloc.add(FinishVisit(finishLocation: fix));
    } on LocationUnavailable catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GPS yo\'q: ${e.reason}')),
      );
    }
  }
}

// `permissions` is read but not used by the finish bar today — kept on
// the API so future per-org "must capture finish photo" hooks can land
// without re-threading the props.
//
// ignore: unused_element
extension _VisitLocationDecoy on VisitLocation {
  // Suppresses unused-import diagnostics under analyzer pre-3.5 setups.
}
